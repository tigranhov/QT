--[[
    RangeDetector Module
    Provides unit range detection using the action forbidden technique.
    
    The module works by attempting to target units and catching the ADDON_ACTION_FORBIDDEN
    event, which indicates that a unit exists and is in range but cannot be targeted
    due to addon restrictions.

    Error Handling Implementation:
    - Uses separate frames for different event types to avoid conflicts with other addons
    - Specifically designed to be compatible with Nova World Buffs addon which also handles
      targeting and UI errors
    
    Why this approach:
    1. Frame Separation:
       - Main frame (QT_RangeDetector) handles ADDON_ACTION_FORBIDDEN
       - Error frame (QT_ErrorHandler) handles UI_ERROR_MESSAGE
       - Unique frame names prevent conflicts with other addons' frame registrations
    
    2. UIParent Event Handling:
       - Preserves original UIParent error handler
       - Only filters our specific addon's events
       - Allows other addons (like Nova World Buffs) to handle their events normally
    
    3. Event Conflict Resolution:
       - Previous approach of unregistering events from UIParent caused conflicts
       - Nova World Buffs also handles targeting events
       - Current approach allows both addons to coexist by isolating our error handling
    
    This implementation resolved UI errors that occurred specifically when Nova World Buffs
    was active, which were caused by both addons trying to handle the same events globally.
]]

local addonName, ns = ...
ns = ns or {}

-- Local references
local GetTime = GetTime
local TargetUnit = TargetUnit

-- Configuration
local POLLING_FREQUENCY = 0.25  -- How often to check for targets (in seconds)
local MATCH_TIMEOUT = 2        -- How long to consider a target in range (in seconds)

--[[
    RangeDetector Module Definition
    Provides functionality to detect units in range using action forbidden technique.
]]
ns.RangeDetector = {
    isInitialized = false,
    
    -- State tracking
    state = {
        lastScan = 0,
        lastMatch = 0,
        currentMatch = false,
        scanData = {},
        detectedUnits = {},
        unitsProvider = nil
    },
    
    --[[
        Initialize the RangeDetector module
        Sets up event handling and UI modifications
        @return void
    ]]
    Initialize = function(self)
        if self.isInitialized then return end
        
        -- Create our frame with a unique, prefixed name
        local frame = CreateFrame("Frame", addonName .. "_RangeDetector", UIParent)

        -- Create a separate frame for error handling to avoid event conflicts
        local errorFrame = CreateFrame("Frame", addonName .. "_ErrorHandler", UIParent)

        -- Register for ADDON_ACTION_FORBIDDEN event on main frame
        frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
        -- Register UI errors on separate frame
        errorFrame:RegisterEvent("UI_ERROR_MESSAGE")

        -- Set up event handling
        frame:SetScript("OnEvent", function(_, event, addon, func)
            if event == "ADDON_ACTION_FORBIDDEN" then
                self:OnAddonActionForbidden(event, addon, func)
            end
        end)
        
        errorFrame:SetScript("OnEvent", function(_, event, errorType, message)
            if event == "UI_ERROR_MESSAGE" then
                return self:OnUIError(errorType, message)
            end
        end)

        -- Store frame references
        self.frame = frame
        self.errorFrame = errorFrame
        
        -- Only unregister our specific events
        local origErrorHandler = UIParent:GetScript("OnEvent")
        UIParent:SetScript("OnEvent", function(self, event, ...)
            if event == "ADDON_ACTION_FORBIDDEN" then
                local addon = ...
                if addon == addonName then return end
            end
            if origErrorHandler then
                origErrorHandler(self, event, ...)
            end
        end)
        
        self.isInitialized = true
    end,
    
    --[[
        Set the function that provides units to check
        @param providerFunc function - Function that returns array of unit objects
        @return void
    ]]
    SetUnitsProvider = function(self, providerFunc)
        self.state.unitsProvider = providerFunc
    end,
    
    --[[
        Main update function called on timer
        Checks all units provided by unitsProvider for range
        Updates visibility status on unit objects
        @return void
    ]]
    Update = function(self)
        if not self.isInitialized then return end
        if not self.state.unitsProvider then return end
        
        local now = GetTime()
        
        -- Only scan based on our polling frequency
        if now - self.state.lastScan <= POLLING_FREQUENCY then
            return
        end
        
        -- Update last scan time
        self.state.lastScan = now
        
        -- Clean up expired detections
        for name, data in pairs(self.state.detectedUnits) do
            if now - data.lastSeen > MATCH_TIMEOUT then
                self.state.detectedUnits[name] = nil
            end
        end
        
        -- Get current units and check each one
        local units = self.state.unitsProvider()
        if not units then return end
        
        for _, unit in ipairs(units) do
            -- Update visibility based on detection state
            local wasVisible = unit.isVisible
            unit.isVisible = self.state.detectedUnits[unit.name] ~= nil
            -- Check range for this unit if it's not already visible
            if not unit.isVisible then
                self:CheckUnitRange(unit.name)
            end
        end
    end,
    
    --[[
        Check if a specific unit is in range
        @param unitName string - Name of the unit to check
        @return void - Updates state through OnAddonActionForbidden
    ]]
    CheckUnitRange = function(self, unitName)
        if not unitName then return end
        
        -- Store what we're scanning for
        self.state.scanData = {
            name = unitName,
            timestamp = GetTime()
        }
        
        -- Attempt to target the unit
        -- This will trigger ADDON_ACTION_FORBIDDEN if the unit exists and is in range
        TargetUnit(unitName, true)
    end,
    
    --[[
        Handle UI error messages
        @param errorType number - The error type
        @param message string - The error message
        @return boolean - True if error was handled, false otherwise
    ]]
    OnUIError = function(self, errorType, message)
        -- Suppress targeting-related errors that we expect during range detection
        if message and (
                message:find("Target not in line of sight") or
                message:find("Invalid target") or
                message:find("You cannot target this unit") or
                message:find("You can't do that while") or
                message:find("No target is currently selected")
            ) then
            return true
        end
        return false
    end,
    --[[
        Handle the ADDON_ACTION_FORBIDDEN event
        Updates unit detection state when a unit is found in range
        @param event string - Event name
        @param forbiddenAddon string - Name of addon that triggered the event
        @param func string - Name of function that was forbidden
        @return void
    ]]
    OnAddonActionForbidden = function(self, event, forbiddenAddon, func)
        -- Only process our own forbidden actions
        if func ~= "TargetUnit()" or forbiddenAddon ~= addonName then return end
        
        -- Make sure we have scan data
        if not self.state.scanData or not self.state.scanData.name then return end
        
        local now = GetTime()
        local unitName = self.state.scanData.name
        
        -- Update our state
        self.state.detectedUnits[unitName] = {
            lastSeen = now,
            name = unitName
        }
        
        self.state.lastMatch = now
        self.state.currentMatch = true
    end,
    
    --[[
        Get a list of all units currently detected in range
        @return string[] - Array of unit names that are in range
    ]]
    GetUnitsInRange = function(self)
        local units = {}
        local now = GetTime()
        
        -- Clean up expired units and build our list
        for name, data in pairs(self.state.detectedUnits) do
            if now - data.lastSeen <= MATCH_TIMEOUT then
                table.insert(units, name)
            else
                self.state.detectedUnits[name] = nil
            end
        end
        
        return units
    end
}

-- Create a local reference
local RangeDetector = ns.RangeDetector

-- Hook into the addon's OnUpdate to perform our range checks
local function OnUpdate(self, elapsed)
    RangeDetector:Update()
end

-- Create and set up the update frame
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", OnUpdate)
updateFrame:Show() -- Make sure the frame is shown

-- Export the module
return RangeDetector 
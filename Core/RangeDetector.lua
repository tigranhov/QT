--[[
    RangeDetector Module
    Provides unit range detection using the action forbidden technique.
    
    The module works by attempting to target units and catching the ADDON_ACTION_FORBIDDEN
    event, which indicates that a unit exists and is in range but cannot be targeted
    due to addon restrictions.
    
    State Structure:
    {
        lastScan = number,      -- Timestamp of last scan
        lastMatch = number,     -- Timestamp of last successful match
        currentMatch = boolean, -- Whether we currently have any matches
        scanData = {           -- Data about current scan
            name = string,     -- Name of unit being scanned
            timestamp = number -- When the scan started
        },
        detectedUnits = {      -- Map of units currently in range
            [unitName] = {
                lastSeen = number, -- Last time unit was detected
                name = string     -- Name of the unit
            }
        },
        unitsProvider = function -- Function that provides list of units to check
    }
]]

local addonName, ns = ...
ns = ns or {}

-- Local references
local GetTime = GetTime
local TargetUnit = TargetUnit

-- Configuration
local POLLING_FREQUENCY = 0.25  -- How often to check for targets (in seconds)
local MATCH_TIMEOUT = 2         -- How long to consider a target in range (in seconds)

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
        
        -- Register for ADDON_ACTION_FORBIDDEN event
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
        frame:SetScript("OnEvent", function(_, event, forbiddenAddon, func)
            self:OnAddonActionForbidden(event, forbiddenAddon, func)
        end)
        
        -- Store the frame reference
        self.frame = frame
        
        -- Prevent default forbidden UI popup
        UIParent:UnregisterEvent("ADDON_ACTION_FORBIDDEN")
        
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
        
        for _, unit in ipairs(units) do
            -- Update visibility based on detection state
            local wasVisible = unit.isVisible
            unit.isVisible = self.state.detectedUnits[unit.name] ~= nil
            -- Check range for this unit
            self:CheckUnitRange(unit.name)
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
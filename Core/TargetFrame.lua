--[[
    TargetFrame Module
    Provides visual display of quest units that are currently in range.
]]

local addonName, ns = ...
ns = ns or {}

-- Local references
local CreateFrame = CreateFrame
local BackdropTemplateMixin = BackdropTemplateMixin

-- Constants
local FRAME_WIDTH = 200
local BUTTON_HEIGHT = 25
local BUTTON_SPACING = 2
local MAX_BUTTONS = 10

-- Colors
local COLORS = {
    background = {0, 0, 0, 0.7},
    border = {0.4, 0.4, 0.4, 0.8},
    turnInNpc = {0, 1, 0}, -- Green for turn-in NPCs
    target = {1, 1, 1},    -- White for regular targets
}

ns.TargetFrame = {
    isInitialized = false,
    frame = nil,
    buttons = {},
    isVisible = true, -- Add visibility state tracking
    
    --[[
        Initialize the target frame
        Creates the main frame and button pool
        @return void
    ]]
    Initialize = function(self)
        if self.isInitialized then return end
        
        -- Ensure dependencies are initialized
        if not ns.QuestObjectives or not ns.QuestObjectives.isInitialized then
            print("|cFFFF0000[QuestTarget]|r Waiting for QuestObjectives...")
            C_Timer.After(0.5, function() self:Initialize() end)
            return
        end
        
        -- Create main frame
        self.frame = CreateFrame("Frame", "QTTargetFrame", UIParent, 
            BackdropTemplateMixin and "BackdropTemplate" or nil)
        local f = self.frame
        
        -- Set up frame properties
        f:SetSize(FRAME_WIDTH, 30) -- Height will be adjusted dynamically
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(unpack(COLORS.background))
        f:SetBackdropBorderColor(unpack(COLORS.border))
        
        -- Set up dragging
        f:SetScript("OnMouseDown", function(frame, button)
            if button == "LeftButton" then
                frame:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", function(frame)
            frame:StopMovingOrSizing()
        end)
        
        -- Create title
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
        f.title:SetText("Quest Targets")
        
        -- Create button pool
        for i = 1, MAX_BUTTONS do
            local button = CreateFrame("Button", "QTTargetButton"..i, f, "SecureActionButtonTemplate")
            button:SetSize(FRAME_WIDTH - 16, BUTTON_HEIGHT)
            button:SetAttribute("type", "macro")
            
            -- Position first button under title, rest under previous button
            if i == 1 then
                button:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -5)
            else
                button:SetPoint("TOPLEFT", self.buttons[i-1], "BOTTOMLEFT", 0, -BUTTON_SPACING)
            end
            
            -- Create text
            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            button.text:SetPoint("LEFT", button, "LEFT", 4, 0)
            button.text:SetJustifyH("LEFT")
            
            -- Create highlight
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            
            table.insert(self.buttons, button)
        end
        
        -- Set up update timer
        f:SetScript("OnUpdate", function(_, elapsed)
            self:Update()
        end)
        
        self.isInitialized = true
        self:Show() -- Show frame initially
    end,
    
    --[[
        Toggle the frame visibility
        @return void
    ]]
    Toggle = function(self)
        if not self.isInitialized then return end
        
        self.isVisible = not self.isVisible
        if self.isVisible then
            self:Show()
        else
            self:Hide()
        end
    end,
    
    --[[
        Update the target frame
        Gets current visible units and updates the display
        @return void
    ]]
    Update = function(self)
        if not self.isInitialized then return end
        if not ns.QuestObjectives then return end
        if not self.isVisible then return end -- Add visibility check
        
        -- Get visible units
        print("[QuestTarget] Getting visible units...")
        local units = ns.QuestObjectives:GetVisibleUnits()
        print("[QuestTarget] Found " .. #units .. " visible units")
        
        -- Sort units: turn-in NPCs first, then other targets
        table.sort(units, function(a, b)
            if a.isTurnInNpc ~= b.isTurnInNpc then
                return a.isTurnInNpc -- Turn-in NPCs come first
            end
            return a.name < b.name -- Alphabetical within each group
        end)
        
        -- Update buttons
        local visibleButtons = 0
        for i, button in ipairs(self.buttons) do
            local unit = units[i]
            if unit then
                -- Set up macro to target the unit
                button:SetAttribute("macrotext", "/targetexact " .. unit.name)
                
                -- Set text color based on unit type
                local color = unit.isTurnInNpc and COLORS.turnInNpc or COLORS.target
                button.text:SetText(unit.name)
                button.text:SetTextColor(unpack(color))
                
                button:Show()
                visibleButtons = visibleButtons + 1
            else
                button:Hide()
            end
        end
        
        -- Adjust frame height based on visible buttons
        if visibleButtons > 0 then
            local height = 30 + (visibleButtons * (BUTTON_HEIGHT + BUTTON_SPACING))
            self.frame:SetHeight(height)
            self.frame:Show()
        else
            self.frame:Hide()
        end
    end,
    
    --[[
        Show the target frame
        @return void
    ]]
    Show = function(self)
        if self.isInitialized then
            self.frame:Show()
            self.isVisible = true
        end
    end,
    
    --[[
        Hide the target frame
        @return void
    ]]
    Hide = function(self)
        if self.isInitialized then
            self.frame:Hide()
            self.isVisible = false
        end
    end
}

-- Export the module
return ns.TargetFrame 
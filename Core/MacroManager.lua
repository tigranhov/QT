--[[
    MacroManager Module
    Handles creation and updating of a dynamic macro for targeting visible quest targets.
]]

local addonName, ns = ...
ns = ns or {}

local MACRO_NAME = "QT_Targets"
local MACRO_ICON = "Ability_Hunter_SniperShot"
local MAX_CHARACTER_MACROS = 18
local MAX_ACCOUNT_MACROS = 120

local MacroManager = {
    isInitialized = false,
    frame = nil,
    UPDATE_FREQUENCY = 1, -- How often to update the macro (in seconds)
    enabled = true,       -- Track enabled state
    lastTargetName = nil  -- Track last selected target
}

function MacroManager:Initialize()
    if self.isInitialized then return end

    print("[QT] Initializing MacroManager")

    -- Create frame for OnUpdate without size/position (making it virtual)
    self.frame = CreateFrame("Frame", nil, UIParent)
    
    -- Register for target change events
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TARGET_CHANGED" and UnitExists("target") then
            local name = UnitName("target")
            if name and ns.QuestObjectives and ns.QuestObjectives:IsQuestUnit(name) then
                self.lastTargetName = name
            end
        end
    end)
    -- Initialize update timer
    self.frame.TimeSinceLastUpdate = 0
    
    -- Set up update checks with improved timing logic
    self.frame:SetScript("OnUpdate", function(frame, elapsed)
        frame.TimeSinceLastUpdate = frame.TimeSinceLastUpdate + elapsed
        
        while (frame.TimeSinceLastUpdate > self.UPDATE_FREQUENCY) do
            self:UpdateMacro()
            frame.TimeSinceLastUpdate = frame.TimeSinceLastUpdate - self.UPDATE_FREQUENCY
        end
    end)
    
    -- Register slash command
    SLASH_QTMACRO1 = "/qtm"
    SlashCmdList["QTMACRO"] = function(msg)
        msg = msg:lower()
        if msg == "enable" then
            self:Enable()
        elseif msg == "disable" then
            self:Disable()
        else  -- toggle or empty command
            if self.enabled then
                self:Disable()
            else
                self:Enable()
            end
        end
    end
    
    self.isInitialized = true
end

function MacroManager:Enable()
    if not self.isInitialized then return end
    self.enabled = true
    self.frame:Show()
    print("[QT] MacroManager enabled - macro will update automatically")
end

function MacroManager:Disable()
    if not self.isInitialized then return end
    self.enabled = false
    self.frame:Hide()
    print("[QT] MacroManager disabled - macro will not update")
end

function MacroManager:CreateOrUpdateMacro()
    local macroIndex = GetMacroIndexByName(MACRO_NAME)
    if macroIndex == 0 then
        -- Get number of global and per-character macros
        local numGlobal, numPerChar = GetNumMacros()
        
        -- Try to create global macro first
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(MACRO_NAME, "INV_MISC_QUESTIONMARK", "/cleartarget [dead]", nil)
            print("[QT] Created global macro")
            return
        end
        
        -- Fall back to character slots if global is full
        if numPerChar < MAX_CHARACTER_MACROS then
            CreateMacro(MACRO_NAME, "INV_MISC_QUESTIONMARK", "/cleartarget [dead]", 1)
            print("[QT] Created character macro")
            return
        end
        
        print("[QT] No macro slots available")
    end
end

--[[
    Updates the targeting macro based on currently visible quest units.
    Priority system:
    1. Regular quest targets (combat objectives) get absolute priority
    2. Turn-in NPCs are only included if no regular targets exist
    3. Empty macro with comment if no valid targets found
    
    This ensures players are guided to complete quest objectives before
    being directed to turn-in locations.
]]
function MacroManager:UpdateMacro()
    if not ns.QuestObjectives then return end
    
    local visibleUnits = ns.QuestObjectives:GetVisibleUnits()
    if not visibleUnits then return end
    
    -- Stage 1: Ensure macro exists
    -- Create or verify macro exists before attempting updates
    local macroIndex = GetMacroIndexByName(MACRO_NAME)
    if macroIndex == 0 then
        self:CreateOrUpdateMacro()
        macroIndex = GetMacroIndexByName(MACRO_NAME)
        if macroIndex == 0 then return end -- Exit if we couldn't create the macro
    end
    
    -- Stage 2: Initialize macro building
    -- Start with cleartarget command and prepare for unit collection
    local macroText = "/cleartarget [dead]"
    local targetCount = 0
    local maxLength = 255  -- WoW's macro character limit
    local turnInNpcs = {}
    
    -- Stage 3: Primary target collection
    -- First pass: prioritize last selected target, then regular quest targets
    -- We collect turn-in NPCs separately but don't use them yet
    -- Add last selected target first if it's still valid
    if self.lastTargetName then
        for _, unit in ipairs(visibleUnits) do
            if unit.name == self.lastTargetName and unit.isTarget and not unit.isTurnInNpc then
                if not unit.progress or unit.progress < 100 then
                    local newLine = string.format("\n/targetexact %s", unit.name)
                    if (macroText:len() + newLine:len()) <= maxLength then
                        macroText = macroText .. newLine
                        targetCount = targetCount + 1
                    end
                    break
                end
            end
        end
    end

    -- Then add other regular targets
    for _, unit in ipairs(visibleUnits) do
        if unit.isTarget and not unit.isTurnInNpc and unit.name ~= self.lastTargetName then
            if not unit.progress or unit.progress < 100 then
                local newLine = string.format("\n/targetexact %s", unit.name)
                if (macroText:len() + newLine:len()) <= maxLength then
                    macroText = macroText .. newLine
                    targetCount = targetCount + 1
                else
                    break
                end
            end
        elseif unit.isTurnInNpc then
            table.insert(turnInNpcs, unit)
        end
    end
    
    -- Stage 4: Fallback to turn-in NPCs
    -- Only if no regular targets were found
    -- This ensures players complete objectives before seeing turn-in options
    if targetCount == 0 and #turnInNpcs > 0 then
        for _, unit in ipairs(turnInNpcs) do
            local newLine = string.format("\n/targetexact %s", unit.name)
            if (macroText:len() + newLine:len()) <= maxLength then
                macroText = macroText .. newLine
                targetCount = targetCount + 1
            else
                break
            end
        end
    end
    
    -- Stage 5: Handle empty state
    -- Provide feedback when no valid targets exist
    if targetCount == 0 then
        macroText = "-- No quest objectives found"
    end
    
    -- Stage 6: Update macro
    -- Only update if content has changed to prevent unnecessary updates
    if macroIndex > 0 then
        local _, _, oldMacroText = GetMacroInfo(macroIndex)
        if oldMacroText ~= macroText then
            EditMacro(macroIndex, MACRO_NAME, nil, macroText)
        end
    end
end

ns.MacroManager = MacroManager

-- Export the module
return MacroManager 
--[[
    MarkerManager Module
    Handles raid target markers for quest targets and turn-in NPCs.
    
    Marker Rules:
    - Selected quest target: Skull (8)
    - Hovered quest target: Cross (7)
    - Selected turn-in NPC: Square (6)
]]

local addonName, ns = ...
ns = ns or {}

-- Constants for raid markers
local MARKER = {
    SELECTED_TARGET = 8,  -- Skull
    HOVER_TARGET = 7,     -- Cross
    TURN_IN_NPC = 6      -- Square
}

local MarkerManager = {
    isInitialized = false,
    currentTarget = nil,
    hoveredUnit = nil,
    frame = nil
}

function MarkerManager:Initialize()
    if self.isInitialized then return end

    self.frame = CreateFrame("Frame")
    
    -- Monitor target changes
    self.frame:RegisterEvent("UNIT_TARGET")
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_TARGET" and unit == "player" then
            -- This is a more specific target selection event
            self:OnTargetChanged()
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- Keep this for clearing state when target is lost
            if not UnitExists("target") then
                self.currentTarget = nil
            end
        end
    end)

    -- Monitor unit hover state via GameTooltip
    local originalOnTooltipSetUnit = GameTooltip:GetScript("OnTooltipSetUnit")
    GameTooltip:SetScript("OnTooltipSetUnit", function(tooltip, ...)
        if originalOnTooltipSetUnit then
            originalOnTooltipSetUnit(tooltip, ...)
        end
        self:OnTooltipUnit(tooltip)
    end)

    GameTooltip:HookScript("OnHide", function()
        self:OnTooltipHide()
    end)

    self.isInitialized = true
end

function MarkerManager:SetUnitMarker(unit, marker)
    if not unit then return false end
    
    -- Don't override existing markers
    if GetRaidTargetIndex(unit) then return false end
    
    SetRaidTarget(unit, marker)
    return true
end

function MarkerManager:OnTargetChanged()
    if not UnitExists("target") then
        self.currentTarget = nil
        return
    end

    local targetName = UnitName("target")
    if not targetName then return end

    -- Check if target is a quest unit first
    if ns.QuestObjectives then
        local isTarget, isTurnInNpc, _, progress = ns.QuestObjectives:IsQuestUnit(targetName)
        
        -- Always update our tracking
        self.currentTarget = targetName
        
        -- If it's not a quest unit, just track it but don't mark
        if not isTarget and not isTurnInNpc then return end
        
        -- Try to set appropriate marker
        if isTurnInNpc then
            self:SetUnitMarker("target", MARKER.TURN_IN_NPC)
        elseif isTarget and (not progress or progress < 100) then
            self:SetUnitMarker("target", MARKER.SELECTED_TARGET)
        end
    end
end

function MarkerManager:OnTooltipUnit(tooltip)
    -- Get the unit from the tooltip
    local _, unit = tooltip:GetUnit()
    if not unit then return end

    local unitName = UnitName(unit)
    if not unitName then return end

    -- If we're already hovering this unit, don't do anything
    if self.hoveredUnit == unit then return end

    -- Clear previous hover unit
    if self.hoveredUnit and self.hoveredUnit ~= unit then
        self.hoveredUnit = nil
    end

    -- Check if unit is a quest unit
    if ns.QuestObjectives then
        local isTarget, isTurnInNpc, _, progress = ns.QuestObjectives:IsQuestUnit(unitName)
        
        -- Turn-in NPCs always get their specific marker
        if isTurnInNpc then
            if self:SetUnitMarker(unit, MARKER.TURN_IN_NPC) then
                self.hoveredUnit = unit
            end
            return
        end
        
        -- For regular targets
        if isTarget and (not progress or progress < 100) then
            -- If this is not our current target, mark it with hover marker
            if unitName ~= self.currentTarget then
                if self:SetUnitMarker(unit, MARKER.HOVER_TARGET) then
                    self.hoveredUnit = unit
                end
            end
        end
    end
end

function MarkerManager:OnTooltipHide()
    -- Clear hover marker if we were showing one
    if self.hoveredUnit then
        local currentMarker = GetRaidTargetIndex(self.hoveredUnit)
        -- Only clear hover markers, not selection or turn-in markers
        if currentMarker == MARKER.HOVER_TARGET then
            SetRaidTarget(self.hoveredUnit, 0)
        end
        self.hoveredUnit = nil
    end
end

ns.MarkerManager = MarkerManager

-- Export the module
return MarkerManager 
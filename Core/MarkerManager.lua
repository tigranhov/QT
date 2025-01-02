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
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self.frame:SetScript("OnEvent", function(_, event, unit)
        -- Only process events if addon is enabled
        if not ns.enabled then return end

        if event == "PLAYER_TARGET_CHANGED" then
            self:SetUnitMarker("target", "target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            self:SetUnitMarker("mouseover", "mouseover")
        end
    end)
    self.isInitialized = true
end

function MarkerManager:SetUnitMarker(unit, markerType)
    -- Only set markers if addon is enabled
    -- Only process if we have QuestObjectives module
    if not ns.QuestObjectives then return false end

    -- Get visible units from QuestObjectives
    local visibleUnits = ns.QuestObjectives:GetVisibleUnits()
    if not visibleUnits then return false end

    -- Check if unit is in our visible units list
    local unitName = UnitName(unit)
    if not unitName then return false end

    local isVisibleUnit = false
    for _, visibleUnit in ipairs(visibleUnits) do
        if visibleUnit.name == unitName then
            isVisibleUnit = true
            break
        end
    end

    if not isVisibleUnit then return false end
    if not ns.enabled then return false end
    if not unit then return false end

    if markerType == "target" then
        -- Always set skull marker on target
        SetRaidTarget(unit, MARKER.SELECTED_TARGET) -- Skull (8)
        return true
    elseif markerType == "mouseover" then
        -- Only set hover marker if unit doesn't already have one
        if GetRaidTargetIndex(unit) then return false end
        SetRaidTarget(unit, MARKER.HOVER_TARGET) -- Cross (7)
        return true
    end

    return false
end

function MarkerManager:OnTargetChanged()
end

ns.MarkerManager = MarkerManager

return MarkerManager

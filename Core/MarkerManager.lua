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
    frame = nil,
    ignorePartyRestriction = false
}

function MarkerManager:Initialize()
    if self.isInitialized then return end

    self.frame = CreateFrame("Frame")
    
    -- Register slash command
    SLASH_QTMI1 = "/qtmi"
    SlashCmdList["QTMI"] = function(msg)
        self.ignorePartyRestriction = not self.ignorePartyRestriction
        if self.ignorePartyRestriction then
            print("QT: Marker party restrictions disabled")
        else
            print("QT: Marker party restrictions enabled")
        end
    end
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
    -- Check if we have a valid unit first
    if not UnitExists(unit) then return false end
    -- Only set markers if addon is enabled
    -- Only process if we have QuestObjectives module
    if not ns.QuestObjectives then return false end

    -- Get filtered units from QuestObjectives
    local visibleUnits = ns.QuestObjectives:GetVisibleUnits()
    local filteredUnits = ns.QuestObjectives:GetFilteredUnits(visibleUnits)
    if not filteredUnits then return false end

    -- Check if unit is in our filtered units list
    local unitName = UnitName(unit)
    if not unitName then return false end

    local isValidUnit = false
    for _, filteredUnit in ipairs(filteredUnits) do
        if filteredUnit.name == unitName then
            isValidUnit = true
            break
        end
    end

    if not isValidUnit then return false end
    
    -- Check if player is in a party and is not the leader (unless override is active)
    if not self.ignorePartyRestriction and IsInGroup() and not UnitIsGroupLeader("player") then
        print("[QT] Not group leader (use /qtmi to override)")
        return false
    end

    if not ns.enabled then return false end

    if markerType == "target" then
        -- Always set skull marker on target
        local currentMarker = GetRaidTargetIndex(unit)

        -- If the unit already has the marker we want, consider it a success
        if currentMarker == MARKER.SELECTED_TARGET then return true end

        -- Try to clear any existing marker first if different from what we want
        if currentMarker and currentMarker ~= MARKER.SELECTED_TARGET then
            SetRaidTarget(unit, 0)
        end

        -- Small delay to ensure marker clearing is processed
        C_Timer.After(0.1, function()
            if UnitExists(unit) then                        -- Double check unit still exists after delay
                SetRaidTarget(unit, MARKER.SELECTED_TARGET) -- Skull (8)
            end
        end)

        return true -- Return true since we've initiated the marking process
    elseif markerType == "mouseover" then
        -- Only set hover marker if unit doesn't already have one
        if GetRaidTargetIndex(unit) then return false end
        local success = SetRaidTarget(unit, MARKER.HOVER_TARGET) -- Cross (7)
        return success
    end

    return false
end

function MarkerManager:OnTargetChanged()
end

ns.MarkerManager = MarkerManager

return MarkerManager

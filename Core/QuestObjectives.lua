--[[
    QuestObjectives Module
    Handles quest target tracking and management by integrating with Questie.
    
    Unit Structure:
    {
        name = string,        -- Name of the unit
        isTarget = boolean,   -- True if this is a quest target (monster or item dropper)
        isTurnInNpc = boolean, -- True if this is a quest turn-in NPC
        isVisible = boolean,  -- True if unit is currently in range (updated by RangeDetector)
        progress = number,    -- Progress percentage for this unit's objective (0-100)
        questName = string,   -- Name of the quest this unit is related to
        objectiveName = string, -- Description of the specific objective
        objectiveType = string  -- Type of objective: "kill" or "collect"
    }
]]

local addonName, ns = ...
ns = ns or {}

-- Local references to Questie modules
local QuestieDB
local QuestiePlayer

--[[
    QuestObjectives Module Definition
    Provides functionality to track and manage quest-related units.
]]
ns.QuestObjectives = {
    isInitialized = false,
    unitCache = {}, -- Add cache for unit states
    
    --[[
        Initialize the QuestObjectives module
        Sets up Questie integration and RangeDetector connection
        @return void
    ]]
    Initialize = function(self)
        -- Import required Questie modules
        QuestieDB = QuestieLoader:ImportModule("QuestieDB")
        if not QuestieDB then return end
        
        QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer")
        if not QuestiePlayer then return end
        
        -- Initialize RangeDetector if it exists
        if ns.RangeDetector then
            ns.RangeDetector:Initialize()
            ns.RangeDetector:SetUnitsProvider(function() return self:GetQuestUnits() end)
        end
        
        self.isInitialized = true
    end,
    
    --[[
        Get all quest-related units with their current status
        This is the main method to get an up-to-date list of all units
        with their visibility status maintained by RangeDetector
        
        @return table[] - Array of unit objects
    ]]
    GetQuestUnits = function(self)
        if not self.isInitialized then return {} end
        if not QuestiePlayer or not QuestiePlayer.currentQuestlog then return {} end
        
        local units = {}
        local currentUnits = {} -- Track current units for cleanup
        
        -- Process quest log
        for questId, quest in pairs(QuestiePlayer.currentQuestlog) do
            -- Add turn-in NPCs for completed quests
            if quest and quest:IsComplete() == 1 then
                if quest.Finisher and quest.Finisher.NPC then
                    for _, npcId in pairs(quest.Finisher.NPC) do
                        local npc = QuestieDB:GetNPC(npcId)
                        if npc and npc.name then
                            -- Use cached unit if exists, otherwise create new
                            local unit = self.unitCache[npc.name] or {
                                name = npc.name,
                                isTarget = false,
                                isTurnInNpc = true,
                                isVisible = false
                            }
                            self.unitCache[npc.name] = unit
                            currentUnits[npc.name] = true
                            table.insert(units, unit)
                        end
                    end
                end
            end
            
            -- Add targetable units from objectives
            if quest.Objectives then
                for _, objective in pairs(quest.Objectives) do
                    -- Only process incomplete objectives
                    if objective.Needed and objective.Collected then
                        -- Calculate progress percentage
                        local progress = math.floor((objective.Collected / objective.Needed) * 100)
                        -- Add monster targets
                        if objective.Type == "monster" and objective.spawnList then
                            for _, spawn in pairs(objective.spawnList) do
                                if spawn.Name and not currentUnits[spawn.Name] then
                                    -- Use cached unit if exists, otherwise create new
                                    local unit = self.unitCache[spawn.Name] or {
                                        name = spawn.Name,
                                        isTarget = true,
                                        isTurnInNpc = false,
                                        isVisible = false,
                                        progress = 0,
                                        questName = quest.name or "Unknown Quest",
                                        objectiveName = objective.Description or "",
                                        objectiveType = "kill"
                                    }
                                    -- Update progress
                                    unit.progress = progress
                                    unit.questName = quest.name or "Unknown Quest"
                                    unit.objectiveName = objective.Description or ""
                                    unit.objectiveType = "kill"
                                    self.unitCache[spawn.Name] = unit
                                    currentUnits[spawn.Name] = true
                                    table.insert(units, unit)
                                end
                            end
                        -- Add monsters that drop required items
                        elseif objective.Type == "item" and objective.spawnList then
                            for _, spawn in pairs(objective.spawnList) do
                                if spawn.Name and not currentUnits[spawn.Name] then
                                    -- Use cached unit if exists, otherwise create new
                                    local unit = self.unitCache[spawn.Name] or {
                                        name = spawn.Name,
                                        isTarget = true,
                                        isTurnInNpc = false,
                                        isVisible = false,
                                        progress = 0,
                                        questName = quest.name or "Unknown Quest",
                                        objectiveName = objective.Description or "",
                                        objectiveType = "collect"
                                    }
                                    -- Update progress
                                    unit.progress = progress
                                    unit.questName = quest.name or "Unknown Quest"
                                    unit.objectiveName = objective.Description or ""
                                    unit.objectiveType = "collect"
                                    self.unitCache[spawn.Name] = unit
                                    currentUnits[spawn.Name] = true
                                    table.insert(units, unit)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Clean up units that are no longer in quests
        for name, _ in pairs(self.unitCache) do
            if not currentUnits[name] then
                self.unitCache[name] = nil
            end
        end
        
        return units
    end,
    
    --[[
        Get only the units that are currently visible (in range)
        @return table[] - Array of visible unit objects
    ]]
    GetVisibleUnits = function(self)
        local units = self:GetQuestUnits()
        local visibleUnits = {}
        
        for _, unit in ipairs(units) do
            if unit.isVisible then
                table.insert(visibleUnits, unit)
            end
        end
        
        return visibleUnits
    end,
    
    --[[
        Check if a unit is quest-related and get its status
        @param unitName string - Name of the unit to check
        @return boolean, boolean, boolean - isTarget, isTurnInNpc, isVisible
    ]]
    IsQuestUnit = function(self, unitName)
        if not unitName or not self.isInitialized then 
            return false, false, false
        end
        
        local units = self:GetQuestUnits()
        local lowerUnitName = string.lower(unitName)
        
        for _, unit in ipairs(units) do
            if string.find(lowerUnitName, string.lower(unit.name)) then
                return unit.isTarget, unit.isTurnInNpc, unit.isVisible
            end
        end
        
        return false, false, false
    end
}

-- Export the module
return ns.QuestObjectives 
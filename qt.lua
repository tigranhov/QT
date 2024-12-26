--[[
    QuestTarget Addon
    Main initialization file that sets up the addon and its modules.
]]

local addonName, ns = ...
local QT = ns

-- Initialize frame for events
QT.frame = CreateFrame("Frame")

-- Slash command handler
local function HandleSlashCommand(msg)
    local command = msg:lower()
    
    if command == "toggle" or command == "" then
        -- Toggle frame visibility
        if QT.TargetFrame then
            QT.TargetFrame:Toggle()
        end
    elseif command == "show" then
        -- Show frame
        if QT.TargetFrame then
            QT.TargetFrame:Show()
        end
    elseif command == "hide" then
        -- Hide frame
        if QT.TargetFrame then
            QT.TargetFrame:Hide()
        end
    end
end

-- Register slash commands
SLASH_QUESTTARGET1 = "/qt"
SLASH_QUESTTARGET2 = "/questtarget"
SlashCmdList["QUESTTARGET"] = HandleSlashCommand

-- Event handling
QT.frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize modules in correct order
        if not QT.QuestObjectives then return end
        
        -- Initialize QuestObjectives first
        QT.QuestObjectives:Initialize()
        
        -- Initialize RangeDetector
        if QT.RangeDetector then
            QT.RangeDetector:Initialize()
        end
        
        -- Initialize MarkerManager
        if QT.MarkerManager then
            QT.MarkerManager:Initialize()
        end
        
        -- Initialize MacroManager
        if QT.MacroManager then
            QT.MacroManager:Initialize()
        end
        
        -- Initialize TargetFrame
        if QT.TargetFrame then
            QT.TargetFrame:Initialize()
        end
    end
end)

-- Register events
QT.frame:RegisterEvent("ADDON_LOADED")

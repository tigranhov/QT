--[[
    QuestTarget Addon
    Main initialization file that sets up the addon and its modules.
]]

local addonName, ns = ...
local QT = ns

-- Initialize frame for events
QT.frame = CreateFrame("Frame")

-- Global addon state
QT.enabled = true

-- Function to disable all subsystems
local function DisableSubsystems()
    if QT.RangeDetector and QT.RangeDetector.frame then
        QT.RangeDetector.frame:Hide()
    end
    if QT.MarkerManager and QT.MarkerManager.frame then
        QT.MarkerManager.frame:Hide()
    end
    if QT.TargetFrame then
        QT.TargetFrame:Hide()
    end
    -- Clear macro when disabled
    if QT.MacroManager then
        local macroIndex = GetMacroIndexByName("QT_Targets")
        if macroIndex > 0 then
            EditMacro(macroIndex, "QT_Targets", nil, "-- QuestTarget disabled")
        end
    end
end

-- Function to enable all subsystems
local function EnableSubsystems()
    if QT.RangeDetector and QT.RangeDetector.frame then
        QT.RangeDetector.frame:Show()
    end
    if QT.MarkerManager and QT.MarkerManager.frame then
        QT.MarkerManager.frame:Show()
    end
    if QT.TargetFrame then
        QT.TargetFrame:Show()
    end
    -- Update macro when enabled
    if QT.MacroManager then
        QT.MacroManager:UpdateMacro()
    end
end
-- Slash command handler
local function HandleSlashCommand(msg)
    local command, rest = msg:match("^(%S+)%s*(.-)$")
    if not command then command = msg end
    command = command:lower()
    
    if command == "help" then
        print("|cFF00FF00QuestTarget Addon Commands:|r")
        print("Main commands (/qt or /questtarget):")
        print("  |cFFFFFF00/qt|r - Toggle the target frame")
        print("  |cFFFFFF00/qt show|r - Show the target frame")
        print("  |cFFFFFF00/qt hide|r - Hide the target frame")
        print("  |cFFFFFF00/qt enable|r - Enable the addon")
        print("  |cFFFFFF00/qt disable|r - Disable the addon")
        print("  |cFFFFFF00/qt completed|r - Toggle showing completed targets")
        print("  |cFFFFFF00/qt keybind <key>|r - Set the next target keybind")
        print("  |cFFFFFF00/qt list|r - List all current targets")
        print("  |cFFFFFF00/qt help|r - Show this help message")

        print("\nQuest Objectives commands (/qto):")
        print("  |cFFFFFF00/qto add <name>|r - Add a custom target by name")
        print("  |cFFFFFF00/qto add target|r - Add your current target as a custom target")
        print("  |cFFFFFF00/qto timeout <minutes>|r - Set the timeout for custom targets")
        print("  |cFFFFFF00/qto clear|r - Clear all manual objectives")
        print("  |cFFFFFF00/qto print|r - Show current manual objectives")
        print("  |cFFFFFF00/qto data <unit name>|r - Show detailed unit data")

        print("\nMarker and Macro commands:")
        print("  |cFFFFFF00/qtm|r - Toggle macro manager")
        print("  |cFFFFFF00/qtm enable|r - Enable macro manager")
        print("  |cFFFFFF00/qtm disable|r - Disable macro manager")
        print("  |cFFFFFF00/qtmi|r - Toggle party restrictions for markers")
        return
    end

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
    elseif command == "enable" then
        -- Enable addon
        QT.enabled = true
        print("QuestTarget addon enabled")
        EnableSubsystems()
    elseif command == "disable" then
        -- Disable addon
        QT.enabled = false
        print("QuestTarget addon disabled")
        DisableSubsystems()
    elseif command == "completed" then
        if QT.TargetFrame then
            QuestTargetSettings.showCompleted = not QuestTargetSettings.showCompleted
            print(string.format("[QuestTarget] Show completed targets: %s",
                QuestTargetSettings.showCompleted and "Enabled" or "Disabled"))
        end
    elseif command == "keybind" and rest ~= "" then
        if QT.TargetFrame and QT.TargetFrame.keybindButton then
            -- Clear existing binding if it exists
            if QuestTargetSettings.nextTargetKeybind then
                SetBinding(QuestTargetSettings.nextTargetKeybind)
            end

            -- Set new binding
            local key = rest:upper()
            if SetBinding(key, "CLICK " .. QT.TargetFrame.keybindButton:GetName() .. ":LeftButton") then
                QuestTargetSettings.nextTargetKeybind = key
                print(string.format("[QuestTarget] Next target keybind set to: %s", key))
            else
                print("[QuestTarget] Failed to set keybind. Invalid key or already in use.")
            end
        end
    elseif command == "list" then
        if QT.QuestObjectives then
            local units = QT.QuestObjectives:GetVisibleUnits()
            if not units or #units == 0 then
                print("[QuestTarget] No units available")
                return
            end

            print("[QuestTarget] Current targets:")
            for i, unit in ipairs(units) do
                local unitType = unit.isTurnInNpc and "Turn-in NPC" or "Target"
                local progress = not unit.isTurnInNpc and unit.progress and string.format(" (%d%%)", unit.progress) or ""
                print(string.format("%d. %s - %s%s", i, unit.name, unitType, progress))
            end
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
        
        -- Only initialize if addon is enabled
        if QT.enabled then
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
        else
            -- If addon starts disabled, make sure subsystems are disabled
            DisableSubsystems()
        end
    end
end)

-- Register events
QT.frame:RegisterEvent("ADDON_LOADED")

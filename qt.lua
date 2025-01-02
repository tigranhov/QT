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
    local command = msg:lower()
    
    if command == "help" then
        print("|cFF00FF00QuestTarget Addon Commands:|r")
        print("Main commands (/qt or /questtarget):")
        print("  |cFFFFFF00/qt|r - Toggle the target frame")
        print("  |cFFFFFF00/qt show|r - Show the target frame")
        print("  |cFFFFFF00/qt hide|r - Hide the target frame")
        print("  |cFFFFFF00/qt enable|r - Enable the addon")
        print("  |cFFFFFF00/qt disable|r - Disable the addon")
        print("  |cFFFFFF00/qt help|r - Show this help message")

        print("\nTarget Frame commands (/qtf):")
        print("  |cFFFFFF00/qtf|r - Toggle the target frame")
        print("  |cFFFFFF00/qtf enable|r - Show the target frame")
        print("  |cFFFFFF00/qtf disable|r - Hide the target frame")
        print("  |cFFFFFF00/qtf completed|r - Toggle showing completed targets")
        print("  |cFFFFFF00/qtf keybind <key>|r - Set the next target keybind")
        print("  |cFFFFFF00/qtf list|r - List all current targets")

        print("\nMarker Manager commands (/qtm):")
        print("  |cFFFFFF00/qtm|r - Toggle auto-marking")
        print("  |cFFFFFF00/qtm enable|r - Enable auto-marking")
        print("  |cFFFFFF00/qtm disable|r - Disable auto-marking")
        print("  |cFFFFFF00/qtm clear|r - Clear all raid markers")
        print("  |cFFFFFF00/qtm config|r - Open marker configuration")
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

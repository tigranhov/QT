--[[
    TargetFrame Module
    A dynamic list of targetable quest units that updates based on player proximity and quest status.

    Target List Behavior:
    1. Visibility Rules:
        - Only shows units that are currently visible to the player
        - Filters out completed quest targets unless explicitly enabled
        - Hides duplicate entries of the same unit name
        - Shows "No Targets" message when no valid targets are found

    2. Target Prioritization:
        - Quest turn-in NPCs always appear at the top of the list
        - If the same NPC is both a turn-in and regular target, shows as turn-in
        - Regular quest targets are sorted alphabetically below turn-in NPCs
        - Completed targets (100% progress) are hidden by default

    3. Progress Tracking:
        - Regular targets show current progress as a percentage bar
        - Turn-in NPCs don't show progress bars
        - Progress updates dynamically as quest objectives are completed
        - 100% complete targets can be shown/hidden via "/qtf completed"

    4. Target Interaction:
        - Clicking any target attempts to target that unit
        - Turn-in NPCs are automatically marked with Square (6)
        - Regular targets are automatically marked with Skull (8)
        - Both left and right clicks perform the same targeting action

    5. List Updates:
        - List refreshes every 0.1 seconds
        - Frame grows/shrinks to fit content
        - Minimum 1 entry height for "No Targets"
        - Maximum width of 200px with text truncation
        - Preserves scroll position during updates

    6. Visual Indicators:
        - Turn-in NPCs shown in green text
        - Regular targets shown in white text
        - Progress bars shown in default UI colors
        - "No Targets" shown in gray when list is empty
]]
local addonName, ns = ...

-- Constants
local Constants = {
    FRAME = {
        MIN_WIDTH = 120,
        MIN_HEIGHT = 50,
        MAX_WIDTH = 200,
        TITLE_HEIGHT = 16,
        BUTTON_HEIGHT = 16,
        BUTTON_SPACING = 1,
        PADDING = 4
    },
    COLORS = {
        TURNIN_NPC = { 0, 1, 0 },       -- Green
        REGULAR_TARGET = { 1, 1, 1 },   -- White
        MANUAL_TARGET = { 1, 1, 0 },    -- Yellow
        NO_TARGETS = { 0.5, 0.5, 0.5 }, -- Gray
    },
    MARKERS = {
        TURNIN_NPC = 6,    -- Square
        REGULAR_TARGET = 8 -- Skull
    },
    UPDATE_INTERVAL = 0.1
}

-- Settings Manager Component
local SettingsManager = {
    Initialize = function()
        if not QuestTargetSettings then
            QuestTargetSettings = {}
        end
        if not QuestTargetSettings.framePosition then
            QuestTargetSettings.framePosition = {
                point = "CENTER",
                relativePoint = "CENTER",
                xOfs = 0,
                yOfs = 0
            }
        end
        if QuestTargetSettings.frameShown == nil then
            QuestTargetSettings.frameShown = true
        end
        if QuestTargetSettings.showCompleted == nil then
            QuestTargetSettings.showCompleted = false
        end
        if QuestTargetSettings.nextTargetKeybind == nil then
            QuestTargetSettings.nextTargetKeybind = "TAB"
        end
    end,
    SavePosition = function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
        if point then
            QuestTargetSettings.framePosition = {
                point = point,
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs
            }
        end
    end,
    RestorePosition = function(frame)
        if not QuestTargetSettings.framePosition then return end
        local pos = QuestTargetSettings.framePosition
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end
}

-- Target List Manager Component
local TargetListManager = {
    CreateTargetMacro = function(unitData)
        -- Create a targeting macro that:
        -- 1. Attempts to target the unit
        -- 2. Clears target if it's dead
        return string.format(
            "/targetexact %s\n/cleartarget [dead]",
            unitData.name)
    end
}

-- UI Component Factory
local UIFactory = {
    CreateTitleFrame = function(parent)
        local titleFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        titleFrame:SetHeight(Constants.FRAME.TITLE_HEIGHT)
        titleFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", Constants.FRAME.PADDING, -Constants.FRAME.PADDING)
        titleFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -Constants.FRAME.PADDING, -Constants.FRAME.PADDING)
        titleFrame:EnableMouse(true)
        titleFrame:RegisterForDrag("LeftButton")

        titleFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        -- Add movement handlers to title frame that control parent frame
        titleFrame:SetScript("OnDragStart", function()
            if not parent.isMoving then
                parent:StartMoving()
                parent.isMoving = true
            end
        end)
        titleFrame:SetScript("OnDragStop", function()
            if parent.isMoving then
                parent:StopMovingOrSizing()
                parent.isMoving = false
                SettingsManager.SavePosition(parent)
            end
        end)

        local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
        title:SetText("Quest Targets")
        title:SetTextColor(1, 0.82, 0)

        return titleFrame
    end,
    CreateListContainer = function(parent)
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", Constants.FRAME.PADDING,
            -(Constants.FRAME.TITLE_HEIGHT + Constants.FRAME.PADDING * 2))
        container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -Constants.FRAME.PADDING, Constants.FRAME.PADDING)
        return container
    end,
    CreateNoTargetsIndicator = function(parent)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(Constants.FRAME.MIN_WIDTH - Constants.FRAME.PADDING * 2, Constants.FRAME.BUTTON_HEIGHT)
        frame:SetPoint("CENTER", parent, "CENTER", 0, 0)

        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("No Targets")
        text:SetTextColor(unpack(Constants.COLORS.NO_TARGETS))

        frame:Hide()
        return frame
    end
}

-- Main TargetFrame Module
local TargetFrame = {
    frame = nil,
    buttons = {},
    isInitialized = false,
    currentTargetIndex = 0
}

function TargetFrame:Initialize()
    if self.isInitialized then return end

    -- Initialize settings
    SettingsManager.Initialize()

    -- Create main frame
    self:CreateFrame()

    -- Register keybinds
    self:RegisterKeybinds()

    -- Save keybinds
    self.frame:RegisterEvent("PLAYER_LOGOUT")
    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGOUT" then
            -- Save keybinds
            SaveBindings(2) -- 2 is for per-character bindings
        end
    end)

    -- Restore position and show
    SettingsManager.RestorePosition(self.frame)
    -- Delay showing until next frame to ensure secure environment is ready
    C_Timer.After(0, function()
        if QuestTargetSettings.frameShown then
            self:Show()
        end
    end)

    self.isInitialized = true
end

function TargetFrame:CreateFrame()
    if self.frame then return self.frame end

    -- Create main frame
    local frame = CreateFrame("Frame", addonName.."TargetFrame", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER")
    frame:SetSize(Constants.FRAME.MIN_WIDTH, Constants.FRAME.MIN_HEIGHT)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create child frames
    local titleFrame = UIFactory.CreateTitleFrame(frame)
    local listContainer = UIFactory.CreateListContainer(frame)
    local noTargets = UIFactory.CreateNoTargetsIndicator(listContainer)

    -- Make the list container click-through for frame dragging
    listContainer:EnableMouse(false)

    -- Setup update handler
    local lastUpdate = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate < Constants.UPDATE_INTERVAL then return end
        lastUpdate = 0

        if ns.QuestObjectives then
            local visibleUnits = ns.QuestObjectives:GetVisibleUnits()
            if visibleUnits and #visibleUnits > 0 then
                TargetFrame:UpdateButtons(visibleUnits)
            else
                TargetFrame:UpdateButtons({})
            end
        end
    end)

    -- Store references
    frame.listContainer = listContainer
    frame.noTargets = noTargets
    self.frame = frame

    return frame
end

function TargetFrame:UpdateButtons(units)
    local filteredUnits = ns.QuestObjectives:GetFilteredUnits()
    -- Clean up all existing buttons more thoroughly
    for _, button in pairs(self.buttons) do
        button:Hide()
        button:ClearAllPoints()
        button:SetParent(nil)
        button:SetMouseClickEnabled(false)
        button:SetMouseMotionEnabled(false)
        button:SetScript("OnEnter", nil)
        button:SetScript("OnLeave", nil)
        button:SetAttribute("macrotext", nil)
    end
    wipe(self.buttons) -- Use wipe instead of creating new table

    -- Show no targets if needed
    if #filteredUnits == 0 then
        self.frame.noTargets:Show()
        local contentHeight = Constants.FRAME.TITLE_HEIGHT + Constants.FRAME.BUTTON_HEIGHT +
            (Constants.FRAME.PADDING * 4)
        self.frame:SetSize(Constants.FRAME.MIN_WIDTH, contentHeight)
        return
    end

    -- Hide no targets indicator
    self.frame.noTargets:Hide()
    
    -- Calculate required width
    local requiredWidth = Constants.FRAME.MIN_WIDTH
    local textMeasure = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    for _, unitData in ipairs(filteredUnits) do
        textMeasure:SetText(unitData.name)
        local extraPadding = not unitData.isTurnInNpc and 30 or 0
        requiredWidth = math.max(requiredWidth, textMeasure:GetStringWidth() + Constants.FRAME.PADDING * 4 + extraPadding)
    end
    textMeasure:Hide()
    
    requiredWidth = math.min(requiredWidth, Constants.FRAME.MAX_WIDTH)
    -- Update frame size
    local totalButtonHeight = #filteredUnits * Constants.FRAME.BUTTON_HEIGHT +
        (#filteredUnits - 1) * Constants.FRAME.BUTTON_SPACING
    local contentHeight = Constants.FRAME.TITLE_HEIGHT + Constants.FRAME.PADDING * 5 + totalButtonHeight
    contentHeight = math.max(contentHeight, Constants.FRAME.MIN_HEIGHT)
    self.frame:SetSize(requiredWidth, contentHeight)
    
    -- Create new buttons for each unit
    for i, unitData in ipairs(filteredUnits) do
        -- Create appropriate button type
        local button = (unitData.isTurnInNpc or unitData.objectiveType == "manual") and
            ns.ButtonTypes.CreateTextButton(self.frame.listContainer) or
            ns.ButtonTypes.CreateProgressButton(self.frame.listContainer)

        -- Enable mouse interaction
        button:SetMouseClickEnabled(true)
        button:SetMouseMotionEnabled(true)

        -- Position button
        local topOffset = (i - 1) * (Constants.FRAME.BUTTON_HEIGHT + Constants.FRAME.BUTTON_SPACING)
        button:SetPoint("TOPLEFT", self.frame.listContainer, "TOPLEFT", Constants.FRAME.PADDING, -topOffset)
        button:SetPoint("TOPRIGHT", self.frame.listContainer, "TOPRIGHT", -Constants.FRAME.PADDING, -topOffset)

        -- Set up button data
        button.unitData = unitData
        button.text:SetText(unitData.name)
        
        -- Set up macro
        local macroText = TargetListManager.CreateTargetMacro(unitData)
        button:SetAttribute("macrotext", macroText)
        -- Set colors and progress
        if unitData.isTurnInNpc then
            button.text:SetTextColor(unpack(Constants.COLORS.TURNIN_NPC))
        else
            if unitData.objectiveType == "manual" then
                button.text:SetTextColor(unpack(Constants.COLORS.MANUAL_TARGET))
            else
                button.text:SetTextColor(unpack(Constants.COLORS.REGULAR_TARGET))
            end
            if button.SetProgress then
                button:SetProgress(unitData.progress or 0)
            end
        end
        
        -- Store button reference
        table.insert(self.buttons, button)
        button:Show()
    end
end

function TargetFrame:Show()
    if not self.frame then return end
    self.frame:Show()
    self.frame:SetAlpha(1)
    QuestTargetSettings.frameShown = true
end

function TargetFrame:Hide()
    if not self.frame then return end
    self.frame:Hide()
    QuestTargetSettings.frameShown = false
end

function TargetFrame:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function TargetFrame:CycleNextTarget()
    if #self.buttons == 0 then return end

    -- Increment index and wrap around
    self.currentTargetIndex = self.currentTargetIndex + 1
    if self.currentTargetIndex > #self.buttons then
        self.currentTargetIndex = 1
    end

    -- Execute the macro for the selected target
    local button = self.buttons[self.currentTargetIndex]
    if button and button:GetAttribute("macrotext") then
        RunMacroText(button:GetAttribute("macrotext"))
    end
end

function TargetFrame:RegisterKeybinds()
    -- Create a secure action button for the keybind
    local keybindButton = CreateFrame("Button", addonName .. "NextTargetButton", nil, "SecureActionButtonTemplate")
    keybindButton:RegisterForClicks("AnyDown")
    keybindButton:SetAttribute("type", "macro")
    keybindButton:SetScript("PreClick", function()
        -- Update the macro text right before the click
        if #self.buttons > 0 then
            local nextIndex = (self.currentTargetIndex % #self.buttons) + 1
            local button = self.buttons[nextIndex]
            if button then
                keybindButton:SetAttribute("macrotext", button:GetAttribute("macrotext"))
            end
        end
    end)

    keybindButton:SetScript("PostClick", function()
        self:CycleNextTarget()
    end)

    -- Set up the initial keybind
    if QuestTargetSettings.nextTargetKeybind then
        SetBinding(QuestTargetSettings.nextTargetKeybind, "CLICK " .. keybindButton:GetName() .. ":LeftButton")
    end

    -- Store the button reference
    self.keybindButton = keybindButton
end
-- Export the module
ns.TargetFrame = TargetFrame

-- Initialize immediately
TargetFrame:Initialize()

-- UI/TargetFrame.lua - Targeting frame functionality
local addonName, ns = ...

-- Constants for frame sizes and layout
local FRAME_MIN_WIDTH = 120
local FRAME_MIN_HEIGHT = 50
local FRAME_MAX_WIDTH = 200
local TITLE_HEIGHT = 16  -- Reduced from 20
local BUTTON_HEIGHT = 16
local BUTTON_SPACING = 1
local PADDING = 4

-- Create the TargetFrame module
local TargetFrame = {
    frame = nil,
    buttons = {},
    isInitialized = false
}

-- Add it to the namespace
ns.TargetFrame = TargetFrame

-- Create event frame at file level
local eventFrame = CreateFrame("Frame")

function TargetFrame:Initialize()
    if self.isInitialized then return end
    
    -- Register for events
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            -- Initialize saved variables if they don't exist
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
            -- Initialize visibility state to true by default
            if QuestTargetSettings.frameShown == nil then
                QuestTargetSettings.frameShown = true
            end

            -- Register slash command
            SLASH_TARGETFRAME1 = "/qtf"
            SlashCmdList["TARGETFRAME"] = function(msg)
                msg = msg:lower()
                if msg == "enable" then
                    self:Show()
                elseif msg == "disable" then
                    self:Hide()
                else  -- toggle or empty command
                    self:Toggle()
                end
            end

            -- Create initial frame
            self:CreateFrame()
            self:RestorePosition()

            -- Always show frame on initialization
            self:Show()

            eventFrame:UnregisterEvent("ADDON_LOADED")
            self.isInitialized = true
        end
    end)
end

-- Call Initialize immediately
TargetFrame:Initialize()

function TargetFrame:CreateFrame()
    if self.frame then return self.frame end

    -- Create main frame with unique name
    local frame = CreateFrame("Frame", addonName.."TargetFrame", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER")
    frame:SetSize(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TargetFrame:SavePosition()
    end)

    -- Add OnUpdate script with throttling
    local lastUpdate = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate < 0.1 then return end  -- Only update every 0.1 seconds
        lastUpdate = 0

        if ns.QuestObjectives then
            local visibleUnits = ns.QuestObjectives:GetVisibleUnits()
            if visibleUnits and #visibleUnits > 0 then
                TargetFrame:UpdateButtons(visibleUnits)
            else
                -- Show "No Targets" when there are no visible units
                TargetFrame:UpdateButtons({})
            end
        end
    end)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create title background frame (unnamed child frame)
    local titleFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleFrame:SetHeight(TITLE_HEIGHT)
    titleFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, TITLE_HEIGHT/2)
    titleFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, TITLE_HEIGHT/2)
    titleFrame:EnableMouse(true)  -- Enable mouse interaction
    titleFrame:RegisterForDrag("LeftButton")  -- Allow dragging
    titleFrame:SetScript("OnDragStart", function() frame:StartMoving() end)  -- Start parent frame movement
    titleFrame:SetScript("OnDragStop", function() 
        frame:StopMovingOrSizing()
        TargetFrame:SavePosition()
    end)
    titleFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })

    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    title:SetText("Quest Targets")
    title:SetTextColor(1, 0.82, 0) -- Gold color

    -- Create list container (unnamed child frame)
    local listContainer = CreateFrame("Frame", nil, frame)
    listContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -(TITLE_HEIGHT/2))
    listContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)

    -- Create the "No Targets" indicator
    local noTargets = CreateFrame("Frame", nil, listContainer)
    noTargets:SetHeight(BUTTON_HEIGHT)
    noTargets:SetPoint("TOPLEFT", listContainer, "TOPLEFT", PADDING, -PADDING)
    noTargets:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -PADDING, -PADDING)
    local noTargetsText = noTargets:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noTargetsText:SetPoint("CENTER")
    noTargetsText:SetText("No Targets")
    noTargetsText:SetTextColor(0.5, 0.5, 0.5) -- Gray color
    noTargets:Hide()

    frame.listContainer = listContainer
    frame.noTargets = noTargets
    self.frame = frame
    self.buttons = {}

    frame:Hide()
    return frame
end

function TargetFrame:UpdateButtons(nearbyUnits)
    if not self.frame or not self.frame.listContainer then return end

    -- Hide all existing buttons
    for _, button in pairs(self.buttons) do
        button:Hide()
    end

    -- If no units, show "No Targets" message and adjust frame size
    if #nearbyUnits == 0 then
        self.frame.noTargets:Show()
        local contentHeight = TITLE_HEIGHT + BUTTON_HEIGHT + (PADDING * 2)
        self.frame:SetSize(FRAME_MIN_WIDTH, contentHeight)
        return
    end

    -- Hide "No Targets" indicator if we have units
    self.frame.noTargets:Hide()

    -- Sort units: turn-in NPCs first, then other targets
    table.sort(nearbyUnits, function(a, b)
        if a.isTurnInNpc ~= b.isTurnInNpc then
            return a.isTurnInNpc
        end
        return a.name < b.name
    end)

    -- Calculate required width based on text with smaller font
    local requiredWidth = FRAME_MIN_WIDTH
    local textMeasure = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    for _, unitData in ipairs(nearbyUnits) do
        textMeasure:SetText(unitData.name)
        requiredWidth = math.max(requiredWidth, textMeasure:GetStringWidth() + PADDING * 3)
    end
    textMeasure:Hide()
    requiredWidth = math.min(requiredWidth, FRAME_MAX_WIDTH)

    -- Calculate required height with tighter spacing
    local contentHeight = TITLE_HEIGHT + (#nearbyUnits * (BUTTON_HEIGHT + BUTTON_SPACING)) + PADDING

    -- Update frame size
    self.frame:SetSize(requiredWidth, contentHeight)

    -- Create/update buttons
    for i, unitData in ipairs(nearbyUnits) do
        local button = self.buttons[i]
        if not button then
            button = self:CreateButton(i)
        end

        local y = -(BUTTON_HEIGHT + BUTTON_SPACING) * (i - 1)
        button:SetPoint("TOPLEFT", self.frame.listContainer, "TOPLEFT", 0, y)
        button:SetPoint("TOPRIGHT", self.frame.listContainer, "TOPRIGHT", 0, y)
        button:SetHeight(BUTTON_HEIGHT)

        button.unitData = unitData
        button.text:SetText(unitData.name)

        -- Set up targeting macro for both left and right click
        local macroText
        if unitData.isTurnInNpc then
            -- For turn-in NPCs, use Square (6)
            macroText = string.format("/targetexact %s\n/run SetRaidTarget(\"target\", 6)", unitData.name)
            button.text:SetTextColor(0, 1, 0) -- Green for turn-in NPCs
            button.isTurnInNPC = true
        else
            -- For regular targets, use Skull (8)
            macroText = string.format("/targetexact %s\n/run SetRaidTarget(\"target\", 8)", unitData.name)
            button.text:SetTextColor(1, 1, 1) -- White for regular targets
            button.isTurnInNPC = false
        end

        button:SetAttribute("macrotext1", macroText) -- Left click
        button:SetAttribute("macrotext2", macroText) -- Right click (backup targeting)
        button:Show()
    end
end

function TargetFrame:CreateButton(index)
    -- Create secure button for targeting
    local button = CreateFrame("Button", addonName.."TargetButton"..index, self.frame.listContainer, "SecureActionButtonTemplate")
    button:SetHeight(BUTTON_HEIGHT)
    button:SetPoint("LEFT", 0, 0)
    button:SetPoint("RIGHT", 0, 0)

    -- Set up secure targeting
    button:SetAttribute("type1", "macro")
    button:SetAttribute("type2", "macro")
    button:RegisterForClicks("AnyDown")

    -- Create text label with smaller font
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 4, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)  -- Prevent text wrapping
    text:SetHeight(BUTTON_HEIGHT)  -- Force single line height
    button.text = text

    -- Create hover highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.2)

    -- Create background for better visibility
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.2)

    button:SetScript("OnEnter", function(self)
        if not self.unitData then return end
        self.text:SetTextColor(1, 1, 0)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.unitData.name, 1, 1, 1)
        if self.unitData.isTurnInNpc then
            GameTooltip:AddLine("Quest Turn-in NPC", 0, 1, 0)
        else
            GameTooltip:AddLine("Quest Target", 1, 0.82, 0)
        end
        if self.unitData.lastSeen then
            GameTooltip:AddLine(string.format("Last seen: %.1f seconds ago", GetTime() - self.unitData.lastSeen))
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        if self.isTurnInNPC then
            self.text:SetTextColor(0, 1, 0)
        else
            self.text:SetTextColor(1, 1, 1)
        end
        GameTooltip:Hide()
    end)

    self.buttons[index] = button
    return button
end

function TargetFrame:SavePosition()
    if not self.frame then return end

    local point, _, relativePoint, xOfs, yOfs = self.frame:GetPoint()
    if point then
        QuestTargetSettings.framePosition = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end
end

function TargetFrame:RestorePosition()
    if not self.frame or not QuestTargetSettings.framePosition then return end

    local pos = QuestTargetSettings.framePosition
    self.frame:ClearAllPoints()
    self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
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


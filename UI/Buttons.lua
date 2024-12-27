--[[
    Button Types Module
    Provides reusable button components for the UI.
]]

local addonName, ns = ...
ns = ns or {}

-- Constants for button sizes and layout
local BUTTON_HEIGHT = 16
local BUTTON_SPACING = 1
local PADDING = 4

local ButtonTypes = {
    --[[
        Creates a basic text button
        @param parent Frame - The parent frame
        @param text string - The button text
        @param textColor table - RGB color table {r, g, b}
        @return Button - The created button
    ]]
    CreateTextButton = function(parent, text, textColor)
        -- Create secure button for targeting
        local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
        button:SetHeight(BUTTON_HEIGHT)

        -- Set up secure targeting
        button:SetAttribute("type1", "macro")
        button:SetAttribute("type2", "macro")
        button:RegisterForClicks("AnyDown")

        -- Create text label with smaller font
        local textLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        textLabel:SetPoint("LEFT", 4, 0)
        textLabel:SetPoint("RIGHT", -4, 0)
        textLabel:SetJustifyH("LEFT")
        textLabel:SetWordWrap(false)       -- Prevent text wrapping
        textLabel:SetHeight(BUTTON_HEIGHT) -- Force single line height
        button.text = textLabel

        -- Create hover highlight
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.2)

        -- Create background for better visibility
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.2)

        -- Set initial text and color
        textLabel:SetText(text or "")
        if textColor then
            textLabel:SetTextColor(unpack(textColor))
        end

        -- Add hover color change and tooltip
        button:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 0) -- Yellow on hover

            -- Show tooltip if we have unit data
            if self.unitData then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(self.unitData.name, 1, 1, 1)
                if self.unitData.isTurnInNpc then
                    GameTooltip:AddLine("Turn in Quest", 0, 1, 0)
                end
                GameTooltip:Show()
            end
        end)

        button:SetScript("OnLeave", function(self)
            if textColor then
                self.text:SetTextColor(unpack(textColor))
            else
                self.text:SetTextColor(1, 1, 1) -- Default white
            end
            GameTooltip:Hide()
        end)

        return button
    end,

    --[[
        Creates a button with text and a thin progress bar below
        @param parent Frame - The parent frame
        @param text string - The button text
        @param textColor table - RGB color table {r, g, b}
        @return Button - The created button with progress functionality
    ]]
    CreateProgressButton = function(parent, text, textColor)
        -- Create base button
        local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
        button:SetHeight(BUTTON_HEIGHT)

        -- Set up secure targeting
        button:SetAttribute("type1", "macro")
        button:SetAttribute("type2", "macro")
        button:RegisterForClicks("AnyDown")

        -- Create text label with smaller font
        local textLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        textLabel:SetPoint("LEFT", 4, 1) -- Slight offset up to make room for progress bar
        textLabel:SetPoint("RIGHT", -4, 1)
        textLabel:SetJustifyH("LEFT")
        textLabel:SetWordWrap(false)
        button.text = textLabel

        -- Create hover highlight
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.2)

        -- Create background for better visibility
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.2)

        -- Create progress bar background (grey line)
        local progressBg = button:CreateTexture(nil, "ARTWORK")
        progressBg:SetHeight(1)
        progressBg:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 1)
        progressBg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 1)
        progressBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)

        -- Create progress bar fill (blue line)
        local progressFill = button:CreateTexture(nil, "ARTWORK", nil, 1)
        progressFill:SetHeight(1)
        progressFill:SetPoint("BOTTOMLEFT", progressBg, "BOTTOMLEFT", 0, 0)
        progressFill:SetColorTexture(0, 1, 0, 1) -- Green color
        progressFill:SetWidth(0)                 -- Start at 0 progress

        button.progressFill = progressFill
        button.progressBg = progressBg

        -- Set initial text and color
        textLabel:SetText(text or "")
        if textColor then
            textLabel:SetTextColor(unpack(textColor))
        end

        -- Add hover color change and tooltip
        button:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 0) -- Yellow on hover

            -- Show tooltip if we have unit data
            if self.unitData then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(self.unitData.name, 1, 1, 1)
                if self.unitData.questName then
                    GameTooltip:AddLine(self.unitData.questName, 0.8, 0.8, 0.8)
                end
                if self.unitData.objectiveName then
                    local objectiveType = self.unitData.objectiveType == "kill" and "Kill" or "Collect"
                    local progress = self.unitData.progress or 0
                    GameTooltip:AddLine(
                        string.format("%s: %s (%d%%)", objectiveType, self.unitData.objectiveName, progress), 1, 0.82, 0)
                end
                GameTooltip:Show()
            end
        end)

        button:SetScript("OnLeave", function(self)
            if textColor then
                self.text:SetTextColor(unpack(textColor))
            else
                self.text:SetTextColor(1, 1, 1) -- Default white
            end
            GameTooltip:Hide()
        end)

        -- Add progress functionality
        button.SetProgress = function(self, progress)
            if not self.progressFill then return end
            progress = progress or 0

            -- Update color based on progress (brighter as progress increases)
            local r, g, b = 0, 1, 0  -- Default green
            if progress < 33 then
                r, g, b = 0, 0.5, 0  -- Darker green for low progress
            elseif progress < 66 then
                r, g, b = 0, 0.75, 0 -- Medium green for medium progress
            else
                r, g, b = 0, 1, 0    -- Bright green for high progress
            end

            -- Update progress bar width and color
            local totalWidth = self.progressBg:GetWidth()
            self.progressFill:SetWidth(totalWidth * (progress / 100))
            self.progressFill:SetColorTexture(r, g, b, 1)
        end

        return button
    end
}

ns.ButtonTypes = ButtonTypes
return ButtonTypes

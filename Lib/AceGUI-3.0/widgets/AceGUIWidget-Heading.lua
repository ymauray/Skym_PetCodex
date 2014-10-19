-- Copyright (c) 2014 Yannick Mauray.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

--[[-----------------------------------------------------------------------------
Heading Widget
-------------------------------------------------------------------------------]]
local Type, Version = "Heading", 20
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetText()
        self:SetFullWidth()
        self:SetHeight(18)
    end,

    -- ["OnRelease"] = nil,

    ["SetText"] = function(self, text)
        self.label:SetText(text or "")
        if text and text ~= "" then
            self.left:SetPoint("RIGHT", self.label, "LEFT", -5, 0)
            self.right:Show()
        else
            self.left:SetPoint("RIGHT", -3, 0)
            self.right:Hide()
        end
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    label:SetPoint("TOP")
    label:SetPoint("BOTTOM")
    label:SetJustifyH("CENTER")

    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetHeight(8)
    left:SetPoint("LEFT", 3, 0)
    left:SetPoint("RIGHT", label, "LEFT", -5, 0)
    left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    left:SetTexCoord(0.81, 0.94, 0.5, 1)

    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetHeight(8)
    right:SetPoint("RIGHT", -3, 0)
    right:SetPoint("LEFT", label, "RIGHT", 5, 0)
    right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    right:SetTexCoord(0.81, 0.94, 0.5, 1)

    local widget = {
        label = label,
        left = left,
        right = right,
        frame = frame,
        type = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

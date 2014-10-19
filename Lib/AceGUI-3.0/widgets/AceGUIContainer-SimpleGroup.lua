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
SimpleGroup Container
Simple container widget that just groups widgets.
-------------------------------------------------------------------------------]]
local Type, Version = "SimpleGroup", 20
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
        self:SetWidth(300)
        self:SetHeight(100)
    end,

    -- ["OnRelease"] = nil,

    ["LayoutFinished"] = function(self, width, height)
        if self.noAutoHeight then return end
        self:SetHeight(height or 0)
    end,
    ["OnWidthSet"] = function(self, width)
        local content = self.content
        content:SetWidth(width)
        content.width = width
    end,
    ["OnHeightSet"] = function(self, height)
        local content = self.content
        content:SetHeight(height)
        content.height = height
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    --Container Support
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT")
    content:SetPoint("BOTTOMRIGHT")

    local widget = {
        frame = frame,
        content = content,
        type = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

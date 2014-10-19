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

local LibStub = LibStub
local MAJOR, MINOR = "SkymFramework-0.1.0", 1
local SkymFramework, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not SkymFramework then return end -- No Upgrade needed.

-- Référence à AceGUI

local gui = LibStub("AceGUI-3.0")

local handlers = {}

local NEXT_WIDGET_ID = 1

function SkymFramework:addListener(eventName, closure)
    handlers[eventName] = handlers[eventName] or {}
    handlers[eventName][#handlers[eventName] + 1] = closure
    return #handlers[eventName]
end

function SkymFramework:removeListener(eventName, handler)
    handlers[eventName][handler] = nil
end

function SkymFramework:fireEvent(eventName, ...)
    for _, handler in pairs(handlers[eventName] or {}) do
        handler(...)
    end
end

function SkymFramework:createComponent(o)
    o.meta = { id = NEXT_WIDGET_ID, listeners = nil }

    o.addListener = function(self, eventName, closure)
        self.meta.listeners = self.meta.listeners or {}
        self.meta.listeners[eventName] = self.meta.listeners[eventName] or {}
        self.meta.listeners[eventName][#self.meta.listeners[eventName] + 1] = closure
        handlers[eventName] = handlers[eventName] or {}
        handlers[eventName]["h" .. self.meta.id] = self
    end

    o.fireEvent = function(self, eventName, ...)
        local handler = handlers[eventName] or {}
        for _, widget in pairs(handler) do
            for _, closure in pairs(widget.meta.listeners[eventName]) do
                closure(self, widget, ...)
            end
        end
    end

    local onHide = o.frame:GetScript("OnHide")
    o.frame:SetScript("OnHide", function(frame)
        if o.meta.listeners then
            for eventName, _ in pairs(o.meta.listeners) do
                handlers[eventName]["h" .. o.meta.id] = nil
            end
        end
        if onHide then
            onHide(o.frame)
        end
    end)

    NEXT_WIDGET_ID = NEXT_WIDGET_ID + 1

    return o
end

function SkymFramework:createInlineGroup()
    local widget = self:createComponent(gui:Create("InlineGroup"))

    return widget
end

function SkymFramework:createCheckBox()
    local widget = self:createComponent(gui:Create("CheckBox"))

    return widget
end

function SkymFramework:createScrollFrame()
    local widget = self:createComponent(gui:Create("ScrollFrame"))

    return widget
end

function SkymFramework:createButton()
    local widget = self:createComponent(gui:Create("Button"))

    return widget
end

function SkymFramework:createEditBox()
    local widget = self:createComponent(gui:Create("EditBox"))

    return widget
end

function SkymFramework:createLabel()
    local widget = self:createComponent(gui:Create("Label"))

    return widget
end

function SkymFramework:createInteractiveLabel()
    local widget = self:createComponent(gui:Create("InteractiveLabel"))

    return widget
end

function SkymFramework:createFrame()
    local widget = self:createComponent(gui:Create("Frame"))

    return widget
end

function SkymFramework:createSimpleGroup()
    local widget = self:createComponent(gui:Create("SimpleGroup"))

    return widget
end

function SkymFramework:createDropdown()
    local widget = self:createComponent(gui:Create("Dropdown"))

    return widget
end

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

--- AceConfig-3.0 wrapper library.
-- Provides an API to register an options table with the config registry,
-- as well as associate it with a slash command.
-- @class file
-- @name AceConfig-3.0
-- @release $Id: AceConfig-3.0.lua 969 2010-10-07 02:11:48Z shefki $

--[[
AceConfig-3.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

]]

local MAJOR, MINOR = "AceConfig-3.0", 2
local AceConfig = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfig then return end

local cfgreg = LibStub("AceConfigRegistry-3.0")
local cfgcmd = LibStub("AceConfigCmd-3.0")
--TODO: local cfgdlg = LibStub("AceConfigDialog-3.0", true)
--TODO: local cfgdrp = LibStub("AceConfigDropdown-3.0", true)

-- Lua APIs
local pcall, error, type, pairs = pcall, error, type, pairs

-- -------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, slashcmd, persist)
--
-- - appName - (string) application name
-- - options - table or function ref, see AceConfigRegistry
-- - slashcmd - slash command (string) or table with commands, or nil to NOT create a slash command

--- Register a option table with the AceConfig registry.
-- You can supply a slash command (or a table of slash commands) to register with AceConfigCmd directly.
-- @paramsig appName, options [, slashcmd]
-- @param appName The application name for the config table.
-- @param options The option table (or a function to generate one on demand).  http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- @param slashcmd A slash command to register for the option table, or a table of slash commands.
-- @usage
-- local AceConfig = LibStub("AceConfig-3.0")
-- AceConfig:RegisterOptionsTable("MyAddon", myOptions, {"/myslash", "/my"})
function AceConfig:RegisterOptionsTable(appName, options, slashcmd)
    local ok, msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options)
    if not ok then error(msg, 2) end

    if slashcmd then
        if type(slashcmd) == "table" then
            for _, cmd in pairs(slashcmd) do
                cfgcmd:CreateChatCommand(cmd, appName)
            end
        else
            cfgcmd:CreateChatCommand(slashcmd, appName)
        end
    end
end

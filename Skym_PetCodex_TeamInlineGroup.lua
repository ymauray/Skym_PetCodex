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

-- Init module

Skym_PetCodex_TeamInlineGroup = Skym_PetCodex:NewModule("Skym_PetCodex_TeamInlineGroup", "AceEvent-3.0")

-- Reference to AceGUI

local gui = LibStub("AceGUI-3.0")

RARITY_COLOR = {
    [1] = "|cff9a9a9a",
    [2] = "|cffffffff",
    [3] = "|cff1eff00",
    [4] = "|cff0070dc",
    [5] = "|cff0070dc",
    [6] = "|cff0070dc"
}

-- --------------------------------------------------------------------------------------

local SimpleIconType, SimpleIconVersion = "SimpleIcon", 23

local simpleIconMethods = {
    ["OnAcquire"] = function(self)
        self.bgTexture:SetAllPoints(true)
    end,
    ["SetTexture"] = function(self, path)
        self.bgTexture:SetTexture(path)
    end
}

local function SimpleIconConstructor()
    local name = "AceGUI30SimpleIcon" .. gui:GetNextWidgetNum(SimpleIconType)
    local frame = CreateFrame("Frame", name, UIParent)

    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(true)

    local widget = {
        frame = frame,
        bgTexture = bgTexture,
        -- /pink
        type = SimpleIconType
    }

    for method, func in pairs(simpleIconMethods) do
        widget[method] = func
    end

    return gui:RegisterAsWidget(widget)
end

gui:RegisterWidgetType(SimpleIconType, SimpleIconConstructor, SimpleIconVersion)

-- --------------------------------------------------------------------------------------

local PetIconType, PetIconVersion = "PetIcon", 23

local petIconMethods = {
    ["OnAcquire"] = function(self)
        self.texture:SetPoint("TOPLEFT", self.frame, 5, -5)
        self.texture:SetPoint("BOTTOMRIGHT", self.frame, -3, 3)
    end,
    ["SetTexture"] = function(self, path)
        self.texture:SetTexture(path)
    end,
    ["SetBackgroundTexture"] = function(self, path)
        self.bgTexture:SetTexture(path)
    end,
    ["SetBackgroundTexCoord"] = function(self, left, right, top, bottom)
        self.bgTexture:SetTexCoord(left, right, top, bottom)
    end
}

local function PetIconConstructor()
    local name = "AceGUI30PetIcon" .. gui:GetNextWidgetNum(PetIconType)
    local frame = CreateFrame("Frame", name, UIParent)

    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(true)
    bgTexture:SetTexture("Interface\\PetBattles\\PetJournal")
    bgTexture:SetTexCoord(0.421875, 0.515625, 0.0234375, 0.0703125)

    local texture = frame:CreateTexture(nil, "ARTWORK")

    local widget = {
        frame = frame,
        bgTexture = bgTexture,
        texture = texture,
        type = PetIconType
    }

    for method, func in pairs(petIconMethods) do
        widget[method] = func
    end

    return gui:RegisterAsWidget(widget)
end

gui:RegisterWidgetType(PetIconType, PetIconConstructor, PetIconVersion)

-- --------------------------------------------------------------------------------------

local AbilitySelectionButtonType, AbilitySelectionButtonVersion = "AbilitySelectionButton", 23

local spellSelectionButtonMethods = {
    ["OnAcquire"] = function(self)
        self.background:SetAllPoints(true)
        self.artwork:SetPoint("TOPLEFT", self.frame, 1, -1)
        self.artwork:SetPoint("BOTTOMRIGHT", self.frame, -1, 1)
        self.arrow:SetPoint("BOTTOM", self.frame, 0, -3)
        self.list:SetPoint("TOP", self.frame, "BOTTOM", 0, 0)
    end,
    ["OnWidthSet"] = function(self)
        self.list:SetWidth(self.frame.width or self.frame:GetWidth() or 0)
    end,
    ["SetAbility"] = function(self, index, path, abilityId, speciesID, petID)
        self.abilitiesInfo[index] = { path = path, id = abilityId, speciesID = speciesID, petID = petID }
    end,
    ["SetSelectedAbility"] = function(self, index)
        self.artwork:SetTexture(self.abilitiesInfo[index].path)
        self.selectedAbilityIndex = index
    end
}

local function AbilitySelectionButton_OnClick(frame, ...)
    local self = frame.obj
    if self.frame:GetChecked() == nil then
        self.list:Hide()
    else
        self.list:Show()
    end
end

local PaneBackdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local function AbilitySelectionButtonConstructor()
    local name = "AceGUI30PetAbilitySelectionButton" .. gui:GetNextWidgetNum(AbilitySelectionButtonType)
    local frame = CreateFrame("CheckButton", name, UIParent)
    frame:EnableMouse(true)
    frame:SetScript("OnClick", AbilitySelectionButton_OnClick)
    frame:SetScript("OnEnter", function(frame, ...)
        local self = frame.obj
        PetJournal_ShowAbilityTooltip(frame, self.abilitiesInfo[self.selectedAbilityIndex].id, self.abilitiesInfo[self.selectedAbilityIndex].speciesID, self.abilitiesInfo[self.selectedAbilityIndex].petID)
    end)
    frame:SetScript("OnLeave", function(frame, ...)
        local self = frame.obj
        PetJournal_HideAbilityTooltip(frame)
    end)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Spellbook\\Spellbook-Parts")
    background:SetTexCoord(0.79296875, 0.96093750, 0.00390625, 0.17187500)

    local artwork = frame:CreateTexture(nil, "ARTWORK")
    local abilitiesInfo = { nil, nil }

    local arrow = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    arrow:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    arrow:SetTexCoord(0.62500000, 0.98437500, 0.82812500, 0.74218750)
    arrow:SetSize(23, 11)

    local list = CreateFrame("Frame", nil, frame)
    list:SetHeight(50)
    list:Hide()

    local border = CreateFrame("Frame", nil, list)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", 0, 0)
    border:SetBackdrop(PaneBackdrop)
    border:SetBackdropColor(0.1, 0.1, 0.1)
    border:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local content = CreateFrame("Frame", nil, border)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", 0, 0)

    --list.red = list:CreateTexture(nil, "ARTWORK")
    --list.red:SetAllPoints(true)
    --list.red:SetTexture(1.0, 0.0, 0.0)

    local icon1 = CreateFrame("Frame", nil, list)
    icon1.texture = icon1:CreateTexture(nil, "ARTWORK")

    local icon2 = CreateFrame("Frame", nil, list)
    icon2.texture = icon2:CreateTexture(nil, "ARTWORK")

    local widget = {
        frame = frame,
        background = background,
        artwork = artwork,
        abilitiesInfo = abilitiesInfo,
        arrow = arrow,
        list = list,
        type = AbilitySelectionButtonType
    }

    for method, func in pairs(spellSelectionButtonMethods) do
        widget[method] = func
    end

    return gui:RegisterAsWidget(widget)
end

gui:RegisterWidgetType(AbilitySelectionButtonType, AbilitySelectionButtonConstructor, AbilitySelectionButtonVersion)

-- --------------------------------------------------------------------------------------

Skym_PetCodex_TeamInlineGroup = {}

function Skym_PetCodex_TeamInlineGroup:create(o)

    local ig = gui:Create("InlineGroup")
    setmetatable(Skym_PetCodex_TeamInlineGroup, { __index = ig })

    local newInstance = o or {}
    setmetatable(newInstance, { __index = Skym_PetCodex_TeamInlineGroup })

    newInstance:SetTitle("Equipe")
    newInstance:SetFullWidth(true)
    newInstance:SetLayout("List")

    self.items = {}

    for i = 1, 3 do
        local group = gui:Create("SimpleGroup")
        group:SetFullWidth(true)
        group:SetLayout("Flow")

        local icon = gui:Create("PetIcon")
        icon:SetWidth(30)
        icon:SetHeight(30)

        group:AddChild(icon)

        local nameGroup = gui:Create("SimpleGroup")
        nameGroup:SetLayout("List")
        nameGroup:SetWidth(125)

        local nameLabel = gui:Create("Label")
        nameLabel:SetText("<vide>")
        nameLabel:SetFullWidth(true)

        nameGroup:AddChild(nameLabel)

        local healthLabel = gui:Create("Label")
        healthLabel:SetText("??? / ???")
        healthLabel:SetImage("Interface\\PetBattles\\PetBattle-StatIcons", 0.5, 1.0, 0.5, 1.0)
        healthLabel:SetImageSize(12, 12)
        healthLabel:SetFullWidth(true)

        nameGroup:AddChild(healthLabel)

        group:AddChild(nameGroup)

        local ability1 = gui:Create("AbilitySelectionButton")
        ability1:SetWidth(29)
        ability1:SetHeight(29)

        group:AddChild(ability1)

        local ability2 = gui:Create("AbilitySelectionButton")
        ability2:SetWidth(29)
        ability2:SetHeight(29)

        group:AddChild(ability2)

        local ability3 = gui:Create("AbilitySelectionButton")
        ability3:SetWidth(29)
        ability3:SetHeight(29)

        group:AddChild(ability3)

        self.items[i] = { group = group, icon = icon, nameLabel = nameLabel, healthLabel = healthLabel, abilities = { ability1, ability2, ability3 } }

        newInstance:AddChild(group)
    end

    return newInstance
end

function Skym_PetCodex_TeamInlineGroup:setTeam(team)
    for i = 1, 3 do
        local pet = team[i]
        if pet ~= nil then
            local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(pet.petID)
            --print(speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable)
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(pet.petID)
            --print(health, maxHealth, power, speed, rarity)
            local idTable, levelTable = C_PetJournal.GetPetAbilityList(speciesID)

            self.items[i].icon:SetTexture(icon)
            self.items[i].nameLabel:SetText(RARITY_COLOR[rarity] .. (customName or name) .. "|r (" .. level .. ")")
            self.items[i].healthLabel:SetText(health .. " / " .. maxHealth)
            pet.attacks = pet.attacks or {}
            for a = 1, 3 do
                local abilityIndex = pet.attacks[a]
                if abilityIndex ~= nil then
                    local abilityId = idTable[a]
                    local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityId)
                    self.items[i].abilities[a]:SetAbility(1, abilityIcon, abilityId, speciesID, pet.petID)

                    abilityId = idTable[a + 3]
                    abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityId)
                    self.items[i].abilities[a]:SetAbility(2, abilityIcon, abilityId, speciesID, pet.petID)

                    self.items[i].abilities[a]:SetSelectedAbility(abilityIndex)
                end
            end
        else
            print "heu.."
        end
    end
end

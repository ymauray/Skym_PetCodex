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

Skym_PetCodex_MainFrame = Skym_PetCodex:NewModule("Skym_PetCodex_MainFrame", "AceEvent-3.0")

-- Reference to AceGUI

local acegui = LibStub("AceGUI-3.0")

local gui = {}
setmetatable(gui, { __index = acegui })

-- Init module variables

local mainFrame = nil

-- _G["BATTLE_PET_BREED_QUALITY" .. n] 2=Commun, 4=rare
-- _G["BATTLE_PET_NAME_" .. n] 10=machine, 2=Draconien, 5=Bestiole, 8=Bête, 4=Mort-vivant
-- _G["BATTLE_PET_DAMAGE_NAME_" .. n] 7 élémentaires, 4 de mort-vivant, 1 d'humanoïde, 2=draconique
-- _G["TOOLTIPE_BATTLE_PET"] = Mascotte de combat

-- _G["PET_BATTLE_PET_TYPE_PASSIVES"]
-- 

local Model = {}

function Model:setValue(property, value)
    print("Model:setValue(" .. property .. ", ...)")
    local oldValue = self[property]
    self[property] = value
    self.listeners = self.listeners or {}
    local propertyListeners = self.listeners[property] or {}
    for _, listener in pairs(propertyListeners) do
        listener(oldValue, newValue)
    end
end

function Model:addPropertyChangeListener(property, listener)
    print("Adding property listener on " .. property)
    self.listeners = self.listeners or {}
    self.listeners[property] = self.listeners[property] or {}
    tinsert(self.listeners[property], listener)
    -- /pink
end

function Skym_PetCodex_MainFrame:showFrame()

    C_PetJournal.AddAllPetSourcesFilter()
    C_PetJournal.AddAllPetTypesFilter()
    C_PetJournal.ClearSearchFilter()

    local numPets, numOwned = C_PetJournal.GetNumPets()
    for index = 1, numOwned do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
        if canBattle then
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
        end
    end

    -- Get info for target pet
    local targetPetName = UnitName("target")
    local targetSpeciesID, targetPetGUID = C_PetJournal.FindPetIDByName(targetPetName)
    --local targetSpeciesID, customName, level, xp, maxXp, displayID, petName, petIcon, petType, creatureID = C_PetJournal.GetPetInfoByPetID(targetPetGUID)

    --local targetPetLink = C_PetJournal.GetBattlePetLink(targetPetGUID)
    --local _, _, _, breedQuality, maxHealth, power, speed, _ = strsplit(":", targetPetLink)

    local targetSpeciesName, targetSpeciesIcon, targetPetType, targetCompanionID, targetTooltipSource, targetTooltipDescription, targetIsWild, targetCanBattle, targetIsTradeable, targetIsUnique, targetObtainable = C_PetJournal.GetPetInfoBySpeciesID(targetSpeciesID)
    local targetPetAbilitiesIDTable, targetPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(targetSpeciesID)
    local targetPetTypeName = _G["BATTLE_PET_NAME_" .. targetPetType]

    -- Get target pet attacks

    local targetPetAttacks = {}
    for _, abilityID in pairs(targetPetAbilitiesIDTable) do
        local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
        local abilityID, abilityName, abilityIcon, abilityMaxCooldown, abilityUnparsedDescription, abilityNumTurns, abilityPetType, abilityNoStrongWeakHints = C_PetBattles.GetAbilityInfoByID(abilityID)
        -- print(abilityID, abilityName, abilityIcon, abilityMaxCooldown, abilityUnparsedDescription, abilityNumTurns, abilityPetType, abilityNoStrongWeakHints)
        targetPetAttacks[#targetPetAttacks + 1] = {
            id = abilityID,
            name = abilityName,
            icon = abilityIcon,
            maxCooldown = abilityMaxCooldown,
            unparsedDescription = abilityUnparsedDescription,
            numTurns = abilityNumTurns,
            petType = abilityPetType,
            type = abilityType,
            noStrongWeakHints = abilityNoStrongWeakHints
        }
    end

    if mainFrame == nil then

        -- Main frame
        local window = gui:Create("Window")
        setmetatable(Model, { __index = window })
        mainFrame = {}
        setmetatable(mainFrame, { __index = Model })

        --window:SetTitle("Skym : Pet Codex v0.1.0 - © 2013-2014 Kraäl Jenkins")
        mainFrame:SetTitle("| Skym : Pet Codex |")
        mainFrame:SetLayout("List")
        mainFrame:SetWidth(640)
        mainFrame:SetHeight(640)

        -- Target pet
        local targetPetIG = gui:Create("InlineGroup")
        targetPetIG:SetTitle("Cible : " .. targetPetName .. " (" .. targetPetTypeName .. ")")
        targetPetIG:SetFullWidth(true)
        targetPetIG:SetLayout("Flow")

        local targetPetIcon = gui:Create("Icon")
        targetPetIcon:SetImage(targetSpeciesIcon)

        targetPetIG:AddChild(targetPetIcon)

        local targetPetInfo = gui:Create("SimpleGroup")
        targetPetInfo:SetLayout("Flow")
        targetPetInfo.width = "grow"

        local attackNameLabels = {}
        for _, attack in ipairs(targetPetAttacks) do
            local group = gui:Create("SimpleGroup")
            group:SetRelativeWidth(.3333)
            group:SetLayout("Flow")
            local icon = gui:Create("Icon")
            icon:SetImageSize(16, 16)
            icon:SetImage(attack.icon)
            icon:SetWidth(21)
            icon:SetCallback("OnEnter", function() PetJournal_ShowAbilityTooltip(icon.frame, attack.id, targetSpeciesID, targetPetGUID) end)
            icon:SetCallback("OnLeave", function() PetJournal_HideAbilityTooltip(icon.frame) end)
            local attackNameLabel = gui:Create("Label")
            attackNameLabel:SetText(attack.name)
            attackNameLabel.width = "grow"

            group:AddChildren(icon, attackNameLabel)
            attackNameLabels[#attackNameLabels + 1] = group
        end

        targetPetInfo:AddChildren(unpack(attackNameLabels))

        targetPetIG:AddChild(targetPetInfo)

        mainFrame:AddChild(targetPetIG)

        -- Associated team
        local teamIG = Skym_PetCodex_TeamInlineGroup:create()
        mainFrame:addPropertyChangeListener("team", function()
            teamIG:setTeam(mainFrame.team)
        end)
        mainFrame:AddChild(teamIG)

        -- Options
        local optionsIG = gui:Create("InlineGroup")
        optionsIG:SetTitle("Options")
        optionsIG:SetFullWidth(true)
        mainFrame:AddChild(optionsIG)

        -- Bottom section : strong pets and pets weak against the target
        local bottomSG = gui:Create("SimpleGroup")
        bottomSG:SetFullWidth(true)
        bottomSG:SetLayout("Flow")

        local strongPetsIG = gui:Create("InlineGroup")
        strongPetsIG:SetTitle("Mascottes efficaces")
        strongPetsIG:SetRelativeWidth(.5)
        bottomSG:AddChild(strongPetsIG)

        local weakPetsIG = gui:Create("InlineGroup")
        weakPetsIG:SetTitle("Mascottes peu sensible")
        weakPetsIG:SetRelativeWidth(.5)
        bottomSG:AddChild(weakPetsIG)

        mainFrame:AddChild(bottomSG)
    end

    local team = Skym_PetCodex.db.global.teams[targetSpeciesID] or {}

    mainFrame:setValue("team", team)

    mainFrame:Show()

    --	for k,v in pairs(_G) do
    --		if (k:match("BATTLE_PET.*")) then
    --			print(k, v)
    --		end
    --	end
end

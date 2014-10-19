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

-- Initialisation

Skym_PetCodex_Frame = Skym_PetCodex:NewModule("Skym_PetCodex_Frame", "AceEvent-3.0")

-- Référence à AceGUI

local gui = LibStub("AceGUI-3.0")

-- Référence à SkymFramework

local sk = LibStub("SkymFramework-0.1.0")


-- Table des types de mascottes

local TYPES_MASCOTTE = {
    [1] = "Humanoid",
    [2] = "Dragon",
    [3] = "Flying",
    [4] = "Undead",
    [5] = "Critter",
    [6] = "Magical",
    [7] = "Elemental",
    [8] = "Beast",
    [9] = "Water",
    [10] = "Mechanical",
}

-- Table des types d'attaque

local TYPES_ATTAQUE = {
    Mechanical = {
        fort = "Beast",
        faible = "Elemental"
    },
    Elemental = {
        fort = "Mechanical",
        faible = "Critter"
    },
    Critter = {
        fort = "Undead",
        -- /pink
        faible = "Humanoid"
    },
    Water = {
        fort = "Elemental",
        faible = "Magical"
    },
    Flying = {
        fort = "Water",
        faible = "Dragon"
    },
    Magical = {
        fort = "Flying",
        faible = "Mechanical"
    },
    Undead = {
        fort = "Humanoid",
        faible = "Water"
    },
    Dragon = {
        fort = "Magical",
        faible = "Undead"
    },
    Beast = {
        fort = "Critter",
        faible = "Flying"
    },
    Humanoid = {
        fort = "Dragon",
        faible = "Beast"
    }
}

-- Table des couleur associées à la rareté de la mascotte

RARITY_COLOR = {
    [1] = "|cff9a9a9a",
    [2] = "|cffffffff",
    [3] = "|cff1eff00",
    [4] = "|cff0070dc",
    [5] = "|cff0070dc",
    [6] = "|cff0070dc"
}

local function scrollListener(source, target, value, petData)
    for _, child in pairs(target.children) do
        -- TODO : refaire ce test quand le libelleé sera un composant standard.
        if child.meta then
            local check = child
            local checkPetData = check:GetUserData("pet")
            if (checkPetData["petID"] == petData["petID"]) then
                local level = checkPetData["level"]
                if checkPetData["level"] < 10 then
                    level = "0" .. level
                end
                if value then
                    if check.meta.id ~= source.meta.id then
                        check:SetValue(value)
                        if Skym_PetCodex.disableOnMultipleSelection then
                            check:SetLabel(level .. " - " .. "|cff808080" .. checkPetData["customName"] .. "|r")
                            check:SetDisabled(true)
                        end
                    end
                else
                    check:SetLabel(level .. " - " .. RARITY_COLOR[checkPetData["rarity"]] .. checkPetData["customName"] .. "|r")
                    check:SetValue(value)
                    check:SetDisabled(false)
                end
            end
        end
    end
end

local function resetScroll(source, target)
    for _, child in pairs(target.children) do
        -- TODO : refaire ce test quand le libelleé sera un composant standard.
        if child.meta then
            local check = child
            local checkPetData = check:GetUserData("pet")
            local level = checkPetData["level"]
            if checkPetData["level"] < 10 then
                level = "0" .. level
            end
            check:SetLabel(level .. " - " .. RARITY_COLOR[checkPetData["rarity"]] .. checkPetData["customName"] .. "|r")
            check:SetValue(false)
            check:SetDisabled(false)
        end
    end
end

local function sortPetList(a, b)
    if (a.level == b.level) then
        if (a.customName == b.customName) then
            return a.rarity > b.rarity
        else
            return a.customName < b.customName
        end
    else
        return a.level > b.level
    end
end

local function buildLeftList(container, targetPetAbilitiesIDTable, targetPetType)
    -- Préparation de la liste de gauche :
    -- 3 attaques rouges ou moins ;
    -- 1 attaque verte ou plus ;
    -- l'adversaire n'a pas d'attaque verte ;
    -- classé par nombre d'attaques vertes

    local classementMascottesEfficaces = {}
    for i = 1, 6 do
        classementMascottesEfficaces[i] = {}
    end

    local numPets, numOwned = C_PetJournal.GetNumPets()
    for index = 1, numOwned do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
        if canBattle then
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
            if health > 0 and rarity >= Skym_PetCodex.rarityThreshold and level >= Skym_PetCodex.db.global.minLevel and level <= Skym_PetCodex.db.global.maxLevel then
                local green, red, white, vulnerable = 0, 0, 0, false
                local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(speciesID)
                for k, abilityID in pairs(myPetAbilitiesIDTable) do
                    local abilityLevel = myPetAbilitiesLevelTable[k]
                    if level > abilityLevel then
                        -- abilityName : nom de l'attaque
                        local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                        -- typeName : type d'attaque
                        local typeName, fort, faible = PET_TYPE_SUFFIX[abilityType], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["fort"], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["faible"]
                        if (fort == targetPetType) then
                            green = green + 1
                        elseif (faible == targetPetType) then
                            red = red + 1
                        end
                    end
                end
                vulnerable = false
                local monType = TYPES_MASCOTTE[petType]
                for _, abilityID in ipairs(targetPetAbilitiesIDTable) do
                    -- abilityName : nom de l'attaque
                    local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                    -- typeName : type d'attaque
                    local typeName, fort, faible = PET_TYPE_SUFFIX[abilityType], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["fort"], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["faible"]
                    if fort == monType then
                        vulnerable = true
                    end
                end
                if red <= 3 and green >= 1 and not vulnerable then
                    local c = #classementMascottesEfficaces[green]
                    classementMascottesEfficaces[green][c + 1] = {
                        ["petID"] = petID,
                        ["index"] = index,
                        ["customName"] = customName or speciesName,
                        ["speciesName"] = speciesName,
                        ["speciesID"] = speciesID,
                        ["level"] = level,
                        ["rarity"] = rarity,
                        ["icon"] = icon,
                        ["type"] = _G['BATTLE_PET_NAME_' .. petType]
                    }
                end
            end
        end
    end

    for i = 6, 1, -1 do
        local c = classementMascottesEfficaces[i]
        if (#c > 0) then
            table.sort(c, sortPetList)
            local heading = gui:Create("Heading");
            if (i > 1) then
                heading:SetText(i .. " attaques vertes")
            else
                heading:SetText(i .. " attaque verte")
            end
            heading.width = "fill"
            container:AddChild(heading)
            for _, petData in pairs(c) do
                local check = Skym_PetCodex_Frame:CreateCheckBox(petData)
                container:AddChild(check)
            end
        end
    end
end

local function buildRightList(container, targetPetAbilitiesIDTable, targetPetType)
    -- Préparation de la liste de droite
    -- l'adversaire n'a pas d'attaque verte ;
    -- classé par nombre d'attaque rouge de l'adversaire.

    local classementMascottesPeuSensibles = {}
    for i = -6, 6 do
        classementMascottesPeuSensibles[i] = {}
    end
    local numPets, numOwned = C_PetJournal.GetNumPets()
    for index = 1, numOwned do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
        if canBattle then
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
            if health > 0 and rarity >= Skym_PetCodex.rarityThreshold and level >= Skym_PetCodex.db.global.minLevel and level <= Skym_PetCodex.db.global.maxLevel then
                local green, red, white, vulnerable = 0, 0, 0, false
                local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(speciesID)
                for k, abilityID in pairs(myPetAbilitiesIDTable) do
                    local abilityLevel = myPetAbilitiesLevelTable[k]
                    if level > abilityLevel then
                        -- abilityName : nom de l'attaque
                        local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                        -- typeName : type d'attaque
                        local typeName, fort, faible = PET_TYPE_SUFFIX[abilityType], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["fort"], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["faible"]
                        if (faible == targetPetType) then
                            red = red + 1
                        end
                    end
                end
                local score, monType = 0, TYPES_MASCOTTE[petType]
                local ignorer = false
                local acceptableMaxScore = 4
                if #targetPetAbilitiesIDTable == 3 then
                    -- Pet is legendary and only has 3 attacks
                    acceptableMaxScore = 1
                end
                for _, abilityID in ipairs(targetPetAbilitiesIDTable) do
                    -- abilityName : nom de l'attaque
                    local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                    -- typeName : type d'attaque
                    local typeName, fort, faible = PET_TYPE_SUFFIX[abilityType], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["fort"], TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityType]]["faible"]
                    if fort == monType then
                        ignorer = true
                    elseif faible == monType then
                        score = score + 1
                    end
                end
                if not ignorer and score >= acceptableMaxScore and red <= 3 then
                    local c = #classementMascottesPeuSensibles[score]
                    classementMascottesPeuSensibles[score][c + 1] = {
                        ["petID"] = petID,
                        ["index"] = index,
                        ["customName"] = customName or speciesName,
                        ["speciesName"] = speciesName,
                        ["speciesID"] = speciesID,
                        ["level"] = level,
                        ["rarity"] = rarity,
                        ["icon"] = icon,
                        ["type"] = _G['BATTLE_PET_NAME_' .. petType]
                    }
                end
            end
        end
    end

    for i = 6, -6, -1 do
        local c = classementMascottesPeuSensibles[i]
        if (#c > 0) then
            table.sort(c, sortPetList)
            local heading = gui:Create("Heading");
            if (i > 1) then
                heading:SetText(i .. " attaques adverses rouges")
            else
                heading:SetText(i .. " attaque adverse rouge")
            end
            heading.width = "fill"
            container:AddChild(heading)
            for _, petData in pairs(c) do
                local check = Skym_PetCodex_Frame:CreateCheckBox(petData)
                container:AddChild(check)
            end
        end
    end
end

function Skym_PetCodex_Frame:CreateCheckBox(petData)
    local check = sk:createCheckBox()
    local level = petData["level"]
    if petData["level"] < 10 then
        level = "0" .. level
    end
    check:SetLabel(level .. " - " .. RARITY_COLOR[petData["rarity"]] .. petData["customName"] .. "|r")
    check:SetImage(petData["icon"])
    check:SetUserData("pet", petData)
    local value = false
    local targetSpeciesID = self.groupeMascotteCible:GetUserData("targetSpeciesID")
    for i = 1, 3 do
        if Skym_PetCodex.db.global.teams[targetSpeciesID][i] then
            if Skym_PetCodex.db.global.teams[targetSpeciesID][i].petID == petData.petID then
                value = true
            end
        end
    end
    check:SetValue(value)
    if value then
        if not self.petSelected[petData.petID] then
            self.nbPetSelected = self.nbPetSelected + 1
            self.petSelected[petData.petID] = true
        else
            check:SetDisabled(true)
            check:SetValue(true)
            check:SetLabel(level .. " - " .. "|cff808080" .. petData["customName"] .. "|r")
        end
    end
    check:SetCallback("OnEnter", function(info, event)
        self.frame:SetStatusText(info.userdata.pet.customName .. " - " .. info.userdata.pet.type)
    end)
    check["ToggleChecked"] = function(info)
        if not check:GetValue() then
            if self.nbPetSelected == 3 then return end
            check:SetValue(true)
            check:fireEvent("SKPC:CLICK", true, info.userdata.pet)
            if not self.petSelected[petData.petID] then
                self.nbPetSelected = self.nbPetSelected + 1
                self.petSelected[petData.petID] = true
            end
        else
            check:SetValue(false)
            check:fireEvent("SKPC:CLICK", false, info.userdata.pet)
            self.nbPetSelected = self.nbPetSelected - 1
            self.petSelected[petData.petID] = nil
        end
    end
    check.width = "fill"

    return check
end

local function displayPetAbilities(index, petData, attacks, targetPetType, targetSpeciesID, load)
    -- Récupération des attaques de la mascotte
    local speciesID, level = petData["speciesID"], petData["level"]
    local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(speciesID)

    local abilityNames = {}
    local abilityIcons = {}
    local abilityTypes = {}
    local abilityStrength = {}
    for key, abilityID in ipairs(myPetAbilitiesIDTable) do
        abilityNames[key], abilityIcons[key], abilityTypes[key] = C_PetJournal.GetPetAbilityInfo(abilityID)
        abilityStrength[key] = 0
        if level > myPetAbilitiesLevelTable[key] and (TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityTypes[key]]]["fort"] == targetPetType) then
            abilityNames[key] = "|cff18e700" .. abilityNames[key] .. "|r"
            abilityStrength[key] = 1
        elseif level > myPetAbilitiesLevelTable[key] and (TYPES_ATTAQUE[PET_TYPE_SUFFIX[abilityTypes[key]]]["faible"] == targetPetType) then
            abilityNames[key] = "|cffdd0000" .. abilityNames[key] .. "|r"
            abilityStrength[key] = -1
        end
    end

    attacks[1]:SetList({ abilityNames[1], abilityNames[4] })
    attacks[1]:SetText("<vide>")
    attacks[2]:SetList({ abilityNames[2], abilityNames[5] })
    attacks[2]:SetText("<vide>")
    attacks[3]:SetList({ abilityNames[3], abilityNames[6] })
    attacks[3]:SetText("<vide>")

    attacks[1]:SetItemDisabled(1, level < myPetAbilitiesLevelTable[1])
    attacks[2]:SetItemDisabled(1, level < myPetAbilitiesLevelTable[2])
    attacks[3]:SetItemDisabled(1, level < myPetAbilitiesLevelTable[3])
    attacks[1]:SetItemDisabled(2, level < myPetAbilitiesLevelTable[4])
    attacks[2]:SetItemDisabled(2, level < myPetAbilitiesLevelTable[5])
    attacks[3]:SetItemDisabled(2, level < myPetAbilitiesLevelTable[6])

    if not load then
        Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks = Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks or {}
        if level < myPetAbilitiesLevelTable[4] then
            attacks[1]:SetValue(1)
            -- Attaque 1 sélectionnée
            C_PetJournal.SetAbility(index, 1, myPetAbilitiesIDTable[1])
            Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[1] = 1
        else
            if abilityStrength[1] >= abilityStrength[4] then
                attacks[1]:SetValue(1)
                -- Attaque 1 sélectionnée
                C_PetJournal.SetAbility(index, 1, myPetAbilitiesIDTable[1])
                Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[1] = 1
            else
                attacks[1]:SetValue(2)
                -- Attaque 4 sélectionnée
                C_PetJournal.SetAbility(index, 1, myPetAbilitiesIDTable[4])
                Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[1] = 2
            end
        end

        if level >= myPetAbilitiesLevelTable[2] then
            if level < myPetAbilitiesLevelTable[5] then
                attacks[2]:SetValue(1)
                -- Attaque 2 sélectionnée
                C_PetJournal.SetAbility(index, 2, myPetAbilitiesIDTable[2])
                Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[2] = 1
            else
                if abilityStrength[2] >= abilityStrength[5] then
                    --frame = attacks[2].pullout.items[1].frame
                    attacks[2]:SetValue(1)
                    -- Attaque 2 sélectionnée
                    C_PetJournal.SetAbility(index, 2, myPetAbilitiesIDTable[2])
                    Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[2] = 1
                else
                    attacks[2]:SetValue(2)
                    -- Attaque 5 sélectionnée
                    C_PetJournal.SetAbility(index, 2, myPetAbilitiesIDTable[5])
                    Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[2] = 2
                end
            end
        end

        if level >= myPetAbilitiesLevelTable[3] then
            if level < myPetAbilitiesLevelTable[6] then
                attacks[3]:SetValue(1)
                -- Attaque 3 sélectionnée
                C_PetJournal.SetAbility(index, 3, myPetAbilitiesIDTable[3])
                Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[3] = 1
            else
                if abilityStrength[3] >= abilityStrength[6] then
                    attacks[3]:SetValue(1)
                    -- Attaque 3 sélectionnée
                    C_PetJournal.SetAbility(index, 3, myPetAbilitiesIDTable[3])
                    Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[3] = 1
                else
                    attacks[3]:SetValue(2)
                    -- Attaque 6 sélectionnée
                    C_PetJournal.SetAbility(index, 3, myPetAbilitiesIDTable[6])
                    Skym_PetCodex.db.global.teams[targetSpeciesID][index].attacks[3] = 2
                end
            end
        end
    else
        for i = 1, 3 do
            petData.attacks = petData.attacks or {}
            if petData.attacks[i] then
                attacks[i]:SetText(abilityNames[i + (petData.attacks[i] - 1) * 3])
                attacks[i]:SetValue(petData.attacks[i])
            else
                attacks[i]:SetText("<vide>")
                attacks[i]:SetValue(nil)
            end
        end
    end
    -- Fin récupération données mascotte
end

-- ShowFrame

function Skym_PetCodex_Frame:ShowFrame()

    if self.frame then return end

    self.nbPetSelected = 0
    self.petSelected = {}

    -- Frame principale

    local f = sk:createFrame()

    self.frame = f

    f:ReleaseChildren()
    tinsert(UISpecialFrames, f.frame:GetName())

    f:SetCallback("OnClose", function(widget, event)
        gui:Release(widget)
        self.frame = nil
    end)
    f:SetTitle("Skym : Pet Codex")
    f:SetStatusText("(c) 2013 - Skym")
    f:SetLayout("Flow")
    f:SetWidth(640)
    f:SetHeight(640)

    C_PetJournal.AddAllPetSourcesFilter()
    C_PetJournal.AddAllPetTypesFilter()
    C_PetJournal.ClearSearchFilter()

    -- Entête : information sur la mascotte ciblée

    self.groupeMascotteCible = gui:Create("InlineGroup")
    self.groupeMascotteCible:SetTitle("Mascotte ciblée")
    self.groupeMascotteCible.width = "fill"
    self.groupeMascotteCible:SetLayout("Flow")

    -- La team

    local teamMembers = {}

    self.teamGroup = sk:createInlineGroup()
    self.teamGroup:SetTitle("Equipe")
    self.teamGroup.width = "fill"
    self.teamGroup:SetLayout("Flow")
    self.teamGroup:addListener("SKPC:CLICK", function(source, target, value, petData)
        local targetSpeciesID = self.groupeMascotteCible:GetUserData("targetSpeciesID")
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID(targetSpeciesID)
        local targetPetType = TYPES_MASCOTTE[petType]
        if value then
            local found = false
            for i = 1, 12, 4 do
                local label = self.teamGroup.children[i]
                if not found and not label:GetUserData("pet") then
                    C_PetJournal.SetPetLoadOutInfo(1 + (i - 1) / 4, petData.petID)
                    Skym_PetCodex.db.global.teams[targetSpeciesID][1 + (i - 1) / 4] = petData

                    label:SetText(petData.customName)
                    label:SetUserData("pet", petData)
                    local attacks = label:GetUserData("attacks")

                    displayPetAbilities(1 + (i - 1) / 4, petData, attacks, targetPetType, targetSpeciesID)

                    found = true
                end
            end
        else
            for i = 1, 12, 4 do
                local label = self.teamGroup.children[i]
                if label:GetUserData("pet") and label:GetUserData("pet").petID == petData.petID then
                    label:SetText("<vide>")
                    label:SetUserData("pet", nil)
                    Skym_PetCodex.db.global.teams[targetSpeciesID][1 + (i - 1) / 4] = nil
                end
            end
        end
    end)
    self.teamGroup:addListener("SKPC:RESET", function()
        self.nbPetSelected = 0
        self.petSelected = {}
        for i = 1, 3 do
            teamMembers[i].label:SetText("<vide>")
            teamMembers[i].label:SetUserData("pet", nil)
            for j = 1, 3 do
                teamMembers[i].attacks[j]:SetText("<vide>")
            end
        end
        targetSpeciesID = self.groupeMascotteCible:GetUserData("targetSpeciesID")
        if targetSpeciesID then
            Skym_PetCodex.db.global.teams[targetSpeciesID] = {}
        end
    end)

    for i = 1, 3 do
        teamMembers[i] = { label = gui:Create("Label") }
        teamMembers[i].label:SetText("<vide>")
        teamMembers[i].label:SetUserData("pet", nil)
        teamMembers[i].label:SetRelativeWidth(.25)
        self.teamGroup:AddChild(teamMembers[i].label)

        teamMembers[i].attacks = {}
        for j = 1, 3 do
            teamMembers[i].attacks[j] = gui:Create("Dropdown")
            local list = { "Attaque 1", "Attaque 2" }
            teamMembers[i].attacks[j]:SetList(list)
            teamMembers[i].attacks[j]:SetItemDisabled(1, true)
            teamMembers[i].attacks[j]:SetItemDisabled(2, true)
            teamMembers[i].attacks[j]:SetText("<vide>")
            teamMembers[i].attacks[j]:SetRelativeWidth(.25)
            teamMembers[i].attacks[j]:SetCallback("OnValueChanged", function(info, event, key)
                local targetSpeciesID = self.groupeMascotteCible:GetUserData("targetSpeciesID")
                Skym_PetCodex.db.global.teams[targetSpeciesID][i]["attacks"] = Skym_PetCodex.db.global.teams[targetSpeciesID][i]["attacks"] or {}
                Skym_PetCodex.db.global.teams[targetSpeciesID][i]["attacks"][j] = key

                local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(Skym_PetCodex.db.global.teams[targetSpeciesID][i].speciesID)
                C_PetJournal.SetAbility(i, j, myPetAbilitiesIDTable[j + (key - 1) * 3])
            end)
            self.teamGroup:AddChild(teamMembers[i].attacks[j])
        end

        teamMembers[i].label:SetUserData("attacks", teamMembers[i].attacks)
    end

    -- Options

    self.options = sk:createInlineGroup()
    self.options:SetTitle("Options")
    self.options.width = "fill"
    self.options:SetLayout("Flow")

    local resetButton = sk:createButton()
    resetButton:SetText("Décocher tout")
    resetButton:SetWidth(150)
    resetButton:SetCallback("OnClick", function()
        resetButton:fireEvent("SKPC:RESET")
    end)
    self.options:AddChild(resetButton)

    local spacer = sk:createLabel()
    spacer:SetWidth(20)
    self.options:AddChild(spacer)

    local textLevelMin = sk:createEditBox()
    textLevelMin:SetLabel("Niveau min. :")
    textLevelMin:SetMaxLetters(2)
    textLevelMin:SetText(Skym_PetCodex.db.global.minLevel)
    textLevelMin:SetWidth(80)
    textLevelMin:DisableButton(true)
    self.options:AddChild(textLevelMin)

    local textLevelMax = sk:createEditBox()
    textLevelMax:SetLabel("Niveau max. :")
    textLevelMax:SetMaxLetters(2)
    textLevelMax:SetText(Skym_PetCodex.db.global.maxLevel)
    textLevelMax:SetWidth(80)
    textLevelMax:DisableButton(true)
    self.options:AddChild(textLevelMax)

    local levelButton = sk:createButton()
    levelButton:SetText("Ok")
    levelButton:SetWidth(50)
    levelButton:SetCallback("OnClick", function()
        local levelMin = tonumber(textLevelMin:GetText())
        if not levelMin then
            levelMin = Skym_PetCodex.db.global.minLevel
        elseif levelMin > 25 then
            levelMin = 25
        elseif levelMin < 1 then
            levelMin = 1
        end

        local levelMax = tonumber(textLevelMax:GetText())
        if not levelMax then
            levelMax = Skym_PetCodex.db.global.maxLevel
        elseif levelMax > 25 then
            levelMax = 25
        elseif levelMax < 1 then
            levelMax = 1
        end

        if (levelMin > levelMax) then
            local temp = levelMin
            levelMin = levelMax
            levelMax = temp
        end

        textLevelMin:SetText(levelMin)
        textLevelMax:SetText(levelMax)

        Skym_PetCodex.db.global.minLevel = levelMin
        Skym_PetCodex.db.global.maxLevel = levelMax
        levelButton:fireEvent("SKPC:LEVELS_CHANGEG", levelMin, levelMax)
    end)
    self.options:AddChild(levelButton)

    -- Colonne de gauche : mascottes efficaces

    local groupeMascottesEfficaces = gui:Create("InlineGroup")
    groupeMascottesEfficaces:SetTitle("Mascottes efficaces")
    groupeMascottesEfficaces.height = "fill"
    groupeMascottesEfficaces:SetLayout("Fill")

    -- ScrollFrame des mascottes efficaces

    groupeMascottesEfficacesScroll = sk:createScrollFrame()
    groupeMascottesEfficacesScroll:SetLayout("Flow")
    groupeMascottesEfficacesScroll.width = "fill"
    groupeMascottesEfficacesScroll.height = "fill"
    groupeMascottesEfficacesScroll:addListener("SKPC:CLICK", scrollListener)
    groupeMascottesEfficacesScroll:addListener("SKPC:RESET", resetScroll)

    -- Colonne de droite : mascottes peu sensibles

    local groupeMascottesPeuSensibles = gui:Create("InlineGroup")
    groupeMascottesPeuSensibles:SetTitle("Mascottes peu sensibles")
    groupeMascottesPeuSensibles.height = "fill"
    groupeMascottesPeuSensibles:SetLayout("Fill")

    -- ScrollFrame des mascottes peu sensibles

    groupeMascottesPeuSensiblesScroll = sk:createScrollFrame()
    groupeMascottesPeuSensiblesScroll:SetLayout("Flow")
    groupeMascottesPeuSensiblesScroll.width = "fill"
    groupeMascottesPeuSensiblesScroll.height = "fill"
    groupeMascottesPeuSensiblesScroll:addListener("SKPC:CLICK", scrollListener)
    groupeMascottesPeuSensiblesScroll:addListener("SKPC:RESET", resetScroll)

    if targetIsBattlePet() then

        -- Chargement automatique de l'équipe associée à la mascotte adverse

        Skym_PetCodex:loadTeamForTarget()

        -- Récupération des informations sur la cible

        local targetPetName = UnitName("target")
        targetSpeciesID = C_PetJournal.FindPetIDByName(targetPetName)

        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID(targetSpeciesID)
        local targetPetAbilitiesIDTable, targetPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(targetSpeciesID)
        local targetPetType = TYPES_MASCOTTE[petType]

        -- Chargement des attaques de la mascotte cible

        local attaques = {}
        for k, abilityID in pairs(targetPetAbilitiesIDTable) do
            local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
            attaques[#attaques + 1] = abilityName
        end

        -- Affichage des information dans l'entête de la page

        local iconPet = gui:Create("Icon")
        iconPet:SetImage(speciesIcon)
        self.groupeMascotteCible:AddChild(iconPet)

        local labelNomPet = gui:Create("Label")
        labelNomPet:SetText("Nom : " .. targetPetName)
        self.groupeMascotteCible:AddChild(labelNomPet)

        local labelEspece = gui:Create("Label")
        labelEspece:SetText("Espère : " .. TYPES_MASCOTTE[petType])
        self.groupeMascotteCible:AddChild(labelEspece)

        for k, v in ipairs(attaques) do
            local labelAttaque = gui:Create("Label")
            labelAttaque:SetText(v)
            self.groupeMascotteCible:AddChild(labelAttaque)
        end

        self.groupeMascotteCible:SetUserData("targetSpeciesID", targetSpeciesID)

        -- Affichage de l'équippe associée à la mascotte cible

        for i = 1, 3 do
            local petData = Skym_PetCodex.db.global.teams[targetSpeciesID][i]
            if petData then
                -- Refresh level
                local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(petData.index)
                petData["level"] = level
                teamMembers[i].label:SetText(RARITY_COLOR[petData.rarity] .. petData.customName .. "|r " .. level)
                teamMembers[i].label:SetUserData("pet", petData)
                C_PetJournal.SetPetLoadOutInfo(i, petData.petID)
                local attacks = teamMembers[i].label:GetUserData("attacks")
                displayPetAbilities(i, petData, attacks, targetPetType, targetSpeciesID, true)
            end
        end

        buildLeftList(groupeMascottesEfficacesScroll, targetPetAbilitiesIDTable, targetPetType)
        buildRightList(groupeMascottesPeuSensiblesScroll, targetPetAbilitiesIDTable, targetPetType)

        f:addListener("SKPC:LEVELS_CHANGEG", function(source, target, levelMin, levelMax)
            groupeMascottesEfficacesScroll:ReleaseChildren()
            groupeMascottesPeuSensiblesScroll:ReleaseChildren()
            local backup = { nbPetSelected = self.nbPetSelected, petSelected = self.petSelected }
            self.nbPetSelected = 0
            self.petSelected = {}
            buildLeftList(groupeMascottesEfficacesScroll, targetPetAbilitiesIDTable, targetPetType)
            buildRightList(groupeMascottesPeuSensiblesScroll, targetPetAbilitiesIDTable, targetPetType)
            self.nbPetSelected = backup.nbPetSelected
            self.petSelected = backup.petSelected
        end)
    end

    groupeMascottesEfficaces:AddChild(groupeMascottesEfficacesScroll)
    groupeMascottesPeuSensibles:AddChild(groupeMascottesPeuSensiblesScroll)

    f:AddChild(self.groupeMascotteCible)
    f:AddChild(self.teamGroup)
    f:AddChild(self.options)
    f:AddChild(groupeMascottesEfficaces)
    f:AddChild(groupeMascottesPeuSensibles)
end

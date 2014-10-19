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

Skym_PetCodex_TeamFrame = Skym_PetCodex:NewModule("Skym_PetCodex_TeamFrame", "AceEvent-3.0")

-- Référence à AceGUI

local gui = LibStub("AceGUI-3.0")

-- Référence à SkymFramework

local sk = LibStub("SkymFramework-0.1.0")

local function lpairs(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return a > b end)

    local i = 0

    return function()
        i = i + 1
        if keys[i] then return keys[i], t[keys[i]] end
    end
end

function DEC_HEX(IN)
    local B, K, OUT, I, D = 16, "0123456789ABCDEF", "", 0
    while IN > 0 do
        I = I + 1
        local mod = IN - B * math.floor(IN / B)
        --IN,D=math.floor(IN/B),/*math.mod(IN,B)*/mod+1
        IN, D = math.floor(IN / B), mod + 1
        OUT = string.sub(K, D, D) .. OUT
    end
    return OUT
end

local function filterBattlePetList(filtre)
    local liste = {}
    local numPets, numOwned = C_PetJournal.GetNumPets()
    for index = 1, numOwned do
        -- /pink
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
        if not filtre or (string.match(string.lower(customName or speciesName), ".*" .. filtre:lower() .. ".*")) then
            if canBattle then
                local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

                local petInfo = { id = petID, name = customName or speciesName, rarity = rarity, icon = icon, level = level }
                petInfo.abilities = {}

                local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(speciesID)
                for k, v in pairs(myPetAbilitiesLevelTable) do
                    if level >= v then
                        local abilityID = myPetAbilitiesIDTable[k]
                        local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                        petInfo.abilities[k] = { id = abilityID, name = abilityName, icon = abilityIcon, type = abilityType }
                    end
                end

                liste[level] = liste[level] or {}
                liste[level][rarity] = liste[level][rarity] or {}
                local r = liste[level][rarity]
                r[#r + 1] = petInfo
            end
        end
    end

    for _, rarities in pairs(liste) do
        for _, pets in pairs(rarities) do
            table.sort(pets, function(a, b) return a.name < b.name end)
        end
    end

    return liste
end

local function fillPetInfo(widget, pet)
    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(pet.id)

    if health == nil then
        local numPets, numOwned = C_PetJournal.GetNumPets()

        for index = 1, numOwned do
            local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
            local name = customName or speciesName
        end

        for index = 1, numOwned do
            local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
            local name = customName or speciesName
            if ((pet.name == name) and (pet.speciesID == speciesID) and (pet.level <= level)) then
                pet.id = petID
                health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(pet.id)
            end
        end
    end
    if (health == nil) then
        print("Pas trouvé : ", pet.name, "(", "speciesID: ", pet.speciesID, "level:", pet.level, ")")
        return
    end
    local green = math.floor(health / maxHealth * 255)
    local sgreen = "00" .. DEC_HEX(green)
    sgreen = sgreen:sub(-2)
    local red = 255 - green
    local sred = "00" .. DEC_HEX(red)
    sred = sred:sub(-2)
    local color = sred .. sgreen .. "00"
    color = "|cff" .. color
    pet.health = health
    pet.maxHealth = maxHealth

    local offset = 2
    widget.children[offset].children[1]:SetText(RARITY_COLOR[pet.rarity] .. pet.name .. "|r")
    widget.children[offset].children[2]:SetText(pet.level .. " - " .. color .. pet.health .. "/" .. pet.maxHealth .. "|r")
    for i = 1, 3 do
        local list = {}
        if pet.abilities[i] then
            list[1] = pet.abilities[i].name
            widget.children[i + offset]:SetItemDisabled(1, false)
        else
            list[1] = "|cff808080----|r"
            widget.children[i + offset]:SetItemDisabled(1, true)
        end
        if pet.abilities[i + 3] then
            list[2] = pet.abilities[i + 3].name
            widget.children[i + offset]:SetItemDisabled(2, false)
        else
            list[2] = "|cff808080----|r"
            widget.children[i + offset]:SetItemDisabled(2, true)
        end
        widget.children[i + offset]:SetList(list)
        if pet.attacks and pet.attacks[i] then
            widget.children[i + offset]:SetText(pet.attacks[i].name)
            widget.children[i + offset]:SetValue(pet.attacks[i].key)
        else
            widget.children[i + offset]:SetText(nil)
            widget.children[i + offset]:SetValue(nil)
        end
    end
end

local function cleanPetInfo(widget)
    local offset = 2
    if widget.children then
        widget.children[offset].children[1]:SetText("<vide>")
        widget.children[offset].children[2]:SetText("-- - |cff00FF00----/----|r")
        for i = 1, 3 do
            local list = { "|cff808080----|r", "|cff808080----|r" }
            widget.children[i + offset]:SetList(list)
            widget.children[i + offset]:SetItemDisabled(1, true)
            widget.children[i + offset]:SetItemDisabled(2, true)
            widget.children[i + offset]:SetText("")
            widget.children[i + offset]:SetValue(nil)
        end
    end
end

-- ShowFrame

function Skym_PetCodex_TeamFrame:showFrame()

    C_PetJournal.AddAllPetSourcesFilter()
    C_PetJournal.AddAllPetTypesFilter()
    C_PetJournal.ClearSearchFilter()

    if self.frame then return end

    self.frame = sk:createFrame()
    self.frame:ReleaseChildren()

    tinsert(UISpecialFrames, self.frame.frame:GetName())

    self.frame:SetCallback("OnClose", function(widget, event)
    --gui:Release(widget)
        self.frame = nil
    end)

    self.frame:SetTitle("Skym : Pet Codex")
    self.frame:SetStatusText("(c) 2013 - Skym")
    self.frame:SetLayout("Flow")
    self.frame:SetWidth(740)
    self.frame:SetHeight(640)
    --	self.frame.frame:SetScript("OnKeyDown", function(info, key)
    --		if key == "LCTRL" then
    --			Skym_PetCodex_TeamFrame.CTRL = true
    --		end
    --	end)
    --	self.frame.frame:SetScript("OnKeyUp", function(info, key)
    --		if key == "LCTRL" then
    --			Skym_PetCodex_TeamFrame.CTRL = nil
    --		end
    --	end)

    C_PetJournal.AddAllPetSourcesFilter()
    C_PetJournal.AddAllPetTypesFilter()
    C_PetJournal.ClearSearchFilter()

    -- Les équipes prédéfinies

    local teamsList = sk:createInlineGroup()
    teamsList:SetTitle("Equipes prédéfinies")
    teamsList:SetFullWidth(true)
    teamsList:SetLayout("Flow")
    self.frame:AddChild(teamsList)

    local teamsListScrollContainer = gui:Create("SimpleGroup")
    teamsListScrollContainer:SetFullWidth(true)
    teamsListScrollContainer:SetHeight(80)
    teamsListScrollContainer:SetLayout("Fill")
    teamsList:AddChild(teamsListScrollContainer)

    local teamsListScroll = sk:createScrollFrame()
    teamsListScroll:SetLayout("Flow")
    teamsListScroll:addListener("PRESET_CHANGED", function()
        teamsListScroll:ReleaseChildren()
        Skym_PetCodex_TeamFrame.selection = nil
        local list = {}
        for presetKey, preset in pairs(Skym_PetCodex.db.global.presets) do
            local l = sk:createInteractiveLabel()
            l.key = presetKey
            l:SetText(preset.name)
            --l.width = "fill"
            l:SetRelativeWidth(.49)
            l:SetImage("INTERFACE\\ICONS\\INV_PET_SPRITE_DARTER_HATCHLING.BLP")
            l:SetHighlight(1.0, 0.0, 0.0, 0.5)
            if l.overlay then
                l.overlay:Hide()
            end
            l:SetCallback("OnClick", function()
                if Skym_PetCodex_TeamFrame.selection then
                    Skym_PetCodex_TeamFrame.selection.overlay:Hide()
                    Skym_PetCodex_TeamFrame.selection = nil
                end
                if l.overlay then
                    l.overlay:Show()
                else
                    local overlay = l.frame:CreateTexture(nil, "OVERLAY")
                    overlay:SetTexture(nil)
                    overlay:SetAllPoints()
                    overlay:SetBlendMode("ADD")
                    overlay:SetTexture(0.0, 0.0, 1.0, 0.5)
                    l.overlay = overlay
                end
                Skym_PetCodex_TeamFrame.selection = l
                Skym_PetCodex.db.global.selection = presetKey
                l:fireEvent("TEAM_SELECTED")
            end)
            teamsListScroll:AddChild(l)
        end
    end)
    teamsListScrollContainer:AddChild(teamsListScroll)

    -- La barre d'actions

    local presetGroup = sk:createInlineGroup()
    presetGroup:SetTitle("Equipes prédéfinies")
    presetGroup:SetLayout("Flow")
    presetGroup.width = "fill"

    local newPresetName = sk:createEditBox()
    newPresetName:SetRelativeWidth(.30)
    newPresetName:DisableButton(true)
    newPresetName:SetCallback("OnTextChanged", function()
        newPresetName:fireEvent("NEW_PRESET_NAME_CHANGED", newPresetName:GetText())
    end)
    newPresetName:addListener("ADD_NEW_PRESET_BUTTON_CLICKED", function()
        local p = Skym_PetCodex.db.global.presets
        p[#p + 1] = { name = newPresetName:GetText() }
        newPresetName:SetText("")
        newPresetName:fireEvent("PRESET_CHANGED")
    end)
    newPresetName:addListener("EDIT_PRESET_BUTTON_CLICKED", function()
        local p = Skym_PetCodex.db.global.presets
        p[Skym_PetCodex_TeamFrame.selection.key].name = newPresetName:GetText()
        newPresetName:SetText("")
        newPresetName:fireEvent("PRESET_CHANGED")
    end)
    newPresetName:addListener("TEAM_SELECTED", function()
        local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
        newPresetName:SetText(p.name)
    end)
    presetGroup:AddChild(newPresetName)

    local addNewPresetButton = sk:createButton()
    addNewPresetButton:SetText("Ajouter")
    addNewPresetButton:SetRelativeWidth(.17)
    addNewPresetButton:SetDisabled(true)
    addNewPresetButton:addListener("NEW_PRESET_NAME_CHANGED", function(source, target, text)
        if text == "" then
            addNewPresetButton:SetDisabled(true)
        else
            addNewPresetButton:SetDisabled(false)
        end
    end)
    addNewPresetButton:addListener("TEAM_SELECTED", function()
        addNewPresetButton:SetDisabled(true)
    end)
    addNewPresetButton:SetCallback("OnClick", function()
        addNewPresetButton:SetDisabled(true)
        addNewPresetButton:fireEvent("ADD_NEW_PRESET_BUTTON_CLICKED")
    end)
    addNewPresetButton:addListener("PRESET_CHANGED", function(source, target)
        target:SetDisabled(true)
    end)
    presetGroup:AddChild(addNewPresetButton)

    local editPresetButton = sk:createButton()
    editPresetButton:SetText("Modifier")
    editPresetButton:SetRelativeWidth(.17)
    editPresetButton:SetDisabled(true)
    editPresetButton:addListener("NEW_PRESET_NAME_CHANGED", function(source, target, text)
        if Skym_PetCodex_TeamFrame.selection and text ~= "" then
            target:SetDisabled(false)
        else
            target:SetDisabled(true)
        end
    end)
    editPresetButton:addListener("PRESET_CHANGED", function(source, target)
        target:SetDisabled(true)
    end)
    editPresetButton:addListener("TEAM_SELECTED", function()
        editPresetButton:SetDisabled(true)
    end)
    editPresetButton:SetCallback("OnClick", function()
        editPresetButton:SetDisabled(true)
        editPresetButton:fireEvent("EDIT_PRESET_BUTTON_CLICKED")
    end)
    presetGroup:AddChild(editPresetButton)

    local deletePresetButton = sk:createButton()
    deletePresetButton:SetText("Supprimer")
    deletePresetButton:SetRelativeWidth(.17)
    deletePresetButton:SetDisabled(true)
    deletePresetButton:addListener("TEAM_SELECTED", function(source, target)
        target:SetDisabled(false)
    end)
    deletePresetButton:SetCallback("OnClick", function()
        Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key] = nil
        deletePresetButton:SetDisabled(true)
        deletePresetButton:fireEvent("PRESET_CHANGED")
    end)
    deletePresetButton:addListener("PRESET_CHANGED", function()
        deletePresetButton:SetDisabled(true)
    end)
    presetGroup:AddChild(deletePresetButton)

    local loadTeamButton = sk:createButton()
    loadTeamButton:SetText("Charger")
    loadTeamButton:SetRelativeWidth(.17)
    loadTeamButton:SetDisabled(true)
    presetGroup:AddChild(loadTeamButton)
    loadTeamButton:addListener("TEAM_SELECTED", function(source, target)
        loadTeamButton:SetDisabled(false)
    end)
    loadTeamButton:addListener("PRESET_CHANGED", function(source, target)
        loadTeamButton:SetDisabled(true)
    end)
    loadTeamButton:SetCallback("OnClick", function()
        local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
        p.members = p.members or {}
        for i = 1, 3 do
            local pet = p.members[i]
            if pet then
                pet.attacks = pet.attacks or {}
                C_PetJournal.SetPetLoadOutInfo(i, pet.id)
                for k = 1, 3 do
                    local attack = pet.attacks[k]
                    if attack then
                        C_PetJournal.SetAbility(i, k, pet.abilities[k + (attack.key - 1) * 3].id)
                    else
                        if pet.abilities[k] then
                            C_PetJournal.SetAbility(i, k, pet.abilities[k].id)
                        end
                    end
                end
            else
                C_PetJournal.SetPetLoadOutInfo(i, nil)
            end
        end
    end)

    self.frame:AddChild(presetGroup)

    -- La team

    local teamGroup = sk:createInlineGroup()
    teamGroup:SetTitle("Equipe")
    teamGroup:SetLayout("Flow")
    teamGroup.width = "fill"
    teamGroup:addListener("BATTLE_PET_SELECTED", function(source, target, pet)
        local found = false
        for _, widget in pairs(target.children) do
            if not found and not widget.pet then
                found = true
                widget.pet = pet
                local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
                p.members = p.members or {}
                p.members[widget.slot] = pet
                fillPetInfo(widget, pet)
            end
        end
    end)
    teamGroup:addListener("BATTLE_PET_UNSELECTED", function(source, target, pet)
        for _, widget in pairs(target.children) do
            if widget.pet and widget.pet.id == pet.id then
                widget.pet = nil
                local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
                p.members = p.members or {}
                p.members[widget.slot] = nil
                cleanPetInfo(widget)
            end
        end
    end)
    teamGroup:addListener("TEAM_SELECTED", function(source, target)
        for _, widget in pairs(target.children) do
            local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
            p.members = p.members or {}
            pet = p.members[widget.slot]
            if pet then
                if (not (string.sub(pet.id, 6) == "Battle")) then
                    pet.id = "BattlePet-0-" .. string.sub(pet.id, -12)
                end
                local numPets, numOwned = C_PetJournal.GetNumPets()
                for index = 1, numOwned do
                    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(index)
                    if petID == pet.id then
                        pet.index = index
                        pet.level = level
                        pet.speciesID = speciesID
                    end
                end
                local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(pet.speciesID)
                for k, v in pairs(myPetAbilitiesLevelTable) do
                    if pet.level >= v then
                        local abilityID = myPetAbilitiesIDTable[k]
                        local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)
                        pet.abilities[k] = { id = abilityID, name = abilityName, icon = abilityIcon, type = abilityType }
                    end
                end
                widget.pet = pet
                fillPetInfo(widget, pet)
            else
                widget.pet = nil
                cleanPetInfo(widget)
            end
        end
    end)
    teamGroup:addListener("PRESET_CHANGED", function(source, target)
        for _, widget in pairs(target.children) do
            widget.pet = nil
            cleanPetInfo(widget)
        end
    end)

    for i = 1, 3 do
        local sg = sk:createSimpleGroup()
        sg:SetLayout("Flow")
        sg:SetFullWidth(true)
        sg.slot = i

        local iconGroup = sk:createSimpleGroup();
        iconGroup:SetLayout("Flow")
        iconGroup:SetRelativeWidth(.05)
        sg:AddChild(iconGroup)

        local upArrow = sk:createInteractiveLabel()
        if i > 1 then
            upArrow:SetImage([[Interface\Addons\Skym_PetCodex\Textures\glyphicons_213_up_arrow]])
            upArrow:SetImageSize(8, 8)
            upArrow:SetHighlight(1.0, 0.0, 0.0, .5)
        end
        upArrow:SetRelativeWidth(.30)
        upArrow:SetCallback("OnClick", function()
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i - 1]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i - 1] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = nil
            upArrow:fireEvent("TEAM_SELECTED")
        end)
        iconGroup:AddChild(upArrow)

        local downArrow = sk:createInteractiveLabel()
        if i < 3 then
            downArrow:SetImage([[Interface\Addons\Skym_PetCodex\Textures\glyphicons_212_down_arrow]])
            downArrow:SetImageSize(8, 8)
            downArrow:SetHighlight(1.0, 0.0, 0.0, .5)
        end
        downArrow:SetRelativeWidth(.30)
        downArrow:SetCallback("OnClick", function()
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i + 1]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i + 1] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"]
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = nil
            downArrow:fireEvent("TEAM_SELECTED")
        end)
        iconGroup:AddChild(downArrow)

        local deleteCheck = sk:createInteractiveLabel()
        deleteCheck:SetImage([[Interface\Addons\Skym_PetCodex\Textures\glyphicons_207_remove_2]])
        deleteCheck:SetImageSize(8, 8)
        deleteCheck:SetRelativeWidth(.30)
        deleteCheck:SetHighlight(1.0, 0.0, 0.0, .5)
        deleteCheck:SetCallback("OnClick", function()
            Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i] = nil
            deleteCheck:fireEvent("TEAM_SELECTED")
        end)
        iconGroup:AddChild(deleteCheck)

        local labelGroup = sk:createSimpleGroup();
        labelGroup:SetLayout("Flow")
        labelGroup:SetRelativeWidth(.20)

        local il = sk:createInteractiveLabel()
        il:SetRelativeWidth(1)
        il:SetHighlight(1.0, 0.0, 0.0, .5)
        il:SetCallback("OnClick", function(info, event, button)
            if not Skym_PetCodex_TeamFrame.selection then return end
            if Skym_PetCodex_TeamFrame.CTRL then
            else
                if button == "LeftButton" and i ~= 3 then
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i + 1]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i + 1] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = nil
                    il:fireEvent("TEAM_SELECTED")
                end
                if button == "RightButton" and i ~= 1 then
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i - 1]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members[i - 1] = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"]
                    Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key].members["tmp"] = nil
                    il:fireEvent("TEAM_SELECTED")
                end
            end
        end)
        labelGroup:AddChild(il)

        il = sk:createLabel()
        il:SetRelativeWidth(1)
        labelGroup:AddChild(il)

        sg:AddChild(labelGroup)
        for a = 1, 3 do
            local dd = sk:createDropdown()
            dd.attack = a
            dd:SetRelativeWidth(.25)
            dd:SetCallback("OnValueChanged", function()
                local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
                p.members = p.members or {}
                local pet = p.members[sg.slot]
                pet.attacks = pet.attacks or {}
                local abilityIndex = a + (dd:GetValue() - 1) * 3
                pet.attacks[a] = { name = pet.abilities[abilityIndex].name, key = dd:GetValue() }
            end)
            sg:AddChild(dd)
        end

        cleanPetInfo(sg)
        teamGroup:AddChild(sg)
    end

    self.frame:AddChild(teamGroup)

    -- Les mascottes

    local petGroup = sk:createInlineGroup()
    petGroup:SetTitle("Mascottes")
    petGroup:SetFullWidth(true)
    petGroup:SetLayout("Flow")
    petGroup:SetFullHeight(true)
    self.frame:AddChild(petGroup)

    local box = sk:createEditBox()
    box:SetFullWidth(true)
    box:DisableButton(true)
    box:SetCallback("OnTextChanged", function()
        local liste = filterBattlePetList(box:GetText())
        box:fireEvent("BATTLE_PET_LIST_FILTERED", liste)
    end)
    box:SetCallback("OnEnterPressed", function()
        local liste = filterBattlePetList(box:GetText())
        box:fireEvent("BATTLE_PET_LIST_FILTERED", liste)
    end)
    petGroup:AddChild(box)

    local petScrollContainer = gui:Create("SimpleGroup")
    petScrollContainer:SetFullWidth(true)
    petScrollContainer:SetFullHeight(true)
    petScrollContainer:SetLayout("Fill")
    petGroup:AddChild(petScrollContainer)

    local petScroll = sk:createScrollFrame()
    petScroll:SetLayout("Flow")
    petScroll:addListener("BATTLE_PET_LIST_FILTERED", function(source, target, liste)
        target:ReleaseChildren()
        for level, rarities in lpairs(liste) do
            local separator = gui:Create("Heading")
            separator:SetText("Niveau " .. level)
            separator.width = "fill"
            target:AddChild(separator)
            for rarity, pets in lpairs(rarities) do
                for _, pet in pairs(pets) do
                    local check = sk:createCheckBox()
                    check:SetImage(pet.icon)
                    check:SetLabel(RARITY_COLOR[pet.rarity] .. pet.name .. "|r")
                    check:SetRelativeWidth(.50)
                    check.petId = pet.id
                    if Skym_PetCodex_TeamFrame.selection then
                        local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
                        p.members = p.members or {}
                        for _, spet in pairs(p.members) do
                            if pet.id == spet.id then
                                check:SetValue(true)
                            end
                        end
                    end
                    check.ToggleChecked = function(info)
                        if not check:GetValue() then
                            if not Skym_PetCodex_TeamFrame.selection then return end
                            if Skym_PetCodex_TeamFrame.petSelected == 3 then return end
                            Skym_PetCodex_TeamFrame.petSelected = Skym_PetCodex_TeamFrame.petSelected + 1
                            check:fireEvent("BATTLE_PET_SELECTED", pet)
                            check:SetValue(true)
                        else
                            Skym_PetCodex_TeamFrame.petSelected = Skym_PetCodex_TeamFrame.petSelected - 1
                            check:fireEvent("BATTLE_PET_UNSELECTED", pet)
                            check:SetValue(false)
                        end
                    end
                    target:AddChild(check)
                end
            end
        end
    end)
    petScroll:addListener("TEAM_SELECTED", function(source, target)
        Skym_PetCodex_TeamFrame.petSelected = 0
        for _, widget in pairs(target.children) do
            if widget.petId then
                widget:SetValue(false)
                local p = Skym_PetCodex.db.global.presets[Skym_PetCodex_TeamFrame.selection.key]
                p.members = p.members or {}
                for _, pet in pairs(p.members) do
                    if pet and pet.id == widget.petId then
                        widget:SetValue(true)
                        Skym_PetCodex_TeamFrame.petSelected = Skym_PetCodex_TeamFrame.petSelected + 1
                    end
                end
            end
        end
    end)
    petScroll:addListener("PRESET_CHANGED", function(source, target)
        Skym_PetCodex_TeamFrame.petSelected = 0
        for _, widget in pairs(target.children) do
            if widget.petId then
                widget:SetValue(false)
            end
        end
    end)
    petScrollContainer:AddChild(petScroll)

    self.frame:AddChild(petGroup)

    Skym_PetCodex_TeamFrame.petSelected = 0

    self.frame:fireEvent("PRESET_CHANGED")
    local liste = filterBattlePetList(nil)
    self.frame:fireEvent("BATTLE_PET_LIST_FILTERED", liste)

    if Skym_PetCodex.db.global.selection then
        for _, label in pairs(teamsListScroll.children) do
            if label.key == Skym_PetCodex.db.global.selection then
                if label.overlay then
                    label.overlay:Show()
                else
                    local overlay = label.frame:CreateTexture(nil, "OVERLAY")
                    overlay:SetTexture(nil)
                    overlay:SetAllPoints()
                    overlay:SetBlendMode("ADD")
                    overlay:SetTexture(0.0, 0.0, 1.0, 0.5)
                    label.overlay = overlay
                end
                Skym_PetCodex_TeamFrame.selection = label
                label:fireEvent("TEAM_SELECTED")
            end
        end
    end
end

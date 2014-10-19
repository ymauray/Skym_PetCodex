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

Skym_PetCodex = LibStub("AceAddon-3.0"):NewAddon("Skym_PetCodex", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")

-- local Skym_PetCodex_Frame

-- Variables globales

Skym_PetCodex.frame = nil
Skym_PetCodex.nbPetSelected = 0

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
AceConfigDialog:SetDefaultSize("Skym_PetCodex", 680, 525)

local options = {
    name = "Skym_PetCodex",
    handler = Skym_PetCodex,
    type = "group",
    name = "Skym : PetCodex v0.1.0 - (c) 2013 Yannick & Sandrine",
    args = {
        selection = {
            type = "group",
            name = "Option de sélection",
            inline = true,
            args = {
                disableOnMultipleSelection = {
                    type = "toggle",
                    name = "Griser",
                    desc = "Griser les sélections supplémentaires lorsqu'une mascotte est sélectionnée plusieurs fois",
                    tristate = false,
                    set = function(info, value)
                        Skym_PetCodex.disableOnMultipleSelection = value
                        Skym_PetCodex.db.global.disableOnMultipleSelection = value
                    end,
                    get = function(info)
                        return Skym_PetCodex.disableOnMultipleSelection
                    end
                },
                autoload = {
                    type = "toggle",
                    name = "Chargement auto.",
                    -- /pink
                    desc = "Charger automatiquement l'équippe correspondant à la mascotte de combat ciblée.",
                    tristate = false,
                    set = function(info, value)
                        Skym_PetCodex.db.global.autoload = value
                    end,
                    get = function(info)
                        return Skym_PetCodex.db.global.autoload
                    end
                },
            },
        },
        presentation = {
            type = "group",
            name = "Options de présentation de mes mascottes",
            inline = true,
            args = {
                rarity = {
                    type = "select",
                    name = "Rareté",
                    desc = "Rareté minimum à prendre en compte pour la sélection de mes mascottes",
                    values = {
                        [1] = "Toutes",
                        [3] = "Inhabituelle et plus",
                        [4] = "Rare et plus"
                    },
                    set = function(info, value)
                        Skym_PetCodex.rarityThreshold = value
                        Skym_PetCodex.db.global.rarityThreshold = value
                    end,
                    get = function(info)
                        return Skym_PetCodex.rarityThreshold
                    end,
                },
                level = {
                    type = "input",
                    name = "Niveau minimum",
                    desc = "Niveau mininum à prendre en compte pour la sélection de mes mascottes",
                    validate = function(info, value)
                        value = tonumber(value)
                        if type(value) == "nil" then return "Veuillez saisir un nombre" else return true end
                    end,
                    set = function(info, value)
                        Skym_PetCodex.levelThreshold = tonumber(value)
                        Skym_PetCodex.db.global.levelThreshold = tonumber(value)
                    end,
                    get = function(info)
                        return tostring(Skym_PetCodex.levelThreshold)
                    end
                }
            },
        },
    },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Skym_PetCodex", options);

function Skym_PetCodex:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("Skym_PetCodexDB");

    self.rarityThreshold = self.db.global.rarityThreshold or 3
    self.levelThreshold = self.db.global.levelThreshold or 20
    self.disableOnMultipleSelection = self.db.global.disableOnMultipleSelection or true
    self.db.global.teams = self.db.global.teams or {}
    self.db.global.minLevel = self.db.global.minLevel or 1
    self.db.global.maxLevel = self.db.global.maxLevel or 25
    self.db.global.presets = self.db.global.presets or {}

    -- PATCH pour récupérer les données sans speciesID
    for targetSpeciesID, team in pairs(self.db.global.teams) do
        for index, petData in pairs(team) do
            if not petData["speciesID"] then
                local _, speciesID = C_PetJournal.GetPetInfoByIndex(petData["index"])
                petData["speciesID"] = speciesID
            end
        end
    end

    self.inCombat = false
    self:RegisterEvent("PET_BATTLE_OPENING_START", function()
    -- TODO
    end)

    Skym_PetCodex:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        Skym_PetCodex.inCombat = true
    end)

    Skym_PetCodex:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        Skym_PetCodex.inCombat = false
    end)

    self:Print("Add-on Skym_PetCodex initialisé");
end

Skym_PetCodex:RegisterChatCommand("petcodex", "ChatCommand");

local function resetPetJournalFilters()
    C_PetJournal.AddAllPetSourcesFilter()
    C_PetJournal.AddAllPetTypesFilter()
    C_PetJournal.ClearSearchFilter()
end

function targetIsBattlePet()

    resetPetJournalFilters()

    local isBattlePet = false
    local targetUnitName = UnitName("target")

    if targetUnitName then
        local targetSpeciesID = C_PetJournal.FindPetIDByName(targetUnitName)
        if targetSpeciesID then
            isBattlePet = true
        end
    end

    return isBattlePet
end

local function loadTeamForSpeciesID(speciesID)
    if not Skym_PetCodex.db.global.teams[speciesID] then
        Skym_PetCodex.db.global.teams[speciesID] = {}
    end

    local i
    for i = 1, 3 do
        local data = Skym_PetCodex.db.global.teams[speciesID][i]
        if data then
            data.attacks = data.attacks or {}
            C_PetJournal.SetPetLoadOutInfo(i, data.petID)
            local myPetAbilitiesIDTable, myPetAbilitiesLevelTable = C_PetJournal.GetPetAbilityList(data.speciesID)
            for a = 1, 3 do
                if data.attacks[a] then
                    C_PetJournal.SetAbility(i, a, myPetAbilitiesIDTable[a + (data.attacks[a] - 1) * 3])
                end
            end
        end
    end
end

function Skym_PetCodex:loadTeamForTarget()
    local targetUnitName = UnitName("target")
    local targetSpeciesID = C_PetJournal.FindPetIDByName(targetUnitName)
    loadTeamForSpeciesID(targetSpeciesID)
end

--
-- ChatCommand : traitement de la commande "/petcodex"
function Skym_PetCodex:ChatCommand(input)

    -- On sort vite si l'on est en combat.
    -- if self.inCombat then return end

    -- Si aucun paramètre passé à la commande : ouverture de la fenêtre principale
    -- Si le paramètre "config" est passé à la commande, ouverture de la fenêtre de configuration
    if not input or input:trim() == "" then

        -- Si la cible n'est pas une mascotte de combat, on n'ouvre pas la fenêtre.
        -- if not targetIsBattlePet() then return end

        if targetIsBattlePet() then

            Skym_PetCodex_Frame:ShowFrame()
            --Skym_PetCodex_MainFrame:showFrame()

        else

            Skym_PetCodex_TeamFrame:showFrame()
        end

    elseif input:trim() == "config" then

        AceConfigDialog:Open("Skym_PetCodex")
    end
end

--
-- Fonction de rappel pour l'évènement "PLAYER_TARGET_CHANGED"
--
-- Cette fonction est appelée lorsque l'on clique sur une cible
-- 
function Skym_PetCodex:PLAYER_TARGET_CHANGED(eventName, ...)

    -- On sort vite si l'on est en combat.
    if self.inCombat then return end

    -- On vérifie que la cible est bien une mascotte de combat
    if not targetIsBattlePet() then return end

    -- Tout va bien, on charge la team prédéfinie.
    if self.db.global.autoload then
        self:loadTeamForTarget()
    end
end

--
-- Initialisation de l'addon. Cette fonction est appelée
-- automatiquement par AceAddon
--
function Skym_PetCodex:OnEnable()
    self:Print("Add-on Skym_PetCodex activé")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    Skym_PetCodex_Frame = self:GetModule("Skym_PetCodex_Frame")
end

--
-- Désactivation de l'addon. Cette fonction est appelée
-- Automatiquement par AceAddon.
-- Note : je n'ai encore jamais vu cette fonction être appelée.
--
function Skym_PetCodex:OnDisable()
    self:Print("Add-on Skym_PetCodex désactivé")
end

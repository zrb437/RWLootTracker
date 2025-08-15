-- Dies ist die Listener-Datei, die sich um die Beute-Events kütert.

-- Zugriff auf globale Addon-Datenbank und Konfiguration
-- LootTrackerDB und LootTrackerConfig werden von RWLootTracker.lua global definiert
-- und sollten hier direkt verfügbar sein.

-- Hilfsfunktion für Debug-Ausgaben
local function DebugPrint(msg)
    -- Sicherstellen, dass LootTrackerConfig und DebugMode existieren, bevor darauf zugegriffen wird
    if LootTrackerConfig and LootTrackerConfig.DebugMode then
        print("RWLootTracker: " .. msg)
    end
end

-- Hilfsfunktion, um zu überprüfen, ob die Beute in der aktuellen Instanz getrackt werden soll
local function ShouldTrackInstance()
    local inInstance, instanceType, difficultyID = IsInInstance()
    local instanceName, instanceMapID, difficultyName, maxPlayers, isDynamic, instanceID, instanceGroupSize = GetInstanceInfo()
    
    if inInstance and trackedInstanceTypes[instanceType] then
        if instanceType == "raid" then
            if trackedRaidDifficulties[difficultyID] then
                DebugPrint(string.format("Instanz verfolgen: %s (%s, %s)", instanceName, difficultyName, instanceType))
                return true
            else
                DebugPrint(string.format("Instanz NICHT verfolgen: %s (%s). Schwierigkeitsgrad nicht aktiviert.", instanceName, difficultyName))
                return false
            end
        else
            DebugPrint(string.format("Instanz verfolgen: %s (%s)", instanceName, instanceType))
            return true
        end
    elseif not inInstance and trackedInstanceTypes.none then
        DebugPrint("Instanz verfolgen: Offene Welt (none)")
        return true
    else
        DebugPrint(string.format("Instanz NICHT verfolgen: Instanztyp '%s' nicht aktiviert.", instanceType or "none"))
        return false
    end
end

-- Zuordnung von Enum.LootRollType-Werten (Zahlen) zu ihren String-Namen
-- Wird hier beibehalten, auch wenn eine detailliertere Logik für rollTypeName verwendet wird.
local ROLL_TYPE_MAPPING = {
    [0] = "NEED",
    [1] = "GREED",
    [2] = "DISENCHANT",
    [3] = "PASS",
}

local trackedRaidDifficulties = {
    [14] = false,  -- LFR
    [15] = true,  -- Normal
    [16] = true,  -- Heroisch
    [17] = true,  -- Mythisch
}

-- Erstelle einen separaten Frame nur für den Listener, um Events zu registrieren
local listenerFrame = CreateFrame("Frame")
listenerFrame:RegisterEvent("LOOT_HISTORY_UPDATE_DROP")

-- Setze das Skript, um Events zu behandeln
listenerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "LOOT_HISTORY_UPDATE_DROP" then
        local encounterID, lootListID = ...

        -- Nur Drops verarbeiten, wenn die aktuelle Instanz getrackt werden soll
        if not ShouldTrackInstance() then return end

        local dropInfo = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListID)
        -- Stelle sicher, dass dropInfo und Item-Hyperlink gültig sind
        if not dropInfo or not dropInfo.itemHyperlink then return end

        if dropInfo.winner then
            local item = Item:CreateFromItemLink(dropInfo.itemHyperlink)
            local itemName = item:GetItemName()
            local itemID = select(1, GetItemInfoInstant(dropInfo.itemHyperlink))
            local encounterInfo = C_LootHistory.GetInfoForEncounter(encounterID)
            local bossName = encounterInfo and encounterInfo.encounterName or "Unbekannt"

            local rollTypeName = "Unbekannt"
            local rollValue = 0
            if dropInfo.rollInfos then
                for _, roll in ipairs(dropInfo.rollInfos) do
                    if roll.isWinner then
                        local rollType = roll.state
                        rollValue = roll.roll
                        if rollType == Enum.EncounterLootDropRollState.NeedMainSpec then
                            rollTypeName = "Need (Main Spec)"
                        elseif rollType == Enum.EncounterLootDropRollState.NeedOffSpec then
                            rollTypeName = "Need (Off Spec)"
                        elseif rollType == Enum.EncounterLootDropRollState.Greed then
                            rollTypeName = "Greed"
                        elseif rollType == Enum.EncounterLootDropRollState.Transmog then
                            rollTypeName = "Transmog"
                        elseif rollType == Enum.EncounterLootDropRollState.Pass then
                            rollTypeName = "Pass"
                        else
                            rollTypeName = "Unbekannt" -- Fallback für unerwartete Rollzustände
                        end
                        break -- Wir haben den Gewinner gefunden, Schleife beenden
                    end
                end
            end

            local _, _, _, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(dropInfo.itemHyperlink)

            local armorType = ""
            if itemType == "Armor" then
                armorType = itemSubClass or "Unbekannt"
            elseif itemType == "Weapon" then
                armorType = "Waffe"
            else
                armorType = itemType or "Sonstiges"
            end

            local itemSlot = ""
            if itemEquipLoc and _G[itemEquipLoc] then
                itemSlot = _G[itemEquipLoc]
            elseif itemEquipLoc then
                itemSlot = itemEquipLoc
            else
                itemSlot = "Nicht ausrüstbar"
            end

            local fullTime = date("%Y-%m-%d %H:%M:%S")
            local dateOnly = date("%Y-%m-%d")

            -- Zusätzliche Informationen aus dropInfo.winner und erweiterte Logik für Klasse/Spezialisierung
            local playerGUID = dropInfo.winner.playerGUID or "Unbekannt"
            local playerClass = "Unbekannt"
            local playerSpecialization = dropInfo.winner.specialization or "Unbekannt"

            -- Versuche, die Klasse über GetPlayerInfoByGUID zu ermitteln und zu lokalisieren
            if playerGUID ~= "Unbekannt" then
                -- Der erste Rückgabewert von GetPlayerInfoByGUID ist die lokalisierte Klasse.
                local locClassString, _, _, _, _, _, _ = GetPlayerInfoByGUID(playerGUID)
                if locClassString then
                    playerClass = locClassString
                end
            end


            -- Sicherstellen, dass LootTrackerDB existiert, bevor darauf zugegriffen wird
            LootTrackerDB = LootTrackerDB or {}
            LootTrackerDB[dateOnly] = LootTrackerDB[dateOnly] or {}

            table.insert(LootTrackerDB[dateOnly], {
                time = fullTime,
                player = dropInfo.winner.playerName,
                playerGUID = playerGUID,
                playerClass = playerClass,
                playerSpecialization = playerSpecialization,
                item = dropInfo.itemHyperlink,
                itemID = itemID,
                itemName = itemName,
                method = rollTypeName,
                rollValue = rollValue,
                boss = bossName,
                armorType = armorType,
                slot = itemSlot,
                dateOnly = dateOnly
            })

            -- Sicherstellen, dass LootTrackerConfig existiert, bevor darauf zugegriffen wird
            if LootTrackerConfig and LootTrackerConfig.LogToChat then
                print("RWLootTracker: Gewinner erkannt: " .. dropInfo.winner.playerName .. " (" .. playerClass .. ", " .. playerSpecialization .. ", GUID: " .. playerGUID .. "), " .. itemName .. " (Roll: " .. rollTypeName .. ", Wert: " .. rollValue .. ")")
            end

            -- Speichere die Daten nach jedem Loot-Drop
            if RWLootTrackerGlobal.SaveLootData then
                RWLootTrackerGlobal.SaveLootData()
            else
                DebugPrint("FEHLER: RWLootTrackerGlobal.SaveLootData ist NIL! Daten können nicht sofort gespeichert werden.")
            end
        end
    end
end)

DebugPrint("Listener-Modul geladen (Version " .. RWLootTrackerGlobal.Version .. ").")

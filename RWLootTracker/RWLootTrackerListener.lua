-- Dies ist die Listener-Datei, die sich um die Beute-Events kümmert.

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
    -- Sicherstellen, dass LootTrackerConfig und trackInstanceTypes existieren
    if not LootTrackerConfig or not LootTrackerConfig.trackInstanceTypes then
        DebugPrint("Konfiguration für Instanztypen nicht geladen.")
        return false
    end

    local inInstance, instanceType = IsInInstance()

    if inInstance then
        return LootTrackerConfig.trackInstanceTypes[instanceType] == true
    else
        return LootTrackerConfig.trackInstanceTypes.none == true
    end
end

-- Die alte ROLL_TYPE_MAPPING Tabelle ist nicht mehr direkt notwendig, da wir die Enums abfragen.
-- Trotzdem lassen wir sie hier, falls noch andere Verwendungen bestehen oder zur Referenz.
local ROLL_TYPE_MAPPING = {
    [0] = "NEED",       -- Entspricht Enum.LootRollType.Need
    [1] = "GREED",      -- Entspricht Enum.LootRollType.Greed
    [2] = "DISENCHANT", -- Entspricht Enum.LootRollType.Disenchant
    [3] = "PASS",       -- Entspricht Enum.LootRollType.Pass
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

            -- START NEUE LOGIK FÜR rollTypeName
            local rollTypeName = "Unbekannt"
            if dropInfo.rollInfos then
                for _, roll in ipairs(dropInfo.rollInfos) do
                    if roll.isWinner then
                        local rollType = roll.state
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
            -- ENDE NEUE LOGIK FÜR rollTypeName

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


            -- Sicherstellen, dass LootTrackerDB existiert, bevor darauf zugegriffen wird
            LootTrackerDB = LootTrackerDB or {}
            LootTrackerDB[dateOnly] = LootTrackerDB[dateOnly] or {}

            table.insert(LootTrackerDB[dateOnly], {
                time = fullTime,
                player = dropInfo.winner.playerName,
                item = dropInfo.itemHyperlink,
                itemID = itemID,
                itemName = itemName,
                method = rollTypeName,
                boss = bossName,
                armorType = armorType,
                slot = itemSlot,
                dateOnly = dateOnly
            })

            -- Sicherstellen, dass LootTrackerConfig existiert, bevor darauf zugegriffen wird
            if LootTrackerConfig and LootTrackerConfig.LogToChat then
                print("RWLootTracker: Gewinner erkannt: " .. dropInfo.winner.playerName .. ", " .. itemName .. " (Roll: " .. rollTypeName .. ")")
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

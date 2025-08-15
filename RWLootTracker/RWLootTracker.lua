-- RWLootTracker.lua
-- Dies ist die Haupt-Initialisierungsdatei des Addons.
-- Sie definiert globale Variablen, Event-Handler und zentrale Funktionen.

-- Globale Referenz für Addon-Funktionen und -Daten.
-- Dies wird von allen anderen Modulen verwendet, um miteinander zu kommunizieren.
RWLootTrackerGlobal = RWLootTrackerGlobal or {}

-- Standardkonfiguration des Addons.
-- Diese Tabelle wird von WoW automatisch gespeichert und geladen (siehe .toc-Datei).
-- Neue Einstellungen sollten hier mit ihren Standardwerten hinzugefügt werden.
LootTrackerConfig = LootTrackerConfig or {} -- Wird unten durch ApplyDefaults initialisiert

-- Addon-Datenbank für Beute-Einträge
-- Die Struktur wird jetzt sein: LootTrackerDB[Datum_String] = { {Beute-Eintrag 1}, {Beute-Eintrag 2}, ... }
LootTrackerDB = LootTrackerDB or {}

-- Versionsnummer des Addons (jetzt global über RWLootTrackerGlobal verfügbar)
RWLootTrackerGlobal.Version = "0.3.0"

-- Standardkonfiguration für das Addon
local defaults = {
    DebugMode = false, -- Aktiviert zusätzliche Debug-Ausgaben im Chat
    LogToChat = true,  -- Sendet Beute-Meldungen an den Chat
    trackInstanceTypes = { -- Welche Instanztypen getrackt werden sollen
        raid = true,
        party = false,    -- Dungeons/Gruppen
        pvp = false,      -- Schlachtfelder/Arenen
        scenario = false, -- Szenarien
        none = false,     -- Offene Welt / Weltbosse (wenn keine Instanz)
    },
}

-- Hilfsfunktion für Debug-Ausgaben
-- Diese Funktion prüft den DebugMode in LootTrackerConfig, um Ausgaben zu steuern.
local function DebugPrint(msg)
    -- Sicherstellen, dass LootTrackerConfig und DebugMode existieren, bevor darauf zugegriffen wird
    if LootTrackerConfig and LootTrackerConfig.DebugMode then
        print("RWLootTracker.lua: " .. msg)
    end
end

-- Funktion zum rekursiven Anwenden von Standardwerten.
-- Dies stellt sicher, dass alle Untertabellen und Werte aus 'defaults' in 'targetTable' vorhanden sind,
-- wenn sie dort nicht bereits definiert sind.
local function ApplyDefaults(targetTable, defaultTable)
    for k, v in pairs(defaultTable) do
        if type(v) == "table" then
            -- Wenn der Standardwert eine Tabelle ist, und der Zielwert keine Tabelle ist,
            -- oder nicht existiert, erstelle eine leere Tabelle im Ziel und rufe rekursiv auf.
            if type(targetTable[k]) ~= "table" then
                targetTable[k] = {}
            end
            ApplyDefaults(targetTable[k], v) -- Rekursiver Aufruf für verschachtelte Tabellen
        elseif targetTable[k] == nil then
            -- Wenn der Schlüssel im Ziel nicht existiert, setze den Standardwert
            targetTable[k] = v
        end
    end
end

-- Globale Referenzen für GUI-Elemente, die von RWLootTrackerViewer.lua gesetzt werden.
-- Diese müssen hier deklariert werden, damit sie auch in den anderen Skripten global zugänglich sind.
-- Sie werden später in RWLootTrackerViewer.lua mit den tatsächlichen Frame-Objekten befüllt.
-- Sie werden jetzt als Felder von RWLootTrackerGlobal behandelt.
RWLootTrackerGlobal.lootTrackerFrame = nil        -- Haupt-Addon-Frame
RWLootTrackerGlobal.lootDatabasePanel = nil       -- Panel für die Beute-Datenbank
RWLootTrackerGlobal.settingsPanel = nil           -- Panel für die Einstellungen
RWLootTrackerGlobal.tabButtons = {}               -- Tabelle der Tab-Buttons
RWLootTrackerGlobal.calendarFrame = nil           -- Neuer Frame für den Kalender
RWLootTrackerGlobal.currentCalendarDate = date("*t") -- Aktuelles Datum des Kalenders (tabelle)
RWLootTrackerGlobal.lootDetailsFrame = nil        -- Neues Frame für die Beute-Details

-- Funktion: RWLootTrackerGlobal.SaveLootData
-- Diese Funktion ist dafür vorgesehen, eine Speicherung der Addon-Daten auszulösen.
-- Da LootTrackerConfig und LootTrackerDB in der .toc-Datei als SavedVariables deklariert sind,
-- werden sie von WoW automatisch beim Beenden des Spiels oder Neuladen des UIs gespeichert.
-- Ein expliziter Aufruf dieser Funktion ist nur notwendig, wenn eine sofortige Speicherung
-- nach einer wichtigen Datenänderung (z.B. dem Leeren der Datenbank) erzwungen werden soll,
-- bevor der automatische Speichermechanismus greift.
-- Es gibt keine direkte WoW API-Funktion wie `SaveVariable("MyVariable")`.
-- Stattdessen nutzt man den internen Mechanismus über das Addon-Objekt.
function RWLootTrackerGlobal.SaveLootData()
    DebugPrint("SaveLootData: Speicherung der Beutedaten ausgelöst.")
    
    -- Überprüfen, ob das Addon-Objekt verfügbar ist, um SaveVariables aufzurufen.
    -- Dies ist eine gängige Methode, um SavedVariables sofort zu speichern.
    local addon = _G["RWLootTracker"] -- Holt das Addon-Objekt (Registriert über RegisterAddon in WoW)
    if addon and addon.SaveVariables then
        addon:SaveVariables() -- Ruft die Speichermethode des Addons auf
        DebugPrint("SaveLootData: Addon-Variablen über SaveVariables() gespeichert.")
    else
        DebugPrint("SaveLootData: Addon-Objekt oder SaveVariables() nicht gefunden. Automatische Speicherung durch WoW wird erwartet.")
    end
end


-- Erstelle den Haupt-Frame, um Events zu registrieren
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN") -- Für die Konfigurationsinitialisierung bei jedem Login

-- Setze das Skript, um Events zu behandeln
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Stelle sicher, dass LootTrackerConfig korrekt mit Standardwerten initialisiert ist
        ApplyDefaults(LootTrackerConfig, defaults)
        print("RWLootTracker geladen und bereit (Version " .. RWLootTrackerGlobal.Version .. ").")
    end
end)


-- **Slash-Befehle registrieren**
SLASH_RWLOOTTRACKER1 = "/rwloottracker"
SLASH_RWLOOTTRACKER2 = "/rwl"

SlashCmdList["RWLOOTTRACKER"] = function(msg)
    -- Hier wird die Funktion aus RWLootTrackerViewer.lua aufgerufen
    if RWLootTrackerGlobal.CreateGUI and type(RWLootTrackerGlobal.CreateGUI) == "function" then
        RWLootTrackerGlobal.CreateGUI()
    else
        print("RWLootTracker: GUI-Modul nicht geladen oder CreateGUI-Funktion nicht verfügbar. Bitte Addon neuladen.")
    end
end

DebugPrint("Core-Modul RWLootTracker.lua geladen. Version " .. RWLootTrackerGlobal.Version .. ".")

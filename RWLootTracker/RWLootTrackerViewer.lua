-- Dies ist die Viewer-Datei, die sich um die Darstellung der GUI kümmert.

-- Zugriff auf globale Addon-Datenbank und Konfiguration
-- LootTrackerDB, LootTrackerConfig, RWLootTrackerGlobal und dessen Felder
-- lootTrackerFrame, settingsPanel, tabButtons, calendarFrame, currentCalendarDate, lootDetailsFrame
-- werden von RWLootTracker.lua global definiert.

-- Hilfsfunktion für Debug-Ausgaben
local function DebugPrint(msg)
    if LootTrackerConfig.DebugMode then
        print("RWLootTracker: " .. msg)
    end
end

-- Hilfsfunktion, um die exportierten Daten zu aktualisieren (für das Loot-Details-Fenster)
local function UpdateLootDetailsText(editBox, selectedDate)
    DebugPrint("UpdateLootDetailsText: selectedDate erhalten: " .. tostring(selectedDate))
    if not editBox then DebugPrint("UpdateLootDetailsText: FEHLER: editBox ist NIL!") return end
    if not editBox:IsVisible() then DebugPrint("UpdateLootDetailsText: Warnung: editBox ist nicht sichtbar!") end
    if not editBox:GetParent():IsVisible() then DebugPrint("UpdateLootDetailsText: Warnung: Parent scrollBox ist nicht sichtbar!") end

    local scrollBox = editBox:GetParent()
    if scrollBox then
        -- Explizite Größenanpassung des EditBox an den ScrollFrame
        editBox:SetPoint("TOPLEFT", scrollBox, "TOPLEFT")
        editBox:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT")
        editBox:SetWidth(scrollBox:GetWidth()) -- Beibehalten als zusätzliche Absicherung
        editBox:SetHeight(scrollBox:GetHeight()) -- Beibehalten als zusätzliche Absicherung
        DebugPrint(string.format("UpdateLootDetailsText: editBox Größe nach Anpassung: %.2fx%.2f", editBox:GetWidth(), editBox:GetHeight()))
    else
        DebugPrint("UpdateLootDetailsText: scrollBox ist NIL. Kann editBox nicht anpassen.")
    end
    DebugPrint(string.format("UpdateLootDetailsText: scrollBox Größe: %.2fx%.2f", scrollBox:GetWidth(), scrollBox:GetHeight()))


    local lines = {} -- Initialisiere lines als leere Tabelle
    local entriesToDisplay = LootTrackerDB[selectedDate] or {}

    DebugPrint("UpdateLootDetailsText: Anzahl der Einträge für " .. selectedDate .. ": " .. #entriesToDisplay)
    if #entriesToDisplay == 0 then
        DebugPrint("UpdateLootDetailsText: Keine Daten gefunden für " .. selectedDate .. ". LootTrackerDB[" .. selectedDate .. "] ist leer oder nil.")
        -- Keine Header-Zeile hinzufügen, wenn keine Daten vorhanden sind
    else
        -- Aktualisierter Header mit neuen Feldern
        table.insert(lines, "Zeit\tBoss\tSpieler\tGUID\tKlasse\tSpezialisierung\tGegenstand\tItemname\tItemID\tRollart\tRollwert\tRüstungstyp\tSlot")
    end

    for _, entry in ipairs(entriesToDisplay) do
        -- Aktualisierte Formatierung für jede Zeile mit neuen Feldern
        table.insert(lines, string.format('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',
            entry.time or "",
            entry.boss or "",
            entry.player or "",
            entry.playerGUID or "",         -- NEU: Spieler GUID
            entry.playerClass or "",        -- NEU: Spieler Klasse
            entry.playerSpecialization or "", -- NEU: Spieler Spezialisierung
            entry.item or "",
            entry.itemName or "",
            entry.itemID or "",
            entry.method or "",
            entry.rollValue or "",          -- NEU: Rollwert
            entry.armorType or "",
            entry.slot or ""
        ))
    end
    editBox:SetText(table.concat(lines, "\n"))
    -- editBox:HighlightText() -- Entfernt, da nicht notwendig für die Anzeige und potenziell problematisch
end

-- Funktion zum Erstellen/Anzeigen des Loot-Details-Fensters
local function ShowLootDetailsFrame(selectedDate)
    DebugPrint("ShowLootDetailsFrame aufgerufen für Datum: " .. tostring(selectedDate))
    if not RWLootTrackerGlobal.lootDetailsFrame then
        local f = CreateFrame("Frame", "LootTrackerDetailsFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(600, 400)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("TOOLTIP") -- Geändert zu TOOLTIP für höchste Sichtbarkeit
        f:SetFrameLevel(100) -- Hoher Level innerhalb des TOOLTIP Strata, um immer oben zu sein
        f:SetClampedToScreen(true) -- Sicherstellen, dass das Fenster auf dem Bildschirm bleibt

        f.title = f:CreateFontString(nil, "OVERLAY")
        f.title:SetFontObject("GameFontHighlight")
        f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
        f.title:SetText("Beute für den " .. selectedDate)
        f.title:SetTextColor(1, 1, 1, 1)

        -- Korrigierte Positionierung des Close Buttons für BasicFrameTemplateWithInset
        -- NICHT explizit SetPoint aufrufen, der Template sollte es handhaben
        f.CloseButton:SetScript("OnClick", function() f:Hide() end)


        local scrollBox = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scrollBox:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -45)
        scrollBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 15)
        scrollBox:SetFrameLevel(f:GetFrameLevel() + 1)
        
        local editBox = CreateFrame("EditBox", nil, scrollBox)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetAutoFocus(false)
        -- Setzt die EditBox, um den gesamten ScrollFrame-Bereich abzudecken
        editBox:SetPoint("TOPLEFT", scrollBox, "TOPLEFT")
        editBox:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT")
        editBox:SetMaxBytes(1000000)
        editBox:SetJustifyH("LEFT") -- Stellt sicher, dass der Text linksbündig ist
        editBox:SetJustifyV("TOP") -- Stellt sicher, dass der Text am oberen Rand beginnt
        scrollBox:SetScrollChild(editBox)
        f.editBox = editBox -- Referenz für UpdateLootDetailsText

        -- Explizite Größenanpassung des EditBox an den ScrollFrame nach der Initialisierung
        editBox:SetWidth(scrollBox:GetWidth())
        editBox:SetHeight(scrollBox:GetHeight())
        DebugPrint(string.format("ShowLootDetailsFrame: editBox Größe nach Initialisierung: %.2fx%.2f", editBox:GetWidth(), editBox:GetHeight()))

        editBox:SetTextColor(1, 1, 1, 1)

        RWLootTrackerGlobal.lootDetailsFrame = f
    end

    RWLootTrackerGlobal.lootDetailsFrame.title:SetText("Beute für den " .. selectedDate)
    UpdateLootDetailsText(RWLootTrackerGlobal.lootDetailsFrame.editBox, selectedDate)
    RWLootTrackerGlobal.lootDetailsFrame:Show()
    -- Entfernt: RWLootTrackerGlobal.lootDetailsFrame:SetFrameLevel(RWLootTrackerGlobal.lootDetailsFrame:GetFrameLevel() + 1) -- Bringt es bei jedem Aufruf nach vorne
end

-- Funktion zur Initialisierung des Kalenders
function RWLootTrackerGlobal.InitializeCalendar()
    -- Debug-Ausgabe: Prüfen, ob calendarFrame existiert, bevor darauf zugegriffen wird
    if not RWLootTrackerGlobal.calendarFrame then
        DebugPrint("RWLootTrackerGlobal.InitializeCalendar: calendarFrame ist NIL. Kann Kalender nicht initialisieren.")
        return
    end

    local year = RWLootTrackerGlobal.currentCalendarDate.year
    local month = RWLootTrackerGlobal.currentCalendarDate.month

    -- Setze den Titel des Kalenders
    RWLootTrackerGlobal.calendarFrame.monthYearText:SetText(date("%B %Y", time{year=year, month=month, day=1, hour=0, min=0, sec=0}))

    -- Hilfsfunktion, um den ersten Wochentag des Monats zu erhalten (0=Sonntag, 1=Montag...)
    -- Lua date() gibt 1 für Sonntag, 2 für Montag usw. zurück.
    local function GetFirstWeekdayOfMonth(year, month)
        local t = time{year=year, month=month, day=1, hour=0, min=0, sec=0}
        local weekday = tonumber(date("%w", t)) -- 0 für Sonntag, 1 für Montag, ... 6 für Samstag. Konvertiere zu Zahl.
        -- Passe an, um 1 für Montag, 7 für Sonntag zu haben
        return (weekday == 0) and 7 or weekday
    end

    local firstWeekday = GetFirstWeekdayOfMonth(year, month)
    local daysInMonth = tonumber(date("%d", time{year=year, month=month, day=28, hour=0, min=0, sec=0} + 4 * 86400)) -- Trick für Tage im Monat. Konvertiere zu Zahl.

    local dayIndex = 1
    for i = 1, 42 do -- 6 Reihen * 7 Tage
        local dayButton = RWLootTrackerGlobal.calendarFrame.dayButtons[i]
        -- Debug-Ausgabe: Prüfen, ob dayButton existiert
        if not dayButton then
            DebugPrint("RWLootTrackerGlobal.InitializeCalendar: dayButton[" .. i .. "] ist NIL.")
            break -- Schleife abbrechen, um weitere Fehler zu vermeiden
        end

        -- Berechne das tatsächliche Datum für diesen Button-Slot
        local dateOffset = i - firstWeekday
        local timestampForDay = time{year=year, month=month, day=1, hour=0, min=0, sec=0} + dateOffset * 86400
        local displayDay = tonumber(date("%d", timestampForDay)) -- Sicherstellen, dass es eine Zahl ist
        local displayMonth = tonumber(date("%m", timestampForDay)) -- Sicherstellen, dass es eine Zahl ist
        local displayYear = tonumber(date("%Y", timestampForDay)) -- Sicherstellen, dass es eine Zahl ist
        local fullDisplayDate = string.format("%04d-%02d-%02d", displayYear, displayMonth, displayDay) -- Format mit führenden Nullen

        dayButton.dateString = fullDisplayDate -- Speichere das vollständige Datum als String

        -- Prüfe, ob der Tag zum aktuellen Monat gehört
        local isCurrentMonthDay = (displayMonth == month and displayYear == year)

        -- Setze die Tag-Nummer, wenn es ein gültiger Tag im Kalender ist
        dayButton.text:SetText(displayDay)

        -- Prüfe, ob Daten für diesen Tag vorhanden sind (egal ob im aktuellen Monat oder nicht)
        local hasData = LootTrackerDB[fullDisplayDate] and #LootTrackerDB[fullDisplayDate] > 0
        DebugPrint(string.format("Button %d (%s): isCurrentMonthDay=%s, hasData=%s", i, fullDisplayDate, tostring(isCurrentMonthDay), tostring(hasData)))

        if isCurrentMonthDay then
            dayButton:Enable() -- Tage im aktuellen Monat sind klickbar
            if hasData then
                -- Highlighted (wie Screenshot 2)
                dayButton.bg:SetColorTexture(0.5, 0.1, 0.1, 0.9) -- Rötlicher Hintergrund
                dayButton.border:SetColorTexture(0.8, 0.2, 0.2, 1) -- Roter Rahmen
                dayButton.text:SetTextColor(1, 1, 0, 1) -- Gelber Text
            else
                -- Ausgegraut (wie Screenshot 1)
                dayButton.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5) -- Dunklerer, transparenterer Hintergrund
                dayButton.border:SetColorTexture(0.4, 0.4, 0.4, 0.8) -- Grauer Rahmen
                dayButton.text:SetTextColor(0.8, 0.8, 0.8, 1) -- Grauer Text
            end
        else
            -- Tage außerhalb des aktuellen Monats (Vormonat / Folgemonat)
            dayButton.text:SetText(displayDay) -- Zeige die Tageszahl auch für andere Monate
            dayButton.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3) -- Sehr dunkler, transparenter Hintergrund
            dayButton.border:SetColorTexture(0.3, 0.3, 0.3, 0.5) -- Dunkelgrauer Rahmen
            dayButton.text:SetTextColor(0.5, 0.5, 0.5, 0.6) -- Noch grauer und transparenter für Text
            dayButton:Disable() -- Tage außerhalb des Monats sind nicht klickbar
        end
    end
end

-- Hilfsfunktion zum Generieren von Debug-Beutedaten
local function GenerateDebugLootData()
    -- Leere die bestehende DB für frische Debug-Daten
    LootTrackerDB = {}

    -- Funktion zum Hinzufügen eines einzelnen Beute-Eintrags
    local function AddDebugEntry(dateOnly, timeSuffix, player, playerGUID, playerClass, playerSpecialization, itemLink, itemID, itemName, method, rollValue, boss, armorType, slot)
        LootTrackerDB[dateOnly] = LootTrackerDB[dateOnly] or {}
        table.insert(LootTrackerDB[dateOnly], {
            time = dateOnly .. " " .. timeSuffix,
            player = player,
            playerGUID = playerGUID,
            playerClass = playerClass,
            playerSpecialization = playerSpecialization,
            item = itemLink,
            itemID = itemID,
            itemName = itemName,
            method = method,
            rollValue = rollValue,
            boss = boss,
            armorType = armorType,
            slot = slot,
            dateOnly = dateOnly
        })
    end

    -- Generiere Daten für 5 verschiedene Tage
    for i = 0, 4 do -- i von 0 (heute) bis 4 (vor 4 Tagen)
        local currentTimestamp = time() - (86400 * i) -- 86400 Sekunden = 1 Tag
        local currentDate = date("%Y-%m-%d", currentTimestamp)

        -- Tag 1: Heute (i=0) - Corresponds to current day (e.g., 2025-06-05) if today is June 5th
        if i == 0 then
            AddDebugEntry(currentDate, "20:00:00", "SpielerA", "0x1234567890ABCDEF", "Krieger", "Furor", "|cffa335ee|Hitem:19019:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Donnerzorn, Gesegnete Klinge des Windsuchers]|h|r", 19019, "Donnerzorn", "Need (Main Spec)", 95, "Ragnaros", "Waffe", "Main Hand")
            AddDebugEntry(currentDate, "20:15:30", "SpielerB", "0xFEDCBA9876543210", "Magier", "Feuer", "|cff0070dd|Hitem:23072:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Helm des Schnellflugs]|h|r", 23072, "Helm des Schnellflugs", "Greed", 42, "Onyxia", "Stoff", "Kopf")
            AddDebugEntry(currentDate, "20:30:00", "SpielerC", "0x1234567812345678", "Paladin", "Schutz", "|cff1eff00|Hitem:124636:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Herz des Teufelspirschers]|h|r", 124636, "Herz des Teufelspirschers", "Bonus", 88, "Kael'thas Sunstrider", "Schmuckstück", "Schmuckstück")
        -- Tag 2: Gestern (i=1)
        elseif i == 1 then
            AddDebugEntry(currentDate, "19:00:00", "SpielerD", "0xABCDEF0123456789", "Todesritter", "Blut", "|cff0070dd|Hitem:49623:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Schiftung der Geißel des Eisens]|h|r", 49623, "Schiftung der Geißel des Eisens", "Need (Main Spec)", 70, "Lord Mark'gar", "Platte", "Schulter")
            AddDebugEntry(currentDate, "19:45:00", "SpielerE", "0x9876543210FEDCBA", "Jäger", "Tierherrschaft", "|cff1eff00|Hitem:50444:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Schattenmourne]|h|r", 50444, "Schattenmourne", "Need (Main Spec)", 99, "Lichkönig", "Waffe", "Zweihändig")
        -- Tag 3: Vor 2 Tagen (i=2)
        elseif i == 2 then
            AddDebugEntry(currentDate, "21:00:00", "SpielerF", "0xBA9876543210FEDC", "Druide", "Wiederherstellung", "|cff0070dd|Hitem:32371:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Kopfschmuck des Verwandlers]|h|r", 32371, "Kopfschmuck des Verwandlers", "Greed", 30, "Illidan Sturmgrimm", "Leder", "Kopf")
            AddDebugEntry(currentDate, "21:10:00", "SpielerG", "0x1FEDCBA987654321", "Priester", "Schatten", "|cffa335ee|Hitem:30720:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Aschenbringer]|h|r", 30720, "Aschenbringer", "Need (Main Spec)", 100, "Kel'Thuzad", "Waffe", "Zweihändig")
        -- Tag 4: Vor 3 Tagen (i=3)
        elseif i == 3 then
            AddDebugEntry(currentDate, "18:30:00", "SpielerH", "0x567890ABCDEF1234", "Schurke", "Täuschung", "|cff0070dd|Hitem:6948:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Defias-Lederweste]|h|r", 6948, "Defias-Lederweste", "Pass", 0, "Edwin VanCleef", "Leder", "Brust")
        -- Tag 5: Vor 4 Tagen (i=4)
        elseif i == 4 then
            AddDebugEntry(currentDate, "22:00:00", "SpielerI", "0xABCD1234EFGH5678", "Hexenmeister", "Dämonologie", "|cff1eff00|Hitem:13374:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Zulianischer Tiger]|h|r", 13374, "Zulianischer Tiger", "Need (Main Spec)", 60, "Hoher Priester Thekal", "Sonstiges", "Mount")
            AddDebugEntry(currentDate, "22:05:00", "SpielerJ", "0x87654321HGFE9876", "Mönch", "Braumeister", "|cff0070dd|Hitem:13375:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Raptor des Razzashi]|h|r", 13375, "Raptor des Razzashi", "Greed", 25, "Hoher Priester Venoxis", "Sonstiges", "Mount")
        end
    end

    local count = 0
    for k, v in pairs(LootTrackerDB) do
        count = count + 1
    end
    DebugPrint("Debug-Daten generiert. Anzahl der Tage in DB (gezählt): " .. count)

    -- Nach dem Generieren der Daten, Kalender aktualisieren, falls das GUI offen ist
    if RWLootTrackerGlobal.lootTrackerFrame and RWLootTrackerGlobal.lootTrackerFrame:IsVisible() then
        RWLootTrackerGlobal.InitializeCalendar()
        -- Wenn der Debug-Button in den Einstellungen gedrückt wurde, wechsel zur "Beute Datenbank"
        if RWLootTrackerGlobal.settingsPanel and RWLootTrackerGlobal.settingsPanel:IsVisible() then
            -- Finde den passenden Tab-Button für das lootDatabasePanel
            for _, btn in pairs(RWLootTrackerGlobal.tabButtons) do
                if btn.text:GetText() == "Beute Datenbank" then
                    -- Hier muss SwitchTab auch global sein oder direkt aufgerufen werden, wenn es im selben Modul ist.
                    -- Da SwitchTab in diesem Modul definiert ist, können wir es direkt aufrufen, wenn es in diesem Modul ist.
                    -- Da SwitchTab in diesem Modul definiert ist, können wir es direkt aufrufen, wenn es in diesem Modul ist.
                    -- Problem: SwitchTab ist eine lokale Funktion in CreateGUI.
                    -- Lösung: Wir müssen es global machen, damit es von hier aus aufgerufen werden kann.
                    -- Da dies ein Viewer-Modul ist, muss SwitchTab als Teil von RWLootTrackerGlobal verfügbar sein
                    -- oder die Logik zum Umschalten der Tabs muss aufgerufen werden, indem man die GUI neu erstellt.
                    -- Für die Vereinfachung machen wir SwitchTab vorerst global verfügbar.
                    RWLootTrackerGlobal.SwitchTab(btn, RWLootTrackerGlobal.lootDatabasePanel)
                    break
                end
            end
        end
    end
end

-- Funktion zum Initialisieren des Bestätigungs-Popups einmalig
function RWLootTrackerGlobal.InitializeConfirmDialog()
    DebugPrint("InitializeConfirmDialog: Dialog-Frame initialisiert.")
    local dialog = CreateFrame("Frame", "LootTrackerConfirmDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(350, 180)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("TOOLTIP") -- Höchste Sichtbarkeit
    dialog:SetFrameLevel(100) -- Hoher Level innerhalb der Strata
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide() -- Initial ausblenden

    dialog.titleText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.titleText:SetPoint("TOP", dialog, "TOP", 0, -10)
    dialog.titleText:SetTextColor(1, 1, 1, 1)

    dialog.messageText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dialog.messageText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 25, -60)
    dialog.messageText:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -25, -60)
    dialog.messageText:SetJustifyH("CENTER")
    dialog.messageText:SetJustifyV("TOP")
    dialog.messageText:SetTextColor(1, 1, 1, 1)
    dialog.messageText:SetMaxLines(5)

    dialog.confirmButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    dialog.confirmButton:SetSize(80, 25)
    dialog.confirmButton:SetPoint("BOTTOM", dialog, "BOTTOM", -45, 25)
    dialog.confirmButton:SetText("Ja")

    dialog.cancelButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
    dialog.cancelButton:SetSize(80, 25)
    dialog.cancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 45, 25)
    dialog.cancelButton:SetText("Nein")
    
    -- Close Button des Templates
    dialog.CloseButton:SetScript("OnClick", function() dialog:Hide() end)

    RWLootTrackerGlobal.confirmDialog = dialog -- Globale Referenz speichern
end

-- Funktion zum Anzeigen des Bestätigungs-Popups mit dynamischen Funktionen
function RWLootTrackerGlobal.ShowConfirmDialog(title, message, onConfirmCallback, onCancelCallback)
    DebugPrint("ShowConfirmDialog: Popup anzeigen für '" .. title .. "'")
    local dialog = RWLootTrackerGlobal.confirmDialog
    if not dialog then
        DebugPrint("ShowConfirmDialog: FEHLER: ConfirmDialog nicht initialisiert. Rufe InitializeConfirmDialog auf.")
        RWLootTrackerGlobal.InitializeConfirmDialog()
        dialog = RWLootTrackerGlobal.confirmDialog
        if not dialog then
            DebugPrint("ShowConfirmDialog: FEHLER: ConfirmDialog konnte auch nach Initialisierung nicht erstellt werden.")
            return
        end
    end

    dialog.titleText:SetText(title)
    dialog.messageText:SetText(message)

    dialog.confirmButton:SetScript("OnClick", function()
        DebugPrint("ConfirmDialog: Ja geklickt.")
        dialog:Hide() -- Popup ausblenden
        if onConfirmCallback then onConfirmCallback() end -- Aktion ausführen
    end)

    dialog.cancelButton:SetScript("OnClick", function()
        DebugPrint("ConfirmDialog: Nein geklickt.")
        dialog:Hide() -- Popup ausblenden
        if onCancelCallback then onCancelCallback() end -- Aktion ausführen
    end)

    dialog:Show()
    DebugPrint("ShowConfirmDialog: Popup Show() aufgerufen.")
end


-- Hauptfunktion zum Erstellen der GUI
function RWLootTrackerGlobal.CreateGUI()
    if RWLootTrackerGlobal.lootTrackerFrame then
        RWLootTrackerGlobal.lootTrackerFrame:Show()
        RWLootTrackerGlobal.InitializeCalendar() -- Kalender immer aktualisieren, wenn das GUI gezeigt wird.
        return
    end

    -- Initialisiere DebugMode, wenn noch nicht geschehen (z.B. bei erster GUI-Erstellung)
    LootTrackerConfig.DebugMode = LootTrackerConfig.DebugMode or false

    local f = CreateFrame("Frame", "LootTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    DebugPrint("RWLootTrackerGlobal.CreateGUI: lootTrackerFrame (f) nach CreateFrame: " .. tostring(f))
    if not f then
        DebugPrint("FEHLER: lootTrackerFrame (f) ist NIL nach CreateFrame!")
        return -- Beende die Funktion, wenn Frame-Erstellung fehlschlägt
    end

    f:SetSize(710, 600) -- Hauptfenster-Höhe und -Breite angepasst
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(2)
    f:SetClampedToScreen(true) -- Sicherstellen, dass das Hauptfenster auf dem Bildschirm bleibt

    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
    f.title:SetText("RWLootTracker") -- Nur Addon-Name als Haupttitel
    f.title:SetTextColor(1, 1, 1, 1)

    -- Hintergrundleiste für die Tabs, spanning the main frame's width
    local tabAreaBackground = f:CreateTexture(nil, "BACKGROUND")
    tabAreaBackground:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -40) -- Start below title bar, adjust Y
    tabAreaBackground:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -40)
    tabAreaBackground:SetHeight(30) -- Height of the tab area
    tabAreaBackground:SetColorTexture(0.2, 0.2, 0.2, 0.8) -- Dark grey, slightly transparent
    tabAreaBackground:SetDrawLayer("BACKGROUND", 0) -- Use SetDrawLayer for textures on frames


    -- **Tab-System erstellen (ohne TabGroupTemplate)**
    local tabGroup = CreateFrame("Frame", nil, f) -- Einfacher Frame als Container
    tabGroup:SetPoint("TOPLEFT", tabAreaBackground, "TOPLEFT", 10, 0) -- Position relative to new background
    tabGroup:SetSize(400, 30) -- Genug Platz für die Tabs
    tabGroup:SetFrameLevel(f:GetFrameLevel() + 2) -- Setzt den FrameLevel des tabGroup


    -- Panels für die Tab-Inhalte
    RWLootTrackerGlobal.lootDatabasePanel = CreateFrame("Frame", nil, f)
    DebugPrint("RWLootTrackerGlobal.CreateGUI: lootDatabasePanel nach CreateFrame: " .. tostring(RWLootTrackerGlobal.lootDatabasePanel))
    if not RWLootTrackerGlobal.lootDatabasePanel then
        DebugPrint("FEHLER: lootDatabasePanel ist NIL nach CreateFrame!")
        return -- Beende die Funktion, wenn Frame-Erstellung fehlschlägt
    end
    RWLootTrackerGlobal.lootDatabasePanel:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -70) -- Unter den Tabs
    RWLootTrackerGlobal.lootDatabasePanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15) -- Bis zum unteren Rand
    RWLootTrackerGlobal.lootDatabasePanel:SetFrameLevel(f:GetFrameLevel() + 1)
    -- Hintergrund für lootDatabasePanel
    local lootDatabasePanelBg = RWLootTrackerGlobal.lootDatabasePanel:CreateTexture(nil, "BACKGROUND")
    lootDatabasePanelBg:SetAllPoints(true)
    lootDatabasePanelBg:SetColorTexture(0.1, 0.1, 0.15, 0.7) -- Dezentes Dunkelblau-Grau
    lootDatabasePanelBg:SetDrawLayer("BACKGROUND")


    RWLootTrackerGlobal.settingsPanel = CreateFrame("Frame", nil, f)
    RWLootTrackerGlobal.settingsPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -70)
    RWLootTrackerGlobal.settingsPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
    RWLootTrackerGlobal.settingsPanel:SetFrameLevel(f:GetFrameLevel() + 1)
    RWLootTrackerGlobal.settingsPanel:Hide() -- Standardmäßig verstecken

    -- Hintergrund für das settingsPanel
    local settingsPanelBg = RWLootTrackerGlobal.settingsPanel:CreateTexture(nil, "BACKGROUND")
    settingsPanelBg:SetAllPoints(true)
    settingsPanelBg:SetColorTexture(0.1, 0.1, 0.15, 0.7) -- Dezentes Dunkelblau-Grau
    settingsPanelBg:SetDrawLayer("BACKGROUND")

    -- ÄNDERUNG: Call CreateSettingsPanelElements right after settingsPanel is created
    RWLootTrackerGlobal.CreateSettingsPanelElements(RWLootTrackerGlobal.settingsPanel)


    -- Tabs definieren und zur Tab-Gruppe hinzufügen
    local tabs = {
        { name = "Beute Datenbank", panel = RWLootTrackerGlobal.lootDatabasePanel },
        { name = "Einstellungen", panel = RWLootTrackerGlobal.settingsPanel },
    }

    local lastActiveTab = nil -- Speichert den zuletzt aktiven Tab-Button

    -- Machen Sie SwitchTab global über RWLootTrackerGlobal
    function RWLootTrackerGlobal.SwitchTab(tabButton, panelToShow)
        -- Alle Panels verstecken
        RWLootTrackerGlobal.lootDatabasePanel:Hide()
        RWLootTrackerGlobal.settingsPanel:Hide()

        -- Den zuvor aktiven Tab-Button zurücksetzen
        if lastActiveTab then
            -- ÄNDERUNG: Verwende einen leeren String "" anstelle von nil, um die Highlight-Textur zu entfernen
            lastActiveTab:SetHighlightTexture("")
            lastActiveTab.text:SetFontObject("GameFontNormal")
            lastActiveTab.text:SetTextColor(1, 1, 1, 1) -- Setze Textfarbe zurück auf weiß
        end

        -- Das ausgewählte Panel zeigen
        panelToShow:Show()

        -- Den neuen aktiven Tab-Button hervorheben
        tabButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Tab-Unselected") -- Ausgewählte Textur
        tabButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Tab-Selected") -- Ausgewählte Textur
        tabButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Tab-Selected-Highlight", "ADD") -- Highlight hinzufügen
        tabButton.text:SetFontObject("GameFontHighlight")
        tabButton.text:SetTextColor(1, 1, 0, 1) -- Gelbe Farbe für den aktiven Tab-Text

        lastActiveTab = tabButton -- Den aktuellen Tab als letzten aktiven speichern
    end

    -- Globale Referenz zu den Tab-Buttons in der GUI-Erstellung speichern
    RWLootTrackerGlobal.tabButtons = {}
    for i = 1, #tabs do -- Iteriere über die Anzahl der Tabs, nicht über die Tabelle selbst mit ipairs, da es Probleme geben kann.
        local tabInfo = tabs[i] -- Hole die Tab-Informationen
        local tabButton = CreateFrame("Button", nil, tabGroup) -- Kein "CharacterTabButtonTemplate"
        tabButton:SetPoint("LEFT", 5 + (i - 1) * 100, 0) -- Positioniere Tabs nebeneinander
        tabButton:SetWidth(100)
        tabButton:SetHeight(30)
        
        -- Textur für den Tab-Button
        tabButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Tab-Unselected")
        tabButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Tab-Selected")
        tabButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Tab-Selected-Highlight", "ADD")

        -- Font für den Tab-Text
        tabButton.text = tabButton:CreateFontString(nil, "OVERLAY")
        tabButton.text:SetFontObject("GameFontNormal")
        tabButton.text:SetPoint("CENTER")
        tabButton.text:SetText(tabInfo.name)
        tabButton.text:SetTextColor(1, 1, 1, 1)

        tabButton:SetID(i)

        tabButton:SetScript("OnClick", function(self)
            RWLootTrackerGlobal.SwitchTab(self, tabInfo.panel) -- Panel wechseln und Tab-Button hervorheben
        end)
        table.insert(RWLootTrackerGlobal.tabButtons, tabButton) -- Verwende table.insert, um die Buttons zu speichern
    end

    -- Standardmäßig den ersten Tab auswählen und das zugehörige Panel anzeigen
    if RWLootTrackerGlobal.tabButtons[1] then
        RWLootTrackerGlobal.SwitchTab(RWLootTrackerGlobal.tabButtons[1], tabs[1].panel)
    end


    -- === Elemente für "Beute Datenbank" Tab (RWLootTrackerGlobal.lootDatabasePanel) - Jetzt mit Kalender ===
    -- WICHTIG: Erstelle calendarFrame nur, wenn lootDatabasePanel existiert
    if RWLootTrackerGlobal.lootDatabasePanel then
        -- Erstelle ein einfaches Frame
        RWLootTrackerGlobal.calendarFrame = CreateFrame("Frame", "LootTrackerCalendarFrame", RWLootTrackerGlobal.lootDatabasePanel)
        DebugPrint("calendarFrame nach CreateFrame (mit Parent, OHNE Template): " .. tostring(RWLootTrackerGlobal.calendarFrame))
        
        if not RWLootTrackerGlobal.calendarFrame then
            DebugPrint("FEHLER: calendarFrame ist NIL nach CreateFrame in RWLootTrackerGlobal.CreateGUI, obwohl lootDatabasePanel existiert!")
            return -- Beende die Funktion, wenn Frame-Erstellung fehlschlägt
        end

        -- FIX: Kalender-Hintergrund soll vertikal das lootDatabasePanel ausfüllen und feste Breite haben.
        -- Berücksichtigt den 'inset' des manuellen Rahmens, um visuelle Überlappungen zu vermeiden.
        local calendarFrameInset = 4 -- Der gleiche 'inset' Wert, der für die Ränder verwendet wird

        RWLootTrackerGlobal.calendarFrame:SetPoint("TOPLEFT", RWLootTrackerGlobal.lootDatabasePanel, "TOPLEFT", 15, -calendarFrameInset) -- Y-Offset nach oben für den oberen Rand
        RWLootTrackerGlobal.calendarFrame:SetPoint("BOTTOMLEFT", RWLootTrackerGlobal.lootDatabasePanel, "BOTTOMLEFT", 15, calendarFrameInset) -- Y-Offset nach unten für den unteren Rand
        RWLootTrackerGlobal.calendarFrame:SetWidth(450) -- Feste Breite für den Kalender
        
        -- ÄNDERUNG: SetFrameLevel auf Basis des Parent, aber sicherstellen, dass es über dem Panel-Hintergrund ist.
        RWLootTrackerGlobal.calendarFrame:SetFrameLevel(RWLootTrackerGlobal.lootDatabasePanel:GetFrameLevel() + 2)
        
        -- MANUELLES BACKDROP IM STIL VON LEATRIX
        local bg = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.7) -- Dunkler Hintergrund
        bg:SetDrawLayer("BACKGROUND", 0) -- Sicherstellen, dass es die unterste Ebene ist

        local borderTex = "Interface/Tooltips/UI-Tooltip-Border"
        local borderSize = 16
        local inset = 4

        -- Rahmentexturen mit ARTWORK-Ebene
        local topBorder = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "ARTWORK")
        topBorder:SetTexture(borderTex)
        topBorder:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", -inset, inset)
        topBorder:SetPoint("TOPRIGHT", RWLootTrackerGlobal.calendarFrame, "TOPRIGHT", inset, inset)
        topBorder:SetHeight(borderSize)
        topBorder:SetTexCoord(0.125, 0.875, 0.125, 0.875)
        topBorder:SetDrawLayer("ARTWORK", 0)

        local bottomBorder = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "ARTWORK")
        bottomBorder:SetTexture(borderTex)
        bottomBorder:SetPoint("BOTTOMLEFT", RWLootTrackerGlobal.calendarFrame, "BOTTOMLEFT", -inset, -inset)
        bottomBorder:SetPoint("BOTTOMRIGHT", RWLootTrackerGlobal.calendarFrame, "BOTTOMRIGHT", inset, -inset)
        bottomBorder:SetHeight(borderSize)
        bottomBorder:SetTexCoord(0.125, 0.875, 0.125, 0.875)
        bottomBorder:SetDrawLayer("ARTWORK", 0)

        local leftBorder = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "ARTWORK")
        leftBorder:SetTexture(borderTex)
        leftBorder:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", -inset, inset)
        leftBorder:SetPoint("BOTTOMLEFT", RWLootTrackerGlobal.calendarFrame, "BOTTOMLEFT", -inset, -inset)
        leftBorder:SetWidth(borderSize)
        leftBorder:SetTexCoord(0.125, 0.875, 0.125, 0.875)
        leftBorder:SetDrawLayer("ARTWORK", 0)

        local rightBorder = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "ARTWORK")
        rightBorder:SetTexture(borderTex)
        rightBorder:SetPoint("TOPRIGHT", RWLootTrackerGlobal.calendarFrame, "TOPRIGHT", inset, inset)
        rightBorder:SetPoint("BOTTOMRIGHT", RWLootTrackerGlobal.calendarFrame, "BOTTOMRIGHT", inset, -inset)
        rightBorder:SetWidth(borderSize)
        rightBorder:SetTexCoord(0.125, 0.875, 0.125, 0.875)
        rightBorder:SetDrawLayer("ARTWORK", 0)
        
        DebugPrint("Manuelles Backdrop für calendarFrame erstellt.")


        -- Kalender-Header (Monat und Jahr)
        RWLootTrackerGlobal.calendarFrame.monthYearText = RWLootTrackerGlobal.calendarFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        RWLootTrackerGlobal.calendarFrame.monthYearText:SetPoint("TOP", RWLootTrackerGlobal.calendarFrame, "TOP", 0, -30) -- Weiter nach unten verschoben für Header-Bereich
        RWLootTrackerGlobal.calendarFrame.monthYearText:SetText("Monat Jahr")
        RWLootTrackerGlobal.calendarFrame.monthYearText:SetTextColor(1, 1, 1, 1)
        RWLootTrackerGlobal.calendarFrame.monthYearText:SetDrawLayer("OVERLAY") -- Text immer über dem Hintergrund


        -- Navigationspfeile
        RWLootTrackerGlobal.calendarFrame.prevMonthButton = CreateFrame("Button", nil, RWLootTrackerGlobal.calendarFrame, "UIPanelButtonTemplate")
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetSize(20, 20)
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetPoint("RIGHT", RWLootTrackerGlobal.calendarFrame.monthYearText, "LEFT", -10, 0) -- Relative Position zum Text
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetText("<")
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetScript("OnClick", function()
            RWLootTrackerGlobal.currentCalendarDate.month = RWLootTrackerGlobal.currentCalendarDate.month - 1
            if RWLootTrackerGlobal.currentCalendarDate.month < 1 then
                RWLootTrackerGlobal.currentCalendarDate.month = 12
                RWLootTrackerGlobal.currentCalendarDate.year = RWLootTrackerGlobal.currentCalendarDate.year - 1
            end
            RWLootTrackerGlobal.InitializeCalendar()
        end)

        RWLootTrackerGlobal.calendarFrame.nextMonthButton = CreateFrame("Button", nil, RWLootTrackerGlobal.calendarFrame, "UIPanelButtonTemplate")
        RWLootTrackerGlobal.calendarFrame.nextMonthButton:SetSize(20, 20)
        RWLootTrackerGlobal.calendarFrame.nextMonthButton:SetPoint("LEFT", RWLootTrackerGlobal.calendarFrame.monthYearText, "RIGHT", 10, 0) -- Relative Position zum Text
        RWLootTrackerGlobal.calendarFrame.nextMonthButton:SetText(">")
        RWLootTrackerGlobal.calendarFrame.nextMonthButton:SetScript("OnClick", function()
            RWLootTrackerGlobal.currentCalendarDate.month = RWLootTrackerGlobal.currentCalendarDate.month + 1
            if RWLootTrackerGlobal.currentCalendarDate.month > 12 then
                RWLootTrackerGlobal.currentCalendarDate.month = 1
                RWLootTrackerGlobal.currentCalendarDate.year = RWLootTrackerGlobal.currentCalendarDate.year + 1
            end
            RWLootTrackerGlobal.InitializeCalendar()
        end)


        -- Wochentags-Labels
        local dayNames = {"Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"}
        RWLootTrackerGlobal.calendarFrame.dayLabels = {}
        local columnWidth = 60 -- Einheitliche Spaltenbreite
        local initialXOffset = 15 -- Anfangs-Offset vom linken Rand des Kalender-Hintergrunds

        for i = 1, 7 do
            local label = RWLootTrackerGlobal.calendarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetWidth(columnWidth) -- Breite des Labels auf Spaltenbreite setzen
            label:SetJustifyH("CENTER") -- Text horizontal zentrieren
            label:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", initialXOffset + (i-1) * columnWidth, -70)
            label:SetText(dayNames[i])
            label:SetTextColor(1, 1, 0, 1) -- Gelb für Wochentage
            label:SetDrawLayer("OVERLAY") -- Text immer über dem Hintergrund
            RWLootTrackerGlobal.calendarFrame.dayLabels[i] = label
        end

        -- Kalender-Tage-Buttons (Grid)
        RWLootTrackerGlobal.calendarFrame.dayButtons = {}
        local buttonSize = 50
        local buttonSpacing = columnWidth -- Abstand zwischen Buttons (horizontal und vertikal)
        local startY = -110 -- Angepasster Startpunkt für Tage, um Header und Wochentags-Labels zu berücksichtigen
        local buttonPaddingInColumn = (columnWidth - buttonSize) / 2 -- Padding, um Button in Spalte zu zentrieren

        for row = 0, 5 do -- 6 Reihen
            for col = 0, 6 do -- 7 Spalten
                local button = CreateFrame("Button", nil, RWLootTrackerGlobal.calendarFrame)
                button:SetSize(buttonSize, buttonSize)
                button:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", initialXOffset + col * buttonSpacing + buttonPaddingInColumn, startY + row * -buttonSpacing)
                button:SetFrameLevel(RWLootTrackerGlobal.calendarFrame:GetFrameLevel() + 2) -- Ensure buttons are above calendar background
                
                -- Hintergrund für den Button
                button.bg = button:CreateTexture(nil, "BACKGROUND")
                button.bg:SetAllPoints(true)
                button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8) -- Initial dunkler Hintergrund
                button.bg:SetDrawLayer("BACKGROUND", 1) -- Hintergrund hinter dem Text

                -- Rahmen für den Button
                button.border = button:CreateTexture(nil, "ARTWORK")
                button.border:SetTexture("Interface/Common/Common-Border") -- Ein einfacher Border
                button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
                button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
                button.border:SetBlendMode("BLEND")
                button.border:SetColorTexture(0.5, 0.5, 0.5, 1) -- Initial grauer Rahmen
                button.border:SetDrawLayer("ARTWORK", 0) -- Rahmen über dem Hintergrund, unter dem Text

                -- Text (Tag-Nummer)
                button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                button.text:SetPoint("CENTER")
                button.text:SetText("")
                button.text:SetTextColor(1, 1, 1, 1) -- Initial weißer Text
                button.text:SetDrawLayer("OVERLAY") -- Text immer oben

                button:SetScript("OnClick", function(self)
                    if self.dateString then
                        ShowLootDetailsFrame(self.dateString)
                    end
                end)
                table.insert(RWLootTrackerGlobal.calendarFrame.dayButtons, button)
            end
        end

        -- Aktualierungs-Button für den Kalender
        local refreshCalendarButton = CreateFrame("Button", nil, RWLootTrackerGlobal.lootDatabasePanel, "GameMenuButtonTemplate")
        refreshCalendarButton:SetPoint("LEFT", RWLootTrackerGlobal.calendarFrame, "RIGHT", 20, 100) -- Position rechts neben dem Kalender
        refreshCalendarButton:SetSize(180, 30)
        refreshCalendarButton:SetText("Kalender aktualisieren")
        refreshCalendarButton:SetScript("OnClick", function()
            RWLootTrackerGlobal.InitializeCalendar()
        end)

        -- Debug Datensatz Button (im RWLootTrackerGlobal.lootDatabasePanel)
        local debugButton = CreateFrame("Button", nil, RWLootTrackerGlobal.lootDatabasePanel, "GameMenuButtonTemplate")
        debugButton:SetPoint("TOPLEFT", refreshCalendarButton, "BOTTOMLEFT", 0, -10) -- Unter dem Refresh Button
        debugButton:SetSize(180, 30)
        debugButton:SetText("Debug Datensatz")
        debugButton:SetFrameLevel(RWLootTrackerGlobal.lootDatabasePanel:GetFrameLevel() + 1)
        debugButton:SetScript("OnClick", function()
            GenerateDebugLootData()
        end)

        -- Neuer "Datenbank leeren" Button
        local clearDatabaseButton = CreateFrame("Button", nil, RWLootTrackerGlobal.lootDatabasePanel, "GameMenuButtonTemplate")
        clearDatabaseButton:SetPoint("TOPLEFT", debugButton, "BOTTOMLEFT", 0, -10) -- Unter dem Debug-Button
        clearDatabaseButton:SetSize(180, 30)
        clearDatabaseButton:SetText("Datenbank leeren")
        clearDatabaseButton:SetFrameLevel(RWLootTrackerGlobal.lootDatabasePanel:GetFrameLevel() + 1)
        clearDatabaseButton:SetScript("OnClick", function()
            DebugPrint("Datenbank leeren button clicked.")
            -- Rufe die neue globale ShowConfirmDialog-Funktion auf
            RWLootTrackerGlobal.ShowConfirmDialog(
                "Datenbank leeren",
                "Wollen Sie Ihre Datenbank wirklich leeren? Alle Daten werden unwiderruflich gelöscht.",
                function()
                    DebugPrint("Datenbank wird geleert. (Bestätigt)")
                    LootTrackerDB = {} -- Leere die Datenbank
                    if RWLootTrackerGlobal.SaveLootData then -- Prüfung hinzugefügt
                        RWLootTrackerGlobal.SaveLootData() -- Speichere den leeren Zustand
                    else
                        DebugPrint("FEHLER: RWLootTrackerGlobal.SaveLootData ist NIL! Daten können nicht sofort gespeichert werden.")
                    end
                    RWLootTrackerGlobal.InitializeCalendar() -- Kalender aktualisieren, um die leeren Daten anzuzeigen
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RWLootTracker]|r Die Beutedatenbank wurde erfolgreich geleert.")
                end,
                function()
                    DebugPrint("Datenbank leeren abgebrochen. (Abgelehnt)")
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[RWLootTracker]|r Das Leeren der Beutedatenbank wurde abgebrochen.")
                end
            )
        end)

    else
        DebugPrint("lootDatabasePanel ist NIL, Kalender wird nicht erstellt.")
    end

    RWLootTrackerGlobal.lootTrackerFrame = f -- Speichere die Referenz zum Haupt-Frame
    f:Show()
    -- Sicherstellen, dass der Kalender initial gefüllt wird, wenn das GUI zum ersten Mal erstellt wird.
    -- Dies sollte nur aufgerufen werden, wenn calendarFrame tatsächlich erstellt wurde.
    if RWLootTrackerGlobal.calendarFrame then
        RWLootTrackerGlobal.InitializeCalendar()
    end

    -- Initialisiere das Bestätigungs-Popup beim Erstellen der GUI
    RWLootTrackerGlobal.InitializeConfirmDialog()
end

-- === Elemente für "Einstellungen" Tab (RWLootTrackerGlobal.settingsPanel) ===
-- Diese Funktion wird einmal aufgerufen, wenn der Slash-Befehl zum ersten Mal ausgeführt wird
function RWLootTrackerGlobal.CreateSettingsPanelElements(parentFrame)
    -- Da parentFrame hier RWLootTrackerGlobal.settingsPanel ist, können wir dies direkt direkt verwenden.
    local configChatFrame = CreateFrame("Frame", nil, parentFrame)
    configChatFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 15, -15)
    configChatFrame:SetSize(300, 30)
    configChatFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1) -- Erhöht den FrameLevel

    local logToChatCheckbox = CreateFrame("CheckButton", nil, configChatFrame, "UICheckButtonTemplate")
    logToChatCheckbox:SetPoint("LEFT", configChatFrame, "LEFT", 0, 0)
    logToChatCheckbox:SetScale(1.2)
    logToChatCheckbox:SetFrameLevel(configChatFrame:GetFrameLevel() + 1) -- Sicherstellen, dass die Checkbox über dem Frame ist

    logToChatCheckbox.text = logToChatCheckbox:CreateFontString(nil, "OVERLAY")
    logToChatCheckbox.text:SetFontObject("GameFontNormal")
    logToChatCheckbox.text:SetPoint("LEFT", logToChatCheckbox, "RIGHT", 5, 0)
    logToChatCheckbox.text:SetText("Meldungen an Chat senden")
    logToChatCheckbox.text:SetTextColor(1, 1, 1, 1)
    logToChatCheckbox.text:SetDrawLayer("OVERLAY")

    logToChatCheckbox:SetChecked(LootTrackerConfig.LogToChat)

    logToChatCheckbox:SetScript("OnClick", function(self)
        LootTrackerConfig.LogToChat = self:GetChecked()
        DebugPrint("'Meldungen an Chat senden' auf " .. tostring(LootTrackerConfig.LogToChat) .. " gesetzt.")
    end)
    DebugPrint("Checkbox 'Meldungen an Chat senden' erstellt.")


    -- Neuer Debug Mode Checkbox
    local debugModeCheckboxFrame = CreateFrame("Frame", nil, parentFrame)
    debugModeCheckboxFrame:SetPoint("TOPLEFT", logToChatCheckbox, "BOTTOMLEFT", 0, -10) -- Unter der vorherigen Checkbox
    debugModeCheckboxFrame:SetSize(300, 30)
    debugModeCheckboxFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1)

    local debugModeCheckbox = CreateFrame("CheckButton", nil, debugModeCheckboxFrame, "UICheckButtonTemplate")
    debugModeCheckbox:SetPoint("LEFT", debugModeCheckboxFrame, "LEFT", 0, 0)
    debugModeCheckbox:SetScale(1.2)
    debugModeCheckbox:SetFrameLevel(debugModeCheckboxFrame:GetFrameLevel() + 1)

    debugModeCheckbox.text = debugModeCheckbox:CreateFontString(nil, "OVERLAY")
    debugModeCheckbox.text:SetFontObject("GameFontNormal")
    debugModeCheckbox.text:SetPoint("LEFT", debugModeCheckbox, "RIGHT", 5, 0)
    debugModeCheckbox.text:SetText("Debug Mode")
    debugModeCheckbox.text:SetTextColor(1, 1, 1, 1)
    debugModeCheckbox.text:SetDrawLayer("OVERLAY")

    debugModeCheckbox:SetChecked(LootTrackerConfig.DebugMode)

    debugModeCheckbox:SetScript("OnClick", function(self)
        LootTrackerConfig.DebugMode = self:GetChecked()
        DebugPrint("'Debug Mode' auf " .. tostring(LootTrackerConfig.DebugMode) .. " gesetzt.")
    end)
    DebugPrint("Checkbox 'Debug Mode' erstellt.")


    local instanceTypeConfigFrame = CreateFrame("Frame", nil, parentFrame)
    instanceTypeConfigFrame:SetPoint("TOPLEFT", debugModeCheckboxFrame, "BOTTOMLEFT", 0, -20) -- Position unter dem neuen Debug Mode Checkbox
    instanceTypeConfigFrame:SetSize(420, 180)
    instanceTypeConfigFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1) -- Erhöht den FrameLevel

    local instanceTypeLabel = instanceTypeConfigFrame:CreateFontString(nil, "OVERLAY")
    instanceTypeLabel:SetFontObject("GameFontNormal")
    instanceTypeLabel:SetPoint("TOPLEFT", instanceTypeConfigFrame, "TOPLEFT", 15, 5)
    instanceTypeLabel:SetText("Beute erfassen in:")
    instanceTypeLabel:SetTextColor(1, 1, 1, 1)
    instanceTypeLabel:SetDrawLayer("OVERLAY") -- Sicherstellen, dass der Text oben ist
    DebugPrint("Label 'Beute erfassen in:' erstellt.")


    local instanceTypeCheckboxes = {
        { key = "raid", text = "Raids" },
        { key = "party", text = "Dungeons/Gruppen" },
        { key = "scenario", text = "Szenarien" },
        { key = "pvp", text = "PvP-Inhalt" },
        { key = "none", text = "Offene Welt" },
    }

    local col1X = 15
    local col2X = 215
    local startYCheckbox = 40
    local rowYStep = 30

    for i = 1, #instanceTypeCheckboxes do -- Iteriere über die Anzahl der Checkboxen
        local data = instanceTypeCheckboxes[i] -- Hole die Daten für die aktuelle Checkbox
        local cb = CreateFrame("CheckButton", nil, instanceTypeConfigFrame, "UICheckButtonTemplate")
        cb:SetScale(1.2)

        local x_pos, y_pos
        if (i - 1) % 2 == 0 then
            x_pos = col1X
        else
            x_pos = col2X
        end
        
        y_pos = - (startYCheckbox + floor((i-1)/2) * rowYStep)

        cb:SetPoint("TOPLEFT", instanceTypeConfigFrame, "TOPLEFT", x_pos, y_pos)
        cb:SetFrameLevel(instanceTypeConfigFrame:GetFrameLevel() + 2) -- Sicherstellen, dass Checkbox über Frame ist

        cb.text = cb:CreateFontString(nil, "OVERLAY")
        cb.text:SetFontObject("GameFontNormal")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        cb.text:SetText(data.text)
        cb.text:SetTextColor(1, 1, 1, 1)
        cb.text:SetDrawLayer("OVERLAY")

        cb:SetChecked(LootTrackerConfig.trackInstanceTypes[data.key])

        cb:SetScript("OnClick", function(self)
            LootTrackerConfig.trackInstanceTypes[data.key] = self:GetChecked()
            DebugPrint("Verfolgung für '" .. data.text .. "' auf " .. tostring(LootTrackerConfig.trackInstanceTypes[data.key]) .. " gesetzt.")
        end)
        DebugPrint(string.format("Created instance type checkbox for %s at %.2f, %.2f. Checked: %s", data.text, cb:GetLeft(), cb:GetTop(), tostring(LootTrackerConfig.trackInstanceTypes[data.key])))
    end
end

DebugPrint("Viewer-Modul geladen (Version " .. RWLootTrackerGlobal.Version .. ").")


local function DebugPrint(msg)
    if LootTrackerConfig.DebugMode then
        print("RWLootTracker: " .. msg)
    end
end


local function UpdateLootDetailsText(editBox, selectedDate)
    DebugPrint("UpdateLootDetailsText: selectedDate erhalten: " .. tostring(selectedDate))
    if not editBox then DebugPrint("UpdateLootDetailsText: FEHLER: editBox ist NIL!") return end
    if not editBox:IsVisible() then DebugPrint("UpdateLootDetailsText: Warnung: editBox ist nicht sichtbar!") end
    if not editBox:GetParent():IsVisible() then DebugPrint("UpdateLootDetailsText: Warnung: Parent scrollBox ist nicht sichtbar!") end

    local scrollBox = editBox:GetParent()
    if scrollBox then

        editBox:SetPoint("TOPLEFT", scrollBox, "TOPLEFT")
        editBox:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT")
        editBox:SetWidth(scrollBox:GetWidth())
        editBox:SetHeight(scrollBox:GetHeight())
        DebugPrint(string.format("UpdateLootDetailsText: editBox Größe nach Anpassung: %.2fx%.2f", editBox:GetWidth(), editBox:GetHeight()))
    else
        DebugPrint("UpdateLootDetailsText: scrollBox ist NIL. Kann editBox nicht anpassen.")
    end
    DebugPrint(string.format("UpdateLootDetailsText: scrollBox Größe: %.2fx%.2f", scrollBox:GetWidth(), scrollBox:GetHeight()))


    local lines = {}
    local entriesToDisplay = LootTrackerDB[selectedDate] or {}

    DebugPrint("UpdateLootDetailsText: Anzahl der Einträge für " .. selectedDate .. ": " .. #entriesToDisplay)
    if #entriesToDisplay == 0 then
        DebugPrint("UpdateLootDetailsText: Keine Daten gefunden für " .. selectedDate .. ". LootTrackerDB[" .. selectedDate .. "] ist leer oder nil.")
    elseif LootTrackerConfig.AddTableHeader then
        table.insert(lines, "Zeit\tBoss\tSpieler\tGUID\tKlasse\tSpezialisierung\tGegenstand\tItemname\tItemID\tRollart\tRollwert\tRüstungstyp\tSlot")
    end

    for _, entry in ipairs(entriesToDisplay) do
        table.insert(lines, string.format('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',
            entry.time or "",
            entry.boss or "",
            entry.player or "",
            entry.playerGUID or "",
            entry.playerClass or "",
            entry.playerSpecialization or "",
            entry.item or "",
            entry.itemName or "",
            entry.itemID or "",
            entry.method or "",
            entry.rollValue or "",
            entry.armorType or "",
            entry.slot or ""
        ))
    end
    editBox:SetText(table.concat(lines, "\n"))
end


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
        f:SetFrameStrata("TOOLTIP") 
        f:SetFrameLevel(100) 
        f:SetClampedToScreen(true) 

        f.title = f:CreateFontString(nil, "OVERLAY")
        f.title:SetFontObject("GameFontHighlight")
        f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
        f.title:SetText("Beute für den " .. selectedDate)
        f.title:SetTextColor(1, 1, 1, 1)

        f.CloseButton:SetScript("OnClick", function() f:Hide() end)


        local scrollBox = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scrollBox:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -30)
        scrollBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 15)
        scrollBox:SetFrameLevel(f:GetFrameLevel() + 1)
        
        local editBox = CreateFrame("EditBox", nil, scrollBox)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetAutoFocus(false)

        editBox:SetPoint("TOPLEFT", scrollBox, "TOPLEFT")
        editBox:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT")
        editBox:SetMaxBytes(1000000)
        editBox:SetJustifyH("LEFT")
        editBox:SetJustifyV("TOP")
        scrollBox:SetScrollChild(editBox)
        f.editBox = editBox

        editBox:SetWidth(scrollBox:GetWidth())
        editBox:SetHeight(scrollBox:GetHeight())
        DebugPrint(string.format("ShowLootDetailsFrame: editBox Größe nach Initialisierung: %.2fx%.2f", editBox:GetWidth(), editBox:GetHeight()))

        editBox:SetTextColor(1, 1, 1, 1)

        RWLootTrackerGlobal.lootDetailsFrame = f
    end

    RWLootTrackerGlobal.lootDetailsFrame.title:SetText("Beute für den " .. selectedDate)
    UpdateLootDetailsText(RWLootTrackerGlobal.lootDetailsFrame.editBox, selectedDate)
    RWLootTrackerGlobal.lootDetailsFrame:Show()
end


function RWLootTrackerGlobal.InitializeCalendar()
    if not RWLootTrackerGlobal.calendarFrame then
        DebugPrint("RWLootTrackerGlobal.InitializeCalendar: calendarFrame ist NIL. Kann Kalender nicht initialisieren.")
        return
    end

    local year = RWLootTrackerGlobal.currentCalendarDate.year
    local month = RWLootTrackerGlobal.currentCalendarDate.month

    RWLootTrackerGlobal.calendarFrame.monthYearText:SetText(date("%B %Y", time{year=year, month=month, day=1, hour=0, min=0, sec=0}))

    local function GetFirstWeekdayOfMonth(year, month)
        local t = time{year=year, month=month, day=1, hour=0, min=0, sec=0}
        local weekday = tonumber(date("%w", t))
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
    f.title:SetText("RWLootTracker " .. RWLootTrackerGlobal.Version)
    f.title:SetTextColor(1, 1, 1, 1)


    -- Panels für die Tab-Inhalte
    RWLootTrackerGlobal.lootDatabasePanel = CreateFrame("Frame", nil, f)
    DebugPrint("RWLootTrackerGlobal.CreateGUI: lootDatabasePanel nach CreateFrame: " .. tostring(RWLootTrackerGlobal.lootDatabasePanel))
    if not RWLootTrackerGlobal.lootDatabasePanel then
        DebugPrint("FEHLER: lootDatabasePanel ist NIL nach CreateFrame!")
        return -- Beende die Funktion, wenn Frame-Erstellung fehlschlägt
    end
    RWLootTrackerGlobal.lootDatabasePanel:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -45) -- Unter den Tabs
    RWLootTrackerGlobal.lootDatabasePanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15) -- Bis zum unteren Rand
    RWLootTrackerGlobal.lootDatabasePanel:SetFrameLevel(f:GetFrameLevel() + 1)
    -- Hintergrund für lootDatabasePanel
    local lootDatabasePanelBg = RWLootTrackerGlobal.lootDatabasePanel:CreateTexture(nil, "BACKGROUND")
    lootDatabasePanelBg:SetAllPoints(true)
    lootDatabasePanelBg:SetColorTexture(0.1, 0.1, 0.15, 0.7) -- Dezentes Dunkelblau-Grau
    lootDatabasePanelBg:SetDrawLayer("BACKGROUND")

    RWLootTrackerGlobal.lootDatabasePanel:Show() -- Sicherstellen, dass das Panel sichtbar ist


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

        -- Kalender-Hintergrund soll vertikal das lootDatabasePanel ausfüllen und feste Breite haben.
        -- Berücksichtigt den 'inset' des manuellen Rahmens, um visuelle Überlappungen zu vermeiden.
        local calendarFrameInset = 4

        RWLootTrackerGlobal.calendarFrame:SetPoint("TOPLEFT", RWLootTrackerGlobal.lootDatabasePanel, "TOPLEFT", 15, -calendarFrameInset) -- Y-Offset nach oben für den oberen Rand
        RWLootTrackerGlobal.calendarFrame:SetPoint("BOTTOMLEFT", RWLootTrackerGlobal.lootDatabasePanel, "BOTTOMLEFT", 15, calendarFrameInset) -- Y-Offset nach unten für den unteren Rand
        RWLootTrackerGlobal.calendarFrame:SetWidth(450) -- Feste Breite für den Kalender
        
        -- SetFrameLevel auf Basis des Parent, aber sicherstellen, dass es über dem Panel-Hintergrund ist.
        RWLootTrackerGlobal.calendarFrame:SetFrameLevel(RWLootTrackerGlobal.lootDatabasePanel:GetFrameLevel() + 2)
        
        -- MANUELLES BACKDROP IM STIL VON LEATRIX
        local bg = RWLootTrackerGlobal.calendarFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.7) -- Dunkler Hintergrund
        bg:SetDrawLayer("BACKGROUND", 0)

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
        RWLootTrackerGlobal.calendarFrame.monthYearText:SetDrawLayer("OVERLAY")


        -- Navigationspfeile
        RWLootTrackerGlobal.calendarFrame.prevMonthButton = CreateFrame("Button", nil, RWLootTrackerGlobal.calendarFrame, "UIPanelButtonTemplate")
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetSize(20, 20)
        RWLootTrackerGlobal.calendarFrame.prevMonthButton:SetPoint("RIGHT", RWLootTrackerGlobal.calendarFrame.monthYearText, "LEFT", -10, 0)
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
        RWLootTrackerGlobal.calendarFrame.nextMonthButton:SetPoint("LEFT", RWLootTrackerGlobal.calendarFrame.monthYearText, "RIGHT", 10, 0)
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
        local columnWidth = 60
        local initialXOffset = 15

        for i = 1, 7 do
            local label = RWLootTrackerGlobal.calendarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetWidth(columnWidth)
            label:SetJustifyH("CENTER")
            label:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", initialXOffset + (i-1) * columnWidth, -70)
            label:SetText(dayNames[i])
            label:SetTextColor(1, 1, 0, 1)
            label:SetDrawLayer("OVERLAY")
            RWLootTrackerGlobal.calendarFrame.dayLabels[i] = label
        end

        -- Kalender-Tage-Buttons (Grid)
        RWLootTrackerGlobal.calendarFrame.dayButtons = {}
        local buttonSize = 50
        local buttonSpacing = columnWidth
        local startY = -110
        local buttonPaddingInColumn = (columnWidth - buttonSize) / 2

        for row = 0, 5 do -- 6 Reihen
            for col = 0, 6 do -- 7 Spalten
                local button = CreateFrame("Button", nil, RWLootTrackerGlobal.calendarFrame)
                button:SetSize(buttonSize, buttonSize)
                button:SetPoint("TOPLEFT", RWLootTrackerGlobal.calendarFrame, "TOPLEFT", initialXOffset + col * buttonSpacing + buttonPaddingInColumn, startY + row * -buttonSpacing)
                button:SetFrameLevel(RWLootTrackerGlobal.calendarFrame:GetFrameLevel() + 2)
                
                -- Hintergrund für den Button
                button.bg = button:CreateTexture(nil, "BACKGROUND")
                button.bg:SetAllPoints(true)
                button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
                button.bg:SetDrawLayer("BACKGROUND", 1)

                -- Rahmen für den Button
                button.border = button:CreateTexture(nil, "ARTWORK")
                button.border:SetTexture("Interface/Common/Common-Border")
                button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
                button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
                button.border:SetBlendMode("BLEND")
                button.border:SetColorTexture(0.5, 0.5, 0.5, 1)
                button.border:SetDrawLayer("ARTWORK", 0)

                -- Text (Tag-Nummer)
                button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                button.text:SetPoint("CENTER")
                button.text:SetText("")
                button.text:SetTextColor(1, 1, 1, 1)
                button.text:SetDrawLayer("OVERLAY")

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
        refreshCalendarButton:SetPoint("LEFT", RWLootTrackerGlobal.calendarFrame, "RIGHT", 20, 100)
        refreshCalendarButton:SetSize(180, 30)
        refreshCalendarButton:SetText("Kalender aktualisieren")
        refreshCalendarButton:SetScript("OnClick", function()
            RWLootTrackerGlobal.InitializeCalendar()
        end)

        -- Debug Datensatz Button (im RWLootTrackerGlobal.lootDatabasePanel)
        local debugButton = CreateFrame("Button", nil, RWLootTrackerGlobal.lootDatabasePanel, "GameMenuButtonTemplate")
        debugButton:SetPoint("TOPLEFT", refreshCalendarButton, "BOTTOMLEFT", 0, -10)
        debugButton:SetSize(180, 30)
        debugButton:SetText("Debug Datensatz")
        debugButton:SetFrameLevel(RWLootTrackerGlobal.lootDatabasePanel:GetFrameLevel() + 1)
        debugButton:SetScript("OnClick", function()
            GenerateDebugLootData()
        end)

        -- Neuer "Datenbank leeren" Button
        local clearDatabaseButton = CreateFrame("Button", nil, RWLootTrackerGlobal.lootDatabasePanel, "GameMenuButtonTemplate")
        clearDatabaseButton:SetPoint("TOPLEFT", debugButton, "BOTTOMLEFT", 0, -10)
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
                    if RWLootTrackerGlobal.SaveLootData then
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

DebugPrint("Viewer-Modul geladen (Version " .. RWLootTrackerGlobal.Version .. ").")
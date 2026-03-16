local PANEL = {}

function PANEL:Init()
    local theme = MyCarDealer.Theme
    
    -- Permission Check
    local hasPermission = false
    local ply = LocalPlayer()
    
    if sam and sam.player and sam.player.HasPermission then
        hasPermission = sam.player.HasPermission(ply, "cardealer_admin") or 
                       sam.player.HasPermission(ply, "manage_cardealer") or
                       sam.player.HasPermission(ply, "cardealer_spawn")
    end
    
    if not hasPermission then
        hasPermission = MyCarDealer.IsAdmin(ply)
    end
    
    if game.SinglePlayer() or GetConVar("developer"):GetInt() > 0 then
        hasPermission = true
    end
    
    if not hasPermission then
        chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(255, 255, 255), "Keine Berechtigung! (Gruppe: " .. ply:GetUserGroup() .. ")")
        self:Remove()
        return
    end
    
    self:SetSize(1200, 800)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.5, 0)
    
    self.Paint = function(s, w, h)
        surface.SetDrawColor(theme.background)
        surface.DrawRect(0, 0, w, h)
        
        local time = CurTime() * 0.3
        surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 5)
        for i = 0, w, 100 do
            local offset = math.sin(time + i * 0.01) * 30
            surface.DrawLine(i + offset, 0, i + offset, h)
        end
        
        MyCarDealer.DrawGradient(0, 0, w, 4, theme.error, theme.primary, true)
        surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 20)
        surface.DrawRect(0, 0, w, 150)
    end
    
    -- Header
    local header = vgui.Create("DPanel", self)
    header:SetSize(1200, 100)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("ADMIN CONTROL PANEL", "DermaLarge", 40, 30, theme.error, TEXT_ALIGN_LEFT)
        draw.SimpleText("SYSTEM VERWALTUNG", "DermaDefault", 40, 60, theme.textMuted, TEXT_ALIGN_LEFT)
        draw.RoundedBox(6, w - 250, 35, 15, 15, theme.success)
        draw.SimpleText("SYSTEM ONLINE", "DermaDefault", w - 220, 42, theme.textMuted, TEXT_ALIGN_LEFT)
    end
    
    -- Close Button
    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(55, 55)
    closeBtn:SetPos(1130, 22)
    closeBtn:SetText("")
    closeBtn.Paint = function(s, w, h)
        local hovered = s:IsHovered()
        draw.RoundedBox(16, 0, 0, w, h, hovered and theme.error or Color(50, 50, 50))
        draw.SimpleText("X", "DermaLarge", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        self:AlphaTo(0, 0.3, 0, function() self:Remove() end)
    end
    
    -- Tab Bar
    local tabBar = vgui.Create("DPanel", self)
    tabBar:SetSize(1160, 60)
    tabBar:SetPos(20, 110)
    tabBar.Paint = function() end
    
    self.tabs = {}
    self.activeTab = "spawn"
    
    self:CreateTab(tabBar, "FAHRZEUG SPAWN", 0, "spawn", theme.success)
    self:CreateTab(tabBar, "SPIELER VERWALTUNG", 280, "player", theme.secondary)
    self:CreateTab(tabBar, "CONFIG EDITOR", 560, "config", theme.accent)
    self:CreateTab(tabBar, "SYSTEM LOGS", 840, "logs", theme.primary)
    
    -- Content Panel
    self.content = vgui.Create("DPanel", self)
    self.content:SetSize(1160, 620)
    self.content:SetPos(20, 180)
    self.content.Paint = function(s, w, h)
        draw.RoundedBox(20, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    
    self:CreateSpawnTab()
    self:CreatePlayerTab()
    self:CreateConfigTab()
    self:CreateLogsTab()
    self:ShowTab("spawn")
end

function PANEL:CreateTab(parent, text, x, id, color)
    local theme = MyCarDealer.Theme
    local btn = vgui.Create("DButton", parent)
    btn:SetSize(260, 55)
    btn:SetPos(x, 2)
    btn:SetText("")
    
    btn.Paint = function(s, w, h)
        local active = self.activeTab == id
        local col = active and color or (s:IsHovered() and theme.surfaceHover or theme.glass)
        draw.RoundedBox(12, 0, 0, w, h, col)
        if active then
            surface.SetDrawColor(color)
            surface.DrawRect(0, h-4, w, 4)
            MyCarDealer.DrawGlow(0, 0, w, h, color, 0.4)
        end
        draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:ShowTab(id)
    end
    
    self.tabs[id] = btn
end

function PANEL:ShowTab(id)
    self.activeTab = id
    if IsValid(self.spawnTab) then self.spawnTab:SetVisible(false) end
    if IsValid(self.playerTab) then self.playerTab:SetVisible(false) end
    if IsValid(self.configTab) then self.configTab:SetVisible(false) end
    if IsValid(self.logsTab) then self.logsTab:SetVisible(false) end
    
    if id == "spawn" and IsValid(self.spawnTab) then self.spawnTab:SetVisible(true) end
    if id == "player" and IsValid(self.playerTab) then self.playerTab:SetVisible(true) end
    if id == "config" and IsValid(self.configTab) then self.configTab:SetVisible(true) end
    if id == "logs" and IsValid(self.logsTab) then self.logsTab:SetVisible(true) end
end

-- SPAWN TAB
function PANEL:CreateSpawnTab()
    local theme = MyCarDealer.Theme
    self.spawnTab = vgui.Create("DPanel", self.content)
    self.spawnTab:Dock(FILL)
    self.spawnTab:DockMargin(25, 25, 25, 25)
    self.spawnTab.Paint = function() end
    
    local search = vgui.Create("DTextEntry", self.spawnTab)
    search:Dock(TOP)
    search:SetHeight(50)
    search:DockMargin(0, 0, 0, 20)
    search:SetPlaceholderText("Fahrzeug suchen...")
    search:SetFont("DermaDefault")
    search:SetTextColor(theme.textPrimary)
    search.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.success)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.success, theme.textPrimary)
    end
    
    local scroll = vgui.Create("DScrollPanel", self.spawnTab)
    scroll:Dock(FILL)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(8)
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, theme.success)
    end
    
    local grid = vgui.Create("DPanel", scroll)
    grid:SetSize(1100, 2000)
    grid.Paint = function() end
    
    local cardW = 350
    local cardH = 100
    local spacing = 20
    local cols = 3
    
    for i, vehicle in ipairs(MyCarDealer.Vehicles) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local card = vgui.Create("DButton", grid)
        card:SetSize(cardW, cardH)
        card:SetPos(10 + col * (cardW + spacing), 10 + row * (cardH + spacing))
        card:SetText("")
        card:SetTooltip("Spawnt " .. vehicle.name)
        
        card.Paint = function(s, w, h)
            draw.RoundedBox(14, 0, 0, w, h, s:IsHovered() and theme.surfaceHover or theme.elevated)
            local borderCol = vehicle.previewColor or theme.success
            surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, s:IsHovered() and 255 or 150)
            surface.DrawOutlinedRect(0, 0, w, h, s:IsHovered() and 3 or 1)
            draw.SimpleText(vehicle.name, "DermaDefaultBold", 20, 25, theme.textPrimary, TEXT_ALIGN_LEFT)
            draw.SimpleText("$" .. string.Comma(vehicle.price), "DermaDefault", 20, 55, theme.success, TEXT_ALIGN_LEFT)
            draw.SimpleText(vehicle.category, "DermaDefault", w-20, 55, theme.textMuted, TEXT_ALIGN_RIGHT)
        end
        
        card.DoClick = function()
            net.Start("MyCarDealer_AdminSpawn")
            net.WriteString(vehicle.id)
            net.SendToServer()
            surface.PlaySound("buttons/button9.wav")
            self:ShowNotification(vehicle.name .. " gespawnt", "success")
        end
    end
    
    local totalRows = math.ceil(#MyCarDealer.Vehicles / cols)
    grid:SetHeight(20 + totalRows * (cardH + spacing))
end

-- PLAYER TAB - KORRIGIERT
function PANEL:CreatePlayerTab()
    local theme = MyCarDealer.Theme
    self.playerTab = vgui.Create("DPanel", self.content)
    self.playerTab:Dock(FILL)
    self.playerTab:DockMargin(25, 25, 25, 25)
    self.playerTab.Paint = function() end
    self.playerTab:SetVisible(false)
    
    -- Left Panel (Player List)
    local left = vgui.Create("DPanel", self.playerTab)
    left:Dock(LEFT)
    left:SetWidth(450)
    left.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
    end

    local listHeader = vgui.Create("DLabel", left)
    listHeader:Dock(TOP)
    listHeader:SetHeight(50)
    listHeader:DockMargin(20, 20, 20, 0)
    listHeader:SetText("ONLINE SPIELER")
    listHeader:SetFont("DermaDefaultBold")
    listHeader:SetTextColor(theme.secondary)

    local playerList = vgui.Create("DScrollPanel", left)
    playerList:Dock(FILL)
    playerList:DockMargin(20, 15, 20, 20)

    local sbar = playerList:GetVBar()
    sbar:SetWide(6)
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, theme.secondary)
    end

    self.selectedPlayer = nil
    self.playerButtons = {}
    self.playerList = playerList

    -- Right Panel (Player Details) - WICHTIG: Immer erstellen!
    self.playerDetails = vgui.Create("DPanel", self.playerTab)
    self.playerDetails:Dock(FILL)
    self.playerDetails:DockMargin(25, 0, 0, 0)
    self.playerDetails.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
    end
    
    -- Empty state label
    local emptyLabel = vgui.Create("DLabel", self.playerDetails)
    emptyLabel:Dock(FILL)
    emptyLabel:SetText("Waehle einen Spieler aus")
    emptyLabel:SetFont("DermaDefault")
    emptyLabel:SetTextColor(theme.textMuted)
    emptyLabel:SetContentAlignment(5)

    -- Initial laden
    self:RefreshPlayerList()
    
    -- Auto-Refresh (VERBESSERT: Nutze tostring(self) statt EntIndex)
    self.refreshTimerName = "MyCarDealer_PlayerRefresh_" .. tostring(self):gsub("[^%w]", "_")
    timer.Create(self.refreshTimerName, 3, 0, function()
        if IsValid(self) then
            self:RefreshPlayerList()
        end
    end)
end

function PANEL:RefreshPlayerList()
    if not IsValid(self) or not IsValid(self.playerList) then return end
    
    local theme = MyCarDealer.Theme
    
    -- Alte Buttons entfernen (außer ausgewaehlten behalten falls noch gueltig)
    for _, btn in ipairs(self.playerButtons or {}) do
        if IsValid(btn) then
            btn:Remove()
        end
    end
    self.playerButtons = {}
    
    local yOffset = 0
    
    -- Auch sich selbst anzeigen (markiert als "DU")
    local allPlayers = player.GetAll()
    
    for _, ply in ipairs(allPlayers) do
        if IsValid(ply) then
            local btn = vgui.Create("DButton", self.playerList)
            btn:Dock(TOP)
            btn:SetHeight(70)
            btn:DockMargin(0, 0, 10, 10)
            btn:SetText("")
            
            local isSelf = (ply == LocalPlayer())
            local isSelected = (self.selectedPlayer == ply)
            
            btn.Paint = function(s, w, h)
                local col
                if isSelected then
                    col = Color(theme.secondary.r, theme.secondary.g, theme.secondary.b, 80)
                elseif s:IsHovered() then
                    col = theme.surfaceHover
                else
                    col = theme.glass
                end
                
                draw.RoundedBox(12, 0, 0, w, h, col)
                
                if isSelected then
                    surface.SetDrawColor(theme.secondary)
                    surface.DrawRect(0, 0, 4, h)
                end
                
                local nameText = ply:Nick()
                if isSelf then nameText = nameText .. " (DU)" end
                
                draw.SimpleText(nameText, "DermaDefaultBold", 20, 20, isSelf and theme.success or theme.textPrimary, TEXT_ALIGN_LEFT)
                draw.SimpleText(team.GetName(ply:Team()), "DermaDefault", 20, 42, theme.textMuted, TEXT_ALIGN_LEFT)
                draw.SimpleText("$" .. string.Comma(ply:getDarkRPVar("money") or 0), "DermaDefault", w-20, h/2, theme.success, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                for _, b in pairs(self.playerButtons) do 
                    if IsValid(b) then b.isSelected = false end 
                end
                isSelected = true
                self.selectedPlayer = ply
                self:UpdatePlayerDetails(ply)
                surface.PlaySound("ui/buttonclick.wav")
            end
            
            btn.isSelected = isSelected
            table.insert(self.playerButtons, btn)
        end
    end
end

function PANEL:UpdatePlayerDetails(ply)
    local theme = MyCarDealer.Theme
    for _, child in pairs(self.playerDetails:GetChildren()) do
        if IsValid(child) then child:Remove() end
    end
    
    local header = vgui.Create("DPanel", self.playerDetails)
    header:Dock(TOP)
    header:SetHeight(100)
    header:DockMargin(25, 25, 25, 0)
    header.Paint = function(s, w, h)
        draw.SimpleText(ply:Nick(), "DermaLarge", 0, 0, theme.textPrimary, TEXT_ALIGN_LEFT)
        draw.SimpleText(ply:SteamID(), "DermaDefault", 0, 40, theme.textMuted, TEXT_ALIGN_LEFT)
        draw.SimpleText("Geld: $" .. string.Comma(ply:getDarkRPVar("money") or 0), "DermaDefault", 0, 65, theme.success, TEXT_ALIGN_LEFT)
    end
    
    local actions = vgui.Create("DPanel", self.playerDetails)
    actions:Dock(TOP)
    actions:SetHeight(400)
    actions:DockMargin(25, 20, 25, 0)
    actions.Paint = function() end
    
    -- Give Vehicle
    local giveLabel = vgui.Create("DLabel", actions)
    giveLabel:SetPos(0, 0)
    giveLabel:SetSize(500, 30)
    giveLabel:SetText("FAHRZEUG GEBEN")
    giveLabel:SetFont("DermaDefaultBold")
    giveLabel:SetTextColor(theme.success)
    
    local giveCombo = vgui.Create("DComboBox", actions)
    giveCombo:SetPos(0, 40)
    giveCombo:SetSize(350, 45)
    giveCombo:SetValue("Fahrzeug waehlen...")
    
    for _, v in ipairs(MyCarDealer.Vehicles) do
        giveCombo:AddChoice(v.name, v.id)
    end
    
    local giveBtn = vgui.Create("DButton", actions)
    giveBtn:SetPos(370, 40)
    giveBtn:SetSize(120, 45)
    giveBtn:SetText("")
    giveBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.success or Color(0, 180, 100))
        draw.SimpleText("GEBEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    giveBtn.DoClick = function()
        local _, id = giveCombo:GetSelected()
        if id then
            net.Start("MyCarDealer_AdminGive")
            net.WriteEntity(ply)
            net.WriteString(id)
            net.SendToServer()
            self:ShowNotification("Fahrzeug gegeben", "success")
        end
    end
    
    -- Remove Vehicle
    local removeLabel = vgui.Create("DLabel", actions)
    removeLabel:SetPos(0, 110)
    removeLabel:SetSize(500, 30)
    removeLabel:SetText("FAHRZEUG ENTFERNEN")
    removeLabel:SetFont("DermaDefaultBold")
    removeLabel:SetTextColor(theme.error)
    
    local removeCombo = vgui.Create("DComboBox", actions)
    removeCombo:SetPos(0, 150)
    removeCombo:SetSize(350, 45)
    removeCombo:SetValue("Fahrzeug waehlen...")
    
    for _, v in ipairs(MyCarDealer.Vehicles) do
        removeCombo:AddChoice(v.name, v.id)
    end
    
    local removeBtn = vgui.Create("DButton", actions)
    removeBtn:SetPos(370, 150)
    removeBtn:SetSize(120, 45)
    removeBtn:SetText("")
    removeBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.error or Color(180, 50, 50))
        draw.SimpleText("ENTFERNEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    removeBtn.DoClick = function()
        local _, id = removeCombo:GetSelected()
        if id then
            net.Start("MyCarDealer_AdminRemove")
            net.WriteEntity(ply)
            net.WriteString(id)
            net.SendToServer()
            self:ShowNotification("Fahrzeug entfernt", "success")
        end
    end
end

-- CONFIG EDITOR TAB - VERBESSERT
function PANEL:CreateConfigTab()
    local theme = MyCarDealer.Theme
    self.configTab = vgui.Create("DPanel", self.content)
    self.configTab:Dock(FILL)
    self.configTab:DockMargin(25, 25, 25, 25)
    self.configTab.Paint = function() end
    self.configTab:SetVisible(false)
    
    -- Left: Form
    local formPanel = vgui.Create("DPanel", self.configTab)
    formPanel:Dock(LEFT)
    formPanel:SetWidth(550)
    formPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
    end
    
    -- Header mit Hilfe-Text
    local formHeader = vgui.Create("DPanel", formPanel)
    formHeader:Dock(TOP)
    formHeader:SetHeight(80)
    formHeader:DockMargin(15, 15, 15, 0)
    formHeader.Paint = function(s, w, h)
        draw.SimpleText("NEUES FAHRZEUG HINZUFUEGEN", "DermaDefaultBold", 10, 5, theme.accent, TEXT_ALIGN_LEFT)
        draw.SimpleText("1. Fuelle alle Felder aus", "DermaDefault", 10, 30, theme.textMuted, TEXT_ALIGN_LEFT)
        draw.SimpleText("2. Klicke 'ZUR CONFIG HINZUFUEGEN'", "DermaDefault", 10, 48, theme.textMuted, TEXT_ALIGN_LEFT)
        draw.SimpleText("3. Fahrzeug erscheint sofort im Shop", "DermaDefault", 10, 66, theme.textMuted, TEXT_ALIGN_LEFT)
    end
    
    local scroll = vgui.Create("DScrollPanel", formPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(15, 10, 15, 15)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, theme.accent)
    end
    
    -- Formular Container
    local formContainer = vgui.Create("DPanel", scroll)
    formContainer:Dock(TOP)
    formContainer:SetHeight(1200)
    formContainer.Paint = function() end
    
    local yPos = 0
    local lineHeight = 75
    
    -- Hilfsfunktion fuer Form-Felder
    local function CreateFormField(parent, labelText, y, isRequired, tooltip)
        local label = vgui.Create("DLabel", parent)
        label:SetPos(0, y)
        label:SetSize(520, 20)
        local reqText = isRequired and " *" or ""
        label:SetText(labelText .. reqText)
        label:SetTextColor(isRequired and theme.accent or theme.textSecondary)
        label:SetFont("DermaDefaultBold")
        if tooltip then
            label:SetTooltip(tooltip)
        end
        return y + 25
    end
    
    -- ID
    yPos = CreateFormField(formContainer, "FAHRZEUG ID", yPos, true, "Eindeutige ID, z.B. 'bmw_m3_e46' - keine Leerzeichen!")
    local idEntry = vgui.Create("DTextEntry", formContainer)
    idEntry:SetPos(0, yPos)
    idEntry:SetSize(520, 35)
    idEntry:SetPlaceholderText("z.B. bmw_m3_e46")
    idEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.idEntry = idEntry
    yPos = yPos + lineHeight
    
    -- Name
    yPos = CreateFormField(formContainer, "ANZEIGENAME", yPos, true, "Der Name im Shop, z.B. 'BMW M3 E46'")
    local nameEntry = vgui.Create("DTextEntry", formContainer)
    nameEntry:SetPos(0, yPos)
    nameEntry:SetSize(520, 35)
    nameEntry:SetPlaceholderText("z.B. BMW M3 E46")
    nameEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.nameEntry = nameEntry
    yPos = yPos + lineHeight
    
    -- Category
    yPos = CreateFormField(formContainer, "KATEGORIE", yPos, true)
    local catCombo = vgui.Create("DComboBox", formContainer)
    catCombo:SetPos(0, yPos)
    catCombo:SetSize(520, 35)
    catCombo:SetValue("Kategorie waehlen...")
    for _, cat in ipairs(MyCarDealer.Categories) do
        catCombo:AddChoice(cat)
    end
    catCombo.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    self.catCombo = catCombo
    yPos = yPos + lineHeight
    
    -- Price
    yPos = CreateFormField(formContainer, "PREIS ($)", yPos, true)
    local priceEntry = vgui.Create("DTextEntry", formContainer)
    priceEntry:SetPos(0, yPos)
    priceEntry:SetSize(520, 35)
    priceEntry:SetPlaceholderText("z.B. 75000")
    priceEntry:SetNumeric(true)
    priceEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.priceEntry = priceEntry
    yPos = yPos + lineHeight
    
    -- Model Path
    yPos = CreateFormField(formContainer, "MODEL PFAD", yPos, true, "Voller Pfad zum Model, z.B. 'models/diggercars/bmw_e46/e46.mdl'")
    local modelEntry = vgui.Create("DTextEntry", formContainer)
    modelEntry:SetPos(0, yPos)
    modelEntry:SetSize(520, 35)
    modelEntry:SetPlaceholderText("z.B. models/diggercars/bmw_e46/e46.mdl")
    modelEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.modelEntry = modelEntry
    yPos = yPos + lineHeight
    
    -- Class
    yPos = CreateFormField(formContainer, "FAHRZEUG CLASS", yPos, true, "LVS Class Name, z.B. 'lvs_wheeldrive_bmw_e46m3'")
    local classEntry = vgui.Create("DTextEntry", formContainer)
    classEntry:SetPos(0, yPos)
    classEntry:SetSize(520, 35)
    classEntry:SetPlaceholderText("z.B. lvs_wheeldrive_bmw_e46m3")
    classEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.classEntry = classEntry
    yPos = yPos + lineHeight
    
    -- Job (optional)
    yPos = CreateFormField(formContainer, "JOB EINSCHRAENKUNG (OPTIONAL)", yPos, false, "Leer lassen fuer alle Jobs, z.B. 'TEAM_POLICE'")
    local jobEntry = vgui.Create("DTextEntry", formContainer)
    jobEntry:SetPos(0, yPos)
    jobEntry:SetSize(520, 35)
    jobEntry:SetPlaceholderText("Leer lassen oder z.B. TEAM_POLICE")
    jobEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.jobEntry = jobEntry
    yPos = yPos + lineHeight
    
    -- Max Speed
    yPos = CreateFormField(formContainer, "MAX GESCHWINDIGKEIT (ANZEIGE)", yPos, false)
    local speedEntry = vgui.Create("DTextEntry", formContainer)
    speedEntry:SetPos(0, yPos)
    speedEntry:SetSize(520, 35)
    speedEntry:SetPlaceholderText("z.B. 250")
    speedEntry:SetNumeric(true)
    speedEntry:SetText("250")
    speedEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.speedEntry = speedEntry
    yPos = yPos + lineHeight
    
    -- Description
    yPos = CreateFormField(formContainer, "BESCHREIBUNG", yPos, false)
    local descEntry = vgui.Create("DTextEntry", formContainer)
    descEntry:SetPos(0, yPos)
    descEntry:SetSize(520, 60)
    descEntry:SetPlaceholderText("Fahrzeugbeschreibung...")
    descEntry:SetMultiline(true)
    descEntry.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.accent, theme.textPrimary)
    end
    self.descEntry = descEntry
    yPos = yPos + 80
    
    -- Preview Color
    yPos = CreateFormField(formContainer, "PREVIEW FARBE", yPos, false)
    local colorPanel = vgui.Create("DPanel", formContainer)
    colorPanel:SetPos(0, yPos)
    colorPanel:SetSize(520, 50)
    colorPanel.Paint = function() end
    
    self.previewColor = Color(255, 255, 255)
    
    local colorPreview = vgui.Create("DPanel", colorPanel)
    colorPreview:SetSize(50, 50)
    colorPreview:SetPos(0, 0)
    colorPreview.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, self.previewColor)
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    
    local colorBtn = vgui.Create("DButton", colorPanel)
    colorBtn:SetSize(460, 50)
    colorBtn:SetPos(60, 0)
    colorBtn:SetText("")
    colorBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.surfaceHover or theme.glass)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("FARBE AENDERN (KLICKEN)", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    colorBtn.DoClick = function()
        self:OpenColorPicker("PREVIEW FARBE WAEHLEN", self.previewColor, function(col)
            self.previewColor = col
        end)
    end
    yPos = yPos + 70
    
    -- Add Button - VERBESSERT
    local addBtn = vgui.Create("DButton", formContainer)
    addBtn:SetPos(0, yPos)
    addBtn:SetSize(520, 55)
    addBtn:SetText("")
    addBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and theme.accent or theme.accentDark
        draw.RoundedBox(12, 0, 0, w, h, col)
        if s:IsHovered() then
            surface.SetDrawColor(theme.accentLight)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        draw.SimpleText("ZUR CONFIG HINZUFUEGEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addBtn.DoClick = function()
        self:AddVehicleToConfig()
    end
    yPos = yPos + 75
    
    -- Remove Vehicle Section
    yPos = yPos + 20
    
    local removeHeader = vgui.Create("DPanel", formContainer)
    removeHeader:SetPos(0, yPos)
    removeHeader:SetSize(520, 30)
    removeHeader.Paint = function(s, w, h)
        surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 30)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(theme.error)
        surface.DrawRect(0, h-2, w, 2)
        draw.SimpleText("FAHRZEUG ENTFERNEN (ADMIN)", "DermaDefaultBold", 10, h/2, theme.error, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    yPos = yPos + 40
    
    local removeCombo = vgui.Create("DComboBox", formContainer)
    removeCombo:SetPos(0, yPos)
    removeCombo:SetSize(350, 45)
    removeCombo:SetValue("Fahrzeug zum Entfernen waehlen...")
    
    for _, v in ipairs(MyCarDealer.Vehicles) do
        removeCombo:AddChoice(v.name .. " (" .. v.id .. ")", v.id)
    end
    
    removeCombo.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.error)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    self.removeCombo = removeCombo
    
    local removeBtn = vgui.Create("DButton", formContainer)
    removeBtn:SetPos(370, yPos)
    removeBtn:SetSize(150, 45)
    removeBtn:SetText("")
    removeBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.error or Color(180, 50, 50))
        draw.SimpleText("ENTFERNEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    removeBtn.DoClick = function()
        local _, id = removeCombo:GetSelected()
        if not id then
            self:ShowNotification("Waehle ein Fahrzeug zum Entfernen!", "error")
            return
        end
        
        local vehicleName = ""
        for _, v in ipairs(MyCarDealer.Vehicles) do
            if v.id == id then vehicleName = v.name break end
        end
        
        -- Bestaetigungsdialog
        local confirm = vgui.Create("DFrame")
        confirm:SetSize(450, 220)
        confirm:Center()
        confirm:SetTitle("")
        confirm:ShowCloseButton(false)
        confirm:MakePopup()
        confirm:SetAlpha(0)
        confirm:AlphaTo(255, 0.2, 0)
        
        confirm.Paint = function(s, w, h)
            draw.RoundedBox(16, 0, 0, w, h, theme.surface)
            surface.SetDrawColor(theme.error)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            surface.SetDrawColor(theme.elevated)
            surface.DrawRect(0, 0, w, 50)
            draw.SimpleText("WARNUNG: FAHRZEUG ENTFERNEN", "DermaLarge", w/2, 25, theme.error, TEXT_ALIGN_CENTER)
        end
        
        local text = vgui.Create("DLabel", confirm)
        text:SetSize(410, 100)
        text:SetPos(20, 60)
        text:SetText("Fahrzeug: " .. vehicleName .. "\n\nDies entfernt das Fahrzeug aus:\n- Der Config (sofort)\n- ALLEN Spieler-Inventaren (DB)\n- Aktiven Fahrzeugen werden entfernt\n\nDies kann NICHT rueckgaengig gemacht werden!")
        text:SetFont("DermaDefault")
        text:SetTextColor(theme.textPrimary)
        
        local yes = vgui.Create("DButton", confirm)
        yes:SetSize(180, 45)
        yes:SetPos(30, 165)
        yes:SetText("")
        yes.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.error or Color(200, 50, 50))
            draw.SimpleText("JA, ENTFERNEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        yes.DoClick = function()
            self:RemoveVehicleCompletely(id)
            confirm:Remove()
        end
        
        local no = vgui.Create("DButton", confirm)
        no:SetSize(180, 45)
        no:SetPos(240, 165)
        no:SetText("")
        no.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.success or Color(50, 150, 100))
            draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        no.DoClick = function()
            confirm:Remove()
        end
    end
    
    yPos = yPos + 60
    
    -- Container-Hoehe anpassen
    formContainer:SetHeight(yPos + 50)
    
    -- Right: Live Preview - VERBESSERT
    local previewPanel = vgui.Create("DPanel", self.configTab)
    previewPanel:Dock(FILL)
    previewPanel:DockMargin(25, 0, 0, 0)
    previewPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
    end
    
    local previewHeader = vgui.Create("DPanel", previewPanel)
    previewHeader:Dock(TOP)
    previewHeader:SetHeight(60)
    previewHeader:DockMargin(15, 15, 15, 0)
    previewHeader.Paint = function(s, w, h)
        draw.SimpleText("LIVE CONFIG VORSCHAU", "DermaDefaultBold", 10, 10, theme.accent, TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(#MyCarDealer.Vehicles) .. " Fahrzeuge geladen", "DermaDefault", 10, 35, theme.textMuted, TEXT_ALIGN_LEFT)
    end
    
    -- VERBESSERT: Groesserer Scrollbereich
    local previewScroll = vgui.Create("DScrollPanel", previewPanel)
    previewScroll:Dock(FILL)
    previewScroll:DockMargin(15, 10, 15, 15)
    
    local sbar2 = previewScroll:GetVBar()
    sbar2:SetWide(8)
    sbar2.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, theme.accent)
    end
    
    -- DTextEntry mit automatischer Hoehe
    self.configPreview = vgui.Create("DTextEntry", previewScroll)
    self.configPreview:Dock(TOP)
    self.configPreview:SetMultiline(true)
    self.configPreview:SetEditable(false)
    self.configPreview:SetFont("DermaDefault")
    self.configPreview:SetTextColor(theme.textSecondary)
    self.configPreview.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(10, 10, 15))
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textSecondary, theme.accent, theme.textSecondary)
    end
    
    self:UpdateConfigPreview()
end

function PANEL:RemoveVehicleCompletely(vehicleID)
    local theme = MyCarDealer.Theme
    
    -- 1. Aus Config entfernen
    for i, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == vehicleID then
            table.remove(MyCarDealer.Vehicles, i)
            break
        end
    end
    
    -- Cache neu aufbauen
    if MyCarDealer.RebuildVehicleCache then
        MyCarDealer.RebuildVehicleCache()
    end
    
    -- 2. Server mitteilen (fuer DB-Entfernung)
    net.Start("MyCarDealer_RemoveVehicleFromDB")
    net.WriteString(vehicleID)
    net.SendToServer()
    
    -- 3. UI aktualisieren
    self:UpdateConfigPreview()
    
    -- Remove-Combo neu fuellen
    if IsValid(self.removeCombo) then
        self.removeCombo:Clear()
        self.removeCombo:SetValue("Fahrzeug zum Entfernen waehlen...")
        for _, v in ipairs(MyCarDealer.Vehicles) do
            self.removeCombo:AddChoice(v.name .. " (" .. v.id .. ")", v.id)
        end
    end
    
    self:ShowNotification("Fahrzeug '" .. vehicleID .. "' wird entfernt...", "success")
end

-- VERBESSERTER Color Picker mit Close Button
function PANEL:OpenColorPicker(title, defaultColor, callback)
    local theme = MyCarDealer.Theme
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(450, 400)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.3, 0)
    
    frame.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Header
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 0, w, 50)
        draw.SimpleText(title, "DermaLarge", w/2, 25, theme.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Close Button (X)
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(400, 5)
    closeBtn:SetText("X")
    closeBtn:SetFont("DermaLarge")
    closeBtn:SetTextColor(theme.textPrimary)
    closeBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.error or Color(0,0,0,0))
    end
    closeBtn.DoClick = function()
        frame:Remove()
    end
    
    local mixer = vgui.Create("DColorMixer", frame)
    mixer:SetSize(400, 250)
    mixer:SetPos(25, 70)
    mixer:SetColor(defaultColor)
    mixer:SetPalette(false)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    
    local currentColor = defaultColor
    
    -- Live Preview
    local preview = vgui.Create("DPanel", frame)
    preview:SetSize(400, 40)
    preview:SetPos(25, 330)
    preview.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, currentColor)
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText("VORSCHAU", "DermaDefaultBold", w/2, h/2, Color(255-currentColor.r, 255-currentColor.g, 255-currentColor.b), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    mixer.ValueChanged = function()
        currentColor = mixer:GetColor()
    end
    
    -- Buttons
    local okBtn = vgui.Create("DButton", frame)
    okBtn:SetSize(190, 45)
    okBtn:SetPos(25, 340)
    okBtn:SetText("")
    okBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.success or Color(0, 200, 100))
        draw.SimpleText("UEBERNEHMEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    okBtn.DoClick = function()
        callback(currentColor)
        frame:Remove()
    end
    
    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetSize(190, 45)
    cancelBtn:SetPos(235, 340)
    cancelBtn:SetText("")
    cancelBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.error or Color(200, 50, 50))
        draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancelBtn.DoClick = function()
        frame:Remove()
    end
end

function PANEL:AddVehicleToConfig()
    local theme = MyCarDealer.Theme
    
    local id = self.idEntry:GetValue()
    local name = self.nameEntry:GetValue()
    local category = self.catCombo:GetValue()
    local price = tonumber(self.priceEntry:GetValue()) or 0
    local model = self.modelEntry:GetValue()
    local class = self.classEntry:GetValue()
    local job = self.jobEntry:GetValue()
    local speed = tonumber(self.speedEntry:GetValue()) or 250
    local desc = self.descEntry:GetValue()
    
    -- Validierung
    if id == "" or name == "" or model == "" or class == "" or category == "Kategorie waehlen..." then
        self:ShowNotification("Bitte alle Pflichtfelder (*) ausfuellen!", "error")
        surface.PlaySound("buttons/button10.wav")
        return
    end
    
    -- ID Format pruefen
    if not id:match("^[a-z0-9_]+$") then
        self:ShowNotification("ID darf nur Kleinbuchstaben, Zahlen und Unterstriche enthalten!", "error")
        return
    end
    
    -- Pruefen ob ID existiert
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == id then
            self:ShowNotification("Diese ID existiert bereits!", "error")
            return
        end
    end
    
    -- Neues Fahrzeug erstellen
    local newVehicle = {
        id = id,
        name = name,
        category = category,
        price = price,
        model = model,
        class = class,
        job = (job ~= "" and job) or nil,
        maxSpeed = speed,
        description = desc,
        previewColor = Color(self.previewColor.r, self.previewColor.g, self.previewColor.b)
    }
    
    table.insert(MyCarDealer.Vehicles, newVehicle)
    
    if MyCarDealer.RebuildVehicleCache then
        MyCarDealer.RebuildVehicleCache()
    end
    
    net.Start("MyCarDealer_SaveConfig")
    net.WriteTable(MyCarDealer.Vehicles)
    net.SendToServer()
    
    -- Form zuruecksetzen
    self.idEntry:SetValue("")
    self.nameEntry:SetValue("")
    self.catCombo:SetValue("Kategorie waehlen...")
    self.priceEntry:SetValue("")
    self.modelEntry:SetValue("")
    self.classEntry:SetValue("")
    self.jobEntry:SetValue("")
    self.speedEntry:SetValue("250")
    self.descEntry:SetValue("")
    self.previewColor = Color(255, 255, 255)
    
    -- Remove-Combo aktualisieren
    if IsValid(self.removeCombo) then
        self.removeCombo:AddChoice(newVehicle.name .. " (" .. newVehicle.id .. ")", newVehicle.id)
    end
    
    self:UpdateConfigPreview()
    self:ShowNotification("Fahrzeug '" .. name .. "' hinzugefuegt!", "success")
end

function PANEL:UpdateConfigPreview()
    local configText = "-- ============================================\n"
    configText = configText .. "-- Dynora CarDealer - Vehicle Config\n"
    configText = configText .. "-- " .. tostring(#MyCarDealer.Vehicles) .. " Fahrzeuge\n"
    configText = configText .. "-- ============================================\n\n"
    configText = configText .. "MyCarDealer.Vehicles = {\n"
    
    for _, v in ipairs(MyCarDealer.Vehicles) do
        configText = configText .. "    {\n"
        configText = configText .. '        id = "' .. v.id .. '",\n'
        configText = configText .. '        name = "' .. v.name .. '",\n'
        configText = configText .. '        category = "' .. v.category .. '",\n'
        configText = configText .. "        price = " .. v.price .. ",\n"
        configText = configText .. '        model = "' .. v.model .. '",\n'
        configText = configText .. '        class = "' .. v.class .. '",\n'
        if v.job then
            configText = configText .. '        job = "' .. v.job .. '",\n'
        else
            configText = configText .. "        job = nil,\n"
        end
        configText = configText .. "        maxSpeed = " .. (v.maxSpeed or 250) .. ",\n"
        configText = configText .. '        description = "' .. (v.description or "") .. '",\n'
        configText = configText .. "        previewColor = Color(" .. (v.previewColor and v.previewColor.r or 255) .. ", " .. 
                     (v.previewColor and v.previewColor.g or 255) .. ", " .. 
                     (v.previewColor and v.previewColor.b or 255) .. ")\n"
        configText = configText .. "    },\n"
    end
    
    configText = configText .. "}"
    self.configPreview:SetText(configText)
    
    -- WICHTIG: Hoehe an Content anpassen
    surface.SetFont("DermaDefault")
    local _, lineHeight = surface.GetTextSize("A")
    local lines = select(2, configText:gsub("\n", "\n"))
    local neededHeight = math.max((lines + 5) * lineHeight, 400)
    self.configPreview:SetHeight(neededHeight)
end

-- LOGS TAB - VERBESSERT
function PANEL:CreateLogsTab()
    local theme = MyCarDealer.Theme
    self.logsTab = vgui.Create("DPanel", self.content)
    self.logsTab:Dock(FILL)
    self.logsTab:DockMargin(25, 25, 25, 25)
    self.logsTab.Paint = function() end
    self.logsTab:SetVisible(false)
    
    -- Toolbar
    local toolbar = vgui.Create("DPanel", self.logsTab)
    toolbar:Dock(TOP)
    toolbar:SetHeight(50)
    toolbar.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.elevated)
        draw.SimpleText("SYSTEM LOGS", "DermaDefaultBold", 15, h/2, theme.primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Refresh Button
    local refreshBtn = vgui.Create("DButton", toolbar)
    refreshBtn:SetSize(120, 35)
    refreshBtn:SetPos(toolbar:GetWide() - 130, 7)
    refreshBtn:SetText("")
    refreshBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.success or Color(50, 150, 100))
        draw.SimpleText("AKTUALISIEREN", "DermaDefault", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    refreshBtn.DoClick = function()
        self:LoadLogs()
    end
    
    -- Logs Liste
    self.logsList = vgui.Create("DScrollPanel", self.logsTab)
    self.logsList:Dock(FILL)
    self.logsList:DockMargin(0, 10, 0, 0)
    
    local sbar = self.logsList:GetVBar()
    sbar:SetWide(8)
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, theme.primary)
    end
    
    self.logsContainer = vgui.Create("DPanel", self.logsList)
    self.logsContainer:Dock(TOP)
    self.logsContainer:SetHeight(1000)
    self.logsContainer.Paint = function() end
    
    -- Initial laden
    self:LoadLogs()
    
    -- Auto-refresh alle 10 Sekunden wenn Tab aktiv
    self.logsTimerName = "MyCarDealer_LogsRefresh_" .. tostring(self):gsub("[^%w]", "_")
    timer.Create(self.logsTimerName, 10, 0, function()
        if IsValid(self) and self.activeTab == "logs" then
            self:LoadLogs()
        end
    end)
end

function PANEL:LoadLogs()
    -- Vom Server anfragen
    net.Start("MyCarDealer_RequestLogs")
    net.SendToServer()
end

function PANEL:ShowNotification(text, type)
    local theme = MyCarDealer.Theme
    local col = type == "success" and theme.success or theme.error
    
    local notif = vgui.Create("DFrame")
    notif:SetSize(400, 80)
    notif:Center()
    notif:SetTitle("")
    notif:ShowCloseButton(false)
    notif:MakePopup()
    notif:SetAlpha(0)
    
    notif.Paint = function(s, w, h)
        draw.RoundedBox(14, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText(type == "success" and "OK" or "X", "DermaLarge", 40, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "DermaDefaultBold", 80, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    notif:AlphaTo(255, 0.2, 0, function()
        timer.Simple(2.5, function()
            if IsValid(notif) then
                notif:AlphaTo(0, 0.3, 0, function() notif:Remove() end)
            end
        end)
    end)
end

function PANEL:OnRemove()
    -- Alle Timer cleanup (VERBESSERT: Nutze gespeicherte Namen)
    if self.refreshTimerName then
        timer.Remove(self.refreshTimerName)
    end
    if self.logsTimerName then
        timer.Remove(self.logsTimerName)
    end
end

vgui.Register("MyCarDealer_Admin", PANEL, "DFrame")

function MyCarDealer.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if sam and sam.player and sam.player.HasPermission then
        if sam.player.HasPermission(ply, "cardealer_admin") then return true end
        if sam.player.HasPermission(ply, "manage_cardealer") then return true end
        if sam.player.HasPermission(ply, "cardealer_spawn") then return true end
    end
    local userGroup = ply:GetUserGroup()
    if userGroup == "superadmin" then return true end
    if userGroup == "admin" then return true end
    if userGroup == "sadmin" then return true end
    return false
end

net.Receive("MyCarDealer_OpenAdminMenu", function()
    vgui.Create("MyCarDealer_Admin")
end)

-- Logs empfangen
net.Receive("MyCarDealer_SendLogs", function()
    local logs = net.ReadTable()
    
    -- Aktualisiere Logs Tab wenn offen
    for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
        if IsValid(v) and v:GetName() == "MyCarDealer_Admin" and IsValid(v.logsContainer) then
            local theme = MyCarDealer.Theme
            
            -- Alte entfernen
            for _, child in pairs(v.logsContainer:GetChildren()) do
                child:Remove()
            end
            
            -- Neue anzeigen
            local y = 0
            for i, log in ipairs(logs) do
                local entry = vgui.Create("DPanel", v.logsContainer)
                entry:SetSize(v.logsContainer:GetWide() - 20, 50)
                entry:SetPos(10, y)
                
                local logCol = theme.glass
                if log.action == "ERROR" or log.action == "ADMIN_REMOVE" or log.action == "ADMIN_REMOVE_VEHICLE" then 
                    logCol = Color(150, 50, 50, 60)
                elseif log.action == "BUY" then 
                    logCol = Color(50, 150, 50, 60)
                elseif log.action == "ADMIN" or log.action == "ADMIN_SPAWN" or log.action == "ADMIN_GIVE" then 
                    logCol = Color(50, 100, 150, 60)
                elseif log.action == "SELL" then
                    logCol = Color(200, 150, 50, 60)
                end
                
                entry.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, logCol)
                    surface.SetDrawColor(theme.border)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    
                    draw.SimpleText("[" .. (log.time or "?") .. "]", "DermaDefault", 10, h/2, theme.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(log.action, "DermaDefaultBold", 110, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText((log.player or "?") .. ": " .. (log.details or ""), "DermaDefault", 220, h/2, theme.textSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                y = y + 55
            end
            
            if #logs == 0 then
                local empty = vgui.Create("DLabel", v.logsContainer)
                empty:SetSize(v.logsContainer:GetWide(), 100)
                empty:SetPos(0, 50)
                empty:SetText("Keine Logs vorhanden")
                empty:SetFont("DermaDefault")
                empty:SetTextColor(theme.textMuted)
                empty:SetContentAlignment(5)
            end
            
            v.logsContainer:SetHeight(math.max(y + 50, 500))
        end
    end
end)

concommand.Add("cardealer_admin", function()
    vgui.Create("MyCarDealer_Admin")
end)

concommand.Add("cardealer_admin_force", function(ply)
    if IsValid(ply) and ply:IsSuperAdmin() then
        vgui.Create("MyCarDealer_Admin")
    end
end)

print("[Dynora Motor´s] cl_admin.lua loaded")
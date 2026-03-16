local PANEL = {}

function PANEL:Init()
    local theme = MyCarDealer.Theme
    
    self:SetSize(ScrW() * 0.9, ScrH() * 0.9)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.5, 0)
    
    -- Blur Hintergrund
    self.Paint = function(s, w, h)
        -- Dark overlay
        surface.SetDrawColor(theme.background)
        surface.DrawRect(0, 0, w, h)
        
        -- Animated grid
        local time = CurTime() * 0.5
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 3)
        for i = 0, w, 60 do
            local offset = math.sin(time + i * 0.01) * 20
            surface.DrawLine(i + offset, 0, i + offset, h)
        end
        for i = 0, h, 60 do
            local offset = math.cos(time + i * 0.01) * 20
            surface.DrawLine(0, i + offset, w, i + offset)
        end
        
        -- Top gradient line
        MyCarDealer.DrawGradient(0, 0, w, 4, theme.primary, theme.secondary, true)
        
        -- Glow effect at top
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 20)
        surface.DrawRect(0, 0, w, 150)
    end
    
    -- Header Panel
    local header = vgui.Create("DPanel", self)
    header:SetSize(self:GetWide(), 100)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        -- Glass effect
        surface.SetDrawColor(theme.elevated.r, theme.elevated.g, theme.elevated.b, 200)
        surface.DrawRect(0, 0, w, h)
        
        -- Title with glow
        draw.SimpleText("PERSONAL GARAGE", "DermaLarge", 40, 25, theme.primary, TEXT_ALIGN_LEFT)
        draw.SimpleText("FAHRZEUGVERWALTUNG", "DermaDefault", 40, 55, theme.textMuted, TEXT_ALIGN_LEFT)
        
        -- Stats
        local count = MyCarDealer.MyInventory and #MyCarDealer.MyInventory or 0
        draw.SimpleText(count .. " FAHRZEUGE", "DermaDefaultBold", w - 40, 40, theme.secondary, TEXT_ALIGN_RIGHT)
        
        -- Bottom line
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 100)
        surface.DrawRect(0, h-2, w, 2)
    end
    
    -- Store Button (Autos Einparken)
    local storeBtn = vgui.Create("DButton", header)
    storeBtn:SetSize(200, 50)
    storeBtn:SetPos(header:GetWide() - 320, 25)
    storeBtn:SetText("")
    storeBtn:SetTooltip("Alle deine aktiven Fahrzeuge einparken")
    
    storeBtn.Paint = function(s, w, h)
        local hovered = s:IsHovered()
        local col = hovered and theme.accent or theme.accentDark
        
        -- Animated background
        draw.RoundedBox(12, 0, 0, w, h, col)
        
        -- Shine effect
        if hovered then
            surface.SetDrawColor(255, 255, 255, 30)
            surface.DrawRect(0, 0, w, h/2)
            
            surface.SetDrawColor(theme.accentLight)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        -- Icon + Text
        draw.SimpleText("[", "DermaLarge", 20, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("EINPARKEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("]", "DermaLarge", w-20, h/2, theme.textPrimary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    
    storeBtn.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        net.Start("MyCarDealer_GlobalStore")
        net.SendToServer()
        
        -- Visual feedback
        local notif = vgui.Create("DFrame")
        notif:SetSize(300, 80)
        notif:Center()
        notif:SetTitle("")
        notif:ShowCloseButton(false)
        notif:SetAlpha(0)
        notif:MakePopup()
        notif.Paint = function(s, w, h)
            draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
            surface.SetDrawColor(theme.accent)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.SimpleText("Einparken...", "DermaLarge", w/2, h/2, theme.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        notif:AlphaTo(255, 0.2, 0, function()
            timer.Simple(1, function() if IsValid(notif) then notif:Remove() end end)
        end)
    end
    
    -- Close Button
    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(50, 50)
    closeBtn:SetPos(header:GetWide() - 80, 25)
    closeBtn:SetText("")
    
    closeBtn.Paint = function(s, w, h)
        local hovered = s:IsHovered()
        draw.RoundedBox(12, 0, 0, w, h, hovered and theme.error or Color(60, 60, 60))
        
        draw.SimpleText("×", "DermaLarge", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if hovered then
            surface.SetDrawColor(theme.error)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end
    
    closeBtn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:AlphaTo(0, 0.3, 0, function()
            self:Remove()
            vgui.Create("MyCarDealer_Menu")
        end)
    end
    
    -- Main Container
    local container = vgui.Create("DPanel", self)
    container:SetSize(self:GetWide() - 80, self:GetTall() - 180)
    container:SetPos(40, 120)
    container.Paint = function(s, w, h)
        draw.RoundedBox(20, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    
    -- Toolbar
    local toolbar = vgui.Create("DPanel", container)
    toolbar:Dock(TOP)
    toolbar:SetHeight(70)
    toolbar:DockMargin(25, 25, 25, 0)
    toolbar.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
    end
    
    -- Search
    local searchEntry = vgui.Create("DTextEntry", toolbar)
    searchEntry:SetSize(350, 45)
    searchEntry:SetPos(20, 12)
    searchEntry:SetPlaceholderText("Fahrzeug suchen...")
    searchEntry:SetFont("DermaDefault")
    searchEntry:SetTextColor(theme.textPrimary)
    searchEntry.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.textPrimary, theme.secondary, theme.textPrimary)
    end
    
    -- Search Icon
    local searchIcon = vgui.Create("DLabel", toolbar)
    searchIcon:SetPos(365, 12)
    searchIcon:SetSize(40, 45)
    searchIcon:SetText("S")
    searchIcon:SetFont("DermaDefault")
    searchIcon:SetTextColor(theme.textMuted)
    
    self.searchEntry = searchEntry
    
    -- Sort Dropdown
    local sortCombo = vgui.Create("DComboBox", toolbar)
    sortCombo:SetSize(250, 45)
    sortCombo:SetPos(420, 12)
    sortCombo:SetValue("Sortieren nach...")
    sortCombo:AddChoice("Name (A-Z)", "name_asc")
    sortCombo:AddChoice("Name (Z-A)", "name_desc")
    sortCombo:AddChoice("Preis (niedrig)", "price_asc")
    sortCombo:AddChoice("Preis (hoch)", "price_desc")
    sortCombo:AddChoice("Kaufdatum (neu)", "date_desc")
    sortCombo:AddChoice("Kaufdatum (alt)", "date_asc")
    
    sortCombo.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.glass)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    
    self.sortCombo = sortCombo
    
    -- Count Label
    local countLabel = vgui.Create("DLabel", toolbar)
    countLabel:SetPos(700, 12)
    countLabel:SetSize(200, 45)
    countLabel:SetText("0 Fahrzeuge")
    countLabel:SetFont("DermaDefaultBold")
    countLabel:SetTextColor(theme.textMuted)
    self.countLabel = countLabel
    
    -- Event Handler
    searchEntry.OnChange = function()
        self:RefreshInventory()
    end
    
    sortCombo.OnSelect = function(_, _, _, data)
        self.currentSort = data
        self:RefreshInventory()
    end
    
    self.currentSort = "name_asc"
    
    -- Grid Scroll
    self.vehicleGrid = vgui.Create("DScrollPanel", container)
    self.vehicleGrid:Dock(FILL)
    self.vehicleGrid:DockMargin(25, 20, 25, 25)
    
    local sbar = self.vehicleGrid:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, theme.primary)
    end
    
    self.gridContainer = vgui.Create("DPanel", self.vehicleGrid)
    self.gridContainer:SetSize(container:GetWide() - 70, 2000)
    self.gridContainer:SetPos(0, 0)
    self.gridContainer.Paint = function() end
    
    MyCarDealer.RequestSync()
    
    timer.Simple(0.5, function()
        if IsValid(self) then self:LoadInventory() end
    end)
end

function PANEL:GetSortedAndFilteredVehicles()
    local vehicles = {}
    
    if MyCarDealer.MyInventory then
        for _, v in ipairs(MyCarDealer.MyInventory) do
            table.insert(vehicles, table.Copy(v))
        end
    end
    
    -- Filter
    local searchText = self.searchEntry:GetValue():lower()
    if searchText and searchText ~= "" then
        local filtered = {}
        for _, v in ipairs(vehicles) do
            local match = false
            if v.name and v.name:lower():find(searchText, 1, true) then match = true end
            if v.category and v.category:lower():find(searchText, 1, true) then match = true end
            if v.price and tostring(v.price):find(searchText, 1, true) then match = true end
            
            if match then table.insert(filtered, v) end
        end
        vehicles = filtered
    end
    
    -- Sort
    local sortFunc = {
        name_asc = function(a, b) return (a.name or "") < (b.name or "") end,
        name_desc = function(a, b) return (a.name or "") > (b.name or "") end,
        price_asc = function(a, b) return (a.price or 0) < (b.price or 0) end,
        price_desc = function(a, b) return (a.price or 0) > (b.price or 0) end,
        date_desc = function(a, b) return (a.purchase_date or "") > (b.purchase_date or "") end,
        date_asc = function(a, b) return (a.purchase_date or "") < (b.purchase_date or "") end,
    }
    
    if sortFunc[self.currentSort] then
        table.sort(vehicles, sortFunc[self.currentSort])
    end
    
    return vehicles
end

function PANEL:RefreshInventory()
    self:LoadInventory()
end

function PANEL:LoadInventory()
    for _, child in pairs(self.gridContainer:GetChildren()) do
        child:Remove()
    end

    local vehicles = self:GetSortedAndFilteredVehicles()
    
    self.countLabel:SetText(#vehicles .. " Fahrzeuge")

    if #vehicles == 0 then
        local empty = vgui.Create("DPanel", self.gridContainer)
        empty:SetSize(500, 300)
        empty:SetPos(self.gridContainer:GetWide()/2 - 250, 200)
        empty.Paint = function(s, w, h)
            draw.SimpleText("KEINE FAHRZEUGE", "DermaLarge", w/2, h/2 - 30, MyCarDealer.Theme.textMuted, TEXT_ALIGN_CENTER)
            draw.SimpleText("Kaufe Fahrzeuge im Hauptmenue", "DermaDefault", w/2, h/2 + 20, MyCarDealer.Theme.textMuted, TEXT_ALIGN_CENTER)
        end
        return
    end

    local cardW = 380
    local cardH = 480
    local spacing = 30
    local cols = math.floor((self.gridContainer:GetWide()) / (cardW + spacing))
    cols = math.max(cols, 2)
    local startX = 20
    local startY = 20

    for i, vehicle in ipairs(vehicles) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local x = startX + col * (cardW + spacing)
        local y = startY + row * (cardH + spacing)
        
        self:CreateVehicleCard(vehicle, x, y, cardW, cardH, i)
    end

    local totalRows = math.ceil(#vehicles / cols)
    local newHeight = startY + (totalRows * (cardH + spacing)) + 50
    self.gridContainer:SetHeight(newHeight)
end

function PANEL:CreateVehicleCard(vehicle, x, y, w, h, cardIndex)
    local theme = MyCarDealer.Theme
    local card = vgui.Create("DPanel", self.gridContainer)
    card:SetSize(w, h)
    card:SetPos(x, y)
    card:SetAlpha(0)
    card:AlphaTo(255, 0.4, (cardIndex * 0.05))

    local canSpawn = true
    local jobText = ""
    local isPoliceVehicle = false
    local vehicleData = nil
    
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == vehicle.id then
            vehicleData = v
            break
        end
    end
    
    if vehicleData and vehicleData.job then
        isPoliceVehicle = true
        local jobTeam = _G[vehicleData.job]
        if jobTeam and LocalPlayer():Team() ~= jobTeam then
            canSpawn = false
            jobText = "JOB LOCKED"
        else
            jobText = "DIENSTFAHRZEUG"
        end
    end

    card.Paint = function(s, w, h)
        -- Card background with glass effect
        if isPoliceVehicle then
            draw.RoundedBox(20, 0, 0, w, h, Color(15, 25, 60, 240))
            surface.SetDrawColor(canSpawn and theme.secondary or theme.error)
        else
            draw.RoundedBox(20, 0, 0, w, h, theme.elevated)
            surface.SetDrawColor(canSpawn and theme.success or theme.error)
        end
        
        -- Left accent line
        surface.DrawRect(0, 20, 6, h - 40)

        -- Hover glow
        if s:IsHovered() then
            surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 30)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(theme.primary)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        -- Job badge
        if jobText ~= "" then
            local textCol = isPoliceVehicle and theme.secondary or theme.error
            draw.SimpleText(jobText, "DermaDefaultBold", w/2, h-35, textCol, TEXT_ALIGN_CENTER)
        end
    end

    -- Model Container
    local modelContainer = vgui.Create("DPanel", card)
    modelContainer:SetSize(w - 40, 220)
    modelContainer:SetPos(20, 20)
    modelContainer.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 100))
        
        -- Grid pattern
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 10)
        for i = 0, w, 20 do surface.DrawLine(i, 0, i, h) end
        for i = 0, h, 20 do surface.DrawLine(0, i, w, i) end
    end

    local model = vgui.Create("DModelPanel", modelContainer)
    model:Dock(FILL)
    model:DockMargin(15, 15, 15, 15)
    model:SetModel(vehicle.model)

    if model.Entity then
        local mn, mx = model.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
        model:SetFOV(45)
        model:SetCamPos(Vector(size, size, size))
        model:SetLookAt((mn + mx) * 0.5)
        
        if vehicle.tuning then
            if vehicle.tuning.lvs and vehicle.tuning.lvs.bodyColor then
                model.Entity:SetColor(vehicle.tuning.lvs.bodyColor)
            end
            if vehicle.tuning.lvs and vehicle.tuning.lvs.skin then
                model.Entity:SetSkin(vehicle.tuning.lvs.skin)
            end
        end
        
        model.Think = function(s)
            if IsValid(s.Entity) then
                s.Entity:SetAngles(Angle(0, (CurTime() * 20) % 360, 0))
            end
        end
    end

    -- Name Label
    local nameLabel = vgui.Create("DLabel", card)
    nameLabel:SetSize(w - 40, 35)
    nameLabel:SetPos(20, 250)
    nameLabel:SetText(vehicle.name)
    nameLabel:SetFont("DermaLarge")
    nameLabel:SetTextColor(theme.textPrimary)

    -- Date Label
    local dateLabel = vgui.Create("DLabel", card)
    dateLabel:SetSize(w - 40, 22)
    dateLabel:SetPos(20, 285)
    dateLabel:SetText("Gekauft: " .. (vehicle.purchase_date or "-"))
    dateLabel:SetFont("DermaDefault")
    dateLabel:SetTextColor(theme.textMuted)

    -- Tuning Info
    local yOffset = 315
    local tuningText = ""
    
    if vehicle.tuning then
        if vehicle.tuning.neon and vehicle.tuning.neon.enabled then
            tuningText = tuningText .. "[NEON] "
        end
        if vehicle.tuning.lvs and vehicle.tuning.lvs.skin and vehicle.tuning.lvs.skin > 0 then
            tuningText = tuningText .. "[SKIN " .. vehicle.tuning.lvs.skin .. "] "
        end
        if vehicle.tuning.lvs and vehicle.tuning.lvs.items then
            local items = vehicle.tuning.lvs.items
            if items.turbo then tuningText = tuningText .. "[TURBO] " end
            if items.compressor then tuningText = tuningText .. "[KOMPRESSOR] " end
        end
    end
    
    if tuningText ~= "" then
        local tuningLabel = vgui.Create("DLabel", card)
        tuningLabel:SetSize(w - 40, 20)
        tuningLabel:SetPos(20, yOffset)
        tuningLabel:SetText(tuningText)
        tuningLabel:SetFont("DermaDefault")
        tuningLabel:SetTextColor(theme.primary)
        yOffset = yOffset + 25
    end

    -- SPAWN Button (Main Action)
    local spawnBtn = vgui.Create("DButton", card)
    spawnBtn:SetSize(w - 40, 55)
    spawnBtn:SetPos(20, 360)
    spawnBtn:SetText("")
    spawnBtn:SetTooltip(canSpawn and "Spawnt das Fahrzeug" or "Falsche Job-Rolle!")
    
    spawnBtn.Paint = function(s, w, h)
        local col = canSpawn and (s:IsHovered() and Color(0, 240, 140) or Color(0, 200, 100)) or Color(80, 80, 80)
        
        draw.RoundedBox(14, 0, 0, w, h, col)
        
        -- Shine
        surface.SetDrawColor(255, 255, 255, s:IsHovered() and 25 or 15)
        surface.DrawRect(0, 0, w, h/2)
        
        -- Shadow
        surface.SetDrawColor(0, 0, 0, s:IsHovered() and 40 or 25)
        surface.DrawRect(0, h-4, w, 4)
        
        if s:IsHovered() and canSpawn then
            surface.SetDrawColor(0, 255, 180, 50)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        local text = canSpawn and "AUSPARKEN" or "GESPERRT"
        draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    spawnBtn.DoClick = function()
        if not canSpawn then
            surface.PlaySound("buttons/button10.wav")
            return
        end
        net.Start("MyCarDealer_Spawn")
        net.WriteString(vehicle.id)
        net.SendToServer()
        
        -- Cool exit animation
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end

    -- Action Buttons Row
    local btnY = 425
    local btnW = (w - 60) / 4
    local btnH = 45

    -- TUNING Button
    local tuneBtn = vgui.Create("DButton", card)
    tuneBtn:SetSize(btnW, btnH)
    tuneBtn:SetPos(20, btnY)
    tuneBtn:SetText("")
    tuneBtn:SetTooltip("Tuning-Menue oeffnen")
    
    tuneBtn.Paint = function(s, w, h)
        local baseCol = Color(60, 120, 200)
        local hoverCol = Color(80, 160, 240)
        local col = s:IsHovered() and hoverCol or baseCol
        
        draw.RoundedBox(10, 0, 0, w, h, col)
        
        draw.SimpleText("TUNING", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    tuneBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
            local tune = vgui.Create("MyCarDealer_Tuning")
            tune:SetVehicle(vehicle)
        end)
    end

    -- INSURANCE Button
    local insBtn = vgui.Create("DButton", card)
    insBtn:SetSize(btnW, btnH)
    insBtn:SetPos(30 + btnW, btnY)
    insBtn:SetText("")
    insBtn:SetTooltip("Versicherung verwalten")
    
    insBtn.Paint = function(s, w, h)
        local baseCol = Color(200, 180, 60)
        local hoverCol = Color(240, 220, 80)
        local col = s:IsHovered() and hoverCol or baseCol
        
        draw.RoundedBox(10, 0, 0, w, h, col)
        draw.SimpleText("VERSICHERUNG", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    insBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        MyCarDealer.OpenInsuranceBuy(vehicle)
    end

    -- SELL Button
    local sellBtn = vgui.Create("DButton", card)
    sellBtn:SetSize(btnW, btnH)
    sellBtn:SetPos(40 + btnW * 2, btnY)
    sellBtn:SetText("")
    sellBtn:SetTooltip("An Haendler verkaufen")
    
    sellBtn.Paint = function(s, w, h)
        local baseCol = Color(200, 100, 60)
        local hoverCol = Color(240, 120, 80)
        local col = s:IsHovered() and hoverCol or baseCol
        
        draw.RoundedBox(10, 0, 0, w, h, col)
        draw.SimpleText("VERKAUF", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    sellBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        local returnPrice = math.floor((vehicle.price or 0) * (MyCarDealer.Config.SellReturnPercent or 0.7))
        
        local confirm = vgui.Create("DFrame")
        confirm:SetSize(450, 200)
        confirm:Center()
        confirm:SetTitle("")
        confirm:ShowCloseButton(false)
        confirm:MakePopup()
        confirm.Paint = function(s, w, h)
            draw.RoundedBox(20, 0, 0, w, h, theme.surface)
            surface.SetDrawColor(theme.accent)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            
            draw.SimpleText("VERKAUF BESTAETIGEN", "DermaLarge", w/2, 40, theme.accent, TEXT_ALIGN_CENTER)
            draw.SimpleText("Rueckzahlung: $" .. string.Comma(returnPrice), "DermaDefault", w/2, 80, theme.textPrimary, TEXT_ALIGN_CENTER)
        end
        
        local yes = vgui.Create("DButton", confirm)
        yes:SetSize(170, 50)
        yes:SetPos(50, 120)
        yes:SetText("")
        yes.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.error or Color(180, 50, 50))
            draw.SimpleText("VERKAUFEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        yes.DoClick = function()
            net.Start("MyCarDealer_Sell")
            net.WriteString(vehicle.id)
            net.SendToServer()
            confirm:Remove()
            timer.Simple(0.3, function()
                if IsValid(self) then MyCarDealer.RequestSync() end
            end)
        end
        
        local no = vgui.Create("DButton", confirm)
        no:SetSize(170, 50)
        no:SetPos(230, 120)
        no:SetText("")
        no.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and theme.textMuted or Color(80, 80, 80))
            draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        no.DoClick = function() confirm:Remove() end
    end

    -- SELL TO PLAYER Button
    local sellPlayerBtn = vgui.Create("DButton", card)
    sellPlayerBtn:SetSize(btnW, btnH)
    sellPlayerBtn:SetPos(50 + btnW * 3, btnY)
    sellPlayerBtn:SetText("")
    sellPlayerBtn:SetTooltip("An Spieler verkaufen")
    
    sellPlayerBtn.Paint = function(s, w, h)
        local baseCol = Color(160, 80, 200)
        local hoverCol = Color(200, 100, 240)
        local col = s:IsHovered() and hoverCol or baseCol
        
        draw.RoundedBox(10, 0, 0, w, h, col)
        draw.SimpleText("AN SPIELER", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    sellPlayerBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
            local sellMenu = vgui.Create("MyCarDealer_SellToPlayer")
            sellMenu:SetVehicle(vehicle)
        end)
    end
end

vgui.Register("MyCarDealer_Inventory", PANEL, "DFrame")

function MyCarDealer.RequestSync()
    net.Start("MyCarDealer_Return")
    net.SendToServer()
end

net.Receive("MyCarDealer_SyncInventory", function()
    local data = net.ReadTable() or {}
    MyCarDealer.MyInventory = {}

    for _, item in ipairs(data) do
        for _, v in ipairs(MyCarDealer.Vehicles) do
            if v.id == item.vehicle_id then
                table.insert(MyCarDealer.MyInventory, {
                    id = item.vehicle_id,
                    name = v.name,
                    model = v.model,
                    price = v.price,
                    category = v.category,
                    purchase_date = item.purchase_date,
                    tuning = util.JSONToTable(item.tuning_data or "{}"),
                    job = v.job
                })
                break
            end
        end
    end

    for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
        if IsValid(v) and v:GetName() == "MyCarDealer_Inventory" then
            v:LoadInventory()
        end
    end
end)

print("[Dynora Motor´s] cl_inventory.lua loaded")
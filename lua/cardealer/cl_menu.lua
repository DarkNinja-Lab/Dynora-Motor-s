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
    
    -- Animated background
    self.Paint = function(s, w, h)
        -- Base dark
        surface.SetDrawColor(theme.background)
        surface.DrawRect(0, 0, w, h)
        
        -- Animated particles/grid
        local time = CurTime() * 0.3
        for i = 0, w, 80 do
            for j = 0, h, 80 do
                local dist = math.sqrt((i - w/2)^2 + (j - h/2)^2)
                local pulse = math.sin(time + dist * 0.01) * 0.5 + 0.5
                surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, pulse * 15)
                surface.DrawRect(i, j, 2, 2)
            end
        end
        
        -- Top gradient
        MyCarDealer.DrawGradient(0, 0, w, 5, theme.primary, theme.secondary, true)
        
        -- Header glow
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 30)
        surface.DrawRect(0, 0, w, 120)
    end
    
    -- Header
    local header = vgui.Create("DPanel", self)
    header:SetSize(self:GetWide(), 100)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        -- Glass effect
        surface.SetDrawColor(theme.elevated.r, theme.elevated.g, theme.elevated.b, 220)
        surface.DrawRect(0, 0, w, h)
        
        -- Logo text with glow
        draw.SimpleText("DYNORA", "DermaLarge", 40, 30, theme.primary, TEXT_ALIGN_LEFT)
        draw.SimpleText("MOTORS", "DermaDefaultBold", 160, 35, theme.secondary, TEXT_ALIGN_LEFT)
        
        -- Subtitle
        draw.SimpleText("PREMIUM FAHRZEUGMARKT", "DermaDefault", w/2, 60, theme.textMuted, TEXT_ALIGN_CENTER)
        
        -- Decorative line
        surface.SetDrawColor(theme.primary)
        surface.DrawRect(0, h-3, w, 3)
    end
    
    -- Close Button
    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(50, 50)
    closeBtn:SetPos(header:GetWide() - 80, 25)
    closeBtn:SetText("")
    
    closeBtn.Paint = function(s, w, h)
        local hovered = s:IsHovered()
        draw.RoundedBox(14, 0, 0, w, h, hovered and theme.error or Color(40, 40, 40))
        
        draw.SimpleText("×", "DermaLarge", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if hovered then
            surface.SetDrawColor(theme.error)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end
    
    closeBtn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:AlphaTo(0, 0.3, 0, function() self:Remove() end)
    end
    
    -- Sidebar
    local sidebar = vgui.Create("DPanel", self)
    sidebar:SetSize(300, self:GetTall() - 100)
    sidebar:SetPos(0, 100)
    sidebar.Paint = function(s, w, h)
        surface.SetDrawColor(theme.surface)
        surface.DrawRect(0, 0, w, h)
        
        -- Right border glow
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 100)
        surface.DrawRect(w-3, 0, 3, h)
    end

    -- Player Card
    local playerCard = vgui.Create("DPanel", sidebar)
    playerCard:SetSize(270, 120)
    playerCard:SetPos(15, 20)
    playerCard.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
        
        -- Avatar circle
        draw.RoundedBox(8, 15, 20, 60, 60, theme.glass)
        draw.SimpleText(string.sub(LocalPlayer():Nick(), 1, 1):upper(), "DermaLarge", 45, 50, theme.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Info
        draw.SimpleText(LocalPlayer():Nick(), "DermaDefaultBold", 90, 30, theme.textPrimary, TEXT_ALIGN_LEFT)
        draw.SimpleText("$" .. string.Comma(LocalPlayer():getDarkRPVar("money") or 0), "DermaDefault", 90, 55, theme.success, TEXT_ALIGN_LEFT)
        
        -- Decorative
        surface.SetDrawColor(theme.primary)
        surface.DrawRect(0, h-2, w, 2)
    end
    
    -- Categories Label
    local catLabel = vgui.Create("DLabel", sidebar)
    catLabel:SetPos(25, 160)
    catLabel:SetSize(250, 35)
    catLabel:SetText("KATEGORIEN")
    catLabel:SetFont("DermaDefaultBold")
    catLabel:SetTextColor(theme.textMuted)
    
    -- Category List
    local catList = vgui.Create("DScrollPanel", sidebar)
    catList:SetSize(270, 320)
    catList:SetPos(15, 200)
    
    local sbar = catList:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, theme.primary)
    end
    
    self.catButtons = {}
    local yOffset = 0
    
    for _, cat in ipairs(MyCarDealer.Categories) do
        if cat == "Polizei" then continue end
        
        local btn = vgui.Create("DButton", catList)
        btn:SetSize(270, 60)
        btn:SetPos(0, yOffset)
        btn:SetText("")
        yOffset = yOffset + 65
        
        local isSelected = false
        btn.Paint = function(s, w, h)
            local bgCol = isSelected and theme.primary or (s:IsHovered() and theme.surfaceHover or theme.glass)
            local alpha = isSelected and 100 or 30
            
            draw.RoundedBox(12, 0, 0, w, h, Color(bgCol.r, bgCol.g, bgCol.b, alpha))
            
            if isSelected then
                -- Glow effect
                surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 50)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                surface.SetDrawColor(theme.primary)
                surface.DrawRect(0, 0, 4, h)
            end
            
            draw.SimpleText(cat, "DermaDefaultBold", 20, h/2, isSelected and theme.textPrimary or theme.textSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Count
            local count = 0
            for _, v in ipairs(MyCarDealer.Vehicles) do
                if v.category == cat then count = count + 1 end
            end
            draw.SimpleText(count, "DermaDefault", w-20, h/2, theme.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        btn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            for _, b in pairs(self.catButtons) do b.isSelected = false end
            isSelected = true
            self:LoadCategory(cat)
        end
        
        btn.isSelected = false
        table.insert(self.catButtons, btn)
    end
    
    -- Bottom Buttons
    local btnY = sidebar:GetTall() - 140
    
    -- Garage Button
    local garageBtn = vgui.Create("DButton", sidebar)
    garageBtn:SetSize(270, 55)
    garageBtn:SetPos(15, btnY)
    garageBtn:SetText("")
    garageBtn:SetTooltip("Deine persönliche Garage")
    
    garageBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and theme.secondary or Color(0, 150, 200)
        draw.RoundedBox(12, 0, 0, w, h, col)
        
        if s:IsHovered() then
            surface.SetDrawColor(theme.secondaryLight)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        draw.SimpleText("[ GARAGE ]", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    garageBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
            vgui.Create("MyCarDealer_Inventory")
        end)
    end
    
    -- Police Button (if applicable)
    if LocalPlayer():Team() == TEAM_POLICE then
        local policeBtn = vgui.Create("DButton", sidebar)
        policeBtn:SetSize(270, 55)
        policeBtn:SetPos(15, btnY + 60)
        policeBtn:SetText("")
        policeBtn:SetTooltip("Polizei-Dienstfahrzeuge")
        
        policeBtn.Paint = function(s, w, h)
            local col = s:IsHovered() and theme.accent or theme.accentDark
            draw.RoundedBox(12, 0, 0, w, h, col)
            
            if s:IsHovered() then
                surface.SetDrawColor(theme.accentLight)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            
            draw.SimpleText("[ POLIZEI ]", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        policeBtn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            self:AlphaTo(0, 0.2, 0, function()
                self:Remove()
                vgui.Create("MyCarDealer_PoliceMenu")
            end)
        end
    end
    
    -- Main Panel
    self.mainPanel = vgui.Create("DPanel", self)
    self.mainPanel:SetSize(self:GetWide() - 340, self:GetTall() - 120)
    self.mainPanel:SetPos(320, 110)
    self.mainPanel.Paint = function(s, w, h)
        draw.RoundedBox(20, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    
    -- Vehicle Grid
    self.vehicleGrid = vgui.Create("DScrollPanel", self.mainPanel)
    self.vehicleGrid:Dock(FILL)
    self.vehicleGrid:DockMargin(25, 25, 25, 25)
    
    local gridSbar = self.vehicleGrid:GetVBar()
    gridSbar:SetWide(8)
    gridSbar.Paint = function() end
    gridSbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, theme.primary)
    end
    
    self.gridContainer = vgui.Create("DPanel", self.vehicleGrid)
    self.gridContainer:SetSize(self.mainPanel:GetWide() - 60, 2000)
    self.gridContainer:SetPos(0, 0)
    self.gridContainer.Paint = function() end
    
    -- Load first category
    if self.catButtons[1] then
        self.catButtons[1].isSelected = true
        self:LoadCategory(MyCarDealer.Categories[1])
    end
end

function PANEL:LoadCategory(category)
    for _, child in pairs(self.gridContainer:GetChildren()) do
        child:Remove()
    end
    
    local vehicles = {}
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.category == category and v.job ~= "TEAM_POLICE" then
            table.insert(vehicles, v)
        end
    end
    
    local cardW = 340
    local cardH = 450
    local spacing = 25
    local cols = math.floor((self.mainPanel:GetWide() - 50) / (cardW + spacing))
    cols = math.max(cols, 2)
    
    local startX = 15
    local startY = 15
    
    for i, vehicle in ipairs(vehicles) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local x = startX + col * (cardW + spacing)
        local y = startY + row * (cardH + spacing)
        
        self:CreateVehicleCard(vehicle, x, y, cardW, cardH)
    end
    
    local totalRows = math.ceil(#vehicles / cols)
    local newHeight = startY + (totalRows * (cardH + spacing)) + 50
    self.gridContainer:SetHeight(newHeight)
end

function PANEL:CreateVehicleCard(vehicle, x, y, w, h)
    local theme = MyCarDealer.Theme
    local card = vgui.Create("DPanel", self.gridContainer)
    card:SetSize(w, h)
    card:SetPos(x, y)
    card:SetAlpha(0)
    card:AlphaTo(255, 0.4, (x + y) / 2000)
    
    local canBuy = true
    local jobText = ""
    if vehicle.job then
        local jobTeam = _G[vehicle.job]
        if jobTeam and LocalPlayer():Team() ~= jobTeam then
            canBuy = false
            jobText = "JOB REQUIRED"
        end
    end
    
    local isFavorite = MyCarDealer.IsFavorite(vehicle.id)
    
    card.Paint = function(s, w, h)
        -- Background
        draw.RoundedBox(20, 0, 0, w, h, theme.elevated)
        
        -- Hover effect
        if s:IsHovered() then
            surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 40)
            surface.DrawOutlinedRect(0, 0, w, h, 3)
        end
        
        -- Top line with vehicle color
        local lineCol = canBuy and vehicle.previewColor or theme.error
        surface.SetDrawColor(lineCol)
        surface.DrawRect(30, 0, w-60, 4)
        
        -- Favorite star
        if isFavorite then
            draw.SimpleText("★", "DermaDefaultBold", w-40, 25, theme.accent, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Model Panel
    local modelPanel = vgui.Create("DPanel", card)
    modelPanel:SetSize(w - 40, 220)
    modelPanel:SetPos(20, 20)
    modelPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, Color(0, 0, 0, 100))
        
        -- Grid pattern
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 8)
        for i = 0, w, 25 do surface.DrawLine(i, 0, i, h) end
        for i = 0, h, 25 do surface.DrawLine(0, i, w, i) end
    end
    
    local model = vgui.Create("DModelPanel", modelPanel)
    model:Dock(FILL)
    model:DockMargin(15, 15, 15, 15)
    model:SetModel(vehicle.model)
    
    if model.Entity then
        local mn, mx = model.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), 
                             math.abs(mn.y) + math.abs(mx.y), 
                             math.abs(mn.z) + math.abs(mx.z))
        model:SetFOV(45)
        model:SetCamPos(Vector(size, size, size) * 0.6)
        model:SetLookAt((mn + mx) * 0.5)
        
        model.Think = function(s)
            if IsValid(s.Entity) then
                s.Entity:SetAngles(Angle(0, (CurTime() * 15) % 360, 0))
            end
        end
    end
    
    -- Name
    local nameLabel = vgui.Create("DLabel", card)
    nameLabel:SetSize(w - 40, 35)
    nameLabel:SetPos(20, 250)
    nameLabel:SetText(vehicle.name)
    nameLabel:SetFont("DermaLarge")
    nameLabel:SetTextColor(theme.textPrimary)
    
    -- Price
    local priceLabel = vgui.Create("DLabel", card)
    priceLabel:SetSize(w - 40, 30)
    priceLabel:SetPos(20, 285)
    priceLabel:SetText("$" .. string.Comma(vehicle.price))
    priceLabel:SetFont("DermaDefaultBold")
    priceLabel:SetTextColor(canBuy and theme.success or theme.error)
    
    -- Description
    local descLabel = vgui.Create("DLabel", card)
    descLabel:SetSize(w - 40, 50)
    descLabel:SetPos(20, 320)
    descLabel:SetText(vehicle.description or "")
    descLabel:SetFont("DermaDefault")
    descLabel:SetTextColor(theme.textSecondary)
    descLabel:SetWrap(true)
    
    -- Stats
    draw.SimpleText("MAX " .. vehicle.maxSpeed .. " KM/H", "DermaDefault", 20, 375, theme.textMuted, TEXT_ALIGN_LEFT)
    
    if canBuy then
        -- Test Drive Button
        local testBtn = vgui.Create("DButton", card)
        testBtn:SetSize(140, 45)
        testBtn:SetPos(20, h - 70)
        testBtn:SetText("")
        testBtn:SetTooltip("Testfahrt starten")
        
        testBtn.Paint = function(s, w, h)
            local col = s:IsHovered() and theme.secondary or Color(0, 150, 200)
            draw.RoundedBox(12, 0, 0, w, h, col)
            draw.SimpleText("TESTFAHRT", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        testBtn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            MyCarDealer.StartTestDrive(vehicle.id)
            self:Remove()
        end
        
        -- Buy Button
        local buyBtn = vgui.Create("DButton", card)
        buyBtn:SetSize(140, 45)
        buyBtn:SetPos(w - 160, h - 70)
        buyBtn:SetText("")
        buyBtn:SetTooltip("Fahrzeug kaufen")
        
        buyBtn.Paint = function(s, w, h)
            local col = s:IsHovered() and theme.primary or theme.primaryDark
            draw.RoundedBox(12, 0, 0, w, h, col)
            
            if s:IsHovered() then
                surface.SetDrawColor(theme.primaryLight)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            
            draw.SimpleText("KAUFEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        buyBtn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            self:ShowBuyConfirmation(vehicle)
        end
    else
        -- Locked
        local lockedLabel = vgui.Create("DLabel", card)
        lockedLabel:SetSize(w - 40, 45)
        lockedLabel:SetPos(20, h - 70)
        lockedLabel:SetText("[ " .. jobText .. " ]")
        lockedLabel:SetFont("DermaDefaultBold")
        lockedLabel:SetTextColor(theme.error)
        lockedLabel:SetContentAlignment(5)
    end
    
    -- Favorite Button
    local favBtn = vgui.Create("DButton", card)
    favBtn:SetSize(40, 40)
    favBtn:SetPos(w - 60, 20)
    favBtn:SetText("")
    favBtn:SetTooltip(isFavorite and "Aus Favoriten entfernen" or "Zu Favoriten hinzufügen")
    
    favBtn.Paint = function(s, w, h)
        local col = isFavorite and theme.accent or theme.textMuted
        draw.SimpleText(isFavorite and "★" or "☆", "DermaLarge", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    favBtn.DoClick = function()
        isFavorite = not isFavorite
        MyCarDealer.ToggleFavorite(vehicle.id)
        favBtn:SetTooltip(isFavorite and "Aus Favoriten entfernen" or "Zu Favoriten hinzufügen")
        surface.PlaySound("ui/buttonclick.wav")
    end
end

function PANEL:ShowBuyConfirmation(vehicle)
    local theme = MyCarDealer.Theme
    
    local confirm = vgui.Create("DFrame")
    confirm:SetSize(500, 280)
    confirm:Center()
    confirm:SetTitle("")
    confirm:ShowCloseButton(false)
    confirm:MakePopup()
    confirm:SetAlpha(0)
    confirm:AlphaTo(255, 0.3, 0)
    
    confirm.Paint = function(s, w, h)
        draw.RoundedBox(20, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Header
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 0, w, 70)
        draw.SimpleText("KAUF BESTÄTIGEN", "DermaLarge", w/2, 35, theme.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local text = vgui.Create("DLabel", confirm)
    text:SetSize(460, 100)
    text:SetPos(20, 90)
    text:SetText(vehicle.name .. "\n\nPreis: $" .. string.Comma(vehicle.price) .. "\nDein Guthaben: $" .. string.Comma(LocalPlayer():getDarkRPVar("money") or 0))
    text:SetFont("DermaDefault")
    text:SetTextColor(theme.textPrimary)
    text:SetContentAlignment(5)
    
    local yes = vgui.Create("DButton", confirm)
    yes:SetSize(200, 55)
    yes:SetPos(40, 200)
    yes:SetText("")
    yes.Paint = function(s, w, h)
        draw.RoundedBox(14, 0, 0, w, h, s:IsHovered() and theme.success or Color(0, 200, 100))
        draw.SimpleText("BESTÄTIGEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    yes.DoClick = function()
        net.Start("MyCarDealer_Buy")
        net.WriteString(vehicle.id)
        net.SendToServer()
        confirm:Remove()
    end
    
    local no = vgui.Create("DButton", confirm)
    no:SetSize(200, 55)
    no:SetPos(260, 200)
    no:SetText("")
    no.Paint = function(s, w, h)
        draw.RoundedBox(14, 0, 0, w, h, s:IsHovered() and theme.error or Color(150, 50, 50))
        draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    no.DoClick = function()
        confirm:Remove()
    end
end

vgui.Register("MyCarDealer_Menu", PANEL, "DFrame")

function MyCarDealer.IsAdmin(ply)
    if not IsValid(ply) then return false end
    local userGroup = ply:GetUserGroup()
    return userGroup == "admin" or userGroup == "superadmin" or userGroup == "owner" or userGroup == "developer"
end

function MyCarDealer.IsFavorite(vehicleID)
    local favorites = util.JSONToTable(cookie.GetString("CD_Favorites", "[]") or "[]")
    return table.HasValue(favorites, vehicleID)
end

function MyCarDealer.ToggleFavorite(vehicleID)
    local favorites = util.JSONToTable(cookie.GetString("CD_Favorites", "[]") or "[]")
    local idx = table.KeyFromValue(favorites, vehicleID)
    
    if idx then
        table.remove(favorites, idx)
    else
        table.insert(favorites, vehicleID)
    end
    
    cookie.Set("CD_Favorites", util.TableToJSON(favorites))
end

function MyCarDealer.AddToRecentPurchases(ply, vehicleID)
end

function MyCarDealer.StartTestDrive(vehicleID)
    net.Start("MyCarDealer_StartTestDrive")
    net.WriteString(vehicleID)
    net.SendToServer()
end

concommand.Add("cardealer_open", function()
    if IsValid(MyCarDealer_Menu) then
        MyCarDealer_Menu:Remove()
    end
    MyCarDealer_Menu = vgui.Create("MyCarDealer_Menu")
end)

net.Receive("MyCarDealer_OpenAdminMenu", function()
    vgui.Create("MyCarDealer_Admin")
end)

print("[Dynora Motor´s] cl_menu.lua loaded (Beautiful UI v4.0)")
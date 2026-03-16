local PANEL = {}

local COLORS = {
    bg = Color(15, 10, 25, 245),
    glass = Color(255, 255, 255, 8),
    glassHover = Color(255, 255, 255, 15),
    glassStrong = Color(255, 255, 255, 25),
    
    accent1 = Color(200, 100, 255),
    accent2 = Color(255, 100, 200),
    money = Color(255, 215, 0),
    moneyDark = Color(200, 170, 0),
    
    text = Color(255, 255, 255),
    textDim = Color(180, 170, 200),
    textDark = Color(120, 110, 140),
    
    success = Color(100, 255, 150),
    error = Color(255, 100, 100),
}

function PANEL:Init()
    local frameW = 700
    local frameH = 600
    
    self:SetSize(frameW, frameH)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.4, 0)
    
    self.vehicle = nil
    self.selectedPlayer = nil
    self.playerButtons = {}

    self.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.bg)
        surface.DrawRect(0, 0, w, h)
        
        local time = CurTime() * 0.5
        for i = 0, h, 2 do
            local wave = math.sin((i / h) * math.pi * 2 + time) * 0.5 + 0.5
            local alpha = wave * 15
            surface.SetDrawColor(100, 50, 150, alpha)
            surface.DrawRect(0, i, w, 2)
        end
        
        surface.SetDrawColor(COLORS.money.r, COLORS.money.g, COLORS.money.b, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(COLORS.money)
        surface.DrawRect(0, 0, w, 3)
        
        local cornerSize = 20
        surface.SetDrawColor(COLORS.accent1)
        surface.DrawRect(0, 0, cornerSize, 3)
        surface.DrawRect(0, 0, 3, cornerSize)
        surface.DrawRect(w - cornerSize, 0, cornerSize, 3)
        surface.DrawRect(w - 3, 0, 3, cornerSize)
        surface.DrawRect(0, h - 3, cornerSize, 3)
        surface.DrawRect(0, h - cornerSize, 3, cornerSize)
        surface.DrawRect(w - cornerSize, h - 3, cornerSize, 3)
        surface.DrawRect(w - 3, h - cornerSize, 3, cornerSize)
    end


    local header = vgui.Create("DPanel", self)
    header:SetSize(frameW, 90)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.glassStrong)
        surface.DrawRect(0, 0, w, h)
        
        for i = 0, w do
            local progress = i / w
            local r = Lerp(progress, COLORS.money.r, COLORS.accent1.r)
            local g = Lerp(progress, COLORS.money.g, COLORS.accent1.g)
            local b = Lerp(progress, COLORS.money.b, COLORS.accent1.b)
            surface.SetDrawColor(r, g, b, 30)
            surface.DrawRect(i, h-2, 1, 2)
        end
        

        draw.SimpleText("€", "DermaLarge", 30, 25, COLORS.money, TEXT_ALIGN_LEFT)
        draw.SimpleText("FAHRZEUG VERKAUFEN", "DermaLarge", 60, 20, COLORS.text, TEXT_ALIGN_LEFT)
        draw.SimpleText("Wähle einen Player und setze den Preis", "DermaDefault", 60, 50, COLORS.textDim, TEXT_ALIGN_LEFT)
    end

  
    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetSize(45, 45)
    closeBtn:SetPos(frameW - 55, 22)
    closeBtn:SetText("X")
    closeBtn:SetFont("DermaLarge")
    closeBtn:SetTextColor(COLORS.text)
    
    local closeHover = 0
    closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then
            closeHover = math.min(closeHover + FrameTime() * 10, 1)
        else
            closeHover = math.max(closeHover - FrameTime() * 10, 0)
        end
        
        local col = Color(
            Lerp(closeHover, COLORS.glass.r, COLORS.error.r),
            Lerp(closeHover, COLORS.glass.g, COLORS.error.g),
            Lerp(closeHover, COLORS.glass.b, COLORS.error.b),
            Lerp(closeHover, 50, 200)
        )
        
        draw.RoundedBox(12, 0, 0, w, h, col)
        
        if closeHover > 0 then
            surface.SetDrawColor(COLORS.error.r, COLORS.error.g, COLORS.error.b, closeHover * 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end
    
    closeBtn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:CloseAnimation()
    end


    local infoCard = vgui.Create("DPanel", self)
    infoCard:SetSize(660, 130)
    infoCard:SetPos(20, 105)
    infoCard.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, COLORS.glass)
        surface.SetDrawColor(COLORS.money.r, COLORS.money.g, COLORS.money.b, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(COLORS.money)
        surface.DrawRect(0, 15, 4, h - 30)
    end


    self.modelPanel = vgui.Create("DModelPanel", infoCard)
    self.modelPanel:SetSize(150, 110)
    self.modelPanel:SetPos(15, 10)
    self.modelPanel:SetFOV(45)
    
    self.modelPanel.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 100))
        surface.SetDrawColor(COLORS.money)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        DModelPanel.Paint(s, w, h)
    end

    
    self.infoName = vgui.Create("DLabel", infoCard)
    self.infoName:SetSize(470, 35)
    self.infoName:SetPos(180, 15)
    self.infoName:SetFont("DermaLarge")
    self.infoName:SetTextColor(COLORS.text)

    self.infoValue = vgui.Create("DLabel", infoCard)
    self.infoValue:SetSize(470, 25)
    self.infoValue:SetPos(180, 50)
    self.infoValue:SetFont("DermaDefaultBold")
    self.infoValue:SetTextColor(COLORS.money)

    self.infoMarket = vgui.Create("DLabel", infoCard)
    self.infoMarket:SetSize(470, 20)
    self.infoMarket:SetPos(180, 80)
    self.infoMarket:SetFont("DermaDefault")
    self.infoMarket:SetTextColor(COLORS.textDim)
    
    self.infoTuning = vgui.Create("DLabel", infoCard)
    self.infoTuning:SetSize(470, 20)
    self.infoTuning:SetPos(180, 105)
    self.infoTuning:SetFont("DermaDefault")
    self.infoTuning:SetTextColor(COLORS.accent1)


    local playerSection = vgui.Create("DPanel", self)
    playerSection:SetSize(660, 45)
    playerSection:SetPos(20, 245)
    playerSection.Paint = function(s, w, h)

        draw.SimpleText("[ SPIELER AUSWAEHLEN ]", "DermaDefaultBold", 0, h/2, COLORS.accent1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(COLORS.accent1)
        surface.DrawRect(0, h-2, 220, 2)
    end


    local playerList = vgui.Create("DScrollPanel", self)
    playerList:SetSize(660, 160)
    playerList:SetPos(20, 300)
    
    local sbar = playerList:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, COLORS.accent1)
    end

    self.playerContainer = vgui.Create("DPanel", playerList)
    self.playerContainer:Dock(FILL)
    self.playerContainer.Paint = function() end


    local priceSection = vgui.Create("DPanel", self)
    priceSection:SetSize(660, 45)
    priceSection:SetPos(20, 470)
    priceSection.Paint = function(s, w, h)

        draw.SimpleText("[ VERKAUFSPREIS ]", "DermaDefaultBold", 0, h/2, COLORS.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(COLORS.money)
        surface.DrawRect(0, h-2, 180, 2)
    end


    local priceContainer = vgui.Create("DPanel", self)
    priceContainer:SetSize(300, 50)
    priceContainer:SetPos(20, 525)
    priceContainer.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.glassStrong)
        surface.SetDrawColor(COLORS.money)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("$", "DermaLarge", 15, h/2, COLORS.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.priceEntry = vgui.Create("DTextEntry", priceContainer)
    self.priceEntry:SetSize(250, 40)
    self.priceEntry:SetPos(45, 5)
    self.priceEntry:SetFont("DermaLarge")
    self.priceEntry:SetTextColor(COLORS.text)
    self.priceEntry:SetNumeric(true)
    self.priceEntry:SetDrawBackground(false)
    self.priceEntry:SetPlaceholderText("0")
    self.priceEntry:SetPlaceholderColor(COLORS.textDark)


    self.sellBtn = vgui.Create("DButton", self)
    self.sellBtn:SetSize(340, 50)
    self.sellBtn:SetPos(340, 525)
    self.sellBtn:SetText("")
    
    local btnHover = 0
    self.sellBtn.Paint = function(s, w, h)
        local canSell = self.selectedPlayer ~= nil and self.priceEntry:GetValue() ~= ""
        
        if s:IsHovered() and canSell then
            btnHover = math.min(btnHover + FrameTime() * 15, 1)
        else
            btnHover = math.max(btnHover - FrameTime() * 15, 0)
        end
        
        for i = 0, w do
            local progress = i / w
            local baseCol = canSell and COLORS.money or Color(100, 100, 100)
            local hoverCol = canSell and Color(255, 235, 100) or Color(120, 120, 120)
            
            local r = Lerp(btnHover, baseCol.r, hoverCol.r)
            local g = Lerp(btnHover, baseCol.g, hoverCol.g)
            local b = Lerp(btnHover, baseCol.b, hoverCol.b)
            
            surface.SetDrawColor(r, g, b, canSell and 255 or 150)
            surface.DrawRect(i, 0, 1, h)
        end
        
        draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,0))
        
        if btnHover > 0 then
            surface.SetDrawColor(255, 215, 0, btnHover * 50)
            surface.DrawRect(-2, -2, w+4, h+4)
        end
        
        surface.SetDrawColor(canSell and COLORS.money or Color(150, 150, 150))
        surface.DrawOutlinedRect(0, 0, w, h, canSell and 2 or 1)
        
        local text = canSell and "ANGEBOT SENDEN >>" or "WAEHLE SPIELER & PREIS"
        draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    self.sellBtn.DoClick = function()
        self:AttemptSell()
    end

    self:LoadPlayers()
end

function PANEL:SetVehicle(vehicle)
    self.vehicle = vehicle
    
    self.infoName:SetText(vehicle.name or "Unbekannt")
    self.infoValue:SetText("Marktwert: $" .. string.Comma(vehicle.price or 0))
    
    local suggested = math.floor((vehicle.price or 0) * 0.8)
    self.infoMarket:SetText("Empfohlener Preis: $" .. string.Comma(suggested))
    
    local tuningText = ""
    if vehicle.tuning then
        if vehicle.tuning.neon and vehicle.tuning.neon.enabled then
            tuningText = tuningText .. "[NEON] "
        end
        if vehicle.tuning.lvs and vehicle.tuning.lvs.skin and vehicle.tuning.lvs.skin > 0 then
            tuningText = tuningText .. "[SKIN " .. vehicle.tuning.lvs.skin .. "] "
        end
        if vehicle.tuning.lvs and vehicle.tuning.lvs.bodyColor then
            tuningText = tuningText .. "[CUSTOM COLOR]"
        end
    end
    self.infoTuning:SetText(tuningText ~= "" and "Tuning: " .. tuningText or "Kein Tuning")
    
    self.priceEntry:SetText(tostring(suggested))
    
    if vehicle.model and util.IsValidModel(vehicle.model) then
        self.modelPanel:SetModel(vehicle.model)
        
        local mn, mx = self.modelPanel.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), 
                             math.abs(mn.y) + math.abs(mx.y), 
                             math.abs(mn.z) + math.abs(mx.z))
        
        self.modelPanel:SetCamPos(Vector(size, size, size) * 0.7)
        self.modelPanel:SetLookAt((mn + mx) * 0.5)
        
        if vehicle.tuning then
            if vehicle.tuning.lvs and vehicle.tuning.lvs.bodyColor then
                self.modelPanel.Entity:SetColor(vehicle.tuning.lvs.bodyColor)
            end
            if vehicle.tuning.lvs and vehicle.tuning.lvs.skin then
                self.modelPanel.Entity:SetSkin(vehicle.tuning.lvs.skin)
            end
        end
        
        self.modelPanel.Think = function(s)
            if IsValid(s.Entity) then
                s.Entity:SetAngles(Angle(0, (CurTime() * 20) % 360, 0))
            end
        end
    else
        self.modelPanel:SetModel("models/error.mdl")
    end
end

function PANEL:LoadPlayers()
    for _, btn in pairs(self.playerButtons) do
        if IsValid(btn) then btn:Remove() end
    end
    self.playerButtons = {}

    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply ~= LocalPlayer() then
            table.insert(players, ply)
        end
    end

    if #players == 0 then
        local noPlayers = vgui.Create("DLabel", self.playerContainer)
        noPlayers:Dock(TOP)
        noPlayers:SetHeight(60)
        noPlayers:SetText(">> Keine anderen Spieler online <<")
        noPlayers:SetFont("DermaDefaultBold")
        noPlayers:SetTextColor(COLORS.error)
        noPlayers:SetContentAlignment(5)
        return
    end

    for _, ply in ipairs(players) do
        local btn = vgui.Create("DButton", self.playerContainer)
        btn:Dock(TOP)
        btn:SetHeight(60)
        btn:DockMargin(0, 0, 10, 8)
        btn:SetText("")
        
        local isSelected = false
        local hoverAnim = 0
        
        btn.Paint = function(s, w, h)
            if s:IsHovered() or isSelected then
                hoverAnim = math.min(hoverAnim + FrameTime() * 10, 1)
            else
                hoverAnim = math.max(hoverAnim - FrameTime() * 10, 0)
            end
            
            local baseCol = isSelected and Color(COLORS.accent1.r, COLORS.accent1.g, COLORS.accent1.b, 80) or COLORS.glass
            local targetCol = isSelected and Color(COLORS.accent1.r, COLORS.accent1.g, COLORS.accent1.b, 120) or COLORS.glassHover
            
            local col = Color(
                Lerp(hoverAnim, baseCol.r, targetCol.r),
                Lerp(hoverAnim, baseCol.g, targetCol.g),
                Lerp(hoverAnim, baseCol.b, targetCol.b),
                Lerp(hoverAnim, baseCol.a, targetCol.a)
            )
            
            draw.RoundedBox(12, 0, 0, w, h, col)
            
            if isSelected then
                surface.SetDrawColor(COLORS.success)
                surface.DrawRect(0, 0, 4, h)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                draw.SimpleText(">>", "DermaLarge", w-25, h/2, COLORS.success, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            else
                surface.SetDrawColor(COLORS.textDim)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            

            draw.RoundedBox(10, 10, 10, 40, 40, Color(50, 45, 70))
            local name = ply:Nick()
            local initial = string.sub(name, 1, 1):upper()
            draw.SimpleText(initial, "DermaLarge", 30, 30, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            draw.SimpleText(ply:Nick(), "DermaDefaultBold", 65, 15, COLORS.text, TEXT_ALIGN_LEFT)
            
            local teamName = team.GetName(ply:Team()) or "Unknown"
            draw.SimpleText(teamName, "DermaDefault", 65, 38, COLORS.textDim, TEXT_ALIGN_LEFT)
            
            local money = ply:getDarkRPVar("money") or 0
            draw.SimpleText("$" .. string.Comma(money), "DermaDefault", w-15, h/2, COLORS.money, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        btn.DoClick = function()
            for _, b in pairs(self.playerButtons) do
                b.isSelected = false
            end
            isSelected = true
            self.selectedPlayer = ply
            
            surface.PlaySound("ui/buttonclick.wav")
        end
        
        btn.isSelected = false
        table.insert(self.playerButtons, btn)
    end
end

function PANEL:AttemptSell()
    if not self.selectedPlayer then
        self:ShowNotification("Wähle einen Player aus!", "error")
        surface.PlaySound("buttons/button10.wav")
        return
    end
    
    local price = tonumber(self.priceEntry:GetValue())
    if not price or price <= 0 then
        self:ShowNotification("Gib einen gültigen Preis ein!", "error")
        surface.PlaySound("buttons/button10.wav")
        return
    end
    
    if not self.vehicle then return end
    
    local confirm = vgui.Create("DFrame")
    confirm:SetSize(400, 200)
    confirm:Center()
    confirm:SetTitle("")
    confirm:ShowCloseButton(false)
    confirm:MakePopup()
    confirm:SetAlpha(0)
    confirm:AlphaTo(255, 0.2, 0)
    
    confirm.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, COLORS.bg)
        surface.SetDrawColor(COLORS.money)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        surface.SetDrawColor(COLORS.glassStrong)
        surface.DrawRect(0, 0, w, 50)
        draw.SimpleText("VERKAUF BESTAETIGEN", "DermaLarge", w/2, 25, COLORS.money, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local info = vgui.Create("DLabel", confirm)
    info:SetSize(360, 80)
    info:SetPos(20, 60)
    info:SetText("Fahrzeug: " .. self.vehicle.name .. "\nKäufer: " .. self.selectedPlayer:Nick() .. "\nPreis: $" .. string.Comma(price))
    info:SetFont("DermaDefault")
    info:SetTextColor(COLORS.text)
    
    local yesBtn = vgui.Create("DButton", confirm)
    yesBtn:SetSize(170, 45)
    yesBtn:SetPos(20, 140)
    yesBtn:SetText("[ JA, SENDEN ]")
    yesBtn:SetFont("DermaDefaultBold")
    yesBtn:SetTextColor(COLORS.text)
    yesBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.success or Color(0, 200, 100))
    end
    yesBtn.DoClick = function()
        net.Start("MyCarDealer_SellToPlayer")
        net.WriteString(self.vehicle.id)
        net.WriteEntity(self.selectedPlayer)
        net.WriteInt(price, 32)
        net.SendToServer()
        
        confirm:Remove()
        self:CloseAnimation()
        
        surface.PlaySound("ambient/levels/labs/coinslot1.wav")
    end
    
    local noBtn = vgui.Create("DButton", confirm)
    noBtn:SetSize(170, 45)
    noBtn:SetPos(210, 140)
    noBtn:SetText("[ ABBRECHEN ]")
    noBtn:SetFont("DermaDefaultBold")
    noBtn:SetTextColor(COLORS.text)
    noBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.error or Color(150, 50, 50))
    end
    noBtn.DoClick = function()
        confirm:Remove()
    end
end

function PANEL:ShowNotification(text, type)
    local notif = vgui.Create("DFrame")
    notif:SetSize(350, 80)
    notif:Center()
    notif:SetTitle("")
    notif:ShowCloseButton(false)
    notif:MakePopup()
    notif:SetAlpha(0)
    
    local col = type == "success" and COLORS.success or COLORS.error
    local symbol = type == "success" and ">>" or "!!"
    
    notif.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.glassStrong)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText(symbol, "DermaLarge", 30, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "DermaDefaultBold", 60, h/2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    notif:AlphaTo(255, 0.2, 0, function()
        timer.Simple(2, function()
            if IsValid(notif) then
                notif:AlphaTo(0, 0.3, 0, function() notif:Remove() end)
            end
        end)
    end)
end

function PANEL:CloseAnimation()
    self:AlphaTo(0, 0.3, 0, function()
        self:Remove()
        vgui.Create("MyCarDealer_Inventory")
    end)
end

vgui.Register("MyCarDealer_SellToPlayer", PANEL, "DFrame")
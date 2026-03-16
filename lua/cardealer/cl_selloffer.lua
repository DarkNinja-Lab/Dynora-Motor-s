local PANEL = {}

local COLORS = {
    bg = Color(20, 10, 30, 250),
    glass = Color(255, 255, 255, 10),
    accent = Color(180, 100, 255),
    money = Color(255, 200, 50),
    success = Color(0, 255, 150),
    error = Color(255, 80, 100),
    text = Color(255, 255, 255),
    textDim = Color(180, 170, 200),
}

function PANEL:Init()
    self:SetSize(450, 350)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.3, 0)

    self.vehicleID = nil
    self.sellerSteamID = nil
    self.price = 0

    self.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.bg)
        surface.DrawRect(0, 0, w, h)
        
        for i = 0, h do
            local alpha = math.sin(i / h * math.pi) * 20
            surface.SetDrawColor(100, 50, 150, alpha)
            surface.DrawRect(0, i, w, 1)
        end
        
        surface.SetDrawColor(COLORS.money)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(COLORS.money.r, COLORS.money.g, COLORS.money.b, 50)
        surface.DrawRect(0, 0, w, 2)
    end


    local header = vgui.Create("DPanel", self)
    header:SetSize(450, 80)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.glass)
        surface.DrawRect(0, 0, w, h)
        
        draw.SimpleText("ANGEBOT ERHALTEN", "DermaLarge", w/2, 20, COLORS.money, TEXT_ALIGN_CENTER)
        draw.SimpleText("Jemand moechte dir sein Fahrzeug verkaufen!", "DermaDefault", w/2, 50, COLORS.textDim, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(COLORS.money)
        surface.DrawRect(50, h-1, w-100, 1)
    end

 
    local infoPanel = vgui.Create("DPanel", self)
    infoPanel:SetSize(410, 140)
    infoPanel:SetPos(20, 100)
    infoPanel.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.glass)
        surface.SetDrawColor(COLORS.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    self.infoText = vgui.Create("DLabel", infoPanel)
    self.infoText:SetSize(390, 120)
    self.infoText:SetPos(10, 10)
    self.infoText:SetText("Lade...")
    self.infoText:SetFont("DermaDefault")
    self.infoText:SetTextColor(COLORS.text)

  
    local acceptBtn = vgui.Create("DButton", self)
    acceptBtn:SetSize(180, 50)
    acceptBtn:SetPos(30, 270)
    acceptBtn:SetText("")
    
    acceptBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.success or Color(0, 200, 100))
        
        if s:IsHovered() then
            surface.SetDrawColor(COLORS.success.r, COLORS.success.g, COLORS.success.b, 30)
            surface.DrawRect(-5, -5, w+10, h+10)
        end
        
        draw.SimpleText("✓ ANNEHMEN", "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    acceptBtn.DoClick = function()
        net.Start("MyCarDealer_SellAccept")
        net.WriteString(self.vehicleID)
        net.WriteString(self.sellerSteamID)
        net.WriteInt(self.price, 32)
        net.SendToServer()
        self:Remove()
    end

    local declineBtn = vgui.Create("DButton", self)
    declineBtn:SetSize(180, 50)
    declineBtn:SetPos(240, 270)
    declineBtn:SetText("")
    
    declineBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.error or Color(200, 50, 50))
        
        draw.SimpleText("✗ ABLEHNEN", "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    declineBtn.DoClick = function()
        net.Start("MyCarDealer_SellDecline")
        net.WriteString(self.sellerSteamID)
        net.SendToServer()
        self:Remove()
    end
end

function PANEL:SetOffer(vehicleID, vehicleName, sellerName, sellerSteamID, price)
    self.vehicleID = vehicleID
    self.sellerSteamID = sellerSteamID
    self.price = price
    
    self.infoText:SetText(
        "Fahrzeug: " .. vehicleName .. "\n\n" ..
        "Verkäufer: " .. sellerName .. "\n" ..
        "Preis: " .. price .. "\n\n" ..
        "Dein Kontostand: " .. (LocalPlayer():getDarkRPVar("money") or 0)
    )
end

vgui.Register("MyCarDealer_SellOffer", PANEL, "DFrame")


net.Receive("MyCarDealer_SellOffer", function()
    local vehicleID = net.ReadString()
    local vehicleName = net.ReadString()
    local sellerName = net.ReadString()
    local sellerSteamID = net.ReadString()
    local price = net.ReadInt(32)
    
    local offer = vgui.Create("MyCarDealer_SellOffer")
    offer:SetOffer(vehicleID, vehicleName, sellerName, sellerSteamID, price)
    
 
    surface.PlaySound("buttons/button4.wav")
end)
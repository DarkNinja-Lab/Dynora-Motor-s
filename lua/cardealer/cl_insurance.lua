local PANEL = {}

local COLORS = {
    bg = Color(12, 12, 20, 250),
    glass = Color(255, 255, 255, 12),
    glassHover = Color(255, 255, 255, 20),
    primary = Color(157, 78, 221),
    success = Color(0, 255, 150),
    warning = Color(255, 200, 50),
    error = Color(255, 80, 100),
    money = Color(255, 215, 0),
    text = Color(255, 255, 255),
    textDim = Color(180, 180, 200),
}

function PANEL:Init()
    self:SetSize(550, 480)  -- VERBESSERT: Hoehe erhoeht von 450 auf 480
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.4, 0)
    
    self.vehicle = nil
    self.damageType = "accident"
    self.insuranceData = {
        hasInsurance = false,
        cooldown = 0,
        claims = 0
    }

    self.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.bg)
        surface.DrawRect(0, 0, w, h)
        
        local time = CurTime() * 0.5
        for i = 0, h do
            local wave = math.sin((i / h) * math.pi + time) * 20
            surface.SetDrawColor(157, 78, 221, math.abs(wave))
            surface.DrawRect(0, i, w, 1)
        end
        
        surface.SetDrawColor(COLORS.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(COLORS.primary.r, COLORS.primary.g, COLORS.primary.b, 80)
        surface.DrawRect(0, 0, w, 4)
    end

    local header = vgui.Create("DPanel", self)
    header:SetSize(550, 90)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.glass)
        surface.DrawRect(0, 0, w, h)
        
        local icons = {
            totalLoss = "!",
            accident = "WARNUNG",
            theft = "DIEBSTAHL",
            minor = "WARTUNG"
        }
        local titles = {
            totalLoss = "TOTALSCHADEN!",
            accident = "UNFALL GEMELDET",
            theft = "FAHRZEUG DIEBSTAHL",
            minor = "SCHADENSMELDUNG"
        }
        local colors = {
            totalLoss = COLORS.error,
            accident = COLORS.warning,
            theft = COLORS.warning,
            minor = COLORS.success
        }
        
        local icon = icons[self.damageType] or "WARNUNG"
        local title = titles[self.damageType] or "SCHADEN"
        local color = colors[self.damageType] or COLORS.warning
        
        draw.SimpleText(icon, "DermaLarge", 40, h/2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(title, "DermaLarge", 80, 30, COLORS.text, TEXT_ALIGN_LEFT)
        draw.SimpleText("Versicherungsanspruch pruefen...", "DermaDefault", 80, 55, COLORS.textDim, TEXT_ALIGN_LEFT)
        
        surface.SetDrawColor(color)
        surface.DrawRect(0, h-3, w, 3)
    end

    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetSize(45, 45)
    closeBtn:SetPos(495, 22)
    closeBtn:SetText("X")
    closeBtn:SetFont("DermaLarge")
    closeBtn:SetTextColor(COLORS.text)
    closeBtn.Paint = function(s, w, h)
        draw.RoundedBox(10, 0, 0, w, h, s:IsHovered() and COLORS.error or Color(0,0,0,0))
    end
    closeBtn.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end

    self.content = vgui.Create("DPanel", self)
    self.content:SetSize(510, 360)  -- VERBESSERT: Hoehe angepasst
    self.content:SetPos(20, 105)     -- VERBESSERT: Y-Position angepasst
    self.content.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, COLORS.glass)
        surface.SetDrawColor(COLORS.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    
    self:BuildContent()
end

function PANEL:SetVehicle(vehicle, damageType)
    self.vehicle = vehicle
    self.damageType = damageType or "accident"
end

function PANEL:SetInsuranceData(hasInsurance, cooldown, claims)
    self.insuranceData.hasInsurance = hasInsurance
    self.insuranceData.cooldown = cooldown
    self.insuranceData.claims = claims or 0
    self:BuildContent()
end

function PANEL:BuildContent()
    for _, child in pairs(self.content:GetChildren()) do
        child:Remove()
    end
    
    if not self.vehicle then return end
    
    local theme = MyCarDealer.Theme or COLORS
    
    local infoPanel = vgui.Create("DPanel", self.content)
    infoPanel:SetSize(470, 90)
    infoPanel:SetPos(20, 20)
    infoPanel.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,50))
        surface.SetDrawColor(theme.primary or COLORS.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText(self.vehicle.name or "Unbekannt", "DermaLarge", 20, 15, COLORS.text, TEXT_ALIGN_LEFT)
        draw.SimpleText("Wert: $" .. string.Comma(self.vehicle.price or 0), "DermaDefault", 20, 55, COLORS.money, TEXT_ALIGN_LEFT)
    end
    
    if self.vehicle.model then
        local modelPanel = vgui.Create("DModelPanel", infoPanel)
        modelPanel:SetSize(100, 80)
        modelPanel:SetPos(360, 5)
        modelPanel:SetModel(self.vehicle.model)
        modelPanel:SetFOV(45)
        
        if modelPanel.Entity then
            local mn, mx = modelPanel.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
            modelPanel:SetCamPos(Vector(size, size, size) * 0.5)
            modelPanel:SetLookAt((mn + mx) * 0.5)
        end
    end
    
    local statusY = 125  -- VERBESSERT: Mehr Abstand nach oben (war 120)
    
    if not self.insuranceData.hasInsurance then
        local noIns = vgui.Create("DLabel", self.content)
        noIns:SetSize(470, 40)
        noIns:SetPos(20, statusY)
        noIns:SetText("X KEINE VERSICHERUNG")
        noIns:SetFont("DermaDefaultBold")
        noIns:SetTextColor(COLORS.error)
        noIns:SetContentAlignment(5)
        
        local hint = vgui.Create("DLabel", self.content)
        hint:SetSize(470, 100)
        hint:SetPos(20, statusY + 50)
        hint:SetText("Dieses Fahrzeug ist nicht versichert.\n\nDu erhaelst keine Entschaedigung bei:\n- Unfaellen - Diebstahl - Totalschaden\n\nSchliesse eine Versicherung ab um geschuetzt zu sein!")
        hint:SetFont("DermaDefault")
        hint:SetTextColor(COLORS.textDim)
        hint:SetContentAlignment(5)
        
    else
        local hasIns = vgui.Create("DLabel", self.content)
        hasIns:SetSize(470, 30)
        hasIns:SetPos(20, statusY)
        hasIns:SetText("OK VERSICHERUNG AKTIV")
        hasIns:SetFont("DermaDefaultBold")
        hasIns:SetTextColor(COLORS.success)
        hasIns:SetContentAlignment(5)
        
        local claimsLabel = vgui.Create("DLabel", self.content)
        claimsLabel:SetSize(470, 25)
        claimsLabel:SetPos(20, statusY + 35)
        claimsLabel:SetText("Bisherige Schadensfaelle: " .. self.insuranceData.claims .. " / 3")
        claimsLabel:SetFont("DermaDefault")
        claimsLabel:SetTextColor(self.insuranceData.claims >= 2 and COLORS.warning or COLORS.textDim)
        claimsLabel:SetContentAlignment(5)
        
        local cooldownRemaining = self.insuranceData.cooldown - os.time()
        
        if cooldownRemaining > 0 then
            local minutes = math.ceil(cooldownRemaining / 60)
            
            local cooldownLabel = vgui.Create("DLabel", self.content)
            cooldownLabel:SetSize(470, 50)
            cooldownLabel:SetPos(20, statusY + 65)  -- VERBESSERT: Position angepasst
            cooldownLabel:SetText("COOLDOWN AKTIV\nVerfuegbar in: " .. minutes .. " Minuten")
            cooldownLabel:SetFont("DermaDefaultBold")
            cooldownLabel:SetTextColor(COLORS.warning)
            cooldownLabel:SetContentAlignment(5)
            
        else
            local payoutPercent = MyCarDealer.Insurance.Config.Payouts[self.damageType] or 0.25
            local payout = math.floor((self.vehicle.price or 0) * payoutPercent)
            
            local payoutPanel = vgui.Create("DPanel", self.content)
            payoutPanel:SetSize(470, 100)
            payoutPanel:SetPos(20, statusY + 60)  -- VERBESSERT: Position angepasst
            payoutPanel.Paint = function(s, w, h)
                draw.RoundedBox(12, 0, 0, w, h, Color(0, 150, 100, 40))
                surface.SetDrawColor(COLORS.success)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                
                draw.SimpleText("MOEGLICHE AUSZAHLUNG", "DermaDefault", w/2, 20, COLORS.textDim, TEXT_ALIGN_CENTER)
                draw.SimpleText("$" .. string.Comma(payout), "DermaLarge", w/2, 55, COLORS.money, TEXT_ALIGN_CENTER)
            end
            
            -- VERBESSERT: Button mit mehr Abstand
            local claimBtn = vgui.Create("DButton", self.content)
            claimBtn:SetSize(220, 55)
            claimBtn:SetPos(145, statusY + 175)  -- VERBESSERT: War 170, jetzt 175
            claimBtn:SetText("")
            claimBtn.Paint = function(s, w, h)
                local col = s:IsHovered() and COLORS.success or Color(0, 200, 100)
                draw.RoundedBox(14, 0, 0, w, h, col)
                
                if s:IsHovered() then
                    surface.SetDrawColor(255, 255, 255, 30)
                    surface.DrawRect(0, 0, w, h)
                end
                
                draw.SimpleText("ANSPRUCH EINLOESEN", "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            claimBtn.DoClick = function()
                self:SubmitClaim()
            end
            
            -- VERBESSERT: Warnung mit mehr Abstand
            local warnLabel = vgui.Create("DLabel", self.content)
            warnLabel:SetSize(470, 40)
            warnLabel:SetPos(20, statusY + 240)  -- VERBESSERT: War 235, jetzt 240
            warnLabel:SetText("ACHTUNG: Bei Totalschaden/Diebstahl wird das Fahrzeug entfernt!")
            warnLabel:SetFont("DermaDefault")
            warnLabel:SetTextColor(COLORS.warning)
            warnLabel:SetContentAlignment(5)
        end
    end
end

function PANEL:SubmitClaim()
    if not self.vehicle then return end
    
    net.Start("MyCarDealer_ClaimInsurance")
    net.WriteString(self.vehicle.id)
    net.WriteString(self.damageType)
    net.SendToServer()
    
    self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    surface.PlaySound("ui/buttonclick.wav")
end

vgui.Register("MyCarDealer_InsuranceMenu", PANEL, "DFrame")

net.Receive("MyCarDealer_InsuranceMenu", function()
    local vehicleID = net.ReadString()
    local damageType = net.ReadString()
    
    local vehicleData = nil
    for _, v in ipairs(MyCarDealer.Vehicles or {}) do
        if v.id == vehicleID then
            vehicleData = v
            break
        end
    end
    
    if not vehicleData and MyCarDealer.MyInventory then
        for _, v in ipairs(MyCarDealer.MyInventory) do
            if v.id == vehicleID then
                vehicleData = v
                break
            end
        end
    end
    
    if not vehicleData then
        vehicleData = {id = vehicleID, name = "Unbekannt", price = 0, model = "models/error.mdl"}
    end
    
    local menu = vgui.Create("MyCarDealer_InsuranceMenu")
    menu:SetVehicle(vehicleData, damageType)
    
    net.Start("MyCarDealer_BuyInsurance")
    net.WriteString(vehicleID)
    net.SendToServer()
end)

net.Receive("MyCarDealer_SyncInsurance", function()
    local vehicleID = net.ReadString()
    local hasInsurance = net.ReadBool()
    local cooldown = net.ReadUInt(32)
    local claims = net.ReadUInt(8)
    
    for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
        if IsValid(v) and v:GetName() == "MyCarDealer_InsuranceMenu" and v.vehicle and v.vehicle.id == vehicleID then
            v:SetInsuranceData(hasInsurance, cooldown, claims)
        end
    end
end)

function MyCarDealer.OpenInsuranceBuy(vehicle)
    local theme = MyCarDealer.Theme or COLORS
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 400)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.4, 0)
    
    local price = math.floor((vehicle.price or 0) * 0.10)
    price = math.Clamp(price, 500, 50000)
    
    frame.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(theme.primary or COLORS.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        surface.SetDrawColor(COLORS.glass)
        surface.DrawRect(0, 0, w, 80)
        draw.SimpleText("VERSICHERUNG ABSCHLIESSEN", "DermaLarge", w/2, 40, theme.primary or COLORS.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local info = vgui.Create("DPanel", frame)
    info:SetSize(460, 100)
    info:SetPos(20, 100)
    info.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, COLORS.glass)
        draw.SimpleText(vehicle.name or "Unbekannt", "DermaLarge", 20, 20, COLORS.text, TEXT_ALIGN_LEFT)
        draw.SimpleText("Jaehrliche Praemie: $" .. string.Comma(price), "DermaDefault", 20, 60, COLORS.money, TEXT_ALIGN_LEFT)
    end
    
    local coverage = vgui.Create("DLabel", frame)
    coverage:SetSize(460, 120)
    coverage:SetPos(20, 220)
    coverage:SetText("DECKUNG:\n\n" ..
                     "* Totalschaden: 85% Auszahlung\n" ..
                     "* Unfall: 50% Auszahlung\n" ..
                     "* Diebstahl: 70% Auszahlung\n" ..
                     "* Kleinschaden: 25% Auszahlung\n\n" ..
                     "Max. 3 Schadensfaelle pro Fahrzeug\n" ..
                     "Cooldown: 1 Stunde zwischen Claims")
    coverage:SetFont("DermaDefault")
    coverage:SetTextColor(COLORS.text)
    
    local buyBtn = vgui.Create("DButton", frame)
    buyBtn:SetSize(200, 50)
    buyBtn:SetPos(50, 330)
    buyBtn:SetText("")
    buyBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.success or Color(0, 200, 100))
        draw.SimpleText("ABSCHLIESSEN", "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    buyBtn.DoClick = function()
        net.Start("MyCarDealer_BuyInsurance")
        net.WriteString(vehicle.id)
        net.SendToServer()
        frame:Remove()
    end
    
    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetSize(200, 50)
    cancelBtn:SetPos(270, 330)
    cancelBtn:SetText("")
    cancelBtn.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and COLORS.error or Color(150, 50, 50))
        draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancelBtn.DoClick = function()
        frame:Remove()
    end
end

print("[Dynora Motor´s] Client insurance module loaded")
local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() * 0.85, ScrH() * 0.85)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.4, 0)
    
    local theme = MyCarDealer.Theme
    
    self.Paint = function(s, w, h)
        surface.SetDrawColor(8, 12, 20, 255)
        surface.DrawRect(0, 0, w, h)
        
    
        surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 8)
        for i = 0, w, 50 do surface.DrawLine(i, 0, i, h) end
        for i = 0, h, 50 do surface.DrawLine(0, i, w, i) end
        
        MyCarDealer.DrawGradient(0, 0, w, 3, theme.secondary, Color(0, 100, 200), true)
        surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 20)
        surface.DrawRect(0, 70, w, 100)
    end
    

    local header = vgui.Create("DPanel", self)
    header:SetSize(self:GetWide(), 80)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 0, w, h)
        
        draw.SimpleText("POLIZEI", "DermaLarge", 30, 28, theme.secondary, TEXT_ALIGN_LEFT)
        draw.SimpleText("DIENSTSTELLE", "DermaDefaultBold", 145, 32, Color(100, 150, 255), TEXT_ALIGN_LEFT)
        
        draw.SimpleText("OFFIZIELLE DIENSTFAHRZEUGE", "DermaDefault", w/2, 50, theme.textMuted, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(theme.border)
        surface.DrawRect(0, h-1, w, 1)
    end
    

    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(header:GetWide() - 60, 20)
    closeBtn:SetText("")
    closeBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and theme.error or theme.textMuted
        draw.SimpleText("×", "DermaLarge", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if s:IsHovered() then
            surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end
    closeBtn.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end
    
  
    local sidebar = vgui.Create("DPanel", self)
    sidebar:SetSize(280, self:GetTall() - 80)
    sidebar:SetPos(0, 80)
    sidebar.Paint = function(s, w, h)
        surface.SetDrawColor(theme.surface)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 30)
        surface.DrawRect(w-2, 0, 2, h)
    end
    
 
    local infoPanel = vgui.Create("DPanel", sidebar)
    infoPanel:SetSize(260, 140)
    infoPanel:SetPos(10, 20)
    infoPanel.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("INFORMATION", "DermaDefaultBold", 15, 15, theme.secondary, TEXT_ALIGN_LEFT)
        draw.SimpleText("Hier können aktive", "DermaDefault", 15, 40, theme.textSecondary, TEXT_ALIGN_LEFT)
        draw.SimpleText("Polizeibeamte ihre", "DermaDefault", 15, 58, theme.textSecondary, TEXT_ALIGN_LEFT)
        draw.SimpleText("Dienstfahrzeuge erwerben.", "DermaDefault", 15, 76, theme.textSecondary, TEXT_ALIGN_LEFT)
        
        local rank = LocalPlayer():getDarkRPVar("job") or "Unbekannt"
        draw.SimpleText("Rang: " .. rank, "DermaDefaultBold", 15, 110, theme.secondary, TEXT_ALIGN_LEFT)
    end

    local btnY = sidebar:GetTall() - 120
    
 
    local invBtn = vgui.Create("DButton", sidebar)
    invBtn:SetSize(260, 45)
    invBtn:SetPos(10, btnY)
    invBtn:SetText("")
    invBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and theme.success or Color(0, 150, 100)
        draw.RoundedBox(8, 0, 0, w, h, col)
        draw.SimpleText("[ MEINE GARAGE ]", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    invBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
            vgui.Create("MyCarDealer_Inventory")
        end)
    end
    
 
    local backBtn = vgui.Create("DButton", sidebar)
    backBtn:SetSize(260, 45)
    backBtn:SetPos(10, btnY + 50)
    backBtn:SetText("")
    backBtn.Paint = function(s, w, h)
        local col = s:IsHovered() and theme.primary or theme.primaryDark
        draw.RoundedBox(8, 0, 0, w, h, col)
        draw.SimpleText("[ ZURÜCK ]", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    backBtn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
            vgui.Create("MyCarDealer_Menu")
        end)
    end
    
  
    self.mainPanel = vgui.Create("DPanel", self)
    self.mainPanel:SetSize(self:GetWide() - 300, self:GetTall() - 100)
    self.mainPanel:SetPos(290, 90)
    self.mainPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.surface)
    end
    

    self.vehicleGrid = vgui.Create("DScrollPanel", self.mainPanel)
    self.vehicleGrid:Dock(FILL)
    self.vehicleGrid:DockMargin(20, 20, 20, 20)
    
    local gridSbar = self.vehicleGrid:GetVBar()
    gridSbar:SetWide(6)
    gridSbar.Paint = function() end
    gridSbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, theme.secondary)
    end
    
    self.gridContainer = vgui.Create("DPanel", self.vehicleGrid)
    self.gridContainer:SetSize(self.mainPanel:GetWide() - 50, 2000)
    self.gridContainer:SetPos(0, 0)
    self.gridContainer.Paint = function() end
    
    self:LoadPoliceVehicles()
end

function PANEL:LoadPoliceVehicles()
    local theme = MyCarDealer.Theme
    
    for _, child in pairs(self.gridContainer:GetChildren()) do
        child:Remove()
    end
    
    local vehicles = {}
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.job == "TEAM_POLICE" then
            table.insert(vehicles, v)
        end
    end
    
    if #vehicles == 0 then
        local noVehicles = vgui.Create("DLabel", self.gridContainer)
        noVehicles:SetSize(400, 100)
        noVehicles:SetPos(200, 200)
        noVehicles:SetText("KEINE DIENSTFAHRZEUGE VERFÜGBAR")
        noVehicles:SetFont("DermaLarge")
        noVehicles:SetTextColor(theme.error)
        return
    end
    
    local cardW = 300
    local cardH = 400
    local spacing = 20
    local cols = math.floor((self.mainPanel:GetWide() - 60) / (cardW + spacing))
    cols = math.max(cols, 2)
    
    for i, vehicle in ipairs(vehicles) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local x = 10 + col * (cardW + spacing)
        local y = 10 + row * (cardH + spacing)
        
        local card = vgui.Create("DPanel", self.gridContainer)
        card:SetSize(cardW, cardH)
        card:SetPos(x, y)
        card:SetAlpha(0)
        card:AlphaTo(255, 0.3, (x + y) / 1000)
        
        card.Paint = function(s, w, h)
            draw.RoundedBox(16, 0, 0, w, h, theme.elevated)
            
            if s:IsHovered() then
                surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 30)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            
            surface.SetDrawColor(theme.secondary)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            surface.SetDrawColor(theme.secondary)
            surface.DrawRect(20, 0, w-40, 3)
        end
        
      
        local modelPanel = vgui.Create("DPanel", card)
        modelPanel:SetSize(cardW - 40, 180)
        modelPanel:SetPos(20, 20)
        modelPanel.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 100))
            surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 10)
            for i = 0, w, 20 do surface.DrawLine(i, 0, i, h) end
        end
        
        local model = vgui.Create("DModelPanel", modelPanel)
        model:Dock(FILL)
        model:DockMargin(10, 10, 10, 10)
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
                    s.Entity:SetAngles(Angle(0, (CurTime() * 10) % 360, 0))
                end
            end
        end
        
    
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetSize(cardW - 40, 30)
        nameLabel:SetPos(20, 210)
        nameLabel:SetText(vehicle.name)
        nameLabel:SetFont("DermaLarge")
        nameLabel:SetTextColor(theme.textPrimary)
        
        local priceLabel = vgui.Create("DLabel", card)
        priceLabel:SetSize(cardW - 40, 25)
        priceLabel:SetPos(20, 245)
        priceLabel:SetText("$" .. string.Comma(vehicle.price))
        priceLabel:SetFont("DermaDefaultBold")
        priceLabel:SetTextColor(theme.success)
        
        local descLabel = vgui.Create("DLabel", card)
        descLabel:SetSize(cardW - 40, 40)
        descLabel:SetPos(20, 275)
        descLabel:SetText(vehicle.description or "")
        descLabel:SetFont("DermaDefault")
        descLabel:SetTextColor(theme.textSecondary)
        descLabel:SetWrap(true)
        
        local badge = vgui.Create("DLabel", card)
        badge:SetSize(cardW - 40, 20)
        badge:SetPos(20, 320)
        badge:SetText("[ DIENSTFAHRZEUG ]")
        badge:SetFont("DermaDefaultBold")
        badge:SetTextColor(theme.secondary)
        

        local buyBtn = vgui.Create("DButton", card)
        buyBtn:SetSize(140, 45)
        buyBtn:SetPos((cardW - 140) / 2, 350)
        buyBtn:SetText("")
        buyBtn.Paint = function(s, w, h)
            local col = s:IsHovered() and theme.secondary or Color(0, 120, 200)
            draw.RoundedBox(8, 0, 0, w, h, col)
            if s:IsHovered() then
                MyCarDealer.DrawGlow(0, 0, w, h, theme.secondary, 0.3)
            end
            draw.SimpleText("ANSCHAFFEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        buyBtn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            
            local confirm = vgui.Create("DFrame")
            confirm:SetSize(450, 200)
            confirm:Center()
            confirm:SetTitle("")
            confirm:ShowCloseButton(false)
            confirm:MakePopup()
            confirm:SetAlpha(0)
            confirm:AlphaTo(255, 0.2, 0)
            
            confirm.Paint = function(s, w, h)
                draw.RoundedBox(16, 0, 0, w, h, theme.surface)
                surface.SetDrawColor(theme.secondary)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                surface.SetDrawColor(theme.elevated)
                surface.DrawRect(0, 0, w, 60)
                draw.SimpleText("BESTÄTIGUNG", "DermaLarge", w/2, 30, theme.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            local text = vgui.Create("DLabel", confirm)
            text:Dock(TOP)
            text:SetHeight(80)
            text:SetText(vehicle.name .. "\nPreis: $" .. string.Comma(vehicle.price))
            text:SetFont("DermaDefault")
            text:SetTextColor(theme.textPrimary)
            text:SetContentAlignment(5)
            
            local yes = vgui.Create("DButton", confirm)
            yes:SetSize(150, 45)
            yes:SetPos(50, 130)
            yes:SetText("")
            yes.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.success or Color(0, 150, 100))
                draw.SimpleText("JA", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            yes.DoClick = function()
                net.Start("MyCarDealer_Buy")
                net.WriteString(vehicle.id)
                net.SendToServer()
                confirm:Remove()
            end
            
            local no = vgui.Create("DButton", confirm)
            no:SetSize(150, 45)
            no:SetPos(250, 130)
            no:SetText("")
            no.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.error or Color(150, 50, 50))
                draw.SimpleText("NEIN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            no.DoClick = function()
                confirm:Remove()
            end
        end
    end
    
    local totalRows = math.ceil(#vehicles / cols)
    self.gridContainer:SetHeight(20 + totalRows * (cardH + spacing))
end

vgui.Register("MyCarDealer_PoliceMenu", PANEL, "DFrame")
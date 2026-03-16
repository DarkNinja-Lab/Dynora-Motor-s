local PANEL = {}

local COLORS = {
    bg = Color(10, 30, 20, 250),           
    panel = Color(20, 60, 40, 200),       
    panelHover = Color(30, 90, 60, 220),   
    accent = Color(100, 255, 150),        
    accentDark = Color(50, 150, 100),    
    text = Color(255, 255, 255),
    textDim = Color(180, 255, 200),
    success = Color(100, 255, 150),
    error = Color(255, 100, 100),
    warning = Color(255, 200, 100),
    glass = Color(255, 255, 255, 10),
    police = Color(0, 100, 255)             
}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.3, 0)

 
    self.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.bg)
        surface.DrawRect(0, 0, w, h)

        for i = 0, 200 do
            surface.SetDrawColor(50, 150, 100, 200 - i)
            surface.DrawRect(0, i, w, 1)
        end

        surface.SetDrawColor(COLORS.accent)
        surface.DrawRect(0, 0, w, 2)
    end

    
    local header = vgui.Create("DPanel", self)
    header:SetSize(ScrW(), 100)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(COLORS.glass)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("FAHRZEUG GARAGE", "DermaLarge", w/2, 25, COLORS.text, TEXT_ALIGN_CENTER)
        draw.SimpleText("Verwalte deine Fahrzeuge", "DermaDefault", w/2, 55, COLORS.textDim, TEXT_ALIGN_CENTER)
        
     
        if MyCarDealer.MyInventory and #MyCarDealer.MyInventory > 0 then
            local nameList = {}
            for _, v in ipairs(MyCarDealer.MyInventory) do
                table.insert(nameList, v.name)
            end
            
            local namesText = table.concat(nameList, "  •  ")
            
            surface.SetFont("DermaDefault")
            local textWidth, _ = surface.GetTextSize(namesText)
            
            if textWidth > w - 100 then
                local shortList = {}
                local maxChars = 80
                local currentLength = 0
                
                for _, name in ipairs(nameList) do
                    if currentLength + #name < maxChars then
                        table.insert(shortList, name)
                        currentLength = currentLength + #name + 5
                    else
                        table.insert(shortList, "...")
                        break
                    end
                end
                namesText = table.concat(shortList, "  •  ")
            end
            
            draw.SimpleText(namesText, "DermaDefault", w/2, 75, COLORS.accent, TEXT_ALIGN_CENTER)
        end
    end


    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetSize(50, 50)
    closeBtn:SetPos(ScrW() - 70, 25)
    closeBtn:SetText("×")
    closeBtn:SetFont("DermaLarge")
    closeBtn:SetTextColor(COLORS.text)
    closeBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and COLORS.error or Color(0,0,0,0))
    end
    closeBtn.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end

  
    local container = vgui.Create("DPanel", self)
    container:SetSize(ScrW() - 60, ScrH() - 140)
    container:SetPos(30, 110)
    container.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, COLORS.panel)
    end

    self.vehicleGrid = vgui.Create("DScrollPanel", container)
    self.vehicleGrid:Dock(FILL)
    self.vehicleGrid:DockMargin(20, 20, 20, 20)

    local sbar = self.vehicleGrid:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.accentDark)
    end

    self.gridContainer = vgui.Create("DPanel", self.vehicleGrid)
    self.gridContainer:SetSize(container:GetWide() - 40, 2000)
    self.gridContainer:SetPos(0, 0)
    self.gridContainer.Paint = function() end


    MyCarDealer.RequestSync()

    timer.Simple(0.5, function()
        if IsValid(self) then
            self:LoadGarage()
        end
    end)
end

function PANEL:LoadGarage()
    for _, child in pairs(self.gridContainer:GetChildren()) do
        child:Remove()
    end

    if not MyCarDealer.MyInventory or #MyCarDealer.MyInventory == 0 then
        local noCars = vgui.Create("DLabel", self.gridContainer)
        noCars:SetSize(400, 100)
        noCars:SetPos(300, 200)
        noCars:SetText("Keine Fahrzeuge im Besitz!")
        noCars:SetFont("DermaLarge")
        noCars:SetTextColor(COLORS.error)
        return
    end

    local cardWidth = 300
    local cardHeight = 320
    local spacing = 20
    local cols = 4
    local startX = 10
    local startY = 10

    for i, vehicle in ipairs(MyCarDealer.MyInventory) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local x = startX + col * (cardWidth + spacing)
        local y = startY + row * (cardHeight + spacing)
        
        self:CreateGarageCard(vehicle, x, y, cardWidth, cardHeight)
    end

    local totalRows = math.ceil(#MyCarDealer.MyInventory / cols)
    local newHeight = startY + (totalRows * (cardHeight + spacing)) + 50
    self.gridContainer:SetHeight(newHeight)
end

function PANEL:CreateGarageCard(vehicle, x, y, w, h)
    local card = vgui.Create("DPanel", self.gridContainer)
    card:SetSize(w, h)
    card:SetPos(x, y)
    card:SetAlpha(0)
    card:AlphaTo(255, 0.3, 0)


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
            jobText = "[JOB GESPERRT]"
        else
            jobText = "[DIENSTFAHRZEUG]"
        end
    end

    card.Paint = function(s, w, h)
    
        if isPoliceVehicle then
            draw.RoundedBox(12, 0, 0, w, h, Color(20, 40, 80, 220))
            surface.SetDrawColor(canSpawn and COLORS.police or COLORS.error)
        else
            draw.RoundedBox(12, 0, 0, w, h, COLORS.panel)
            surface.SetDrawColor(canSpawn and COLORS.success or COLORS.error)
        end
        
        surface.DrawRect(0, 0, 4, h)

        if s:IsHovered() then
            surface.SetDrawColor(255, 255, 255, 5)
            surface.DrawRect(0, 0, w, h)
        end
        
        if jobText ~= "" then
            local textCol = isPoliceVehicle and COLORS.police or COLORS.error
            draw.SimpleText(jobText, "DermaDefaultBold", w/2, h-20, textCol, TEXT_ALIGN_CENTER)
        end
    end

    local modelContainer = vgui.Create("DPanel", card)
    modelContainer:SetSize(w - 20, 140)
    modelContainer:SetPos(10, 10)
    modelContainer.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 100))
    end

  
    local model = vgui.Create("DModelPanel", modelContainer)
    model:Dock(FILL)
    model:DockMargin(10, 10, 10, 10)
    model:SetModel(vehicle.model)

    if model.Entity then
        local mn, mx = model.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), 
                             math.abs(mn.y) + math.abs(mx.y), 
                             math.abs(mn.z) + math.abs(mx.z))
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
                s.Entity:SetAngles(Angle(0, (CurTime() * 15) % 360, 0))
            end
        end
    end


    local nameLabel = vgui.Create("DLabel", card)
    nameLabel:SetSize(w - 20, 25)
    nameLabel:SetPos(10, 160)
    nameLabel:SetText(vehicle.name)
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetTextColor(COLORS.text)

 
    local dateLabel = vgui.Create("DLabel", card)
    dateLabel:SetSize(w - 20, 20)
    dateLabel:SetPos(10, 185)
    dateLabel:SetText("Gekauft: " .. (vehicle.purchase_date or "-"))
    dateLabel:SetFont("DermaDefault")
    dateLabel:SetTextColor(COLORS.textDim)

  
    local tuningText = ""
    if vehicle.tuning then
        if vehicle.tuning.neon and vehicle.tuning.neon.enabled then
            tuningText = tuningText .. "[NEON] "
        end
        if vehicle.tuning.lvs and vehicle.tuning.lvs.skin and vehicle.tuning.lvs.skin > 0 then
            tuningText = tuningText .. "[SKIN " .. vehicle.tuning.lvs.skin .. "] "
        end
    end
    
    if tuningText ~= "" then
        local tuningLabel = vgui.Create("DLabel", card)
        tuningLabel:SetSize(w - 20, 20)
        tuningLabel:SetPos(10, 210)
        tuningLabel:SetText(tuningText)
        tuningLabel:SetFont("DermaDefault")
        tuningLabel:SetTextColor(COLORS.accent)
    end

  
    local btnW = 130
    local btnH = 40
    local btnY = 250

  
    local spawnBtn = vgui.Create("DButton", card)
    spawnBtn:SetSize(btnW, btnH)
    spawnBtn:SetPos(15, btnY)
    spawnBtn:SetText(canSpawn and "AUSPARKEN" or "GESPERRT")
    spawnBtn:SetFont("DermaDefaultBold")
    spawnBtn:SetTextColor(COLORS.text)
    spawnBtn.Paint = function(s, w, h)
        local col
        if canSpawn then
            col = s:IsHovered() and COLORS.accent or COLORS.accentDark
        else
            col = Color(100, 100, 100)
        end
        draw.RoundedBox(8, 0, 0, w, h, col)
    end
    spawnBtn.DoClick = function()
        if not canSpawn then
         
            local msg = vgui.Create("DFrame")
            msg:SetSize(350, 120)
            msg:Center()
            msg:SetTitle("")
            msg:ShowCloseButton(false)
            msg:MakePopup()
            msg.Paint = function(s, w, h)
                draw.RoundedBox(16, 0, 0, w, h, COLORS.panel)
            end
            
            local text = vgui.Create("DLabel", msg)
            text:Dock(TOP)
            text:SetHeight(60)
            text:SetText("Du hast nicht den richtigen Job!\n" .. (MyCarDealer.JobNames[vehicleData.job] or vehicleData.job))
            text:SetFont("DermaDefaultBold")
            text:SetTextColor(COLORS.error)
            text:SetContentAlignment(5)
            
            local ok = vgui.Create("DButton", msg)
            ok:SetSize(100, 35)
            ok:SetPos(125, 70)
            ok:SetText("OK")
            ok:SetTextColor(COLORS.text)
            ok.Paint = function(s, w, h)
                draw.RoundedBox(8, 0, 0, w, h, COLORS.accentDark)
            end
            ok.DoClick = function() msg:Remove() end
            return
        end
        
        net.Start("MyCarDealer_Spawn")
        net.WriteString(vehicle.id)
        net.SendToServer()
  
        surface.PlaySound("buttons/button9.wav")

    end


    local storeBtn = vgui.Create("DButton", card)
    storeBtn:SetSize(btnW, btnH)
    storeBtn:SetPos(w - btnW - 15, btnY)
    storeBtn:SetText("EINPARKEN")
    storeBtn:SetFont("DermaDefaultBold")
    storeBtn:SetTextColor(COLORS.text)
    storeBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and COLORS.warning or Color(200, 150, 0))
    end
    storeBtn.DoClick = function()
        net.Start("MyCarDealer_Store")
        net.SendToServer()
        
        timer.Simple(0.3, function()
            if IsValid(self) then
                MyCarDealer.RequestSync()
                timer.Simple(0.2, function()
                    if IsValid(self) then self:LoadGarage() end
                end)
            end
        end)
        
        surface.PlaySound("buttons/button14.wav")
    end
end

vgui.Register("MyCarDealer_GarageMenu", PANEL, "DFrame")
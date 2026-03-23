local PANEL = {}

function PANEL:Init()
    local theme = MyCarDealer.Theme
    
    self:SetSize(900, 650)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.4, 0)

    self.Paint = function(s, w, h)
        surface.SetDrawColor(theme.background)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, 3)
        for i = 0, w, 40 do surface.DrawLine(i, 0, i, h) end
        
        MyCarDealer.DrawGradient(0, 0, w, 3, theme.primary, theme.accent, true)
    end

    local header = vgui.Create("DPanel", self)
    header:SetSize(900, 70)
    header:SetPos(0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 0, w, h)
        
        draw.SimpleText("FAHRZEUG TUNING", "DermaLarge", w/2, 20, theme.primary, TEXT_ALIGN_CENTER)
        draw.SimpleText("Passe dein Fahrzeug individuell an", "DermaDefault", w/2, 45, theme.textMuted, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(850, 15)
    closeBtn:SetText("")
    closeBtn.Paint = function(s, w, h)
        draw.SimpleText("×", "DermaLarge", w/2, h/2, s:IsHovered() and theme.error or theme.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end

    local leftPanel = vgui.Create("DPanel", self)
    leftPanel:SetSize(400, 560)
    leftPanel:SetPos(20, 80)
    leftPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local scroll = vgui.Create("DScrollPanel", leftPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(15, 15, 15, 15)

    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, theme.primary)
    end
    
    self:AddSection(scroll, "NEON BELEUCHTUNG", theme.primary)
    
    local neonToggle = vgui.Create("DPanel", scroll)
    neonToggle:Dock(TOP)
    neonToggle:SetHeight(50)
    neonToggle:DockMargin(0, 10, 0, 10)
    
    local neonEnabled = false
    neonToggle.Paint = function(s, w, h)
        draw.SimpleText("Aktivieren", "DermaDefault", 10, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        local switchW = 50
        local switchH = 26
        local switchX = w - switchW - 10
        local switchY = (h - switchH) / 2
        
        draw.RoundedBox(13, switchX, switchY, switchW, switchH, neonEnabled and Color(theme.primary.r, theme.primary.g, theme.primary.b, 80) or theme.glass)
        surface.SetDrawColor(neonEnabled and theme.primary or theme.textMuted)
        surface.DrawOutlinedRect(switchX, switchY, switchW, switchH, 2)
        
        local knobX = neonEnabled and (switchX + switchW - 24) or (switchX + 4)
        draw.RoundedBox(11, knobX, switchY + 3, 20, 20, neonEnabled and theme.primary or theme.textMuted)
    end
    
    neonToggle.OnMousePressed = function()
        neonEnabled = not neonEnabled
        surface.PlaySound("ui/buttonclick.wav")
        if not self.tuning then self.tuning = {} end
        if not self.tuning.neon then self.tuning.neon = {enabled = false, color = Color(157, 78, 221)} end
        self.tuning.neon.enabled = neonEnabled
        self:UpdatePreview()
    end

    local neonColorBtn = vgui.Create("DButton", scroll)
    neonColorBtn:Dock(TOP)
    neonColorBtn:SetHeight(50)
    neonColorBtn:DockMargin(0, 0, 0, 20)
    neonColorBtn:SetText("")
    
    local neonColor = Color(157, 78, 221)
    neonColorBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.surfaceHover or theme.glass)
        surface.SetDrawColor(theme.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.RoundedBox(6, 10, 12, 26, 26, neonColor)
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(10, 12, 26, 26, 1)
        
        draw.SimpleText("FARBE WAEHLEN", "DermaDefaultBold", 50, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    neonColorBtn.DoClick = function()
        self:OpenColorPicker("NEON FARBE", neonColor, function(col)
            neonColor = col
            if not self.tuning then self.tuning = {} end
            if not self.tuning.neon then self.tuning.neon = {enabled = false, color = Color(157, 78, 221)} end
            self.tuning.neon.color = col
            self:UpdatePreview()
        end)
    end

    -- KORRIGIERT: Karosseriefarbe mit mehr Platz
    self:AddSection(scroll, "KAROSSERIEFARBE", theme.secondary)
    
    local bodyColorBtn = vgui.Create("DButton", scroll)
    bodyColorBtn:Dock(TOP)
    bodyColorBtn:SetHeight(50)
    bodyColorBtn:DockMargin(0, 10, 0, 25)  -- VERBESSERT: Mehr Abstand unten (25 statt 20)
    bodyColorBtn:SetText("")
    
    local bodyColor = Color(255, 255, 255)
    bodyColorBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.surfaceHover or theme.glass)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.RoundedBox(6, 10, 12, 26, 26, bodyColor)
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(10, 12, 26, 26, 1)
        
        -- VERBESSERT: Text klarer positioniert
        draw.SimpleText("LACKIERUNG", "DermaDefaultBold", 50, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    bodyColorBtn.DoClick = function()
        self:OpenColorPicker("KAROSSERIEFARBE", bodyColor, function(col)
            bodyColor = col
            if not self.tuning then self.tuning = {} end
            if not self.tuning.lvs then self.tuning.lvs = {} end
            self.tuning.lvs.bodyColor = col
            self:UpdatePreview()
        end, theme.secondary)
    end

    self:AddSection(scroll, "SKIN / TEXTURE", theme.accent)
    
    local skinPanel = vgui.Create("DPanel", scroll)
    skinPanel:Dock(TOP)
    skinPanel:SetHeight(70)
    skinPanel:DockMargin(0, 10, 0, 20)
    
    local skinValue = 0
    skinPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, theme.glass)
        
        draw.SimpleText("SKIN ID", "DermaDefault", 15, 12, theme.textMuted)
        draw.SimpleText(tostring(skinValue), "DermaLarge", w-20, h/2, theme.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        local barW = w - 80
        draw.RoundedBox(4, 15, 42, barW, 8, theme.glass)
        draw.RoundedBox(4, 15, 42, (skinValue / 10) * barW, 8, theme.accent)
    end

    local skinSlider = vgui.Create("DNumSlider", skinPanel)
    skinSlider:SetSize(320, 20)
    skinSlider:SetPos(15, 40)
    skinSlider:SetMin(0)
    skinSlider:SetMax(10)
    skinSlider:SetDecimals(0)
    skinSlider:SetValue(0)
    skinSlider.OnValueChanged = function(s, val)
        skinValue = math.floor(val)
        if not self.tuning then self.tuning = {} end
        if not self.tuning.lvs then self.tuning.lvs = {} end
        self.tuning.lvs.skin = skinValue
        self:UpdatePreview()
    end

    -- LVS Items Tuning Section
    self:AddSection(scroll, "LVS PERFORMANCE", theme.success)
    
    local lvsItems = {
        {id = "turbo", name = "TURBO LADER", price = 250, desc = "Erhoeht die Motorleistung"},
        {id = "compressor", name = "KOMPRESSOR", price = 300, desc = "Kontinuierlicher Ladedruck"},
        {id = "racingTires", name = "SPORTREIFEN", price = 150, desc = "Bessere Haftung"},
        {id = "exhaust", name = "SPORTAUSPUFF", price = 80, desc = "Backfire-Effekt"},
        {id = "gauge", name = "RACING HUD", price = 50, desc = "Digitale Anzeige"},
        {id = "manualTransmission", name = "SCHALTGETRIEBE", price = 100, desc = "Manuelles Schalten"}
    }
    
    self.lvsToggles = {}
    
    for _, item in ipairs(lvsItems) do
        local itemPanel = vgui.Create("DPanel", scroll)
        itemPanel:Dock(TOP)
        itemPanel:SetHeight(60)
        itemPanel:DockMargin(0, 5, 0, 5)
        
        local enabled = false
        
        itemPanel.Paint = function(s, w, h)
            draw.RoundedBox(8, 0, 0, w, h, enabled and Color(theme.success.r, theme.success.g, theme.success.b, 30) or theme.glass)
            surface.SetDrawColor(enabled and theme.success or theme.textMuted)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.SimpleText(item.name, "DermaDefaultBold", 15, 18, enabled and theme.success or theme.textPrimary, TEXT_ALIGN_LEFT)
            draw.SimpleText("$" .. item.price .. " - " .. item.desc, "DermaDefault", 15, 38, theme.textMuted, TEXT_ALIGN_LEFT)
            
            -- Checkbox
            local checkX = w - 35
            local checkY = h/2 - 10
            draw.RoundedBox(4, checkX, checkY, 20, 20, enabled and theme.success or theme.glass)
            if enabled then
                draw.SimpleText("✓", "DermaDefaultBold", checkX + 10, checkY + 10, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        itemPanel.OnMousePressed = function()
            enabled = not enabled
            surface.PlaySound("ui/buttonclick.wav")
            
            if not self.tuning then self.tuning = {} end
            if not self.tuning.lvs then self.tuning.lvs = {} end
            if not self.tuning.lvs.items then self.tuning.lvs.items = {} end
            
            self.tuning.lvs.items[item.id] = enabled
            self:UpdatePrice()
        end
        
        self.lvsToggles[item.id] = {panel = itemPanel, enabled = function() return enabled end}
    end

    self.pricePanel = vgui.Create("DPanel", leftPanel)
    self.pricePanel:Dock(BOTTOM)
    self.pricePanel:SetHeight(80)
    self.pricePanel:DockMargin(0, 10, 0, 0)
    self.pricePanel.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.primary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("GESAMTKOSTEN", "DermaDefault", 15, 15, theme.textMuted)
        draw.SimpleText("$0", "DermaLarge", w-15, h/2, theme.success, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local saveBtn = vgui.Create("DButton", leftPanel)
    saveBtn:Dock(BOTTOM)
    saveBtn:SetHeight(50)
    saveBtn:DockMargin(0, 10, 0, 0)
    saveBtn:SetText("")
    
    saveBtn.Paint = function(s, w, h)
        MyCarDealer.DrawGradient(0, 0, w, h, theme.primary, theme.secondary, true)
        
        if s:IsHovered() then
            surface.SetDrawColor(255, 255, 255, 30)
            surface.DrawRect(0, 0, w, h)
        end
        
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(0, 0, w, h, s:IsHovered() and 2 or 1)
        
        draw.SimpleText("TUNING SPEICHERN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    saveBtn.DoClick = function()
        self:SaveTuning()
    end

    local rightPanel = vgui.Create("DPanel", self)
    rightPanel:SetSize(460, 560)
    rightPanel:SetPos(430, 80)
    rightPanel.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("VORSCHAU", "DermaDefaultBold", w/2, 15, theme.textMuted, TEXT_ALIGN_CENTER)
    end

    self.preview = vgui.Create("DModelPanel", rightPanel)
    self.preview:SetSize(420, 480)
    self.preview:SetPos(20, 60)
    self.preview:SetFOV(50)

    self.preview.Paint = function(s, w, h)
        surface.SetDrawColor(5, 5, 10)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 15)
        for i = 0, w, 30 do surface.DrawLine(i, 0, i, h) end
        for i = 0, h, 30 do surface.DrawLine(0, i, w, i) end
        
        if self.tuning and self.tuning.neon and self.tuning.neon.enabled then
            local c = self.tuning.neon.color or theme.primary
            surface.SetDrawColor(c.r, c.g, c.b, 40)
            surface.DrawRect(0, h-100, w, 100)
            
            for i = 1, 10 do
                surface.SetDrawColor(c.r, c.g, c.b, 20 - i*2)
                surface.DrawRect(0, h-100-i*5, w, 5)
            end
        end
        
        if self.tuning and self.tuning.lvs and self.tuning.lvs.skin and self.tuning.lvs.skin > 0 then
            draw.SimpleText("SKIN " .. self.tuning.lvs.skin, "DermaDefaultBold", w-10, 10, theme.accent, TEXT_ALIGN_RIGHT)
        end
        
        if self.tuning and self.tuning.lvs and self.tuning.lvs.bodyColor then
            local c = self.tuning.lvs.bodyColor
            draw.RoundedBox(4, 10, 10, 30, 30, c)
            surface.SetDrawColor(theme.textPrimary)
            surface.DrawOutlinedRect(10, 10, 30, 30, 1)
        end

        DModelPanel.Paint(s, w, h)
    end

    self.tuning = {
        neon = {enabled = false, color = Color(157, 78, 221)},
        lvs = {bodyColor = Color(255, 255, 255), skin = 0, items = {}}
    }
end

function PANEL:AddSection(parent, title, color)
    local theme = MyCarDealer.Theme
    
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetHeight(35)
    header:DockMargin(0, 15, 0, 0)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(color.r, color.g, color.b, 30)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(color)
        surface.DrawRect(0, h-2, w, 2)
        
        draw.SimpleText(title, "DermaDefaultBold", 10, h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

function PANEL:OpenColorPicker(title, defaultColor, callback, accentColor)
    local theme = MyCarDealer.Theme
    accentColor = accentColor or theme.primary
    
    local frame = vgui.Create("DFrame")   -- Main DFrame of the ColorPicker Interface
    frame:SetSize(450, 380) -- l. h
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.3, 0)
    
    frame.Paint = function(s, w, h)
        draw.RoundedBox(16, 0, 0, w, h, theme.surface)
        surface.SetDrawColor(accentColor)    -- to be changed -- opaque/invisible? 
        surface.DrawOutlinedRect(0, 0, w/2, h, 0)
        
        -- Header
        surface.SetDrawColor(theme.elevated)
        surface.DrawRect(0, 10, w, 50)
        draw.SimpleText(title, "DermaLarge", w/2, 35, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    

    
    local mixer = vgui.Create("DColorMixer", frame) -- Color Picker itself
    mixer:SetSize(360, 200)
    mixer:SetPos(25, 70)
    mixer:SetColor(defaultColor)
    mixer:SetPalette(false)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    
    local currentColor = defaultColor
    
    -- Live Preview
    local preview = vgui.Create("DPanel", frame)
    preview:SetSize(325, 40)
    preview:SetPos(25, 275) -- color preview position
    preview.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, currentColor)
        surface.SetDrawColor(theme.textPrimary)
        surface.DrawOutlinedRect(0, 0, w, h, 0)
        draw.SimpleText("VORSCHAU", "DermaDefaultBold", w/2, h/2, Color(255-currentColor.r, 255-currentColor.g, 255-currentColor.b), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    mixer.ValueChanged = function()
        currentColor = mixer:GetColor()
    end
    
    -- Buttons
    local okBtn = vgui.Create("DButton", frame)
    okBtn:SetSize(190, 45)
    okBtn:SetPos(25, 325)
    okBtn:SetText("")
    okBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and accentColor or Color(accentColor.r-40, accentColor.g-40, accentColor.b-40))
        draw.SimpleText("UEBERNEHMEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    okBtn.DoClick = function()
        if callback then
            callback(currentColor)
        end
        frame:Remove()
    end
    
    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetSize(190, 45)
    cancelBtn:SetPos(235, 325)
    cancelBtn:SetText("")
    cancelBtn.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, s:IsHovered() and theme.error or Color(200, 50, 50))
        draw.SimpleText("ABBRECHEN", "DermaDefaultBold", w/2, h/2, theme.textPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancelBtn.DoClick = function()
        frame:Remove()
    end
end

function PANEL:SetVehicle(vehicle)
    self.vehicle = vehicle
    
    if vehicle.tuning then
        self.tuning = table.Copy(vehicle.tuning)
        if not self.tuning.neon then
            self.tuning.neon = {enabled = false, color = Color(157, 78, 221)}
        end
        if not self.tuning.lvs then
            self.tuning.lvs = {bodyColor = Color(255, 255, 255), skin = 0, items = {}}
        end
    end

    if vehicle.model and util.IsValidModel(vehicle.model) then
        self.preview:SetModel(vehicle.model)

        local mn, mx = self.preview.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), 
                             math.abs(mn.y) + math.abs(mx.y), 
                             math.abs(mn.z) + math.abs(mx.z))
        self.preview:SetCamPos(Vector(size, size, size))
        self.preview:SetLookAt((mn + mx) * 0.5)
        
        if self.tuning.lvs.skin then
            self.preview.Entity:SetSkin(self.tuning.lvs.skin)
        end
        if self.tuning.lvs.bodyColor then
            self.preview.Entity:SetColor(self.tuning.lvs.bodyColor)
        end
        
        self.preview.Think = function(s)
            if IsValid(s.Entity) then
                s.Entity:SetAngles(Angle(0, (CurTime() * 20) % 360, 0))
            end
        end
    end

    self:UpdatePrice()
end

function PANEL:UpdatePreview()
    if IsValid(self.preview.Entity) and self.tuning and self.tuning.lvs then
        self.preview.Entity:SetSkin(self.tuning.lvs.skin or 0)
        if self.tuning.lvs.bodyColor then
            self.preview.Entity:SetColor(self.tuning.lvs.bodyColor)
        end
    end
    self:UpdatePrice()
end

function PANEL:UpdatePrice()
    local theme = MyCarDealer.Theme
    local price = 0
    
    if self.tuning and self.tuning.neon and self.tuning.neon.enabled then
        price = price + (MyCarDealer.Config.NeonPrice or 500)
    end
    
    if self.tuning and self.tuning.lvs then
        -- Skin/Color Basispreis
        if self.tuning.lvs.skin and self.tuning.lvs.skin > 0 then
            price = price + 300
        end
        if self.tuning.lvs.bodyColor then
            price = price + 300
        end
        
        -- LVS Items Preise
        local itemPrices = {
            turbo = 2500,
            compressor = 3000,
            racingTires = 1500,
            exhaust = 800,
            gauge = 500,
            manualTransmission = 1000
        }
        
        if self.tuning.lvs.items then
            for itemId, enabled in pairs(self.tuning.lvs.items) do
                if enabled and itemPrices[itemId] then
                    price = price + itemPrices[itemId]
                end
            end
        end
    end

    if IsValid(self.pricePanel) then
        self.pricePanel.Paint = function(s, w, h)
            draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
            surface.SetDrawColor(theme.primary)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.SimpleText("GESAMTKOSTEN", "DermaDefault", 15, 15, theme.textMuted)
            draw.SimpleText("$" .. price, "DermaLarge", w-15, h/2, price > 0 and theme.success or theme.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

function PANEL:SaveTuning()
    if not self.vehicle then return end
    local theme = MyCarDealer.Theme

    if not self.tuning then self.tuning = {} end
    if not self.tuning.neon then self.tuning.neon = {enabled = false} end
    if not self.tuning.lvs then 
        self.tuning.lvs = {bodyColor = Color(255,255,255), skin = 0, items = {}}
    end

    net.Start("MyCarDealer_SaveTuning")
    net.WriteString(self.vehicle.id)
    net.WriteTable(self.tuning)
    net.SendToServer()

    local notif = vgui.Create("DFrame")
    notif:SetSize(300, 80)
    notif:Center()
    notif:SetTitle("")
    notif:ShowCloseButton(false)
    notif:MakePopup()
    notif:SetAlpha(0)
    
    notif.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.success)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText("✓", "DermaLarge", 40, h/2, theme.success, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Tuning gespeichert!", "DermaDefaultBold", 70, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    notif:AlphaTo(255, 0.2, 0, function()
        timer.Simple(1.5, function()
            if IsValid(notif) then
                notif:AlphaTo(0, 0.3, 0, function() notif:Remove() end)
            end
        end)
    end)

    self:Remove()
end

vgui.Register("MyCarDealer_Tuning", PANEL, "DFrame")

print("[Dynora Motor´s] cl_tuning.lua loaded (Patch 1.1 Tuning Color Picker Überarbeitung)")
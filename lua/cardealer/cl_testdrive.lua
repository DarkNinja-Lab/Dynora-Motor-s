function MyCarDealer.StartTestDrive(vehicleID)
    net.Start("MyCarDealer_StartTestDrive")
    net.WriteString(vehicleID)
    net.SendToServer()
end


local testDriveActive = false
local testDriveEndTime = 0

net.Receive("MyCarDealer_TestDriveStart", function()
    local timeLimit = net.ReadUInt(16)
    testDriveActive = true
    testDriveEndTime = CurTime() + timeLimit
    
    local theme = MyCarDealer.Theme
    
    local notif = vgui.Create("DFrame")
    notif:SetSize(400, 100)
    notif:Center()
    notif:SetTitle("")
    notif:ShowCloseButton(false)
    notif:MakePopup()
    notif:SetAlpha(0)
    
    notif.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.secondary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText(">>", "DermaLarge", 30, h/2, theme.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("TESTFAHRT GESTARTET", "DermaDefaultBold", 60, 35, theme.textPrimary, TEXT_ALIGN_LEFT)
        draw.SimpleText(timeLimit .. " Sekunden verbleibend", "DermaDefault", 60, 60, theme.textMuted, TEXT_ALIGN_LEFT)
    end
    
    notif:AlphaTo(255, 0.3, 0, function()
        timer.Simple(3, function()
            if IsValid(notif) then
                notif:AlphaTo(0, 0.3, 0, function() notif:Remove() end)
            end
        end)
    end)
end)

net.Receive("MyCarDealer_TestDriveEnd", function()
    testDriveActive = false
    
    local theme = MyCarDealer.Theme
    
    local notif = vgui.Create("DFrame")
    notif:SetSize(350, 80)
    notif:Center()
    notif:SetTitle("")
    notif:ShowCloseButton(false)
    notif:MakePopup()
    notif:SetAlpha(0)
    
    notif.Paint = function(s, w, h)
        draw.RoundedBox(12, 0, 0, w, h, theme.elevated)
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        draw.SimpleText("!", "DermaLarge", 30, h/2, theme.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("TESTFAHRT BEENDET", "DermaDefaultBold", 60, h/2, theme.textPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    notif:AlphaTo(255, 0.3, 0, function()
        timer.Simple(2, function()
            if IsValid(notif) then
                notif:AlphaTo(0, 0.3, 0, function() notif:Remove() end)
            end
        end)
    end)
end)

hook.Add("HUDPaint", "MyCarDealer_TestDriveHUD", function()
    if not testDriveActive then return end
    
    local timeLeft = math.max(0, testDriveEndTime - CurTime())
    if timeLeft <= 0 then
        testDriveActive = false
        return
    end
    
    local theme = MyCarDealer.Theme
    local w, h = ScrW(), ScrH()
    
    surface.SetDrawColor(10, 10, 15, 200)
    surface.DrawRect(w/2 - 150, 30, 300, 50)
    
    surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 100)
    surface.DrawOutlinedRect(w/2 - 150, 30, 300, 50, 2)
    
    local progress = timeLeft / (MyCarDealer.Config.TestDriveTime or 60)
    surface.SetDrawColor(theme.secondary.r, theme.secondary.g, theme.secondary.b, 80)
    surface.DrawRect(w/2 - 145, 35, 290 * progress, 40)
    
    draw.SimpleText("TESTFAHRT", "DermaDefaultBold", w/2, 45, theme.textPrimary, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.ceil(timeLeft) .. "s", "DermaDefault", w/2, 62, theme.textSecondary, TEXT_ALIGN_CENTER)
    
    if timeLeft <= 10 then
        local pulse = math.sin(CurTime() * 10) * 0.5 + 0.5
        surface.SetDrawColor(theme.error.r, theme.error.g, theme.error.b, 100 * pulse)
        surface.DrawOutlinedRect(w/2 - 152, 28, 304, 54, 3)
    end
end)
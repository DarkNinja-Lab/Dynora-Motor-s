-- Chat Commands fuer Dynora CarDealer
-- Keine Console mehr noetig!

hook.Add("OnPlayerChat", "MyCarDealer_ChatCommands", function(ply, text, teamChat, isDead)
    if ply ~= LocalPlayer() then return end
    
    text = string.lower(text)
    
    -- Admin Menu
    if text == "!cardealer_admin" or text == "!cd_admin" or text == "/cardealer_admin" or text == "/cd_admin" then
        if MyCarDealer.IsAdmin(LocalPlayer()) then
            vgui.Create("MyCarDealer_Admin")
            chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(0, 255, 150), "Admin Menu geoeffnet")
        else
            chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(255, 80, 100), "Keine Berechtigung!")
        end
        return true -- Verhindert dass der Chat gesendet wird
    end
    
    -- Force Admin (SuperAdmin only)
    if text == "!cardealer_force" or text == "/cardealer_force" then
        if LocalPlayer():IsSuperAdmin() then
            vgui.Create("MyCarDealer_Admin")
            chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(0, 255, 150), "Admin Menu (FORCE) geoeffnet")
        end
        return true
    end
    
    -- Hauptmenue
    if text == "!cardealer" or text == "!cd" or text == "/cardealer" or text == "/cd" then
        vgui.Create("MyCarDealer_Menu")
        chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(0, 255, 150), "Hauptmenu geoeffnet")
        return true
    end
    
    -- Garage
    if text == "!garage" or text == "!cd_garage" or text == "/garage" or text == "/cd_garage" then
        vgui.Create("MyCarDealer_Inventory")
        chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(0, 255, 150), "Garage geoeffnet")
        return true
    end
    
    -- Einparken
    if text == "!store" or text == "!einparken" or text == "/store" or text == "/einparken" then
        if IsValid(LocalPlayer().MyCarDealer_Vehicle) then
            net.Start("MyCarDealer_GlobalStore")
            net.SendToServer()
            chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(0, 255, 150), "Fahrzeug wird eingeparkt...")
        else
            chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(255, 200, 50), "Kein aktives Fahrzeug!")
        end
        return true
    end
    
    -- Hilfe
    if text == "!cardealer_help" or text == "!cd_help" or text == "/cardealer_help" or text == "/cd_help" then
        chat.AddText(Color(157, 78, 221), "[Dynora Motor's] ", Color(255, 255, 255), "=== BEFEHLE ===")
        chat.AddText(Color(255, 255, 255), "!cardealer / !cd", Color(200, 200, 200), " - Hauptmenu oeffnen")
        chat.AddText(Color(255, 255, 255), "!garage", Color(200, 200, 200), " - Garage oeffnen")
        chat.AddText(Color(255, 255, 255), "!store / !einparken", Color(200, 200, 200), " - Fahrzeug einparken")
        chat.AddText(Color(255, 255, 255), "!cardealer_admin / !cd_admin", Color(200, 200, 200), " - Admin Menu (Admins)")
        return true
    end
end)

print("[Dynora Motor´s] Chat commands active!")
-- EINFACHES EINPARKEN: F2 drücken während im Fahrzeug = sofort einparken
hook.Add("PlayerBindPress", "MyCarDealer_SimpleStore", function(ply, bind, pressed)
    if not pressed then return end

    -- F2 oder +showscores (Tab) zum Einparken
    if bind == "gm_showspare2" or bind == "+showscores" then
        if IsValid(ply.MyCarDealer_Vehicle) then
            -- Sofort einparken ohne Bestätigung
            net.Start("MyCarDealer_GlobalStore")
            net.SendToServer()
            
            -- Sound + visuelles Feedback
            surface.PlaySound("buttons/button14.wav")
            
            -- Kurze Notification
            notification.AddLegacy("Fahrzeug wird eingeparkt...", NOTIFY_HINT, 2)
            
            return true -- Blockiert das normale Menü
        end
    end
end)

-- Alternative: F1 zum Öffnen des Hauptmenüs
hook.Add("PlayerBindPress", "MyCarDealer_OpenMenuBind", function(ply, bind, pressed)
    if not pressed then return end
    
    if bind == "gm_showhelp" then -- F1
        -- Nur wenn nicht im Fahrzeug
        if not IsValid(ply.MyCarDealer_Vehicle) then
            vgui.Create("MyCarDealer_Menu")
            return true
        end
    end
end)

print("[Dynora Motor´s] cl_binds.lua loaded")
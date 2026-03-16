-- ============================================
-- NPC SPAWNPOINT VISUALISIERUNG (Admin Only)
-- ============================================

local npcSpawnPoints = {}
local showAllPoints = false

-- Net Messages empfangen
net.Receive("MyCarDealer_SetNPCSpawnPoint", function()
    local npcType = net.ReadString()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local name = net.ReadString()
    local color = net.ReadColor()
    
    npcSpawnPoints[npcType] = {
        pos = pos,
        ang = ang,
        name = name,
        color = color,
        time = CurTime()
    }
end)

net.Receive("MyCarDealer_ShowAllSpawnPoints", function()
    showAllPoints = true
    -- Auto-hide nach 30 Sekunden
    timer.Simple(30, function()
        showAllPoints = false
    end)
end)

-- 3D2D Drawing für Labels
hook.Add("PostDrawTranslucentRenderables", "MyCarDealer_NPCSpawnPoints", function()
    if not showAllPoints and table.IsEmpty(npcSpawnPoints) then return end
    if not MyCarDealer.IsAdmin(LocalPlayer()) then return end
    
    local lp = LocalPlayer()
    local time = CurTime()
    
    for npcType, data in pairs(npcSpawnPoints) do
        if not data.pos then continue end
        
        local pos = data.pos
        local dist = lp:GetPos():Distance(pos)
        
        -- Nur zeigen wenn in Reichweite (oder Admin will alle sehen)
        if dist > 2000 and not showAllPoints then continue end
        
        local alpha = math.Clamp(255 - (dist / 2000) * 155, 100, 255)
        local color = data.color or Color(255, 255, 255)
        
        -- Pulsierender Ring am Boden
        local pulse = math.sin(time * 3) * 10
        local radius = 60 + pulse
        
        render.SetColorMaterial()
        
        -- Kreis zeichnen
        local segments = 32
        for i = 0, segments - 1 do
            local ang1 = (i / segments) * math.pi * 2
            local ang2 = ((i + 1) / segments) * math.pi * 2
            
            local x1 = pos.x + math.cos(ang1) * radius
            local y1 = pos.y + math.sin(ang1) * radius
            local x2 = pos.x + math.cos(ang2) * radius
            local y2 = pos.y + math.sin(ang2) * radius
            
            -- Gefüllter Kreis (translucent)
            render.DrawQuad(
                Vector(x1, y1, pos.z + 2),
                Vector(x2, y2, pos.z + 2),
                pos + Vector(0, 0, 2),
                pos + Vector(0, 0, 2),
                Color(color.r, color.g, color.b, 30)
            )
            
            -- Linie
            render.DrawLine(
                Vector(x1, y1, pos.z + 2),
                Vector(x2, y2, pos.z + 2),
                Color(color.r, color.g, color.b, alpha),
                3
            )
        end
        
        -- Vertikale Linie nach oben
        render.DrawLine(pos + Vector(0, 0, 0), pos + Vector(0, 0, 100), Color(color.r, color.g, color.b, alpha), 4)
        
        -- Spitze oben
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(-10, 0, 90), Color(color.r, color.g, color.b, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(10, 0, 90), Color(color.r, color.g, color.b, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(0, -10, 90), Color(color.r, color.g, color.b, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(0, 10, 90), Color(color.r, color.g, color.b, alpha), 2)
        
        -- 3D2D Label
        local ang = Angle(0, lp:EyeAngles().yaw - 90, 90)
        cam.Start3D2D(pos + Vector(0, 0, 120), ang, 0.1)
            
            -- Hintergrund
            local text = "[ " .. (data.name or npcType) .. " ]"
            surface.SetFont("DermaDefaultBold")
            local textW, textH = surface.GetTextSize(text)
            local boxW = math.max(textW + 30, 180)
            local boxH = 70
            
            draw.RoundedBox(12, -boxW/2, -boxH/2, boxW, boxH, Color(0, 0, 0, math.Clamp(alpha, 0, 200)))
            surface.SetDrawColor(color.r, color.g, color.b, alpha)
            surface.DrawOutlinedRect(-boxW/2, -boxH/2, boxW, boxH, 2)
            
            -- Icon/Badge
            draw.RoundedBox(6, -boxW/2 + 10, -boxH/2 + 15, 20, 20, color)
            
            -- Text
            draw.SimpleText(text, "DermaDefaultBold", 0, -5, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
            draw.SimpleText("Fahrzeug-Spawnpunkt", "DermaDefault", 0, 15, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER)
            draw.SimpleText(math.floor(dist) .. "m", "DermaDefault", 0, 30, Color(150, 150, 150, alpha), TEXT_ALIGN_CENTER)
            
        cam.End3D2D()
    end
end)

-- Halo-Effekt für Admins (leuchtender Umriss)
hook.Add("PreDrawHalos", "MyCarDealer_NPCSpawnHalos", function()
    if not showAllPoints then return end
    if not MyCarDealer.IsAdmin(LocalPlayer()) then return end
    
    local halos = {}
    
    for npcType, data in pairs(npcSpawnPoints) do
        if data.pos then
            -- Erstelle ein temporäres Entity für den Halo (oder nutze Debug-Visualisierung)
            -- Da wir kein echtes Entity haben, zeichnen wir manuell
        end
    end
end)

-- ConCommand zum Umschalten
concommand.Add("cardealer_showspawnpoints", function()
    showAllPoints = not showAllPoints
    chat.AddText(Color(157, 78, 221), "[Dynora Motor´s] ", Color(255, 255, 255), 
        showAllPoints and "Spawnpunkte werden angezeigt (30s)" or "Spawnpunkte ausgeblendet")
end)

print("[Dynora Motor´s] NPC Spawnpoint Visualizer loaded")
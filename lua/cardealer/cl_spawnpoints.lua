local spawnPoints = {}
local pointLifetime = 5

net.Receive("MyCarDealer_DrawSpawnPoint", function()
    local pos = net.ReadVector()
    local name = net.ReadString()
    local id = net.ReadUInt(16)
    
    table.insert(spawnPoints, {
        pos = pos, 
        name = name, 
        id = id,
        time = CurTime(),
        alpha = 255
    })
end)


timer.Create("MyCarDealer_CleanupSpawns", 1, 0, function()
    local time = CurTime()
    for i = #spawnPoints, 1, -1 do
        if time - spawnPoints[i].time > pointLifetime then
            table.remove(spawnPoints, i)
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "MyCarDealer_DrawSpawnPoints", function()
    if #spawnPoints == 0 then return end
    
    local time = CurTime()
    local viewPos = LocalPlayer():GetPos()
    
    for _, spawn in ipairs(spawnPoints) do
        local age = time - spawn.time
        if age > pointLifetime then continue end
        
        local pos = spawn.pos
        local pulse = math.sin(time * 4) * 8
        

        local dist = viewPos:Distance(pos)
        local maxDist = 1000
        local alpha = math.Clamp(255 * (1 - dist / maxDist), 100, 255)
        

        render.SetColorMaterial()
        
        local segments = 32
        local radius = 50 + pulse
        

        for i = 0, segments - 1 do
            local ang1 = (i / segments) * math.pi * 2
            local ang2 = ((i + 1) / segments) * math.pi * 2
            
            local x1 = pos.x + math.cos(ang1) * radius
            local y1 = pos.y + math.sin(ang1) * radius
            local x2 = pos.x + math.cos(ang2) * radius
            local y2 = pos.y + math.sin(ang2) * radius
            
            render.DrawQuad(
                Vector(x1, y1, pos.z + 2),
                Vector(x2, y2, pos.z + 2),
                pos + Vector(0, 0, 2),
                pos + Vector(0, 0, 2),
                Color(255, 215, 0, alpha * 0.3)
            )
        end
        

        for i = 0, segments - 1 do
            local ang1 = (i / segments) * math.pi * 2
            local ang2 = ((i + 1) / segments) * math.pi * 2
            
            local x1 = pos.x + math.cos(ang1) * radius
            local y1 = pos.y + math.sin(ang1) * radius
            local x2 = pos.x + math.cos(ang2) * radius
            local y2 = pos.y + math.sin(ang2) * radius
            
            render.DrawLine(
                Vector(x1, y1, pos.z + 2),
                Vector(x2, y2, pos.z + 2),
                Color(255, 215, 0, alpha),
                3
            )
        end
        

        render.DrawLine(pos + Vector(0, 0, 0), pos + Vector(0, 0, 100), Color(255, 215, 0, alpha), 4)

            
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(-10, 0, 90), Color(255, 215, 0, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(10, 0, 90), Color(255, 215, 0, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(0, -10, 90), Color(255, 215, 0, alpha), 2)
        render.DrawLine(pos + Vector(0, 0, 100), pos + Vector(0, 10, 90), Color(255, 215, 0, alpha), 2)

            
        local ang = Angle(0, LocalPlayer():EyeAngles().yaw - 90, 90)
        cam.Start3D2D(pos + Vector(0, 0, 120), ang, 0.12)
        
            surface.SetFont("DermaDefaultBold")
            local textW, textH = surface.GetTextSize(spawn.name)
            local boxW = math.max(textW + 20, 140)
            local boxH = 50
            
            draw.RoundedBox(8, -boxW/2, -boxH/2, boxW, boxH, Color(0, 0, 0, math.Clamp(alpha, 0, 200)))
            surface.SetDrawColor(255, 215, 0, alpha)
            surface.DrawOutlinedRect(-boxW/2, -boxH/2, boxW, boxH, 2)
            
        
            draw.SimpleText("SPAWN " .. spawn.id, "DermaDefault", 0, -8, Color(255, 215, 0, alpha), TEXT_ALIGN_CENTER)
            draw.SimpleText(spawn.name, "DermaDefaultBold", 0, 8, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end)
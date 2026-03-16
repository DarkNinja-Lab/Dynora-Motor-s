-- cardealer/sv_spawnpoints.lua
-- Spawnpoint Management System für Dynora CarDealer

util.AddNetworkString("MyCarDealer_DrawSpawnPoint")
util.AddNetworkString("MyCarDealer_SyncSpawnPoints")

MyCarDealer.SpawnPoints = MyCarDealer.SpawnPoints or {}

-- Konfiguration
MyCarDealer.SpawnPointConfig = {
    MinDistanceBetweenPoints = 500,    -- Mindestabstand zwischen Spawnpoints
    MaxDistanceFromDealer = 2000,      -- Max Entfernung vom Händler
    DefaultSpawnName = "Standard Spawn",
    MaxAttempts = 10                     -- KORRIGIERT: Maximale Versuche
}

--[[
    HILFSFUNKTIONEN
]]

function MyCarDealer.LoadSpawnPoints()
    -- Lade aus Datei oder erstelle Default
    local points = {}
    
    -- Versuche aus data/cardealer/spawnpoints.txt zu laden
    local filePath = "cardealer/spawnpoints.txt"
    if file.Exists(filePath, "DATA") then
        local content = file.Read(filePath, "DATA")
        if content then
            local loaded = util.JSONToTable(content)
            if loaded and istable(loaded) then
                points = loaded
                print("[MyCarDealer] Loaded " .. #points .. " spawnpoints from file")
            end
        end
    end
    
    MyCarDealer.SpawnPoints = points
    return points
end

function MyCarDealer.SaveSpawnPoints()
    local filePath = "cardealer/spawnpoints.txt"
    
    -- Erstelle Ordner falls nicht vorhanden
    if not file.Exists("cardealer", "DATA") then
        file.CreateDir("cardealer")
    end
    
    local content = util.TableToJSON(MyCarDealer.SpawnPoints, true)
    file.Write(filePath, content)
    
    print("[MyCarDealer] Saved " .. #MyCarDealer.SpawnPoints .. " spawnpoints to file")
end

function MyCarDealer.AddSpawnPoint(pos, ang, name)
    -- Prüfe Mindestabstand zu anderen Points
    for _, point in ipairs(MyCarDealer.SpawnPoints) do
        if point.pos:Distance(pos) < MyCarDealer.SpawnPointConfig.MinDistanceBetweenPoints then
            return false, "Zu nah an existierendem Spawnpoint (" .. math.floor(point.pos:Distance(pos)) .. "m)"
        end
    end
    
    -- Prüfe ob Position gültig ist
    local trace = util.TraceLine({
        start = pos + Vector(0, 0, 50),
        endpos = pos - Vector(0, 0, 100),
        mask = MASK_SOLID
    })
    
    if not trace.Hit then
        return false, "Kein Boden gefunden unter Position"
    end
    
    -- Erstelle neuen Point
    local newPoint = {
        id = #MyCarDealer.SpawnPoints + 1,
        pos = trace.HitPos + Vector(0, 0, 10), -- Leicht über Boden
        ang = ang or Angle(0, 0, 0),
        name = name or (MyCarDealer.SpawnPointConfig.DefaultSpawnName .. " " .. (#MyCarDealer.SpawnPoints + 1))
    }
    
    table.insert(MyCarDealer.SpawnPoints, newPoint)
    MyCarDealer.SaveSpawnPoints()
    
    -- Informiere alle Admins
    for _, ply in ipairs(player.GetAll()) do
        if MyCarDealer.IsAdmin(ply) then
            MyCarDealer.ChatPrint(ply, "Spawnpoint #" .. newPoint.id .. " hinzugefügt: " .. newPoint.name)
        end
    end
    
    return true, newPoint
end

function MyCarDealer.RemoveSpawnPoint(id)
    if not MyCarDealer.SpawnPoints[id] then
        return false, "Spawnpoint #" .. id .. " existiert nicht"
    end
    
    local name = MyCarDealer.SpawnPoints[id].name
    table.remove(MyCarDealer.SpawnPoints, id)
    
    -- IDs neu zuweisen
    for i, point in ipairs(MyCarDealer.SpawnPoints) do
        point.id = i
    end
    
    MyCarDealer.SaveSpawnPoints()
    
    return true, "Spawnpoint #" .. id .. " (" .. name .. ") entfernt"
end

-- ============================================
-- KORRIGIERT: GetRandomSpawnPoint mit Safety-Checks
-- ============================================
function MyCarDealer.GetRandomSpawnPoint(attempts)
    attempts = attempts or 0
    
    -- Schutz gegen Endlosschleife
    if attempts > MyCarDealer.SpawnPointConfig.MaxAttempts then
        print("[MyCarDealer] WARNING: Max spawn attempts reached, using fallback")
        return nil
    end
    
    if #MyCarDealer.SpawnPoints == 0 then
        return nil
    end
    
    -- Wähle zufälligen Point
    local point = MyCarDealer.SpawnPoints[math.random(1, #MyCarDealer.SpawnPoints)]
    
    if not point or not point.pos then
        return MyCarDealer.GetRandomSpawnPoint(attempts + 1)
    end
    
    -- Prüfe ob frei
    local entitiesNear = ents.FindInSphere(point.pos, 200)
    for _, ent in ipairs(entitiesNear) do
        if IsValid(ent) and (ent:IsVehicle() or ent:IsPlayer()) then
            -- Position besetzt, suche anderen (rekursiv mit Zähler)
            return MyCarDealer.GetRandomSpawnPoint(attempts + 1)
        end
    end
    
    return point
end

function MyCarDealer.GetNearestSpawnPoint(pos)
    if #MyCarDealer.SpawnPoints == 0 then
        return nil
    end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, point in ipairs(MyCarDealer.SpawnPoints) do
        if point and point.pos then
            local dist = point.pos:Distance(pos)
            if dist < nearestDist then
                nearestDist = dist
                nearest = point
            end
        end
    end
    
    return nearest
end

-- ============================================
-- KORRIGIERT: SpawnVehicleAtPoint mit besserer Fehlerbehandlung
-- ============================================
function MyCarDealer.SpawnVehicleAtPoint(ply, vehicle_id)
    if not IsValid(ply) then return false end
    
    -- Prüfe ob Spawnpoints existieren
    if not MyCarDealer.SpawnPoints or #MyCarDealer.SpawnPoints == 0 then
        -- Keine Spawnpoints vorhanden, nutze Standard-Position
        print("[MyCarDealer] No spawnpoints found, using fallback spawn")
        MyCarDealer.SpawnVehicle(ply, vehicle_id)
        return true
    end
    
    local point = MyCarDealer.GetRandomSpawnPoint()
    
    if not point then
        -- Alle Spawnpoints besetzt oder Fehler
        print("[MyCarDealer] All spawnpoints occupied or error, using fallback")
        MyCarDealer.SpawnVehicle(ply, vehicle_id)
        return true
    end
    
    -- Spawn mit expliziter Position
    MyCarDealer.SpawnVehicle(ply, vehicle_id, point.pos, point.ang)
    
    -- Zeige Spawnpoint an
    net.Start("MyCarDealer_DrawSpawnPoint")
    net.WriteVector(point.pos)
    net.WriteString(point.name or "Spawn")
    net.WriteUInt(point.id or 1, 16)
    net.Send(ply)
    
    MyCarDealer.ChatPrint(ply, "Fahrzeug gespawnt bei: " .. (point.name or "Spawn"))
    return true
end

function MyCarDealer.ShowSpawnPointEffect(pos, name, id)
    if not pos then return end
    
    -- Sende an alle Spieler in der Nähe
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPos():Distance(pos) < 2000 then
            net.Start("MyCarDealer_DrawSpawnPoint")
            net.WriteVector(pos)
            net.WriteString(name or "Spawn")
            net.WriteUInt(id or 1, 16)
            net.Send(ply)
        end
    end
end

--[[
    CONSOLE COMMANDS
]]

concommand.Add("cardealer_addspawn", function(ply, cmd, args)
    if not IsValid(ply) then 
        print("[CarDealer] Muss als Spieler ausgeführt werden!")
        return 
    end
    
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    local name = args[1] or "Spawnpoint"
    local pos = ply:GetPos()
    local ang = Angle(0, ply:GetAngles().yaw, 0)
    
    local success, result = MyCarDealer.AddSpawnPoint(pos, ang, name)
    
    if success then
        MyCarDealer.ShowSpawnPointEffect(result.pos, result.name, result.id)
        MyCarDealer.ChatPrint(ply, "OK: " .. result.name .. " hinzugefügt!")
    else
        MyCarDealer.ChatPrint(ply, "FEHLER: " .. result)
    end
end)

concommand.Add("cardealer_removespawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    local id = tonumber(args[1])
    if not id then
        MyCarDealer.ChatPrint(ply, "Usage: cardealer_removespawn <id>")
        return
    end
    
    local success, result = MyCarDealer.RemoveSpawnPoint(id)
    MyCarDealer.ChatPrint(ply, (success and "OK: " or "FEHLER: ") .. result)
end)

concommand.Add("cardealer_listspawns", function(ply, cmd, args)
    if not IsValid(ply) then 
        -- Server-Konsole
        print("[MyCarDealer] Spawnpoints:")
        for _, point in ipairs(MyCarDealer.SpawnPoints or {}) do
            if point then
                print("  #" .. (point.id or "?") .. ": " .. (point.name or "Unnamed") .. " at " .. tostring(point.pos))
            end
        end
        return
    end
    
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    MyCarDealer.ChatPrint(ply, "=== SPAWNPOINTS ===")
    if #MyCarDealer.SpawnPoints == 0 then
        MyCarDealer.ChatPrint(ply, "Keine Spawnpoints vorhanden!")
        return
    end
    
    for _, point in ipairs(MyCarDealer.SpawnPoints) do
        if point and point.pos then
            local dist = math.floor(ply:GetPos():Distance(point.pos))
            MyCarDealer.ChatPrint(ply, "#" .. (point.id or "?") .. ": " .. (point.name or "Unnamed") .. " (" .. dist .. "m entfernt)")
        end
    end
end)

concommand.Add("cardealer_nearestspawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local nearest = MyCarDealer.GetNearestSpawnPoint(ply:GetPos())
    if nearest then
        local dist = math.floor(ply:GetPos():Distance(nearest.pos))
        MyCarDealer.ChatPrint(ply, "Nächster Spawnpoint: #" .. (nearest.id or "?") .. " " .. (nearest.name or "Unnamed") .. " (" .. dist .. "m)")
        
        -- Zeige Effekt
        MyCarDealer.ShowSpawnPointEffect(nearest.pos, nearest.name, nearest.id)
    else
        MyCarDealer.ChatPrint(ply, "Keine Spawnpoints vorhanden!")
    end
end)

concommand.Add("cardealer_teleportspawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    local id = tonumber(args[1])
    if not id or not MyCarDealer.SpawnPoints[id] then
        MyCarDealer.ChatPrint(ply, "Ungültige ID! Usage: cardealer_teleportspawn <id>")
        return
    end
    
    local point = MyCarDealer.SpawnPoints[id]
    if point and point.pos then
        ply:SetPos(point.pos + Vector(0, 0, 50))
        if point.ang then
            ply:SetEyeAngles(point.ang)
        end
        MyCarDealer.ChatPrint(ply, "Teleportiert zu Spawnpoint #" .. id)
    end
end)

--[[
    INITIALISIERUNG
]]

hook.Add("Initialize", "MyCarDealer_LoadSpawnPoints", function()
    timer.Simple(1, function()
        MyCarDealer.LoadSpawnPoints()
    end)
end)

print("[Dynora Motor´s] Spawnpoints module loaded")
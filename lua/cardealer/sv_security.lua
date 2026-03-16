function MyCarDealer.CheckCooldown(ply, action, seconds)
    if not IsValid(ply) then return false end
    
    ply.CD_Cooldowns = ply.CD_Cooldowns or {}
    local lastAction = ply.CD_Cooldowns[action] or 0
    local timeDiff = CurTime() - lastAction
    
    if timeDiff < seconds then
        local remaining = math.ceil(seconds - timeDiff)
        MyCarDealer.ChatPrint(ply, "Warte " .. remaining .. " Sekunden...")
        return false
    end
    
    ply.CD_Cooldowns[action] = CurTime()
    return true
end

function MyCarDealer.ValidateString(str, maxLen, pattern)
    if not isstring(str) then return false end
    if #str > maxLen then return false end
    if pattern and not str:match(pattern) then return false end
    return true
end

function MyCarDealer.ValidateVehicleID(id)
    if not MyCarDealer.ValidateString(id, 64, "^[%w_%-]+$") then return false end
    
    -- Nutze Cache falls verfügbar
    if MyCarDealer.VehicleCache and MyCarDealer.VehicleCache[id] then
        return true, MyCarDealer.VehicleCache[id]
    end
    
    -- Fallback auf Loop
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == id then return true, v end
    end
    return false
end

function MyCarDealer.ValidatePrice(price)
    price = tonumber(price)
    if not price then return false end
    if price < 1 then return false end
    if price > 100000000 then return false end -- Max 100M
    return true, price
end

function MyCarDealer.SafeQuery(queryTemplate, params)
    local query = queryTemplate
    
    for key, value in pairs(params) do
        local safeValue = sql.SQLStr(tostring(value))
        query = query:gsub("{" .. key .. "}", safeValue)
    end
    
    local result = sql.Query(query)
    
    if result == false then
        print("[MyCarDealer] SQL Error: " .. sql.LastError())
        print("[MyCarDealer] Query: " .. query)
        return nil, sql.LastError()
    end
    
    return result
end

-- SAM Permission Support + Fallback
function MyCarDealer.IsAdmin(ply)
    if not IsValid(ply) then return false end
    
    -- SAM Permission Check (falls SAM installiert)
    if sam and sam.player and sam.player.HasPermission then
        -- Prüfe spezifische CarDealer Admin Permission
        if sam.player.HasPermission(ply, "cardealer_admin") then
            return true
        end
        -- Prüfe auch auf superadmin/admin Permission als Fallback
        if sam.player.HasPermission(ply, "manage_cardealer") then
            return true
        end
    end
    
    -- Fallback: Standard UserGroup Check
    local userGroup = ply:GetUserGroup()
    return userGroup == "admin" or userGroup == "superadmin" or userGroup == "owner" or userGroup == "developer"
end

-- SAM Permission Registration (Server-seitig)
hook.Add("Initialize", "MyCarDealer_SAM_Permissions", function()
    -- Registriere SAM Permissions falls SAM vorhanden
    if sam and sam.permissions and sam.permissions.add then
        -- Haupt-Admin Permission
        sam.permissions.add("cardealer_admin", "CarDealer Admin", "Erlaubt vollen Zugriff auf das CarDealer Admin-Menü und alle Funktionen")
        
        -- Management Permission (für Moderatoren)
        sam.permissions.add("manage_cardealer", "CarDealer Verwaltung", "Erlaubt Verwaltung von Fahrzeugen (geben/entfernen)")
        
        -- Spawn Permission (für Support)
        sam.permissions.add("cardealer_spawn", "CarDealer Spawning", "Erlaubt Spawnen von CarDealer Fahrzeugen")
        
        print("[MyCarDealer] SAM Permissions registriert:")
        print("  - cardealer_admin (Admin-Menü)")
        print("  - manage_cardealer (Fahrzeug-Verwaltung)")
        print("  - cardealer_spawn (Fahrzeug-Spawn)")
    else
        print("[MyCarDealer] SAM nicht gefunden - nutze Fallback Admin-Check")
    end
end)

-- VERBESSERT: Logging mit mehr Details und In-Memory Speicher
MyCarDealer.Logs = MyCarDealer.Logs or {}
MyCarDealer.MaxLogs = 100

function MyCarDealer.AddLog(action, ply, details)
    table.insert(MyCarDealer.Logs, 1, {
        time = os.date("%Y-%m-%d %H:%M:%S"),
        action = action,
        player = IsValid(ply) and ply:Nick() or "Server",
        steamid = IsValid(ply) and ply:SteamID() or "N/A",
        details = details
    })
    
    -- Max Logs begrenzen
    if #MyCarDealer.Logs > MyCarDealer.MaxLogs then
        table.remove(MyCarDealer.Logs)
    end
end

-- Ersetze die alte Log Funktion:
function MyCarDealer.Log(action, ply, details)
    MyCarDealer.AddLog(action, ply, details)
    
    -- Auch in Datei loggen
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logStr = string.format("[%s] %s | %s: %s\n", 
        timestamp, action, IsValid(ply) and ply:Nick() or "Server", details or "")
    
    if not file.Exists("cardealer", "DATA") then
        file.CreateDir("cardealer")
    end
    file.Append("cardealer/logs.txt", logStr)
    
    -- Auch in Konsole
    print("[MyCarDealer] " .. logStr)
end

-- Chat Print mit Lila Prefix
function MyCarDealer.ChatPrint(ply, text)
    if not IsValid(ply) then return end
    ply:ChatPrint("[Dynora Motor's] " .. text)
end

print("[Dynora Motor´s] sv_security.lua loaded")
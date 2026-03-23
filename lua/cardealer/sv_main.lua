util.AddNetworkString("MyCarDealer_OpenGarageMenu")
util.AddNetworkString("MyCarDealer_OpenMenu")
util.AddNetworkString("MyCarDealer_Buy")
util.AddNetworkString("MyCarDealer_Spawn")
util.AddNetworkString("MyCarDealer_Store")
util.AddNetworkString("MyCarDealer_Sell")
util.AddNetworkString("MyCarDealer_Return")
util.AddNetworkString("MyCarDealer_SyncInventory")
util.AddNetworkString("MyCarDealer_AdminSpawn")
util.AddNetworkString("MyCarDealer_AdminGive")
util.AddNetworkString("MyCarDealer_AdminRemove")
util.AddNetworkString("MyCarDealer_OpenPoliceMenu")
util.AddNetworkString("MyCarDealer_GlobalStore")
util.AddNetworkString("MyCarDealer_StartTestDrive")
util.AddNetworkString("MyCarDealer_OpenAdminMenu")
util.AddNetworkString("MyCarDealer_SetNPCSpawnPoint")
util.AddNetworkString("MyCarDealer_ShowAllSpawnPoints")
util.AddNetworkString("MyCarDealer_SetNPCType")
util.AddNetworkString("MyCarDealer_StoreEffect")

-- Vehicle Cache
MyCarDealer.VehicleCache = MyCarDealer.VehicleCache or {}
MyCarDealer.VehicleCacheByModel = MyCarDealer.VehicleCacheByModel or {}

function MyCarDealer.RebuildVehicleCache()
    MyCarDealer.VehicleCache = {}
    MyCarDealer.VehicleCacheByModel = {}
    
    for _, v in ipairs(MyCarDealer.Vehicles or {}) do
        MyCarDealer.VehicleCache[v.id] = v
        if v.model then
            MyCarDealer.VehicleCacheByModel[v.model] = v
        end
    end
    
    print("[Dynora Motor´s] Vehicle cache rebuilt: " .. table.Count(MyCarDealer.VehicleCache) .. " vehicles cached")
end

hook.Add("Initialize", "MyCarDealer_BuildCache", function()
    timer.Simple(2, MyCarDealer.RebuildVehicleCache)
end)

function MyCarDealer.GetVehicleByID(id)
    return MyCarDealer.VehicleCache[id]
end

function MyCarDealer.GetVehicleByModel(model)
    return MyCarDealer.VehicleCacheByModel[model]
end

-- Rate Limiting
MyCarDealer.RateLimits = MyCarDealer.RateLimits or {}

function MyCarDealer.CheckRateLimit(ply, action, baseSeconds)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID64()
    MyCarDealer.RateLimits[steamID] = MyCarDealer.RateLimits[steamID] or {}
    
    local limitData = MyCarDealer.RateLimits[steamID][action] or {
        lastUse = 0,
        violations = 0,
        baseCooldown = baseSeconds
    }
    
    local timeDiff = CurTime() - limitData.lastUse
    local currentCooldown = limitData.baseCooldown * math.pow(1.5, limitData.violations)
    
    if timeDiff < currentCooldown then
        local remaining = math.ceil(currentCooldown - timeDiff)
        limitData.violations = math.min(limitData.violations + 1, 5)
        MyCarDealer.RateLimits[steamID][action] = limitData
        
        MyCarDealer.ChatPrint(ply, "Rate limit! Warte " .. remaining .. "s (Verstoß #" .. limitData.violations .. ")")
        return false
    end
    
    if timeDiff > currentCooldown * 3 then
        limitData.violations = 0
    end
    
    limitData.lastUse = CurTime()
    MyCarDealer.RateLimits[steamID][action] = limitData
    return true
end

-- Lila Chat Prefix
function MyCarDealer.ChatPrint(ply, text)
    if not IsValid(ply) then return end
    ply:ChatPrint("[Dynora Motor's] " .. text)
end

net.Receive("MyCarDealer_SetNPCType", function(len, ply)
    local npcType = net.ReadString()
    ply.MyCarDealer_LastNPC = npcType
end)

-- EINFACHES EINPARKEN: Sofort ohne State-Saving
net.Receive("MyCarDealer_GlobalStore", function(len, ply)
    if not MyCarDealer.CheckRateLimit(ply, "store", 1) then return end
    
    if not ply.MyCarDealer_Vehicle or not IsValid(ply.MyCarDealer_Vehicle) then
        MyCarDealer.ChatPrint(ply, "Du hast kein aktives Fahrzeug!")
        return
    end

    local ent = ply.MyCarDealer_Vehicle
    
    if ply:GetPos():Distance(ent:GetPos()) > 800 then
        MyCarDealer.ChatPrint(ply, "Du bist zu weit vom Fahrzeug entfernt! (Max: 800m)")
        return
    end

    -- Einfach entfernen, kein komplexes Saving mehr nötig
    ent:Remove()
    ply.MyCarDealer_Vehicle = nil
    MyCarDealer.SetActiveVehicle(ply, "")

    MyCarDealer.Log("STORE", ply, "Fahrzeug eingeparkt")
    MyCarDealer.ChatPrint(ply, "Fahrzeug eingeparkt!")
    
    -- Sound + Effekt
    net.Start("MyCarDealer_StoreEffect")
    net.Send(ply)
end)

net.Receive("MyCarDealer_Buy", function(len, ply)
    if not MyCarDealer.CheckRateLimit(ply, "buy", 1) then return end
    
    local vehicle_id = net.ReadString()
    
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    if not valid then
        MyCarDealer.ChatPrint(ply, "Ungültiges Fahrzeug!")
        return
    end
    
    MyCarDealer.BuyVehicle(ply, vehicle_id)
end)

net.Receive("MyCarDealer_Spawn", function(len, ply)
    if not MyCarDealer.CheckRateLimit(ply, "spawn", 2) then return end
    
    local vehicle_id = net.ReadString()
    
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    if not valid then
        MyCarDealer.ChatPrint(ply, "Ungültiges Fahrzeug!")
        return
    end
    
    MyCarDealer.SpawnVehicle(ply, vehicle_id)
end)

net.Receive("MyCarDealer_Sell", function(len, ply)
    if not MyCarDealer.CheckRateLimit(ply, "sell", 1) then return end
    
    local vehicle_id = net.ReadString()
    
    local valid = MyCarDealer.ValidateVehicleID(vehicle_id)
    if not valid then
        MyCarDealer.ChatPrint(ply, "Ungültiges Fahrzeug!")
        return
    end
    
    MyCarDealer.SellVehicle(ply, vehicle_id)
end)

net.Receive("MyCarDealer_StartTestDrive", function(len, ply)
    if not MyCarDealer.CheckRateLimit(ply, "testdrive", 5) then return end
    
    local vehicle_id = net.ReadString()
    
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    if not valid then
        MyCarDealer.ChatPrint(ply, "Ungültiges Fahrzeug!")
        return
    end
    
    MyCarDealer.StartTestDrive(ply, vehicleData)
end)

-- Admin Menu
net.Receive("MyCarDealer_OpenAdminMenu", function(len, ply)
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    net.Start("MyCarDealer_OpenAdminMenu")
    net.Send(ply)
end)

net.Receive("MyCarDealer_AdminSpawn", function(len, ply)
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.Log("ADMIN_FAIL", ply, "Versuchter Admin-Spawn")
        return
    end
    
    local vehicle_id = net.ReadString()
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    
    if valid then
        MyCarDealer.AdminSpawn(ply, vehicle_id)
        MyCarDealer.Log("ADMIN_SPAWN", ply, vehicleData.name)
    end
end)

net.Receive("MyCarDealer_AdminGive", function(len, ply)
    if not MyCarDealer.IsAdmin(ply) then return end
    
    local target = net.ReadEntity()
    local vehicle_id = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    if valid then
        MyCarDealer.GiveVehicle(target, vehicle_id)
        MyCarDealer.Log("ADMIN_GIVE", ply, vehicleData.name .. " an " .. target:Nick())
        MyCarDealer.ChatPrint(ply, "Gegeben: " .. vehicleData.name .. " an " .. target:Nick())
    end
end)

net.Receive("MyCarDealer_AdminRemove", function(len, ply)
    if not MyCarDealer.IsAdmin(ply) then return end
    
    local target = net.ReadEntity()
    local vehicle_id = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local valid, vehicleData = MyCarDealer.ValidateVehicleID(vehicle_id)
    if valid then
        MyCarDealer.RemoveVehicle(target, vehicle_id)
        MyCarDealer.Log("ADMIN_REMOVE", ply, vehicleData.name .. " von " .. target:Nick())
        MyCarDealer.ChatPrint(ply, "Entfernt: " .. vehicleData.name .. " von " .. target:Nick())
    end
end)

function MyCarDealer.BuyVehicle(ply, vehicle_id)
    local vehicle = MyCarDealer.GetVehicleByID(vehicle_id)

    if not vehicle then
        for _, v in ipairs(MyCarDealer.Vehicles) do
            if v.id == vehicle_id then
                vehicle = v
                break
            end
        end
    end

    if not vehicle then
        MyCarDealer.ChatPrint(ply, "Fahrzeug nicht gefunden!")
        return
    end

    if vehicle.job then
        local jobTeam = _G[vehicle.job]
        if not jobTeam or ply:Team() ~= jobTeam then
            MyCarDealer.ChatPrint(ply, "Falsche Job! Benötigt: " .. (MyCarDealer.JobNames[vehicle.job] or vehicle.job))
            return
        end
    end

    if not ply:canAfford(vehicle.price) then
        MyCarDealer.ChatPrint(ply, "Nicht genug Geld! Benötigt: $" .. string.Comma(vehicle.price))
        return
    end

    local steamid = ply:SteamID64()
    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if result and #result > 0 then
        MyCarDealer.ChatPrint(ply, "Du besitzt dieses Auto bereits!")
        return
    end

    ply:addMoney(-vehicle.price)
    
    MyCarDealer.SafeQuery(
        "INSERT INTO mycardealer_inventory (steamid, vehicle_id, tuning_data) VALUES ({steamid}, {vid}, '{}')",
        {steamid = steamid, vid = vehicle_id}
    )

    MyCarDealer.Log("BUY", ply, vehicle.name .. " für $" .. vehicle.price)
    MyCarDealer.ChatPrint(ply, "Gekauft: " .. vehicle.name .. " für $" .. string.Comma(vehicle.price))
    
    MyCarDealer.AddToRecentPurchases(ply, vehicle_id)
    MyCarDealer.SyncInventory(ply)
end

function MyCarDealer.SpawnVehicle(ply, vehicle_id, spawnPos, spawnAng)
    local steamid = ply:SteamID64()

    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if not result or #result == 0 then
        MyCarDealer.ChatPrint(ply, "Du besitzt dieses Auto nicht!")
        return false
    end

    local vehicleData = MyCarDealer.GetVehicleByID(vehicle_id)
    
    if not vehicleData then
        for _, v in ipairs(MyCarDealer.Vehicles) do
            if v.id == vehicle_id then
                vehicleData = v
                break
            end
        end
    end

    if not vehicleData then return false end

    if vehicleData.job then
        local jobTeam = _G[vehicleData.job]
        if not jobTeam or ply:Team() ~= jobTeam then
            MyCarDealer.ChatPrint(ply, "Du hast nicht den richtigen Job!")
            return false
        end
    end

    if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
        ply.MyCarDealer_Vehicle:Remove()
    end

    local usedSpawnpoint = false
    
    if not spawnPos then
        local npcType = ply.MyCarDealer_LastNPC or "main"
        local npcSpawn = MyCarDealer.GetNPCSpawnPoint(npcType)
        
        if npcSpawn then
            spawnPos = npcSpawn.pos
            spawnAng = npcSpawn.ang
            usedSpawnpoint = true
            
            net.Start("MyCarDealer_DrawSpawnPoint")
            net.WriteVector(spawnPos)
            net.WriteString(npcType:upper() .. " SPAWN")
            net.WriteUInt(1, 16)
            net.Send(ply)
            
            MyCarDealer.ChatPrint(ply, "Fahrzeug gespawnt bei: " .. npcType:upper() .. " Standort")
        elseif MyCarDealer.SpawnPoints and #MyCarDealer.SpawnPoints > 0 then
            local point = MyCarDealer.GetRandomSpawnPoint()
            if point and point.pos then
                spawnPos = point.pos
                spawnAng = point.ang
                usedSpawnpoint = true
                
                net.Start("MyCarDealer_DrawSpawnPoint")
                net.WriteVector(point.pos)
                net.WriteString(point.name or "Spawn")
                net.WriteUInt(point.id or 1, 16)
                net.Send(ply)
                
                MyCarDealer.ChatPrint(ply, "Fahrzeug gespawnt bei: " .. (point.name or "Spawn"))
            end
        end
        
        if not spawnPos then
            spawnPos = ply:GetPos() + ply:GetForward() * 200 + Vector(0, 0, 50)
            spawnAng = Angle(0, ply:GetAngles().yaw, 0)
        end
    end

    if not spawnPos or not isvector(spawnPos) then
        print("[MyCarDealer] ERROR: Invalid spawn position!")
        MyCarDealer.ChatPrint(ply, "Fehler: Ungültige Spawn-Position!")
        return false
    end

    local ent = nil
    if string.sub(vehicleData.class, 1, 4) == "lvs_" then
        ent = ents.Create(vehicleData.class)
        if IsValid(ent) then
            ent:SetPos(spawnPos)
            ent:SetAngles(Angle(0, spawnAng.yaw, 0))
            ent:Spawn()
            ent:Activate()
        end
    else
        ent = ents.Create("prop_vehicle_jeep")
        if IsValid(ent) then
            ent:SetModel(vehicleData.model)
            ent:SetKeyValue("vehiclescript", vehicleData.vehicleScript or "scripts/vehicles/jeep_test.txt")
            ent:SetPos(spawnPos)
            ent:SetAngles(Angle(0, spawnAng.yaw, 0))
            ent:Spawn()
            ent:Activate()
        end
    end

    if not IsValid(ent) then
        MyCarDealer.ChatPrint(ply, "Fehler beim Spawnen!")
        return false
    end

    ent:SetNW2Entity("CD_Owner", ply)
    ent:SetNW2String("CD_VehicleID", vehicle_id)
    ent.CD_Owner = ply
    ent.CD_VehicleID = vehicle_id
    ent.CD_CanStore = true
    ent.CD_SpawnTime = CurTime()

    timer.Simple(0.5, function()
        if IsValid(ent) then
            MyCarDealer.ApplyTuningToSpawned(ent, vehicle_id, steamid)
        end
    end)

    timer.Simple(1.0, function()
        if IsValid(ent) then
            MyCarDealer.ApplyLVSItemsToSpawned(ent, vehicle_id, steamid)
        end
    end)

    ply.MyCarDealer_Vehicle = ent
    MyCarDealer.SetActiveVehicle(ply, vehicle_id)

    MyCarDealer.Log("SPAWN", ply, vehicleData.name)
    if not usedSpawnpoint then
        MyCarDealer.ChatPrint(ply, "Fahrzeug ausgeparkt!")
    end
    
    return true
end

function MyCarDealer.SellVehicle(ply, vehicle_id)
    local vehicle = nil
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == vehicle_id then
            vehicle = v
            break
        end
    end

    if not vehicle then return end

    local steamid = ply:SteamID64()
    
    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if not result or #result == 0 then
        MyCarDealer.ChatPrint(ply, "Du besitzt dieses Auto nicht!")
        return
    end

    local returnAmount = math.floor(vehicle.price * MyCarDealer.Config.SellReturnPercent)
    ply:addMoney(returnAmount)

    MyCarDealer.SafeQuery(
        "DELETE FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    MyCarDealer.SafeQuery(
        "DELETE FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )

    if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
        if ply.MyCarDealer_Vehicle.CD_VehicleID == vehicle_id then
            ply.MyCarDealer_Vehicle:Remove()
            ply.MyCarDealer_Vehicle = nil
        end
    end

    MyCarDealer.SetActiveVehicle(ply, "")
    MyCarDealer.Log("SELL", ply, vehicle.name .. " für $" .. returnAmount)
    MyCarDealer.ChatPrint(ply, "Verkauft: " .. vehicle.name .. " für $" .. string.Comma(returnAmount))
    
    MyCarDealer.SyncInventory(ply)
end

function MyCarDealer.AdminSpawn(ply, vehicle_id)
    local vehicleData = nil
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == vehicle_id then
            vehicleData = v
            break
        end
    end

    if not vehicleData then return end

    local spawnPos = ply:GetEyeTrace().HitPos + Vector(0, 0, 50)

    local ent = nil
    if string.sub(vehicleData.class, 1, 4) == "lvs_" then
        ent = ents.Create(vehicleData.class)
        if IsValid(ent) then
            ent:SetPos(spawnPos)
            ent:SetAngles(Angle(0, ply:GetAngles().yaw, 0))
            ent:Spawn()
            ent:Activate()
        end
    else
        ent = ents.Create("prop_vehicle_jeep")
        if IsValid(ent) then
            ent:SetModel(vehicleData.model)
            ent:SetKeyValue("vehiclescript", vehicleData.vehicleScript or "scripts/vehicles/jeep_test.txt")
            ent:SetPos(spawnPos)
            ent:SetAngles(Angle(0, ply:GetAngles().yaw, 0))
            ent:Spawn()
            ent:Activate()
        end
    end

    if IsValid(ent) then
        ent:SetNW2Bool("CD_AdminSpawn", true)
        MyCarDealer.ChatPrint(ply, "Admin-Spawn: " .. vehicleData.name)
    end
end

function MyCarDealer.GiveVehicle(ply, vehicle_id)
    local steamid = ply:SteamID64()
    
    MyCarDealer.SafeQuery(
        "INSERT OR REPLACE INTO mycardealer_inventory (steamid, vehicle_id, tuning_data) VALUES ({steamid}, {vid}, '{}')",
        {steamid = steamid, vid = vehicle_id}
    )
    
    MyCarDealer.RemoveLVSItems(steamid, vehicle_id)
    MyCarDealer.SyncInventory(ply)
    MyCarDealer.ChatPrint(ply, "Du hast ein Fahrzeug erhalten!")
end

function MyCarDealer.RemoveVehicle(ply, vehicle_id)
    local steamid = ply:SteamID64()
    
    MyCarDealer.SafeQuery(
        "DELETE FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )

    if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
        if ply.MyCarDealer_Vehicle.CD_VehicleID == vehicle_id then
            ply.MyCarDealer_Vehicle:Remove()
            ply.MyCarDealer_Vehicle = nil
        end
    end

    MyCarDealer.RemoveLVSItems(steamid, vehicle_id)
    MyCarDealer.SyncInventory(ply)
end

-- Vereinfachtes Tuning-Apply (kein Fuel/Health mehr)
function MyCarDealer.ApplyTuningToSpawned(ent, vehicle_id, steamid)
    timer.Simple(0.3, function()
        if not IsValid(ent) then return end
        
        local result = MyCarDealer.SafeQuery(
            "SELECT tuning_data FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {steamid = steamid, vid = vehicle_id}
        )

        if result and result[1] and result[1].tuning_data then
            local tuning = util.JSONToTable(result[1].tuning_data) or {}

            if tuning.neon and tuning.neon.enabled then
                local col = tuning.neon.color or {r=157, g=78, b=221}
                if ent.SetNeonColor then
                    ent:SetNeonColor(Color(col.r, col.g, col.b))
                    ent:SetNeonEnabled(true)
                end
                if ent.SetNeon then ent:SetNeon(true) end
                ent:SetNW2Bool("CD_Neon", true)
                ent:SetNW2Vector("CD_NeonColor", Vector(col.r, col.g, col.b))
                if not ent.SetNeonColor then
                    ent:SetNW2Bool("CD_NeonSimfphys", true)
                end
            end

            if tuning.lvs then
                local lvs = tuning.lvs

                if lvs.bodyColor then
                    local col = Color(lvs.bodyColor.r, lvs.bodyColor.g, lvs.bodyColor.b)
                    ent:SetColor(col)
                end

                if lvs.skin and ent.SetSkin then
                    ent:SetSkin(lvs.skin)
                end

                if lvs.gauge then
                    local hasGauge = false
                    for _, child in ipairs(ent:GetChildren()) do
                        if IsValid(child) and child:GetClass() == "lvs_item_gauge" then
                            hasGauge = true
                            break
                        end
                    end

                    if not hasGauge then
                        local gauge = ents.Create("lvs_item_gauge")
                        if IsValid(gauge) then
                            gauge:SetPos(ent:GetPos() + Vector(0, 0, 50))
                            gauge:SetAngles(ent:GetAngles())
                            gauge:Spawn()
                            gauge:Activate()
                            gauge:SetParent(ent)
                            
                            local attachment = ent:LookupAttachment("vehicle_driver_eyes") or 0
                            if attachment > 0 then
                                local attPos = ent:GetAttachment(attachment)
                                if attPos then
                                    gauge:SetLocalPos(Vector(10, 0, -5))
                                    gauge:SetLocalAngles(Angle(0, 0, 0))
                                end
                            else
                                gauge:SetLocalPos(Vector(20, 0, 15))
                                gauge:SetLocalAngles(Angle(0, 0, 0))
                            end
                        end
                    end
                end

                ent.CD_Tuning = tuning
            end
        end
    end)
end

function MyCarDealer.SaveLVSItemsFromVehicle(ent, steamid, vehicle_id)
    if not IsValid(ent) or not ent.LVS then return end
    
    MyCarDealer.EnsureLVSItemsTable()
    
    local items = {}
    
    if IsValid(ent:GetTurbo()) then
        local turbo = ent:GetTurbo()
        items.turbo = {
            curve = turbo.GetEngineCurve and turbo:GetEngineCurve() or 0.5,
            torque = turbo.GetEngineTorque and turbo:GetEngineTorque() or 1.2
        }
    end
    
    if IsValid(ent:GetCompressor()) then
        local comp = ent:GetCompressor()
        items.compressor = {
            curve = comp.GetEngineCurve and comp:GetEngineCurve() or 0.3,
            torque = comp.GetEngineTorque and comp:GetEngineTorque() or 1.5
        }
    end
    
    if ent.GetRacingHud and ent:GetRacingHud() then
        items.gauge = true
    end
    
    if ent.GetBackfire and ent:GetBackfire() then
        items.exhaust = true
    end
    
    if ent.GetRacingTires and ent:GetRacingTires() then
        items.racingTires = true
    end
    
    if ent.IsManualTransmission and ent:IsManualTransmission() then
        items.manualTransmission = true
    end
    
    if ent.GetBodyGroups then
        local bodygroups = ent:GetBodyGroups()
        local savedBodygroups = {}
        local hasCustomBodygroups = false
        
        for _, bg in ipairs(bodygroups) do
            if bg.id and bg.num then
                local currentValue = ent:GetBodygroup(bg.id)
                if currentValue ~= 0 then
                    savedBodygroups[bg.id] = currentValue
                    hasCustomBodygroups = true
                end
            end
        end
        
        if hasCustomBodygroups then
            items.bodygroups = savedBodygroups
        end
    end
    
    MyCarDealer.SafeQuery(
        "DELETE FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    for itemType, itemData in pairs(items) do
        local dataJson
        if itemData == true then
            dataJson = "true"
        elseif istable(itemData) then
            dataJson = util.TableToJSON(itemData)
        else
            dataJson = tostring(itemData)
        end
        
        MyCarDealer.SafeQuery(
            "INSERT INTO mycardealer_lvs_items (steamid, vehicle_id, item_type, item_data) VALUES ({steamid}, {vid}, {itype}, {idata})",
            {steamid = steamid, vid = vehicle_id, itype = itemType, idata = dataJson}
        )
    end
    
    local tuningResult = MyCarDealer.SafeQuery(
        "SELECT tuning_data FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if tuningResult and tuningResult[1] then
        local tuning = util.JSONToTable(tuningResult[1].tuning_data) or {}
        if not tuning.lvs then tuning.lvs = {} end
        tuning.lvs.items = items
        
        MyCarDealer.SafeQuery(
            "UPDATE mycardealer_inventory SET tuning_data = {tdata} WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {tdata = util.TableToJSON(tuning), steamid = steamid, vid = vehicle_id}
        )
    end
end

function MyCarDealer.ApplyLVSItemsToSpawned(ent, vehicle_id, steamid)
    if not IsValid(ent) then return end
    
    if not ent.LVS then
        timer.Simple(0.5, function()
            if IsValid(ent) then
                MyCarDealer.ApplyLVSItemsToSpawned(ent, vehicle_id, steamid)
            end
        end)
        return
    end
    
    local result = MyCarDealer.SafeQuery(
        "SELECT item_type, item_data FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if not result or #result == 0 then return end
    
    for _, row in ipairs(result) do
        local itemType = row.item_type
        local itemData = util.JSONToTable(row.item_data) or (row.item_data == "true" and true) or row.item_data
        
        if itemType == "turbo" then
            if isfunction(ent.AddTurboCharger) then
                if not IsValid(ent:GetTurbo()) then
                    local turbo = ent:AddTurboCharger()
                    if IsValid(turbo) and itemData and istable(itemData) then
                        if itemData.curve then turbo:SetEngineCurve(itemData.curve) end
                        if itemData.torque then turbo:SetEngineTorque(itemData.torque) end
                    end
                end
            end
            
        elseif itemType == "compressor" then
            if isfunction(ent.AddSuperCharger) then
                if not IsValid(ent:GetCompressor()) then
                    local comp = ent:AddSuperCharger()
                    if IsValid(comp) and itemData and istable(itemData) then
                        if itemData.curve then comp:SetEngineCurve(itemData.curve) end
                        if itemData.torque then comp:SetEngineTorque(itemData.torque) end
                    end
                end
            end
            
        elseif itemType == "gauge" then
            if isfunction(ent.SetRacingHud) then
                ent:SetRacingHud(true)
            end
            
        elseif itemType == "exhaust" then
            if isfunction(ent.SetBackfire) then
                ent:SetBackfire(true)
            end
            
        elseif itemType == "racingTires" then
            if isfunction(ent.SetRacingTires) then
                ent:SetRacingTires(true)
            end
            
        elseif itemType == "manualTransmission" then
            if isfunction(ent.EnableManualTransmission) then
                ent:EnableManualTransmission()
            end
            
        elseif itemType == "bodygroups" then
            if istable(itemData) and ent.SetBodygroup then
                for bgID, bgValue in pairs(itemData) do
                    bgID = tonumber(bgID)
                    bgValue = tonumber(bgValue)
                    if bgID and bgValue then
                        ent:SetBodygroup(bgID, bgValue)
                    end
                end
            end
        end
    end
end

function MyCarDealer.EnsureLVSItemsTable()
    local checkQuery = "PRAGMA table_info(mycardealer_lvs_items)"
    local columns = sql.Query(checkQuery)
    
    local hasCorrectStructure = false
    if columns and istable(columns) and #columns > 0 then
        local hasSteamID = false
        local hasVehicleID = false
        local hasItemType = false
        local hasItemData = false
        
        for _, col in ipairs(columns) do
            if col.name == "steamid" then hasSteamID = true end
            if col.name == "vehicle_id" then hasVehicleID = true end
            if col.name == "item_type" then hasItemType = true end
            if col.name == "item_data" then hasItemData = true end
        end
        
        if hasSteamID and hasVehicleID and hasItemType and hasItemData then
            hasCorrectStructure = true
        end
    end
    
    if not hasCorrectStructure then
        sql.Query("DROP TABLE IF EXISTS mycardealer_lvs_items")
        
        sql.Query([[CREATE TABLE mycardealer_lvs_items (
            steamid VARCHAR(32) NOT NULL,
            vehicle_id VARCHAR(64) NOT NULL,
            item_type VARCHAR(32) NOT NULL,
            item_data TEXT,
            PRIMARY KEY (steamid, vehicle_id, item_type)
        )]])
    end
end

function MyCarDealer.RemoveLVSItems(steamid, vehicle_id)
    MyCarDealer.SafeQuery(
        "DELETE FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
end

function MyCarDealer.SaveVehicleStat(steamid, vehicle_id, stat, value)
end

function MyCarDealer.AddToRecentPurchases(ply, vehicle_id)
end

function MyCarDealer.StartTestDrive(ply, vehicleData)
    MyCarDealer.ChatPrint(ply, "Testfahrten sind derzeit deaktiviert.")
end

function MyCarDealer.SyncInventory(ply)
    local steamid = ply:SteamID64()
    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id, purchase_date, tuning_data FROM mycardealer_inventory WHERE steamid = {steamid}",
        {steamid = steamid}
    ) or {}

    local inventory = {}
    for _, row in ipairs(result) do
        table.insert(inventory, {
            vehicle_id = row.vehicle_id,
            purchase_date = row.purchase_date,
            tuning_data = row.tuning_data
        })
    end

    net.Start("MyCarDealer_SyncInventory")
    net.WriteTable(inventory)
    net.Send(ply)
end

function MyCarDealer.SetActiveVehicle(ply, vehicle_id)
    local steamid = ply:SteamID64()
    MyCarDealer.SafeQuery(
        "INSERT OR REPLACE INTO mycardealer_active (steamid, vehicle_id, spawn_time) VALUES ({steamid}, {vid}, CURRENT_TIMESTAMP)",
        {steamid = steamid, vid = vehicle_id or ""}
    )
end

function MyCarDealer.GetInventory(ply, callback)
    if not IsValid(ply) then 
        if callback then callback({}) end
        return 
    end
    
    local steamid = ply:SteamID64()
    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id, purchase_date, tuning_data, insurance FROM mycardealer_inventory WHERE steamid = {steamid}",
        {steamid = steamid}
    )
    
    if callback then
        callback(result or {})
    end
    
    return result or {}
end

function MyCarDealer.GetPlayerVehiclesRaw(steamid64)
    local result = MyCarDealer.SafeQuery(
        "SELECT vehicle_id, purchase_date, tuning_data FROM mycardealer_inventory WHERE steamid = {steamid}",
        {steamid = steamid64}
    )
    
    if not result or #result == 0 then return {} end
    
    local vehicles = {}
    for _, item in ipairs(result) do
        local vehicleData = nil
        
        if MyCarDealer.Vehicles then
            for _, v in ipairs(MyCarDealer.Vehicles) do
                if v.id == item.vehicle_id then
                    vehicleData = v
                    break
                end
            end
        end
        
        table.insert(vehicles, {
            id = item.vehicle_id,
            name = vehicleData and vehicleData.name or item.vehicle_id,
            category = vehicleData and vehicleData.category or "Unbekannt",
            price = vehicleData and vehicleData.price or 0,
            model = vehicleData and vehicleData.model or "models/error.mdl",
            class = vehicleData and vehicleData.class or "unknown",
            maxSpeed = vehicleData and vehicleData.maxSpeed or 0,
            description = vehicleData and vehicleData.description or "",
            purchase_date = item.purchase_date,
            tuning_data = item.tuning_data
        })
    end
    
    return vehicles
end

hook.Add("PlayerDisconnected", "MyCarDealer_Cleanup", function(ply)
    if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
        ply.MyCarDealer_Vehicle:Remove()
    end
end)

hook.Add("PlayerInitialSpawn", "MyCarDealer_InitSync", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            MyCarDealer.SyncInventory(ply)
        end
    end)
end)

net.Receive("MyCarDealer_Return", function(len, ply)
    MyCarDealer.SyncInventory(ply)
end)

hook.Add("Initialize", "MyCarDealer_LVSItemsTable", function()
    timer.Simple(5, function()
        MyCarDealer.EnsureLVSItemsTable()
    end)
end)

-- NPC Spawnpoints
MyCarDealer.NPCSpawnPoints = MyCarDealer.NPCSpawnPoints or {
    main = nil,
    garage = nil,
    police = nil
}

hook.Add("Initialize", "MyCarDealer_LoadNPCSpawnPoints", function()
    local saved = file.Read("cardealer/npc_spawnpoints.txt", "DATA")
    if saved then
        MyCarDealer.NPCSpawnPoints = util.JSONToTable(saved) or MyCarDealer.NPCSpawnPoints
    end
end)

function MyCarDealer.SaveNPCSpawnPoints()
    if not file.Exists("cardealer", "DATA") then
        file.CreateDir("cardealer")
    end
    file.Write("cardealer/npc_spawnpoints.txt", util.TableToJSON(MyCarDealer.NPCSpawnPoints, true))
end

function MyCarDealer.SetNPCSpawnPoint(ply, npcType, name, color)
    if not IsValid(ply) then return end
    if not MyCarDealer.IsAdmin(ply) then
        MyCarDealer.ChatPrint(ply, "Keine Berechtigung!")
        return
    end
    
    local tr = ply:GetEyeTrace()
    local pos = tr.HitPos + Vector(0, 0, 10)
    local ang = Angle(0, ply:GetAngles().yaw, 0)
    
    MyCarDealer.NPCSpawnPoints[npcType] = {
        pos = {x = pos.x, y = pos.y, z = pos.z},
        ang = {p = ang.p, y = ang.y, r = ang.r},
        name = name,
        color = color,
        setBy = ply:Nick(),
        setTime = os.date("%Y-%m-%d %H:%M:%S")
    }
    MyCarDealer.SaveNPCSpawnPoints()
    
    MyCarDealer.ChatPrint(ply, "Spawnpunkt für " .. name .. " gesetzt!")
    
    net.Start("MyCarDealer_SetNPCSpawnPoint")
    net.WriteString(npcType)
    net.WriteVector(pos)
    net.WriteAngle(ang)
    net.WriteString(name)
    net.WriteColor(color)
    net.Broadcast()
end

concommand.Add("cardealer_spawnpoint_main", function(ply)
    MyCarDealer.SetNPCSpawnPoint(ply, "main", "Haupt-Händler", Color(157, 78, 221))
end)

concommand.Add("cardealer_spawnpoint_garage", function(ply)
    MyCarDealer.SetNPCSpawnPoint(ply, "garage", "Garage", Color(0, 230, 150))
end)

concommand.Add("cardealer_spawnpoint_police", function(ply)
    MyCarDealer.SetNPCSpawnPoint(ply, "police", "Polizei", Color(0, 168, 255))
end)

concommand.Add("cardealer_spawnpoint_list", function(ply)
    if not IsValid(ply) then return end
    if not MyCarDealer.IsAdmin(ply) then return end
    
    MyCarDealer.ChatPrint(ply, "=== NPC FAHRZEUG-SPAWNPOINTS ===")
    
    local hasAny = false
    for npcType, data in pairs(MyCarDealer.NPCSpawnPoints) do
        if data and data.pos then
            hasAny = true
            local pos = Vector(data.pos.x, data.pos.y, data.pos.z)
            local dist = math.floor(ply:GetPos():Distance(pos))
            MyCarDealer.ChatPrint(ply, "[" .. npcType .. "] " .. (data.name or "Unbekannt"))
            MyCarDealer.ChatPrint(ply, "  Pos: " .. math.floor(pos.x) .. " " .. math.floor(pos.y) .. " " .. math.floor(pos.z))
            MyCarDealer.ChatPrint(ply, "  Distanz: " .. dist .. "m")
        end
    end
    
    if not hasAny then
        MyCarDealer.ChatPrint(ply, "Keine Spawnpunkte gesetzt!")
    end
    
    net.Start("MyCarDealer_ShowAllSpawnPoints")
    net.Send(ply)
end)

concommand.Add("cardealer_spawnpoint_clear", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not MyCarDealer.IsAdmin(ply) then return end
    
    local npcType = args[1]
    if not npcType or not MyCarDealer.NPCSpawnPoints[npcType] then
        MyCarDealer.ChatPrint(ply, "Usage: cardealer_spawnpoint_clear <main/garage/police>")
        return
    end
    
    MyCarDealer.NPCSpawnPoints[npcType] = nil
    MyCarDealer.SaveNPCSpawnPoints()
    MyCarDealer.ChatPrint(ply, "Spawnpunkt für " .. npcType .. " gelöscht!")
end)

function MyCarDealer.GetNPCSpawnPoint(npcType)
    local data = MyCarDealer.NPCSpawnPoints[npcType]
    if not data or not data.pos then return nil end
    
    return {
        pos = Vector(data.pos.x, data.pos.y, data.pos.z),
        ang = Angle(data.ang.p, data.ang.y, data.ang.r)
    }
end

print("[Dynora Motor's] sv_main.lua loaded")
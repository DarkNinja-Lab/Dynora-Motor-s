util.AddNetworkString("MyCarDealer_SaveTuning")

net.Receive("MyCarDealer_SaveTuning", function(len, ply)
    local vehicle_id = net.ReadString()
    local tuningData = net.ReadTable()

    local steamid = ply:SteamID64()
    local checkQuery = string.format(
        "SELECT vehicle_id FROM mycardealer_inventory WHERE steamid = '%s' AND vehicle_id = '%s'",
        steamid, vehicle_id
    )
    local result = sql.Query(checkQuery)

    if not result or #result == 0 then
        MyCarDealer.ChatPrint(ply, "Du besitzt dieses Auto nicht!")
        return
    end

    local cost = 0
    
    -- Neon Kosten
    if tuningData.neon and tuningData.neon.enabled then
        cost = cost + (MyCarDealer.Config.NeonPrice or 500)
    end
    
    -- LVS Tuning Kosten
    if tuningData.lvs then
        -- Skin/Farbe
        if tuningData.lvs.skin and tuningData.lvs.skin > 0 then
            cost = cost + 300
        end
        
        -- LVS Items
        local itemPrices = {
            turbo = 2500,
            compressor = 3000,
            racingTires = 1500,
            exhaust = 800,
            gauge = 500,
            manualTransmission = 1000
        }
        
        if tuningData.lvs.items then
            for itemId, enabled in pairs(tuningData.lvs.items) do
                if enabled and itemPrices[itemId] then
                    cost = cost + itemPrices[itemId]
                end
            end
        end
    end

    if cost > 0 then
        if not ply:canAfford(cost) then
            MyCarDealer.ChatPrint(ply, "Nicht genug Geld für Tuning! Benötigt: $" .. cost)
            return
        end
        ply:addMoney(-cost)
        MyCarDealer.ChatPrint(ply, "Tuning gekauft für $" .. cost)
    end

    -- ============================================
    -- KORRIGIERT: LVS Items in separate Tabelle speichern
    -- ============================================
    if tuningData.lvs and tuningData.lvs.items then
        MyCarDealer.EnsureLVSItemsTable()
        
        -- Lösche alte Items
        MyCarDealer.SafeQuery(
            "DELETE FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {steamid = steamid, vid = vehicle_id}
        )
        
        -- Speichere neue Items
        for itemType, enabled in pairs(tuningData.lvs.items) do
            if enabled then
                MyCarDealer.SafeQuery(
                    "INSERT INTO mycardealer_lvs_items (steamid, vehicle_id, item_type, item_data) VALUES ({steamid}, {vid}, {itype}, {idata})",
                    {steamid = steamid, vid = vehicle_id, itype = itemType, idata = "true"}
                )
            end
        end
        
        -- Items in tuning_data als Referenz speichern
        tuningData.lvs.items = tuningData.lvs.items
    end

    local tuningJson = util.TableToJSON(tuningData)
    local updateQuery = string.format(
        "UPDATE mycardealer_inventory SET tuning_data = %s WHERE steamid = '%s' AND vehicle_id = '%s'",
        sql.SQLStr(tuningJson), steamid, vehicle_id
    )

    local updateResult = sql.Query(updateQuery)
    if updateResult == false then
        print("[MyCarDealer] Tuning Save Error: " .. sql.LastError())
        MyCarDealer.ChatPrint(ply, "Fehler beim Speichern!")
        return
    end

    if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
        if ply.MyCarDealer_Vehicle.CD_VehicleID == vehicle_id then
            MyCarDealer.ApplyTuningToSpawned(ply.MyCarDealer_Vehicle, vehicle_id, steamid)
            -- LVS Items erneut anwenden
            timer.Simple(0.5, function()
                if IsValid(ply.MyCarDealer_Vehicle) then
                    MyCarDealer.ApplyLVSItemsToSpawned(ply.MyCarDealer_Vehicle, vehicle_id, steamid)
                end
            end)
        end
    end

    MyCarDealer.ChatPrint(ply, "Tuning gespeichert!")

    MyCarDealer.SyncInventory(ply)
end)

print("[Dynora Motor´s] sv_tuning.lua loaded")
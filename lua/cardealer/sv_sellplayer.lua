util.AddNetworkString("MyCarDealer_SellToPlayer")
util.AddNetworkString("MyCarDealer_SellOffer")
util.AddNetworkString("MyCarDealer_SellAccept")
util.AddNetworkString("MyCarDealer_SellDecline")

net.Receive("MyCarDealer_SellToPlayer", function(len, ply)
    local vehicle_id = net.ReadString()
    local target = net.ReadEntity()
    local price = net.ReadInt(32)
    
    if not IsValid(target) or not target:IsPlayer() then return end
    if target == ply then return end
    
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
    
    local vehicleData = nil
    for _, v in ipairs(MyCarDealer.Vehicles) do
        if v.id == vehicle_id then
            vehicleData = v
            break
        end
    end
    
    if not vehicleData then return end
    
    net.Start("MyCarDealer_SellOffer")
    net.WriteString(vehicle_id)
    net.WriteString(vehicleData.name)
    net.WriteString(ply:Nick())
    net.WriteString(ply:SteamID64())
    net.WriteInt(price, 32)
    net.Send(target)
    
    MyCarDealer.ChatPrint(ply, "Angebot gesendet an " .. target:Nick() .. "!")
end)

net.Receive("MyCarDealer_SellAccept", function(len, ply)
    local vehicle_id = net.ReadString()
    local sellerSteamID = net.ReadString()
    local price = net.ReadInt(32)
    
    local seller = nil
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID64() == sellerSteamID then
            seller = p
            break
        end
    end
    
    if not IsValid(seller) then
        MyCarDealer.ChatPrint(ply, "Verkäufer ist nicht mehr online!")
        return
    end
    
    if not ply:canAfford(price) then
        MyCarDealer.ChatPrint(ply, "Du hast nicht genug Geld!")
        return
    end
    
    local sellerSteam = seller:SteamID64()
    local checkQuery = string.format(
        "SELECT vehicle_id, tuning_data FROM mycardealer_inventory WHERE steamid = '%s' AND vehicle_id = '%s'",
        sellerSteam, vehicle_id
    )
    local result = sql.Query(checkQuery)
    
    if not result or #result == 0 then
        MyCarDealer.ChatPrint(ply, "Fahrzeug nicht mehr verfügbar!")
        return
    end
    
    local tuningData = result[1].tuning_data or "{}"
    
    ply:addMoney(-price)
    seller:addMoney(price)
    
    sql.Query(string.format(
        "DELETE FROM mycardealer_inventory WHERE steamid = '%s' AND vehicle_id = '%s'",
        sellerSteam, vehicle_id
    ))
    
    sql.Query(string.format(
        "DELETE FROM mycardealer_lvs_items WHERE steamid = '%s' AND vehicle_id = '%s'",
        sellerSteam, vehicle_id
    ))
    
    if seller.MyCarDealer_Vehicle and IsValid(seller.MyCarDealer_Vehicle) then
        if seller.MyCarDealer_Vehicle.CD_VehicleID == vehicle_id then
            seller.MyCarDealer_Vehicle:Remove()
            seller.MyCarDealer_Vehicle = nil
        end
    end
    
    local lvsItemsQuery = string.format(
        "SELECT item_type, item_data FROM mycardealer_lvs_items WHERE steamid = '%s' AND vehicle_id = '%s'",
        sellerSteam, vehicle_id
    )
    local lvsItems = sql.Query(lvsItemsQuery)
    
    local buyerSteam = ply:SteamID64()
    sql.Query(string.format(
        "INSERT INTO mycardealer_inventory (steamid, vehicle_id, tuning_data) VALUES ('%s', '%s', %s)",
        buyerSteam, vehicle_id, sql.SQLStr(tuningData)
    ))

    if lvsItems and #lvsItems > 0 then
        for _, item in ipairs(lvsItems) do
            sql.Query(string.format(
                "INSERT INTO mycardealer_lvs_items (steamid, vehicle_id, item_type, item_data) VALUES ('%s', '%s', '%s', %s)",
                buyerSteam, vehicle_id, item.item_type, sql.SQLStr(item.item_data)
            ))
        end
    end

    MyCarDealer.SyncInventory(seller)
    MyCarDealer.SyncInventory(ply)
    
    MyCarDealer.ChatPrint(ply, "Du hast das Fahrzeug für $" .. string.Comma(price) .. " gekauft!")
    MyCarDealer.ChatPrint(seller, ply:Nick() .. " hat dein Fahrzeug für $" .. string.Comma(price) .. " gekauft!")
    
        -- KORRIGIERT: Sound ohne doppelte Backslashes
    ply:SendLua('surface.PlaySound("ambient/levels/labs/coinslot1.wav")')
    seller:SendLua('surface.PlaySound("ambient/levels/labs/coinslot1.wav")')
end)

net.Receive("MyCarDealer_SellDecline", function(len, ply)
    local sellerSteamID = net.ReadString()
    
    local seller = nil
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID64() == sellerSteamID then
            seller = p
            break
        end
    end
    
    if IsValid(seller) then
        MyCarDealer.ChatPrint(seller, ply:Nick() .. " hat dein Angebot abgelehnt.")
    end
    
    MyCarDealer.ChatPrint(ply, "Angebot abgelehnt.")
end)

print("[Dynora Motor´s] sv_sellplayer.lua loaded")
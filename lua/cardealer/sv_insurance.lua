util.AddNetworkString("MyCarDealer_BuyInsurance")
util.AddNetworkString("MyCarDealer_ClaimInsurance")
util.AddNetworkString("MyCarDealer_InsuranceMenu")
util.AddNetworkString("MyCarDealer_SyncInsurance")

MyCarDealer.Insurance = MyCarDealer.Insurance or {}

-- NEUES SYSTEM: Versicherung mit echten Vorteilen
MyCarDealer.Insurance.Config = {
    -- Preis: 10% des Fahrzeugwerts (einmalig, gültig bis Fahrzeug verkauft)
    PriceMultiplier = 0.10,
    
    -- Auszahlungen bei verschiedenen Schadensarten
    Payouts = {
        totalLoss = 0.85,      -- 85% bei Totalschaden (Fahrzeug explodiert/zerstört)
        accident = 0.50,       -- 50% bei Unfall (schwerer Schaden)
        theft = 0.70,          -- 70% bei Diebstahl (Fahrzeug despawnt/despawned)
        minor = 0.25           -- 25% bei kleineren Schäden
    },
    
    -- Cooldown zwischen Claims (realistisch)
    ClaimCooldownHours = 1,
    
    -- Max Claims pro Fahrzeug (danach Versicherung erlischt)
    MaxClaimsPerVehicle = 3,
    
    -- Min/Max Preise
    MinPrice = 500,
    MaxPrice = 50000
}

-- Versicherung kaufen (einmalig, gültig für dieses Fahrzeug)
function MyCarDealer.Insurance.Buy(ply, vehicle_id)
    if not IsValid(ply) then return false end
    
    local steamid = ply:SteamID64()
    
    -- Prüfe ob Fahrzeug existiert
    local checkQuery = MyCarDealer.SafeQuery(
        "SELECT vehicle_id, insurance FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if not checkQuery or #checkQuery == 0 then
        MyCarDealer.ChatPrint(ply, "Du besitzt dieses Fahrzeug nicht!")
        return false
    end
    
    -- Prüfe ob bereits versichert
    local isInsured = checkQuery[1].insurance == "1" or checkQuery[1].insurance == 1
    if isInsured then
        MyCarDealer.ChatPrint(ply, "Dieses Fahrzeug ist bereits versichert!")
        return false
    end
    
    -- Fahrzeugdaten holen
    local vehicleData = MyCarDealer.GetVehicleByID(vehicle_id)
    if not vehicleData then
        MyCarDealer.ChatPrint(ply, "Fahrzeugdaten nicht gefunden!")
        return false
    end
    
    local insurancePrice = math.Clamp(
        math.floor(vehicleData.price * MyCarDealer.Insurance.Config.PriceMultiplier),
        MyCarDealer.Insurance.Config.MinPrice,
        MyCarDealer.Insurance.Config.MaxPrice
    )
    
    if not ply:canAfford(insurancePrice) then
        MyCarDealer.ChatPrint(ply, "Nicht genug Geld! Benötigt: $" .. string.Comma(insurancePrice))
        return false
    end
    
    ply:addMoney(-insurancePrice)
    
    -- Aktiviere Versicherung mit Claim-Counter
    MyCarDealer.SafeQuery(
        "UPDATE mycardealer_inventory SET insurance = 1, insurance_cooldown = 0, crash_count = 0 WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    MyCarDealer.Log("INSURANCE_BUY", ply, vehicleData.name .. " für $" .. insurancePrice)
    MyCarDealer.ChatPrint(ply, "VERSICHERUNG ABGESCHLOSSEN!")
    MyCarDealer.ChatPrint(ply, vehicleData.name .. " ist nun versichert.")
    MyCarDealer.ChatPrint(ply, "Preis: $" .. string.Comma(insurancePrice) .. " | Max. 3 Schadensfälle")
    
    ply:SendLua('surface.PlaySound("ambient/levels/labs/coinslot1.wav")')
    MyCarDealer.Insurance.Sync(ply, vehicle_id)
    
    return true
end

-- Schadensfall melden (Claim)
function MyCarDealer.Insurance.Claim(ply, vehicle_id, damageType)
    if not IsValid(ply) then return false end
    
    damageType = damageType or "accident"
    
    local steamid = ply:SteamID64()
    
    -- Fahrzeugdaten holen
    local vehicleData = MyCarDealer.GetVehicleByID(vehicle_id)
    if not vehicleData then
        MyCarDealer.ChatPrint(ply, "Fahrzeugdaten nicht gefunden!")
        return false
    end
    
    -- Prüfe Versicherung
    local result = MyCarDealer.SafeQuery(
        "SELECT insurance, insurance_cooldown, crash_count FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if not result or #result == 0 then
        MyCarDealer.ChatPrint(ply, "Fahrzeug nicht gefunden!")
        return false
    end
    
    local isInsured = result[1].insurance == "1" or result[1].insurance == 1
    if not isInsured then
        MyCarDealer.ChatPrint(ply, "Dieses Fahrzeug ist nicht versichert!")
        return false
    end
    
    -- Cooldown prüfen
    local cooldown = tonumber(result[1].insurance_cooldown) or 0
    if cooldown > os.time() then
        local remaining = cooldown - os.time()
        local minutes = math.ceil(remaining / 60)
        MyCarDealer.ChatPrint(ply, "Versicherung in Cooldown! Noch " .. minutes .. " Minuten.")
        return false
    end
    
    -- Max Claims prüfen
    local claims = tonumber(result[1].crash_count) or 0
    if claims >= MyCarDealer.Insurance.Config.MaxClaimsPerVehicle then
        MyCarDealer.ChatPrint(ply, "Maximale Anzahl an Schadensfällen erreicht!")
        MyCarDealer.ChatPrint(ply, "Versicherung ist erloschen. Neu abschließen nötig.")
        
        -- Versicherung deaktivieren
        MyCarDealer.SafeQuery(
            "UPDATE mycardealer_inventory SET insurance = 0 WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {steamid = steamid, vid = vehicle_id}
        )
        return false
    end
    
    -- Auszahlung berechnen
    local payoutPercent = MyCarDealer.Insurance.Config.Payouts[damageType] or 0.25
    local payout = math.floor(vehicleData.price * payoutPercent)
    
    -- Auszahlung
    ply:addMoney(payout)
    
    -- Cooldown und Claim-Counter setzen
    local newCooldown = os.time() + (MyCarDealer.Insurance.Config.ClaimCooldownHours * 3600)
    MyCarDealer.SafeQuery(
        "UPDATE mycardealer_inventory SET insurance_cooldown = {cooldown}, crash_count = crash_count + 1 WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id, cooldown = newCooldown}
    )
    
    -- Bei Totalschaden/Theft: Fahrzeug entfernen
    if damageType == "totalLoss" or damageType == "theft" then
        MyCarDealer.SafeQuery(
            "DELETE FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {steamid = steamid, vid = vehicle_id}
        )
        MyCarDealer.SafeQuery(
            "DELETE FROM mycardealer_lvs_items WHERE steamid = {steamid} AND vehicle_id = {vid}",
            {steamid = steamid, vid = vehicle_id}
        )
        
        -- Aktives Fahrzeug entfernen
        if ply.MyCarDealer_Vehicle and IsValid(ply.MyCarDealer_Vehicle) then
            if ply.MyCarDealer_Vehicle.CD_VehicleID == vehicle_id then
                ply.MyCarDealer_Vehicle:Remove()
                ply.MyCarDealer_Vehicle = nil
            end
        end
        
        MyCarDealer.SyncInventory(ply)
    end
    
    -- Log und Feedback
    local damageNames = {
        totalLoss = "Totalschaden",
        accident = "Unfall",
        theft = "Diebstahl",
        minor = "Kleinschaden"
    }
    
    MyCarDealer.Log("INSURANCE_CLAIM", ply, vehicleData.name .. " | " .. damageType .. " | $" .. payout)
    
    MyCarDealer.ChatPrint(ply, "SCHADENSFALL GEMELDET!")
    MyCarDealer.ChatPrint(ply, "Grund: " .. (damageNames[damageType] or "Sonstiges"))
    MyCarDealer.ChatPrint(ply, "Auszahlung: $" .. string.Comma(payout))
    MyCarDealer.ChatPrint(ply, "Verbleibende Claims: " .. (MyCarDealer.Insurance.Config.MaxClaimsPerVehicle - claims - 1))
    
    if damageType == "totalLoss" or damageType == "theft" then
        MyCarDealer.ChatPrint(ply, "Fahrzeug wurde aus dem Inventar entfernt.")
    end
    
    ply:SendLua('surface.PlaySound("ambient/levels/labs/coinslot1.wav")')
    return true
end

-- Sync für Client
function MyCarDealer.Insurance.Sync(ply, vehicle_id)
    local steamid = ply:SteamID64()
    
    local result = MyCarDealer.SafeQuery(
        "SELECT insurance, insurance_cooldown, crash_count FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if result and #result > 0 then
        net.Start("MyCarDealer_SyncInsurance")
        net.WriteString(vehicle_id)
        net.WriteBool(result[1].insurance == "1" or result[1].insurance == 1)
        net.WriteUInt(tonumber(result[1].insurance_cooldown) or 0, 32)
        net.WriteUInt(tonumber(result[1].crash_count) or 0, 8)
        net.Send(ply)
    else
        net.Start("MyCarDealer_SyncInsurance")
        net.WriteString(vehicle_id)
        net.WriteBool(false)
        net.WriteUInt(0, 32)
        net.WriteUInt(0, 8)
        net.Send(ply)
    end
end

-- Hooks für automatische Schadenserkennung
hook.Add("EntityTakeDamage", "MyCarDealer_Insurance_Damage", function(target, dmginfo)
    if not IsValid(target) then return end
    if not target.CD_VehicleID then return end
    if not IsValid(target.CD_Owner) then return end
    
    local owner = target.CD_Owner
    local vehicle_id = target.CD_VehicleID
    
    -- Schwerer Schaden (>500 HP)
    if dmginfo:GetDamage() >= 500 then
        target.CD_HeavyDamage = (target.CD_HeavyDamage or 0) + 1
        
        -- Bei 3+ schweren Treffern = Unfall
        if target.CD_HeavyDamage >= 3 and not target.CD_InsuranceNotified then
            target.CD_InsuranceNotified = true
            
            local steamid = owner:SteamID64()
            local hasInsurance = MyCarDealer.SafeQuery(
                "SELECT insurance FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
                {steamid = steamid, vid = vehicle_id}
            )
            
            if hasInsurance and hasInsurance[1] and (hasInsurance[1].insurance == "1" or hasInsurance[1].insurance == 1) then
                timer.Simple(1, function()
                    if IsValid(owner) then
                        net.Start("MyCarDealer_InsuranceMenu")
                        net.WriteString(vehicle_id)
                        net.WriteString("accident")
                        net.Send(owner)
                    end
                end)
            end
        end
    end
end)

-- Fahrzeug zerstört (Totalschaden)
hook.Add("EntityRemoved", "MyCarDealer_Insurance_Destroyed", function(ent)
    if not ent.CD_VehicleID then return end
    if ent.CD_InsuranceClaimed then return end
    
    local owner = ent.CD_Owner
    if not IsValid(owner) then return end
    if not owner:IsPlayer() then return end
    
    local steamid = owner:SteamID64()
    local vehicle_id = ent.CD_VehicleID
    
    -- Prüfe Versicherung
    local result = MyCarDealer.SafeQuery(
        "SELECT insurance FROM mycardealer_inventory WHERE steamid = {steamid} AND vehicle_id = {vid}",
        {steamid = steamid, vid = vehicle_id}
    )
    
    if result and result[1] and (result[1].insurance == "1" or result[1].insurance == 1) then
        ent.CD_InsuranceClaimed = true
        
        timer.Simple(0.5, function()
            if IsValid(owner) then
                net.Start("MyCarDealer_InsuranceMenu")
                net.WriteString(vehicle_id)
                net.WriteString("totalLoss")
                net.Send(owner)
            end
        end)
    end
end)

-- Net Messages
net.Receive("MyCarDealer_BuyInsurance", function(len, ply)
    if not MyCarDealer.CheckCooldown(ply, "insurance_buy", 2) then return end
    local vehicle_id = net.ReadString()
    MyCarDealer.Insurance.Buy(ply, vehicle_id)
end)

net.Receive("MyCarDealer_ClaimInsurance", function(len, ply)
    if not MyCarDealer.CheckCooldown(ply, "insurance_claim", 5) then return end
    local vehicle_id = net.ReadString()
    local damageType = net.ReadString()
    MyCarDealer.Insurance.Claim(ply, vehicle_id, damageType)
end)

print("[Dynora Motor´s] Insurance module loaded (v4.0 - Realistic System)")
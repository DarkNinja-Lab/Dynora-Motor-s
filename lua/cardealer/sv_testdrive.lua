util.AddNetworkString("MyCarDealer_TestDriveStart")
util.AddNetworkString("MyCarDealer_TestDriveEnd")

MyCarDealer.TestDrives = MyCarDealer.TestDrives or {}

function MyCarDealer.StartTestDrive(ply, vehicleData)
    if MyCarDealer.TestDrives[ply:SteamID64()] then
        local oldData = MyCarDealer.TestDrives[ply:SteamID64()]
        if IsValid(oldData.vehicle) then
            oldData.vehicle:Remove()
        end
        if oldData.timer then
            timer.Remove(oldData.timer)
        end
    end
    
    local spawnPos = ply:GetPos() + ply:GetForward() * 200 + Vector(0, 0, 50)
    local spawnAng = Angle(0, ply:GetAngles().yaw, 0)
    
    local ent = nil
    if string.sub(vehicleData.class, 1, 4) == "lvs_" then
        ent = ents.Create(vehicleData.class)
        if IsValid(ent) then
            ent:SetPos(spawnPos)
            ent:SetAngles(spawnAng)
            ent:Spawn()
            ent:Activate()
        end
    else
        ent = ents.Create("prop_vehicle_jeep")
        if IsValid(ent) then
            ent:SetModel(vehicleData.model)
            ent:SetKeyValue("vehiclescript", vehicleData.vehicleScript or "scripts/vehicles/jeep_test.txt")
            ent:SetPos(spawnPos)
            ent:SetAngles(spawnAng)
            ent:Spawn()
            ent:Activate()
        end
    end
    
    if not IsValid(ent) then
        MyCarDealer.ChatPrint(ply, "Fehler beim Starten der Testfahrt!")
        return
    end
    
    ent:SetNW2Bool("CD_TestDrive", true)
    ent:SetNW2Entity("CD_Owner", ply)
    
    local timeLeft = MyCarDealer.Config.TestDriveTime or 60

    net.Start("MyCarDealer_TestDriveStart")
    net.WriteUInt(timeLeft, 16)
    net.Send(ply)
    
    local timerName = "TestDrive_" .. ply:SteamID64()
    timer.Create(timerName, 1, timeLeft, function()
        if not IsValid(ply) then
            if IsValid(ent) then ent:Remove() end
            timer.Remove(timerName)
            MyCarDealer.TestDrives[ply:SteamID64()] = nil
            return
        end
        
        timeLeft = timeLeft - 1
        
        if timeLeft <= 0 then
            net.Start("MyCarDealer_TestDriveEnd")
            net.Send(ply)
            
            if IsValid(ent) then ent:Remove() end
            MyCarDealer.TestDrives[ply:SteamID64()] = nil
            timer.Remove(timerName)
            
            MyCarDealer.ChatPrint(ply, "Testfahrt beendet!")
        elseif timeLeft <= 10 then
            MyCarDealer.ChatPrint(ply, "Testfahrt endet in " .. timeLeft .. " Sekunden!")
        end
    end)
    
    MyCarDealer.TestDrives[ply:SteamID64()] = {
        vehicle = ent,
        timer = timerName,
        startTime = CurTime()
    }
    
    MyCarDealer.ChatPrint(ply, "Testfahrt gestartet! " .. (MyCarDealer.Config.TestDriveTime or 60) .. " Sekunden verbleibend.")
    MyCarDealer.Log("TESTDRIVE", ply, vehicleData.name)
end

hook.Add("PlayerDisconnected", "MyCarDealer_CleanupTestDrive", function(ply)
    local steamID = ply:SteamID64()
    if MyCarDealer.TestDrives[steamID] then
        local data = MyCarDealer.TestDrives[steamID]
        if IsValid(data.vehicle) then
            data.vehicle:Remove()
        end
        if data.timer then
            timer.Remove(data.timer)
        end
        MyCarDealer.TestDrives[steamID] = nil
    end
end)

print("[Dynora Motor´s] sv_testdrive.lua loaded")
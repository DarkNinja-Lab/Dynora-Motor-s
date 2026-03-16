hook.Add("Think", "MyCarDealer_NeonThink", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    
    for _, ent in ipairs(ents.FindInSphere(lp:GetPos(), 1000)) do
        if IsValid(ent) and ent:GetNW2Bool("CD_Neon", false) then
            local col = ent:GetNW2Vector("CD_NeonColor", Vector(255, 0, 255))
       
            if ent:GetNW2Bool("CD_NeonSimfphys", false) then
                local dlight = DynamicLight(ent:EntIndex())
                if dlight then
                    dlight.pos = ent:GetPos() + Vector(0, 0, 30)
                    dlight.r = col.x
                    dlight.g = col.y
                    dlight.b = col.z
                    dlight.brightness = 3
                    dlight.Decay = 1000
                    dlight.Size = 150
                    dlight.DieTime = CurTime() + 0.05
                end
            end
        end
    end
end)

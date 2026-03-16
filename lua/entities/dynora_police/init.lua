AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/bmk/polizei/male07.mdl")
    self:SetUseType(SIMPLE_USE)

    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self:SetSequence("idle_all_01")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local jobTeam = _G["TEAM_POLICE"]
    if jobTeam and activator:Team() ~= jobTeam then
        -- Lila Chat Nachricht für Police NPC
        if MyCarDealer and MyCarDealer.ChatPrint then
            MyCarDealer.ChatPrint(activator, "Nur Polizeibeamte dürfen hier kaufen!")
        else
            activator:ChatPrint("[Dynora Motor´s] Nur Polizeibeamte dürfen hier kaufen!")
        end
        return
    end

    net.Start("MyCarDealer_OpenPoliceMenu")
    net.Send(activator)
end
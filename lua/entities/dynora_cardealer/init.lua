AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/player/hostage/hostage_01.mdl")
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

    net.Start("MyCarDealer_OpenMenu")
    net.Send(activator)
end

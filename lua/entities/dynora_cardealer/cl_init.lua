include("shared.lua")

function ENT:Initialize()
end

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 78)
    local ang = Angle(0, LocalPlayer():EyeAngles().yaw - 90, 90)
    
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    local alpha = math.Clamp(255 - (dist / 10), 100, 255)
    
    cam.Start3D2D(pos, ang, 0.08)
        local theme = MyCarDealer.Theme
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, alpha * 0.3)
        surface.DrawRect(-140, -35, 280, 70)
        draw.RoundedBox(8, -130, -30, 260, 60, Color(10, 10, 15, alpha))
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, alpha * 0.8)
        surface.DrawOutlinedRect(-130, -30, 260, 60, 2)
        surface.SetDrawColor(theme.primary)
        surface.DrawRect(-130, -30, 260, 3)
        draw.SimpleText("DYNORA MOTORS", "DermaDefaultBold", 0, -15, Color(theme.primary.r, theme.primary.g, theme.primary.b, alpha), TEXT_ALIGN_CENTER)
        draw.SimpleText("[E] Auto Händler", "DermaDefault", 0, 5, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        surface.SetDrawColor(theme.primary.r, theme.primary.g, theme.primary.b, alpha)
        surface.DrawRect(-130, -30, 20, 2)
        surface.DrawRect(-130, -30, 2, 20)
        surface.DrawRect(110, -30, 20, 2)
        surface.DrawRect(128, -30, 2, 20)
        surface.DrawRect(-130, 8, 20, 2)
        surface.DrawRect(-130, -10, 2, 20)
        surface.DrawRect(110, 8, 20, 2)
        surface.DrawRect(128, -10, 2, 20)
    cam.End3D2D()
end

net.Receive("MyCarDealer_OpenMenu", function()
    -- Sende NPC-Typ an Server
    net.Start("MyCarDealer_SetNPCType")
    net.WriteString("main")
    net.SendToServer()
    
    vgui.Create("MyCarDealer_Menu")
end)
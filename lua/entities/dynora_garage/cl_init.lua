
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
        
        surface.SetDrawColor(theme.success.r, theme.success.g, theme.success.b, alpha * 0.3)
        surface.DrawRect(-130, -35, 260, 70)
        
        draw.RoundedBox(8, -120, -30, 240, 60, Color(10, 15, 10, alpha))
        
        surface.SetDrawColor(theme.success.r, theme.success.g, theme.success.b, alpha * 0.8)
        surface.DrawOutlinedRect(-120, -30, 240, 60, 2)
        
        surface.SetDrawColor(theme.success)
        surface.DrawRect(-120, -30, 240, 3)
        
        draw.SimpleText("GARAGE", "DermaDefaultBold", 0, -15, Color(theme.success.r, theme.success.g, theme.success.b, alpha), TEXT_ALIGN_CENTER)
        
        draw.SimpleText("[E] FAHRZEUGE VERWALTEN", "DermaDefault", 0, 5, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(theme.success.r, theme.success.g, theme.success.b, alpha)
        surface.DrawRect(-120, -30, 15, 2)
        surface.DrawRect(-120, -30, 2, 15)
        surface.DrawRect(105, -30, 15, 2)
        surface.DrawRect(118, -30, 2, 15)
        surface.DrawRect(-120, 8, 15, 2)
        surface.DrawRect(-120, -5, 2, 15)
        surface.DrawRect(105, 8, 15, 2)
        surface.DrawRect(118, -5, 2, 15)
    cam.End3D2D()
end

net.Receive("MyCarDealer_OpenGarageMenu", function()
    net.Start("MyCarDealer_SetNPCType")
    net.WriteString("garage")
    net.SendToServer()
    
    vgui.Create("MyCarDealer_Inventory")
end)
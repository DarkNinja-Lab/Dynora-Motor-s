MyCarDealer = MyCarDealer or {}
MyCarDealer.Config = {}
MyCarDealer.Version = "4.0"

-- ============================================
-- KONFIGURATION
-- ============================================
MyCarDealer.Config.Debug = true
MyCarDealer.Config.Database = {Type = "sqlite"}
MyCarDealer.Config.SpawnDistance = 100
MyCarDealer.Config.MaxVehiclesPerPlayer = 5
MyCarDealer.Config.NeonPrice = 500
MyCarDealer.Config.SellReturnPercent = 0.7
MyCarDealer.Config.ActionCooldown = 1
MyCarDealer.Config.InsurancePrice = 5000
MyCarDealer.Config.TestDriveTime = 60

-- ============================================
-- THEME/FARBEN - CYBERPUNK STIL
-- ============================================
MyCarDealer.Theme = {
    -- Basis
    background = Color(5, 5, 10, 255),
    surface = Color(15, 15, 25, 240),
    surfaceHover = Color(25, 25, 40, 250),
    elevated = Color(20, 20, 35, 255),
    
    -- Primary (Lila)
    primary = Color(157, 78, 221),
    primaryLight = Color(200, 130, 255),
    primaryDark = Color(120, 50, 180),
    primaryGlow = Color(157, 78, 221, 80),
    
    -- Secondary (Cyan)
    secondary = Color(0, 200, 255),
    secondaryLight = Color(100, 230, 255),
    secondaryDark = Color(0, 140, 200),
    secondaryGlow = Color(0, 200, 255, 80),
    
    -- Akzente
    accent = Color(255, 140, 0),
    accentLight = Color(255, 180, 60),
    accentDark = Color(200, 100, 0),
    accentGlow = Color(255, 140, 0, 80),
    
    -- Semantic
    success = Color(0, 255, 150),
    warning = Color(255, 200, 50),
    error = Color(255, 80, 100),
    info = Color(100, 200, 255),
    
    -- Text
    textPrimary = Color(255, 255, 255),
    textSecondary = Color(180, 180, 200),
    textMuted = Color(120, 120, 140),
    textInverse = Color(10, 10, 15),
    
    -- Effekte
    glass = Color(255, 255, 255, 8),
    glassHover = Color(255, 255, 255, 15),
    border = Color(255, 255, 255, 10),
    borderActive = Color(157, 78, 221, 100),
    shadow = Color(0, 0, 0, 150),
    
    -- Gradients
    gradientStart = Color(157, 78, 221),
    gradientEnd = Color(0, 200, 255)
}

-- ============================================
-- DATEI-LADUNG
-- ============================================
if SERVER then
    include("cardealer/config.lua")
    include("cardealer/sv_database.lua")
    include("cardealer/sv_security.lua")
    include("cardealer/sv_spawnpoints.lua")
    include("cardealer/sv_main.lua")
    include("cardealer/sv_tuning.lua")
    include("cardealer/sv_inventory.lua")
    include("cardealer/sv_sellplayer.lua")
    include("cardealer/sv_testdrive.lua")
    include("cardealer/sv_insurance.lua")
    include("cardealer/sv_admin.lua")

    AddCSLuaFile("cardealer/config.lua")
    AddCSLuaFile("cardealer/cl_colors.lua")
    AddCSLuaFile("cardealer/cl_neon.lua")
    AddCSLuaFile("cardealer/cl_admin.lua")
    AddCSLuaFile("cardealer/cl_tuning.lua")
    AddCSLuaFile("cardealer/cl_inventory.lua")
    AddCSLuaFile("cardealer/cl_menu.lua")
    AddCSLuaFile("cardealer/cl_menu_police.lua")
    AddCSLuaFile("cardealer/cl_menu_garage.lua")
    AddCSLuaFile("cardealer/cl_sellplayer.lua")
    AddCSLuaFile("cardealer/cl_selloffer.lua")
    AddCSLuaFile("cardealer/cl_spawnpoints.lua")
    AddCSLuaFile("cardealer/cl_insurance.lua")
    AddCSLuaFile("cardealer/cl_npcspawnpoints.lua")
    AddCSLuaFile("cardealer/cl_chatcommands.lua")
else
    include("cardealer/config.lua")
    include("cardealer/cl_colors.lua")
    include("cardealer/cl_neon.lua")
    include("cardealer/cl_admin.lua")
    include("cardealer/cl_tuning.lua")
    include("cardealer/cl_inventory.lua")
    include("cardealer/cl_menu.lua")
    include("cardealer/cl_menu_police.lua")
    include("cardealer/cl_menu_garage.lua")
    include("cardealer/cl_sellplayer.lua")
    include("cardealer/cl_selloffer.lua")
    include("cardealer/cl_spawnpoints.lua")
    include("cardealer/cl_insurance.lua")
    include("cardealer/cl_chatcommands.lua")
end

print("[Dynora Motor´s] v" .. MyCarDealer.Version .. " loaded!")
MyCarDealer.Theme = {
    -- Basis
    background = Color(8, 8, 12, 255),
    surface = Color(18, 18, 25, 240),
    surfaceHover = Color(28, 28, 40, 250),
    elevated = Color(25, 25, 35, 255),
    
    -- Primary
    primary = Color(157, 78, 221),
    primaryLight = Color(188, 120, 255),
    primaryDark = Color(120, 50, 180),
    primaryGlow = Color(157, 78, 221, 80),
    
    -- Secondary
    secondary = Color(0, 168, 255),
    secondaryLight = Color(80, 200, 255),
    secondaryDark = Color(0, 120, 200),
    secondaryGlow = Color(0, 168, 255, 80),
    
    -- Akzente
    accent = Color(255, 140, 0),
    accentLight = Color(255, 180, 60),
    accentDark = Color(200, 100, 0),
    accentGlow = Color(255, 140, 0, 80),
    
    -- Semantic
    success = Color(0, 230, 150),
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
    
    -- Gradients (für Paint-Functions)
    gradientStart = Color(157, 78, 221),
    gradientEnd = Color(0, 168, 255)
}

function MyCarDealer.LerpColor(t, col1, col2)
    return Color(
        Lerp(t, col1.r, col2.r),
        Lerp(t, col1.g, col2.g),
        Lerp(t, col1.b, col2.b),
        Lerp(t, col1.a or 255, col2.a or 255)
    )
end

function MyCarDealer.DrawGradient(x, y, w, h, col1, col2, horizontal)
    surface.SetDrawColor(255, 255, 255, 255)
    
    for i = 0, horizontal and w or h do
        local t = i / (horizontal and w or h)
        local col = MyCarDealer.LerpColor(t, col1, col2)
        surface.SetDrawColor(col)
        
        if horizontal then
            surface.DrawRect(x + i, y, 1, h)
        else
            surface.DrawRect(x, y + i, w, 1)
        end
    end
end

function MyCarDealer.DrawGlow(x, y, w, h, color, intensity)
    intensity = intensity or 1
    for i = 1, 3 do
        local alpha = (color.a or 255) * intensity * (0.3 / i)
        surface.SetDrawColor(color.r, color.g, color.b, alpha)
        surface.DrawOutlinedRect(x - i, y - i, w + i*2, h + i*2)
    end
end

function MyCarDealer.DrawRoundedGlow(x, y, w, h, radius, color)
    draw.RoundedBox(radius, x, y, w, h, Color(color.r, color.g, color.b, 20))
    draw.RoundedBox(radius, x+1, y+1, w-2, h-2, Color(color.r, color.g, color.b, 40))
    draw.RoundedBox(radius, x+2, y+2, w-4, h-4, Color(color.r, color.g, color.b, 60))
end
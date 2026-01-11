KrPoints = KrPoints or {}
KrPoints.Points = KrPoints.Points or {}
KrPoints.ShowPoints = KrPoints.ShowPoints or 0

local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local draw_RoundedBoxEx = draw.RoundedBoxEx
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawRect = surface.DrawRect
local surface_PlaySound = surface.PlaySound
local math_sin = math.sin
local math_abs = math.abs

local cached_scrw, cached_scrh = ScrW(), ScrH()

hook.Add("OnScreenSizeChanged", "KrPoints.ScreenCache", function(old_w, old_h)
    cached_scrw, cached_scrh = ScrW(), ScrH()
end)

local COLOR_BG_DARK = KrPoints.HUD.BackgroundColor or Color(0, 0, 0, 200)
local COLOR_BG_DARKER = KrPoints.HUD.BackgroundColorDark or Color(0, 0, 0, 220)
local COLOR_ORANGE = KrPoints.HUD.OrangeColor or Color(255, 128, 0)
local COLOR_PINK = KrPoints.HUD.PinkColor or Color(255, 0, 128)

local COLOR_WHITE = KrPoints.White
local COLOR_BLUE = KrPoints.Blue
local COLOR_RED = KrPoints.Red
local COLOR_GREEN = KrPoints.Green
local COLOR_YELLOW = KrPoints.Yellow

-- Modern HUD Colors
local COLOR_GOLD = Color(212, 175, 55)
local COLOR_GOLD_DARK = Color(150, 120, 40)
local COLOR_GIVE_GLOW = Color(80, 200, 120)
local COLOR_TAKE_GLOW = Color(220, 60, 60)
local COLOR_BG_GRADIENT_TOP = Color(25, 25, 35, 240)
local COLOR_BG_GRADIENT_BOT = Color(15, 15, 20, 250)
local COLOR_ACCENT_LINE = Color(212, 175, 55, 180)
local COLOR_TEXT_DIM = Color(180, 180, 190)

surface.CreateFont("KrPoints_Font", {
    font = "Roboto",
    size = 23,
    weight = 1000,
})

surface.CreateFont("KrPoints_Title", {
    font = "Trebuchet MS",
    size = 18,
    weight = 700,
    italic = true,
})

surface.CreateFont("KrPoints_Mode", {
    font = "Roboto",
    size = 28,
    weight = 900,
})

surface.CreateFont("KrPoints_Points", {
    font = "Roboto",
    size = 42,
    weight = 900,
})

surface.CreateFont("KrPoints_Hint", {
    font = "Roboto",
    size = 13,
    weight = 500,
})

-- CRITICAL FIX: Define helper functions before use
local function validate_string_length(str, max_len)
    return str and #str > 0 and #str <= (max_len or 64)
end

local function clamp_points(points)
    return math.Clamp(points or 0, -100, 100)
end

net.Receive("KrPoints.Notify", function()
    local prof_name = net.ReadString()
    local house = net.ReadString()
    local points = net.ReadInt(16)

    if not validate_string_length(prof_name, 64) then return end
    if not validate_string_length(house, 32) then return end
    points = clamp_points(points)

    chat.AddText(
        COLOR_ORANGE, "PUAN - ",
        color_white, prof_name .. " isimli profesör ",
        COLOR_PINK, string.upper(house),
        color_white, " evine ",
        COLOR_PINK, tostring(points),
        color_white, " puan verdi."
    )
end)

local function DrawGradientBox(x, y, w, h, col_top, col_bot, radius)
    -- Draw gradient background with rounded corners
    draw_RoundedBox(radius, x, y, w, h, col_bot)
    
    -- Overlay gradient effect
    for i = 0, h / 2 do
        local alpha = Lerp(i / (h / 2), col_top.a, col_bot.a * 0.5)
        local r = Lerp(i / (h / 2), col_top.r, col_bot.r)
        local g = Lerp(i / (h / 2), col_top.g, col_bot.g)
        local b = Lerp(i / (h / 2), col_top.b, col_bot.b)
        
        surface_SetDrawColor(r, g, b, alpha * 0.3)
        surface_DrawRect(x + radius, y + i, w - radius * 2, 1)
    end
end

local function DrawGlowingBorder(x, y, w, h, color, pulse_speed)
    local pulse = math_abs(math_sin(CurTime() * pulse_speed)) * 0.5 + 0.5
    local glow_alpha = 100 + pulse * 80
    
    -- Outer glow
    for i = 1, 3 do
        local glow_col = Color(color.r, color.g, color.b, glow_alpha / (i * 1.5))
        draw_RoundedBox(12 + i, x - i, y - i, w + i * 2, h + i * 2, glow_col)
    end
end

function KrPoints_DrawProfHud()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_puan" then return end

    local scrw, scrh = cached_scrw, cached_scrh
    
    -- HUD Dimensions
    local box_w = 240
    local box_h = 100
    local box_x = (scrw / 2) - (box_w / 2)
    local box_y = scrh - box_h - 20
    
    local current_points = wep:GetSelectedPoints() or 1
    local is_give_mode = wep:GetGiveMode()
    if is_give_mode == nil then is_give_mode = true end
    
    local mode_color = is_give_mode and COLOR_GIVE_GLOW or COLOR_TAKE_GLOW
    local mode_text = is_give_mode and "VER" or "AL"
    local status_text = is_give_mode and "Verilecek Puan" or "Alınacak Puan"
    
    -- Animated glow border
    DrawGlowingBorder(box_x, box_y, box_w, box_h, mode_color, 2.5)
    
    -- Main background with gradient
    DrawGradientBox(box_x, box_y, box_w, box_h, COLOR_BG_GRADIENT_TOP, COLOR_BG_GRADIENT_BOT, 12)
    
    -- Gold accent line at top
    draw_RoundedBoxEx(12, box_x, box_y, box_w, 3, COLOR_ACCENT_LINE, true, true, false, false)
    
    -- Title with magical flair
    local title_pulse = math_abs(math_sin(CurTime() * 1.5)) * 30
    local title_color = Color(COLOR_GOLD.r, COLOR_GOLD.g + title_pulse, COLOR_GOLD.b, 255)
    draw_SimpleText("✦ PUAN SİSTEMİ ✦", "KrPoints_Title", box_x + box_w / 2, box_y + 12, title_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Divider line
    surface_SetDrawColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 60)
    surface_DrawRect(box_x + 20, box_y + 30, box_w - 40, 1)
    
    -- Mode indicator box
    local mode_box_w = 70
    local mode_box_h = 28
    local mode_box_x = box_x + 15
    local mode_box_y = box_y + 40
    
    -- Mode background with glow
    local mode_bg_color = Color(mode_color.r, mode_color.g, mode_color.b, 40)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, mode_bg_color)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, Color(0, 0, 0, 100))
    
    -- Mode text
    draw_SimpleText(mode_text, "KrPoints_Mode", mode_box_x + mode_box_w / 2, mode_box_y + mode_box_h / 2, mode_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Points display with animated pulse
    local points_pulse = 1 + math_abs(math_sin(CurTime() * 3)) * 0.1
    local points_x = box_x + box_w - 50
    local points_y = box_y + 48
    
    -- Points glow effect
    local points_glow = Color(mode_color.r, mode_color.g, mode_color.b, 80)
    draw_SimpleText(current_points, "KrPoints_Points", points_x + 2, points_y + 2, points_glow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw_SimpleText(current_points, "KrPoints_Points", points_x, points_y, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Status text
    draw_SimpleText(status_text, "KrPoints_Hint", mode_box_x + mode_box_w + 10, mode_box_y + mode_box_h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Control hints at bottom
    local hint_y = box_y + box_h - 18
    draw_SimpleText("Sağ Tık: Mod Değiştir", "KrPoints_Hint", box_x + 15, hint_y, Color(150, 150, 160, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw_SimpleText("R: Puan Ayarla", "KrPoints_Hint", box_x + box_w - 15, hint_y, Color(150, 150, 160, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "KrPoints.WeaponHUD", KrPoints_DrawProfHud)

local house_data = {
    ["gryffindor"] = {KrPoints.LogoGryffindor, COLOR_RED, "Gryffindor"},
    ["ravenclaw"] = {KrPoints.LogoRavenclaw, COLOR_BLUE, "Ravenclaw"},
    ["slytherin"] = {KrPoints.LogoSlytherin, COLOR_GREEN, "Slytherin"},
    ["hufflepuff"] = {KrPoints.LogoHufflepuff, COLOR_YELLOW, "Hufflepuff"},
}

local notification_queue = {}
local is_notification_active = false

local function validate_house(house)
    if not house or house == "" then return false end
    local house_lower = string.lower(house)
    return house_data[house_lower] ~= nil
end

local function validate_mode(mode)
    return mode == "ver" or mode == "al"
end

local function draw_notification_hud(data)
    local scrw, scrh = cached_scrw, cached_scrh
    local box_w, box_h = scrw * 0.3, scrh * 0.1
    local box_x = (scrw / 2) - (box_w / 2)
    local box_y = scrh * 0.01

    draw_RoundedBox(20, box_x, box_y, box_w, box_h, COLOR_BG_DARKER)

    if data.logo then
        surface_SetDrawColor(255, 255, 255, 255)
        surface_SetMaterial(data.logo)
        surface_DrawTexturedRect(box_x + scrw * 0.005, 10, 90, 80)
    end

    local text_x = box_x + scrw * 0.08
    draw_SimpleText(data.house .. " Hanesi Puan " .. data.action_text, "KrPoints_Font", text_x, scrh * 0.015, color_white)
    draw_SimpleText(data.student, "KrPoints_Font", box_x + scrw * 0.1, scrh * 0.05, color_white)
    draw_SimpleText(data.given_text .. " Puan: ", "KrPoints_Font", box_x + scrw * 0.1, scrh * 0.08, data.prof_color)
    draw_SimpleText(data.points, "KrPoints_Font", box_x + scrw * 0.195, scrh * 0.08, color_white)
end

local function process_notification_queue()
    if #notification_queue == 0 then
        is_notification_active = false
        hook.Remove("HUDPaint", "KrPoints.NotificationHud")
        timer.Remove("KrPoints.NotificationTimer")
        return
    end

    local current_notification = table.remove(notification_queue, 1)
    is_notification_active = true

    hook.Add("HUDPaint", "KrPoints.NotificationHud", function()
        if not current_notification then
            hook.Remove("HUDPaint", "KrPoints.NotificationHud")
            return
        end
        draw_notification_hud(current_notification)
    end)

    local display_time = KrPoints.HudDuration or 3
    timer.Remove("KrPoints.NotificationTimer")
    timer.Create("KrPoints.NotificationTimer", display_time, 1, function()
        process_notification_queue()
    end)
end

local function queue_notification(data)
    table.insert(notification_queue, data)
    if not is_notification_active then
        process_notification_queue()
    end
end

net.Receive("KrPoints.SyncPoints", function()
    local mode = net.ReadString()
    local prof = net.ReadString()
    local house = net.ReadString()
    local student = net.ReadString()
    local points = net.ReadInt(16)

    if not validate_mode(mode) then return end
    if not validate_string_length(prof, 64) then return end
    if not validate_string_length(house, 32) then return end
    if not validate_string_length(student, 64) then return end
    points = clamp_points(points)

    local logo, house_color, display_house
    local house_info = house_data[string.lower(house)]
    if house_info then
        logo = house_info[1]
        house_color = house_info[2]
        display_house = house_info[3]
    else
        return
    end

    local notification_data = {
        logo = logo,
        color = house_color,
        house = display_house or house,
        prof = prof,
        student = student,
        points = points,
        action_text = (mode == "ver") and "Kazandı" or "Kaybetti",
        given_text = (mode == "ver") and "Kazanılan" or "Kaybedilen",
        prof_color = (mode == "ver") and COLOR_BLUE or COLOR_RED,
    }

    surface_PlaySound("modernrewards/success.wav")
    queue_notification(notification_data)
end)

hook.Add("ShutDown", "KrPoints.Cleanup", function()
    timer.Remove("KrPoints.NotificationTimer")
    hook.Remove("HUDPaint", "KrPoints.NotificationHud")
    hook.Remove("HUDPaint", "KrPoints.WeaponHUD")
    hook.Remove("OnScreenSizeChanged", "KrPoints.ScreenCache")
end)

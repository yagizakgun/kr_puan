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

local COLOR_GOLD = Color(212, 175, 55)
local COLOR_GOLD_DARK = Color(150, 120, 40)
local COLOR_GIVE_GLOW = Color(80, 200, 120)
local COLOR_TAKE_GLOW = Color(220, 60, 60)
local COLOR_BG_GRADIENT_TOP = Color(25, 25, 35, 240)
local COLOR_BG_GRADIENT_BOT = Color(15, 15, 20, 250)
local COLOR_ACCENT_LINE = Color(212, 175, 55, 180)
local COLOR_TEXT_DIM = Color(180, 180, 190)

local function CreateKrFont(name, font, size, weight, options)
    options = options or {}
    surface.CreateFont(name, {
        font = font,
        size = size,
        weight = weight,
        italic = options.italic or false,
        extended = options.extended ~= false, 
        antialias = options.antialias ~= false, 
        shadow = options.shadow or false,
    })
end

CreateKrFont("KrPoints_Font", "Crimson Text", 22, 600)
CreateKrFont("KrPoints_Title", "Cinzel Decorative", 24, 700, {shadow = true})
CreateKrFont("KrPoints_Mode", "Crimson Text", 30, 800)
CreateKrFont("KrPoints_Points", "IM Fell English", 50, 800)
CreateKrFont("KrPoints_Hint", "Crimson Text", 16, 600)
CreateKrFont("KrPoints_Notification_Title", "Cinzel Decorative", 20, 800, {shadow = true})
CreateKrFont("KrPoints_Notification_Subtitle", "Crimson Text", 16, 600)
CreateKrFont("KrPoints_Notification_Points", "IM Fell English", 28, 900)

local function validate_string_length(str, max_len)
    return str and #str > 0 and #str <= (max_len or 64)
end

local function clamp_points(points)
    return math.Clamp(points or 0, -100, 100)
end

local function CalculatePulse(speed, min_val, max_val)
    min_val = min_val or 0
    max_val = max_val or 1
    local pulse = math_abs(math_sin(CurTime() * speed))
    return min_val + pulse * (max_val - min_val)
end

local function ScaleColor(color, scale, alpha)
    return Color(color.r * scale, color.g * scale, color.b * scale, alpha)
end

local function DrawGlowBorder(x, y, w, h, color, radius, layers, spread_multiplier)
    layers = layers or 3
    spread_multiplier = spread_multiplier or 1.5
    
    for i = 1, layers do
        local offset = i * spread_multiplier
        local alpha = color.a / (i * 1.5)
        local glow_col = Color(color.r, color.g, color.b, alpha)
        draw_RoundedBox(radius + i, x - offset, y - offset, w + offset * 2, h + offset * 2, glow_col)
    end
end

local function DrawTextWithGlow(text, font, x, y, color, glow_intensity, align_h, align_v, glow_offset)
    glow_offset = glow_offset or 2
    glow_intensity = glow_intensity or 80
    
    -- Glow
    local glow_col = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, glow_intensity)
    draw_SimpleText(text, font, x + glow_offset, y + glow_offset, glow_col, align_h, align_v)
    
    -- Ana text
    draw_SimpleText(text, font, x, y, color, align_h, align_v)
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
    draw_RoundedBox(radius, x, y, w, h, col_bot)
    
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
    local glow_alpha = CalculatePulse(pulse_speed, 100, 180)
    local animated_color = Color(color.r, color.g, color.b, glow_alpha)
    DrawGlowBorder(x, y, w, h, animated_color, 12, 3, 1)
end

function KrPoints_DrawProfHud()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_puan" then return end

    local scrw, scrh = cached_scrw, cached_scrh
    
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
    
    DrawGlowingBorder(box_x, box_y, box_w, box_h, mode_color, 2.5)
    
    DrawGradientBox(box_x, box_y, box_w, box_h, COLOR_BG_GRADIENT_TOP, COLOR_BG_GRADIENT_BOT, 12)
    
    
    local title_pulse = CalculatePulse(1.5, 0, 30)
    local title_color = Color(COLOR_GOLD.r, COLOR_GOLD.g + title_pulse, COLOR_GOLD.b, 255)
    draw_SimpleText("PUAN SİSTEMİ", "KrPoints_Title", box_x + box_w / 2, box_y + 12, title_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    surface_SetDrawColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 60)
    surface_DrawRect(box_x + 20, box_y + 34, box_w - 40, 1)
    
    local mode_box_w = 70
    local mode_box_h = 28
    local mode_box_x = box_x + 15
    local mode_box_y = box_y + 40
    
    local mode_bg_color = Color(mode_color.r, mode_color.g, mode_color.b, 40)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, mode_bg_color)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, Color(0, 0, 0, 100))
    
    draw_SimpleText(mode_text, "KrPoints_Mode", mode_box_x + mode_box_w / 2, mode_box_y + mode_box_h / 2, mode_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local points_x = box_x + box_w - 50
    local points_y = box_y + 48
    
    DrawTextWithGlow(current_points, "KrPoints_Points", points_x, points_y, COLOR_WHITE, 80, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2)
    
    draw_SimpleText(status_text, "KrPoints_Hint", mode_box_x + mode_box_w + 10, mode_box_y + mode_box_h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    local hint_y = box_y + box_h - 18
    draw_SimpleText("Sağ Tık: Mod Değiştir", "KrPoints_Hint", box_x + 15, hint_y, Color(150, 150, 160, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw_SimpleText("R: Puan Ayarla", "KrPoints_Hint", box_x + 10 + box_w - 15, hint_y, Color(150, 150, 160, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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
local notification_start_time = 0
local notification_duration = 3

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
    
    local elapsed = CurTime() - notification_start_time
    local progress = math.Clamp(elapsed / notification_duration, 0, 1)
    
    local slide_progress = math.Clamp(elapsed / 0.3, 0, 1)
    slide_progress = 1 - math.pow(1 - slide_progress, 3) 
    
    local fade_alpha = 1
    if progress > 0.87 then
        fade_alpha = 1 - ((progress - 0.87) / 0.13)
    end
    
    local box_w = scrw * 0.35  
    local box_h = 110  
    local box_x = (scrw / 2) - (box_w / 2)
    local target_y = scrh * 0.05
    local box_y = target_y - (1 - slide_progress) * 200
    
    local logo_size = 75  
    local logo_padding = 15  
    
    local pulse = CalculatePulse(2, 0.7, 1.0)
    local glow_alpha = 70 * pulse * fade_alpha
    DrawGlowBorder(box_x, box_y, box_w, box_h, Color(data.color.r, data.color.g, data.color.b, glow_alpha), 12, 3, 1.5)
    
    DrawGradientBox(box_x, box_y, box_w, box_h, 
        Color(20, 20, 30, 245 * fade_alpha), 
        Color(10, 10, 15, 255 * fade_alpha), 12)
    
    local logo_box_x = box_x + logo_padding
    local logo_box_y = box_y + (box_h / 2) - (logo_size / 2)
    
    local logo_bg_pulse = CalculatePulse(1.5, 0.8, 1.0)
    local logo_bg_color = ScaleColor(data.color, 0.3, 160 * fade_alpha * logo_bg_pulse)
    draw_RoundedBox(8, logo_box_x - 4, logo_box_y - 4, logo_size + 8, logo_size + 8, logo_bg_color)
    
    local logo_border_color = Color(data.color.r, data.color.g, data.color.b, 50 * fade_alpha)
    DrawGlowBorder(logo_box_x - 4, logo_box_y - 4, logo_size + 8, logo_size + 8, logo_border_color, 8, 2, 1)
    
    if data.logo then
        surface_SetDrawColor(255, 255, 255, 255 * fade_alpha)
        surface_SetMaterial(data.logo)
        surface_DrawTexturedRect(logo_box_x, logo_box_y, logo_size, logo_size)
    end
    
    local text_gap = 15  
    local text_start_x = logo_box_x + logo_size + text_gap
    local text_area_w = box_w - (logo_box_x - box_x) - logo_size - text_gap - logo_padding
    
    local title_h = 22  
    local divider_spacing = 10
    local divider_h = 1
    local student_spacing = 10
    local student_h = 28  
    local total_text_h = title_h + divider_spacing + divider_h + student_spacing + student_h
    
    local text_content_start_y = box_y + (box_h / 2) - (total_text_h / 2)
    
    local title_y = text_content_start_y
    local title_text = data.house .. " " .. data.action_text
    local title_color = Color(data.color.r, data.color.g, data.color.b, 255 * fade_alpha)
    
    local title_center_x = text_start_x + (text_area_w / 2)
    
    local title_glow_offset = math_sin(CurTime() * 3) * 0.8
    DrawTextWithGlow(title_text, "KrPoints_Notification_Title", title_center_x, title_y, 
        title_color, 100 * fade_alpha, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, title_glow_offset)
    
    local divider_y = title_y + title_h + divider_spacing
    local divider_progress = math.Clamp((elapsed - 0.2) / 0.3, 0, 1)
    local divider_max_w = text_area_w * 0.8  
    local divider_w = divider_max_w * divider_progress
    local divider_x = text_start_x + (text_area_w / 2) - (divider_w / 2)
    
    surface_SetDrawColor(data.color.r, data.color.g, data.color.b, 120 * fade_alpha)
    surface_DrawRect(divider_x, divider_y, divider_w, 1)
    
    local student_y = divider_y + divider_h + student_spacing
    local student_color = Color(220, 220, 230, 255 * fade_alpha)
    local student_prefix = "Öğrenci: "
    local student_text = data.student
    
    surface.SetFont("KrPoints_Notification_Subtitle")
    local prefix_w, student_text_h = surface.GetTextSize(student_prefix)
    local student_text_w = surface.GetTextSize(student_text)
    local puan_label_w = surface.GetTextSize("PUAN")
    
    local points_box_w = 65
    local points_box_h = 28
    local spacing_1 = 8  
    local spacing_2 = 8  
    
    local total_width = prefix_w + student_text_w + spacing_1 + points_box_w + spacing_2 + puan_label_w
    
    local group_start_x = text_start_x + (text_area_w / 2) - (total_width / 2)
    
    draw_SimpleText(student_prefix, "KrPoints_Notification_Subtitle", 
        group_start_x, student_y, Color(160, 160, 170, 255 * fade_alpha), 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    draw_SimpleText(student_text, "KrPoints_Notification_Subtitle", 
        group_start_x + prefix_w, student_y, student_color, 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local points_box_x = group_start_x + prefix_w + student_text_w + spacing_1
    local points_y = student_y + (student_text_h / 2) - (points_box_h / 2)
    
    local points_pulse = CalculatePulse(2.5, 0.85, 1.0)
    local points_box_color = ScaleColor(data.prof_color, 0.4, 160 * fade_alpha * points_pulse)
    draw_RoundedBox(4, points_box_x, points_y, points_box_w, points_box_h, points_box_color)
    
    draw_RoundedBox(4, points_box_x, points_y, points_box_w, 2, 
        Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 240 * fade_alpha))
    
    local points_text = (data.points > 0 and "+" or "") .. tostring(data.points)
    local points_text_color = Color(255, 255, 255, 255 * fade_alpha)
    local points_center_x = points_box_x + points_box_w / 2
    local points_center_y = points_y + points_box_h / 2
    
    local points_glow_offset = CalculatePulse(3, 0, 1)
    local points_glow_color = Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 70 * fade_alpha)
    draw_SimpleText(points_text, "KrPoints_Notification_Points", 
        points_center_x + points_glow_offset, points_center_y + points_glow_offset, 
        points_glow_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw_SimpleText(points_text, "KrPoints_Notification_Points", 
        points_center_x, points_center_y, points_text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local label_x = points_box_x + points_box_w + spacing_2
    local label_color = Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 255 * fade_alpha)
    
    draw_SimpleText("PUAN", "KrPoints_Notification_Subtitle", 
        label_x, student_y, label_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local progress_bar_h = 3
    local progress_bar_y = box_y + box_h - progress_bar_h
    local progress_bar_w = box_w * (1 - progress)
    
    surface_SetDrawColor(data.color.r, data.color.g, data.color.b, 160 * fade_alpha)
    draw_RoundedBoxEx(0, box_x, progress_bar_y, progress_bar_w, progress_bar_h, 
        Color(data.color.r, data.color.g, data.color.b, 160 * fade_alpha), 
        false, false, true, true)
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
    notification_start_time = CurTime()
    notification_duration = KrPoints.NotificationDuration or 3

    hook.Add("HUDPaint", "KrPoints.NotificationHud", function()
        if not current_notification then
            hook.Remove("HUDPaint", "KrPoints.NotificationHud")
            return
        end
        draw_notification_hud(current_notification)
    end)

    timer.Remove("KrPoints.NotificationTimer")
    timer.Create("KrPoints.NotificationTimer", notification_duration, 1, function()
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
    if not KrPoints.ShowNotificationHud then return end
    
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
    
    if mode == "al" and points > 0 then
        points = -points
    end

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
        action_text = (mode == "ver") and "Puan Kazandı" or "Puan Kaybetti",
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

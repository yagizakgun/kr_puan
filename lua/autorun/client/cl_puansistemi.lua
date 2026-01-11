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

surface.CreateFont("KrPoints_Font", {
    font = "Crimson Text", -- Roboto yerine bunu kullanıyoruz
    size = 22,
    weight = 600,
    extended = true,
    antialias = true,
})

surface.CreateFont("KrPoints_Title", {
    font = "Cinzel Decorative", -- Dosya adı tam böyle olmalı
    size = 24, -- 18 biraz küçüktü, 24 daha okunaklı olur
    weight = 700,
    italic = false, -- Italic bazen okunabilirliği düşürür, düz daha asil durur
    extended = true, -- TÜRKÇE KARAKTERLER (İ, ş, ğ) İÇİN ŞART!
    antialias = true,
    shadow = true, -- Hafif gölge ekler, büyü hissi verir
})
surface.CreateFont("KrPoints_Mode", {
    font = "Crimson Text", -- Veya 'EB Garamond'
    size = 30, -- Kutunun içini doldurması için
    weight = 800, -- Kalın olması lazım ki mühür gibi dursun
    extended = true,
    antialias = true,
})

surface.CreateFont("KrPoints_Points", {
    font = "IM Fell English", -- Eski kitap baskısı havası verir
    size = 50, -- Sayı odak noktası olduğu için iyice büyüttük
    weight = 800,
    extended = true,
    antialias = true,
})

surface.CreateFont("KrPoints_Hint", {
    font = "Crimson Text", -- Küçük boyutta bile okunaklıdır
    size = 16, -- 13 çok küçük kalabilir, 16 ideal
    weight = 600,
    extended = true,
    antialias = true,
    shadow = false, -- Küçük yazıda gölge bozar, kapattık
})

surface.CreateFont("KrPoints_Notification_Title", {
    font = "Roboto",
    size = 32,
    weight = 900,
})

surface.CreateFont("KrPoints_Notification_Subtitle", {
    font = "Roboto",
    size = 20,
    weight = 600,
})

surface.CreateFont("KrPoints_Notification_Points", {
    font = "Roboto",
    size = 48,
    weight = 900,
})

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
    local pulse = math_abs(math_sin(CurTime() * pulse_speed)) * 0.5 + 0.5
    local glow_alpha = 100 + pulse * 80
    
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
    
    draw_RoundedBoxEx(12, box_x, box_y, box_w, 3, COLOR_ACCENT_LINE, true, true, false, false)
    
    local title_pulse = math_abs(math_sin(CurTime() * 1.5)) * 30
    local title_color = Color(COLOR_GOLD.r, COLOR_GOLD.g + title_pulse, COLOR_GOLD.b, 255)
    draw_SimpleText("PUAN SİSTEMİ", "KrPoints_Title", box_x + box_w / 2, box_y + 12, title_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    surface_SetDrawColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 60)
    surface_DrawRect(box_x + 20, box_y + 30, box_w - 40, 1)
    
    local mode_box_w = 70
    local mode_box_h = 28
    local mode_box_x = box_x + 15
    local mode_box_y = box_y + 40
    
    local mode_bg_color = Color(mode_color.r, mode_color.g, mode_color.b, 40)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, mode_bg_color)
    draw_RoundedBox(6, mode_box_x, mode_box_y, mode_box_w, mode_box_h, Color(0, 0, 0, 100))
    
    draw_SimpleText(mode_text, "KrPoints_Mode", mode_box_x + mode_box_w / 2, mode_box_y + mode_box_h / 2, mode_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local points_pulse = 1 + math_abs(math_sin(CurTime() * 3)) * 0.1
    local points_x = box_x + box_w - 50
    local points_y = box_y + 48
    
    local points_glow = Color(mode_color.r, mode_color.g, mode_color.b, 80)
    draw_SimpleText(current_points, "KrPoints_Points", points_x + 2, points_y + 2, points_glow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw_SimpleText(current_points, "KrPoints_Points", points_x, points_y, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw_SimpleText(status_text, "KrPoints_Hint", mode_box_x + mode_box_w + 10, mode_box_y + mode_box_h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
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
    
    -- Animasyon hesaplamaları
    local elapsed = CurTime() - notification_start_time
    local progress = math.Clamp(elapsed / notification_duration, 0, 1)
    
    -- Slide-in animasyonu (ilk 0.3 saniye)
    local slide_progress = math.Clamp(elapsed / 0.3, 0, 1)
    slide_progress = 1 - math.pow(1 - slide_progress, 3) -- Ease-out cubic
    
    -- Fade-out animasyonu (son 0.4 saniye)
    local fade_alpha = 1
    if progress > 0.87 then
        fade_alpha = 1 - ((progress - 0.87) / 0.13)
    end
    
    -- Boyutlar
    local box_w = scrw * 0.45
    local box_h = 160
    local box_x = (scrw / 2) - (box_w / 2)
    local target_y = scrh * 0.05
    local box_y = target_y - (1 - slide_progress) * 200
    
    -- Logo boyutları
    local logo_size = 120
    local logo_padding = 15
    
    -- Glow efekti
    local pulse = math_abs(math_sin(CurTime() * 2)) * 0.3 + 0.7
    local glow_color = Color(data.color.r, data.color.g, data.color.b, 80 * pulse * fade_alpha)
    
    for i = 1, 4 do
        local glow_offset = i * 2
        local glow_alpha = (80 / i) * pulse * fade_alpha
        draw_RoundedBox(16 + i, box_x - glow_offset, box_y - glow_offset, 
            box_w + glow_offset * 2, box_h + glow_offset * 2, 
            Color(data.color.r, data.color.g, data.color.b, glow_alpha))
    end
    
    -- Arka plan gradient
    DrawGradientBox(box_x, box_y, box_w, box_h, 
        Color(20, 20, 30, 245 * fade_alpha), 
        Color(10, 10, 15, 255 * fade_alpha), 16)
    
    -- Üst kenar vurgusu
    local accent_color = Color(data.color.r, data.color.g, data.color.b, 220 * fade_alpha)
    draw_RoundedBoxEx(16, box_x, box_y, box_w, 5, accent_color, true, true, false, false)
    
    -- Logo arka plan kutusu
    local logo_box_x = box_x + logo_padding
    local logo_box_y = box_y + (box_h / 2) - (logo_size / 2)
    
    local logo_bg_pulse = math_abs(math_sin(CurTime() * 1.5)) * 0.2 + 0.8
    local logo_bg_color = Color(data.color.r * 0.3, data.color.g * 0.3, data.color.b * 0.3, 180 * fade_alpha * logo_bg_pulse)
    draw_RoundedBox(12, logo_box_x - 5, logo_box_y - 5, logo_size + 10, logo_size + 10, logo_bg_color)
    
    -- Logo border
    local logo_border_color = Color(data.color.r, data.color.g, data.color.b, 255 * fade_alpha)
    for i = 1, 2 do
        draw_RoundedBox(12, logo_box_x - 5 - i, logo_box_y - 5 - i, 
            logo_size + 10 + i * 2, logo_size + 10 + i * 2, 
            Color(logo_border_color.r, logo_border_color.g, logo_border_color.b, (60 / i) * fade_alpha))
    end
    
    -- Logo çizimi
    if data.logo then
        surface_SetDrawColor(255, 255, 255, 255 * fade_alpha)
        surface_SetMaterial(data.logo)
        surface_DrawTexturedRect(logo_box_x, logo_box_y, logo_size, logo_size)
    end
    
    -- Text alanı başlangıcı
    local text_start_x = logo_box_x + logo_size + 25
    local text_area_w = box_w - (logo_size + logo_padding * 2 + 25) - 20
    
    -- Ev ismi ve aksiyon
    local title_y = box_y + 20
    local title_text = data.house .. " " .. data.action_text
    local title_color = Color(data.color.r, data.color.g, data.color.b, 255 * fade_alpha)
    
    -- Title glow efekti
    local title_glow_offset = math_sin(CurTime() * 3) * 1
    draw_SimpleText(title_text, "KrPoints_Notification_Title", 
        text_start_x + title_glow_offset, title_y + title_glow_offset, 
        Color(title_color.r * 0.5, title_color.g * 0.5, title_color.b * 0.5, 120 * fade_alpha), 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    draw_SimpleText(title_text, "KrPoints_Notification_Title", 
        text_start_x, title_y, title_color, 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Ayırıcı çizgi
    local divider_y = title_y + 38
    local divider_progress = math.Clamp((elapsed - 0.2) / 0.3, 0, 1)
    local divider_w = text_area_w * divider_progress
    surface_SetDrawColor(data.color.r, data.color.g, data.color.b, 100 * fade_alpha)
    surface_DrawRect(text_start_x, divider_y, divider_w, 2)
    
    -- Öğrenci ismi
    local student_y = divider_y + 12
    local student_color = Color(220, 220, 230, 255 * fade_alpha)
    draw_SimpleText("Öğrenci: " .. data.student, "KrPoints_Notification_Subtitle", 
        text_start_x, student_y, student_color, 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Puan kutsu
    local points_y = student_y + 32
    local points_box_w = 120
    local points_box_h = 50
    local points_box_x = text_start_x
    
    -- Puan kutusu arka plan
    local points_pulse = math_abs(math_sin(CurTime() * 2.5)) * 0.15 + 0.85
    local points_box_color = Color(data.prof_color.r * 0.4, data.prof_color.g * 0.4, data.prof_color.b * 0.4, 200 * fade_alpha * points_pulse)
    draw_RoundedBox(8, points_box_x, points_y, points_box_w, points_box_h, points_box_color)
    
    -- Puan border
    draw_RoundedBox(8, points_box_x, points_y, points_box_w, 2, 
        Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 255 * fade_alpha))
    
    -- Puan değeri
    local points_text = (data.points > 0 and "+" or "") .. data.points
    local points_text_color = Color(255, 255, 255, 255 * fade_alpha)
    
    -- Puan glow
    local points_glow = math_abs(math_sin(CurTime() * 3)) * 2
    draw_SimpleText(points_text, "KrPoints_Notification_Points", 
        points_box_x + points_box_w / 2 + points_glow, points_y + points_box_h / 2 + points_glow, 
        Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 100 * fade_alpha), 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw_SimpleText(points_text, "KrPoints_Notification_Points", 
        points_box_x + points_box_w / 2, points_y + points_box_h / 2, 
        points_text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- "PUAN" etiketi
    local label_x = points_box_x + points_box_w + 10
    local label_y = points_y + 8
    draw_SimpleText(data.given_text, "KrPoints_Notification_Subtitle", 
        label_x, label_y, Color(180, 180, 190, 255 * fade_alpha), 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    draw_SimpleText("PUAN", "KrPoints_Notification_Subtitle", 
        label_x, label_y + 24, Color(data.prof_color.r, data.prof_color.g, data.prof_color.b, 255 * fade_alpha), 
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Alt progress bar
    local progress_bar_h = 4
    local progress_bar_y = box_y + box_h - progress_bar_h
    local progress_bar_w = box_w * (1 - progress)
    
    surface_SetDrawColor(data.color.r, data.color.g, data.color.b, 180 * fade_alpha)
    draw_RoundedBoxEx(0, box_x, progress_bar_y, progress_bar_w, progress_bar_h, 
        Color(data.color.r, data.color.g, data.color.b, 180 * fade_alpha), 
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
    notification_duration = KrPoints.HudDuration or 3

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

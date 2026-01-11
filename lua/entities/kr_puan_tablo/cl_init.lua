include("shared.lua")

local MAT_BG = Material("kr_puan/hogwarts_bg.png", "noclamp smooth")
local MAT_CRESTS = {
    Gryffindor = Material("rlib/interface/grunge/banners/hogwarts/em_gr.png", "noclamp smooth"),
    Hufflepuff = Material("rlib/interface/grunge/banners/hogwarts/em_hu.png", "noclamp smooth"),
    Ravenclaw  = Material("rlib/interface/grunge/banners/hogwarts/em_ra.png", "noclamp smooth"),
    Slytherin  = Material("rlib/interface/grunge/banners/hogwarts/em_sl.png", "noclamp smooth"),
}

local COLORS = {
    Gryffindor = Color(167, 0, 0),
    Hufflepuff = Color(201, 152, 18),
    Ravenclaw  = Color(36, 92, 170),
    Slytherin  = Color(11, 85, 11),
    White      = Color(255, 255, 255),
    Black      = Color(0, 0, 0),
    PanelBG    = Color(20, 20, 20, 200),
    BarBG      = Color(30, 30, 30, 180),
}

local RENDER_DISTANCE_SQR = 650 * 650
local LERP_SPEED = 4
local MIN_BAR_WIDTH = 20
local MIN_SCALE_REF = 250

local LAYOUT = {
    CANVAS_WIDTH = 1200,
    CANVAS_HEIGHT = 1400,
    
    TITLE_Y = 50,
    
    HOUSES_START_X = 100,
    HOUSES_START_Y = 300,
    HOUSE_WIDTH = 250,
    HOUSE_SPACING = 25,
    
    CREST_SIZE = 120,
    CREST_OFFSET_Y = 0,
    
    BAR_WIDTH = 70,
    BAR_MAX_HEIGHT = 500,
    BAR_OFFSET_Y = 140,
    
    BOTTOM_PANEL_Y = 1000,
    BOTTOM_PANEL_HEIGHT = 350,
    STUDENTS_COL_WIDTH = 550,
}

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


CreateKrFont("HP_Title", "Cinzel Decorative", 65, 800, {shadow = true})

CreateKrFont("HP_Subtitle", "Cinzel Decorative", 50, 700, {shadow = true})

CreateKrFont("HP_Large", "IM Fell English", 55, 800)

CreateKrFont("HP_Medium", "Crimson Text", 38, 600)

CreateKrFont("HP_Small", "Crimson Text", 30, 500)

local function ParseStudentData(dataStr)
    if not dataStr or dataStr == "" then return "Yok", "0" end
    local name, score = string.match(dataStr, "^(.*)%s*|%s*(.*)$")
    return name or "Yok", score or "0"
end

function ENT:Initialize()
    self.SmoothScores = KrPoints.GetAllHousePoints()
end

function ENT:Draw()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if self:GetPos():DistToSqr(ply:GetPos()) > RENDER_DISTANCE_SQR then return end
    
    local scores = KrPoints.GetAllHousePoints()
    
    self.SmoothScores = self.SmoothScores or {}
    local dt = FrameTime() * LERP_SPEED
    for house, score in pairs(scores) do
        self.SmoothScores[house] = Lerp(dt, self.SmoothScores[house] or 0, score)
    end
    
    local leadingHouse, maxScore = KrPoints.GetLeadingHouse()
    local scaleRef = math.max(maxScore, MIN_SCALE_REF)
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Forward(), 180)
    ang:RotateAroundAxis(ang:Up(), -90)
    
    cam.Start3D2D(pos + ang:Right() * -50 + ang:Forward() * -105, ang, 0.1)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(MAT_BG)
        surface.DrawTexturedRect(0, 0, LAYOUT.CANVAS_WIDTH, LAYOUT.CANVAS_HEIGHT)
        
        draw.SimpleTextOutlined(
            "HOGWARTS HANE PUANLARI", "HP_Title",
            LAYOUT.CANVAS_WIDTH / 2, LAYOUT.TITLE_Y,
            COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            3, COLORS.Black
        )
        
        for i, house in ipairs(self.Houses) do
            local x = LAYOUT.HOUSES_START_X + ((i - 1) * (LAYOUT.HOUSE_WIDTH + LAYOUT.HOUSE_SPACING))
            self:DrawHouseColumn(house, x, LAYOUT.HOUSES_START_Y, self.SmoothScores[house], scores[house], scaleRef)
        end
        
        self:DrawBottomPanel(leadingHouse)
    cam.End3D2D()
end

function ENT:DrawHouseColumn(house, x, y, smoothScore, realScore, scaleRef)
    local col = COLORS[house] or COLORS.White
    
    local crestX = x + (LAYOUT.HOUSE_WIDTH / 2) - (LAYOUT.CREST_SIZE / 2)
    local crestY = y + LAYOUT.CREST_OFFSET_Y
    
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(MAT_CRESTS[house])
    surface.DrawTexturedRect(crestX, crestY, LAYOUT.CREST_SIZE, LAYOUT.CREST_SIZE)
    
    local barX = x + (LAYOUT.HOUSE_WIDTH / 2) - (LAYOUT.BAR_WIDTH / 2)
    local barY = y + LAYOUT.BAR_OFFSET_Y
    local fillRatio = math.Clamp(smoothScore / scaleRef, 0, 1)
    local currentH = LAYOUT.BAR_MAX_HEIGHT * fillRatio
    
    if realScore > 0 and currentH < MIN_BAR_WIDTH then
        currentH = MIN_BAR_WIDTH
    end
    
    draw.RoundedBox(8, barX, barY, LAYOUT.BAR_WIDTH, LAYOUT.BAR_MAX_HEIGHT, COLORS.BarBG)
    
    local filledBarY = barY + (LAYOUT.BAR_MAX_HEIGHT - currentH)
    draw.RoundedBox(8, barX, filledBarY, LAYOUT.BAR_WIDTH, currentH, col)
    
    draw.SimpleTextOutlined(
        string.Comma(realScore), "HP_Large",
        x + (LAYOUT.HOUSE_WIDTH / 2), barY + LAYOUT.BAR_MAX_HEIGHT + 30,
        COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,
        3, COLORS.Black
    )
end

function ENT:DrawBottomPanel(leadingHouse)
    local panelY = LAYOUT.BOTTOM_PANEL_Y
    local panelW = LAYOUT.CANVAS_WIDTH - 160
    local panelH = LAYOUT.BOTTOM_PANEL_HEIGHT
    local panelX = 80
    
    draw.RoundedBox(16, panelX, panelY, panelW, panelH, COLORS.PanelBG)
    
    local leftX = panelX + 40
    local titleY = panelY + 30
    
    draw.SimpleTextOutlined(
        "Hane Birincileri", "HP_Subtitle",
        leftX + 220, titleY,
        COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,
        3, COLORS.Black
    )
    
    local rowY = titleY + 80
    local gap = 55
    
    for _, house in ipairs(self.Houses) do
        local getter = self["GetTopStudent" .. house]
        local dataStr = getter and getter(self) or "Yok | 0"
        local name, points = ParseStudentData(dataStr)
        
        if #name > 18 then
            name = string.sub(name, 1, 15) .. "..."
        end
        
        draw.SimpleTextOutlined(
            house .. ":", "HP_Medium",
            leftX, rowY,
            COLORS[house], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,
            2, COLORS.Black
        )
        
        draw.SimpleTextOutlined(
            name .. " (" .. points .. ")", "HP_Medium",
            leftX + 420, rowY,
            COLORS.White, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP,
            2, COLORS.Black
        )
        rowY = rowY + gap
    end
    
    surface.SetDrawColor(255, 255, 255, 50)
    surface.DrawRect(panelX + panelW / 2 - 2, panelY + 20, 4, panelH - 40)
    
    local rightX = panelX + panelW / 2 + 40
    local leaderY = panelY + panelH / 2
    
    draw.SimpleTextOutlined(
        "LİDER HANE", "HP_Subtitle",
        rightX + 220, leaderY - 80,
        COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
        3, COLORS.Black
    )
    
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(MAT_CRESTS[leadingHouse])
    surface.DrawTexturedRect(rightX + 145, leaderY - 20, 150, 150)
    
    draw.SimpleTextOutlined(
        leadingHouse, "HP_Large",
        rightX + 220, leaderY + 150,
        COLORS[leadingHouse], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
        3, COLORS.Black
    )
end
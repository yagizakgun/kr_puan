include("shared.lua")

-- ===== MATERIALS =====
local MAT_BG = Material("kr_puan/hogwarts_bg.png", "noclamp smooth")
local MAT_CRESTS = {
    Gryffindor = Material("rlib/interface/grunge/banners/hogwarts/em_gr.png", "noclamp smooth"),
    Hufflepuff = Material("rlib/interface/grunge/banners/hogwarts/em_hu.png", "noclamp smooth"),
    Ravenclaw  = Material("rlib/interface/grunge/banners/hogwarts/em_ra.png", "noclamp smooth"),
    Slytherin  = Material("rlib/interface/grunge/banners/hogwarts/em_sl.png", "noclamp smooth"),
}

-- ===== COLORS =====
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

-- ===== LAYOUT CONSTANTS =====
local RENDER_DISTANCE_SQR = 650 * 650
local LERP_SPEED = 4
local MIN_BAR_WIDTH = 20
local MIN_SCALE_REF = 250

local LAYOUT = {
    ROW_X = 140,
    ROW_POSITIONS = {75, 250, 430, 640},
    CREST_SIZE = 150,
    BAR_OFFSET_X = 180,
    BAR_OFFSET_Y = 35,
    BAR_HEIGHT = 80,
    BAR_MAX_WIDTH = 1450,
    SIDEBAR_X = 1900,
    SIDEBAR_Y = 50,
}

-- ===== FONTS =====
surface.CreateFont("HP_Title", {font = "Poppins", size = 70, weight = 800, antialias = true})
surface.CreateFont("HP_Large", {font = "Poppins", size = 60, weight = 600, antialias = true})
surface.CreateFont("HP_Medium", {font = "Poppins", size = 40, weight = 500, antialias = true})

-- ===== HELPER FUNCTIONS =====
local function ParseStudentData(dataStr)
    if not dataStr or dataStr == "" then return "Yok", "0" end
    local name, score = string.match(dataStr, "^(.*)%s*|%s*(.*)$")
    return name or "Yok", score or "0"
end

-- ===== ENTITY METHODS =====
function ENT:Initialize()
    self.SmoothScores = KrPoints.GetAllHousePoints()
end

function ENT:Draw()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if self:GetPos():DistToSqr(ply:GetPos()) > RENDER_DISTANCE_SQR then return end
    
    -- Get current scores using API
    local scores = KrPoints.GetAllHousePoints()
    
    -- Smooth score interpolation
    self.SmoothScores = self.SmoothScores or {}
    local dt = FrameTime() * LERP_SPEED
    for house, score in pairs(scores) do
        self.SmoothScores[house] = Lerp(dt, self.SmoothScores[house] or 0, score)
    end
    
    -- Find leader using API
    local leadingHouse, maxScore = KrPoints.GetLeadingHouse()
    local scaleRef = math.max(maxScore, MIN_SCALE_REF)
    
    -- Setup 3D2D rendering
    local pos = self:GetPos()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Forward(), 180)
    ang:RotateAroundAxis(ang:Up(), -90)
    
    cam.Start3D2D(pos + ang:Right() * -50 + ang:Forward() * -105, ang, 0.1)
        -- Background
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(MAT_BG)
        surface.DrawTexturedRect(0, 0, 3000, 1000)
        
        -- Draw house rows
        for i, house in ipairs(self.Houses) do
            self:DrawHouseRow(house, LAYOUT.ROW_X, LAYOUT.ROW_POSITIONS[i], self.SmoothScores[house], scores[house], scaleRef)
        end
        
        -- Draw sidebar
        self:DrawSidebar(LAYOUT.SIDEBAR_X, LAYOUT.SIDEBAR_Y, leadingHouse)
    cam.End3D2D()
end

function ENT:DrawHouseRow(house, x, y, smoothScore, realScore, scaleRef)
    local col = COLORS[house] or COLORS.White
    
    -- Draw crest
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(MAT_CRESTS[house])
    surface.DrawTexturedRect(x, y, LAYOUT.CREST_SIZE, LAYOUT.CREST_SIZE)
    
    -- Calculate bar dimensions
    local barX = x + LAYOUT.BAR_OFFSET_X
    local barY = y + LAYOUT.BAR_OFFSET_Y
    local fillRatio = math.Clamp(smoothScore / scaleRef, 0, 1)
    local currentW = LAYOUT.BAR_MAX_WIDTH * fillRatio
    
    -- Ensure minimum visible width for non-zero scores
    if realScore > 0 and currentW < MIN_BAR_WIDTH then
        currentW = MIN_BAR_WIDTH
    end
    
    -- Draw bars
    draw.RoundedBox(8, barX, barY, LAYOUT.BAR_MAX_WIDTH, LAYOUT.BAR_HEIGHT, COLORS.BarBG)
    draw.RoundedBox(8, barX, barY, currentW, LAYOUT.BAR_HEIGHT, col)
    
    -- Draw score text
    draw.SimpleTextOutlined(
        string.Comma(realScore), "HP_Large",
        barX + 20, barY + LAYOUT.BAR_HEIGHT / 2,
        COLORS.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
        2, COLORS.Black
    )
end

function ENT:DrawSidebar(x, y, leadingHouse)
    draw.RoundedBox(16, x - 20, y, 950, 900, COLORS.PanelBG)
    
    -- Title
    local titleY = y + 40
    draw.SimpleText("Hane Birincileri", "HP_Title", x + 475, titleY, COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Student rows
    local rowY = titleY + 100
    local gap = 70
    
    for _, house in ipairs(self.Houses) do
        local getter = self["GetTopStudent" .. house]
        local dataStr = getter and getter(self) or "Yok | 0"
        local name, points = ParseStudentData(dataStr)
        
        -- Truncate long names
        if #name > 15 then
            name = string.sub(name, 1, 12) .. "..."
        end
        
        draw.SimpleText(house .. ":", "HP_Medium", x + 20, rowY, COLORS[house], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(name .. " (" .. points .. ")", "HP_Medium", x + 900, rowY, COLORS.White, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        rowY = rowY + gap
    end
    
    -- Separator line
    surface.SetDrawColor(255, 255, 255, 50)
    surface.DrawRect(x + 50, rowY + 30, 800, 2)
    
    -- Leading house
    rowY = rowY + 60
    draw.SimpleText("Lider Hane", "HP_Title", x + 475, rowY, COLORS.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(leadingHouse, "HP_Title", x + 475, rowY + 80, COLORS[leadingHouse], TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end
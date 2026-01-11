AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Constants
local TIMER_PREFIX = "kr_puan_update_"
local UPDATE_INTERVAL = 30

-- Retrieve top student data using KrPoints API
local function GetTopStudentData(ent, house_name)
    local house_key = ent.HouseKeys[house_name]
    if not house_key then return "Veri Yok | 0" end
    
    if not (KrPoints and KrPoints.Database) then return "Veri Yok | 0" end
    
    local students = KrPoints.Database.GetTopStudents(1, house_key)
    if students and students[1] then
        local student = students[1]
        return (student.id or "Yok") .. " | " .. (student.points or 0)
    end
    
    return "Veri Yok | 0"
end

-- Update network variables for all houses
local function UpdateLeaderboard(ent)
    if not IsValid(ent) then return end
    
    for _, house in ipairs(ent.Houses) do
        local setter = ent["SetTopStudent" .. house]
        if setter then
            setter(ent, GetTopStudentData(ent, house))
        end
    end
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysWake()
    self:Activate()
    
    -- Initial update
    UpdateLeaderboard(self)
    
    -- Store timer name for cleanup
    self.TimerName = TIMER_PREFIX .. self:EntIndex()
    
    -- Periodic update timer
    timer.Create(self.TimerName, UPDATE_INTERVAL, 0, function()
        if IsValid(self) then
            UpdateLeaderboard(self)
        else
            timer.Remove(self.TimerName)
        end
    end)
end

function ENT:OnRemove()
    if self.TimerName then
        timer.Remove(self.TimerName)
    end
end

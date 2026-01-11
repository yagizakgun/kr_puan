AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Constants
local TIMER_PREFIX = "kr_puan_update_"
local UPDATE_INTERVAL = 30

-- Retrieve top student data using KrPoints API (async-safe)
local function GetTopStudentData(ent, house_name, callback)
    local house_key = ent.HouseKeys[house_name]
    if not house_key then 
        if callback then callback("Veri Yok | 0") end
        return "Veri Yok | 0"
    end
    
    if not (KrPoints and KrPoints.Database) then 
        if callback then callback("Veri Yok | 0") end
        return "Veri Yok | 0"
    end
    
    KrPoints.Database.GetTopStudents(1, house_key, function(students)
        if students and students[1] then
            local student = students[1]
            local points = student.points or 0
            -- Use helper function to convert identifier to display name (with callback for async)
            KrPoints.GetDisplayNameFromIdentifier(student.id, function(display_name)
                local result = display_name .. " | " .. points
                if callback then callback(result) end
            end)
        else
            if callback then callback("Veri Yok | 0") end
        end
    end)
    
    -- For sync compatibility (SQLite)
    if not (KrPoints.Database and KrPoints.Database.IsMySQL()) then
        local students = KrPoints.Database.GetTopStudents(1, house_key)
        if students and students[1] then
            local student = students[1]
            local display_name = KrPoints.GetDisplayNameFromIdentifier(student.id)
            return display_name .. " | " .. (student.points or 0)
        end
        return "Veri Yok | 0"
    end
end

-- Update network variables for all houses (async-safe)
local function UpdateLeaderboard(ent)
    if not IsValid(ent) then return end
    
    for _, house in ipairs(ent.Houses) do
        local setter = ent["SetTopStudent" .. house]
        if setter then
            -- Use callback for async support
            GetTopStudentData(ent, house, function(data)
                if IsValid(ent) and setter then
                    setter(ent, data)
                end
            end)
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

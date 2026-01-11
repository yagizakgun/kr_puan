AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local TIMER_PREFIX = "kr_puan_update_"
local UPDATE_INTERVAL = 5

local function UpdateLeaderboard(ent)
    if not IsValid(ent) then return end
    if not (KrPoints and KrPoints.Database) then return end
    
    for _, house in ipairs(ent.Houses) do
        local house_key = ent.HouseKeys[house]
        local setter = ent["SetTopStudent" .. house]
        
        if house_key and setter then
            KrPoints.Database.GetTopStudents(1, house_key, function(students)
                if not IsValid(ent) then return end
                
                if students and students[1] then
                    local student = students[1]
                    local points = student.points or 0
                    
                    -- Use display_name from query if available, otherwise lookup
                    if student.display_name and student.display_name ~= "" then
                        if IsValid(ent) and setter then
                            setter(ent, student.display_name .. " | " .. points)
                        end
                    else
                        KrPoints.GetDisplayNameFromIdentifier(student.id, function(display_name)
                            if IsValid(ent) and setter then
                                setter(ent, display_name .. " | " .. points)
                            end
                        end)
                    end
                else
                    if setter then
                        setter(ent, "Veri Yok | 0")
                    end
                end
            end)
            
            if not (KrPoints.Database and KrPoints.Database.IsMySQL()) then
                local students = KrPoints.Database.GetTopStudents(1, house_key)
                if students and students[1] then
                    local student = students[1]
                    local points = student.points or 0
                    
                    -- Use display_name from query if available, otherwise lookup
                    local display_name = (student.display_name and student.display_name ~= "") 
                        and student.display_name 
                        or KrPoints.GetDisplayNameFromIdentifier(student.id)
                    
                    setter(ent, display_name .. " | " .. points)
                else
                    setter(ent, "Veri Yok | 0")
                end
            end
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
    
    UpdateLeaderboard(self)
    
    self.TimerName = TIMER_PREFIX .. self:EntIndex()
    
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

local UPDATE_DEBOUNCE_TIMER = "kr_puan_debounce_update"
local DEBOUNCE_DELAY = 0.5  -- Wait 0.5 seconds before updating

function KrPoints.UpdateAllLeaderboards()
    if timer.Exists(UPDATE_DEBOUNCE_TIMER) then
        timer.Remove(UPDATE_DEBOUNCE_TIMER)
    end
    
    timer.Create(UPDATE_DEBOUNCE_TIMER, DEBOUNCE_DELAY, 1, function()
        for _, ent in ipairs(ents.FindByClass("kr_puan_tablo")) do
            if IsValid(ent) then
                UpdateLeaderboard(ent)
            end
        end
    end)
end

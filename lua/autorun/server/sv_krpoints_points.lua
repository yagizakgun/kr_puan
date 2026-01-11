-- ============================================
-- KR-PUAN SYSTEM: Points Business Logic Module
-- ============================================
-- Sorumluluk: İş mantığı - puan verme/alma/hesaplama
-- Bağımlılıklar: sv_krpoints_config.lua, sv_krpoints_database.lua
-- ============================================

KrPoints.Points = KrPoints.Points or {}

-- Shorthand references
local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES

-- Faction name to house mapping (eliminates if-elseif chain)
local FACTION_TO_HOUSE = {
	[KrPoints.FactionRavenclaw] = "ravenclaw",
	[KrPoints.FactionGryffindor] = "gryffindor",
	[KrPoints.FactionSlytherin] = "slytherin",
	[KrPoints.FactionHufflepuff] = "hufflepuff",
}

-- ===== GLOBAL INT SYNCHRONIZATION =====
function KrPoints.Points.SyncGlobalInts(specific_house)
	if specific_house then
		-- Update only the specified house
		local points = KrPoints.Database.GetHousePoints(specific_house)
		if points then
			SetGlobalInt("puan_" .. specific_house, points)
		end
	else
		-- Update all houses (used on initialization)
		for _, house in ipairs(VALID_HOUSES) do
			local points = KrPoints.Database.GetHousePoints(house)
			SetGlobalInt("puan_" .. house, points)
		end
	end
end

-- ===== STUDENT HOUSE DETECTION =====
function KrPoints.Points.GetStudentHouse(ply)
	if not IsValid(ply) or not ply:IsPlayer() then 
		print("[KR-PUAN] ERROR: Invalid player in GetStudentHouse")
		return nil 
	end
	
	local char = ply:GetCharacter()
	if not char then 
		print("[KR-PUAN] ERROR: Player has no character: " .. ply:Nick())
		return nil 
	end
	
	local fac = ix.faction.indices[char:GetFaction()]
	if not fac then 
		print("[KR-PUAN] ERROR: Invalid faction for player: " .. ply:Nick())
		return nil 
	end
	
	local faction_name = fac.name
	local house = FACTION_TO_HOUSE[faction_name]
	if house then
		return house
	end
	
	print("[KR-PUAN] ERROR: Faction not recognized: " .. tostring(faction_name) .. " for player: " .. ply:Nick())
	return nil
end

-- ===== HOUSE POINTS OPERATIONS =====
function KrPoints.Points.AddToHouse(house, amount)
	if not VALID_HOUSES_LOOKUP[house] then 
		print("[KR-PUAN] ERROR: Invalid house: " .. tostring(house))
		return false 
	end
	
	local new_points = KrPoints.Database.AddHousePoints(house, amount)
	KrPoints.Points.SyncGlobalInts(house)
	
	return new_points
end

function KrPoints.Points.GetHousePoints(house)
	-- Use cached GlobalInt instead of querying database
	return GetGlobalInt("puan_" .. house, 0)
end

-- ===== STUDENT POINTS OPERATIONS =====
-- Internal helper function to modify student points (reduces code duplication)
local function ModifyStudentPoints(professor_ply, target_ply, amount, is_giving)
	if not IsValid(professor_ply) or not IsValid(target_ply) then
		return false, "Invalid player"
	end
	
	-- Get student's house
	local student_house = KrPoints.Points.GetStudentHouse(target_ply)
	if not student_house then
		return false, "Target is not a student"
	end
	
	-- Calculate new points (positive for give, negative for take)
	local delta = is_giving and amount or -amount
	local current_student_points = KrPoints.Database.GetStudentPoints(target_ply:Nick())
	local new_student_points = current_student_points + delta
	
	-- Update student points
	KrPoints.Database.SetStudentPoints(target_ply:Nick(), new_student_points, student_house)
	
	-- Update house points
	local new_house_points = KrPoints.Points.AddToHouse(student_house, delta)
	
	-- Log the action
	local action = is_giving and "gave" or "took"
	local preposition = is_giving and "to" or "from"
	print("[KR-PUAN] " .. professor_ply:Nick() .. " " .. action .. " " .. amount .. " points " .. preposition .. " " .. target_ply:Nick() .. " (" .. student_house .. ")")
	
	return true, {
		student_name = target_ply:Nick(),
		student_house = student_house,
		new_student_points = new_student_points,
		new_house_points = new_house_points,
		amount = amount
	}
end

function KrPoints.Points.Give(professor_ply, target_ply, amount)
	return ModifyStudentPoints(professor_ply, target_ply, amount, true)
end

function KrPoints.Points.Take(professor_ply, target_ply, amount)
	return ModifyStudentPoints(professor_ply, target_ply, amount, false)
end

-- ===== VALIDATION =====
function KrPoints.Points.ValidateAmount(amount)
	local min = KrPoints.Security.MIN_POINTS_PER_ACTION
	local max = KrPoints.Security.MAX_POINTS_PER_ACTION
	
	amount = tonumber(amount)
	if not amount then
		return false, "Invalid point amount"
	end
	
	if amount < min or amount > max then
		return false, "Point amount must be between " .. min .. " and " .. max
	end
	
	return true, amount
end

print("[KR-PUAN] Points module loaded.")

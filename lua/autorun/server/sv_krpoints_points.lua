KrPoints.Points = KrPoints.Points or {}

local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES

-- Faction ismini ev ismine çeviren fonksiyon
-- Config'deki KrPoints.StudentFactions tablosunu kullanır
local function GetHouseFromFaction(faction_name)
	if not KrPoints.StudentFactions then return nil end
	
	for house, factions in pairs(KrPoints.StudentFactions) do
		for _, faction in ipairs(factions) do
			if faction == faction_name then
				return house
			end
		end
	end
	
	return nil
end

function KrPoints.Points.SyncGlobalInts(specific_house)
	if specific_house then
		KrPoints.Database.GetHousePoints(specific_house, function(points)
			if points then
				SetGlobalInt("puan_" .. specific_house, points)
			end
		end)
	else
		for _, house in ipairs(VALID_HOUSES) do
			KrPoints.Database.GetHousePoints(house, function(points)
				SetGlobalInt("puan_" .. house, points)
			end)
		end
	end
end

function KrPoints.Points.GetStudentHouse(ply)
	if not IsValid(ply) or not ply:IsPlayer() then 
		print("[KR-PUAN] [HATA] GetStudentHouse fonksiyonunda geçersiz oyuncu")
		return nil 
	end
	
	local char = ply:GetCharacter()
	if not char then 
		print("[KR-PUAN] [HATA] Oyuncunun karakteri yok: " .. ply:Nick())
		return nil 
	end
	
	local fac = ix.faction.indices[char:GetFaction()]
	if not fac then 
		print("[KR-PUAN] [HATA] Oyuncu için geçersiz faction: " .. ply:Nick())
		return nil 
	end
	
	local faction_name = fac.name
	local house = GetHouseFromFaction(faction_name)
	if house then
		return house
	end
	
	print("[KR-PUAN] [HATA] Faction tanınmadı: " .. tostring(faction_name) .. " - Oyuncu: " .. ply:Nick())
	return nil
end

function KrPoints.Points.AddToHouse(house, amount, callback)
	if not VALID_HOUSES_LOOKUP[house] then 
		print("[KR-PUAN] [HATA] Geçersiz ev: " .. tostring(house))
		if callback then callback(false) end
		return false 
	end
	
	KrPoints.Database.AddHousePoints(house, amount, function(new_points)
		KrPoints.Points.SyncGlobalInts(house)
		if callback then callback(new_points) end
	end)
	
	if not KrPoints.Database.IsMySQL() then
		return KrPoints.Database.GetHousePoints(house)
	end
end

function KrPoints.Points.GetHousePoints(house)
	return GetGlobalInt("puan_" .. house, 0)
end

-- ===== STUDENT POINTS OPERATIONS =====
local function ModifyStudentPoints(professor_ply, target_ply, amount, is_giving, callback)
	if not IsValid(professor_ply) or not IsValid(target_ply) then
		if callback then callback(false, "Invalid player") end
		return false, "Invalid player"
	end
	
	local student_house = KrPoints.Points.GetStudentHouse(target_ply)
	if not student_house then
		if callback then callback(false, "Target is not a student") end
		return false, "Target is not a student"
	end
	
	local student_id = KrPoints.GetStudentIdentifier(target_ply)
	if not student_id then
		if callback then callback(false, "Could not get student identifier") end
		return false, "Could not get student identifier"
	end
	
	local student_display_name = KrPoints.GetStudentDisplayName(target_ply)
	
	local delta = is_giving and amount or -amount
	
	if KrPoints.Database.IsMySQL() then
		KrPoints.Database.GetStudentPoints(student_id, function(current_student_points)
			local new_student_points = current_student_points + delta
			
			KrPoints.Database.SetStudentPoints(student_id, new_student_points, student_house, function()
				KrPoints.Points.AddToHouse(student_house, delta, function(new_house_points)
					local action = is_giving and "verdi" or "aldı"
					local preposition = is_giving and "için" or "den"
					print("[KR-PUAN] [BİLGİ] " .. professor_ply:Nick() .. " " .. amount .. " puan " .. action .. " - " .. student_display_name .. " [ID:" .. student_id .. "] (" .. student_house .. ")")
					
					local result = {
						student_name = student_display_name,
						student_id = student_id,
						student_house = student_house,
						new_student_points = new_student_points,
						new_house_points = new_house_points,
						amount = amount
					}
					
					if callback then callback(true, result) end
				end)
			end, student_display_name)
		end)
	else
		local current_student_points = KrPoints.Database.GetStudentPoints(student_id)
		local new_student_points = current_student_points + delta
		KrPoints.Database.SetStudentPoints(student_id, new_student_points, student_house, nil, student_display_name)
		local new_house_points = KrPoints.Points.AddToHouse(student_house, delta)
		
		local action = is_giving and "verdi" or "aldı"
		print("[KR-PUAN] [BİLGİ] " .. professor_ply:Nick() .. " " .. amount .. " puan " .. action .. " - " .. student_display_name .. " [ID:" .. student_id .. "] (" .. student_house .. ")")
		
		return true, {
			student_name = student_display_name,
			student_id = student_id,
			student_house = student_house,
			new_student_points = new_student_points,
			new_house_points = new_house_points,
			amount = amount
		}
	end
end

function KrPoints.Points.Give(professor_ply, target_ply, amount, callback)
	return ModifyStudentPoints(professor_ply, target_ply, amount, true, callback)
end

function KrPoints.Points.Take(professor_ply, target_ply, amount, callback)
	return ModifyStudentPoints(professor_ply, target_ply, amount, false, callback)
end

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

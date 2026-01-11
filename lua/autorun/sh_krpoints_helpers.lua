KrPoints.Helpers = KrPoints.Helpers or {}

KrPoints.Gamemode = KrPoints.UsingGamemode or "others"

function KrPoints.GetAllHousePoints()
	local points = {}
	for _, house in ipairs(KrPoints.HouseList) do
		local key = KrPoints.HouseKeys[house]
		points[house] = GetGlobalInt("puan_" .. key, 0)
	end
	return points
end

function KrPoints.GetLeadingHouse()
	local points = KrPoints.GetAllHousePoints()
	local leadingHouse, maxScore = nil, 0
	
	for house, score in pairs(points) do
		if score > maxScore then
			maxScore = score
			leadingHouse = house
		end
	end
	
	return leadingHouse or "Gryffindor", maxScore
end

function KrPoints.GetHousePoints(house)
	local key = KrPoints.HouseKeys[house]
	if not key then return 0 end
	return GetGlobalInt("puan_" .. key, 0)
end

function KrPoints.GetStudentIdentifier(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return nil
	end

	if KrPoints.Gamemode == "helix" then
		local char = ply:GetCharacter()
		if char and char.GetID then
			local charId = char:GetID()
			if charId then
				return tostring(charId)
			end
		end
		print("[KR-PUAN] UYARI: Helix karakter ID bulunamadı, isim kullanılıyor: " .. ply:Nick())
	end
	
	return ply:Nick()
end

function KrPoints.GetStudentDisplayName(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return "Unknown"
	end
	
	if KrPoints.Gamemode == "helix" then
		local char = ply:GetCharacter()
		if char and char.GetName then
			return char:GetName()
		end
	end
	
	return ply:Nick()
end

if SERVER then
	function KrPoints.GetDisplayNameFromIdentifier(identifier, callback)
		if not identifier then 
			if callback then callback("Yok") end
			return "Yok" 
		end
		
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) then
				local ply_id = KrPoints.GetStudentIdentifier(ply)
				if ply_id == identifier then
					local name = KrPoints.GetStudentDisplayName(ply)
					if callback then callback(name) end
					return name
				end
			end
		end
		
		if KrPoints.Database and KrPoints.Database.GetStudentDisplayName then
			if callback then
				KrPoints.Database.GetStudentDisplayName(identifier, function(db_name)
					if db_name and db_name ~= "" then
						callback(db_name)
					else
						callback(identifier)
					end
				end)
				return nil
			else
				local db_name = KrPoints.Database.GetStudentDisplayName(identifier)
				if db_name and db_name ~= "" then
					return db_name
				end
			end
		end
		
		if callback then callback(identifier) end
		return identifier
	end
end


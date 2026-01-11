-- ============================================
-- KR-PUAN SYSTEM: Shared Helper Functions
-- ============================================
-- Sorumluluk: Gamemode-agnostic yardımcı fonksiyonlar
-- Bağımlılıklar: sh_config.lua
-- ============================================

KrPoints.Helpers = KrPoints.Helpers or {}

-- ===== GAMEMODE CONFIGURATION =====
KrPoints.Gamemode = KrPoints.UsingGamemode or "others"

-- ===== HOUSE POINTS HELPERS =====
-- Get all house points from GlobalInts (works on both client and server)
function KrPoints.GetAllHousePoints()
	local points = {}
	for _, house in ipairs(KrPoints.HouseList) do
		local key = KrPoints.HouseKeys[house]
		points[house] = GetGlobalInt("puan_" .. key, 0)
	end
	return points
end

-- Get the leading house and its score
-- Returns: house_name (string), max_score (number)
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

-- Get points for a specific house
function KrPoints.GetHousePoints(house)
	local key = KrPoints.HouseKeys[house]
	if not key then return 0 end
	return GetGlobalInt("puan_" .. key, 0)
end

-- ===== PLAYER IDENTIFIER HELPERS =====
-- Returns unique identifier for student database storage
-- helix: Character ID (survives name changes)
-- darkrp: Player Nick
-- others: Player Nick
function KrPoints.GetStudentIdentifier(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return nil
	end
	
	-- Helix gamemode: use Character ID
	if KrPoints.Gamemode == "helix" then
		local char = ply:GetCharacter()
		if char and char.GetID then
			local charId = char:GetID()
			if charId then
				return tostring(charId)
			end
		end
		-- Fallback to Nick if character not found
		print("[KR-PUAN] UYARI: Helix karakter ID bulunamadı, isim kullanılıyor: " .. ply:Nick())
	end
	
	-- DarkRP / Others: use player name
	return ply:Nick()
end

-- Returns display name for UI and logging purposes
-- helix: Character Name (RP name)
-- darkrp: Player Nick
-- others: Player Nick
function KrPoints.GetStudentDisplayName(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return "Unknown"
	end
	
	-- Helix: try to get character name
	if KrPoints.Gamemode == "helix" then
		local char = ply:GetCharacter()
		if char and char.GetName then
			return char:GetName()
		end
	end
	
	-- DarkRP / Others: use player nick
	return ply:Nick()
end

-- SERVER ONLY: Convert identifier to display name (handles offline players)
if SERVER then
	function KrPoints.GetDisplayNameFromIdentifier(identifier, callback)
		if not identifier then 
			if callback then callback("Yok") end
			return "Yok" 
		end
		
		-- Try to find online player with this identifier
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) then
				local ply_id = KrPoints.GetStudentIdentifier(ply)
				if ply_id == identifier then
					-- Found the player online, return their display name
					local name = KrPoints.GetStudentDisplayName(ply)
					if callback then callback(name) end
					return name
				end
			end
		end
		
		-- Player is offline - try to get display_name from database
		if KrPoints.Database and KrPoints.Database.GetStudentDisplayName then
			-- For async (MySQL) - use callback
			if callback then
				KrPoints.Database.GetStudentDisplayName(identifier, function(db_name)
					if db_name and db_name ~= "" then
						callback(db_name)
					else
						-- Fallback: return identifier as-is
						callback(identifier)
					end
				end)
				return nil -- async, result will come via callback
			else
				-- For sync (SQLite) - direct return
				local db_name = KrPoints.Database.GetStudentDisplayName(identifier)
				if db_name and db_name ~= "" then
					return db_name
				end
			end
		end
		
		-- Final fallback: return identifier as-is
		if callback then callback(identifier) end
		return identifier
	end
end


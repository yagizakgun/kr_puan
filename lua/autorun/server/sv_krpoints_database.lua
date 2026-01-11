-- ============================================
-- KR-PUAN SYSTEM: Database Layer Module
-- ============================================
-- Sorumluluk: Tüm SQL operasyonları ve veritabanı yönetimi
-- Bağımlılıklar: sv_krpoints_config.lua
-- ============================================
-- Modern tek tablo yapısı:
--   kr_points (
--     entity_type TEXT,    -- 'house' veya 'student'
--     entity_id TEXT,      -- ev adı veya öğrenci adı
--     points INTEGER,      -- puan değeri
--     house TEXT,          -- öğrencinin evi (sadece student için)
--     updated_at INTEGER,  -- son güncelleme timestamp
--     PRIMARY KEY (entity_type, entity_id)
--   )
-- ============================================

KrPoints.Database = KrPoints.Database or {}

-- Shorthand references
local TABLE_NAME = KrPoints.DB.TABLE_NAME
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES
local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP

-- ===== HELPER FUNCTIONS =====
-- Extract single value from SQL result (reduces repetitive nil checking)
local function GetSingleValue(result, field, default)
	if result and result ~= false and result[1] then
		return result[1][field]
	end
	return default
end

-- Create all database indexes
local function CreateIndexes()
	sql.Query("CREATE INDEX IF NOT EXISTS idx_entity_type ON " .. TABLE_NAME .. " (entity_type);")
	sql.Query("CREATE INDEX IF NOT EXISTS idx_house ON " .. TABLE_NAME .. " (house);")
	sql.Query("CREATE INDEX IF NOT EXISTS idx_points ON " .. TABLE_NAME .. " (points DESC);")
	sql.Query("CREATE INDEX IF NOT EXISTS idx_type_house ON " .. TABLE_NAME .. " (entity_type, house);")
end

-- Get current timestamp
local function Now()
	return os.time()
end

-- ===== TRANSACTION WRAPPER =====
function KrPoints.Database.Transaction(func)
	sql.Query("BEGIN TRANSACTION;")
	local success, err = pcall(func)
	if success then
		sql.Query("COMMIT;")
		return true
	else
		sql.Query("ROLLBACK;")
		print("[KR-PUAN] DATABASE ERROR: Transaction rolled back: " .. tostring(err))
		return false
	end
end

-- ===== INITIALIZATION =====
function KrPoints.Database.Initialize()
	-- Create modern table structure
	if not sql.TableExists(TABLE_NAME) then
		print("[KR-PUAN] Creating database...")
		
		local create_result = sql.Query([[
			CREATE TABLE ]] .. TABLE_NAME .. [[ (
				entity_type TEXT NOT NULL,
				entity_id TEXT NOT NULL,
				points INTEGER DEFAULT 0,
				house TEXT,
				updated_at INTEGER,
				PRIMARY KEY (entity_type, entity_id)
			);
		]])
		
		if create_result == false then
			print("[KR-PUAN] HATA: Tablo oluşturulamadı: " .. tostring(sql.LastError()))
			return
		end
		
		CreateIndexes()
		print("[KR-PUAN] Database table and indexes created.")
	else
		-- Ensure indexes exist
		CreateIndexes()
	end
	
	-- Ensure all houses exist with default 0 points
	for _, house in ipairs(VALID_HOUSES) do
		sql.QueryTyped(
			"INSERT OR IGNORE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, updated_at) VALUES ('house', ?, 0, ?);",
			house, Now()
		)
	end

	print("[KR-PUAN] Database initialized.")
end

-- ===== HOUSE POINTS OPERATIONS =====
function KrPoints.Database.GetHousePoints(house)
	if not VALID_HOUSES_LOOKUP[house] then return nil end
	
	local result = sql.QueryTyped(
		"SELECT points FROM " .. TABLE_NAME .. " WHERE entity_type = 'house' AND entity_id = ?;",
		house
	)
	return tonumber(GetSingleValue(result, "points", 0)) or 0
end

function KrPoints.Database.SetHousePoints(house, points)
	if not VALID_HOUSES_LOOKUP[house] then return false end
	
	sql.QueryTyped(
		"UPDATE " .. TABLE_NAME .. " SET points = ?, updated_at = ? WHERE entity_type = 'house' AND entity_id = ?;",
		points, Now(), house
	)
	return true
end

function KrPoints.Database.AddHousePoints(house, amount)
	if not VALID_HOUSES_LOOKUP[house] then return false end
	
	-- Atomic increment with single query
	sql.QueryTyped(
		"UPDATE " .. TABLE_NAME .. " SET points = points + ?, updated_at = ? WHERE entity_type = 'house' AND entity_id = ?;",
		amount, Now(), house
	)
	return KrPoints.Database.GetHousePoints(house)
end

-- ===== STUDENT POINTS OPERATIONS =====
function KrPoints.Database.GetStudentPoints(student_name)
	local result = sql.QueryTyped(
		"SELECT points FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;",
		student_name
	)
	return tonumber(GetSingleValue(result, "points", 0)) or 0
end

function KrPoints.Database.SetStudentPoints(student_name, points, house)
	sql.QueryTyped(
		"INSERT OR REPLACE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, house, updated_at) VALUES ('student', ?, ?, ?, ?);",
		student_name, points, house, Now()
	)
	return true
end

function KrPoints.Database.GetStudentHouse(student_name)
	local result = sql.QueryTyped(
		"SELECT house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;",
		student_name
	)
	return GetSingleValue(result, "house", nil)
end

-- ===== QUERY OPERATIONS =====
function KrPoints.Database.GetTopStudents(limit, house_filter)
	limit = math.Clamp(tonumber(limit) or 10, 1, 100)
	
	if house_filter then
		house_filter = string.lower(house_filter)
		if not VALID_HOUSES_LOOKUP[house_filter] then
			print("[KR-PUAN] GÜVENLİK: Geçersiz house_filter: " .. tostring(house_filter))
			return {}
		end
		return sql.QueryTyped(
			"SELECT entity_id as id, points, house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND house = ? ORDER BY points DESC LIMIT ?;",
			house_filter, limit
		) or {}
	end
	
	return sql.Query(
		"SELECT entity_id as id, points, house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' ORDER BY points DESC LIMIT " .. limit .. ";"
	) or {}
end

function KrPoints.Database.GetAllHousePoints()
	local result = sql.Query(
		"SELECT entity_id as house, points FROM " .. TABLE_NAME .. " WHERE entity_type = 'house' ORDER BY points DESC;"
	)
	return result or {}
end

-- ===== RESET OPERATIONS =====
function KrPoints.Database.ResetAll()
	sql.QueryTyped("UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ?;", Now())
	print("[KR-PUAN] All points reset to zero.")
	return true
end

function KrPoints.Database.ResetHouses()
	sql.QueryTyped("UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'house';", Now())
	print("[KR-PUAN] House points reset to zero.")
	return true
end

function KrPoints.Database.ResetStudents()
	sql.QueryTyped("UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'student';", Now())
	print("[KR-PUAN] Student points reset to zero.")
	return true
end

print("[KR-PUAN] Database module loaded.")

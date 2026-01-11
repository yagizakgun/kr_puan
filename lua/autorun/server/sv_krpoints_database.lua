-- ============================================
-- KR-PUAN SYSTEM: Database Layer Module (MySQLOO 9 Compatible)
-- ============================================
-- Sorumluluk: Tüm SQL operasyonları ve veritabanı yönetimi
-- Bağımlılıklar: sv_krpoints_config.lua
-- ============================================
-- Supports both SQLite (default) and MySQL (MySQLOO 9)
-- Modern tek tablo yapısı:
--   kr_points (
--     entity_type TEXT/VARCHAR,    -- 'house' veya 'student'
--     entity_id TEXT/VARCHAR,      -- ev adı veya öğrenci adı
--     points INTEGER/INT,          -- puan değeri
--     house TEXT/VARCHAR,          -- öğrencinin evi (sadece student için)
--     updated_at INTEGER/INT,      -- son güncelleme timestamp
--     PRIMARY KEY (entity_type, entity_id)
--   )
-- ============================================

KrPoints.Database = KrPoints.Database or {}

-- Shorthand references
local TABLE_NAME = KrPoints.DB.TABLE_NAME
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES
local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP
local DB_TYPE = KrPoints.DB.TYPE

-- Database connection instance
local MySQLConnection = nil
local IsMySQL = false
local DatabaseReady = false

-- ===== HELPER FUNCTIONS =====
-- Extract single value from SQL result (reduces repetitive nil checking)
local function GetSingleValue(result, field, default)
	if result and result ~= false and result[1] then
		return result[1][field]
	end
	return default
end

-- Get current timestamp
local function Now()
	return os.time()
end

-- ===== MYSQLOO CONNECTION MANAGEMENT =====
local function ConnectMySQL()
	if not mysqloo then
		print("[KR-PUAN] WARNING: MySQLOO module not found! Falling back to SQLite.")
		return false
	end
	
	print("[KR-PUAN] Attempting to connect to MySQL...")
	print("[KR-PUAN] Host: " .. KrPoints.DB.MYSQL_HOST .. ":" .. KrPoints.DB.MYSQL_PORT)
	print("[KR-PUAN] Database: " .. KrPoints.DB.MYSQL_DATABASE)
	
	MySQLConnection = mysqloo.connect(
		KrPoints.DB.MYSQL_HOST,
		KrPoints.DB.MYSQL_USER,
		KrPoints.DB.MYSQL_PASSWORD,
		KrPoints.DB.MYSQL_DATABASE,
		KrPoints.DB.MYSQL_PORT
	)
	
	if not MySQLConnection then
		print("[KR-PUAN] ERROR: Failed to create MySQL connection object! Falling back to SQLite.")
		return false
	end
	
	-- Connection success callback
	function MySQLConnection:onConnected()
		print("[KR-PUAN] Successfully connected to MySQL database!")
		IsMySQL = true
		DatabaseReady = true
		KrPoints.Database.InitializeTables()
	end
	
	-- Connection error callback
	function MySQLConnection:onConnectionFailed(err)
		print("[KR-PUAN] ERROR: MySQL connection failed: " .. tostring(err))
		print("[KR-PUAN] Falling back to SQLite...")
		IsMySQL = false
		MySQLConnection = nil
		KrPoints.Database.InitializeSQLite()
	end
	
	-- Start the connection
	MySQLConnection:connect()
	return true
end

-- Check if MySQL connection is alive
local function IsConnectionAlive()
	if not IsMySQL or not MySQLConnection then return false end
	return MySQLConnection:status() == mysqloo.DATABASE_CONNECTED
end

-- Reconnect to MySQL if connection is lost
local function EnsureConnection(callback)
	if not IsMySQL then
		if callback then callback(true) end
		return
	end
	
	if IsConnectionAlive() then
		if callback then callback(true) end
		return
	end
	
	print("[KR-PUAN] MySQL connection lost, attempting to reconnect...")
	MySQLConnection:connect()
	MySQLConnection.onConnected = function()
		print("[KR-PUAN] Reconnected to MySQL successfully!")
		if callback then callback(true) end
	end
	MySQLConnection.onConnectionFailed = function(self, err)
		print("[KR-PUAN] Reconnection failed: " .. tostring(err))
		if callback then callback(false) end
	end
end

-- ===== QUERY ABSTRACTION LAYER =====
-- Execute a query (handles both SQLite and MySQL)
local function ExecuteQuery(query_str, callback, ...)
	if IsMySQL then
		-- MySQL (async)
		EnsureConnection(function(connected)
			if not connected then
				print("[KR-PUAN] ERROR: MySQL not connected, query failed!")
				if callback then callback(nil) end
				return
			end
			
			local query = MySQLConnection:query(query_str)
			
			function query:onSuccess(data)
				if callback then callback(data) end
			end
			
			function query:onError(err, sql)
				print("[KR-PUAN] MySQL Query Error: " .. tostring(err))
				print("[KR-PUAN] Query: " .. tostring(sql))
				if callback then callback(nil) end
			end
			
			query:start()
		end)
	else
		-- SQLite (sync)
		local result = sql.Query(query_str)
		if result == false then
			print("[KR-PUAN] SQLite Query Error: " .. tostring(sql.LastError()))
			print("[KR-PUAN] Query: " .. tostring(query_str))
		end
		if callback then callback(result) end
	end
end

-- Execute a prepared query (handles both SQLite and MySQL)
local function ExecutePreparedQuery(query_str, callback, ...)
	local params = {...}
	
	if IsMySQL then
		-- MySQL prepared statement
		EnsureConnection(function(connected)
			if not connected then
				print("[KR-PUAN] ERROR: MySQL not connected, prepared query failed!")
				if callback then callback(nil) end
				return
			end
			
			local query = MySQLConnection:prepare(query_str)
			
			-- Set parameters
			for i, param in ipairs(params) do
				if type(param) == "number" then
					query:setNumber(i, param)
				elseif type(param) == "string" then
					query:setString(i, param)
				elseif type(param) == "boolean" then
					query:setBoolean(i, param)
				elseif param == nil then
					query:setNull(i)
				end
			end
			
			function query:onSuccess(data)
				if callback then callback(data) end
			end
			
			function query:onError(err, sql)
				print("[KR-PUAN] MySQL Prepared Query Error: " .. tostring(err))
				print("[KR-PUAN] Query: " .. tostring(sql))
				if callback then callback(nil) end
			end
			
			query:start()
		end)
	else
		-- SQLite with sql.QueryTyped
		local result = sql.QueryTyped(query_str, unpack(params))
		if result == false then
			print("[KR-PUAN] SQLite Query Error: " .. tostring(sql.LastError()))
			print("[KR-PUAN] Query: " .. tostring(query_str))
		end
		if callback then callback(result) end
	end
end

-- ===== INITIALIZATION =====
function KrPoints.Database.InitializeSQLite()
	print("[KR-PUAN] Initializing SQLite database...")
	IsMySQL = false
	DatabaseReady = false
	
	if not sql.TableExists(TABLE_NAME) then
		print("[KR-PUAN] Creating SQLite table...")
		
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
			print("[KR-PUAN] ERROR: Failed to create table: " .. tostring(sql.LastError()))
			return
		end
		
		-- Create indexes
		sql.Query("CREATE INDEX IF NOT EXISTS idx_entity_type ON " .. TABLE_NAME .. " (entity_type);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_house ON " .. TABLE_NAME .. " (house);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_points ON " .. TABLE_NAME .. " (points DESC);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_type_house ON " .. TABLE_NAME .. " (entity_type, house);")
		
		print("[KR-PUAN] SQLite table and indexes created.")
	end
	
	-- Ensure all houses exist with default 0 points
	for _, house in ipairs(VALID_HOUSES) do
		sql.QueryTyped(
			"INSERT OR IGNORE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, updated_at) VALUES ('house', ?, 0, ?);",
			house, Now()
		)
	end
	
	DatabaseReady = true
	print("[KR-PUAN] SQLite database ready.")
end

function KrPoints.Database.InitializeTables()
	if IsMySQL then
		print("[KR-PUAN] Creating MySQL tables...")
		
		-- MySQL table creation
		local create_query = [[
			CREATE TABLE IF NOT EXISTS ]] .. TABLE_NAME .. [[ (
				entity_type VARCHAR(32) NOT NULL,
				entity_id VARCHAR(128) NOT NULL,
				points INT DEFAULT 0,
				house VARCHAR(32),
				updated_at INT,
				PRIMARY KEY (entity_type, entity_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
		]]
		
		ExecuteQuery(create_query, function(result)
			if result ~= nil then
				print("[KR-PUAN] MySQL table created/verified.")
				
				-- Create indexes
				ExecuteQuery("CREATE INDEX IF NOT EXISTS idx_entity_type ON " .. TABLE_NAME .. " (entity_type);")
				ExecuteQuery("CREATE INDEX IF NOT EXISTS idx_house ON " .. TABLE_NAME .. " (house);")
				ExecuteQuery("CREATE INDEX IF NOT EXISTS idx_points ON " .. TABLE_NAME .. " (points DESC);")
				ExecuteQuery("CREATE INDEX IF NOT EXISTS idx_type_house ON " .. TABLE_NAME .. " (entity_type, house);")
				
				-- Ensure all houses exist
				for _, house in ipairs(VALID_HOUSES) do
					local insert_query = "INSERT IGNORE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, updated_at) VALUES (?, ?, 0, ?);"
					ExecutePreparedQuery(insert_query, nil, "house", house, Now())
				end
				
				print("[KR-PUAN] MySQL database ready.")
			else
				print("[KR-PUAN] ERROR: Failed to create MySQL table!")
			end
		end)
	end
end

function KrPoints.Database.Initialize()
	print("[KR-PUAN] Database Type: " .. string.upper(DB_TYPE))
	
	if DB_TYPE == "mysql" then
		local success = ConnectMySQL()
		if not success then
			KrPoints.Database.InitializeSQLite()
		end
	else
		KrPoints.Database.InitializeSQLite()
	end
end

-- ===== HOUSE POINTS OPERATIONS =====
function KrPoints.Database.GetHousePoints(house, callback)
	if not VALID_HOUSES_LOOKUP[house] then
		if callback then callback(nil) end
		return nil
	end
	
	local query_str = "SELECT points FROM " .. TABLE_NAME .. " WHERE entity_type = ? AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local points = tonumber(GetSingleValue(result, "points", 0)) or 0
		if callback then callback(points) end
	end, "house", house)
	
	-- For sync compatibility (SQLite)
	if not IsMySQL and not callback then
		local result = sql.QueryTyped(query_str, "house", house)
		return tonumber(GetSingleValue(result, "points", 0)) or 0
	end
end

function KrPoints.Database.SetHousePoints(house, points, callback)
	if not VALID_HOUSES_LOOKUP[house] then
		if callback then callback(false) end
		return false
	end
	
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = ?, updated_at = ? WHERE entity_type = 'house' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		if callback then callback(result ~= nil) end
	end, points, Now(), house)
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped(query_str, points, Now(), house)
		return true
	end
end

function KrPoints.Database.AddHousePoints(house, amount, callback)
	if not VALID_HOUSES_LOOKUP[house] then
		if callback then callback(false) end
		return false
	end
	
	-- Atomic increment with single query
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = points + ?, updated_at = ? WHERE entity_type = 'house' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		-- Get updated points
		KrPoints.Database.GetHousePoints(house, function(new_points)
			if callback then callback(new_points) end
		end)
	end, amount, Now(), house)
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped(query_str, amount, Now(), house)
		return KrPoints.Database.GetHousePoints(house)
	end
end

-- ===== STUDENT POINTS OPERATIONS =====
function KrPoints.Database.GetStudentPoints(student_name, callback)
	local query_str = "SELECT points FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local points = tonumber(GetSingleValue(result, "points", 0)) or 0
		if callback then callback(points) end
	end, student_name)
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		local result = sql.QueryTyped(query_str, student_name)
		return tonumber(GetSingleValue(result, "points", 0)) or 0
	end
end

function KrPoints.Database.SetStudentPoints(student_name, points, house, callback)
	local insert_or_replace = IsMySQL and "INSERT INTO" or "INSERT OR REPLACE INTO"
	local on_duplicate = IsMySQL and " ON DUPLICATE KEY UPDATE points = VALUES(points), house = VALUES(house), updated_at = VALUES(updated_at)" or ""
	
	local query_str = insert_or_replace .. " " .. TABLE_NAME .. " (entity_type, entity_id, points, house, updated_at) VALUES (?, ?, ?, ?, ?)" .. on_duplicate .. ";"
	
	ExecutePreparedQuery(query_str, function(result)
		if callback then callback(result ~= nil) end
	end, "student", student_name, points, house, Now())
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped("INSERT OR REPLACE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, house, updated_at) VALUES ('student', ?, ?, ?, ?);", student_name, points, house, Now())
		return true
	end
end

function KrPoints.Database.GetStudentHouse(student_name, callback)
	local query_str = "SELECT house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local house = GetSingleValue(result, "house", nil)
		if callback then callback(house) end
	end, student_name)
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		local result = sql.QueryTyped(query_str, student_name)
		return GetSingleValue(result, "house", nil)
	end
end

-- ===== QUERY OPERATIONS =====
function KrPoints.Database.GetTopStudents(limit, house_filter, callback)
	limit = math.Clamp(tonumber(limit) or 10, 1, 100)
	
	if house_filter then
		house_filter = string.lower(house_filter)
		if not VALID_HOUSES_LOOKUP[house_filter] then
			print("[KR-PUAN] SECURITY: Invalid house_filter: " .. tostring(house_filter))
			if callback then callback({}) end
			return {}
		end
		
		local query_str = "SELECT entity_id as id, points, house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND house = ? ORDER BY points DESC LIMIT ?;"
		
		ExecutePreparedQuery(query_str, function(result)
			if callback then callback(result or {}) end
		end, house_filter, limit)
		
		-- For sync compatibility
		if not IsMySQL and not callback then
			return sql.QueryTyped(query_str, house_filter, limit) or {}
		end
	else
		local query_str = "SELECT entity_id as id, points, house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' ORDER BY points DESC LIMIT " .. limit .. ";"
		
		ExecuteQuery(query_str, function(result)
			if callback then callback(result or {}) end
		end)
		
		-- For sync compatibility
		if not IsMySQL and not callback then
			return sql.Query(query_str) or {}
		end
	end
end

function KrPoints.Database.GetAllHousePoints(callback)
	local query_str = "SELECT entity_id as house, points FROM " .. TABLE_NAME .. " WHERE entity_type = 'house' ORDER BY points DESC;"
	
	ExecuteQuery(query_str, function(result)
		if callback then callback(result or {}) end
	end)
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		return sql.Query(query_str) or {}
	end
end

-- ===== RESET OPERATIONS =====
function KrPoints.Database.ResetAll(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] All points reset to zero.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] All points reset to zero.")
		return true
	end
end

function KrPoints.Database.ResetHouses(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'house';"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] House points reset to zero.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] House points reset to zero.")
		return true
	end
end

function KrPoints.Database.ResetStudents(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'student';"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] Student points reset to zero.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	-- For sync compatibility
	if not IsMySQL and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] Student points reset to zero.")
		return true
	end
end

-- ===== UTILITY FUNCTIONS =====
function KrPoints.Database.IsMySQL()
	return IsMySQL
end

function KrPoints.Database.IsReady()
	return DatabaseReady
end

print("[KR-PUAN] Database module loaded (MySQLOO 9 compatible).")

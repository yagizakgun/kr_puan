KrPoints.Database = KrPoints.Database or {}

local TABLE_NAME = KrPoints.DB.TABLE_NAME
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES
local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP
local DB_TYPE = KrPoints.DB.TYPE

KrPoints.Database._MySQLConnection = KrPoints.Database._MySQLConnection or nil
KrPoints.Database._IsMySQL = KrPoints.Database._IsMySQL or false
KrPoints.Database._DatabaseReady = KrPoints.Database._DatabaseReady or false
KrPoints.Database._Initialized = KrPoints.Database._Initialized or false

local function GetMySQLConnection()
	return KrPoints.Database._MySQLConnection
end

local function SetMySQLConnection(conn)
	KrPoints.Database._MySQLConnection = conn
end

local function GetIsMySQL()
	return KrPoints.Database._IsMySQL
end

local function SetIsMySQL(value)
	KrPoints.Database._IsMySQL = value
end

local function GetDatabaseReady()
	return KrPoints.Database._DatabaseReady
end

local function SetDatabaseReady(value)
	KrPoints.Database._DatabaseReady = value
end

local function GetSingleValue(result, field, default)
	if result and result ~= false and result[1] then
		return result[1][field]
	end
	return default
end

local function Now()
	return os.time()
end

local function ConnectMySQL()
	if not mysqloo then
		print("[KR-PUAN] [UYARI] MySQLOO modülü bulunamadı! SQLite'a geçiliyor.")
		return false
	end
	
	local existingConn = GetMySQLConnection()
	if existingConn and existingConn:status() == mysqloo.DATABASE_CONNECTED then
		print("[KR-PUAN] [BİLGİ] MySQL zaten bağlı, yeniden bağlanma atlanıyor.")
		return true
	end
	
	print("[KR-PUAN] [BİLGİ] MySQL'e bağlanılmaya çalışılıyor...")
	print("[KR-PUAN] [BİLGİ] Sunucu: " .. KrPoints.DB.MYSQL_HOST .. ":" .. KrPoints.DB.MYSQL_PORT)
	print("[KR-PUAN] [BİLGİ] Veritabanı: " .. KrPoints.DB.MYSQL_DATABASE)
	
	local conn = mysqloo.connect(
		KrPoints.DB.MYSQL_HOST,
		KrPoints.DB.MYSQL_USER,
		KrPoints.DB.MYSQL_PASSWORD,
		KrPoints.DB.MYSQL_DATABASE,
		KrPoints.DB.MYSQL_PORT
	)
	
	if not conn then
		print("[KR-PUAN] [HATA] MySQL bağlantı nesnesi oluşturulamadı! SQLite'a geçiliyor.")
		return false
	end
	
	SetMySQLConnection(conn)
	
	function conn:onConnected()
		print("[KR-PUAN] [BAŞARILI] MySQL veritabanına başarıyla bağlanıldı!")
		SetIsMySQL(true)
		SetDatabaseReady(true)
		KrPoints.Database.InitializeTables()
	end
	
	function conn:onConnectionFailed(err)
		print("[KR-PUAN] [HATA] MySQL bağlantısı başarısız oldu: " .. tostring(err))
		print("[KR-PUAN] [BİLGİ] SQLite'a geçiliyor...")
		SetIsMySQL(false)
		SetMySQLConnection(nil)
		KrPoints.Database.InitializeSQLite()
	end
	
	conn:connect()
	return true
end

local function IsConnectionAlive()
	local conn = GetMySQLConnection()
	if not GetIsMySQL() or not conn then return false end
	return conn:status() == mysqloo.DATABASE_CONNECTED
end

local function EnsureConnection(callback)
	if not GetIsMySQL() then
		if callback then callback(true) end
		return
	end
	
	if IsConnectionAlive() then
		if callback then callback(true) end
		return
	end
	
	local conn = GetMySQLConnection()
	if not conn then
		if callback then callback(false) end
		return
	end
	
	print("[KR-PUAN] [UYARI] MySQL bağlantısı koptu, yeniden bağlanılmaya çalışılıyor...")
	conn:connect()
	conn.onConnected = function()
		print("[KR-PUAN] [BAŞARILI] MySQL'e başarıyla yeniden bağlanıldı!")
		if callback then callback(true) end
	end
	conn.onConnectionFailed = function(self, err)
		print("[KR-PUAN] [HATA] Yeniden bağlanma başarısız oldu: " .. tostring(err))
		if callback then callback(false) end
	end
end

local function ExecuteQuery(query_str, callback, ...)
	if GetIsMySQL() then
		EnsureConnection(function(connected)
			if not connected then
				print("[KR-PUAN] [HATA] MySQL bağlı değil, sorgu başarısız oldu!")
				if callback then callback(nil) end
				return
			end
			
			local conn = GetMySQLConnection()
			if not conn then
				print("[KR-PUAN] [HATA] MySQL bağlantı nesnesi nil!")
				if callback then callback(nil) end
				return
			end
			
			local query = conn:query(query_str)
			
			function query:onSuccess(data)
				if callback then callback(data) end
			end
			
			function query:onError(err, sql)
				print("[KR-PUAN] [HATA] MySQL sorgu hatası: " .. tostring(err))
				print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(sql))
				if callback then callback(nil) end
			end
			
			query:start()
		end)
	else
		local result = sql.Query(query_str)
		if result == false then
			print("[KR-PUAN] [HATA] SQLite sorgu hatası: " .. tostring(sql.LastError()))
			print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(query_str))
		end
		if callback then callback(result) end
	end
end

local function ExecutePreparedQuery(query_str, callback, ...)
	local params = {...}
	
	if GetIsMySQL() then
		EnsureConnection(function(connected)
			if not connected then
				print("[KR-PUAN] [HATA] MySQL bağlı değil, hazırlanan sorgu başarısız oldu!")
				if callback then callback(nil) end
				return
			end
			
			local conn = GetMySQLConnection()
			if not conn then
				print("[KR-PUAN] [HATA] MySQL bağlantı nesnesi nil!")
				if callback then callback(nil) end
				return
			end
			
			local query = conn:prepare(query_str)
			
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
				print("[KR-PUAN] [HATA] MySQL hazırlanan sorgu hatası: " .. tostring(err))
				print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(sql))
				if callback then callback(nil) end
			end
			
			query:start()
		end)
	else
		local result = sql.QueryTyped(query_str, unpack(params))
		if result == false then
			print("[KR-PUAN] [HATA] SQLite sorgu hatası: " .. tostring(sql.LastError()))
			print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(query_str))
		end
		if callback then callback(result) end
	end
end

function KrPoints.Database.InitializeSQLite()
	print("[KR-PUAN] [BİLGİ] SQLite veritabanı başlatılıyor...")
	SetIsMySQL(false)
	SetDatabaseReady(false)
	
	if not sql.TableExists(TABLE_NAME) then
		print("[KR-PUAN] [BİLGİ] SQLite tablosu oluşturuluyor...")
		
		local create_result = sql.Query([[
			CREATE TABLE ]] .. TABLE_NAME .. [[ (
				entity_type TEXT NOT NULL,
				entity_id TEXT NOT NULL,
				points INTEGER DEFAULT 0,
				house TEXT,
				display_name TEXT,
				updated_at INTEGER,
				PRIMARY KEY (entity_type, entity_id)
			);
		]])
		
		if create_result == false then
			print("[KR-PUAN] [HATA] Tablo oluşturulamadı: " .. tostring(sql.LastError()))
			return
		end
		
		sql.Query("CREATE INDEX IF NOT EXISTS idx_entity_type ON " .. TABLE_NAME .. " (entity_type);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_house ON " .. TABLE_NAME .. " (house);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_points ON " .. TABLE_NAME .. " (points DESC);")
		sql.Query("CREATE INDEX IF NOT EXISTS idx_type_house ON " .. TABLE_NAME .. " (entity_type, house);")
		
		print("[KR-PUAN] [BAŞARILI] SQLite tablosu ve indeksler oluşturuldu.")
	else
		local columns = sql.Query("PRAGMA table_info(" .. TABLE_NAME .. ");")
		local has_display_name = false
		if columns then
			for _, col in ipairs(columns) do
				if col.name == "display_name" then
					has_display_name = true
					break
				end
			end
		end
		if not has_display_name then
			print("[KR-PUAN] [BİLGİ] Mevcut tabloya display_name kolonu ekleniyor...")
			sql.Query("ALTER TABLE " .. TABLE_NAME .. " ADD COLUMN display_name TEXT;")
		end
	end
	
	for _, house in ipairs(VALID_HOUSES) do
		sql.QueryTyped(
			"INSERT OR IGNORE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, updated_at) VALUES ('house', ?, 0, ?);",
			house, Now()
		)
	end
	
	SetDatabaseReady(true)
	print("[KR-PUAN] [BAŞARILI] SQLite veritabanı hazır.")
end

function KrPoints.Database.InitializeTables()
	if GetIsMySQL() then
		print("[KR-PUAN] [BİLGİ] MySQL tabloları oluşturuluyor...")
		
		local create_query = [[
			CREATE TABLE IF NOT EXISTS ]] .. TABLE_NAME .. [[ (
				entity_type VARCHAR(32) NOT NULL,
				entity_id VARCHAR(128) NOT NULL,
				points INT DEFAULT 0,
				house VARCHAR(32),
				display_name VARCHAR(128),
				updated_at INT,
				PRIMARY KEY (entity_type, entity_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
		]]
		
		ExecuteQuery(create_query, function(result)
			if result ~= nil then
				print("[KR-PUAN] [BAŞARILI] MySQL tablosu oluşturuldu/doğrulandı.")
				
				ExecuteQuery("SHOW COLUMNS FROM " .. TABLE_NAME .. " LIKE 'display_name';", function(col_result)
					if not col_result or #col_result == 0 then
						local conn = GetMySQLConnection()
						if conn then
							local query = conn:query("ALTER TABLE " .. TABLE_NAME .. " ADD COLUMN display_name VARCHAR(128);")
							function query:onSuccess(data)
								print("[KR-PUAN] [BAŞARILI] display_name kolonu eklendi.")
							end
							function query:onError(err, sql)
								if not string.find(err, "Duplicate column name") then
									print("[KR-PUAN] [HATA] MySQL sorgu hatası: " .. tostring(err))
									print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(sql))
								end
							end
							query:start()
						end
					end
				end)
				
				local indexes = {
					{name = "idx_entity_type", def = "CREATE INDEX idx_entity_type ON " .. TABLE_NAME .. " (entity_type);"},
					{name = "idx_house", def = "CREATE INDEX idx_house ON " .. TABLE_NAME .. " (house);"},
					{name = "idx_points", def = "CREATE INDEX idx_points ON " .. TABLE_NAME .. " (points DESC);"},
					{name = "idx_type_house", def = "CREATE INDEX idx_type_house ON " .. TABLE_NAME .. " (entity_type, house);"}
				}
				
				for _, idx in ipairs(indexes) do
					ExecuteQuery("SHOW INDEX FROM " .. TABLE_NAME .. " WHERE Key_name = '" .. idx.name .. "';", function(idx_result)
						if not idx_result or #idx_result == 0 then
							local conn = GetMySQLConnection()
							if conn then
								local query = conn:query(idx.def)
								function query:onSuccess(data)
									print("[KR-PUAN] [BAŞARILI] İndeks oluşturuldu: " .. idx.name)
								end
								function query:onError(err, sql)
									if not string.find(err, "Duplicate key name") then
										print("[KR-PUAN] [HATA] MySQL sorgu hatası: " .. tostring(err))
										print("[KR-PUAN] [BİLGİ] Sorgu: " .. tostring(sql))
									end
								end
								query:start()
							end
						end
					end)
				end
				
				for _, house in ipairs(VALID_HOUSES) do
					local insert_query = "INSERT IGNORE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, updated_at) VALUES (?, ?, 0, ?);"
					ExecutePreparedQuery(insert_query, nil, "house", house, Now())
				end
				
				print("[KR-PUAN] [BAŞARILI] MySQL veritabanı hazır.")
			else
				print("[KR-PUAN] [HATA] MySQL tablosu oluşturulamadı!")
			end
		end)
	end
end

function KrPoints.Database.Initialize()
	if KrPoints.Database._Initialized then
		print("[KR-PUAN] [BİLGİ] Veritabanı zaten başlatılmış, atlanıyor...")
		return
	end
	KrPoints.Database._Initialized = true
	
	print("[KR-PUAN] [BİLGİ] Veritabanı Tipi: " .. string.upper(DB_TYPE))
	
	if DB_TYPE == "mysql" then
		local success = ConnectMySQL()
		if not success then
			print("[KR-PUAN] [UYARI] MySQL bağlantısı başarısız oldu, SQLite'a geçiliyor...")
			KrPoints.Database.InitializeSQLite()
		end
	else
		KrPoints.Database.InitializeSQLite()
	end
end

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
	
	if not GetIsMySQL() and not callback then
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
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped(query_str, points, Now(), house)
		return true
	end
end

function KrPoints.Database.AddHousePoints(house, amount, callback)
	if not VALID_HOUSES_LOOKUP[house] then
		if callback then callback(false) end
		return false
	end
	
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = points + ?, updated_at = ? WHERE entity_type = 'house' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		KrPoints.Database.GetHousePoints(house, function(new_points)
			if callback then callback(new_points) end
		end)
	end, amount, Now(), house)
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped(query_str, amount, Now(), house)
		return KrPoints.Database.GetHousePoints(house)
	end
end

function KrPoints.Database.GetStudentPoints(student_name, callback)
	local query_str = "SELECT points FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local points = tonumber(GetSingleValue(result, "points", 0)) or 0
		if callback then callback(points) end
	end, student_name)
	
	if not GetIsMySQL() and not callback then
		local result = sql.QueryTyped(query_str, student_name)
		return tonumber(GetSingleValue(result, "points", 0)) or 0
	end
end

function KrPoints.Database.SetStudentPoints(student_name, points, house, callback, display_name)
	local insert_or_replace = GetIsMySQL() and "INSERT INTO" or "INSERT OR REPLACE INTO"
	local on_duplicate = GetIsMySQL() and " ON DUPLICATE KEY UPDATE points = VALUES(points), house = VALUES(house), display_name = VALUES(display_name), updated_at = VALUES(updated_at)" or ""
	
	local query_str = insert_or_replace .. " " .. TABLE_NAME .. " (entity_type, entity_id, points, house, display_name, updated_at) VALUES (?, ?, ?, ?, ?, ?)" .. on_duplicate .. ";"
	
	ExecutePreparedQuery(query_str, function(result)
		if callback then callback(result ~= nil) end
	end, "student", student_name, points, house, display_name, Now())
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped("INSERT OR REPLACE INTO " .. TABLE_NAME .. " (entity_type, entity_id, points, house, display_name, updated_at) VALUES ('student', ?, ?, ?, ?, ?);", student_name, points, house, display_name, Now())
		return true
	end
end

function KrPoints.Database.GetStudentDisplayName(student_id, callback)
	local query_str = "SELECT display_name FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local name = GetSingleValue(result, "display_name", nil)
		if callback then callback(name) end
	end, student_id)
		
	if not GetIsMySQL() and not callback then
		local result = sql.QueryTyped(query_str, student_id)
		return GetSingleValue(result, "display_name", nil)
	end
end

function KrPoints.Database.GetStudentHouse(student_name, callback)
	local query_str = "SELECT house FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND entity_id = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		local house = GetSingleValue(result, "house", nil)
		if callback then callback(house) end
	end, student_name)
	
	if not GetIsMySQL() and not callback then
		local result = sql.QueryTyped(query_str, student_name)
		return GetSingleValue(result, "house", nil)
	end
end

function KrPoints.Database.GetTopStudents(limit, house_filter, callback)
	limit = math.Clamp(tonumber(limit) or 10, 1, 100)
	
	if house_filter then
		house_filter = string.lower(house_filter)
		if not VALID_HOUSES_LOOKUP[house_filter] then
			print("[KR-PUAN] [GÜVENLİK] Geçersiz house_filter: " .. tostring(house_filter))
			if callback then callback({}) end
			return {}
		end
		
		local query_str = "SELECT entity_id as id, points, house, display_name FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' AND house = ? ORDER BY points DESC LIMIT " .. limit .. ";"
		
		ExecutePreparedQuery(query_str, function(result)
			if callback then callback(result or {}) end
		end, house_filter)
		
		if not GetIsMySQL() and not callback then
			return sql.QueryTyped(query_str, house_filter) or {}
		end
	else
		local query_str = "SELECT entity_id as id, points, house, display_name FROM " .. TABLE_NAME .. " WHERE entity_type = 'student' ORDER BY points DESC LIMIT " .. limit .. ";"
		
		ExecuteQuery(query_str, function(result)
			if callback then callback(result or {}) end
		end)
		
		if not GetIsMySQL() and not callback then
			return sql.Query(query_str) or {}
		end
	end
end

function KrPoints.Database.GetAllHousePoints(callback)
	local query_str = "SELECT entity_id as house, points FROM " .. TABLE_NAME .. " WHERE entity_type = 'house' ORDER BY points DESC;"
	
	ExecuteQuery(query_str, function(result)
		if callback then callback(result or {}) end
	end)
	
	if not GetIsMySQL() and not callback then
		return sql.Query(query_str) or {}
	end
end

function KrPoints.Database.ResetAll(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ?;"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] [BAŞARILI] Tüm puanlar sıfırlandı.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] [BAŞARILI] Tüm puanlar sıfırlandı.")
		return true
	end
end

function KrPoints.Database.ResetHouses(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'house';"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] [BAŞARILI] Ev puanları sıfırlandı.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] [BAŞARILI] Ev puanları sıfırlandı.")
		return true
	end
end

function KrPoints.Database.ResetStudents(callback)
	local query_str = "UPDATE " .. TABLE_NAME .. " SET points = 0, updated_at = ? WHERE entity_type = 'student';"
	
	ExecutePreparedQuery(query_str, function(result)
		print("[KR-PUAN] [BAŞARILI] Öğrenci puanları sıfırlandı.")
		if callback then callback(result ~= nil) end
	end, Now())
	
	if not GetIsMySQL() and not callback then
		sql.QueryTyped(query_str, Now())
		print("[KR-PUAN] [BAŞARILI] Öğrenci puanları sıfırlandı.")
		return true
	end
end

function KrPoints.Database.IsMySQL()
	return GetIsMySQL()
end

function KrPoints.Database.IsReady()
	return GetDatabaseReady()
end

print("[KR-PUAN] [BAŞARILI] Veritabanı modülü yüklendi (MySQLOO 9 uyumlu).")

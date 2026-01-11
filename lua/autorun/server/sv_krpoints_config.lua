-- ============================================
-- KR-PUAN SYSTEM: Server Configuration Module
-- ============================================
-- Sorumluluk: Tüm server-side sabitler ve konfigürasyon
-- Bağımlılıklar: sh_config.lua (shared config'den extend eder)
-- ============================================

-- Ensure KrPoints namespace exists (already created by sh_config.lua)
KrPoints = KrPoints or {}

-- ===== DATABASE CONFIGURATION =====
KrPoints.DB = KrPoints.DB or {}
KrPoints.DB.TABLE_NAME = KrPoints.TableName or "kr_points"
KrPoints.DB.TYPE = KrPoints.DatabaseType or "sqlite"
KrPoints.DB.MYSQL_HOST = KrPoints.MySQLHost or "localhost"
KrPoints.DB.MYSQL_PORT = KrPoints.MySQLPort or 3306
KrPoints.DB.MYSQL_DATABASE = KrPoints.MySQLDatabase or "gmod_krpuan"
KrPoints.DB.MYSQL_USER = KrPoints.MySQLUser or "root"
KrPoints.DB.MYSQL_PASSWORD = KrPoints.MySQLPassword or ""

-- ===== SECURITY CONFIGURATION =====
KrPoints.Security = KrPoints.Security or {}
KrPoints.Security.RATE_LIMIT_SECONDS = KrPoints.RateLimitSeconds or 3.0
KrPoints.Security.RATE_LIMIT_DECAY_TIME = KrPoints.RateLimitDecayTime or 300
KrPoints.Security.MAX_POINTS_PER_ACTION = KrPoints.MaxPointsPerAction or 5
KrPoints.Security.MIN_POINTS_PER_ACTION = KrPoints.MinPointsPerAction or 1
KrPoints.Security.PROFESSOR_FALLBACK_REQUIRE_ADMIN = KrPoints.ProfessorFallbackRequireAdmin or true

-- ===== VALID HOUSES CONFIGURATION =====
KrPoints.Houses = KrPoints.Houses or {}
KrPoints.Houses.VALID_HOUSES = {"gryffindor", "hufflepuff", "ravenclaw", "slytherin"}
KrPoints.Houses.VALID_HOUSES_LOOKUP = {
	["gryffindor"] = true,
	["hufflepuff"] = true,
	["ravenclaw"] = true,
	["slytherin"] = true
}

-- ===== RESET COMMAND CONFIGURATION =====
KrPoints.Reset = KrPoints.Reset or {}
KrPoints.Reset.ALLOWED_RANKS = KrPoints.ResetAllowedRanks or {
	["superadmin"] = true,
	["owner"] = true,
}

print("[KR-PUAN] Configuration module loaded.")

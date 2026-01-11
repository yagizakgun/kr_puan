KrPoints = KrPoints or {}

-- ===== ELLEMEYİN =====
KrPoints.DB = KrPoints.DB or {}
KrPoints.DB.TABLE_NAME = KrPoints.TableName or "kr_points"
KrPoints.DB.TYPE = KrPoints.DatabaseType or "sqlite"
KrPoints.DB.MYSQL_HOST = KrPoints.MySQLHost or "localhost"
KrPoints.DB.MYSQL_PORT = KrPoints.MySQLPort or 3306
KrPoints.DB.MYSQL_DATABASE = KrPoints.MySQLDatabase or "gmod_krpuan"
KrPoints.DB.MYSQL_USER = KrPoints.MySQLUser or "root"
KrPoints.DB.MYSQL_PASSWORD = KrPoints.MySQLPassword or ""
	
-- ===== ELLEMEYİN =====
KrPoints.Security = KrPoints.Security or {}
KrPoints.Security.RATE_LIMIT_SECONDS = KrPoints.RateLimitSeconds or 3.0
KrPoints.Security.RATE_LIMIT_DECAY_TIME = KrPoints.RateLimitDecayTime or 300
KrPoints.Security.MAX_POINTS_PER_ACTION = KrPoints.MaxPointsPerAction or 5
KrPoints.Security.MIN_POINTS_PER_ACTION = KrPoints.MinPointsPerAction or 1
KrPoints.Security.PROFESSOR_FALLBACK_REQUIRE_ADMIN = KrPoints.ProfessorFallbackRequireAdmin or true

-- ===== GEÇERLİ HANELER =====
KrPoints.Houses = KrPoints.Houses or {}
KrPoints.Houses.VALID_HOUSES = {"gryffindor", "hufflepuff", "ravenclaw", "slytherin"}
KrPoints.Houses.VALID_HOUSES_LOOKUP = {
	["gryffindor"] = true,
	["hufflepuff"] = true,
	["ravenclaw"] = true,
	["slytherin"] = true
}

-- ===== DATA RESETLEME YAPILANDIRMASI =====
KrPoints.Reset = KrPoints.Reset or {}
KrPoints.Reset.ALLOWED_RANKS = KrPoints.ResetAllowedRanks or {
	["superadmin"] = true,
	["owner"] = true,
}

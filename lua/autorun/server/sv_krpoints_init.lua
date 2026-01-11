-- ============================================
-- KR-PUAN SYSTEM: Main Initialization Module
-- ============================================
-- Sorumluluk: Modülleri başlatma ve orchestration
-- Bu dosya tüm modülleri doğru sırada yükler ve sistemi başlatır
-- ============================================

print("[KR-PUAN] ============================================")
print("[KR-PUAN] Starting KR-PUAN Modular System...")
print("[KR-PUAN] ============================================")

-- ===== LOAD MODULES IN DEPENDENCY ORDER =====
-- Critical: Modules must be loaded in this specific order

-- 1. Configuration (no dependencies)
include("autorun/server/sv_krpoints_config.lua")

-- 2. Core modules (depend on config only)
include("autorun/server/sv_krpoints_database.lua")
include("autorun/server/sv_krpoints_permissions.lua")
include("autorun/server/sv_krpoints_ratelimit.lua")

-- 3. Business logic (depends on config + database)
include("autorun/server/sv_krpoints_points.lua")

-- 4. Network layer (depends on all above)
include("autorun/server/sv_krpoints_network.lua")

print("[KR-PUAN] All modules loaded successfully.")

-- ===== SYSTEM INITIALIZATION =====
hook.Add("Initialize", "KrPoints.System", function()
	-- Initialize database
	KrPoints.Database.Initialize()
	
	-- Sync global ints with database values
	KrPoints.Points.SyncGlobalInts()
	
	-- Register network handlers
	KrPoints.Network.RegisterHandlers()
	
	print("[KR-PUAN] ============================================")
	print("[KR-PUAN] Sistema başlatıldı (Modular Architecture)")
	print("[KR-PUAN] Modules: Config, Database, Permissions, RateLimit, Points, Network")
	print("[KR-PUAN] ============================================")
end)

-- Initialize immediately if sql is already available
if sql.TableExists then 
	KrPoints.Database.Initialize()
	KrPoints.Points.SyncGlobalInts()
end

-- ===== SYSTEM CLEANUP =====
hook.Add("ShutDown", "KrPoints.Cleanup", function()
	-- Cleanup rate limiting timers
	KrPoints.RateLimit.Cleanup()
	
	print("[KR-PUAN] System cleanup completed.")
end)

-- ===== BACKWARDS COMPATIBILITY API =====
-- Expose legacy function for backwards compatibility
KrPoints.GetTopStudents = KrPoints.Database.GetTopStudents

print("[KR-PUAN] Initialization module loaded.")

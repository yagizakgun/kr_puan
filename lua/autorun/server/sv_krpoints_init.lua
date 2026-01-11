
print("[KR-PUAN] ============================================")
print("[KR-PUAN] Starting KR-PUAN Modular System...")
print("[KR-PUAN] ============================================")	
include("autorun/server/sv_krpoints_config.lua")
include("autorun/server/sv_krpoints_database.lua")
include("autorun/server/sv_krpoints_permissions.lua")
include("autorun/server/sv_krpoints_ratelimit.lua")
include("autorun/server/sv_krpoints_points.lua")
include("autorun/server/sv_krpoints_network.lua")

hook.Add("Initialize", "KrPoints.System", function()
	KrPoints.Database.Initialize()
	KrPoints.Points.SyncGlobalInts()
	KrPoints.Network.RegisterHandlers()
end)

if sql.TableExists then 
	KrPoints.Database.Initialize()
	KrPoints.Points.SyncGlobalInts()
end

hook.Add("ShutDown", "KrPoints.Cleanup", function()
	KrPoints.RateLimit.Cleanup()
	
	print("[KR-PUAN] System cleanup completed.")
end)

KrPoints.GetTopStudents = KrPoints.Database.GetTopStudents

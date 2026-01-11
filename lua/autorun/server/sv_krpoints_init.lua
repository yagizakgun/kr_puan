local initialized = false

hook.Add("Initialize", "KrPoints.System", function()
	if initialized then return end
	initialized = true
	
	-- Veritabanını başlat (MySQL veya SQLite)
	KrPoints.Database.Initialize()
	
	-- MySQL async olduğundan, sync işlemleri biraz bekletmeliyiz
	if KrPoints.DB.TYPE == "mysql" then
		-- MySQL bağlantısı async, bir sonraki tick'te sync yapalım
		timer.Simple(1, function()
			if KrPoints.Database.IsReady() then
				KrPoints.Points.SyncGlobalInts()
			end
		end)
	else
		KrPoints.Points.SyncGlobalInts()
	end
	
	KrPoints.Network.RegisterHandlers()
end)

-- Hot-reload desteği için (harita değişiminde veya lua_run ile yeniden yüklendiğinde)
timer.Simple(0.1, function()
	if not initialized and KrPoints.Database and KrPoints.Database.Initialize then
		initialized = true
		KrPoints.Database.Initialize()
		
		if KrPoints.DB.TYPE == "mysql" then
			timer.Simple(1, function()
				if KrPoints.Database.IsReady() then
					KrPoints.Points.SyncGlobalInts()
				end
			end)
		else
			KrPoints.Points.SyncGlobalInts()
		end
	end
end)

hook.Add("ShutDown", "KrPoints.Cleanup", function()
	KrPoints.RateLimit.Cleanup()
	
	print("[KR-PUAN] System cleanup completed.")
end)

KrPoints.GetTopStudents = KrPoints.Database.GetTopStudents

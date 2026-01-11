KrPoints = KrPoints or {}

-- Colors
KrPoints.White = Color(255, 255, 255)
KrPoints.Black = Color(0, 0, 0)
KrPoints.Blue = Color(36, 92, 170)
KrPoints.Red = Color(167, 0, 0)
KrPoints.Purple = Color(255, 0, 255)
KrPoints.Yellow = Color(201, 152, 18)
KrPoints.Green = Color(11, 85, 11)

KrPoints.ShowNotificationHud = true -- Enable/Disable notification HUD (true/false)
KrPoints.NotificationDuration = 7 -- Notification duration in seconds


-- Faction Names
KrPoints.FactionRavenclaw = "Ravenclaw Öğrencisi"
KrPoints.FactionGryffindor = "Gryffindor Öğrencisi"
KrPoints.FactionSlytherin = "Slytherin Öğrencisi"
KrPoints.FactionHufflepuff = "Hufflepuff Öğrencisi"

-- Logos
KrPoints.LogoHufflepuff = Material("rlib/interface/grunge/banners/hogwarts/em_hu.png")
KrPoints.LogoSlytherin = Material("rlib/interface/grunge/banners/hogwarts/em_sl.png")
KrPoints.LogoGryffindor = Material("rlib/interface/grunge/banners/hogwarts/em_gr.png")
KrPoints.LogoRavenclaw = Material("rlib/interface/grunge/banners/hogwarts/em_ra.png")

-- ===== SHARED DATA =====
KrPoints.HouseList = {"Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"}
KrPoints.HouseKeys = {
	Gryffindor = "gryffindor",
	Hufflepuff = "hufflepuff",
	Ravenclaw = "ravenclaw",
	Slytherin = "slytherin",
}


-- ===== SERVER-SIDE CONFIGURATION =====
if SERVER then
	-- Security Settings
	KrPoints.RateLimitSeconds = 3.0          -- Time between point giving actions (prevents spam)
	KrPoints.RateLimitDecayTime = 300        -- Cleanup old rate limit entries after this time (seconds)
	KrPoints.MaxPointsPerAction = 5          -- Maximum points that can be given/taken at once
	KrPoints.MinPointsPerAction = 1          -- Minimum points that can be given/taken at once
	
	-- Professor Fallback Security
	KrPoints.ProfessorFallbackRequireAdmin = true  -- If fx_d system not found, require superadmin (true) or allow all admins (false)
	
	-- Gamemode Settings
	KrPoints.UsingGamemode = "helix"         -- "helix", "darkrp", "others"
	
	-- Database Settings
	KrPoints.TableName = "kr_points"
	
	-- ===== DATABASE TYPE CONFIGURATION =====
	-- Choose your database system: "sqlite" or "mysql"
	KrPoints.DatabaseType = "sqlite"         -- "sqlite" (default, no setup needed) or "mysql" (requires MySQLOO 9)
	
	-- ===== MYSQL CONFIGURATION =====
	-- Only used if DatabaseType = "mysql"
	-- MySQLOO 9 is required: https://github.com/FredyH/MySQLOO
	KrPoints.MySQLHost = "localhost"         -- MySQL server host
	KrPoints.MySQLPort = 3306                -- MySQL server port
	KrPoints.MySQLDatabase = "gmod_krpuan"   -- Database name
	KrPoints.MySQLUser = "root"              -- MySQL username
	KrPoints.MySQLPassword = ""              -- MySQL password
	
	-- Reset Command Allowed Ranks
	KrPoints.ResetAllowedRanks = {
		["superadmin"] = true,
		["owner"] = true,
		["ownerast"] = true,
		["yetkilisorumlusu"] = true,
		["yonetimsefi"] = true,
	}

	resource.AddFile("resource/fonts/cinzel_decorative.ttf") 
    resource.AddFile("resource/fonts/crimson_text.ttf")
    resource.AddFile("resource/fonts/im_fell_english.ttf")
end

if CLIENT then
	hook.Add("Initialize", "KrPoints.PrecacheMaterials", function()
		local materials_to_precache = {
			KrPoints.LogoHufflepuff,
			KrPoints.LogoSlytherin,
			KrPoints.LogoGryffindor,
			KrPoints.LogoRavenclaw,
		}
		
		for _, mat in ipairs(materials_to_precache) do
			if mat and not mat:IsError() then
				-- Touch the material to ensure it's loaded
				mat:GetTexture("$basetexture")
			end
		end
		
		print("[KR-PUAN] Materials precached successfully.")
	end)

	-- HUD Position Settings (percentage of screen width/height)
	KrPoints.HUD = KrPoints.HUD or {}
	KrPoints.HUD.WeaponBoxX = 0.385      -- X position of weapon HUD box
	KrPoints.HUD.WeaponBoxY = 0.915      -- Y position of weapon HUD box
	KrPoints.HUD.WeaponBoxWidth = 0.17   -- Width of weapon HUD box
	KrPoints.HUD.WeaponBoxHeight = 0.07  -- Height of weapon HUD box
	
	-- Weapon HUD Text Positions (percentage of screen width/height)
	KrPoints.HUD.WeaponText = {
		LabelX = 0.4,          -- X position of "Puan Modu:" label
		LabelY = 0.92,         -- Y position of "Puan Modu:" label
		HintRightClickX = 0.52,  -- X position of "(Sağ Tık)" hint
		HintRightClickY = 0.92,  -- Y position of "(Sağ Tık)" hint
		HintReloadX = 0.52,    -- X position of "(R)" hint
		HintReloadY = 0.95,    -- Y position of "(R)" hint
		StatusLabelX = 0.4,    -- X position of "Verilecek/Alınacak Puan:" label
		StatusLabelY = 0.95,   -- Y position of "Verilecek/Alınacak Puan:" label
		ModeX = 0.475,         -- X position of "Ver"/"Al" mode indicator
		ModeY = 0.92,          -- Y position of "Ver"/"Al" mode indicator
		PointsX = 0.493,       -- X position of points value
		PointsY = 0.95,        -- Y position of points value
	}
	
	KrPoints.HUD.NotificationBoxWidth = 0.3   -- Width of notification box
	KrPoints.HUD.NotificationBoxHeight = 0.1  -- Height of notification box
	KrPoints.HUD.NotificationBoxY = 0.01      -- Y position of notification box
	
	-- HUD Colors
	KrPoints.HUD.BackgroundColor = Color(0, 0, 0, 200)
	KrPoints.HUD.BackgroundColorDark = Color(0, 0, 0, 220)
	KrPoints.HUD.OrangeColor = Color(255, 128, 0)
	KrPoints.HUD.PinkColor = Color(255, 0, 128)
end
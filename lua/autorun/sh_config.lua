KrPoints = KrPoints or {}

-- Renkler
KrPoints.White = Color(255, 255, 255)
KrPoints.Black = Color(0, 0, 0)
KrPoints.Blue = Color(36, 92, 170)
KrPoints.Red = Color(167, 0, 0)
KrPoints.Purple = Color(255, 0, 255)
KrPoints.Yellow = Color(201, 152, 18)
KrPoints.Green = Color(11, 85, 11)

KrPoints.ShowNotificationHud = true -- Bildirim HUD'unu aç/kapat (true/false)
KrPoints.NotificationDuration = 7 -- Bildirim süresi (saniye cinsinden)


-- ===== ÖĞRENCİ FACTION AYARLARI =====
-- Buraya hangi factionların öğrenci sayılacağını ekleyebilirsiniz.
-- Her ev için birden fazla faction ismi tanımlayabilirsiniz.
-- Örnek: Sunucunuzda "Ravenclaw Hane Başkanı" gibi factionlar varsa hepsini ekleyin.
KrPoints.StudentFactions = {
	-- Ravenclaw öğrenci factionları
	ravenclaw = {
		"Ravenclaw Öğrencisi",
		-- "Ravenclaw Hane Başkanı",
		-- "Ravenclaw Hane Başkan Yardımcısı"
	},
	
	-- Gryffindor öğrenci factionları
	gryffindor = {
		"Gryffindor Öğrencisi",
		"Gryffindor Hane Başkanı",
		-- "Gryffindor Hane Başkan Yardımcısı"
	},
	
	-- Slytherin öğrenci factionları
	slytherin = {
		"Slytherin Öğrencisi",
		-- "Slytherin Hane Başkanı",
		-- "Slytherin Hane Başkan Yardımcısı"
	},
	
	-- Hufflepuff öğrenci factionları
	hufflepuff = {
		"Hufflepuff Öğrencisi",
		-- "Hufflepuff Hane Başkanı",
		-- "Hufflepuff Hane Başkan Yardımcısı"
	},
}

-- Logolar
KrPoints.LogoHufflepuff = Material("rlib/interface/grunge/banners/hogwarts/em_hu.png")
KrPoints.LogoSlytherin = Material("rlib/interface/grunge/banners/hogwarts/em_sl.png")
KrPoints.LogoGryffindor = Material("rlib/interface/grunge/banners/hogwarts/em_gr.png")
KrPoints.LogoRavenclaw = Material("rlib/interface/grunge/banners/hogwarts/em_ra.png")

KrPoints.HouseList = {"Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"}
KrPoints.HouseKeys = {
	Gryffindor = "gryffindor",
	Hufflepuff = "hufflepuff",
	Ravenclaw = "ravenclaw",
	Slytherin = "slytherin",
}

if SERVER then
	-- Güvenlik Ayarları
	KrPoints.RateLimitSeconds = 3.0          -- Puan verme işlemleri arasındaki süre (spam'ı önler)
	KrPoints.RateLimitDecayTime = 300        -- Bu süre sonrasında eski hız sınırı kayıtlarını temizle (saniye)
	KrPoints.MaxPointsPerAction = 5          -- Tek seferde verilebilecek/alınabilecek maksimum puan
	KrPoints.MinPointsPerAction = 1          -- Tek seferde verilebilecek/alınabilecek minimum puan
	
	-- Profesör Yedek Güvenlik
	KrPoints.ProfessorFallbackRequireAdmin = true  -- fx_d sistemi bulunamazsa, superadmin gerektir (true) veya tüm adminlere izin ver (false)
	
	-- Gamemode Ayarları
	KrPoints.UsingGamemode = "helix"         -- "helix", "darkrp", "others"
	
	-- Veritabanı Ayarları
	KrPoints.TableName = "kr_points"
	
	-- ===== VERİTABANI TİPİ YAPILANDIRMASI =====
	-- Veritabanı sisteminizi seçin: "sqlite" veya "mysql"
	KrPoints.DatabaseType = "sqlite"         -- "sqlite" (varsayılan, kurulum gerekmez) veya "mysql" (MySQLOO 9 gerektirir)
	
	-- ===== MYSQL YAPILANDIRMASI =====
	-- Sadece DatabaseType = "mysql" ise kullanılır
	-- MySQLOO 9 gereklidir: https://github.com/FredyH/MySQLOO
	KrPoints.MySQLHost = "localhost"         -- MySQL sunucu adresi
	KrPoints.MySQLPort = 3306                -- MySQL sunucu portu
	KrPoints.MySQLDatabase = "gmod_krpuan"   -- Veritabanı adı
	KrPoints.MySQLUser = "root"              -- MySQL kullanıcı adı
	KrPoints.MySQLPassword = ""              -- MySQL şifresi
	
	-- Sıfırlama Komutu İzinli Rütbeler
	KrPoints.ResetAllowedRanks = {
		["superadmin"] = true
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
				mat:GetTexture("$basetexture")
			end
		end
		
		print("[KR-PUAN] [BAŞARILI] Materyaller başarıyla önceden yüklendi.")
	end)

	-- HUD Konum Ayarları (ekran genişliği/yüksekliği yüzdesi)
	KrPoints.HUD = KrPoints.HUD or {}
	KrPoints.HUD.WeaponBoxX = 0.385      -- Silah HUD kutusunun X konumu
	KrPoints.HUD.WeaponBoxY = 0.915      -- Silah HUD kutusunun Y konumu
	KrPoints.HUD.WeaponBoxWidth = 0.17   -- Silah HUD kutusunun genişliği
	KrPoints.HUD.WeaponBoxHeight = 0.07  -- Silah HUD kutusunun yüksekliği
	
	-- Silah HUD Metin Konumları (ekran genişliği/yüksekliği yüzdesi)
	KrPoints.HUD.WeaponText = {
		LabelX = 0.4,          -- "Puan Modu:" etiketinin X konumu
		LabelY = 0.92,         -- "Puan Modu:" etiketinin Y konumu
		HintRightClickX = 0.52,  -- "(Sağ Tık)" ipucunun X konumu
		HintRightClickY = 0.92,  -- "(Sağ Tık)" ipucunun Y konumu
		HintReloadX = 0.52,    -- "(R)" ipucunun X konumu
		HintReloadY = 0.95,    -- "(R)" ipucunun Y konumu
		StatusLabelX = 0.4,    -- "Verilecek/Alınacak Puan:" etiketinin X konumu
		StatusLabelY = 0.95,   -- "Verilecek/Alınacak Puan:" etiketinin Y konumu
		ModeX = 0.475,         -- "Ver"/"Al" mod göstergesinin X konumu
		ModeY = 0.92,          -- "Ver"/"Al" mod göstergesinin Y konumu
		PointsX = 0.493,       -- Puan değerinin X konumu
		PointsY = 0.95,        -- Puan değerinin Y konumu
	}
	
	KrPoints.HUD.NotificationBoxWidth = 0.3   -- Bildirim kutusunun genişliği
	KrPoints.HUD.NotificationBoxHeight = 0.1  -- Bildirim kutusunun yüksekliği
	KrPoints.HUD.NotificationBoxY = 0.01      -- Bildirim kutusunun Y konumu
	
	-- HUD Renkleri
	KrPoints.HUD.BackgroundColor = Color(0, 0, 0, 200)
	KrPoints.HUD.BackgroundColorDark = Color(0, 0, 0, 220)
	KrPoints.HUD.OrangeColor = Color(255, 128, 0)
	KrPoints.HUD.PinkColor = Color(255, 0, 128)
end
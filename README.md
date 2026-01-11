# KR-PUAN System

Hogwarts RP sunucuları için geliştirilmiş modern puan sistemi. Profesörler öğrencilere puan verebilir/alabilir ve ev puanları otomatik olarak güncellenir.

## 📋 Özellikler

- ✅ Tek tablo ile modern veritabanı yapısı
- ✅ **SQLite ve MySQL (MySQLOO 9) desteği**
- ✅ Otomatik fallback sistemi (MySQL bağlantı hatası durumunda SQLite)
- ✅ Async/sync query desteği
- ✅ Profesör/öğrenci puan sistemi
- ✅ 4 ev desteği (Gryffindor, Slytherin, Hufflepuff, Ravenclaw)
- ✅ Multi-gamemode desteği (Helix, DarkRP, Others)
- ✅ Rate limiting (spam koruması)
- ✅ Yetki kontrolü (fx_d entegrasyonu veya ULX fallback)
- ✅ Gerçek zamanlı GlobalInt senkronizasyonu
- ✅ Özel silah ile puan verme/alma

## 📁 Dosya Yapısı

```
fx_puan/
├── lua/
│   ├── autorun/
│   │   ├── sh_config.lua                    # Paylaşılan konfigürasyon
│   │   ├── sh_krpoints_helpers.lua          # Helper fonksiyonlar (shared)
│   │   ├── client/
│   │   │   └── cl_puansistemi.lua           # Client HUD ve UI
│   │   └── server/
│   │       ├── sv_krpoints_config.lua       # Server konfigürasyonu
│   │       ├── sv_krpoints_database.lua     # Veritabanı katmanı
│   │       ├── sv_krpoints_init.lua         # Başlatma ve network
│   │       ├── sv_krpoints_network.lua      # Network mesajları
│   │       ├── sv_krpoints_permissions.lua  # Yetki kontrolleri
│   │       ├── sv_krpoints_points.lua       # İş mantığı
│   │       └── sv_krpoints_ratelimit.lua    # Spam koruması
│   ├── entities/
│   │   └── kr_puan_tablo/                   # Puan tablosu entity
│   │       ├── cl_init.lua                  # Client render (3D2D)
│   │       ├── init.lua                     # Server logic
│   │       └── shared.lua                   # Shared config + NetworkVars
│   └── weapons/
│       └── weapon_puan/                     # Puan verme silahı
│           ├── cl_init.lua
│           ├── init.lua
│           └── shared.lua
└── README.md
```

## 🗄️ Veritabanı Desteği

KR-PUAN sistemi **SQLite** (varsayılan) ve **MySQL (MySQLOO 9)** veritabanlarını destekler.

### Veritabanı Seçimi

`lua/autorun/sh_config.lua` dosyasından veritabanı tipini seçebilirsiniz:

```lua
-- "sqlite" veya "mysql" seçeneklerinden birini seçin
KrPoints.DatabaseType = "sqlite"  -- Varsayılan (kurulum gerektirmez)
```

### MySQL Kurulumu

#### 1. MySQLOO 9 Modülü Kurulumu

MySQLOO 9 binary dosyalarını indirin: [MySQLOO GitHub](https://github.com/FredyH/MySQLOO)

- **Windows (64-bit):** `gmsv_mysqloo_win64.dll`
- **Linux (64-bit):** `gmsv_mysqloo_linux64.dll`

Binary dosyayı şu klasöre kopyalayın:
```
garrysmod/lua/bin/
```

#### 2. MySQL Bağlantı Ayarları

`lua/autorun/sh_config.lua` dosyasında MySQL bağlantı bilgilerinizi girin:

```lua
-- Veritabanı tipini MySQL olarak ayarlayın
KrPoints.DatabaseType = "mysql"

-- MySQL bağlantı bilgileri
KrPoints.MySQLHost = "localhost"        -- MySQL sunucu adresi
KrPoints.MySQLPort = 3306               -- MySQL port
KrPoints.MySQLDatabase = "gmod_krpuan"  -- Veritabanı adı
KrPoints.MySQLUser = "root"             -- MySQL kullanıcı adı
KrPoints.MySQLPassword = "your_password" -- MySQL şifresi
```

#### 3. MySQL Veritabanı Oluşturma

MySQL sunucunuzda veritabanını oluşturun:

```sql
CREATE DATABASE IF NOT EXISTS gmod_krpuan 
  DEFAULT CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;
```

> **Not:** Tablo otomatik olarak addon tarafından oluşturulur, manuel tablo oluşturmanıza gerek yoktur!

### Otomatik Fallback

Eğer MySQLOO 9 yüklü değilse veya MySQL bağlantısı başarısız olursa, sistem otomatik olarak SQLite'a geçer ve konsola bilgilendirme mesajı yazdırır:

```
[KR-PUAN] WARNING: MySQLOO module not found! Falling back to SQLite.
```

veya

```
[KR-PUAN] ERROR: MySQL connection failed: [error message]
[KR-PUAN] Falling back to SQLite...
```

## 🗄️ Veritabanı Şeması

Tek tablo ile tüm veriler yönetilir:

**SQLite:**
```sql
kr_points (
  entity_type TEXT,     -- 'house' veya 'student'
  entity_id TEXT,       -- ev adı veya öğrenci tanımlayıcı
  points INTEGER,       -- puan değeri
  house TEXT,           -- öğrencinin evi (sadece student için)
  updated_at INTEGER,   -- son güncelleme timestamp
  PRIMARY KEY (entity_type, entity_id)
)
```

**MySQL:**
```sql
kr_points (
  entity_type VARCHAR(32),   -- 'house' veya 'student'
  entity_id VARCHAR(128),    -- ev adı veya öğrenci tanımlayıcı
  points INT DEFAULT 0,      -- puan değeri
  house VARCHAR(32),         -- öğrencinin evi (sadece student için)
  updated_at INT,            -- son güncelleme timestamp
  PRIMARY KEY (entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Örnek Veriler:**

| entity_type | entity_id | points | house | updated_at |
|-------------|-----------|--------|-------|------------|
| house | gryffindor | 150 | NULL | 1736582400 |
| house | slytherin | 120 | NULL | 1736582400 |
| student | 12345 | 25 | gryffindor | 1736583000 |
| student | Harry Potter | 15 | slytherin | 1736583100 |

> **Not:** `entity_id` gamemode'a göre değişir:
> - **Helix:** Character ID (örn: `12345`)
> - **DarkRP/Others:** Player Nick (örn: `Harry Potter`)

## 🔧 API Kullanımı

> **Önemli:** MySQL kullanırken tüm database fonksiyonları async (callback tabanlı) çalışır. SQLite kullanırken ise sync çalışır.

### Ev Puanları

**SQLite (Sync):**
```lua
-- Tek evin puanını çek
local points = KrPoints.Database.GetHousePoints("gryffindor")

-- Eve puan ekle/çıkar (atomic)
local new_points = KrPoints.Database.AddHousePoints("gryffindor", 10)

-- Ev puanını direkt ayarla
KrPoints.Database.SetHousePoints("gryffindor", 200)

-- Tüm evlerin puanlarını çek (sıralı)
local houses = KrPoints.Database.GetAllHousePoints()
-- Dönen: { {house = "gryffindor", points = 150}, ... }
```

**MySQL (Async - Callback):**
```lua
-- Tek evin puanını çek
KrPoints.Database.GetHousePoints("gryffindor", function(points)
    print("Gryffindor points: " .. points)
end)

-- Eve puan ekle/çıkar
KrPoints.Database.AddHousePoints("gryffindor", 10, function(new_points)
    print("New points: " .. new_points)
end)

-- Ev puanını direkt ayarla
KrPoints.Database.SetHousePoints("gryffindor", 200, function(success)
    if success then
        print("Points updated!")
    end
end)

-- Tüm evlerin puanlarını çek
KrPoints.Database.GetAllHousePoints(function(houses)
    for _, house_data in ipairs(houses) do
        print(house_data.house .. ": " .. house_data.points)
    end
end)
```

### Öğrenci Puanları

**SQLite (Sync):**
```lua
-- Öğrencinin puanını çek
local points = KrPoints.Database.GetStudentPoints("Harry Potter")

-- Öğrencinin evini çek
local house = KrPoints.Database.GetStudentHouse("Harry Potter")

-- Öğrenci puanı ayarla
KrPoints.Database.SetStudentPoints("Harry Potter", 50, "gryffindor")

-- En yüksek puanlı öğrencileri çek (tüm evlerden)
local top_students = KrPoints.Database.GetTopStudents(10)

-- Belirli bir evden en yüksek puanlı öğrencileri çek
local top_gryffindor = KrPoints.Database.GetTopStudents(5, "gryffindor")
```

**MySQL (Async - Callback):**
```lua
-- Öğrencinin puanını çek
KrPoints.Database.GetStudentPoints("Harry Potter", function(points)
    print("Student points: " .. points)
end)

-- Öğrencinin evini çek
KrPoints.Database.GetStudentHouse("Harry Potter", function(house)
    print("Student house: " .. house)
end)

-- Öğrenci puanı ayarla
KrPoints.Database.SetStudentPoints("Harry Potter", 50, "gryffindor", function(success)
    if success then
        print("Student points updated!")
    end
end)

-- En yüksek puanlı öğrencileri çek
KrPoints.Database.GetTopStudents(10, nil, function(students)
    for _, student in ipairs(students) do
        print(student.id .. ": " .. student.points .. " (" .. student.house .. ")")
    end
end)

-- Belirli bir evden en yüksek puanlı öğrencileri çek
KrPoints.Database.GetTopStudents(5, "gryffindor", function(students)
    for _, student in ipairs(students) do
        print(student.id .. ": " .. student.points)
    end
end)
```

### Utility Fonksiyonlar

```lua
-- Hangi veritabanı kullanıldığını kontrol et
if KrPoints.Database.IsMySQL() then
    print("Using MySQL")
else
    print("Using SQLite")
end

-- Veritabanı hazır mı?
if KrPoints.Database.IsReady() then
    print("Database is ready")
end

-- Öğrencinin evini çek
local house = KrPoints.Database.GetStudentHouse("Harry Potter")

-- Öğrenci puanını ayarla
KrPoints.Database.SetStudentPoints("Harry Potter", 30, "gryffindor")

-- En iyi öğrencileri çek
local top10 = KrPoints.Database.GetTopStudents(10)
local top5_gryffindor = KrPoints.Database.GetTopStudents(5, "gryffindor")
```

### İş Mantığı (Profesör İşlemleri)

```lua
-- Profesör olarak öğrenciye puan ver
local success, result = KrPoints.Points.Give(professor_ply, student_ply, 5)
if success then
    print(result.student_name .. ": " .. result.new_student_points .. " puan")
    print(result.student_house .. ": " .. result.new_house_points .. " puan")
end

-- Profesör olarak öğrenciden puan al
local success, result = KrPoints.Points.Take(professor_ply, student_ply, 3)

-- Öğrencinin evini tespit et (faction bazlı)
local house = KrPoints.Points.GetStudentHouse(player)

-- Puan miktarını doğrula
local valid, amount_or_error = KrPoints.Points.ValidateAmount(5)
```

### Reset İşlemleri

```lua
-- Tüm puanları sıfırla
KrPoints.Database.ResetAll()

-- Sadece ev puanlarını sıfırla
KrPoints.Database.ResetHouses()

-- Sadece öğrenci puanlarını sıfırla
KrPoints.Database.ResetStudents()
```

### Shared Helper Fonksiyonları (Client & Server)

#### Ev Puanları Helpers

```lua
-- Tüm ev puanlarını al (GlobalInt üzerinden)
local points = KrPoints.GetAllHousePoints()
-- Dönen: {Gryffindor = 150, Hufflepuff = 120, Ravenclaw = 100, Slytherin = 80}

-- Lider evi bul
local house, score = KrPoints.GetLeadingHouse()
-- Dönen: "Gryffindor", 150

-- Tek evin puanını al
local points = KrPoints.GetHousePoints("Gryffindor")
-- Dönen: 150

-- Ev listesi ve key mapping
KrPoints.HouseList  -- {"Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"}
KrPoints.HouseKeys  -- {Gryffindor = "gryffindor", Hufflepuff = "hufflepuff", ...}
```

#### Oyuncu Tanımlayıcı Helpers

```lua
-- Oyuncu için benzersiz tanımlayıcı al (database için)
local identifier = KrPoints.GetStudentIdentifier(ply)
-- Helix: Character ID (örn: "12345")
-- DarkRP/Others: Player Nick (örn: "Harry Potter")

-- Oyuncu için görünen isim al (UI/log için)
local displayName = KrPoints.GetStudentDisplayName(ply)
-- Helix: Character Name (örn: "Harry Potter")
-- DarkRP/Others: Player Nick (örn: "Harry Potter")

-- Aktif gamemode'u öğren
print(KrPoints.Gamemode)  -- "helix", "darkrp", veya "others"
```

### Client-Side Erişim (GlobalInt - Low Level)

```lua
-- Direkt GlobalInt erişimi (alternatif yöntem)
local gryffindor = GetGlobalInt("puan_gryffindor", 0)
local slytherin = GetGlobalInt("puan_slytherin", 0)
local hufflepuff = GetGlobalInt("puan_hufflepuff", 0)
local ravenclaw = GetGlobalInt("puan_ravenclaw", 0)
```

## ⚙️ Konfigürasyon

`lua/autorun/sh_config.lua` dosyasından ayarları değiştirebilirsiniz:

### Gamemode Ayarları

```lua
-- Kullanılan gamemode'u belirtin
KrPoints.UsingGamemode = "helix"  -- "helix", "darkrp", veya "others"
```

| Gamemode | entity_id (Database) | Display Name (UI/Log) |
|----------|---------------------|----------------------|
| `"helix"` | Character ID | Character Name |
| `"darkrp"` | Player Nick | Player Nick |
| `"others"` | Player Nick | Player Nick |

> **Önemli:** Helix kullanıyorsanız, oyuncular karakter değiştirdiğinde puanlar karakter ID'sine bağlı olduğu için korunur.

### Güvenlik Ayarları

```lua
KrPoints.RateLimitSeconds = 3.0          -- İşlemler arası minimum süre
KrPoints.RateLimitDecayTime = 300        -- Rate limit temizleme süresi
KrPoints.MaxPointsPerAction = 5          -- Maksimum verilebilecek puan
KrPoints.MinPointsPerAction = 1          -- Minimum verilebilecek puan
```

### Yetki Ayarları

```lua
KrPoints.ProfessorFallbackRequireAdmin = true  -- fx_d yoksa superadmin gerekli mi?

KrPoints.ResetAllowedRanks = {
    ["superadmin"] = true,
    ["owner"] = true,
}
```

### Faction İsimleri

```lua
KrPoints.FactionRavenclaw = "Ravenclaw Öğrencisi"
KrPoints.FactionGryffindor = "Gryffindor Öğrencisi"
KrPoints.FactionSlytherin = "Slytherin Öğrencisi"
KrPoints.FactionHufflepuff = "Hufflepuff Öğrencisi"
```

## 🏆 Puan Tablosu Entity

`kr_puan_tablo` entity'si spawn edilebilir bir 3D puan tablosudur:

### Özellikler
- Tüm evlerin puanlarını bar grafik olarak gösterir
- Her evin en iyi öğrencisini listeler
- Lider evi vurgular
- 30 saniyede bir otomatik güncellenir
- Smooth animasyonlu puan barları

### Spawn
```lua
-- Console veya Lua ile spawn
local ent = ents.Create("kr_puan_tablo")
ent:SetPos(Vector(0, 0, 0))
ent:SetAngles(Angle(0, 0, 0))
ent:Spawn()
```

### Spawn Menüsü
**Entities → KR-PUAN → Puan Tablosu**

---

## 🎮 Silah Kullanımı

`weapon_puan` silahı profesörlere verilir:

| Tuş | İşlev |
|-----|-------|
| Sol Tık | Hedef öğrenciye puan ver/al |
| Sağ Tık | Mod değiştir (Ver ↔ Al) |
| R (Reload) | Puan miktarını değiştir (1-5) |

## 📝 Örnek Entegrasyonlar

### Özel Skor Tablosu

```lua
hook.Add("PlayerSay", "ShowTopStudents", function(ply, text)
    if text == "!top10" then
        local top = KrPoints.Database.GetTopStudents(10)
        for i, student in ipairs(top) do
            ply:ChatPrint(i .. ". " .. student.id .. " (" .. student.house .. "): " .. student.points)
        end
        return ""
    end
end)
```

### Otomatik Puan Sistemi

```lua
hook.Add("PlayerCompletedQuest", "QuestPoints", function(ply, quest)
    local house = KrPoints.Points.GetStudentHouse(ply)
    if house then
        -- Gamemode-agnostic identifier kullan
        local identifier = KrPoints.GetStudentIdentifier(ply)
        local current = KrPoints.Database.GetStudentPoints(identifier)
        KrPoints.Database.SetStudentPoints(identifier, current + 2, house)
        KrPoints.Database.AddHousePoints(house, 2)
        KrPoints.Points.SyncGlobalInts(house)
        ply:ChatPrint("Quest tamamlandı! +2 puan kazandınız.")
    end
end)
```

### Ev Sıralaması Gösterme

```lua
hook.Add("PlayerSay", "ShowHouseRanking", function(ply, text)
    if text == "!evler" then
        local houses = KrPoints.Database.GetAllHousePoints()
        ply:ChatPrint("=== Ev Sıralaması ===")
        for i, h in ipairs(houses) do
            ply:ChatPrint(i .. ". " .. h.house:gsub("^%l", string.upper) .. ": " .. h.points .. " puan")
        end
        return ""
    end
end)
```

## 🔒 Güvenlik

- ✅ SQL Injection koruması (`sql.QueryTyped` ile parameterized queries)
- ✅ Rate limiting (spam koruması)
- ✅ Whitelist bazlı ev validasyonu
- ✅ Puan miktarı sınırları (min/max)
- ✅ Yetki kontrolü (profesör/admin)
- ✅ Transaction desteği (rollback)

## 📦 Bağımlılıklar

### Gamemode Bağımlılıkları

| Gamemode | Bağımlılık | Açıklama |
|----------|-----------|----------|
| Helix | **Helix Framework** | `ix.faction`, `ply:GetCharacter()` için gerekli |
| DarkRP | Yok | Vanilla GMod fonksiyonları kullanılır |
| Others | Yok | Vanilla GMod fonksiyonları kullanılır |

### Opsiyonel Bağımlılıklar

- **fx_d** (opsiyonel - profesör tespiti için)
- **ULX/ULib** (opsiyonel - fallback yetki sistemi)

---

**Geliştirici:** Kronax  
**Versiyon:** 2.1 (Multi-Gamemode Support)

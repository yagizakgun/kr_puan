# KR-PUAN System

Hogwarts RP sunucuları için geliştirilmiş modern puan sistemi. Profesörler öğrencilere puan verebilir/alabilir ve ev puanları otomatik olarak güncellenir.

## 📋 Özellikler

- ✅ Tek tablo ile modern veritabanı yapısı
- ✅ Profesör/öğrenci puan sistemi
- ✅ 4 ev desteği (Gryffindor, Slytherin, Hufflepuff, Ravenclaw)
- ✅ Rate limiting (spam koruması)
- ✅ Yetki kontrolü (fx_d entegrasyonu veya ULX fallback)
- ✅ Gerçek zamanlı GlobalInt senkronizasyonu
- ✅ Özel silah ile puan verme/alma

## 📁 Dosya Yapısı

```
fx_puan/
├── lua/
│   ├── autorun/
│   │   ├── sh_config.lua                    # Paylaşılan konfigürasyon + Utility API
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

## 🗄️ Veritabanı Şeması

Tek tablo ile tüm veriler yönetilir:

```sql
kr_points (
  entity_type TEXT,     -- 'house' veya 'student'
  entity_id TEXT,       -- ev adı veya öğrenci adı
  points INTEGER,       -- puan değeri
  house TEXT,           -- öğrencinin evi (sadece student için)
  updated_at INTEGER,   -- son güncelleme timestamp
  PRIMARY KEY (entity_type, entity_id)
)
```

**Örnek Veriler:**

| entity_type | entity_id | points | house | updated_at |
|-------------|-----------|--------|-------|------------|
| house | gryffindor | 150 | NULL | 1736582400 |
| house | slytherin | 120 | NULL | 1736582400 |
| student | Harry Potter | 25 | gryffindor | 1736583000 |
| student | Draco Malfoy | 15 | slytherin | 1736583100 |

## 🔧 API Kullanımı

### Ev Puanları

```lua
-- Tüm evlerin puanlarını çek (sıralı)
local houses = KrPoints.Database.GetAllHousePoints()
-- Dönen: { {house = "gryffindor", points = 150}, ... }

-- Tek evin puanını çek
local points = KrPoints.Database.GetHousePoints("gryffindor")

-- Eve puan ekle/çıkar (atomic)
local new_points = KrPoints.Database.AddHousePoints("gryffindor", 10)
local new_points = KrPoints.Database.AddHousePoints("gryffindor", -5)

-- Ev puanını direkt ayarla
KrPoints.Database.SetHousePoints("gryffindor", 200)
```

### Öğrenci Puanları

```lua
-- Öğrencinin puanını çek
local points = KrPoints.Database.GetStudentPoints("Harry Potter")

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

### Shared Utility Fonksiyonları (Client & Server)

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
        local current = KrPoints.Database.GetStudentPoints(ply:Nick())
        KrPoints.Database.SetStudentPoints(ply:Nick(), current + 2, house)
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

- **Helix Framework** (ix.faction için)
- **fx_d** (opsiyonel - profesör tespiti için)
- **ULX/ULib** (opsiyonel - fallback yetki sistemi)

**Geliştirici:** Kronax
**Versiyon:** 2.0 (Modern Database)

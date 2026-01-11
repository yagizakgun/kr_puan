# KR-PUAN System

Hogwarts RP sunucuları için geliştirilmiş modern puan sistemi. Profesörler öğrencilere puan verebilir/alabilir ve ev puanları otomatik olarak güncellenir.

## 📋 Özellikler

- ✅ Tek tablo ile modern veritabanı yapısı
- ✅ **SQLite ve MySQL (MySQLOO 9) desteği**
- ✅ Otomatik fallback sistemi (MySQL bağlantı hatası durumunda SQLite)
- ✅ Async/sync query desteği
- ✅ Profesör/öğrenci puan sistemi
- ✅ Multi-gamemode desteği (Helix, DarkRP, Others)
- ✅ Rate limiting (spam koruması)
- ✅ Yetki kontrolü (fx_d entegrasyonu)
- ✅ Gerçek zamanlı GlobalInt senkronizasyonu
- ✅ Özel silah ile puan verme/alma
- ✅ **Anında leaderboard güncellemesi** (puan verildiğinde tabloların otomatik güncellenmesi)
- ✅ **Debounce optimizasyonu** (spam durumunda performans koruması)

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

## 🔧 API Kullanımı

> **Önemli:** MySQL kullanırken tüm database fonksiyonları async (callback tabanlı) çalışır. SQLite kullanırken ise sync çalışır.

### Ev Puanları

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

### Öğrenci Puanları

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

## 🏆 Puan Tablosu Entity

`kr_puan_tablo` entity'si spawn edilebilir bir 3D puan tablosudur:

### Özellikler
- Tüm evlerin puanlarını bar grafik olarak gösterir
- Her evin en iyi öğrencisini listeler
- Lider evi vurgular
- 30 saniyede bir otomatik güncellenir
- Smooth animasyonlu puan barları

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

**Geliştirici:** Kronax  
**Versiyon:** 2.1 (Multi-Gamemode Desteği)

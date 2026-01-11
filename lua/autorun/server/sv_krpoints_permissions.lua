-- ============================================
-- KR-PUAN SYSTEM: Permissions Module
-- ============================================
-- Sorumluluk: Professor/yetkilendirme kontrolü
-- Bağımlılıklar: sv_krpoints_config.lua
-- ============================================

KrPoints.Permissions = KrPoints.Permissions or {}

-- Shorthand references
local PROFESSOR_FALLBACK_REQUIRE_ADMIN = KrPoints.Security.PROFESSOR_FALLBACK_REQUIRE_ADMIN

-- ===== PROFESSOR CHECK IMPLEMENTATION =====
-- This will be initialized based on available systems
local is_professor_impl

-- Initialize is_professor based on available systems
if FX_ClassSystem then
	-- FX_ClassSystem implementation will be set up by that system
	-- This is a placeholder that will be replaced by the actual class system
	print("[KR-PUAN] FX_ClassSystem detected, professor check will use class system.")
	is_professor_impl = function(ply)
		-- This should be implemented by FX_ClassSystem
		-- For now, fallback to admin check
		if not IsValid(ply) then return false end
		return ply:IsSuperAdmin()
	end
elseif fx_d then
	-- Use fx_d (lesson system) for professor check
	is_professor_impl = function(ply)
		if not IsValid(ply) then return false end
		local ply_team = team.GetName(ply:Team())
		
		-- Check if team is in the professor list
		if table.HasValue(fx_d.acabilecekler, ply_team) then 
			return true 
		end
		
		-- Check for partial matches
		for i = 1, #fx_d.acabilecekler do
			if ply_team:find(fx_d.acabilecekler[i]) then 
				return true 
			end
		end
		
		return false
	end
	print("[KR-PUAN] Profesör kontrolü fx_d sistemi ile çalışıyor.")
else
	-- Fallback: No class system found
	print("[KR-PUAN] UYARI: Ders sistemi (fx_d) bulunamadı. Profesör kontrolü çalışmayacak!")
	
	if PROFESSOR_FALLBACK_REQUIRE_ADMIN then
		-- More restrictive fallback - require superadmin
		is_professor_impl = function(ply) 
			if not IsValid(ply) then return false end
			return ply:IsSuperAdmin()
		end
		print("[KR-PUAN] GÜVENLİK: Profesör kontrolü için SUPERADMIN yetkisi gerekiyor!")
	else
		-- Less restrictive - allow all admins
		is_professor_impl = function(ply) 
			return IsValid(ply) and ply:IsAdmin() 
		end
		print("[KR-PUAN] UYARI: Tüm adminler profesör olarak kabul ediliyor!")
	end
end

-- ===== PUBLIC API =====
function KrPoints.Permissions.IsProfessor(ply)
	return is_professor_impl(ply)
end

function KrPoints.Permissions.CanResetPoints(ply)
	if not IsValid(ply) then return false end
	
	local usergroup = ply:GetUserGroup()
	return KrPoints.Reset.ALLOWED_RANKS[usergroup] or false
end

print("[KR-PUAN] Permissions module loaded.")

KrPoints.Permissions = KrPoints.Permissions or {}

local PROFESSOR_FALLBACK_REQUIRE_ADMIN = KrPoints.Security.PROFESSOR_FALLBACK_REQUIRE_ADMIN

local is_professor_impl

if FX_ClassSystem then
	print("[KR-PUAN] FX_ClassSystem detected, professor check will use class system.")
	is_professor_impl = function(ply)
		if not IsValid(ply) then return false end
		return ply:IsSuperAdmin()
	end
elseif fx_d then
	is_professor_impl = function(ply)
		if not IsValid(ply) then return false end
		local ply_team = team.GetName(ply:Team())
		
		if table.HasValue(fx_d.acabilecekler, ply_team) then 
			return true 
		end
		
		for i = 1, #fx_d.acabilecekler do
			if ply_team:find(fx_d.acabilecekler[i]) then 
				return true 
			end
		end
		
		return false
	end
else
	print("[KR-PUAN] UYARI: Ders sistemi (fx_d) bulunamadı. Profesör kontrolü çalışmayacak!")
	
	if PROFESSOR_FALLBACK_REQUIRE_ADMIN then
		is_professor_impl = function(ply) 
			if not IsValid(ply) then return false end
			return ply:IsSuperAdmin()
		end
		print("[KR-PUAN] GÜVENLİK: Profesör kontrolü için SUPERADMIN yetkisi gerekiyor!")
	else
		is_professor_impl = function(ply) 
			return IsValid(ply) and ply:IsAdmin() 
		end
		print("[KR-PUAN] UYARI: Tüm adminler profesör olarak kabul ediliyor!")
	end
end

function KrPoints.Permissions.IsProfessor(ply)
	return is_professor_impl(ply)
end

function KrPoints.Permissions.CanResetPoints(ply)
	if not IsValid(ply) then return false end
	
	local usergroup = ply:GetUserGroup()
	return KrPoints.Reset.ALLOWED_RANKS[usergroup] or false
end

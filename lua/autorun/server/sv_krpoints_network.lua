-- ============================================
-- KR-PUAN SYSTEM: Network & Commands Module
-- ============================================
-- Sorumluluk: Network mesajları ve chat komutları
-- Bağımlılıklar: sv_krpoints_permissions.lua, sv_krpoints_ratelimit.lua, sv_krpoints_points.lua
-- ============================================

KrPoints.Network = KrPoints.Network or {}

-- Shorthand references
local VALID_HOUSES = KrPoints.Houses.VALID_HOUSES
local VALID_HOUSES_LOOKUP = KrPoints.Houses.VALID_HOUSES_LOOKUP

-- ===== NETWORK STRING REGISTRATION =====
function KrPoints.Network.RegisterHandlers()
	-- Register network strings
	util.AddNetworkString("KrPoints.GivePoints")
	util.AddNetworkString("KrPoints.SyncPoints")
	util.AddNetworkString("KrPoints.Notify")
	
	-- Register network receivers
	net.Receive("KrPoints.GivePoints", KrPoints.Network.HandleGivePoints)
	
	print("[KR-PUAN] Network handlers registered.")
end

-- ===== NOTIFICATION HELPERS =====
local function safe_notify_server(msg, color)
	if notify_server then
		notify_server(msg, color)
	else
		print("[KR-PUAN] " .. msg)
	end
end

function KrPoints.Network.BroadcastNotification(giver_name, target_house, point_amount)
	-- Limit string lengths to prevent network packet bloat
	net.Start("KrPoints.Notify")
	net.WriteString(string.sub(giver_name, 1, 32))
	net.WriteString(target_house)
	net.WriteInt(point_amount, 16)
	net.Broadcast()
end

function KrPoints.Network.SyncToClient(ply)
	net.Start("KrPoints.SyncPoints")
	for _, house in ipairs(VALID_HOUSES) do
		net.WriteString(house .. ":" .. KrPoints.Points.GetHousePoints(house))
	end
	net.Send(ply)
end

function KrPoints.Network.BroadcastPointUpdate(mode, giver_name, student_house, winner_name, points_amount)
	-- Limit string lengths to prevent network packet bloat
	net.Start("KrPoints.SyncPoints")
	net.WriteString(mode)
	net.WriteString(string.sub(giver_name, 1, 32))
	net.WriteString(student_house)
	net.WriteString(string.sub(winner_name, 1, 32))
	net.WriteInt(points_amount, 16)
	net.Broadcast()
end

-- ===== NETWORK HANDLER: Give Points =====
function KrPoints.Network.HandleGivePoints(len, ply)
	if not IsValid(ply) then return end
	
	-- SECURITY: Validate professor status
	if not KrPoints.Permissions.IsProfessor(ply) then
		print("[KR-PUAN] GÜVENLİK: Yetkisiz puan verme girişimi: " .. ply:Nick() .. " [" .. ply:SteamID() .. "]")
		return
	end
	
	-- SECURITY: Rate limiting
	if not KrPoints.RateLimit.Check(ply) then
		print("[KR-PUAN] GÜVENLİK: Hız limiti aşıldı: " .. ply:Nick())
		return
	end

	-- Read network data
	local point_mode = net.ReadString()
	local points_to_give = net.ReadInt(16)
	local winner_entity = net.ReadEntity()

	-- SECURITY: Validate target entity
	if not IsValid(winner_entity) or not winner_entity:IsPlayer() then
		print("[KR-PUAN] GÜVENLİK: Geçersiz hedef entity: " .. ply:Nick())
		return
	end
	
	-- SECURITY: Prevent self-giving
	if winner_entity == ply then
		print("[KR-PUAN] GÜVENLİK: Kendine puan verme girişimi: " .. ply:Nick())
		ply:ChatPrint("[PUAN] Kendine puan veremezsin!")
		return
	end

	-- SECURITY: Validate point amount
	local valid, validated_amount = KrPoints.Points.ValidateAmount(points_to_give)
	if not valid then
		print("[KR-PUAN] GÜVENLİK: Geçersiz puan değeri: " .. tostring(points_to_give) .. " gönderen: " .. ply:Nick())
		return
	end
	points_to_give = validated_amount

	-- SECURITY: Validate mode
	if point_mode ~= "ver" and point_mode ~= "al" then
		print("[KR-PUAN] GÜVENLİK: Geçersiz puan modu: " .. tostring(point_mode) .. " gönderen: " .. ply:Nick())
		return
	end

	-- Execute the point operation (with async callback support)
	local function HandleResult(success, result)
		if not success then
			print("[KR-PUAN] HATA: " .. tostring(result))
			if IsValid(ply) then
				ply:ChatPrint("[PUAN] HATA: " .. tostring(result))
			end
			return
		end

		-- Broadcast the update to all clients
		KrPoints.Network.BroadcastPointUpdate(
			point_mode,
			ply:Nick(),
			result.student_house,
			result.student_name,
			points_to_give
		)
	end
	
	if point_mode == "ver" then
		if KrPoints.Database.IsMySQL() then
			KrPoints.Points.Give(ply, winner_entity, points_to_give, HandleResult)
		else
			local success, result = KrPoints.Points.Give(ply, winner_entity, points_to_give)
			HandleResult(success, result)
		end
	elseif point_mode == "al" then
		if KrPoints.Database.IsMySQL() then
			KrPoints.Points.Take(ply, winner_entity, points_to_give, HandleResult)
		else
			local success, result = KrPoints.Points.Take(ply, winner_entity, points_to_give)
			HandleResult(success, result)
		end
	end
end

-- ===== CHAT COMMAND: !puan =====
local function handle_points_command(ply, text)
	text = text:lower()

	if text:sub(1, 5) == "!puan" or text:sub(1, 5) == "/puan" then
		if KrPoints.Permissions.IsProfessor(ply) then
			local args = string.Explode(" ", text)

			if #args ~= 3 then
				ply:ChatPrint("Kullanım örneği: !puan gryffindor 10")
				return ""
			end

			local target_house = args[2]
			local point_amount = tonumber(args[3])

			if not VALID_HOUSES_LOOKUP[target_house] then
				ply:ChatPrint("Ev bulunamadı. Evler: gryffindor, hufflepuff, ravenclaw, slytherin")
				return ""
			end

			if not point_amount then
				ply:ChatPrint("Kullanım örneği: !puan gryffindor 10")
				return ""
			end

			-- Add points with callback support
			KrPoints.Points.AddToHouse(target_house, point_amount, function(new_points)
				-- Broadcast notification
				KrPoints.Network.BroadcastNotification(ply:Nick(), target_house, point_amount)

				safe_notify_server(
					ply:Nick() .. " [" .. ply:SteamID() .. "] isimli profesör " ..
					string.upper(target_house) .. " evine " .. point_amount .. " puan verdi. " ..
					string.upper(target_house) .. " evinin yeni puanı " .. new_points .. " oldu.",
					point_amount > 0 and "green" or "red"
				)
			end)

			return ""
		else
			-- Only send sync to requesting player
			KrPoints.Network.SyncToClient(ply)
			return ""
		end
	end
end
hook.Add("PlayerSay", "KrPoints.Command", handle_points_command)

-- ===== CHAT COMMAND: !tablosifirla =====
local function handle_reset_command(ply, text)
	text = text:lower()
	if text:sub(1, 13) == "!tablosifirla" then
		if KrPoints.Permissions.CanResetPoints(ply) then
			KrPoints.Database.ResetAll(function(success)
				if success then
					KrPoints.Points.SyncGlobalInts() -- Update all globals after reset
					if IsValid(ply) then
						ply:ChatPrint("[PUAN] Başarıyla tüm tablo puanlarını sıfırladınız.")
					end
				end
			end)
		else
			ply:ChatPrint("[PUAN] Bu komutu kullanmak için yetkiniz yok.")
		end
	end
end
hook.Add("PlayerSay", "KrPoints.ResetCommand", handle_reset_command)

print("[KR-PUAN] Network module loaded.")

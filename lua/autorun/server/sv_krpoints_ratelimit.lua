KrPoints.RateLimit = KrPoints.RateLimit or {}

local RATE_LIMIT_SECONDS = KrPoints.Security.RATE_LIMIT_SECONDS
local RATE_LIMIT_DECAY_TIME = KrPoints.Security.RATE_LIMIT_DECAY_TIME

local player_cooldowns = {}
local player_last_activity = {}
local player_cooldown_keys = {}

function KrPoints.RateLimit.Check(ply)
	if not IsValid(ply) then return false end
	
	local steamid = ply:SteamID()
	local char = ply.GetCharacter and ply:GetCharacter()
	local char_id = char and char:GetID() or "nochar"
	
	local rate_key = steamid .. "_" .. tostring(char_id)
	
	local last_request = player_cooldowns[rate_key] or 0
	if CurTime() - last_request < RATE_LIMIT_SECONDS then 
		return false 
	end
	
	player_cooldowns[rate_key] = CurTime()
	player_last_activity[steamid] = CurTime()
	
	player_cooldown_keys[steamid] = player_cooldown_keys[steamid] or {}
	table.insert(player_cooldown_keys[steamid], rate_key)
	
	return true
end

function KrPoints.RateLimit.Cleanup()
	timer.Remove("KrPoints.RateLimitDecay")
	print("[KR-PUAN] Rate limit cleanup completed.")
end

local function DecayOldEntries()
	local current_time = CurTime()
	local removed_count = 0
	
	for steamid, last_time in pairs(player_last_activity) do
		if current_time - last_time > RATE_LIMIT_DECAY_TIME then
			local keys_to_remove = player_cooldown_keys[steamid]
			if keys_to_remove then
				for _, key in ipairs(keys_to_remove) do
					player_cooldowns[key] = nil
					removed_count = removed_count + 1
				end
				player_cooldown_keys[steamid] = nil
			end
			player_last_activity[steamid] = nil
		end
	end
	
	if removed_count > 0 then
		print("[KR-PUAN] Rate limit decay: Removed " .. removed_count .. " old entries.")
	end
end

hook.Add("PlayerDisconnected", "KrPoints.RateLimitCleanup", function(ply)
	if IsValid(ply) then 
		player_last_activity[ply:SteamID()] = CurTime()
	end
end)

timer.Create("KrPoints.RateLimitDecay", 60, 0, DecayOldEntries)


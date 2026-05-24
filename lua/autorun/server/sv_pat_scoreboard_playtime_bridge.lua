if CLIENT then return end

ZCITY_PATSB = ZCITY_PATSB or {}

function ZCITY_PATSB.GetPlaytime(ply)
	if not IsValid(ply) then return 0 end

	if ply.PATSB_PlaytimeSeconds ~= nil then
		return math.max(0, math.floor(tonumber(ply.PATSB_PlaytimeSeconds) or 0))
	end

	return math.max(0, math.floor(tonumber(ply:GetNWInt("pat_scoreboard_playtime", 0)) or 0))
end

function ZCITY_PATSB.AddPlaytime(ply, seconds)
	if ZCITY_DB and ZCITY_DB.AddPlaytimeSeconds then
		ZCITY_DB.AddPlaytimeSeconds(ply, seconds)
	end
end

hook.Add("ZCITY_DatabaseReady", "ZCITY_PATSB_ExposeAPI", function()
	_G.PATSB_DB_Load = function(ply)
		if ZCITY_DB and ZCITY_DB.ApplyPlaytimeToPlayer then
			ZCITY_DB.ApplyPlaytimeToPlayer(ply)
		end
	end

	_G.PATSB_DB_Add = function(ply, seconds)
		ZCITY_PATSB.AddPlaytime(ply, seconds)
	end
end)

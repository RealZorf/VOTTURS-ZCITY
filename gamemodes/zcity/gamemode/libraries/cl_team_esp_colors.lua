zb = zb or {}
zb.TeamESP = zb.TeamESP or {}

local TeamESP = zb.TeamESP

TeamESP.DefaultColor = Color(35, 225, 110)

TeamESP.ColorsByMode = {
	gwars = {
		[0] = Color(180, 0, 0),
		[1] = Color(0, 180, 0),
		[2] = Color(0, 0, 122),
	},
	tdm = {
		[0] = Color(190, 0, 0),
		[1] = Color(0, 120, 190),
	},
	tdm_cstrike = {
		[0] = Color(190, 0, 0),
		[1] = Color(0, 120, 190),
	},
	riot = {
		[0] = Color(190, 0, 0),
		[1] = Color(0, 120, 190),
	},
	criresp = {
		[0] = Color(68, 10, 255),
		[1] = Color(228, 49, 49),
	},
	hl2dm = {
		[0] = Color(230, 100, 5),
		[1] = Color(0, 200, 220),
	},
	hl3 = {
		[0] = Color(230, 100, 5),
		[1] = Color(0, 200, 220),
		[2] = Color(110, 220, 120),
	},
	activeshooter = {
		[0] = Color(68, 10, 255),
		[1] = Color(0, 190, 190),
		[2] = Color(255, 0, 0),
	},
	tdm_ww2 = {
		[0] = Color(180, 150, 110),
		[1] = Color(110, 170, 120),
	},
}

function TeamESP.GetCurrentRound()
	if not CurrentRound then return nil end
	return CurrentRound()
end

function TeamESP.GetColorTable()
	local round = TeamESP.GetCurrentRound()
	if not round then return nil end

	if round.TeamESPColors then
		return round.TeamESPColors
	end

	return TeamESP.ColorsByMode[round.name]
end

function TeamESP.IsTeamRound()
	return TeamESP.GetColorTable() ~= nil
end

function TeamESP.ColorCopy(col)
	return Color(col.r, col.g, col.b, 255)
end

function TeamESP.GetTeamColor(ply)
	if not IsValid(ply) then return nil end

	local tm = ply:Team()
	local modeColors = TeamESP.GetColorTable()

	if modeColors and modeColors[tm] then
		return TeamESP.ColorCopy(modeColors[tm])
	end

	if zb and zb.Points then
		if tm == 0 and zb.Points.HMCD_TDM_T and zb.Points.HMCD_TDM_T.Color then
			return TeamESP.ColorCopy(zb.Points.HMCD_TDM_T.Color)
		end

		if tm == 1 and zb.Points.HMCD_TDM_CT and zb.Points.HMCD_TDM_CT.Color then
			return TeamESP.ColorCopy(zb.Points.HMCD_TDM_CT.Color)
		end
	end

	local teamColor = team.GetColor(tm)

	if teamColor and (teamColor.r ~= 255 or teamColor.g ~= 255 or teamColor.b ~= 255) then
		return TeamESP.ColorCopy(teamColor)
	end

	return nil
end

local function PlayerIdToHue(ply)
	local id = ply:SteamID64()
	if not id or id == "" or id == "0" then
		id = string.format("ent:%d:uid:%d", ply:EntIndex(), ply:UserID())
	end

	local crc = util.CRC(id)
	return (tonumber(crc, 16) or tonumber(crc) or (ply:EntIndex() * 41 + ply:UserID() * 17)) % 360
end

function TeamESP.GetDistinctPlayerColor(ply, fallback)
	if not IsValid(ply) then return fallback or TeamESP.DefaultColor end

	return HSVToColor(PlayerIdToHue(ply), 0.8, 0.95)
end

function TeamESP.GetPlayerColor(ply, fallback)
	if not IsValid(ply) then return fallback or TeamESP.DefaultColor end

	if TeamESP.IsTeamRound() then
		local teamCol = TeamESP.GetTeamColor(ply)
		if teamCol then return teamCol end
	end

	return HSVToColor(PlayerIdToHue(ply), 0.8, 0.95)
end

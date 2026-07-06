zb = zb or {}
zb.TeamESP = zb.TeamESP or {}

local TeamESP = zb.TeamESP

TeamESP.DefaultColor = Color(35, 225, 110)

-- Spectator ESP: per-player colors on non-team modes (hmcd, fear, dm, etc.)
TeamESP.SpectatorPaletteModes = {
	hmcd = true,
	fear = true,
	dm = true,
	event = true,
	sandbox = true,
	defense = true,
	pathowogen = true,
	scugarena = true,
	superfighters = true,
	lastmanstanding = true,
	assassinsgreed = true,
}

TeamESP.PlayerPalette = {
	Color(70, 130, 180),
	Color(255, 69, 0),
	Color(0, 191, 255),
	Color(123, 104, 238),
	Color(255, 20, 147),
	Color(46, 139, 87),
	Color(255, 165, 0),
	Color(154, 205, 50),
	Color(186, 85, 211),
	Color(30, 144, 255),
	Color(255, 127, 80),
	Color(0, 128, 128),
	Color(219, 112, 147),
	Color(124, 252, 0),
	Color(178, 34, 34),
	Color(65, 105, 225),
	Color(255, 193, 37),
	Color(85, 107, 47),
	Color(0, 250, 154),
	Color(210, 105, 30),
	Color(100, 149, 237),
	Color(32, 178, 170),
	Color(240, 230, 140),
	Color(139, 69, 19),
	Color(64, 224, 208),
	Color(255, 105, 180),
	Color(107, 142, 35),
	Color(72, 209, 204),
	Color(220, 20, 60),
	Color(244, 164, 96),
	Color(0, 206, 209),
	Color(189, 183, 107),
	Color(138, 43, 226),
	Color(255, 140, 0),
	Color(60, 179, 113),
	Color(255, 215, 0),
	Color(50, 205, 50),
	Color(218, 165, 32),
	Color(255, 160, 122),
}

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
	cstrike = {
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
	overstimulated = {
		[0] = Color(68, 10, 255),
		[1] = Color(255, 255, 255),
		[2] = Color(228, 49, 49),
	},
	ww2 = {
		[0] = Color(180, 150, 110),
		[1] = Color(110, 170, 120),
	},
}

function TeamESP.GetCurrentRound()
	if not CurrentRound then return nil end
	return CurrentRound()
end

local function ColorTableHasEntries(colors)
	if not colors then return false end

	for _ in pairs(colors) do
		return true
	end

	return false
end

function TeamESP.GetColorTable()
	local round = TeamESP.GetCurrentRound()
	if not round or not round.name then return nil end

	if round.TeamESPColors and ColorTableHasEntries(round.TeamESPColors) then
		return round.TeamESPColors
	end

	local modeColors = TeamESP.ColorsByMode[round.name]
	if not ColorTableHasEntries(modeColors) then return nil end

	return modeColors
end

function TeamESP.IsTeamRound()
	return ColorTableHasEntries(TeamESP.GetColorTable())
end

function TeamESP.UsesSpectatorPlayerPalette()
	local round = TeamESP.GetCurrentRound()
	return round and round.name and TeamESP.SpectatorPaletteModes[round.name] == true
end

function TeamESP.ColorCopy(col)
	return Color(col.r, col.g, col.b, 255)
end

function TeamESP.GetTeamColor(ply)
	if not IsValid(ply) or not TeamESP.IsTeamRound() then return nil end

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

local paletteSize = #TeamESP.PlayerPalette
local paletteByUserId = {}
local paletteNextSlot = 0

function TeamESP.ResetPaletteAssignments()
	paletteByUserId = {}
	paletteNextSlot = 0
end

local function AssignPaletteColor(ply)
	local userId = ply:UserID()
	local existing = paletteByUserId[userId]
	if existing then return existing end

	local paletteIdx = (paletteNextSlot % paletteSize) + 1
	paletteNextSlot = paletteNextSlot + 1

	local col = TeamESP.ColorCopy(TeamESP.PlayerPalette[paletteIdx])
	paletteByUserId[userId] = col

	return col
end

function TeamESP.GetPalettePlayerColor(ply, fallback)
	if not IsValid(ply) then return fallback or TeamESP.DefaultColor end
	if paletteSize < 1 then return fallback or TeamESP.DefaultColor end

	return AssignPaletteColor(ply)
end

hook.Add("InitPostEntity", "ZB_TeamESP_ResetPalette", function()
	TeamESP.ResetPaletteAssignments()
end)

hook.Add("PlayerDisconnected", "ZB_TeamESP_PaletteCleanup", function(ply)
	if not IsValid(ply) then return end
	paletteByUserId[ply:UserID()] = nil
end)

local paletteLastRoundStart = 0
hook.Add("Think", "ZB_TeamESP_PaletteRoundReset", function()
	if not zb or not zb.ROUND_START or zb.ROUND_START == paletteLastRoundStart then return end

	paletteLastRoundStart = zb.ROUND_START
	TeamESP.ResetPaletteAssignments()
end)

function TeamESP.GetDistinctPlayerColor(ply, fallback)
	return TeamESP.GetPalettePlayerColor(ply, fallback)
end

function TeamESP.GetPlayerColor(ply, fallback)
	if not IsValid(ply) then return fallback or TeamESP.DefaultColor end

	if TeamESP.IsTeamRound() then
		local teamCol = TeamESP.GetTeamColor(ply)
		if teamCol then return teamCol end
	end

	return TeamESP.GetDistinctPlayerColor(ply, fallback)
end

function TeamESP.GetSpectatorColor(ply, fallback)
	if not IsValid(ply) then return fallback or TeamESP.DefaultColor end

	if TeamESP.IsTeamRound() then
		local teamCol = TeamESP.GetTeamColor(ply)
		if teamCol then return teamCol end
	end

	if TeamESP.UsesSpectatorPlayerPalette() then
		return TeamESP.GetPalettePlayerColor(ply, fallback)
	end

	return fallback or TeamESP.DefaultColor
end

local MODE = MODE
MODE.name = "hmcd"

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--//

MODE.TypeSounds = {
	["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gunfreezone"] = "snd_jack_hmcd_panic.mp3" ,
	["suicidelunatic"] = "zbattle/jihadmode.mp3",
	["wildwest"] = "snd_jack_hmcd_wildwest.mp3",
	["supermario"] = "snd_jack_hmcd_psycho.mp3"
}
local fade = 0
net.Receive("HMCD_RoundStart",function()
	for i, ply in player.Iterator() do
		ply.isTraitor = false
		ply.isGunner = false
	end

	--\\
	lply.isTraitor = net.ReadBool()
	lply.isGunner = net.ReadBool()
	MODE.Type = net.ReadString()
	local screen_time_is_default = net.ReadBool()
	lply.SubRole = net.ReadString()
	lply.MainTraitor = net.ReadBool()
	MODE.TraitorWord = net.ReadString()
	MODE.TraitorWordSecond = net.ReadString()
	MODE.TraitorExpectedAmt = net.ReadUInt(MODE.TraitorExpectedAmtBits)
	StartTime = CurTime()
	MODE.HMCDIntroTipSalt = tostring(math.random(1, 2147483647)) .. ":" .. tostring(StartTime)
	MODE.TraitorsLocal = {}

	if(lply.isTraitor and screen_time_is_default)then
		if(MODE.TraitorExpectedAmt == 1)then
			chat.AddText("You are alone on your mission.")
		else
			if(MODE.TraitorExpectedAmt == 2)then
				chat.AddText("You have 1 accomplice")
			else
				chat.AddText("There are(is) " .. MODE.TraitorExpectedAmt - 1 .. " traitor(s) besides you")
			end

			chat.AddText("Traitor secret words are: \"" .. MODE.TraitorWord .. "\" and \"" .. MODE.TraitorWordSecond .. "\".")
		end

		if(lply.MainTraitor)then
			if(MODE.TraitorExpectedAmt > 1)then
				chat.AddText("Traitor names (only you, as a main traitor can see them):")
			end

			for key = 1, MODE.TraitorExpectedAmt do
				local traitor_info = {net.ReadColor(false), net.ReadString()}

				if(MODE.TraitorExpectedAmt > 1)then
					MODE.TraitorsLocal[#MODE.TraitorsLocal + 1] = traitor_info

					chat.AddText(traitor_info[1], "\t" .. traitor_info[2])
				end
			end
		end
	end

	lply.Profession = net.ReadString()
	--//

	if(MODE.RoleChooseRoundTypes[MODE.Type] and !screen_time_is_default)then
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.RoleChooseRoundStartTime
	else
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.DefaultRoundStartTime
	end

	MODE.RoleEndedChosingState = screen_time_is_default

	if(screen_time_is_default)then
		if istable(MODE.TypeSounds[MODE.Type]) then
			surface.PlaySound(table.Random(MODE.TypeSounds[MODE.Type]))
		else
			surface.PlaySound(MODE.TypeSounds[MODE.Type])
		end
	end

	if lply.isTraitor and lply.MainTraitor and screen_time_is_default then
		timer.Simple(0.1, function()
			if not IsValid(lply) or not lply.isTraitor or not lply.MainTraitor then return end

			net.Start("HMCD_RequestTraitorStatuses")
			net.SendToServer()
		end)
	end

	fade = 0
end)

MODE.TypeNames = {
	["standard"] = "Standard",
	["soe"] = "State of Emergency",
	["gunfreezone"] = "Gun Free Zone",
	["suicidelunatic"] = "Suicide Lunatic",
	["wildwest"] = "Wild west",
	["supermario"] = "Super Mario"
}

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_HomicideSmall", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMedium", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMediumLarge", {
	font = font(),
	size = ScreenScale(25),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideLarge", {
	font = font(),
	size = ScreenScale(30),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideHumongous", {
	font = font(),
	size = 255,
	weight = 400,
	antialias = true
})

local function hmcd_intro_scale(num)
	local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.85, 1.25)
	return math.Round(num * scale)
end

surface.CreateFont("ZB_HomicideCellHeader", {
	font = font(),
	size = hmcd_intro_scale(16),
	weight = 800,
	antialias = true
})

surface.CreateFont("ZB_HomicideCellName", {
	font = font(),
	size = hmcd_intro_scale(24),
	weight = 800,
	antialias = true
})

surface.CreateFont("ZB_HomicideCellRole", {
	font = font(),
	size = hmcd_intro_scale(15),
	weight = 700,
	antialias = true
})

surface.CreateFont("ZB_HomicideCellTip", {
	font = font(),
	size = hmcd_intro_scale(14),
	weight = 600,
	antialias = true
})

local function draw_hmcd_intro_cut_box(x, y, w, h, cut, fill, outline)
	surface.SetDrawColor(fill)
	draw.NoTexture()
	surface.DrawPoly({
		{x = x + cut, y = y},
		{x = x + w - cut, y = y},
		{x = x + w, y = y + cut},
		{x = x + w, y = y + h},
		{x = x, y = y + h},
		{x = x, y = y + cut}
	})

	surface.SetDrawColor(outline)
	surface.DrawLine(x + cut, y, x + w - cut, y)
	surface.DrawLine(x + w - cut, y, x + w, y + cut)
	surface.DrawLine(x + w, y + cut, x + w, y + h)
	surface.DrawLine(x + w, y + h, x, y + h)
	surface.DrawLine(x, y + h, x, y + cut)
	surface.DrawLine(x, y + cut, x + cut, y)
end

function get_hmcd_subrole_name(role)
	local info = MODE.SubRoles and MODE.SubRoles[role or ""]
	return info and info.Name or "Traitor"
end

local hmcd_traitor_role_tips = {
	traitor_default = {
		"they can force movement with pistol, IEDs, poison and smoke.",
		"they can plant IEDs or poison while you keep eyes elsewhere.",
		"their suppressed pistol and grenades are best after panic starts.",
		"they can open with smoke, poison or shuriken before you commit.",
		"their fiberwire and poison kit are strongest on isolated targets.",
		"they can fake a normal gunfight while you strip pockets quietly.",
		"their IEDs punish groups; pull victims toward planted routes.",
		"they can smoke a room while you steal from confused players.",
		"their poison works best when you identify who carries medicine.",
		"they have enough tools to bait blame while you stay clean."
	},
	traitor_infiltrator = {
		"give them ragdolled targets so they can steal an identity.",
		"cover exits while they smoke, disguise, then walk back in.",
		"they need bodies and quiet lanes for disguise plays.",
		"let them neck-snap loners while you watch the crowd.",
		"their disguise works best after you create confusion elsewhere.",
		"their smoke buys time to change clothes and leave clean.",
		"they can turn one body into a fake ally inside the group.",
		"their knife and fiberwire reward silent callouts, not chaos.",
		"give them a ragdolled victim before witnesses gather.",
		"they can re-enter crowds as the victim if you cover the body."
	},
	traitor_thief = {
		"let them strip radios, meds and guns before fights start.",
		"their starter gear stays hidden; let them carry suspicious tools.",
		"give them time to search standing players before you go loud.",
		"they can expose pockets instantly; call high-value targets.",
		"after they steal escape tools, close the trap around the victim.",
		"they can quietly remove weapons before your first obvious kill.",
		"their pocket checks tell you who is worth isolating first.",
		"let them take meds first so wounded targets cannot recover.",
		"they can steal radios before you split the group.",
		"their hidden loadout lets them look harmless while carrying gear."
	},
	traitor_assasin = {
		"call gunmen; they can disarm first and turn the weapon on them.",
		"let them open on armed targets while you cover the escape.",
		"they disarm faster from behind and against ragdolled victims.",
		"their stamina and recoil control make stolen guns dangerous.",
		"feed them gun threats, then push when the victim is empty-handed.",
		"they can convert police weapons into traitor pressure.",
		"their walkie lets them call stolen guns before using them.",
		"ragdoll a gunman first so their front disarm is faster.",
		"they should take the weapon; you handle the witness.",
		"their stamina lets them chase armed runners after a failed shot."
	},
	traitor_chemist = {
		"push victims through their sleep gas and poison zones.",
		"hold exits while they contaminate food, rooms or choke points.",
		"they resist chemicals; let them work inside their own gas.",
		"call stacked crowds so their canisters hit multiple targets.",
		"force runners back toward their poison instead of chasing alone.",
		"they can poison consumables; point out trusted food spots.",
		"sleep canisters are strongest when you guard the door.",
		"their chemical readout helps confirm if an area is still lethal.",
		"let them weaken groups before you reveal weapons.",
		"drive wounded targets into gas so they cannot stabilize."
	},
	traitor_shadow = {
		"draw eyes away while they camouflage near walls.",
		"send victims past dark corners for tranquilizer and cuff plays.",
		"their concealed kit stays quiet; let them handle witnesses.",
		"create noise so they can stand still and vanish before striking.",
		"they can tranq, cuff and poison; give them isolated angles.",
		"their handcuffs turn a risky target into a quiet delivery.",
		"let them hold a wall while you bait someone through it.",
		"their tranquilizer is precious; call only high-value targets.",
		"concealed weapons keep suspicion low after a search.",
		"their camouflage needs stillness, so keep pressure away from them."
	},
	traitor_maniac = {
		"block exits before they charge with axe, molotov and grenade.",
		"use their high stamina to start panic while you catch runners.",
		"let their fire axe force close fights; cover guns at range.",
		"their health and stamina buy time for your slower setup.",
		"when they go loud, use the chaos to finish separated targets.",
		"their poisoned axe can make one hit turn into a collapse.",
		"molotov pressure splits crowds; wait where they scatter.",
		"their loud push is cover for your quiet objective.",
		"let them tank attention while you remove weapons from the edge.",
		"grenade panic makes people drop formation; punish the split."
	},
	traitor_terrorist = {
		"keep distance while they use bomb vest, pipebombs and fire.",
		"mark packed groups, then catch survivors after the blast.",
		"their explosives move crowds; wait at the exits they create.",
		"do not stack on them when the vest or IED plan is active.",
		"let their molotovs split rooms before you pick off stragglers.",
		"their matches and molotovs can deny rescue routes.",
		"use their pipebomb timer as your signal to reposition.",
		"bait people toward their IED instead of chasing alone.",
		"their bomb vest is the final call; clear the area before it pops.",
		"fire forces people outside; hold the exits, not the flames."
	},
	traitor_lastmanstanding = {
		"herd targets into their Kar98 sightline and sling setup.",
		"pin victims down so their rifle shots are easy.",
		"let them hold open lanes while you work close corners.",
		"force targets across open ground when their Kar98 is posted.",
		"their brass knuckles cover close range; give them reload time.",
		"their rifle controls distance; call movement before targets cross.",
		"keep pressure off their reload and they can lock the map.",
		"their sling keeps the rifle ready; do not waste their angle.",
		"bait peeks with noise while they hold the shot.",
		"they are strongest when you feed them clean sightlines."
	}
}

local hmcd_traitor_self_tip_openers = {
	traitor_default = {
		"Use your IEDs or smoke to steer targets;",
		"Your pistol and poison can start the panic;",
		"Plant pressure with grenades or poison;",
		"Use the suppressed pistol only after suspicion is useful;",
		"Make the first loud threat look like a normal fight;",
		"Throw smoke before moving gear or bodies;",
		"Use poison to weaken groups before the killing starts;"
	},
	traitor_infiltrator = {
		"Use your smoke and disguise window;",
		"Create a quiet body for identity play;",
		"Work from behind and avoid loud openings;",
		"Break trust by returning as someone else;",
		"Save smoke for the disguise exit;",
		"Pick victims whose absence will confuse the group;",
		"Neck-snap only when your escape route is clear;"
	},
	traitor_thief = {
		"Steal radios, meds or guns first;",
		"Use your hidden starter gear to carry risk;",
		"Pickpocket before the first body drops;",
		"Search the loudest armed player before panic starts;",
		"Take escape tools, then call who is defenseless;",
		"Hide the dangerous gear on yourself;",
		"Empty pockets while your partner holds attention;",
		"Steal medicine before poison or bleed pressure begins;"
	},
	traitor_assasin = {
		"Disarm the biggest gun threat first;",
		"Use your stamina to force the opening;",
		"Strip weapons before your partner commits;",
		"Turn their gun into your next move;",
		"Ragdoll the target before a frontal disarm;",
		"Call the weapon you stole so your cell can push;",
		"Use speed to chase the one person who can stop the plan;"
	},
	traitor_chemist = {
		"Poison food or lock a choke with gas;",
		"Use chemical resistance to hold the area;",
		"Call your gas timing before people scatter;",
		"Sleep a room before anyone knows who started it;",
		"Turn trusted supplies into delayed kills;",
		"Stand in your own cloud if it keeps the exit shut;",
		"Use chemical reads to tell your partner when to enter;"
	},
	traitor_shadow = {
		"Use camouflage, tranq or cuffs to isolate;",
		"Stay hidden until your partner creates noise;",
		"Let your concealed kit remove witnesses;",
		"Hold still near walls before the ambush starts;",
		"Tranq the armed witness, not the easy target;",
		"Cuff someone only when your partner can receive them;",
		"Use poison after the victim is already controlled;"
	},
	traitor_maniac = {
		"Start the panic with axe, fire or grenade;",
		"Use your stamina and health to draw pressure;",
		"Force close combat while exits are covered;",
		"Make people run into your partner's trap;",
		"Use molotovs to break rooms before charging;",
		"Commit only when the gun threats are distracted;",
		"Let your axe announce the collapse, not the plan;"
	},
	traitor_terrorist = {
		"Use explosives to move the crowd;",
		"Set the blast path before anyone suspects;",
		"Burn or bomb exits only after your partner is clear;",
		"Call your vest plan before you get boxed in;",
		"Use fire to deny rescue, then leave the cleanup to them;",
		"Pipebomb first, ambush second;",
		"Make every loud blast create a quiet opening elsewhere;"
	},
	traitor_lastmanstanding = {
		"Hold a long angle with the Kar98;",
		"Use the sling and rifle to control open space;",
		"Cover your reloads with distance and calls;",
		"Tell your cell when someone crosses your lane;",
		"Use brass knuckles only if they rush your rifle;",
		"Let others flush targets into your scope;",
		"Stay posted until the crowd breaks formation;"
	}
}

local hmcd_traitor_role_colors = {
	traitor_default = Color(255, 172, 46),
	traitor_infiltrator = Color(195, 80, 255),
	traitor_thief = Color(70, 235, 255),
	traitor_assasin = Color(80, 150, 255),
	traitor_chemist = Color(70, 255, 115),
	traitor_shadow = Color(130, 90, 255),
	traitor_maniac = Color(255, 70, 70),
	traitor_terrorist = Color(255, 120, 35),
	traitor_lastmanstanding = Color(255, 220, 80)
}

local function get_hmcd_traitor_player_by_steamid(steamID)
	if not steamID or steamID == "" then return nil end

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply.SteamID and ply:SteamID() == steamID then
			return ply
		end
	end
end

local function get_hmcd_traitor_player(info)
	if not istable(info) then return nil end

	local ply = get_hmcd_traitor_player_by_steamid(info[3])
	if IsValid(ply) then return ply end

	local name = tostring(info[2] or "")
	if name == "" then return nil end

	for _, other_ply in player.Iterator() do
		if IsValid(other_ply) then
			local appearanceName = other_ply.CurAppearance and other_ply.CurAppearance.AName
			local playerName = other_ply.GetPlayerName and other_ply:GetPlayerName()

			if appearanceName == name or playerName == name or other_ply:Nick() == name then
				return other_ply
			end
		end
	end
end

local function hmcd_traitor_name_is_bad(name)
	name = tostring(name or "")
	return name == "" or name == "error" or string.find(name, "\239\191\189", 1, true) ~= nil
end

local function is_local_traitor_card(info)
	if not istable(info) then return false end
	if not lply then return false end

	if info[3] and info[3] ~= "" and lply.SteamID and info[3] == lply:SteamID() then
		return true
	end

	local ply = get_hmcd_traitor_player(info)
	if ply == lply then return true end

	if not lply.CurAppearance then return false end

	return info[2] == lply.CurAppearance.AName
end

local function get_hmcd_traitor_display_name(info)
	if not istable(info) then return nil end

	local name = tostring(info[2] or "")
	local ply = get_hmcd_traitor_player(info)

	if hmcd_traitor_name_is_bad(name) then
		if IsValid(ply) then
			name = (ply.GetPlayerName and ply:GetPlayerName()) or ply:Nick() or "Unknown"
		else
			return nil
		end
	end

	name = string.Trim(name)
	if hmcd_traitor_name_is_bad(name) then return nil end

	if #name > 22 then
		name = string.sub(name, 1, 20) .. ".."
	end

	return name
end

local function get_hmcd_traitor_role_name(info)
	local role = info[4] or ""
	local ply = get_hmcd_traitor_player(info)

	if role == "" and IsValid(ply) then
		role = ply.SubRole or ""
	end

	return get_hmcd_subrole_name(role)
end

local function get_hmcd_traitor_role_id(info)
	if not istable(info) then return "" end

	local role = info[4] or ""
	if role == "" then
		local ply = get_hmcd_traitor_player(info)
		if IsValid(ply) then
			role = ply.SubRole or ""
		end
	end

	return role
end

local function get_hmcd_traitor_base_role_id(info)
	local role = get_hmcd_traitor_role_id(info)
	return string.gsub(role or "", "_soe$", "")
end

local function get_hmcd_traitor_role_color(info)
	return hmcd_traitor_role_colors[get_hmcd_traitor_base_role_id(info)] or hmcd_traitor_role_colors.traitor_default
end

local function get_hmcd_local_traitor_base_role_id()
	if not lply then return "traitor_default" end

	local role = lply.SubRole or ""
	if role == "" then return "traitor_default" end

	role = string.gsub(role, "_soe$", "")
	return hmcd_traitor_self_tip_openers[role] and role or "traitor_default"
end

local function get_hmcd_traitor_role_tip(info, usedTips)
	local localRole = get_hmcd_local_traitor_base_role_id()
	local partnerRole = get_hmcd_traitor_base_role_id(info)
	local openers = hmcd_traitor_self_tip_openers[localRole] or hmcd_traitor_self_tip_openers.traitor_default
	local tips = hmcd_traitor_role_tips[partnerRole]

	if not istable(tips) or #tips == 0 then
		local fallback = "Use your kit to create pressure; they should call targets and cover exits."
		if usedTips then usedTips[fallback] = true end
		return fallback
	end

	local seed = tostring(MODE.HMCDIntroTipSalt or StartTime or "") .. tostring(localRole) .. tostring(partnerRole) .. tostring(info and (info[3] or info[2]) or "")
	local sum = 0

	for i = 1, #seed do
		sum = sum + string.byte(seed, i)
	end

	local startIndex = (sum % #tips) + 1

	for offset = 0, #tips - 1 do
		local index = ((startIndex + offset - 1) % #tips) + 1
		local opener = openers[((startIndex + offset - 1) % #openers) + 1]
		local tip = opener .. " " .. tips[index]

		if not usedTips or not usedTips[tip] then
			if usedTips then usedTips[tip] = true end
			return tip
		end
	end

	local tip = openers[((startIndex - 1) % #openers) + 1] .. " " .. tips[startIndex]
	if usedTips then usedTips[tip] = true end
	return tip
end

local function hmcd_fit_text(text, fontName, maxWidth)
	text = tostring(text or "")
	surface.SetFont(fontName)

	if surface.GetTextSize(text) <= maxWidth then
		return text
	end

	local suffix = "..."
	local low, high, fit = 1, #text, suffix

	while low <= high do
		local mid = math.floor((low + high) * 0.5)
		local candidate = string.sub(text, 1, mid) .. suffix

		if surface.GetTextSize(candidate) <= maxWidth then
			fit = candidate
			low = mid + 1
		else
			high = mid - 1
		end
	end

	return fit
end

local function hmcd_wrap_text(text, fontName, maxWidth, maxLines)
	text = tostring(text or "")
	surface.SetFont(fontName)

	local words = {}
	for word in string.gmatch(text, "%S+") do
		words[#words + 1] = word
	end

	local lines = {}
	local current = ""

	for _, word in ipairs(words) do
		local candidate = current == "" and word or (current .. " " .. word)

		if surface.GetTextSize(candidate) <= maxWidth then
			current = candidate
		else
			if current ~= "" then
				lines[#lines + 1] = current
			end

			current = word

			if #lines >= maxLines then
				break
			end
		end
	end

	if current ~= "" and #lines < maxLines then
		lines[#lines + 1] = current
	end

	if #lines == maxLines and surface.GetTextSize(lines[#lines]) > maxWidth then
		lines[#lines] = hmcd_fit_text(lines[#lines], fontName, maxWidth)
	elseif #words > 0 and #lines == maxLines then
		local usedText = table.concat(lines, " ")

		if #usedText < #text then
			lines[#lines] = hmcd_fit_text(lines[#lines], fontName, maxWidth)
		end
	end

	return lines
end

local function draw_hmcd_traitor_solo_cell(y, alpha)
	alpha = math.Clamp(alpha or 0, 0, 1)

	local tileW = hmcd_intro_scale(430)
	local tileH = hmcd_intro_scale(112)
	local x = sw * 0.5 - tileW * 0.5
	local cut = hmcd_intro_scale(12)
	local cy = y + hmcd_intro_scale(32)

	draw.SimpleText("TRAITOR CELL", "ZB_HomicideCellHeader", sw * 0.5, y, Color(255, 70, 70, 230 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw_hmcd_intro_cut_box(x, cy, tileW, tileH, cut, Color(16, 0, 0, 225 * alpha), Color(255, 38, 38, 170 * alpha))

	surface.SetDrawColor(255, 0, 0, 18 * alpha)
	draw.NoTexture()
	surface.DrawPoly({
		{x = x + cut + 1, y = cy + 1},
		{x = x + tileW - cut - 1, y = cy + 1},
		{x = x + tileW - 1, y = cy + cut + 1},
		{x = x + tileW - 1, y = cy + hmcd_intro_scale(36)},
		{x = x + 1, y = cy + hmcd_intro_scale(36)},
		{x = x + 1, y = cy + cut + 1}
	})

	surface.SetDrawColor(255, 40, 40, 140 * alpha)
	surface.DrawRect(x + hmcd_intro_scale(12), cy + hmcd_intro_scale(42), 3, tileH - hmcd_intro_scale(56))
	surface.SetDrawColor(255, 70, 70, 70 * alpha)
	surface.DrawRect(x + hmcd_intro_scale(24), cy + hmcd_intro_scale(72), tileW - hmcd_intro_scale(48), 1)

	draw.SimpleText("NO CELL LINK DETECTED", "ZB_HomicideCellName", sw * 0.5, cy + hmcd_intro_scale(44), Color(255, 95, 95, 235 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(hmcd_fit_text("Solo protocol active. Stay quiet, control evidence, and choose the first kill carefully.", "ZB_HomicideCellTip", tileW - hmcd_intro_scale(48)), "ZB_HomicideCellTip", sw * 0.5, cy + hmcd_intro_scale(78), Color(255, 175, 175, 220 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	return hmcd_intro_scale(32) + tileH
end

local function draw_hmcd_traitor_partner_tiles(partners, y, alpha)
	local validPartners = {}

	for _, info in ipairs(partners) do
		if not is_local_traitor_card(info) and get_hmcd_traitor_display_name(info) then
			validPartners[#validPartners + 1] = info
		end
	end

	local count = #validPartners
	if count <= 0 then return 0 end
	alpha = math.Clamp(alpha or 0, 0, 1)

	local tileW = hmcd_intro_scale(410)
	local tileH = hmcd_intro_scale(156)
	local gap = hmcd_intro_scale(18)
	local maxCols = math.max(1, math.floor((sw - hmcd_intro_scale(120)) / (tileW + gap)))
	local cols = math.min(count, 2, maxCols)
	local rows = math.ceil(count / cols)
	local startX = sw * 0.5 - (cols * tileW + (cols - 1) * gap) * 0.5
	local cardAlpha = 230 * alpha
	local introPulse = math.Clamp(1 - (CurTime() - (StartTime or CurTime())), 0, 1)
	local pulseAlpha = introPulse * alpha
	local usedTips = {}

	draw.SimpleText("TRAITOR CELL", "ZB_HomicideCellHeader", sw * 0.5, y, Color(255, 70, 70, 230 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	y = y + hmcd_intro_scale(32)

	for i, info in ipairs(validPartners) do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local x = startX + col * (tileW + gap)
		local cy = y + row * (tileH + gap)
		local color = IsColor(info[1]) and info[1] or Color(220, 30, 30)
		local name = get_hmcd_traitor_display_name(info)
		local roleName = get_hmcd_traitor_role_name(info)
		local roleAccent = get_hmcd_traitor_role_color(info)
		local roleTipLines = hmcd_wrap_text(get_hmcd_traitor_role_tip(info, usedTips), "ZB_HomicideCellTip", tileW - hmcd_intro_scale(44), 2)
		local header = "CELL LINK ACTIVE / PARTNER " .. string.format("%02d", i)
		local cut = hmcd_intro_scale(12)
		local topBandH = hmcd_intro_scale(36)

		draw_hmcd_intro_cut_box(x, cy, tileW, tileH, cut, Color(18, 0, 0, cardAlpha), Color(255, 38, 38, 170 * alpha))

		surface.SetDrawColor(255, 0, 0, 18 * alpha)
		draw.NoTexture()
		surface.DrawPoly({
			{x = x + cut + 1, y = cy + 1},
			{x = x + tileW - cut - 1, y = cy + 1},
			{x = x + tileW - 1, y = cy + cut + 1},
			{x = x + tileW - 1, y = cy + topBandH},
			{x = x + 1, y = cy + topBandH},
			{x = x + 1, y = cy + cut + 1}
		})
		surface.SetDrawColor(255, 40, 40, 130 * alpha)
		surface.DrawRect(x + hmcd_intro_scale(10), cy + topBandH + hmcd_intro_scale(6), 3, tileH - topBandH - hmcd_intro_scale(18))
		surface.SetDrawColor(roleAccent.r, roleAccent.g, roleAccent.b, 210 * alpha)
		surface.DrawRect(x + hmcd_intro_scale(14), cy + topBandH + hmcd_intro_scale(6), 2, tileH - topBandH - hmcd_intro_scale(18))
		surface.SetDrawColor(255, 70, 70, 80 * alpha)
		surface.DrawRect(x + hmcd_intro_scale(22), cy + hmcd_intro_scale(76), tileW - hmcd_intro_scale(44), 1)
		surface.SetDrawColor(roleAccent.r, roleAccent.g, roleAccent.b, 115 * alpha)
		surface.DrawRect(x + hmcd_intro_scale(22), cy + hmcd_intro_scale(77), tileW - hmcd_intro_scale(44), 1)
		surface.SetDrawColor(38, 0, 0, 155 * alpha)
		surface.DrawRect(x + hmcd_intro_scale(22), cy + hmcd_intro_scale(84), tileW - hmcd_intro_scale(44), hmcd_intro_scale(58))

		if pulseAlpha > 0 then
			local scanY = cy + hmcd_intro_scale(8) + (tileH - hmcd_intro_scale(16)) * (1 - introPulse)
			surface.SetDrawColor(255, 35, 35, 55 * pulseAlpha)
			surface.DrawRect(x + hmcd_intro_scale(18), scanY, tileW - hmcd_intro_scale(36), hmcd_intro_scale(7))
			surface.SetDrawColor(255, 115, 115, 80 * pulseAlpha)
			surface.DrawRect(x + hmcd_intro_scale(18), scanY + hmcd_intro_scale(3), tileW - hmcd_intro_scale(36), 1)
		end

		surface.SetFont("ZB_HomicideCellHeader")
		local roleText = string.upper(roleName)
		local roleW = math.min(surface.GetTextSize(roleText) + hmcd_intro_scale(20), tileW * 0.42)
		local roleX = x + tileW - roleW - hmcd_intro_scale(16)
		local headerY = cy + hmcd_intro_scale(10)
		local roleBadgeY = headerY - hmcd_intro_scale(3)
		local roleBadgeH = hmcd_intro_scale(24)
		draw.RoundedBox(hmcd_intro_scale(4), roleX, roleBadgeY, roleW, roleBadgeH, Color(78, 0, 0, 175 * alpha))
		surface.SetDrawColor(roleAccent.r, roleAccent.g, roleAccent.b, 185 * alpha)
		surface.DrawOutlinedRect(roleX, roleBadgeY, roleW, roleBadgeH, 1)

		draw.SimpleText(header, "ZB_HomicideCellHeader", x + hmcd_intro_scale(24), headerY, Color(255, 115, 115, 200 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("ENCRYPTED", "ZB_HomicideCellHeader", roleX - hmcd_intro_scale(10), headerY, Color(255, 115, 115, 135 * alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(hmcd_fit_text(roleText, "ZB_HomicideCellHeader", roleW - hmcd_intro_scale(12)), "ZB_HomicideCellHeader", roleX + roleW * 0.5, headerY, Color(roleAccent.r, roleAccent.g, roleAccent.b, 235 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(hmcd_fit_text(name, "ZB_HomicideCellName", tileW - hmcd_intro_scale(48)), "ZB_HomicideCellName", x + hmcd_intro_scale(24), cy + hmcd_intro_scale(42), Color(color.r, color.g, color.b, 255 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("TEAM PLAY", "ZB_HomicideCellHeader", x + hmcd_intro_scale(24), cy + hmcd_intro_scale(88), Color(255, 95, 95, 190 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		for lineIndex, line in ipairs(roleTipLines) do
			draw.SimpleText(line, "ZB_HomicideCellTip", x + hmcd_intro_scale(24), cy + hmcd_intro_scale(103 + (lineIndex - 1) * 15), Color(255, 175, 175, 220 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	return hmcd_intro_scale(32) + rows * tileH + (rows - 1) * gap
end

MODE.TypeObjectives = {}
MODE.TypeObjectives.soe = {
	traitor = {
		objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
		name = "a Traitor",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "You are an innocent with a hunting weapon. Find and neutralize the traitor before it's too late.",
		name = "an Innocent",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "You are an innocent, rely only on yourself, but stick around with crowds to make traitor's job harder.",
		name = "an Innocent",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.standard = {
	traitor = {
		objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
		name = "a Murderer",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "You are a bystander with a concealed firearm. You've tasked yourself to help police find the criminal faster.",
		name = "a Bystander",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious.",
		name = "a Bystander",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.wildwest = {
	traitor = {
		objective = "This town ain't that big for all of us.",
		name = "The Killer",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "You're the sheriff of this town. You gotta find and kill the lawless bastard.",
		name = "The Sheriff",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "We gotta get justice served over here, there's a lawless prick murdering men.",
		name = "a Fellow Cowboy",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},
}

MODE.TypeObjectives.gunfreezone = {
	traitor = {
		objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
		name = "a Murderer",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious.",
		name = "a Bystander",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious.",
		name = "a Bystander",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.suicidelunatic = {
	traitor = {
		objective = "My brother insha'Allah, don't let him down.",
		name = "a Shahid",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Sheep fucker's gone crazy, now you need to survive.",
		name = "an Innocent",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Sheep fucker's gone crazy, now you need to survive.",
		name = "an Innocent",
		color1 = Color(0,120,190)
	},
}


MODE.TypeObjectives.supermario = {
	traitor = {
		objective = "You're the evil Mario! Jump around and take down everyone.",
		name = "Traitor Mario",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "You're the hero Mario! Use your jumping ability to stop the traitor.",
		name = "Hero Mario",
		color1 = Color(158,0,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "You're a bystander Mario, survive and avoid the traitor's traps!",
		name = "Innocent Mario",
		color1 = Color(0,120,190)
	},
}

function MODE:RenderScreenspaceEffects()
	-- MODE.DynamicFadeScreenEndTime = MODE.DynamicFadeScreenEndTime or 0
	fade_end_time = MODE.DynamicFadeScreenEndTime or 0
	local time_diff = fade_end_time - CurTime()

	if(time_diff > 0)then
		zb.RemoveFade()

		local fade = math.min(time_diff / MODE.FadeScreenTime, 1)

		surface.SetDrawColor(0, 0, 0, 255 * fade)
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end

local handicap = {
	[1] = "You are handicapped: your right leg is broken.",
	[2] = "You are handicapped: you are suffering from severe obesity.",
	[3] = "You are handicapped: you are suffering from hemophilia.",
	[4] = "You are handicapped: you are physically incapacitated."
}

function MODE:HUDPaint()
	if not MODE.Type or not MODE.TypeObjectives[MODE.Type] then return end
	if lply:Team() == TEAM_SPECTATOR then return end
	if StartTime + 12 < CurTime() then return end
	
	fade = Lerp(FrameTime()*1, fade, math.Clamp(StartTime + 5 - CurTime(),-2,2))

	draw.SimpleText("Homicide | " .. (MODE.TypeNames[MODE.Type] or "Unknown"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Rolename = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.name ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.name ) or MODE.TypeObjectives[MODE.Type].innocent.name
	local ColorRole = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color1 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color1 ) or MODE.TypeObjectives[MODE.Type].innocent.color1
	ColorRole.a = 255 * fade

	local color_role_innocent = MODE.TypeObjectives[MODE.Type].innocent.color1
	color_role_innocent.a = 255 * fade

	local color_white_faded = Color(255, 255, 255, 255 * fade)
	color_white_faded.a = 255 * fade

	draw.SimpleText("You are "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)



	local cur_y = sh * 0.5

	-- local ColorRole = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color1 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color1 ) or MODE.TypeObjectives[MODE.Type].innocent.color1
	-- ColorRole.a = 255 * fade
	if(lply.SubRole and lply.SubRole != "")then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("" .. ((MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Name or lply.SubRole) or lply.SubRole), "ZB_HomicideMediumLarge", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("Assistant", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end


	if(lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		if(lply.MainTraitor)then
			MODE.TraitorsLocal = MODE.TraitorsLocal or {}
			local partners = {}

			for _, traitor_info in ipairs(MODE.TraitorsLocal) do
				if not is_local_traitor_card(traitor_info) and get_hmcd_traitor_display_name(traitor_info) then
					partners[#partners + 1] = traitor_info
				end
			end

			if(#partners > 0)then
				local tileH = draw_hmcd_traitor_partner_tiles(partners, cur_y, fade)
				cur_y = cur_y + tileH + ScreenScale(8)
			else
				local tileH = draw_hmcd_traitor_solo_cell(cur_y, fade)
				cur_y = cur_y + tileH + ScreenScale(8)
			end
		else
			draw.SimpleText("Traitor secret words:", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)

			draw.SimpleText("\"" .. MODE.TraitorWord .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)

			draw.SimpleText("\"" .. MODE.TraitorWordSecond .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if(lply.Profession and lply.Profession != "")then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("Occupation: " .. ((MODE.Professions[lply.Profession] and MODE.Professions[lply.Profession].Name or lply.Profession) or lply.Profession), "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	if(handicap[lply:GetLocalVar("karma_sickness", 0)])then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText(handicap[lply:GetLocalVar("karma_sickness", 0)], "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local Objective = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.objective ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.objective ) or MODE.TypeObjectives[MODE.Type].innocent.objective

	if(lply.SubRole and lply.SubRole != "")then
		if(MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Objective)then
			Objective = MODE.SubRoles[lply.SubRole].Objective
		end
	end

	if(!lply.isTraitor and lply.Profession and lply.Profession != "")then
		local profession_info = MODE.Professions[lply.Profession]

		if(profession_info and profession_info.Objective)then
			Objective = profession_info.Objective
		end
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		Objective = "You are equipped with nothing. Help other traitors win."
	end

	--; WARNING Traitor's objective is not lined up with SubRole's
	if(!MODE.RoleEndedChosingState)then
		Objective = "Round is starting..."
	end

	local ColorObj = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color2 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color2 ) or MODE.TypeObjectives[MODE.Type].innocent.color2 or Color(255,255,255)
	ColorObj.a = 255 * fade
	draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu

net.Receive("hmcd_roundend", function()
	local traitors, gunners = {}, {}

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local traitor = net.ReadEntity()
		traitors[key] = traitor
		traitor.isTraitor = true
	end

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local gunner = net.ReadEntity()
		gunners[key] = gunner
		gunner.isGunner = true
	end

	timer.Simple(2.5, function()


		lply.isPolice = false
		lply.isTraitor = false
		lply.isGunner = false
		lply.MainTraitor = false
		lply.SubRole = nil
		lply.Profession = nil
	end)

	traitor = traitors[1] or Entity(0)

	CreateEndMenu(traitor)
end)

net.Receive("hmcd_announce_traitor_lose", function()
	local traitor = net.ReadEntity()
	local traitor_alive = net.ReadBool()

	if(IsValid(traitor))then
		chat.AddText(color_white, (traitor_alive and "" or "Traitor "), traitor:GetPlayerColor():ToColor(), traitor:GetPlayerName() .. ", " .. traitor:Nick(), color_white, " was " .. (traitor_alive and "a Traitor." or "killed."))
	end
end)

local colGray = Color(85,85,85)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)

local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function(traitor)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

	if !IsValid(hmcdEndMenu) then return end

	local players = {}

	local traitorName = IsValid(traitor) and traitor:GetPlayerName() or "unknown"
	local traitorNick = IsValid(traitor) and traitor:Nick() or "unknown"

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if !IsValid(ply) then return end
		
		players[#players + 1] = {
			nick = ply:Nick(),
			name = ply:GetPlayerName(),
			isTraitor = ply.isTraitor,
			isGunner = ply.isGunner,
			incapacitated = ply.organism and ply.organism.otrub,
			alive = ply:Alive(),
			col = ply:GetPlayerColor():ToColor(),
			frags = ply:Frags(),
			steamid = ply:IsBot() and "BOT" or ply:SteamID64(),
		}
	end

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX,sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")

	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.PaintOver = function(self,w,h)
		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize(traitorName .. " was a traitor ("..traitorNick..")")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText(traitorName .. " was a traitor ("..traitorNick..")")
	end

	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for i, info in ipairs(players) do
		local but = vgui.Create("DButton",DScrollPanel)

		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")

		but.Paint = function(self,w,h)
			local col1 = (info.isTraitor and colRed) or (info.alive and colBlue) or colGray
			local col2 = info.isTraitor and (info.alive and colRedUp or colSpect1) or ((info.alive and !info.incapacitated) and colBlueUp) or colSpect1
			local name = info.nick
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local col = info.col
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(name)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(name)

			surface.SetTextColor(col.r, col.g, col.b, col.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(name)


			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize(info.name)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText(info.name .. ((!info.alive and " - died") or (info.incapacitated and " - incapacitated") or ""))

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(info.frags)
			surface.SetTextPos(w - lengthX -15,h/2 - lengthY/2)
			surface.DrawText(info.frags)
		end

		function but:DoClick()
			if info.steamid == "BOT" then chat.AddText(Color(255, 0, 0), "That's a bot.") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..info.steamid)
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	-- if IsValid(hmcdEndMenu) then
	-- 	hmcdEndMenu:Remove()
	-- 	hmcdEndMenu = nil
	-- end
end

--\\
net.Receive("HMCD(StartPlayersRoleSelection)", function()
	local role = net.ReadString()

	hg.SelectPlayerRole(role)
end)

function hg.SelectPlayerRole(role, mode, parent)
	role = role or "Traitor"

	if not mode then
		if(IsValid(VGUI_HMCD_RolePanelList))then
			VGUI_HMCD_RolePanelList:Remove()
		end

		if(IsValid(VGUI_HMCD_TraitorTileMenu))then
			VGUI_HMCD_TraitorTileMenu:Remove()
		end

		hg.HMCD_TraitorTileEmbedParent = IsValid(parent) and parent or nil
		VGUI_HMCD_TraitorTileMenu = vgui.Create("HMCD_TraitorTileMenu")
		return
	end

	if(IsValid(VGUI_HMCD_RolePanelList))then
		VGUI_HMCD_RolePanelList:Remove()
	end

	if(IsValid(VGUI_HMCD_TraitorTileMenu))then
		VGUI_HMCD_TraitorTileMenu:Remove()
	end

	if(MODE.RoleChooseRoundTypes[mode])then
		//VGUI_HMCD_RolePanelList = vgui.Create("ZB_TraitorSelectionMenu")
		//VGUI_HMCD_RolePanelList:Center()
		VGUI_HMCD_RolePanelList = vgui.Create("HMCD_RolePanelList")
		VGUI_HMCD_RolePanelList.RolesIDsList = MODE.RoleChooseRoundTypes[mode][role]	--; WARNING TCP Reroute
		VGUI_HMCD_RolePanelList.Mode = mode
		-- VGUI_HMCD_RolePanelList:SetSize(ScreenScale(600), ScreenScale(300))
		VGUI_HMCD_RolePanelList:SetSize(screen_scale_2(700), screen_scale_2(300))
		VGUI_HMCD_RolePanelList:Center()
		VGUI_HMCD_RolePanelList:InvalidateParent(false)
		VGUI_HMCD_RolePanelList:Construct()
		VGUI_HMCD_RolePanelList:MakePopup()
	end
end

net.Receive("HMCD(EndPlayersRoleSelection)", function()
	if(IsValid(VGUI_HMCD_RolePanelList))then
		VGUI_HMCD_RolePanelList:Remove()
	end

	if(IsValid(VGUI_HMCD_TraitorTileMenu))then
		VGUI_HMCD_TraitorTileMenu:Remove()
	end
end)

net.Receive("HMCD(SetSubRole)", function(len, ply)
	lply.SubRole = net.ReadString()
end)

net.Receive("HMCD(SetProfession)", function()
	lply.Profession = net.ReadString()
end)
--//

--CreateEndMenu()

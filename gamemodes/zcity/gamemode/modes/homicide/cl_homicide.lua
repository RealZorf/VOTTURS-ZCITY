local MODE = MODE
MODE.name = "hmcd"

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--

MODE.TypeSounds = {
	["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gunfreezone"] = "snd_jack_hmcd_panic.mp3" ,
	["suicidelunatic"] = "zbattle/jihadmode.mp3",
	["wildwest"] = "snd_jack_hmcd_wildwest.mp3",
	["supermario"] = "snd_jack_hmcd_psycho.mp3"
}
local fade = 0
local maniacFuryFeedback = 0
local maniacFuryWasActive = false
local maniacFuryNextHeartbeat = 0
local maniacFuryStartTime = 0
local maniacFuryBreathEndTime = 0
local maniacFuryNextBreath = 0
local maniacFuryBreathIndex = 0
local maniacFuryBreathDuration = 22

local function isLocalManiacFuryActive()
	local ply = LocalPlayer()

	return IsValid(ply)
		and ply:Alive()
		and ply:Team() != TEAM_SPECTATOR
		and ply:GetNWBool("HMCD_ManiacFuryActive", false)
end

local function getLocalManiacFuryElapsed(now)
	local ply = LocalPlayer()
	if not IsValid(ply) then return 0 end

	local started_at = ply:GetNWFloat("HMCD_ManiacFuryStartedAt", 0)
	if started_at <= 0 then return 0 end

	return math.max(now - started_at, 0)
end

hook.Add("Think", "HMCD_ManiacFurySelfFeedback", function()
	local active = isLocalManiacFuryActive()
	local now = CurTime()

	if active and not maniacFuryWasActive then
		maniacFuryStartTime = now
		maniacFuryNextHeartbeat = 0
		maniacFuryBreathEndTime = now + maniacFuryBreathDuration
		maniacFuryNextBreath = 0
		maniacFuryBreathIndex = 0
	elseif not active and maniacFuryWasActive then
		maniacFuryNextHeartbeat = 0
		maniacFuryBreathEndTime = 0
		maniacFuryNextBreath = 0
	end

	if active and maniacFuryNextHeartbeat <= now then
		surface.PlaySound("heartbeat/heartbeat_single.wav")
		maniacFuryNextHeartbeat = now + math.Clamp(0.84 - math.min(now - maniacFuryStartTime, 8) * 0.025, 0.58, 0.84)
	end

	local elapsed = active and getLocalManiacFuryElapsed(now) or 0
	if active and maniacFuryBreathDuration > 0 and elapsed < maniacFuryBreathDuration and maniacFuryNextBreath <= now then
		local ply = LocalPlayer()
		local fade = math.Clamp((maniacFuryBreathDuration - elapsed) / maniacFuryBreathDuration, 0, 1)
		local volume = fade * fade * 0.24
		local sex = ThatPlyIsFemale and ThatPlyIsFemale(ply) and "f" or "m"
		local maxBreaths = sex == "f" and 4 or 4

		if volume > 0.015 then
			maniacFuryBreathIndex = (maniacFuryBreathIndex % maxBreaths) + 1
			ply:EmitSound("snds_jack_hmcd_breathing/" .. sex .. maniacFuryBreathIndex .. ".wav", 45, 96, volume, CHAN_AUTO)
		end

		maniacFuryNextBreath = now + math.Remap(fade, 0, 1, 5.2, 2.8)
	end

	maniacFuryWasActive = active
end)

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
	--

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
	traitor_assassin = {
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
		"create noise so they can blend into a wall before striking.",
		"they can tranq, cuff and poison; give them isolated angles.",
		"their handcuffs turn a risky target into a quiet delivery.",
		"let them hold a wall while you bait someone through it.",
		"their tranquilizer is precious; call only high-value targets.",
		"concealed weapons keep suspicion low after a search.",
		"their camouflage holds briefly after cover, so time the bait."
	},
	traitor_maniac = {
		"block exits before they charge with axe, molotov and grenade.",
		"use their high stamina to start panic while you catch runners.",
		"their first serious wound triggers permanent fury; be ready to push.",
		"let their fire axe force close fights; cover guns at range.",
		"their health and stamina buy time for your slower setup.",
		"when they go loud, use the chaos to finish separated targets.",
		"their poisoned axe can make one hit turn into a collapse.",
		"molotov pressure splits crowds; wait where they scatter.",
		"their loud push is cover for your quiet objective.",
		"let them tank attention while you remove weapons from the edge.",
		"grenade panic makes people drop formation; punish the split."
	},
	traitor_juggernaut = {
		"feed them smaller targets they can lift and strangle.",
		"let them throw bodies into walls while you cover the noise.",
		"they cannot overpower Athletes; call softer targets first.",
		"their size draws attention, so use their push as your opening.",
		"force victims into tight rooms where wall impacts are unavoidable.",
		"let them control the front while you cut off escapes.",
		"their carried victim becomes a weapon; stay out of the slam path.",
		"smoke lets them close distance before the grab.",
		"unconscious victims are vulnerable to a skull stomp."
	},
	traitor_cannibal = {
		"feed them corpses after fights so they can come back stronger.",
		"cover the body while they consume it; each meal makes their next push worse.",
		"their strength scales after dead victims, so early body control matters.",
		"let them finish wounded targets, then protect the corpse long enough to feed.",
		"their melee threat grows with every consumed body.",
		"smoke a corpse pile and let them recover before the next fight.",
		"deny medics the body while they turn it into health and blood.",
		"they are strongest when kills happen close enough to harvest.",
		"drag attention away from fallen victims while they feed."
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
	},
	traitor_stalker = {
		"let them watch groups early; they can mark runners quickly now.",
		"call wounded targets; their heartbeat pulse makes hiding harder.",
		"their first hit on each mark now staggers, drains stamina and bites harder.",
		"split the crowd after they mark three victims.",
		"their sonar is strongest after panic scatters people.",
		"give them quiet sightlines before the first body drops.",
		"marked targets are easier to chase through rooms and smoke.",
		"let them open on a marked gun threat to interrupt and weaken the response.",
		"their pulse readout tells you who is still alive and moving.",
		"they are best at finishing isolated survivors, not starting a massacre."
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
	traitor_assassin = {
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
		"Blend into walls before the ambush starts;",
		"Tranq the armed witness, not the easy target;",
		"Cuff someone only when your partner can receive them;",
		"Use poison after the victim is already controlled;"
	},
	traitor_maniac = {
		"Start the panic with axe, fire or grenade;",
		"Use your stamina and health to draw pressure;",
		"Once seriously wounded, use the permanent fury to keep pushing;",
		"Force close combat while exits are covered;",
		"Make people run into your partner's trap;",
		"Use molotovs to break rooms before charging;",
		"Commit only when the gun threats are distracted;",
		"Let your axe announce the collapse, not the plan;"
	},
	traitor_juggernaut = {
		"Grab smaller non-Athletes and lift them;",
		"Hold ALT while carrying a victim;",
		"Slam carried victims into walls or props;",
		"Press ALT + E over an unconscious head;",
		"Use your larger body to block exits;",
		"Smoke before closing the grab distance;",
		"Avoid Athletes; they are too large to overpower;"
	},
	traitor_cannibal = {
		"Consume bodies after close fights;",
		"Use smoke to secure time over a corpse;",
		"Feed only when exits are covered;",
		"Every body makes your next melee push stronger;",
		"Recover blood before re-entering a gunfight;",
		"Turn fallen victims into stamina before chasing;",
		"Kill near cover so you can harvest safely;"
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
	},
	traitor_stalker = {
		"Mark victims quickly before the room starts moving;",
		"Watch pulses to track people through walls;",
		"Save your first-hit stagger and damage boost for a real opening;",
		"Mark the armed witness before you reveal yourself;",
		"Use heartbeat rhythm to follow wounded runners;",
		"Use isolated prey to refill stamina and move quietly;",
		"Call marked targets when they split from the crowd;"
	}
}

local hmcd_traitor_role_colors = {
	traitor_default = Color(255, 172, 46),
	traitor_infiltrator = Color(195, 80, 255),
	traitor_thief = Color(70, 235, 255),
	traitor_assassin = Color(80, 150, 255),
	traitor_chemist = Color(70, 255, 115),
	traitor_shadow = Color(130, 90, 255),
	traitor_maniac = Color(255, 70, 70),
	traitor_juggernaut = Color(210, 95, 55),
	traitor_cannibal = Color(175, 45, 45),
	traitor_terrorist = Color(255, 120, 35),
	traitor_lastmanstanding = Color(255, 220, 80),
	traitor_stalker = Color(80, 210, 255)
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

	role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
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

	return MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
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

	role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
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

	maniacFuryFeedback = Lerp(FrameTime() * 5, maniacFuryFeedback, isLocalManiacFuryActive() and 1 or 0)
	if maniacFuryFeedback > 0.01 then
		local pulse = 0.55 + math.sin(CurTime() * 7.5) * 0.45
		local strength = maniacFuryFeedback * (0.55 + pulse * 0.45)

		DrawColorModify({
			["$pp_colour_addr"] = 0.025 * strength,
			["$pp_colour_addg"] = -0.006 * strength,
			["$pp_colour_addb"] = -0.008 * strength,
			["$pp_colour_brightness"] = -0.01 * strength,
			["$pp_colour_contrast"] = 1 + 0.06 * strength,
			["$pp_colour_colour"] = 1 + 0.04 * strength,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		})

		surface.SetDrawColor(160, 0, 0, 18 * strength)
		surface.DrawRect(0, 0, ScrW(), ScrH())
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
local hmcdTraitorRoundSummary = {}
local hmcdTraitorSummaryPanel
local HMCD_SUMMARY_BASE_W = 1920
local HMCD_SUMMARY_BASE_H = 1080

local function HMCDSummaryScale()
	return math.min(ScrW() / HMCD_SUMMARY_BASE_W, ScrH() / HMCD_SUMMARY_BASE_H)
end

local function HMCDSummaryUI(value)
	return math.max(1, math.floor(value * HMCDSummaryScale()))
end

local function HMCDRebuildSummaryFonts()
	surface.CreateFont("HMCD_SummaryHeader", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(17),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("HMCD_SummaryName", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(24),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("HMCD_SummaryRole", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(14),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("HMCD_SummarySmall", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(12),
		weight = 700,
		antialias = true
	})

	surface.CreateFont("HMCD_ReportTitle", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(30),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("HMCD_ReportName", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(19),
		weight = 700,
		antialias = true
	})

	surface.CreateFont("HMCD_ReportSmall", {
		font = "Bahnschrift",
		size = HMCDSummaryUI(13),
		weight = 700,
		antialias = true
	})
end

local function HMCDSummaryCutPoints(x, y, w, h, cut)
	return {
		{x = x + cut, y = y},
		{x = x + w - cut, y = y},
		{x = x + w, y = y + cut},
		{x = x + w, y = y + h - cut},
		{x = x + w - cut, y = y + h},
		{x = x + cut, y = y + h},
		{x = x, y = y + h - cut},
		{x = x, y = y + cut}
	}
end

local function HMCDDrawSummaryCutBox(x, y, w, h, cut, fill, outline)
	local points = HMCDSummaryCutPoints(x, y, w, h, cut)
	draw.NoTexture()
	surface.SetDrawColor(fill)
	surface.DrawPoly(points)

	if not outline then return end

	-- VGUI clips coordinates drawn exactly at width/height, so inset the outline only.
	points = HMCDSummaryCutPoints(x, y, math.max(w - 1, 0), math.max(h - 1, 0), cut)
	surface.SetDrawColor(outline)
	for index = 1, #points do
		local nextIndex = index == #points and 1 or index + 1
		surface.DrawLine(points[index].x, points[index].y, points[nextIndex].x, points[nextIndex].y)
	end
end

local function HMCDFitSummaryText(text, font, maxWidth)
	text = tostring(text or "")
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxWidth then return text end

	while #text > 1 and surface.GetTextSize(text .. "...") > maxWidth do
		text = string.sub(text, 1, -2)
	end

	return text .. "..."
end


local function HMCDSnapshotTraitorPortrait(ply)
	local snapshot = {
		model = "models/player/group01/male_07.mdl",
		skin = 0,
		modelScale = 1,
		playerColor = Vector(1, 1, 1),
		bodygroups = {},
		subMaterials = {},
		accessories = {}
	}

	if not IsValid(ply) then return snapshot end

	snapshot.model = ply:GetModel() or snapshot.model
	snapshot.skin = ply:GetSkin() or 0
	snapshot.modelScale = ply:GetModelScale() or 1
	snapshot.playerColor = ply.GetPlayerColor and ply:GetPlayerColor() or snapshot.playerColor

	local accessories = ply.GetNetVar and ply:GetNetVar("Accessories")
	if istable(accessories) then
		snapshot.accessories = table.Copy(accessories)
	elseif isstring(accessories) and accessories ~= "" then
		snapshot.accessories = {accessories}
	end

	for _, bodygroup in ipairs(ply:GetBodyGroups() or {}) do
		snapshot.bodygroups[bodygroup.id] = ply:GetBodygroup(bodygroup.id)
	end

	for materialIndex = 0, #(ply:GetMaterials() or {}) - 1 do
		local subMaterial = ply:GetSubMaterial(materialIndex)
		if isstring(subMaterial) and subMaterial ~= "" then
			snapshot.subMaterials[materialIndex] = subMaterial
		end
	end

	return snapshot
end

local summaryPortraitSequences = {
	"idle_subtle",
	"idle_all_01",
	"idle_all",
	"pose_standing_02",
	"pose_standing_01",
	"menu_walk",
	"idle"
}

local function HMCDPoseSummaryPortrait(entity)
	if not IsValid(entity) then return end

	for _, sequenceName in ipairs(summaryPortraitSequences) do
		local sequence = entity:LookupSequence(sequenceName)
		if isnumber(sequence) and sequence >= 0 then
			entity:ResetSequence(sequence)
			entity:SetCycle(0.08)
			entity:SetPlaybackRate(0)
			entity:SetupBones()
			return
		end
	end

	entity:SetSequence(0)
	entity:SetCycle(0)
	entity:SetPlaybackRate(0)
	entity:SetupBones()
end

local function HMCDFrameSummaryPortrait(panel)
	if not IsValid(panel) or not IsValid(panel.Entity) then return end

	local entity = panel.Entity
	entity:SetupBones()

	local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
	if headBone then
		local matrix = entity:GetBoneMatrix(headBone)
		if matrix then
			local headPos = matrix:GetTranslation()
			panel:SetLookAt(headPos + Vector(0, 0, -3))
			panel:SetCamPos(headPos + Vector(70, 0, 2))
			return
		end
	end

	local mins, maxs = entity:GetRenderBounds()
	local center = (mins + maxs) * 0.5
	panel:SetLookAt(center + Vector(0, 0, 12))
	panel:SetCamPos(center + Vector(74, 0, 12))
end

local function HMCDCreateSummaryPortrait(parent, snapshot, x, y, width, height)
	snapshot = snapshot or {}
	local model = isstring(snapshot.model) and snapshot.model ~= "" and snapshot.model or "models/player/group01/male_07.mdl"
	local portrait = vgui.Create("DModelPanel", parent)
	portrait:SetPos(x, y)
	portrait:SetSize(width, height)
	portrait:SetModel(model)
	portrait:SetFOV(27)
	portrait:SetMouseInputEnabled(false)
	portrait:SetKeyboardInputEnabled(false)
	portrait:SetPaintBackground(false)
	portrait:SetDirectionalLight(BOX_RIGHT, Color(95, 255, 145))
	portrait:SetDirectionalLight(BOX_LEFT, Color(35, 105, 60))
	portrait:SetDirectionalLight(BOX_FRONT, Color(185, 235, 200))
	portrait:SetAmbientLight(Color(48, 72, 56))

	function portrait:LayoutEntity(entity)
		if not IsValid(entity) then return end
		entity:SetAngles(Angle(0, 0, 0))
	end

	function portrait:PostDrawModel(entity)
		if not IsValid(entity) or not DrawAccesories then return end

		for _, accessory in ipairs(snapshot.accessories or {}) do
			local accessoryData = hg.Accessories and hg.Accessories[accessory]
			if accessoryData then
				DrawAccesories(entity, entity, accessory, accessoryData, false, true)
			end
		end
	end

	local entity = portrait.Entity
	if IsValid(entity) then
		entity:SetSkin(snapshot.skin or 0)
		entity:SetModelScale(snapshot.modelScale or 1, 0)
		entity:SetNWVector("PlayerColor", snapshot.playerColor or Vector(1, 1, 1))

		for bodygroup, value in pairs(snapshot.bodygroups or {}) do
			entity:SetBodygroup(bodygroup, value)
		end

		for materialIndex, materialName in pairs(snapshot.subMaterials or {}) do
			entity:SetSubMaterial(materialIndex, materialName)
		end

		HMCDPoseSummaryPortrait(entity)
		HMCDFrameSummaryPortrait(portrait)
	end

	return portrait
end

local function HMCDRemoveTraitorSummary()
	if IsValid(hmcdTraitorSummaryPanel) then
		hmcdTraitorSummaryPanel:Remove()
	end

	hmcdTraitorSummaryPanel = nil
	timer.Remove("HMCD_TraitorRoundSummary_Remove")
end

local function HMCDCreateTraitorSummary(summary)
	HMCDRemoveTraitorSummary()
	if not istable(summary) or #summary == 0 then return end

	HMCDRebuildSummaryFonts()

	local cardWidth = HMCDSummaryUI(248)
	local cardHeight = HMCDSummaryUI(218)
	local cardGap = HMCDSummaryUI(14)
	local sideMargin = HMCDSummaryUI(28)
	local bottomMargin = HMCDSummaryUI(20)
	local headerHeight = HMCDSummaryUI(32)
	local layoutX = sideMargin
	local layoutWidth = ScrW() - sideMargin * 2

	local maxPerRow = math.max(1, math.floor((layoutWidth + cardGap) / (cardWidth + cardGap)))
	local rowCount = math.ceil(#summary / maxPerRow)
	local startY = ScrH() - bottomMargin - rowCount * cardHeight - (rowCount - 1) * cardGap

	hmcdTraitorSummaryPanel = vgui.Create("EditablePanel")
	hmcdTraitorSummaryPanel:SetPos(0, 0)
	hmcdTraitorSummaryPanel:SetSize(ScrW(), ScrH())
	hmcdTraitorSummaryPanel:SetMouseInputEnabled(false)
	hmcdTraitorSummaryPanel:SetKeyboardInputEnabled(false)
	hmcdTraitorSummaryPanel:MoveToFront()

	local headerY = startY - headerHeight
	local topRowCards = math.min(maxPerRow, #summary)
	local topRowWidth = topRowCards * cardWidth + (topRowCards - 1) * cardGap
	local headerCenterX = layoutX + layoutWidth * 0.5
	hmcdTraitorSummaryPanel.Paint = function()
		local lineWidth = math.min(topRowWidth, HMCDSummaryUI(600))
		local lineX = headerCenterX - lineWidth * 0.5

		draw.SimpleTextOutlined(
			"TRAITOR CELL REVEALED",
			"HMCD_SummaryHeader",
			headerCenterX,
			headerY,
			Color(35, 255, 105),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP,
			math.max(1, HMCDSummaryUI(1)),
			Color(0, 8, 3, 235)
		)
		surface.SetDrawColor(22, 220, 88, 150)
		surface.DrawRect(lineX, headerY + HMCDSummaryUI(25), lineWidth, 1)
	end

	for index, info in ipairs(summary) do
		local row = math.floor((index - 1) / maxPerRow)
		local firstInRow = row * maxPerRow + 1
		local cardsInRow = math.min(maxPerRow, #summary - firstInRow + 1)
		local rowWidth = cardsInRow * cardWidth + (cardsInRow - 1) * cardGap
		local column = index - firstInRow
		local rowX = layoutX + (layoutWidth - rowWidth) * 0.5
		local cardX = math.floor(rowX + column * (cardWidth + cardGap))
		local cardY = startY + row * (cardHeight + cardGap)
		local portraitHeight = HMCDSummaryUI(132)
		local cut = HMCDSummaryUI(10)
		local roleBranch = string.sub(info.roleKey or "", -4) == "_soe" and "SOE" or ((info.roleKey or "") ~= "" and "STD" or "")
		local roleText = string.upper(info.roleName or "Traitor") .. (roleBranch ~= "" and " / " .. roleBranch or "")
		local nameText = HMCDFitSummaryText(info.characterName or "Unknown", "HMCD_SummaryName", cardWidth - HMCDSummaryUI(24))
		local nickText = HMCDFitSummaryText("PLAYER / " .. (info.nick or "Unknown"), "HMCD_SummarySmall", cardWidth - HMCDSummaryUI(24))
		local killsText = tostring(info.kills or 0) .. ((info.kills or 0) == 1 and " KILL" or " KILLS")
		local killsWidth
		surface.SetFont("HMCD_SummaryRole")
		killsWidth = surface.GetTextSize(killsText)
		roleText = HMCDFitSummaryText(roleText, "HMCD_SummaryRole", cardWidth - killsWidth - HMCDSummaryUI(42))

		local card = vgui.Create("DPanel", hmcdTraitorSummaryPanel)
		card:SetPos(cardX, cardY)
		card:SetSize(cardWidth, cardHeight)
		card:SetMouseInputEnabled(false)

		card.Paint = function(_, width, height)
			HMCDDrawSummaryCutBox(0, 0, width, height, cut, Color(2, 14, 7, 244), Color(22, 220, 88, 230))

			local bandInset = HMCDSummaryUI(2)
			local bandBottom = height - bandInset
			local bandCut = math.max(cut - bandInset, 1)
			draw.NoTexture()
			surface.SetDrawColor(3, 31, 14, 235)
			surface.DrawPoly({
				{x = bandInset, y = portraitHeight},
				{x = width - bandInset, y = portraitHeight},
				{x = width - bandInset, y = bandBottom - bandCut},
				{x = width - bandInset - bandCut, y = bandBottom},
				{x = bandInset + bandCut, y = bandBottom},
				{x = bandInset, y = bandBottom - bandCut}
			})

			local accentY = portraitHeight + HMCDSummaryUI(8)
			local accentBottom = height - cut - HMCDSummaryUI(3)
			surface.SetDrawColor(35, 255, 105, 230)
			surface.DrawRect(HMCDSummaryUI(8), accentY, HMCDSummaryUI(3), math.max(accentBottom - accentY, 0))

			draw.SimpleText(nameText, "HMCD_SummaryName", HMCDSummaryUI(18), portraitHeight + HMCDSummaryUI(8), Color(232, 255, 238), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(nickText, "HMCD_SummarySmall", HMCDSummaryUI(18), portraitHeight + HMCDSummaryUI(39), Color(148, 205, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(roleText, "HMCD_SummaryRole", HMCDSummaryUI(18), height - HMCDSummaryUI(25), Color(95, 255, 145), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(killsText, "HMCD_SummaryRole", width - HMCDSummaryUI(12), height - HMCDSummaryUI(25), Color(35, 255, 105), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

		card.PaintOver = function(_, width)
			local statusText = info.alive and "SURVIVED" or "NEUTRALIZED"
			local statusColor = info.alive and Color(35, 255, 105) or Color(255, 196, 96)
			draw.SimpleText("CELL " .. string.format("%02d", index), "HMCD_SummarySmall", HMCDSummaryUI(10), HMCDSummaryUI(8), Color(148, 205, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(statusText, "HMCD_SummarySmall", width - HMCDSummaryUI(10), HMCDSummaryUI(8), statusColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

		HMCDCreateSummaryPortrait(card, info.portrait or {}, HMCDSummaryUI(2), HMCDSummaryUI(2), cardWidth - HMCDSummaryUI(4), portraitHeight - HMCDSummaryUI(2))
	end

	timer.Create("HMCD_TraitorRoundSummary_Remove", 5.5, 1, HMCDRemoveTraitorSummary)
end

net.Receive("HMCD_TraitorRoundSummary", function()
	local summary = {}
	local count = net.ReadUInt(6)

	for index = 1, count do
		local traitorEntity = net.ReadEntity()
		summary[index] = {
			entity = traitorEntity,
			characterName = net.ReadString(),
			nick = net.ReadString(),
			roleKey = net.ReadString(),
			roleName = net.ReadString(),
			kills = net.ReadUInt(12),
			alive = net.ReadBool(),
			mainTraitor = net.ReadBool(),
			portrait = HMCDSnapshotTraitorPortrait(traitorEntity)
		}
	end

	hmcdTraitorRoundSummary = summary

	if IsValid(hmcdEndMenu) then
		HMCDCreateTraitorSummary(hmcdTraitorRoundSummary)
	end
end)

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

local hmcdReportGreen = Color(35, 255, 105)
local hmcdReportText = Color(232, 255, 238)
local hmcdReportMuted = Color(148, 205, 165)
local hmcdReportWarning = Color(189, 44, 0)
local hmcdReportBlue = Color(105, 180, 255)
local hmcdReportDead = Color(135, 150, 140)

local function HMCDGetRoundReportStatus(info)
	if info.isTraitor then
		local state = not info.alive and "DEAD" or (info.incapacitated and "DOWN" or "ALIVE")
		return "TRAITOR / " .. state, hmcdReportWarning, 0
	end

	if info.isGunner then
		local state = not info.alive and "DEAD" or (info.incapacitated and "DOWN" or "ALIVE")
		return "GUNNER / " .. state, hmcdReportBlue, 1
	end

	if info.alive and not info.incapacitated then
		return "SURVIVED", hmcdReportGreen, 2
	end

	if info.alive then
		return "INCAPACITATED", hmcdReportWarning, 3
	end

	return "DEAD", hmcdReportDead, 4
end

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function(traitor)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	HMCDRebuildSummaryFonts()
	hmcdEndMenu = vgui.Create("ZFrame")

	if !IsValid(hmcdEndMenu) then return end

	local players = {}
	local traitorCount = 0
	local survivorCount = 0

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local playerColor = ply:GetPlayerColor():ToColor()
		local info = {
			nick = ply:Nick(),
			name = ply:GetPlayerName(),
			isTraitor = ply.isTraitor,
			isGunner = ply.isGunner,
			incapacitated = ply.organism and (ply.organism.incapacitated or ply.organism.otrub),
			alive = ply:Alive(),
			col = Color(playerColor.r, playerColor.g, playerColor.b),
			steamid = ply:IsBot() and "BOT" or ply:SteamID64()
		}

		info.status, info.statusColor, info.sortRank = HMCDGetRoundReportStatus(info)
		players[#players + 1] = info

		if info.isTraitor then traitorCount = traitorCount + 1 end
		if info.alive and not info.incapacitated then survivorCount = survivorCount + 1 end
	end

	table.sort(players, function(left, right)
		if left.sortRank ~= right.sortRank then return left.sortRank < right.sortRank end
		return string.lower(left.name or left.nick or "") < string.lower(right.name or right.nick or "")
	end)

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local margin = HMCDSummaryUI(24)
	local sizeX = math.min(HMCDSummaryUI(640), ScrW() - margin * 2)
	local sizeY = math.min(HMCDSummaryUI(680), ScrH() - HMCDSummaryUI(270))
	sizeY = math.max(HMCDSummaryUI(390), sizeY)
	local posX = ScrW() - sizeX - margin
	local posY = HMCDSummaryUI(32)

	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:SetDraggable(false)
	hmcdEndMenu:SetColorBG(Color(2, 14, 7, 238))
	hmcdEndMenu:SetColorBR(Color(22, 220, 88, 230))
	hmcdEndMenu:SetBlurStrengh(1.5)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	local closeSize = HMCDSummaryUI(34)
	closebutton:SetPos(sizeX - closeSize - HMCDSummaryUI(14), HMCDSummaryUI(14))
	closebutton:SetSize(closeSize, closeSize)
	closebutton:SetText("")
	closebutton:SetTooltip("Close round report")

	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			local menu = hmcdEndMenu
			hmcdEndMenu = nil
			menu:Close()
		end

		HMCDRemoveTraitorSummary()
	end

	closebutton.Paint = function(self, width, height)
		local outline = self:IsHovered() and hmcdReportGreen or Color(22, 220, 88, 150)
		HMCDDrawSummaryCutBox(0, 0, width, height, HMCDSummaryUI(5), Color(2, 25, 11, 240), outline)
		draw.SimpleText("X", "HMCD_ReportName", width * 0.5, height * 0.5, hmcdReportText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	hmcdEndMenu.PaintOver = function(_, width)
		draw.SimpleText("ROUND REPORT", "HMCD_ReportTitle", HMCDSummaryUI(20), HMCDSummaryUI(15), hmcdReportGreen, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("HOMICIDE", "HMCD_ReportSmall", HMCDSummaryUI(21), HMCDSummaryUI(54), hmcdReportMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		surface.SetDrawColor(22, 220, 88, 140)
		surface.DrawRect(HMCDSummaryUI(18), HMCDSummaryUI(79), width - HMCDSummaryUI(36), 1)

		local traitorText = traitorCount == 1 and "1 TRAITOR IDENTIFIED" or traitorCount .. " TRAITORS IDENTIFIED"
		local survivorText = survivorCount == 1 and "1 SURVIVOR" or survivorCount .. " SURVIVORS"
		draw.SimpleText(traitorText, "HMCD_ReportSmall", HMCDSummaryUI(20), HMCDSummaryUI(89), hmcdReportWarning, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(survivorText, "HMCD_ReportSmall", width - HMCDSummaryUI(20), HMCDSummaryUI(89), hmcdReportGreen, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:Dock(FILL)
	DScrollPanel:DockMargin(HMCDSummaryUI(16), HMCDSummaryUI(104), HMCDSummaryUI(16), HMCDSummaryUI(16))

	local vbar = DScrollPanel:GetVBar()
	vbar:SetWide(HMCDSummaryUI(6))
	vbar.Paint = function(_, width, height)
		surface.SetDrawColor(2, 25, 11, 210)
		surface.DrawRect(0, 0, width, height)
	end
	vbar.btnGrip.Paint = function(_, width, height)
		surface.SetDrawColor(35, 255, 105, 185)
		surface.DrawRect(0, 0, width, height)
	end
	vbar.btnUp:SetTall(0)
	vbar.btnDown:SetTall(0)
	vbar.btnUp.Paint = function() end
	vbar.btnDown.Paint = function() end

	local rowWidth = sizeX - HMCDSummaryUI(44)
	local rowHeight = HMCDSummaryUI(50)

	for _, info in ipairs(players) do
		local but = vgui.Create("DButton")
		DScrollPanel:AddItem(but)

		but:SetTall(rowHeight)
		but:Dock(TOP)
		but:DockMargin(0, 0, HMCDSummaryUI(6), HMCDSummaryUI(5))
		but:SetText("")
		but:SetCursor(info.steamid == "BOT" and "arrow" or "hand")

		local nameText = HMCDFitSummaryText(info.name or "Unknown", "HMCD_ReportName", rowWidth * 0.40)
		local nickText = HMCDFitSummaryText(info.nick or "Unknown", "HMCD_ReportName", rowWidth * 0.25)
		local statusText = HMCDFitSummaryText(info.status or "UNKNOWN", "HMCD_ReportSmall", rowWidth * 0.30)

		but.Paint = function(self, width, height)
			local fill = self:IsHovered() and Color(8, 62, 28, 235) or Color(3, 31, 14, 225)
			local outline = self:IsHovered() and Color(35, 255, 105, 210) or Color(22, 220, 88, 80)
			HMCDDrawSummaryCutBox(0, 0, width, height, HMCDSummaryUI(7), fill, outline)

			surface.SetDrawColor(info.statusColor)
			surface.DrawRect(0, HMCDSummaryUI(7), HMCDSummaryUI(4), height - HMCDSummaryUI(14))

			draw.SimpleText(nameText, "HMCD_ReportName", HMCDSummaryUI(16), height * 0.5 + 1, Color(0, 0, 0, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(nameText, "HMCD_ReportName", HMCDSummaryUI(15), height * 0.5, info.col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(nickText, "HMCD_ReportName", width * 0.47, height * 0.5, hmcdReportText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(statusText, "HMCD_ReportSmall", width - HMCDSummaryUI(15), height * 0.5, info.statusColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		function but:DoClick()
			if info.steamid == "BOT" then chat.AddText(Color(255, 0, 0), "That's a bot.") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..info.steamid)
		end
	end

	HMCDCreateTraitorSummary(hmcdTraitorRoundSummary)

	return true
end

function MODE:RoundStart()
	HMCDRemoveTraitorSummary()
	hmcdTraitorRoundSummary = {}

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end

--\\
net.Receive("HMCD(StartPlayersRoleSelection)", function()
	local role = net.ReadString()

	hg.SelectPlayerRole(role, MODE.Type)
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
		--VGUI_HMCD_RolePanelList = vgui.Create("ZB_TraitorSelectionMenu")
		--VGUI_HMCD_RolePanelList:Center()
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

	MODE.RoleEndedChosingState = true
end)

net.Receive("HMCD(SetSubRole)", function(len, ply)
	lply.SubRole = net.ReadString()
end)

net.Receive("HMCD(SetProfession)", function()
	lply.Profession = net.ReadString()
end)
--

--CreateEndMenu()

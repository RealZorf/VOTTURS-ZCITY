if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("ZCityTraps.Use")
	util.AddNetworkString("ZCityTraps.Result")
end

ZCityTraps = ZCityTraps or {}

local traps = ZCityTraps

traps.ButtonClass = "ttt_traitor_button"
traps.ActivatorClass = "weapon_hg_trap_activator"
traps.MaxActivationRange = 3333
traps.Buttons = traps.Buttons or {}

function traps.RegisterButton(ent)
	if not IsValid(ent) or ent:GetClass() ~= traps.ButtonClass then return end

	traps.Buttons[ent] = true
end

function traps.UnregisterButton(ent)
	traps.Buttons[ent] = nil
end

function traps.HasButtons()
	for ent in pairs(traps.Buttons) do
		if IsValid(ent) then return true end

		traps.Buttons[ent] = nil
	end

	return false
end

local function getActiveMode()
	if not CurrentRound then return nil end

	return select(1, CurrentRound())
end

function traps.IsHomicideMode()
	local mode = getActiveMode()

	return istable(mode) and mode.name == "hmcd"
end

if SERVER then
	function traps.SendResult(ply, success, code)
		if not IsValid(ply) then return end

		net.Start("ZCityTraps.Result")
			net.WriteBool(success)
			net.WriteUInt(math.Clamp(code or 0, 0, 15), 4)
		net.Send(ply)
	end

	function traps.CanUseTrap(ply, trap)
		if not IsValid(trap) or trap:GetClass() ~= traps.ButtonClass or not traps.Buttons[trap] then
			return false, 1
		end

		if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then
			return false, 4
		end

		if not traps.IsHomicideMode() or not zb or zb.ROUND_STATE ~= 1 then
			return false, 4
		end

		if not ply.isTraitor then
			return false, 3
		end

		if ply.fake or IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.fake or ply.organism.otrub)) then
			return false, 7
		end

		local weapon = ply:GetActiveWeapon()
		if not IsValid(weapon) or weapon:GetClass() ~= traps.ActivatorClass then
			return false, 5
		end

		if not trap.IsUsable or not trap:IsUsable() then
			return false, 2
		end

		local maxRange = math.max(tonumber(weapon.ActivationRange) or traps.MaxActivationRange, 1)
		if ply:GetPos():DistToSqr(trap:GetPos()) > maxRange * maxRange then
			return false, 6
		end

		local allowed = hook.Run("ZCityCanUseTrap", trap, ply)
		if allowed == false then
			return false, 2
		end

		return true, 0
	end

	function traps.GiveActivator(ply)
		if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
		if not ply.isTraitor or not traps.IsHomicideMode() or not traps.HasButtons() then return false end
		if ply:HasWeapon(traps.ActivatorClass) then return true end

		return IsValid(ply:Give(traps.ActivatorClass))
	end

	local function seedServerButtons()
		for _, trap in ipairs(ents.FindByClass(traps.ButtonClass)) do
			traps.RegisterButton(trap)
		end
	end

	hook.Add("InitPostEntity", "ZCityTraps.SeedServerButtons", seedServerButtons)
	hook.Add("PostCleanupMap", "ZCityTraps.ReseedServerButtons", function()
		timer.Simple(0, seedServerButtons)
	end)

	net.Receive("ZCityTraps.Use", function(_, ply)
		if not IsValid(ply) then return end

		local now = CurTime()
		if (ply.ZCityTrapNextRequest or 0) > now then return end
		ply.ZCityTrapNextRequest = now + 0.15

		local trap = net.ReadEntity()
		if not IsValid(trap) or not trap.ActivateTrap then
			traps.SendResult(ply, false, 1)
			return
		end

		trap:ActivateTrap(ply)
	end)

	concommand.Add("zc_traps_status", function(ply)
		if IsValid(ply) and not ply:IsAdmin() then return end

		local total = 0
		local ready = 0
		for trap in pairs(traps.Buttons) do
			if not IsValid(trap) then
				traps.Buttons[trap] = nil
				continue
			end

			total = total + 1
			if trap.IsUsable and trap:IsUsable() then
				ready = ready + 1
			end
		end

		local message = string.format("%d registered, %d ready, map=%s", total, ready, game.GetMap())
		if IsValid(ply) then
			ply:PrintMessage(HUD_PRINTCONSOLE, message)
		else
			print(message)
		end
	end)

	concommand.Add("zc_traps_give", function(ply)
		if not IsValid(ply) or not ply:IsAdmin() then return end

		local given = traps.GiveActivator(ply)
		ply:PrintMessage(HUD_PRINTCONSOLE, given and "Activator granted." or "Activator not granted; check the active mode, role, and registered trap count.")
	end)
else
	local readyColor = Color(28, 255, 108)
	local cooldownColor = Color(255, 184, 46)
	local lockedColor = Color(130, 143, 136)
	local panelColor = Color(2, 18, 10, 228)
	local panelInnerColor = Color(1, 10, 6, 210)
	local whiteColor = Color(234, 255, 242)
	local mutedColor = Color(139, 185, 155)
	local failureColor = Color(255, 82, 82)
	local focusEnt
	local attackWasDown = false
	local useWasDown = false
	local nextRequest = 0
	local resultText = ""
	local resultColor = readyColor
	local resultUntil = 0

	surface.CreateFont("ZCityTrap_Title", {
		font = "Bahnschrift",
		size = 19,
		weight = 850,
		extended = true,
	})

	surface.CreateFont("ZCityTrap_Text", {
		font = "Bahnschrift",
		size = 15,
		weight = 650,
		extended = true,
	})

	surface.CreateFont("ZCityTrap_Small", {
		font = "Bahnschrift",
		size = 12,
		weight = 700,
		extended = true,
	})

	local function isActivatorActive()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() or not ply.isTraitor then return false end

		local weapon = ply:GetActiveWeapon()

		return IsValid(weapon) and weapon:GetClass() == traps.ActivatorClass
	end

	local function getTrapState(trap)
		if not IsValid(trap) or not trap.IsUsable then
			return lockedColor, "UNAVAILABLE"
		end

		if trap:GetLocked() then
			return lockedColor, "LOCKED"
		end

		local remaining = math.max(trap:GetNextUseTime() - CurTime(), 0)
		if remaining > 0 then
			return cooldownColor, string.format("RECHARGING  %.1fs", remaining)
		end

		return readyColor, "READY  LMB / E"
	end

	local function drawCutPanel(x, y, w, h, cut, color)
		draw.NoTexture()
		surface.SetDrawColor(color)
		surface.DrawPoly({
			{x = x + cut, y = y},
			{x = x + w - cut, y = y},
			{x = x + w, y = y + cut},
			{x = x + w, y = y + h - cut},
			{x = x + w - cut, y = y + h},
			{x = x + cut, y = y + h},
			{x = x, y = y + h - cut},
			{x = x, y = y + cut},
		})
	end

	local function fitText(text, font, maxWidth)
		surface.SetFont(font)
		if surface.GetTextSize(text) <= maxWidth then return text end

		local suffix = "..."
		while #text > 1 and surface.GetTextSize(text .. suffix) > maxWidth do
			text = string.sub(text, 1, -2)
		end

		return text .. suffix
	end

	local function drawMarker(x, y, color, focused, alpha)
		local size = focused and 13 + math.sin(CurTime() * 6) * 1.5 or 8

		draw.NoTexture()
		surface.SetDrawColor(color.r, color.g, color.b, alpha)
		surface.DrawPoly({
			{x = x, y = y - size},
			{x = x + size, y = y},
			{x = x, y = y + size},
			{x = x - size, y = y},
		})

		surface.SetDrawColor(whiteColor.r, whiteColor.g, whiteColor.b, focused and 210 or 105)
		surface.DrawOutlinedRect(x - size - 4, y - size - 4, size * 2 + 8, size * 2 + 8, 1)
	end

	local function drawFocusedCard(trap, screenPos, distance)
		local color, status = getTrapState(trap)
		local description = trap:GetDescription()
		if not isstring(description) or description == "" or description == "?" then
			description = "ENVIRONMENTAL TRAP"
		end

		description = string.upper(description)
		description = fitText(description, "ZCityTrap_Title", 304)

		surface.SetFont("ZCityTrap_Title")
		local titleWidth = surface.GetTextSize(description)
		local width = math.Clamp(titleWidth + 34, 218, 338)
		local height = 69
		local x = math.Clamp(screenPos.x + 26, 12, ScrW() - width - 12)
		local y = math.Clamp(screenPos.y - height * 0.5, 12, ScrH() - height - 12)

		drawCutPanel(x, y, width, height, 8, panelColor)
		surface.SetDrawColor(color)
		surface.DrawOutlinedRect(x, y, width, height, 1)
		surface.DrawRect(x + 9, y + 10, 3, height - 20)
		surface.SetDrawColor(panelInnerColor)
		surface.DrawRect(x + 17, y + 35, width - 28, 1)

		draw.SimpleText(description, "ZCityTrap_Title", x + 21, y + 10, whiteColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(status, "ZCityTrap_Small", x + 21, y + 44, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(string.format("%dm", math.max(math.floor(distance * 0.01905 + 0.5), 1)), "ZCityTrap_Small", x + width - 12, y + 44, mutedColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	end

	local function drawTrapHUD()
		if not isActivatorActive() then
			focusEnt = nil
			return
		end

		local ply = LocalPlayer()
		local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
		local rangeSqr = traps.MaxActivationRange * traps.MaxActivationRange
		local bestEnt
		local bestScreenDistance = 90 * 90
		local visible = {}

		for trap in pairs(traps.Buttons) do
			if not IsValid(trap) then
				traps.Buttons[trap] = nil
				continue
			end

			local distanceSqr = ply:GetPos():DistToSqr(trap:GetPos())
			if distanceSqr > rangeSqr then continue end

			local screenPos = trap:GetPos():ToScreen()
			if not screenPos.visible then continue end
			if screenPos.x < -32 or screenPos.y < -32 or screenPos.x > ScrW() + 32 or screenPos.y > ScrH() + 32 then continue end

			local screenDistance = (screenPos.x - centerX) ^ 2 + (screenPos.y - centerY) ^ 2
			visible[#visible + 1] = {
				ent = trap,
				pos = screenPos,
				distance = math.sqrt(distanceSqr),
			}

			if screenDistance < bestScreenDistance then
				bestScreenDistance = screenDistance
				bestEnt = trap
			end
		end

		focusEnt = bestEnt

		for _, marker in ipairs(visible) do
			local color = select(1, getTrapState(marker.ent))
			local focused = marker.ent == focusEnt
			local alpha = focused and 245 or math.Clamp(210 - marker.distance / traps.MaxActivationRange * 110, 70, 200)

			drawMarker(marker.pos.x, marker.pos.y, color, focused, alpha)
			if focused then
				drawFocusedCard(marker.ent, marker.pos, marker.distance)
			end
		end

		if resultUntil > CurTime() then
			draw.SimpleText(resultText, "ZCityTrap_Text", centerX, centerY + 72, resultColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local function requestFocusedTrap()
		if not IsValid(focusEnt) or nextRequest > CurTime() then return end

		nextRequest = CurTime() + 0.2

		net.Start("ZCityTraps.Use")
			net.WriteEntity(focusEnt)
			net.SendToServer()
	end

	hook.Add("InitPostEntity", "ZCityTraps.SeedButtons", function()
		for _, trap in ipairs(ents.FindByClass(traps.ButtonClass)) do
			traps.RegisterButton(trap)
		end
	end)

	hook.Add("HUDPaint", "ZCityTraps.Draw", drawTrapHUD)

	hook.Add("Think", "ZCityTraps.Input", function()
		if not isActivatorActive() or gui.IsGameUIVisible() or vgui.CursorVisible() then
			attackWasDown = false
			useWasDown = false
			return
		end

		local ply = LocalPlayer()
		local attackDown = ply:KeyDown(IN_ATTACK)
		local useDown = ply:KeyDown(IN_USE)

		if (attackDown and not attackWasDown) or (useDown and not useWasDown) then
			requestFocusedTrap()
		end

		attackWasDown = attackDown
		useWasDown = useDown
	end)

	local resultMessages = {
		[1] = "INVALID TRAP",
		[2] = "TRAP UNAVAILABLE",
		[3] = "ACCESS DENIED",
		[4] = "NETWORK OFFLINE",
		[5] = "ACTIVATOR NOT EQUIPPED",
		[6] = "OUT OF RANGE",
		[7] = "INCAPACITATED",
	}

	net.Receive("ZCityTraps.Result", function()
		local success = net.ReadBool()
		local code = net.ReadUInt(4)

		resultText = success and "TRAP ACTIVATED" or (resultMessages[code] or "ACTIVATION FAILED")
		resultColor = success and readyColor or failureColor
		resultUntil = CurTime() + 1.2

		surface.PlaySound(success and "buttons/button24.wav" or "buttons/button10.wav")
	end)
end

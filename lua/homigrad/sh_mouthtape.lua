local HEAD_BONE = "ValveBiped.Bip01_Head1"
local HEAD_DIST_SQR = 14 * 14
local VOICE_BITS = {"vo/", "voice", "scream", "yell", "pain", "moan", "groan", "phrase", "death", "mercenary/", "zcitysnd/male", "zcitysnd/female"}

if SERVER then
	hg.MouthCutting = hg.MouthCutting or {}

	local function SprayMouth(body)
		local id = body:LookupAttachment("eyes")
		if not id or id <= 0 then return end
		local att = body:GetAttachment(id)
		if not att then return end
		local fwd = att.Ang:Forward()
		local pos = att.Pos - att.Ang:Up() * 3.3
		local tr = util.TraceLine({
			start = pos + fwd * 8,
			endpos = pos - fwd * 4,
			filter = function(hit) return hit == body end,
			mask = MASK_SHOT,
		})
		if not tr.Hit or tr.Entity ~= body then return end
		util.Decal("hmcd_jackatape", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
		return true
	end

	local function ClearMouthTape(ply, wipe)
		if not IsValid(ply) then return end
		local idx = ply:EntIndex()
		ply:SetNWBool("MouthTaped", false)
		timer.Remove("MouthTape_" .. idx)
		timer.Remove("MouthTapeUp_" .. idx)
		if not wipe then return end
		ply:RemoveAllDecals()
		local body = hg.GetCurrentCharacter(ply)
		if IsValid(body) and body ~= ply then body:RemoveAllDecals() end
	end

	local function TrySpray(ply)
		if not IsValid(ply) or not ply:Alive() or not ply:GetNWBool("MouthTaped") then return true end
		local body = hg.GetCurrentCharacter(ply)
		if not IsValid(body) then return end
		if body == ply then ply:RemoveAllDecals() end
		return SprayMouth(body)
	end

	function hg.MouthTapeSpray(ply)
		local idx = ply:EntIndex()
		if not TrySpray(ply) then
			local timerId = "MouthTape_" .. idx
			timer.Create(timerId, 0.15, 8, function()
				if TrySpray(ply) then timer.Remove(timerId) end
			end)
		end

		timer.Create("MouthTapeUp_" .. idx, 1.2, 1, function()
			if not IsValid(ply) or not ply:GetNWBool("MouthTaped") or IsValid(ply.FakeRagdoll) then return end
			ply:RemoveAllDecals()
			SprayMouth(ply)
		end)
	end

	function hg.MouthTapeCut(ply, ent, hitPos)
		local victim = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
		if not IsValid(victim) or victim == ply or not victim:Alive() or not victim:GetNWBool("MouthTaped") then return end
		local bone = ent:LookupBone(HEAD_BONE)
		if not bone then return end
		local head = ent:GetBonePosition(bone)
		if not head or hitPos:DistToSqr(head) > HEAD_DIST_SQR then return end

		local now = CurTime()
		local cut = ply.MouthCut
		if not cut or cut.victim ~= victim then
			cut = {victim = victim, start = now, snd = 0}
			ply.MouthCut = cut
		end
		cut.t = now
		hg.MouthCutting[ply] = true

		local frac = math.min((now - cut.start) / 2.5, 1)
		if not ply.MouthCutFrac or frac - ply.MouthCutFrac >= 0.03 or frac >= 1 then
			ply.MouthCutFrac = frac
			ply:SetNWFloat("MouthCut", frac)
		end

		if now >= cut.snd then
			cut.snd = now + 0.6
			ent:EmitSound("tape_friction" .. math.random(3) .. ".mp3", 60)
		end

		if frac >= 1 then
			hg.MouthCutting[ply] = nil
			ply.MouthCut = nil
			ply.MouthCutFrac = nil
			ply:SetNWFloat("MouthCut", 0)
			ClearMouthTape(victim, true)
			ent:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 65)
		end
		return true
	end

	hook.Add("Think", "MouthTapeCut", function()
		if not next(hg.MouthCutting) then return end
		local now = CurTime()
		for ply in pairs(hg.MouthCutting) do
			local cut = IsValid(ply) and ply.MouthCut
			if not cut or now - cut.t > 0.2 then
				hg.MouthCutting[ply] = nil
				if IsValid(ply) then
					ply.MouthCut = nil
					ply.MouthCutFrac = nil
					if ply:GetNWFloat("MouthCut") > 0 then ply:SetNWFloat("MouthCut", 0) end
				end
			end
		end
	end)

	hook.Add("Fake", "MouthTape", function(ply)
		if ply:GetNWBool("MouthTaped") then hg.MouthTapeSpray(ply) end
	end)

	hook.Add("Player Getup", "MouthTape", function(ply)
		if ply:GetNWBool("MouthTaped") then hg.MouthTapeSpray(ply) end
	end)

	hook.Add("Player Spawn", "MouthTape", function(ply)
		if ply:GetNWBool("MouthTaped") then ClearMouthTape(ply, true) end
	end)

	hook.Add("PostPlayerDeath", "MouthTape", function(ply)
		ClearMouthTape(ply, false)
	end)

	hook.Add("PostCleanupMap", "MouthTape", function()
		for _, ply in player.Iterator() do
			if ply:GetNWBool("MouthTaped") then ClearMouthTape(ply, true) end
		end
	end)

	hook.Add("HG_PlayerCanHearPlayersVoice", "MouthTape", function(listener, talker)
		if IsValid(talker) and talker:GetNWBool("MouthTaped") then return false, false end
	end, -2)

	hook.Add("HG_CanDoPhrase", "MouthTape", function(ply)
		if IsValid(ply) and ply:GetNWBool("MouthTaped") then return true end
	end)

	hook.Add("HG_PlayerSay", "MouthTape", function(ply, txt)
		if not IsValid(ply) or not ply:GetNWBool("MouthTaped") then return end
		local text = txt[1]
		if not isstring(text) or text == "" then return end

		local ok, res = pcall(function()
			local out = {}
			for _, cp in utf8.codes(text) do
				local letter = (cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122)
					or (cp >= 0xC0 and cp <= 0x24F and cp ~= 0xD7 and cp ~= 0xF7)
					or (cp >= 0x370 and cp <= 0x3FF)
					or (cp >= 0x400 and cp <= 0x52F)
				if letter then
					local upper = (cp >= 65 and cp <= 90) or (cp >= 0xC0 and cp <= 0xDE and cp ~= 0xD7)
						or (cp >= 0x391 and cp <= 0x3A9) or (cp >= 0x400 and cp <= 0x42F)
					local ch = math.random(2) == 1 and "m" or "h"
					out[#out + 1] = upper and string.upper(ch) or ch
				else
					out[#out + 1] = utf8.char(cp)
				end
			end
			return table.concat(out)
		end)

		txt[1] = ok and res or string.gsub(text, "%a", function(c)
			local ch = math.random(2) == 1 and "m" or "h"
			return string.match(c, "%u") and string.upper(ch) or ch
		end)
	end, 10)
end

if CLIENT then
	local accent = Color(35, 225, 110)
	local panel = Color(20, 22, 21, 220)
	local border = Color(86, 94, 90, 200)
	local text = Color(236, 238, 236)

	surface.CreateFont("MouthTape_Title", {
		font = "Bahnschrift",
		size = 17,
		weight = 600,
		antialias = true
	})

	hook.Add("HUDPaint", "MouthTape", function()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		local frac = math.Clamp(lp:GetNWFloat("MouthCut"), 0, 1)
		if frac <= 0 then return end

		local w, h = 220, 34
		local x = ScrW() * 0.5 - w * 0.5
		local y = ScrH() * 0.70

		surface.SetDrawColor(panel)
		surface.DrawRect(x, y, w, h)
		surface.SetDrawColor(border)
		surface.DrawOutlinedRect(x, y, w, h, 1)

		local barX, barY = x + 5, y + 23
		local barW, barH = w - 10, 5

		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(barX, barY, barW, barH)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 230)
		surface.DrawRect(barX, barY, barW * frac, barH)
		draw.SimpleText("Cutting tape", "MouthTape_Title", ScrW() * 0.5, y + 4, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end)
end

hook.Add("EntityEmitSound", "MouthTape", function(data)
	local ent = data.Entity
	if not IsValid(ent) then return end

	local voice = data.Channel == CHAN_VOICE
	if not voice then
		local name = string.lower(data.SoundName or "")
		for i = 1, #VOICE_BITS do
			if string.find(name, VOICE_BITS[i], 1, true) then
				voice = true
				break
			end
		end
	end
	if not voice then return end

	local owner = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
	if not IsValid(owner) or not owner:GetNWBool("MouthTaped") then return end
	return false
end)

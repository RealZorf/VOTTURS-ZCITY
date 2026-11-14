local COOLDOWN = 5
local original
local nextPlay = {}

local function StopAnim(ply)
	if not IsValid(ply) or not ply.hgWOSStop then return end
	ply.hgWOSStop = nil
	ply.hgWOSPos = nil
	nextPlay[ply] = CurTime() + COOLDOWN
	if original then original(ply, "wos_uap", {"stop"}, "stop") end
end

local function WrappedUAP(ply, cmd, args, argStr)
	local anim = string.lower(string.Trim(tostring(args and args[1] or "")))
	if anim == "" or anim == "stop" then
		if IsValid(ply) and ply.hgWOSStop then
			StopAnim(ply)
			return
		end
		return original and original(ply, cmd, args, argStr)
	end
	if not IsValid(ply) then return end

	if ply.hgWOSStop or (nextPlay[ply] or 0) > CurTime() then
		if CLIENT and ply == LocalPlayer() then surface.PlaySound("buttons/button10.wav") end
		return
	end

	local ret = original and original(ply, cmd, args, argStr)

	local seq = -1
	local prefixes = {"wos_uap_", "wos_uap_fortnite_", "wos_uap_mocap_", "wos_uap_tf2_", "wos_uap_other_", ""}
	for i = 1, #prefixes do
		seq = ply:LookupSequence(prefixes[i] .. anim)
		if seq >= 0 then break end
	end

	local dur = seq >= 0 and ply:SequenceDuration(seq) or 0
	if not dur or dur < 0.05 then dur = 4 end
	ply.hgWOSStop = CurTime() + dur
	ply.hgWOSPos = ply:GetPos()

	return ret
end

timer.Create("HG_WOS_AnimCooldown", 0.5, 40, function()
	local cur = concommand.GetTable()["wos_uap"]
	if not cur or cur == WrappedUAP then
		if cur == WrappedUAP then timer.Remove("HG_WOS_AnimCooldown") end
		return
	end
	original = cur
	concommand.Add("wos_uap", WrappedUAP)
	timer.Remove("HG_WOS_AnimCooldown")
end)

hook.Add("UpdateAnimation", "HG_WOS_AnimOnce", function(ply)
	if not ply.hgWOSStop then return end

	local moved = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) or ply:KeyDown(IN_JUMP)
	if not moved and ply.hgWOSPos then moved = ply:GetPos():DistToSqr(ply.hgWOSPos) > 1 end
	if moved or CurTime() >= ply.hgWOSStop then
		StopAnim(ply)
		return
	end

	for slot = 0, 6 do
		local layer = ply:GetLayerSequence(slot)
		if layer and layer >= 0 then
			local n = ply:GetSequenceName(layer)
			if n and string.sub(n, 1, 8) == "wos_uap_" then ply:SetLayerLooping(slot, false) end
		end
	end

	local n = ply:GetSequenceName(ply:GetSequence())
	if n and string.sub(n, 1, 8) == "wos_uap_" and ply:GetCycle() > 0.99 then
		ply:SetCycle(0.99)
	end
end)

if SERVER then
	hook.Add("PlayerDisconnected", "HG_WOS_AnimCooldown", function(ply)
		nextPlay[ply] = nil
	end)
end

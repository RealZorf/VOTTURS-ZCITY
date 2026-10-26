if SERVER then
	CreateConVar("hg_wos_anim_cooldown", "2", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Seconds between wOS animations (radial and wos_uap). Server only.", 0.25, 30)
end

local original
local nextPlay = {}

local function WrappedUAP(ply, cmd, args, argStr)
	local anim = string.lower(string.Trim(tostring(args and args[1] or "")))
	if anim == "" or anim == "stop" then
		return original and original(ply, cmd, args, argStr)
	end
	if not IsValid(ply) then return end

	local now = CurTime()
	if (nextPlay[ply] or 0) > now then
		if CLIENT and ply == LocalPlayer() then
			surface.PlaySound("buttons/button10.wav")
		end
		return
	end

	local cv = GetConVar("hg_wos_anim_cooldown")
	nextPlay[ply] = now + math.max(0.25, cv and cv:GetFloat() or 2)
	return original and original(ply, cmd, args, argStr)
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

if SERVER then
	hook.Add("PlayerDisconnected", "HG_WOS_AnimCooldown", function(ply)
		nextPlay[ply] = nil
	end)
end

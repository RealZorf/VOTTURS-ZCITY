if SERVER then
	util.AddNetworkString("hg_lean")

	net.Receive("hg_lean", function(_, ply)
		if not IsValid(ply) or not ply:Alive() then return end

		local active = net.ReadBool()
		local target = math.Clamp(net.ReadFloat(), -1.5, 1.5)

		ply.hglean = active and target or nil
	end)

	hook.Add("PlayerDeath", "hg_lean", function(ply)
		ply.hglean = nil
	end)
end

function hg.IsLeaning(ply)
	return IsValid(ply) and ply.hglean ~= nil
end

if CLIENT then
	local active = false
	local target = 0
	local sendcd = 0
	local senttarget, sentactive = 0, false

	function hg.LeanActive()
		return active
	end

	concommand.Add("+hg_lean", function() active = true end)
	concommand.Add("-hg_lean", function()
		active = false
		target = 0
	end)

	hook.Add("Think", "hg_lean", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then
			active = false
			target = 0
			return
		end

		if active then
			local ft = FrameTime() * 5
			if input.IsKeyDown(KEY_Q) then target = math.max(target - ft, -1.4) end
			if input.IsKeyDown(KEY_E) then target = math.min(target + ft, 1.4) end
		end

		ply.hglean = active and target or nil

		if CurTime() > sendcd and (active ~= sentactive or math.abs(target - senttarget) > 0.01) then
			net.Start("hg_lean")
				net.WriteBool(active)
				net.WriteFloat(target)
			net.SendToServer()
			sendcd = CurTime() + 0.05
			sentactive = active
			senttarget = target
		end
	end)
end

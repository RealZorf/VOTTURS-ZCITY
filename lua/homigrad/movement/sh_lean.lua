function hg.CanLean(ply)
	if not IsValid(ply) or not ply:Alive() then return false end
	if IsValid(ply.FakeRagdoll) then return false end
	if ply:InVehicle() then return false end
	return true
end

function hg.IsLootSearchEntity(ent)
	if not IsValid(ent) then return false end

	local class = ent:GetClass()
	if class == "zbox_lootbox" then return true end

	if hg.GetLootBoxData and hg.GetLootBoxData(ent) then return true end

	if ent:GetNetVar("Inventory") then
		if ent:IsPlayer() then
			return IsValid(ent.FakeRagdoll)
		end
		return true
	end

	return false
end

function hg.ClearPlayerLean(ply)
	if not IsValid(ply) then return end

	ply.hglean = nil

	if SERVER then
		ply:SetNWBool("HG_LeanActive", false)
	end
end

function hg.SetPlayerLean(ply, active, target)
	if not IsValid(ply) then return false end

	if not active or not hg.CanLean(ply) then
		hg.ClearPlayerLean(ply)
		return false
	end

	ply.hglean = math.Clamp(target or 0, -1.5, 1.5)

	if SERVER then
		ply:SetNWBool("HG_LeanActive", true)
		ply:SetNWFloat("HG_LeanTarget", ply.hglean)
	end

	return true
end

function hg.IsLeaning(ply)
	return IsValid(ply) and ply.hglean ~= nil
end

if SERVER then
	util.AddNetworkString("hg_lean")

	net.Receive("hg_lean", function(_, ply)
		if not IsValid(ply) then return end

		local active = net.ReadBool()
		local target = net.ReadFloat()

		if not active then
			hg.ClearPlayerLean(ply)
			return
		end

		if not hg.CanLean(ply) then
			hg.ClearPlayerLean(ply)
			return
		end

		hg.SetPlayerLean(ply, true, target)
	end)

	local function clearLean(ply)
		hg.ClearPlayerLean(ply)
	end

	hook.Add("PlayerDeath", "hg_lean", clearLean)
	hook.Add("PlayerSpawn", "hg_lean", clearLean)
	hook.Add("Fake", "hg_lean", clearLean)
	hook.Add("Fake Up", "hg_lean", clearLean)

	hook.Add("PlayerUse", "hg_lean", function(ply, ent)
		if hg.IsLeaning(ply) and hg.IsLootSearchEntity(ent) then
			return false
		end
	end)

	hook.Add("ZB_CanLootInventory", "hg_lean", function(ply)
		if hg.IsLeaning(ply) then
			return false
		end
	end)
end

if CLIENT then
	local active = false
	local target = 0
	local sendcd = 0
	local senttarget, sentactive = 0, false

	function hg.LeanActive()
		return active
	end

	local function setLeanActive(state)
		active = state
		if not state then
			target = 0
			local ply = LocalPlayer()
			if IsValid(ply) then
				ply.hglean = nil
			end
		end
	end

	local function sendLeanState()
		net.Start("hg_lean")
			net.WriteBool(active)
			net.WriteFloat(target)
		net.SendToServer()
		sendcd = CurTime() + 0.05
		sentactive = active
		senttarget = target
	end

	local function setLeanOff()
		if not active and LocalPlayer().hglean == nil then return end
		setLeanActive(false)
		sendLeanState()
	end

	local function tryToggleLean()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		if active then
			setLeanOff()
			return
		end

		if not hg.CanLean(ply) then return end

		setLeanActive(true)
		sendLeanState()
	end

	concommand.Add("hg_lean", tryToggleLean)
	concommand.Add("+hg_lean", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not hg.CanLean(ply) or active then return end
		setLeanActive(true)
		sendLeanState()
	end)
	concommand.Add("-hg_lean", setLeanOff)

	hook.Add("Fake", "hg_lean", function(ply)
		if ply ~= LocalPlayer() then return end
		setLeanActive(false)
	end)

	hook.Add("FakeUp", "hg_lean", function(ply)
		if ply ~= LocalPlayer() then return end
		setLeanActive(false)
	end)

	hook.Add("Think", "hg_lean", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		if not hg.CanLean(ply) then
			if active or ply.hglean ~= nil then
				setLeanActive(false)
				if CurTime() > sendcd then
					net.Start("hg_lean")
						net.WriteBool(false)
						net.WriteFloat(0)
					net.SendToServer()
					sendcd = CurTime() + 0.05
					sentactive = false
					senttarget = 0
				end
			end
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

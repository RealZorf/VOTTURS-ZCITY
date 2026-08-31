if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("HMCD_LMSDelisleTiming")
end

local function ScaleDeadline(deadline, startedAt, multiplier)
	if not isnumber(deadline) or deadline <= startedAt then return deadline end

	return startedAt + (deadline - startedAt) * multiplier
end

local patchGeneration = {}

local function PatchDelisleReload()
	local stored = weapons.GetStored("weapon_delisle")
	if not stored or not isfunction(stored.Reload) then return false end
	if stored.HMCDLMSPatchGeneration == patchGeneration and stored.Reload == stored.HMCDLMSReloadWrapper then return true end

	if stored.HMCDLMSReloadWrapper and stored.Reload == stored.HMCDLMSReloadWrapper and isfunction(stored.HMCDLMSOriginalReload) then
		stored.Reload = stored.HMCDLMSOriginalReload
	end

	local originalReload = stored.Reload
	local wrapper = function(self, ...)
		local multiplier = self.GetLMSFinalStandMultiplier and self:GetLMSFinalStandMultiplier() or 1
		if multiplier >= 1 then return originalReload(self, ...) end

		local startedAt = CurTime()
		local originalReloadTime = self.ReloadTime
		local primaryNext = self.Primary and self.Primary.Next
		local reloadCooldown = self.reloadCoolDown
		local shootGate = self:GetNetVar("shootgunReload", 0)
		local wasCocking = self.drawBullet == false

		if isnumber(originalReloadTime) then
			self.ReloadTime = originalReloadTime * multiplier
		end

		local result = originalReload(self, ...)
		self.ReloadTime = originalReloadTime

		local newShootGate = self:GetNetVar("shootgunReload", 0)
		local timingChanged = newShootGate ~= shootGate and newShootGate > startedAt
		if timingChanged then
			newShootGate = ScaleDeadline(newShootGate, startedAt, multiplier)
			self.HMCDLMSFinalStandGate = newShootGate
			if SERVER then
				self:SetNetVar("shootgunReload", newShootGate)
			end
		end

		if wasCocking and timingChanged then
			if self.Primary and self.Primary.Next ~= primaryNext then
				self.Primary.Next = ScaleDeadline(self.Primary.Next, startedAt, multiplier)
			end
			if self.reloadCoolDown ~= reloadCooldown then
				self.reloadCoolDown = ScaleDeadline(self.reloadCoolDown, startedAt, multiplier)
			end
			self:PlayAnim(self.AnimList["cycle"] or "cycle", multiplier, false, nil, false, true)
		end

		if SERVER and timingChanged then
			net.Start("HMCD_LMSDelisleTiming")
				net.WriteEntity(self)
				net.WriteFloat(self.Primary and self.Primary.Next or 0)
				net.WriteFloat(self.reloadCoolDown or 0)
				net.WriteFloat(newShootGate)
			net.Broadcast()
		end

		return result
	end

	stored.HMCDLMSOriginalReload = originalReload
	stored.HMCDLMSReloadWrapper = wrapper
	stored.HMCDLMSPatchGeneration = patchGeneration
	stored.Reload = wrapper

	return true
end

local function QueueDelislePatch()
	if PatchDelisleReload() then return end

	timer.Create("HMCD_LMSFinalStand_PatchDelisleRetry", 0.25, 40, function()
		if PatchDelisleReload() then
			timer.Remove("HMCD_LMSFinalStand_PatchDelisleRetry")
		end
	end)
end

QueueDelislePatch()
hook.Add("Initialize", "HMCD_LMSFinalStand_PatchDelisle", QueueDelislePatch)
hook.Add("InitPostEntity", "HMCD_LMSFinalStand_PatchDelisle", QueueDelislePatch)
hook.Add("OnReloaded", "HMCD_LMSFinalStand_PatchDelisle", QueueDelislePatch)
hook.Add("OnEntityCreated", "HMCD_LMSFinalStand_PatchDelisle", function(ent)
	if ent:GetClass() == "weapon_delisle" then
		QueueDelislePatch()
	end
end)

if CLIENT then
	net.Receive("HMCD_LMSDelisleTiming", function()
		local wep = net.ReadEntity()
		local primaryNext = net.ReadFloat()
		local reloadCooldown = net.ReadFloat()
		local shootGate = net.ReadFloat()
		if not IsValid(wep) then return end

		if wep.Primary then
			wep.Primary.Next = primaryNext
		end
		wep.reloadCoolDown = reloadCooldown
		wep.HMCDLMSFinalStandGate = shootGate
	end)

	hook.Add("Think", "HMCD_LMSFinalStand_DelislePrediction", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_delisle" or not wep.Primary then return end

		local shootGate = wep.HMCDLMSFinalStandGate
		if not isnumber(shootGate) then return end

		if shootGate <= CurTime() then
			wep.HMCDLMSFinalStandGate = nil
		elseif wep.Primary.Next > shootGate then
			wep.Primary.Next = shootGate
		end
	end)
end

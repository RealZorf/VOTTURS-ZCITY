util.AddNetworkString("NI_SelectWeapon")
util.AddNetworkString("HG_WeaponSelectorOpened")
util.AddNetworkString("HG_WeaponSelectorConfirmed")

net.Receive("HG_WeaponSelectorOpened", function(_, ply)
	if not IsValid(ply) or not IsValid(ply.FakeRagdoll) then return end
	ply.HGWeaponSelectorOpenUntil = CurTime() + 4.25
end)

net.Receive("HG_WeaponSelectorConfirmed", function(_, ply)
	if not IsValid(ply) or not IsValid(ply.FakeRagdoll) then return end
	local attack = net.ReadUInt(2)
	ply.HGWeaponSelectorOpenUntil = nil
	if attack == 1 then
		ply.HGWeaponSelectorSuppressAttack1 = true
	elseif attack == 2 then
		ply.HGWeaponSelectorSuppressAttack2 = true
	end
end)

hook.Add("StartCommand", "HG_WeaponSelectorBlockFakeAttack", function(ply, cmd)
	if not IsValid(ply.FakeRagdoll) then
		ply.HGWeaponSelectorOpenUntil = nil
		ply.HGWeaponSelectorSuppressAttack1 = nil
		ply.HGWeaponSelectorSuppressAttack2 = nil
		return
	end

	if cmd:GetMouseWheel() ~= 0 then
		ply.HGWeaponSelectorOpenUntil = CurTime() + 4.25
	end

	local attack1 = cmd:KeyDown(IN_ATTACK)
	local attack2 = cmd:KeyDown(IN_ATTACK2)

	if (ply.HGWeaponSelectorOpenUntil or 0) > CurTime() and (attack1 or attack2) then
		ply.HGWeaponSelectorOpenUntil = nil
		ply.HGWeaponSelectorSuppressAttack1 = attack1
		ply.HGWeaponSelectorSuppressAttack2 = attack2
	end

	if ply.HGWeaponSelectorSuppressAttack1 then
		cmd:RemoveKey(IN_ATTACK)
		if not attack1 then ply.HGWeaponSelectorSuppressAttack1 = nil end
	end

	if ply.HGWeaponSelectorSuppressAttack2 then
		cmd:RemoveKey(IN_ATTACK2)
		if not attack2 then ply.HGWeaponSelectorSuppressAttack2 = nil end
	end
end)

net.Receive("NI_SelectWeapon", function(len, ply)
	if not GetGlobalBool("RadialInventory", false) then return end

	local wep = net.ReadEntity()
	if IsValid(wep) and ply:HasWeapon(wep:GetClass()) and wep:GetOwner() == ply and ply:GetActiveWeapon() ~= wep:GetClass() then
		ply:SelectWeapon(wep)
	end
end)

local enableNewInv = CreateConVar("hg_radialinventory", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle radial (NMRIH-like) inventory", 0, 1)
cvars.AddChangeCallback("hg_radialinventory", function(convar_name, value_old, value_new)
	SetGlobalBool("RadialInventory", enableNewInv:GetBool())
end)

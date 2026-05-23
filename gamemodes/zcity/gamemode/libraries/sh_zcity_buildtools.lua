if not SERVER then return end

local TOOLGUN_CLASS = "gmod_tool"
local PHYSGUN_CLASS = "weapon_physgun"
local GRAVGUN_CLASS = "weapon_physcannon"

local function sandboxHandlesPlayer(ply)
	return HG_SANDBOX
		and HG_SANDBOX.IsSandboxModeActive
		and HG_SANDBOX.IsSandboxModeActive()
		and (HG_SANDBOX.IsRestrictedPlayer(ply) or HG_SANDBOX.ShouldBlockPlayer(ply))
end

hook.Add("CanTool", "ZCity_ULXToolgun", function(ply, tr, tool)
	if not IsValid(ply) then return end
	if sandboxHandlesPlayer(ply) then return end

	if not zb.PlayerCanToolgun(ply) then
		return false
	end
end)

hook.Add("PlayerGiveSWEP", "ZCity_ULXBuildWeapons", function(ply, class)
	if not IsValid(ply) or not isstring(class) then return end
	if sandboxHandlesPlayer(ply) then return end

	if class == TOOLGUN_CLASS and not zb.PlayerCanToolgun(ply) then
		return false
	end

	if class == PHYSGUN_CLASS and not zb.PlayerCanPhysgun(ply) then
		return false
	end

	if class == GRAVGUN_CLASS and not zb.PlayerCanPhysgun(ply) then
		return false
	end
end)

hook.Add("PlayerSpawnSWEP", "ZCity_ULXSpawnBuildWeapons", function(ply, class)
	if not IsValid(ply) or not isstring(class) then return end
	if sandboxHandlesPlayer(ply) then return end

	if class == TOOLGUN_CLASS and not zb.PlayerCanToolgun(ply) then
		return false
	end

	if class == PHYSGUN_CLASS and not zb.PlayerCanPhysgun(ply) then
		return false
	end

	if class == GRAVGUN_CLASS and not zb.PlayerCanPhysgun(ply) then
		return false
	end
end)

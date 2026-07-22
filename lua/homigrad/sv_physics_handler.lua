local server_is_crashed = false

local physenv, RunConsoleCommand, game = physenv, RunConsoleCommand, game
local physenv_GetPhysicsPaused = physenv.GetPhysicsPaused
local ents_FindByClass = ents.FindByClass
local CurTime = CurTime

local func = function()
	local should_simulate = physenv_GetPhysicsPaused()

	if server_is_crashed
		or not should_simulate then
		return
	end

	server_is_crashed = true

	PrintMessage(HUD_PRINTTALK, "Physics are crashed, restart schedule created")

	timer.Create("PhysicsCrashedSchedule", 10, 1, function()
		engine.CloseServer()
		timer.Simple(0, function()
			RunConsoleCommand("changelevel", game.GetMap())
		end)
	end)
end

hook.Add("Tick", "vphysics_cathcer", func)

local CrazyPhysPerSec = 0
local CrazyPhysTime = 0
local CrazyPhysTrusthold = 500
hook.Add("OnCrazyPhysics", "stop_physics", function(ent, phys)
	local now = CurTime()
	if CrazyPhysTime < now then
		CrazyPhysTime = now + 1
		CrazyPhysPerSec = 0
	end
	CrazyPhysPerSec = CrazyPhysPerSec + 1

	if CrazyPhysPerSec > CrazyPhysTrusthold then
		physenv.SetPhysicsPaused(true)
	end
end)

local hg_prop_settle_delay = ConVarExists("hg_prop_settle_delay") and GetConVar("hg_prop_settle_delay") or CreateConVar("hg_prop_settle_delay", "6", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Delay before loose props get put to sleep and moved to a lighter collision group.", 0, 300)
local hg_prop_sleep_velocity = ConVarExists("hg_prop_sleep_velocity") and GetConVar("hg_prop_sleep_velocity") or CreateConVar("hg_prop_sleep_velocity", "22", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum linear velocity for a prop to be considered settled by the optimizer.", 0, 500)
local hg_prop_sleep_ang_velocity = ConVarExists("hg_prop_sleep_ang_velocity") and GetConVar("hg_prop_sleep_ang_velocity") or CreateConVar("hg_prop_sleep_ang_velocity", "35", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum angular velocity for a prop to be considered settled by the optimizer.", 0, 1000)
local hg_prop_use_debris_collision = ConVarExists("hg_prop_use_debris_collision") and GetConVar("hg_prop_use_debris_collision") or CreateConVar("hg_prop_use_debris_collision", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Move settled loose props into COLLISION_GROUP_DEBRIS to reduce heavy prop collisions.", 0, 1)

local propClasses = {
	"prop_physics",
	"prop_physics_multiplayer"
}

local function IsPermaAllProp(ent)
	if not IsValid(ent) then return false end

	if ent.PermaID ~= nil then return true end
	if ent.PermaAllNormalPropFix then return true end
	if ent.PermaAllStaticStyle then return true end
	if ent:GetNWBool("IsPermaEntity", false) then return true end
	if ent:GetNWString("_PermaUID", "") ~= "" then return true end

	return false
end

local function IsLooseOptimizableProp(ent)
	if not IsValid(ent) then return false end

	-- Do not touch PermaAll entities.
	-- PermaAll already manages frozen/collision state itself.
	if IsPermaAllProp(ent) then return false end

	if IsValid(ent:GetParent()) then return false end
	if ent:GetCustomCollisionCheck() then return false end
	if ent:IsPlayerHolding() then return false end
	if constraint.HasConstraints(ent) then return false end
	if ent:CreatedByMap() then return false end
	if ent.zcity_collision_proxy or IsValid(ent.hg_collision_source) then return false end
	if hg.GetLootBoxData and hg.GetLootBoxData(ent) then return false end

	return true
end

local function RestoreOptimizedProp(ent)
	if not ent.hg_prop_optimizer_collision_changed then return end

	if ent:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then
		local wantedCollisionGroup = ent.hg_prop_optimizer_collision_group or COLLISION_GROUP_NONE
		hg.SafeSetCollisionGroup(ent, wantedCollisionGroup)
	end

	ent.hg_prop_optimizer_collision_changed = nil
end

local function PropIsSettled(phys, maxVelSqr, maxAngVelSqr)
	if not IsValid(phys) then return false end
	if phys:GetVelocity():LengthSqr() > maxVelSqr then return false end
	if phys:GetAngleVelocity():LengthSqr() > maxAngVelSqr then return false end

	return true
end

timer.Create("hg_prop_optimizer", 4, 0, function()
	local now = CurTime()
	local maxVelSqr = hg_prop_sleep_velocity:GetFloat() ^ 2
	local maxAngVelSqr = hg_prop_sleep_ang_velocity:GetFloat() ^ 2
	local useDebrisCollision = hg_prop_use_debris_collision:GetBool()

	for _, class in ipairs(propClasses) do
		for _, ent in ipairs(ents_FindByClass(class)) do
			if not IsValid(ent) then continue end

			ent.hg_prop_optimizer_spawn = ent.hg_prop_optimizer_spawn or now

			local phys = ent:GetPhysicsObject()
			if not IsValid(phys) then
				RestoreOptimizedProp(ent)
				continue
			end

			if not IsLooseOptimizableProp(ent) then
				RestoreOptimizedProp(ent)
				continue
			end

			if (now - ent.hg_prop_optimizer_spawn) < hg_prop_settle_delay:GetFloat() then
				continue
			end

			if not PropIsSettled(phys, maxVelSqr, maxAngVelSqr) then
				RestoreOptimizedProp(ent)
				continue
			end

			if useDebrisCollision and ent:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS then
				ent.hg_prop_optimizer_collision_group = ent:GetCollisionGroup()
				ent.hg_prop_optimizer_collision_changed = true
				hg.SafeSetCollisionGroup(ent, COLLISION_GROUP_DEBRIS)
			end

			phys:Sleep()
		end
	end
end)

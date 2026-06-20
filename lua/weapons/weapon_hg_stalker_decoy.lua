if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Death Decoy"
SWEP.Category = "Z-City Traitor"
SWEP.Purpose = "Leave behind a corpse-like copy of yourself to fake your death."
SWEP.Instructions = "Left click to place your one-use death decoy. Stalker only."
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.UseHands = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.HoldType = "normal"
SWEP.WorkWithFake = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 6

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime() + 0.35)
	return true
end

function SWEP:DrawWorldModel()
end

function SWEP:PreDrawViewModel()
	return true
end

function SWEP:SecondaryAttack()
end

local function copyBonePoseToRagdoll(ply, rag)
	for physNum = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(physNum)
		if not IsValid(phys) then continue end

		local bone = rag:TranslatePhysBoneToBone(physNum)
		if bone < 0 then continue end

		local matrix = ply:GetBoneMatrix(bone)
		if matrix then
			phys:SetPos(matrix:GetTranslation())
			phys:SetAngles(matrix:GetAngles())
		end

		local boneName = rag:GetBoneName(bone)
		phys:SetMass((hg and hg.IdealMassPlayer and hg.IdealMassPlayer[boneName]) or 4)
		phys:SetVelocity(ply:GetVelocity())
		phys:Wake()
	end
end

local function applyDeadOrganism(rag)
	if not hg or not hg.organism or not hg.organism.Add then return end

	hg.organism.Add(rag)
	if hg.organism.Clear then
		hg.organism.Clear(rag.organism)
	end

	rag.organism.fakePlayer = true
	rag.organism.alive = false
	rag.organism.o2[1] = 0
	rag.organism.pulse = 0
end

local function createDecoyCorpse(ply)
	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return nil end

	rag:SetModel(ply:GetModel())
	rag:SetPos(ply:GetPos())
	rag:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	rag:SetSkin(ply:GetSkin())

	for _, bodyGroup in ipairs(ply:GetBodyGroups()) do
		rag:SetBodygroup(bodyGroup.id, ply:GetBodygroup(bodyGroup.id))
	end

	local modelScale = hg and hg.GetPlayerModelScale and hg.GetPlayerModelScale(ply) or ply:GetModelScale()
	rag:SetNWFloat("ZCModelScale", modelScale)
	rag:SetModelScale(1, 0)
	rag:Spawn()
	rag:Activate()
	rag:SetModelScale(1, 0)
	rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	rag:AddEFlags(EFL_NO_DAMAGE_FORCES + EFL_DONTBLOCKLOS)

	local appearance = ply.CurAppearance and table.Copy(ply.CurAppearance) or nil
	if appearance and hg and hg.Appearance and hg.Appearance.ForceApplyAppearance then
		hg.Appearance.ForceApplyAppearance(rag, appearance)
	end

	rag:SetNWString("PlayerName", ply:GetNWString("PlayerName") or ply:Name())
	rag:SetNWVector("PlayerColor", ply:GetPlayerColor())
	rag:SetNetVar("Accessories", ply:GetNetVar("Accessories", ""))
	rag.HMCDStalkerDeathDecoy = true
	rag.HMCDStalkerDeathDecoyOwnerSteamID64 = ply:SteamID64() or ""
	rag.HMCDStalkerDeathDecoySpawnTime = CurTime()

	if ApplyAppearanceRagdoll then
		ApplyAppearanceRagdoll(rag, ply)
	end

	applyDeadOrganism(rag)
	copyBonePoseToRagdoll(ply, rag)

	if hg and hg.ApplyRagdollPhysicsScale then
		hg.ApplyRagdollPhysicsScale(rag, modelScale)
	end

	rag:EmitSound("physics/flesh/flesh_impact_hard" .. math.random(1, 6) .. ".wav", 65, math.random(90, 105))

	return rag
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1)

	if CLIENT then return end
	if self.Used then return end

	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if ply.HMCDStalkerDeathDecoyUsed then return end

	if IsValid(ply.FakeRagdoll) then
		ply:ChatPrint("You cannot place a death decoy while ragdolled.")
		return
	end

	local subRole = MODE and MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(ply.SubRole) or ply.SubRole
	if subRole ~= "traitor_stalker" and subRole ~= "traitor_stalker_soe" then
		ply:ChatPrint("Only the Stalker can use this.")
		return
	end

	local rag = createDecoyCorpse(ply)
	if not IsValid(rag) then return end

	self.Used = true
	ply.HMCDStalkerDeathDecoyUsed = true
	ply:EmitSound("npc/roller/mine/rmine_blip1.wav", 45, 75)
	ply:ChatPrint("You leave a dead copy behind.")

	timer.Simple(0, function()
		if not IsValid(ply) then return end

		if ply:HasWeapon("weapon_hands_sh") then
			ply:SelectWeapon("weapon_hands_sh")
		end

		if IsValid(self) then
			self:Remove()
		end
	end)
end

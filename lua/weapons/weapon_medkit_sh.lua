if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Medkit"
SWEP.Instructions = "A small bag containing medical supplies. Has bandages, painkillers, tourniquets, internal bleeding medicine, decompression needle and naloxone. A necessary thing in hiking, military conditions and just a necessary thing in everyday life. RMB to apply on others, R to change use mode."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/w_models/weapons/w_eq_medkit.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_medkit")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_medkit.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -0.5, -3)
SWEP.offsetAng = Angle(-30, 20, 90)
SWEP.modes = 6
SWEP.modeNames = {
	[1] = "bandaging",
	[2] = "painkiller",
	[3] = "tranexamic acid",
	[4] = "tourniquet",
	[5] = "decompression needle",
	[6] = "naloxone",
}
SWEP.ofsV = Vector(-2,-10,8)
SWEP.ofsA = Angle(90,-90,90)
function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)

	self.modeValues = {
		[1] = 80,
		[2] = 1,
		[3] = 10,
		[4] = 1,
		[5] = 1,
		[6] = 1,
	}
end

SWEP.modeValuesdef = {
	[1] = {80,true},
	[2] = {1,false},
	[3] = {10,true},
	[4] = {1,true},
	[5] = {1,false},
	[6] = {1,false},
}
SWEP.ShouldDeleteOnFullUse = true

local math = math
local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)
function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if (owner.zmanipstart ~= nil and not owner.organism.larmamputated) then return end

	if not owner.GetAimVector then return end
	local aimvec = owner:GetAimVector()
	if not aimvec then return end

	local hold = self:GetHolding()
	local ducking = owner:IsFlagSet(FL_ANIMDUCKING)

    self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 5, -30 + hold / 2 + 20 * aimvec[3] * (ducking and -3 or -1), 5 - hold / 4))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 25, -hold / 2.5, 35 -hold / 1.4))

    self:BoneSet("l_upperarm", vector_origin, lang1)
    self:BoneSet("l_forearm", vector_origin, lang2)
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:SpawnGarbage()
		self:NPCHeal(owner, 0.6, "snd_jack_hmcd_bandage.wav")
	end
end

if SERVER then
	local function ApplyMedkitPainkiller(org, dose)
		dose = math.max(tonumber(dose) or 0, 0)
		if dose <= 0 then return false end

		org.analgesiaAdd = math.min((org.analgesiaAdd or 0) + dose * 0.45, 4)
		org.painadd = math.max((org.painadd or 0) - 18 * dose, 0)
		org.avgpain = math.max((org.avgpain or 0) - 12 * dose, 0)
		org.pain = math.max((org.pain or 0) - 12 * dose, 0)
		org.shock = math.max((org.shock or 0) - 8 * dose, 0)

		return true
	end

	function SWEP:Heal(ent, mode)
		if ent:IsNPC() then
			self:SpawnGarbage()
			self:NPCHeal(ent, 0.6, "snd_jack_hmcd_bandage.wav")
		end

		local org = ent.organism
		if not org then return end

		local owner = self:GetOwner()
		if ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
			self:SetHolding(math.min(self:GetHolding() + 50, 100))

			if self:GetHolding() < 100 then return end
		end

		local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
		if self.mode == 2 then
			if (self.modeValues[2] or 0) <= 0 then return end
			if ent ~= owner and not org.otrub then return end

			if not ApplyMedkitPainkiller(org, self.modeValues[2]) then return end

			self.modeValues[2] = 0
			entOwner:EmitSound("snd_jack_hmcd_pillsuse.wav", 60, math.random(95, 105))

			return true
		elseif self.mode == 3 then
			if self.modeValues[3] == 0 then return end
			/*local val = org.lungsL[1]
			local healed = math.max(val - self.modeValues[3], 0)
			self.modeValues[3] = self.modeValues[3] - (val - healed)
			org.lungsL[1] = healed
			local val = org.lungsR[1]
			local healed = math.max(val - self.modeValues[3], 0)
			self.modeValues[3] = self.modeValues[3] - (val - healed)
			org.lungsR[1] = healed*/
			local internalBleed = org.internalBleed - org.internalBleedHeal
			
			if self.poisoned2 then
				org.poison4 = CurTime()

				self.poisoned2 = nil
			end

			if internalBleed > 0 then
				local healed = math.max(internalBleed - self.modeValues[3], 0)
				self.modeValues[3] = self.modeValues[3] - (internalBleed - healed) * (owner.Profession == "doctor" and 0.5 or 1)
				org.internalBleedHeal = org.internalBleedHeal + (internalBleed - healed)
				self:RefreshPerfusionTreatment(ent, owner.Profession == "doctor" and 0.35 or 0.25)
				entOwner:EmitSound("snds_jack_gmod/ez_medical/" .. math.random(16, 18) .. ".wav", 60, math.random(95, 105))
			end
		elseif self.mode == 1 then
			self:Bandage(ent, bone)
		elseif self.mode == 4 then
			if self:Tourniquet(ent, bone) then self.modeValues[4] = 0 end
		elseif self.mode == 5 then
			--if ((org.lungsL[2] + org.lungsR[2]) / 2 >= 0.5) and not org.needle then
				if self.modeValues[5] == 0 then return end
				if self.poisoned2 then
					org.poison4 = CurTime()
	
					self.poisoned2 = nil
				end

				org.needle = 1

				if !(org.lungsR[2] == 1 or org.lungsL[2] == 1) then
					if math.random(2) == 1 then 
						org.lungsR[2] = 1
					else
						org.lungsL[2] = 1
					end
				end

				self.modeValues[5] = 0
				self:RefreshPerfusionTreatment(ent, 0.2)
				entOwner:EmitSound("snd_jack_hmcd_needleprick.wav", 60, math.random(95, 105))
			--end
		elseif self.mode == 6 then
			local naloxoneDose = self.modeValues[6] or 0
			if naloxoneDose <= 0 then return end

			if self.poisoned2 then
				org.poison4 = CurTime()

				self.poisoned2 = nil
			end

			org.naloxoneadd = math.min((org.naloxoneadd or 0) + naloxoneDose, 1)
			self.modeValues[6] = 0
			self:RefreshPerfusionTreatment(ent, 0.18)
			entOwner:EmitSound("snd_jack_hmcd_needleprick.wav", 60, math.random(95, 105))
		end

		if self.modeValues[1] == 0 and self.modeValues[2] == 0 and self.modeValues[3] == 0 and self.modeValues[4] == 0 and self.modeValues[5] == 0 and (self.modeValues[6] or 0) == 0 and self.ShouldDeleteOnFullUse then
			owner:SelectWeapon("weapon_hands_sh")
			self:Remove()
		end
	end
end

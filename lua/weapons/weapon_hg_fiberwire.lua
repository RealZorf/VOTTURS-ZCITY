if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Fiber Wire"
SWEP.Instructions = "This is a single cylindrical, flexible strand of metal connected to two ergonomic grips made of carbon fibre and metal. Use it to strange people.\n\nLMB to swing.\nWhen strangling, press LMB to stop strangling."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/hmc/weapons/w_fibrewire.mdl"
SWEP.WorldModelReal = "models/hmc/weapons/v_fibrewire_test.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""

SWEP.HoldType = "melee"

SWEP.ForceIdleAfterDeploy = false

SWEP.HoldPos = Vector(-6,0,0)

SWEP.AttackTime = 0.4
SWEP.AnimTime1 = 1.3
SWEP.WaitTime1 = 1
SWEP.ViewPunch1 = Angle(0,-5,3)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-4)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,-8)
SWEP.weaponAng = Angle(0,-90,0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 0
SWEP.DamageSecondary = 0

SWEP.BlockHoldPos = Vector(-6,0,0)
SWEP.BlockHoldAng = Angle(0, 0, 0)

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 3

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 12
SWEP.StaminaSecondary = 8

SWEP.AttackLen1 = 70
SWEP.AttackLen2 = 40

SWEP.AnimList = {
    ["idle"] = "idle_2",
    ["idle2"] = "idle_2",
    ["deploy"] = "draw",
    ["attack"] = "Swing",
    ["attack2"] = "Swing",
    ["charge_idle"] = "charge_idle",
    ["holster"] = "holster",
    ["drop"] = "drop",
    ["Idle1_To_Charge"] = "Idle1_To_Charge",
    ["Idle2_To_Charge"] = "Idle2_To_Charge",
    ["strangle_start"] = "strangle_start",
    ["strangle_loop"] = "strangle_loop",
    ["strangle_end"] = "strangle_end",
}

local fiberwire_blackout_hold_time = 9
local fiberwire_blackout_time = 12
local fiberwire_choke_grace_time = 1.5
local fiberwire_blackout_brainoxygen = 0.2
local fiberwire_blackout_consciousness = 0.25

function SWEP:PlayAnim(anim, time, cycling, callback, reverse, sendtoclient)
    if CLIENT then
        self.setlh = not (anim == "idle" or anim == "idle2" or anim == "charge_idle")
        self:HideDummyBone()
    end
    return self.BaseClass.PlayAnim(self, anim, time, cycling, callback, reverse, sendtoclient)
end

local function GetStrangleTrace(owner, dist)
    local filter = {owner}
    if IsValid(owner.FakeRagdoll) then filter[2] = owner.FakeRagdoll end
    return util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * (dist or 100), filter)
end

local function IsChokeZoneHit(ent, tr)
    if not IsValid(ent) then return false end
    if ent:IsRagdoll() then return tr.Entity == ent end
    if not (ent:IsNPC() or ent:IsPlayer()) then return false end

    if tr.HitGroup == HITGROUP_HEAD or tr.HitGroup == HITGROUP_NECK or tr.HitGroup == HITGROUP_CHEST then
        return true
    end

    if ent:IsPlayer() and tr.HitPos then
        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            local pos = ent:GetBonePosition(headBone)
            if pos and pos:Distance(tr.HitPos) <= 28 then return true end
        end
    end

    return false
end

local function FindModeNPCRagdoll(npcPos, npcModel, existing)
    local best, bestDist
    for _, ent in ipairs(ents.FindInSphere(npcPos, 220)) do
        if ent:IsRagdoll() and not existing[ent] then
            local dist = ent:GetPos():DistToSqr(npcPos)
            if ent:GetModel() == npcModel then dist = dist * 0.6 end
            if not best or dist < bestDist then
                best, bestDist = ent, dist
            end
        end
    end
    return best
end

local function IsFiberwireStrangled(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if SERVER then
        return IsValid(ply.FakeRagdoll) and ply.FakeRagdoll.StrangleLocked == true
    end
    return ply:GetNetVar("fiberwireStrangled", false)
end

local function StartStrangle(self, victim)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if IsValid(owner.FakeRagdoll) then return end

    if IsValid(victim) and victim:IsNPC() then
        local npcPos = victim:WorldSpaceCenter()
        local npcModel = victim:GetModel()
        local existing = {}
        for _, ent in ipairs(ents.FindInSphere(npcPos, 150)) do
            if ent:IsRagdoll() then existing[ent] = true end
        end

        local dmg = DamageInfo()
        dmg:SetDamage(math.max(victim:Health(), 1000))
        dmg:SetAttacker(owner)
        dmg:SetInflictor(IsValid(self) and self or owner)
        dmg:SetDamageType(DMG_SLASH)
        dmg:SetDamageForce(vector_origin)
        dmg:SetDamagePosition(npcPos)
        victim:TakeDamageInfo(dmg)

        local timerId = "FiberwireNPCRag_" .. self:EntIndex() .. "_" .. victim:EntIndex()
        timer.Create(timerId, 0.05, 8, function()
            if not IsValid(self) or self:GetStrangling() then timer.Remove(timerId) return end
            local ownerNow = self:GetOwner()
            if not IsValid(ownerNow) or not ownerNow:IsPlayer() or IsValid(ownerNow.FakeRagdoll) then timer.Remove(timerId) return end

            local rag = FindModeNPCRagdoll(npcPos, npcModel, existing)
            if not IsValid(rag) then return end

            rag._fiberwire_spawn_colgroup = rag:GetCollisionGroup()
            rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
            for i = 0, rag:GetPhysicsObjectCount() - 1 do
                local phys = rag:GetPhysicsObjectNum(i)
                if IsValid(phys) then
                    phys:SetVelocity(vector_origin)
                    phys:AddAngleVelocity(-phys:GetAngleVelocity())
                end
            end

            timer.Remove(timerId)
            StartStrangle(self, rag)
        end)
        return
    end

    local rag = victim
    if IsValid(victim) and victim:IsPlayer() then
        hg.Fake(victim)
        rag = victim.FakeRagdoll
    end
    if not IsValid(rag) or not rag:IsRagdoll() then return end

    local ragPly = hg.RagdollOwner and hg.RagdollOwner(rag)
    if ragPly == owner then return end

    self:SetStrangling(true)
    self.StrangleRag = rag
    self.StrangleStartedAt = CurTime()
    self.nextBreathSound = CurTime() + math.Rand(3, 5)
    self.breathStage = 0
    self.inhaleCount = 0
    self.NoIdleLoop = true
    self._fw_looping = false
    self._fw_loop_at = CurTime() + 0.6
    self._fw_lock_until = CurTime() + 1

    rag.Strangler = owner
    rag.StrangleLocked = true
    rag._oldCollisionGroup = rag._fiberwire_spawn_colgroup or rag:GetCollisionGroup()
    rag._fiberwire_spawn_colgroup = nil
    rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    if IsValid(ragPly) and ragPly:IsPlayer() then
        ragPly:SetNetVar("fiberwireStrangled", true)

        if not ragPly:HasWeapon("weapon_hands_sh") then
            ragPly:Give("weapon_hands_sh")
        end
        local wep = ragPly:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() ~= "weapon_hands_sh" then
            if wep.RemoveFake then wep:RemoveFake() end
            local hands = ragPly:GetWeapon("weapon_hands_sh")
            if IsValid(hands) then
                ragPly.ActiveWeapon = hands
                ragPly:SetActiveWeapon(hands)
            end
        end

        if ragPly.organism then
            ragPly.organism.neckBrainOxygenPenalty = math.max(ragPly.organism.neckBrainOxygenPenalty or 0, 0.08)
            ragPly:Notify("I feel something suddenly and forcefully pull around my neck from my back. I can't breathe...", true, "fiberwire_strangle_start", 3)
        end
    end

    owner:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1,7) .. ".wav", 60, math.random(95,105))

    local hands = owner:GetWeapon("weapon_hands_sh")
    if IsValid(hands) and hands.SetCarrying then hands:SetCarrying() end
    if hg.SetCarryEnt2 then hg.SetCarryEnt2(owner) end

    self._fw_prev_run = owner:GetRunSpeed()
    owner:SetRunSpeed(owner:GetWalkSpeed())

    if owner.organism and owner.organism.stamina and owner.organism.stamina[1] then
        owner.organism.stamina[1] = math.max(owner.organism.stamina[1] - 50, 0)
    end

    self:PlayAnim("strangle_start", 0.6, false, nil, false, true)
    timer.Simple(0.6, function()
        if not IsValid(self) or not self:GetStrangling() then return end
        self:PlayAnim("strangle_loop", 4.0, true, nil, false, true)
        self._fw_looping = true
    end)
end

local function StopStrangle(self)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local rag = self.StrangleRag
    if IsValid(rag) then
        local ragPly = hg.RagdollOwner and hg.RagdollOwner(rag)
        if IsValid(ragPly) and ragPly:IsPlayer() then
            ragPly:SetNetVar("fiberwireStrangled", false)
            if ragPly.organism then
                ragPly.organism.neckBrainOxygenPenalty = 0
            end
        end

        rag.Strangler = nil
        rag.StrangleLocked = nil
        if rag._oldCollisionGroup then
            rag:SetCollisionGroup(rag._oldCollisionGroup)
            rag._oldCollisionGroup = nil
        end
    end

    self:SetStrangling(false)
    if self.SetSawingHead then self:SetSawingHead(false) end
    self.StrangleRag = nil
    self.StrangleStartedAt = nil
    self.NoIdleLoop = nil
    self.nextBreathSound = nil
    self.breathStage = nil
    self.inhaleCount = nil
    self._fw_looping = false
    self._fw_loop_at = nil
    self._fw_lock_until = nil

    if owner:IsPlayer() then
        self:PlayAnim("idle", 10, true, nil, false, true)
        if self._fw_prev_run then
            owner:SetRunSpeed(self._fw_prev_run)
            self._fw_prev_run = nil
        end
        if owner.SetNetVar then owner:SetNetVar("slowDown", 0) end
    end
end

function SWEP:StopStrangling()
    StopStrangle(self)
end

function SWEP:OnRemove()
    if SERVER and self:GetStrangling() then StopStrangle(self) end
end
SWEP.OnDrop = SWEP.OnRemove

function SWEP:HideDummyBone()
    if not CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local vm = owner:GetViewModel()
    if not IsValid(vm) then return end
    vm:ManipulateBoneScale(60, Vector(0, 0, 0))
    vm:ManipulateBonePosition(60, Vector(0, 0, 0))
end

function SWEP:Deploy()
    local ok = self.BaseClass.Deploy(self)
    self.ForceIdleAfterDeploy = true

    if CLIENT then
        timer.Simple(0.04, function()
            if not IsValid(self) then return end
            local owner = self:GetOwner()
            if not IsValid(owner) or owner:GetActiveWeapon() ~= self then return end
            if self:GetStrangling() then return end
            self:PlayAnim("idle2", 10, true)
            self:HideDummyBone()
        end)
    end
    return ok
end

function SWEP:Holster(target)
    if SERVER and self:GetStrangling() then StopStrangle(self) end
    if self.BaseClass and self.BaseClass.Holster then
        return self.BaseClass.Holster(self, target)
    end
    return true
end

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_fibrewire")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_fibrewire"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis"
SWEP.holsteredPos = Vector(6, -1.5, -6)
SWEP.holsteredAng = Angle(65, 0, 0)
SWEP.Concealed = false
SWEP.HolsterIgnored = false

SWEP.AttackHit = "Plastic_Box.ImpactHard"
SWEP.Attack2Hit = "Plastic_Box.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "Plastic_Box.ImpactSoft"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanSecondaryAttack()
    return false
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 85
SWEP.AttackRads2 = 0

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

function SWEP:SetupDataTables()
    if self.BaseClass and self.BaseClass.SetupDataTables then
        self.BaseClass.SetupDataTables(self)
    end
    self:NetworkVar("Bool", 13, "Strangling")
    self:NetworkVar("Bool", 14, "SawingHead")
end

function SWEP:PrimaryAttack()
    if self:GetStrangling() then
        if (self._fw_lock_until or 0) > CurTime() then return end
        if SERVER then StopStrangle(self) end
        return
    end
    return self.BaseClass.PrimaryAttack(self)
end

function SWEP:CustomAttack()
    if CLIENT then return true end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() or IsValid(owner.FakeRagdoll) then return true end

    local tr = GetStrangleTrace(owner, 100)
    if IsValid(tr.Entity) and IsChokeZoneHit(tr.Entity, tr) then
        StartStrangle(self, tr.Entity)
        self:SetInAttack(false)
    end
    return true
end

function SWEP:CustomThink()
    if self.ForceIdleAfterDeploy then
        self.ForceIdleAfterDeploy = false
        self:PlayAnim("idle2", 10, true)
    end

    if self.BaseClass and self.BaseClass.CustomThink then
        self.BaseClass.CustomThink(self)
    end

    if CLIENT then
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and self:GetSawingHead() and hg.DragHandsToPos then
            local ang = owner:EyeAngles()
            local phase = CurTime() * 15
            local basePos = owner:GetShootPos() + ang:Forward() * 19 - ang:Up() * 9 + ang:Right() * (math.sin(phase) * 4.5)
            hg.DragHandsToPos(owner, self, basePos, true, 5, ang:Right(), Angle(0, 0, 180), Angle(0, 0, 0))
        end
        return
    end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if IsValid(owner.FakeRagdoll) or not self:GetStrangling() then
        if IsValid(owner.FakeRagdoll) then StopStrangle(self) end
        return
    end

    local rag = self.StrangleRag
    if not IsValid(rag) or not rag:IsRagdoll() or not owner:Alive() then
        StopStrangle(self)
        return
    end

    local ragPly = hg.RagdollOwner and hg.RagdollOwner(rag)
    if IsValid(ragPly) and ragPly:IsPlayer() and not (ragPly.organism and ragPly.organism.lungsfunction == false) and CurTime() >= (self.nextBreathSound or 0) then
        local soundToPlay
        local isFemale = ThatPlyIsFemale and ThatPlyIsFemale(ragPly)
        if self.breathStage == 0 then
            soundToPlay = isFemale
                and ("breathing/inhale/female/inhale_0" .. math.random(1, 5) .. ".wav")
                or ("breathing/inhale/male/inhale_0" .. math.random(1, 4) .. ".wav")
            self.inhaleCount = (self.inhaleCount or 0) + 1
            if self.inhaleCount >= 5 then self.breathStage = 1 end
        else
            soundToPlay = "breathing/agonalbreathing_" .. math.random(1, 13) .. ".wav"
        end
        rag:EmitSound(soundToPlay, 50, 100)
        self.nextBreathSound = CurTime() + math.Rand(3, 5)
    end

    local lb = owner:LookupBone("ValveBiped.Bip01_L_Hand")
    local rb = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not lb or not rb then return end
    local lm = owner:GetBoneMatrix(lb)
    local rm = owner:GetBoneMatrix(rb)
    if not lm or not rm then return end

    local mid = (lm:GetTranslation() + rm:GetTranslation()) * 0.5
    local fwd = owner:GetAimVector()
    local up = owner:GetAngles():Up()
    local left = owner:GetAngles():Right() * -1

    local sawData = owner.Ability_NeckBreak
    local sawingHead = sawData and sawData.Action == "saw_head" and sawData.Victim == ragPly or false
    if self:GetSawingHead() ~= sawingHead then
        self:SetSawingHead(sawingHead)
    end

    local sawWave = sawingHead and math.sin(CurTime() * 15) or 0
    local sawPush = sawingHead and math.cos(CurTime() * 15) or 0
    local targetPos = mid + up * 6 + fwd * 12 + left * 3
    if sawingHead then
        targetPos = targetPos + left * (sawWave * 4) + fwd * (sawPush * 1.5) + up * (math.abs(sawWave) * 0.75)
    end

    local neckAng = owner:EyeAngles()
    neckAng:RotateAroundAxis(neckAng:Forward(), 90)
    neckAng:RotateAroundAxis(neckAng:Up(), 90)
    if sawingHead then
        neckAng:RotateAroundAxis(neckAng:Forward(), sawWave * 4)
        neckAng:RotateAroundAxis(neckAng:Up(), sawPush * 2.5)
    end

    hg.ShadowControl(rag, 10, 0.2, neckAng, 300, 30, targetPos, 800, 200)

    local spinePos = targetPos - fwd * 8
    if sawingHead then spinePos = spinePos - left * (sawWave * 2) end
    hg.ShadowControl(rag, 1, 0.2, nil, nil, nil, spinePos, 500, 120)
    hg.ShadowControl(rag, 2, 0.2, nil, nil, nil, spinePos, 500, 120)

    local org = ragPly and ragPly.organism
    if IsValid(ragPly) and ragPly:IsPlayer() and ragPly:Alive() and not (org and org.otrub) then
        local headPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 10))
        local lhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 5))
        local rhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 7))
        if IsValid(headPhys) and IsValid(lhandPhys) and IsValid(rhandPhys) then
            local pos = headPhys:GetPos()
            local lpos = lhandPhys:GetPos()
            local rpos = rhandPhys:GetPos()
            hg.ShadowControl(rag, 5, 0.001, nil, nil, nil, pos - (pos - lpos):GetNormalized() * (2 + math.sin(CurTime() * 2) * 0.5), 80, 60)
            hg.ShadowControl(rag, 7, 0.001, nil, nil, nil, pos - (pos - rpos):GetNormalized() * (2 + math.cos(CurTime() * 1.8) * 0.5), 80, 60)
        end
    end

    if IsValid(ragPly) and ragPly:IsPlayer() and org then
        local dt = FrameTime()
        local held_time = CurTime() - (self.StrangleStartedAt or CurTime())
        local choke_progress = math.Clamp((held_time - fiberwire_choke_grace_time) / math.max(fiberwire_blackout_hold_time - fiberwire_choke_grace_time, 0.1), 0, 1)
        local physiological_progress = choke_progress ^ 1.2

        org.neckBrainOxygenPenalty = math.max(org.neckBrainOxygenPenalty or 0, math.Clamp(choke_progress * 0.95, 0.08, 0.95))
        org.brainoxygen = math.min(org.brainoxygen or 1, Lerp(physiological_progress, 0.92, fiberwire_blackout_brainoxygen))
        org.consciousness = math.min(org.consciousness or 1, Lerp(physiological_progress, 0.98, fiberwire_blackout_consciousness))

        if held_time > fiberwire_choke_grace_time then
            org.disorientation = math.max(org.disorientation or 0, choke_progress * 4.5)
        end

        if held_time >= fiberwire_blackout_hold_time or (org.brainoxygen or 1) <= fiberwire_blackout_brainoxygen or org.otrub then
            ragPly.HMCD_FiberwireBlackoutUntil = math.max(ragPly.HMCD_FiberwireBlackoutUntil or 0, CurTime() + fiberwire_blackout_time)
        end

        if org.stamina and org.stamina.subadd ~= nil then
            org.stamina.subadd = org.stamina.subadd + 6 * dt
        end
    end

    if (self._fw_loop_at or 0) > 0 and CurTime() >= self._fw_loop_at and not self._fw_looping then
        self:PlayAnim("strangle_loop", 4.0, true, nil, false, true)
        self._fw_looping = true
    end
end

hook.Add("PlayerSwitchWeapon", "FiberwireStrangleHands", function(ply, oldWep, newWep)
    if not IsFiberwireStrangled(ply) then return end
    if IsValid(newWep) and newWep:GetClass() == "weapon_hands_sh" then return end
    return true
end)

if SERVER then
    hook.Add("HG_MovementCalc_2", "FiberwireSlowMove", function(mul, ply, cmd)
        local wep = IsValid(ply) and ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_hg_fiberwire" and wep.GetStrangling and wep:GetStrangling() then
            mul[1] = mul[1] * 0.6
        end
    end)

    hook.Add("ShouldCollide", "FiberwireNoCollideStranglerAndVictim", function(ent1, ent2)
        if not IsValid(ent1) or not IsValid(ent2) then return end

        local rag, ply
        if ent1:IsRagdoll() and ent2:IsPlayer() then
            rag, ply = ent1, ent2
        elseif ent2:IsRagdoll() and ent1:IsPlayer() then
            rag, ply = ent2, ent1
        else
            return
        end

        if rag.Strangler == ply then return false end
    end)

    hook.Add("CanControlFake", "FiberwireStrangleLock", function(ply)
        if IsValid(ply and ply.FakeRagdoll) and ply.FakeRagdoll.StrangleLocked then
            return false
        end
    end)

    hook.Add("Should Fake Up", "FiberwireStrangleLockUp", function(ply)
        if IsValid(ply and ply.FakeRagdoll) and ply.FakeRagdoll.StrangleLocked then
            return true
        end
    end)

    hook.Add("StartCommand", "FiberwireNoSprint", function(ply, cmd)
        local wep = IsValid(ply) and ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_hg_fiberwire" and wep.GetStrangling and wep:GetStrangling() then
            cmd:RemoveKey(IN_SPEED)
        end
    end)

    hook.Add("HG_PlayerSay", "FiberwireStrangleMute", function(ply, txtTbl)
        if IsFiberwireStrangled(ply) then txtTbl[1] = "" end
    end)

    hook.Add("HG_PlayerCanHearPlayersVoice", "FiberwireStrangleMute", function(listener, speaker)
        if IsFiberwireStrangled(speaker) then return false, false end
    end, -1)

    hook.Add("HG_PlayerCanSeePlayersChat", "FiberwireStrangleMute", function(listener, speaker)
        if IsFiberwireStrangled(speaker) then return false end
    end)

    hook.Add("HG_CanDoPhrase", "FiberwireStrangleMute", function(ply)
        if IsFiberwireStrangled(ply) then return true end
    end)
end

if CLIENT then
    hook.Add("PlayerBindPress", "FiberwireStrangleMute", function(client, bind, pressed)
        if client ~= LocalPlayer() or not pressed or not IsFiberwireStrangled(client) then return end
        bind = bind:lower()
        if bind:find("messagemode") or bind:find("slot") or bind:find("invnext") or bind:find("invprev") or bind:find("lastinv") or bind:find("phys_swap") then
            return true
        end
    end)
end

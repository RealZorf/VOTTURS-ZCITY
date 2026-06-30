if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("PAT_FlaregunScorch")
end

SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Flare Gun"
SWEP.Author = "Pat"
SWEP.Instructions = "Single-shot flare pistol. Direct hits stagger targets; sky shots burst into a bright flare."
SWEP.Category = "ZCity Other"
SWEP.Slot = 2
SWEP.SlotPos = 11
SWEP.ViewModel = "models/weapons/c_sinabackstabber.mdl"
SWEP.WorldModel = "models/weapons/w_sinabackstabber.mdl"
SWEP.WorldModelFake = "models/weapons/c_sinabackstabber.mdl"
SWEP.ViewModelFOV = 75
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.FiresUnderwater = false
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.WorkWithFake = true

SWEP.FakePos = Vector(-21.5, 3.2, 5.2)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0, 0, 0)
SWEP.AttachmentAng = Angle(0, 0, 0)
SWEP.FakeAttachment = "muzzle"
SWEP.UseCustomWorldModel = true
SWEP.WorldPos = Vector(0, 0, 0)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(0, 0, 0)
SWEP.lengthSub = 20
if CLIENT then
    local IconPath = "vgui/flaregun_homigrad.png"

    SWEP.IconOverride = IconPath
    SWEP.BounceWeaponIcon = false
    SWEP.DrawWeaponInfoBox = true
    SWEP.WepSelectIcon2 = Material(IconPath, "smooth noclamp")
    SWEP.WepSelectIcon2box = true

    local IconMat = SWEP.WepSelectIcon2

    function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
        self:PrintWeaponInfo(x + wide + 20, y + tall * 0.15, alpha)

        if not IconMat or IconMat:IsError() then return end

        surface.SetDrawColor(255, 255, 255, alpha or 255)
        surface.SetMaterial(IconMat)

        local size = math.min(wide, tall) * 0.75
        local ix = x + (wide - size) * 0.5
        local iy = y + (tall - size) * 0.5 - 16

        surface.DrawTexturedRect(ix, iy, size, size)
    end

    function SWEP:DrawHUD()
        self.isscoping = false

        if self.attachments then
            for plc, att in pairs(self.attachments) do
                if not self:HasAttachment(plc) then continue end
                if hg.attachments[plc][att[1]].sightFunction then
                    hg.attachments[plc][att[1]].sightFunction(self)
                end
            end
        end

        if self.ChangeFOV then self:ChangeFOV() end
        if self.DrawHUDAdd then self:DrawHUDAdd() end
        if self.dort and self.DoRT then self:DoRT() end
    end

    function SWEP:PreDrawViewModel(vm, wep, ply)
        if IsValid(ply) and ply == LocalPlayer() and IsValid(ply.FakeRagdoll) then
            return true
        end
    end

    function SWEP:ViewModelDrawn(vm)
        local ply = LocalPlayer()
        if IsValid(ply) and IsValid(ply.FakeRagdoll) then
            return true
        end
    end

    function SWEP:CalcViewModelView(vm, oldEyePos, oldEyeAng, eyePos, eyeAng)
        local ply = self:GetOwner()
        if IsValid(ply) and ply == LocalPlayer() and IsValid(ply.FakeRagdoll) then
            return eyePos, eyeAng
        end
    end
end

SWEP.AnimList = {
    ["idle"] = "idle",
    ["fire"] = "fire",
    ["reload"] = "reload",
    ["reload_empty"] = "reload"
}

SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 4
SWEP.availableAttachments = {}
SWEP.NoMuzzleEffects = true
SWEP.ShellEject = ""
SWEP.DistSound = ""
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, 0, 0)
SWEP.holsteredAng = Angle(-5, -5, 90)
SWEP.shouldntDrawHolstered = true

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Cone = 0.01
SWEP.Primary.Damage = 7
SWEP.Primary.Sound = {"weapons/flaregunbackstabber.wav", 75, 100, 100}
SWEP.Primary.SoundFP = {"weapons/flaregunbackstabber.wav", 75, 100, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/m14/handling/m14_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 4
SWEP.Primary.Wait = 1
SWEP.Tracer = "AR2Tracer"
SWEP.PlayerHitDamage = 24
SWEP.HeadOtrubRange = 96
SWEP.HeadOtrubHitRadius = 18
SWEP.HeadOtrubStunTime = 8

SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "revolver"
SWEP.ZoomPos = Vector(2, -3.55, 2.0)
SWEP.RHandPos = Vector(-5, -1.5, 2)
SWEP.LHandPos = false
SWEP.RHPos = Vector(12, -5, 4.5)
SWEP.RHAng = Angle(-2, -2, 90)
SWEP.LHPos = false
SWEP.LocalMuzzlePos = Vector(8, 4.7, 3)
SWEP.LocalMuzzleAng = Angle(0, 18, -90)
SWEP.WeaponEyeAngles = Angle(0, 0, 0)
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SprayRand = {Angle(0, 0, 0), Angle(0, 0, 0)}
SWEP.Ergonomics = 1
SWEP.AnimShootMul = 0.5
SWEP.AnimShootHandMul = 0.5
SWEP.addSprayMul = 0.5
SWEP.Penetration = 2
SWEP.ShockMultiplier = 1
SWEP.weight = 1
SWEP.NoWINCHESTERFIRE = true
SWEP.AutomaticDraw = false
SWEP.CanSuicide = true
SWEP.DeployAnim = ACT_VM_DRAW
SWEP.ShootAnim = ACT_VM_PRIMARYATTACK
SWEP.IdleAnim = ACT_VM_IDLE
SWEP.FlareSpeed = 2200
SWEP.FlareGravity = 700
SWEP.FlareStepTime = 0.025
SWEP.FlareMaxFlightTime = 6

local scorchMaterial = "FadingScorch"
local centerScorchMaterial = "Scorch"
local angZero = Angle(0, 0, 0)

local function safePaintDown(pos, materialName, ent)
    if not util or not isfunction(util.PaintDown) then
        return
    end

    util.PaintDown(pos, materialName, ent)
end

local function sendScorches(ent, positions)
    if CLIENT then return end

    net.Start("PAT_FlaregunScorch")
        net.WriteEntity(ent)
        net.WriteUInt(#positions, 8)
        for _, pos in ipairs(positions) do
            net.WriteVector(pos)
        end
    net.Broadcast()
end

local function scorchUnderRagdoll(ent)
    if not IsValid(ent) then return end

    local positions = {}
    for i = 0, ent:GetPhysicsObjectCount() - 1 do
        local phys = ent:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local pos = phys:GetPos()
            table.insert(positions, pos)

            if SERVER then
                safePaintDown(pos, scorchMaterial, ent)
            end
        end
    end

    if SERVER and #positions > 0 then
        sendScorches(ent, positions)
    end

    local mid = ent:LocalToWorld(ent:OBBCenter())
    mid.z = mid.z + 25
    safePaintDown(mid, centerScorchMaterial, ent)
end

if CLIENT then
    net.Receive("PAT_FlaregunScorch", function()
        local ent = net.ReadEntity()
        local count = net.ReadUInt(8)

        for _ = 1, count do
            safePaintDown(net.ReadVector(), scorchMaterial, ent)
        end

        if IsValid(ent) then
            safePaintDown(ent:LocalToWorld(ent:OBBCenter()), centerScorchMaterial, ent)
        end
    end)
end

local function handleWorldFlareHit(ent, tr, dmginfo)
    if not IsValid(ent) then return end

    if ent:GetClass() == "prop_ragdoll" then
        scorchUnderRagdoll(ent)
        return
    end

    if SERVER and tr and tr.HitPos then
        safePaintDown(tr.HitPos, scorchMaterial, ent)
    end
end

local function igniteNearbyGasoline(hitPos, attacker)
    if not SERVER or not hitPos or not hg or not hg.gasolinePath then return end

    for _, pathData in ipairs(hg.gasolinePath) do
        local pathPos = pathData[1]
        local ignited = pathData[2]
        if not pathPos or ignited ~= false then continue end
        if pathPos:Distance(hitPos) > 30 then continue end

        pathData[2] = CurTime()
        pathData[3] = attacker
    end
end

local function igniteDrumLeak(ent, hitPos, attacker)
    if not SERVER or not IsValid(ent) or not hitPos or not hg or not hg.drums then return end

    local drum = hg.drums[ent:EntIndex()]
    if not drum then return end

    local expData = hg.expItems and hg.expItems[ent:GetModel()]
    if not expData then return end

    for _, point in ipairs(drum.high_point or {}) do
        local localPos = point and point[1]
        if not localPos then continue end

        local worldPos = LocalToWorld(localPos, angZero, ent:GetPos(), ent:GetAngles())
        if hitPos:DistToSqr(worldPos) >= 25 then continue end

        local phys = ent:GetPhysicsObject()
        ent.owner = attacker
        hg.PropExplosion(ent, expData.ExpType, (ent.Volume or expData.Force) * 2, IsValid(phys) and phys:GetMass() or 1)
        return
    end
end

local function igniteMatchesTargets(tr, attacker)
    if not SERVER or not tr then return end

    local ent = tr.Entity
    local hitPos = tr.HitPos

    if IsValid(ent) and ent.OnMatches then
        ent:OnMatches()
    end

    igniteNearbyGasoline(hitPos, attacker)

    if IsValid(ent) then
        igniteDrumLeak(ent, hitPos, attacker)
    end
end

local function getHeadHitInfo(target, tr)
    if not IsValid(target) then return nil, false end

    local headBone = target:LookupBone("ValveBiped.Bip01_Head1")
    local headPos
    if headBone then
        local headMatrix = target:GetBoneMatrix(headBone)
        headPos = headMatrix and headMatrix:GetTranslation() or nil
    end

    if not headPos and target.EyePos then
        headPos = target:EyePos()
    end

    local isHeadHit = tr and tr.HitGroup == HITGROUP_HEAD
    if target:IsRagdoll() and tr and tr.PhysicsBone ~= nil and headBone then
        local hitBone = target:TranslatePhysBoneToBone(math.max(tonumber(tr.PhysicsBone) or 0, 0))
        if hitBone == headBone then
            isHeadHit = true
        end
    end

    return headPos, isHeadHit
end

local function handlePlayerFlareHit(wep, ply, tr, dmginfo, hitTarget)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local attacker = dmginfo:GetAttacker()
    local aimVec = IsValid(attacker) and attacker.GetAimVector and attacker:GetAimVector() or (tr.Normal * -1)
    local forceDir = (tr.Normal * -0.35 + aimVec + Vector(0, 0, 0.18)):GetNormalized()
    local playerHitDamage = IsValid(wep) and tonumber(wep.PlayerHitDamage) or 24

    dmginfo:SetDamage(math.max(playerHitDamage, tonumber(dmginfo:GetDamage()) or 0))
    dmginfo:SetDamageType(bit.bor(DMG_BURN, DMG_DIRECT))
    dmginfo:SetDamageForce(forceDir * 160)

    ply:TakeDamageInfo(dmginfo)

    if not IsValid(ply) or not ply:Alive() then
        return
    end

    local headRange = IsValid(wep) and tonumber(wep.HeadOtrubRange) or 72
    local headRadius = IsValid(wep) and tonumber(wep.HeadOtrubHitRadius) or 12
    local headTarget = IsValid(hitTarget) and hitTarget or (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply)
    local headPos, isHeadHit = getHeadHitInfo(headTarget, tr)
    if not isHeadHit and headPos and tr.HitPos then
        isHeadHit = tr.HitPos:DistToSqr(headPos) <= headRadius * headRadius
    end

    if isHeadHit and headPos and IsValid(attacker) then
        local org = ply.organism
        local closeEnough = attacker:GetShootPos():DistToSqr(headPos) <= headRange * headRange
        if org and closeEnough and not org.otrub then
            org.consciousness = 0
            org.disorientation = math.max(org.disorientation or 0, 20)
            org.shock = math.max(org.shock or 0, 70)
            org.skull = math.max(org.skull or 0, 0.75)
            org.brain = math.max(org.brain or 0, 0.08)
            org.needotrub = true
            org.lightstun = math.max(org.lightstun or 0, CurTime() + (tonumber(wep.HeadOtrubStunTime) or 6))
            ply:SetLocalVar("stun", org.lightstun)
            if hg and hg.Fake and not IsValid(ply.FakeRagdoll) then
                hg.Fake(ply, nil, true, true)
            end
            hook.Run("Org Think Call", ply, org)
        end
    end

    if ply:InVehicle() then
        ply:ExitVehicle()
    end

    timer.Simple(0, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if not hg or not hg.LightStunPlayer or not hg.AddForceRag then return end

        local ragForce = forceDir * 2800 + Vector(0, 0, 320)
        hg.AddForceRag(ply, 0, ragForce * 0.5, 0.35)
        hg.AddForceRag(ply, 1, ragForce * 0.5, 0.35)
        hg.LightStunPlayer(ply, 2.15)
    end)
end

local function applyRagdollHitForce(ragdoll, tr, dmginfo)
    if not IsValid(ragdoll) or not ragdoll:IsRagdoll() then return end

    local physBone = math.max(tonumber(tr and tr.PhysicsBone) or 0, 0)
    local hitPos = tr and tr.HitPos or ragdoll:WorldSpaceCenter()
    local hitNormal = tr and tr.HitNormal or vector_up

    local phys = ragdoll:GetPhysicsObjectNum(physBone)
    if not IsValid(phys) then
        phys = ragdoll:GetPhysicsObject()
    end
    if not IsValid(phys) then return end

    phys:Wake()
    phys:ApplyForceOffset((-hitNormal * 900 + dmginfo:GetDamageForce() * 0.65), hitPos)

    local torsoBone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
    local torsoPhysBone = torsoBone and ragdoll:TranslateBoneToPhysBone(torsoBone) or -1
    if torsoPhysBone and torsoPhysBone >= 0 and torsoPhysBone ~= physBone then
        local torsoPhys = ragdoll:GetPhysicsObjectNum(torsoPhysBone)
        if IsValid(torsoPhys) then
            torsoPhys:Wake()
            torsoPhys:ApplyForceCenter(dmginfo:GetDamageForce() * 0.35 + Vector(0, 0, 120))
        end
    end
end

function SWEP:GetFlareLaunchData()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local shootPos = owner:GetShootPos()
    local aimAng = owner:EyeAngles()
    local aimVec = aimAng:Forward()
    local launchPos = shootPos + aimAng:Right() * 2 + aimVec * 10

    return shootPos, aimVec, launchPos
end
function SWEP:ShouldDropOnDie()
    return self:Clip1() > 0
end

function SWEP:Reload()
    return false
end

function SWEP:SecondaryAttack()
    return false
end

function SWEP:DoFlareShot(pos, ang)
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local shootPos, aimVec, launchPos = self:GetFlareLaunchData()
    if not shootPos or not aimVec or not launchPos then return end

    local flareSpeed = math.max(self.FlareSpeed or 2200, 1)
    local flareGravity = math.max(self.FlareGravity or 700, 0)
    local stepTime = math.Clamp(self.FlareStepTime or 0.025, 0.01, 0.05)
    local maxFlightTime = math.max(self.FlareMaxFlightTime or 6, 0.5)
    local gravityVec = Vector(0, 0, -flareGravity)
    local filter = {owner, owner.FakeRagdoll, self}

    local flightPos = launchPos
    local flightVel = aimVec * flareSpeed
    local flightTime = 0
    local tr

    owner:LagCompensation(true)
    while flightTime < maxFlightTime do
        local nextPos = flightPos + flightVel * stepTime + gravityVec * (0.5 * stepTime * stepTime)
        tr = util.TraceHull({
            start = flightPos,
            endpos = nextPos,
            mins = Vector(-3, -3, -3),
            maxs = Vector(3, 3, 3),
            filter = filter,
            mask = MASK_SHOT
        })

        if tr and tr.Hit then
            tr.TravelTime = flightTime + stepTime * math.Clamp(tr.Fraction or 1, 0, 1)
            tr.InitialVelocity = aimVec * flareSpeed
            break
        end

        flightPos = nextPos
        flightVel = flightVel + gravityVec * stepTime
        flightTime = flightTime + stepTime
    end
    owner:LagCompensation(false)

    if not tr then
        tr = {
            Hit = false,
            HitPos = flightPos,
            EndPos = flightPos,
            TravelTime = flightTime,
            InitialVelocity = aimVec * flareSpeed
        }
    end

    local hitPos = tr.HitPos or tr.EndPos or flightPos

    local effectdata = EffectData()
    effectdata:SetEntity(self)
    effectdata:SetStart(launchPos)
    effectdata:SetOrigin(hitPos)
    effectdata:SetNormal(tr.InitialVelocity)
    effectdata:SetMagnitude(math.max(tr.TravelTime or 0.05, 0.05))
    effectdata:SetScale(2.1)
    effectdata:SetRadius(flareGravity)
    util.Effect("pat_flare_tracer", effectdata, true, true)

    local tracerTravelTime = math.max(tr.TravelTime or 0.05, 0.05)

    if tr.HitSky then
        local skyBurstPos = hitPos

        timer.Simple(tracerTravelTime, function()
            local airburst = EffectData()
            airburst:SetOrigin(skyBurstPos)
            airburst:SetNormal(vector_up)
            airburst:SetScale(2.8)
            util.Effect("pat_flare_airburst", airburst, true, true)

            local hang = EffectData()
            hang:SetOrigin(skyBurstPos)
            hang:SetScale(2.6)
            util.Effect("pat_flare_hang", hang, true, true)
        end)
    elseif tr.Hit then
        timer.Simple(tracerTravelTime, function()
            local impactdata = EffectData()
            impactdata:SetOrigin(hitPos)
            impactdata:SetNormal(tr.HitNormal)
            impactdata:SetScale(1.6)
            util.Effect("pat_flare_impact", impactdata, true, true)
        end)
    end

    igniteMatchesTargets(tr, owner)

    if not IsValid(tr.Entity) then return end

    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(owner)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamage(self.Primary.Damage)
    dmginfo:SetDamageType(bit.bor(DMG_BURN, DMG_DIRECT))
    dmginfo:SetDamagePosition(hitPos)
    dmginfo:SetDamageForce(aimVec * math.max(self.Primary.Force, 1) * 250)

    if tr.Entity:IsPlayer() then
        handlePlayerFlareHit(self, tr.Entity, tr, dmginfo, tr.Entity)
        return
    end

    if tr.Entity:IsRagdoll() and hg and hg.RagdollOwner then
        local owner = hg.RagdollOwner(tr.Entity)
        if IsValid(owner) and owner:IsPlayer() and owner:Alive() then
            scorchUnderRagdoll(tr.Entity)
            applyRagdollHitForce(tr.Entity, tr, dmginfo)
            handlePlayerFlareHit(self, owner, tr, dmginfo, tr.Entity)
            return
        end
    end

    tr.Entity:TakeDamageInfo(dmginfo)
    handleWorldFlareHit(tr.Entity, tr, dmginfo)
end

function SWEP:ConsumeWeapon()
    if CLIENT then return end

    local owner = self:GetOwner()
    timer.Simple(0.15, function()
        if not IsValid(self) then return end
        if IsValid(owner) and owner:IsPlayer() then
            if owner:HasWeapon("weapon_hands_sh") then
                owner:SelectWeapon("weapon_hands_sh")
            end
        end

        SafeRemoveEntity(self)
    end)
end

function SWEP:Shoot(override)
    if not override and not self:CanPrimaryAttack() then return false end
    if not override and not self:CanUse() then return false end
    if self:Clip1() <= 0 then
        self.LastPrimaryDryFire = CurTime()
        self:PrimaryShootEmpty()
        return false
    end

    local primary = self.Primary
    if not override and IsValid(self:GetOwner()) and not self:GetOwner():IsNPC() and primary.Next > CurTime() then return false end
    if not override and IsValid(self:GetOwner()) and not self:GetOwner():IsNPC() and (primary.NextFire or 0) > CurTime() then return false end

    primary.Next = CurTime() + primary.Wait
    self:SetLastShootTime(CurTime())

    local _, pos, ang = self:GetTrace(true)
    self:DoFlareShot(pos, ang)

    self:EmitShoot()
    self:PrimarySpread()
    self:TakePrimaryAmmo(1)

    if SERVER then
        self:SetNWInt("Clip1", self:Clip1())
    end

    self.drawBullet = false
    if self.AutomaticDraw then
        self:Draw()
    end

    if self.PlayAnim then
        self:PlayAnim("fire", 1, false, nil, false, true)
    end

    self:ConsumeWeapon()
    return true
end

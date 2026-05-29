BLOOD_COLOR_HOMELANDER_SYNTH = BLOOD_COLOR_HOMELANDER_SYNTH or 7

if not theboysbase then
    if SERVER then AddCSLuaFile("autorun/theboysbase.lua") end
    include("autorun/theboysbase.lua")
end

local TBOYS = theboysbase

local VOICE_LINE_SOUNDS = {
    "homelander/voice_line.ogg",
    "homelander/voice_line2.wav",
    "homelander/voice_line3.wav",
    "homelander/voice_line4.wav",
    "homelander/voice_line5.wav",
    "homelander/voice_line6.wav"
}
local VOICE_LINE_MIN_COOLDOWN = 5

if SERVER then
    util.AddNetworkString("HomelanderDismember")
    util.AddNetworkString("HomelanderGoreFX")
    util.AddNetworkString("HomelanderImpactFX")

    local discoveredVoiceLines = file.Find("sound/homelander/voice_line*", "GAME")
    for _, fileName in ipairs(discoveredVoiceLines or {}) do
        local lowerName = string.lower(fileName)
        if string.match(lowerName, "%.wav$") or string.match(lowerName, "%.mp3$") or string.match(lowerName, "%.ogg$") then
            local soundPath = "homelander/" .. fileName
            if not table.HasValue(VOICE_LINE_SOUNDS, soundPath) then
                VOICE_LINE_SOUNDS[#VOICE_LINE_SOUNDS + 1] = soundPath
            end
        end
    end
    table.sort(VOICE_LINE_SOUNDS)

    for _, soundPath in ipairs(VOICE_LINE_SOUNDS) do
        resource.AddFile("sound/" .. soundPath)
    end

    TBOYS.AddBaseResources()
end

TBOYS.PrecacheBaseAssets()

SWEP.PrintName = "Homelander"
SWEP.Author = "Zenius07"
SWEP.Instructions = "LMB - Punch / Grab execute\nRMB - Heat vision / Laser execute\nR - Change mode\nDouble jump - Flight\nShift + Double jump - Dash flight\nG - Voice line"
SWEP.Category = "The Boys"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.ViewModelFOV = 54
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.45
SWEP.Primary.Damage = 80
SWEP.Primary.Range = 95

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 0
SWEP.Secondary.Damage = 100
SWEP.Secondary.Range = 12000

SWEP.HomelanderLaserClass = true

local WEAPON_CLASS = "weapon_homelander"
local LASER_LOOP_SOUND = "homelander/laser.wav"
local EXECUTION_LASER_TICK_SOUND = "ambient/energy/weld2.wav"
local EXECUTION_SOUND = "homelander/execution.wav"
local EXECUTION_SOUND_2 = "homelander/execution2.wav"
local EXECUTION_SOUNDS = { EXECUTION_SOUND, EXECUTION_SOUND_2 }
local GRAB_RELEASE_SOUND = "physics/body/body_medium_impact_soft6.wav"
local GRAB_HIT_SOUNDS = {
    "physics/body/body_medium_impact_hard1.wav",
    "physics/body/body_medium_impact_hard2.wav",
    "physics/body/body_medium_impact_hard3.wav",
    "physics/body/body_medium_impact_hard5.wav",
    "physics/body/body_medium_impact_hard6.wav"
}
local PUNCH_NORMAL_SOUND = TBOYS.Sounds.PunchNormal
local PUNCH_LIGHT_SWING_SOUND = TBOYS.Sounds.PunchLightSwing
local FLIGHT_LUNGE_SOUND = TBOYS.Sounds.FlightLunge
local SONIC_STOP_SOUND = TBOYS.Sounds.SonicStop
local PROP_BREAK_SOUNDS = TBOYS.Sounds.PropBreak
local VOICE_LINE_SOUND_LEVEL = 75
local PUNCH_NORMAL_PROP_FORCE = 400
local PUNCH_STRONG_PROP_FORCE = 20000
local HOMELANDER_STRONG_PUNCH_DAMAGE = 1000
local HOMELANDER_FLIGHT_DAMAGE = 1000
local PUNCH_SHOCKWAVE_RADIUS = 50
local PUNCH_SHOCKWAVE_FORCE = 32000
local PUNCH_SHOCKWAVE_DAMAGE = 250
local PUNCH_PROP_DESTROY_RADIUS = 200
local PUNCH_PROP_SCATTER_RADIUS = 400
local PUNCH_PROP_SCATTER_FORCE = PUNCH_SHOCKWAVE_FORCE * 0.85
local PUNCH_PROP_DAMAGE = 2500
local PUNCH_HIT_DELAY = 0.12
local STRONG_PUNCH_COOLDOWN = 1
local STRONG_PUNCH_EFFECT = TBOYS.Particles.PunchHit
local SHOCKWAVE_EFFECT = TBOYS.Particles.Shockwave
local HOMELANDER_FLY_SPEED = 450
local HOMELANDER_SUPER_FLY_SPEED = 3500
local HOMELANDER_FLY_SPRINT_MULT = 1.8
local HOMELANDER_FLIGHT_LUNGE_UP_SPEED = 1650
local HOMELANDER_FLIGHT_LUNGE_FORWARD_SPEED = 260
local HOMELANDER_FLIGHT_LUNGE_DELAY = 0.45
local HOMELANDER_FLIGHT_LUNGE_GROUND_DISTANCE = 72
local HOMELANDER_FLY_DAMAGE_MIN_SPEED = 600
local HOMELANDER_SUPER_IMPACT_RADIUS = 200
local HOMELANDER_SUPER_PROP_DESTROY_RADIUS = 300
local HOMELANDER_SUPER_PROP_SCATTER_RADIUS = 400
local HOMELANDER_SUPER_PROP_SCATTER_FORCE = 90000
local HOMELANDER_SUPER_PROP_DAMAGE = 5000
local HOMELANDER_LASER_MAX_ENTITY_PENETRATIONS = 24
local HOMELANDER_LASER_MAX_WORLD_PENETRATIONS = 8
local HOMELANDER_LASER_WORLD_PENETRATION_DEPTH = 32
local HOMELANDER_SUPER_IMPACT_DAMAGE_MIN = HOMELANDER_FLIGHT_DAMAGE
local HOMELANDER_SUPER_IMPACT_DAMAGE_MAX = HOMELANDER_FLIGHT_DAMAGE
local HOMELANDER_GIB_EFFECT_TIME = 10
local HOMELANDER_GIB_CORPSE_REMOVE_DELAY = 0.08
local HOMELANDER_DEFAULT_HEALTH = 30000

local function getHomelanderSettingFloat(cvarName, fallback, minValue, maxValue)
    return TBOYS.GetSettingFloat(cvarName, fallback, minValue, maxValue)
end

local function homelanderDebugValue(value)
    local canBeValid = (isentity and isentity(value)) or (ispanel and ispanel(value))
    if canBeValid and IsValid(value) then
        return string.format("%s#%s model=%s", value:GetClass() or "entity", value:EntIndex(), value:GetModel() or "")
    end

    return tostring(value)
end

local function debugHomelanderDismember(context, fields)
    if SERVER then
        local cvar = GetConVar("homelander_sv_dismember_debug")
        if cvar and not cvar:GetBool() then return end
    elseif CLIENT then
        local cvar = GetConVar("homelander_cl_dismember_debug")
        if cvar and not cvar:GetBool() then return end
    end

    local parts = { "[HomelanderDismember]", SERVER and "[SERVER]" or "[CLIENT]", tostring(context) }
    if istable(fields) then
        for key, value in pairs(fields) do
            parts[#parts + 1] = tostring(key) .. "=" .. homelanderDebugValue(value)
        end
    end

    print(table.concat(parts, " "))
end

local HOMELANDER_MODE_NORMAL = 0
local HOMELANDER_MODE_STRONG = 1
local HOMELANDER_MODE_GRAB = 2
local HOMELANDER_GRAB_RANGE = 95
local HOMELANDER_GRAB_HOLD_DISTANCE = 34
local HOMELANDER_GRAB_RELEASE_DISTANCE = 36
local HOMELANDER_GRAB_DAMAGE = 10000
local HOMELANDER_GRAB_LASER_EXECUTION_TIME = 2
local HOMELANDER_GRAB_RAGDOLL_HOLD_OFFSET = Vector(0, 0, -15)
local HOMELANDER_GRAB_RAGDOLL_ANGLE_OFFSET = Angle(0, -90, 0)
local HOMELANDER_GRAB_RAGDOLL_HEAD_ANGLE_OFFSET = Angle(0, 0, 0)
local HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET = Vector(0, 0, 0)
local HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET = Vector(0, 0, 3)
local FLYING_DAMAGE_CLASSES = {
    prop_physics = true,
    prop_physics_multiplayer = true,
    prop_dynamic = true,
    prop_ragdoll = false,
    prop_physics_clipped = true,
    prop_door_rotating = true,
    func_breakable_surf = true,
    func_physbox = true,
    func_breakable = true
}
local HOMELANDER_VEHICLE_CLASS_HINTS = {
    "simfphys",
    "gmod_sent_vehicle",
    "sent_sakarias",
    "lvs",
    "wac",
    "scar",
    "scars",
    "sw_",
    "swv",
    "tdm",
    "photon",
    "vcmod",
    "vehicle"
}
local LEFT_EYE_ATTACHMENTS = {
    "lefteye",
    "left_eye",
    "eye_l",
    "l_eye",
    "anim_attachment_LH_Eye",
    "ValveBiped.Bip01_L_Eye"
}

local RIGHT_EYE_ATTACHMENTS = {
    "righteye",
    "right_eye",
    "eye_r",
    "r_eye",
    "anim_attachment_RH_Eye",
    "ValveBiped.Bip01_R_Eye"
}

local EYES_ATTACHMENTS = {
    "eyes",
    "eye",
    "forward"
}

local function findAttachment(ent, names)
    return TBOYS.FindAttachment(ent, names)
end

local function getAimAngles(ply)
    if not IsValid(ply) then return Angle(0, 0, 0) end
    return ply:EyeAngles()
end

local function getHomelanderEyeFallbackOffset(name, fallback)
    local cvar = GetConVar(name)
    if not cvar then return fallback end

    return math.Clamp(cvar:GetFloat(), -20, 20)
end

local function invalidateHomelanderBoneCache(ent)
    return TBOYS.InvalidateBoneCache(ent)
end

local function getHomelanderPlayerEyeFallbackOffset(ply, nwName, clientCvarName, fallback)
    if IsValid(ply) then
        local value = ply:GetNWFloat(nwName, fallback)
        if value ~= fallback then
            return math.Clamp(value, -20, 20)
        end
    end

    if CLIENT and IsValid(ply) and ply == LocalPlayer() then
        return getHomelanderEyeFallbackOffset(clientCvarName, fallback)
    end

    return fallback
end

local function HomelanderGetEyePositions(ply)
    return TBOYS.GetEyePositions(ply, {
        leftAttachments = LEFT_EYE_ATTACHMENTS,
        rightAttachments = RIGHT_EYE_ATTACHMENTS,
        centerAttachments = EYES_ATTACHMENTS,
        getSideOffset = function(target)
            return getHomelanderPlayerEyeFallbackOffset(target, "HomelanderEyeFallbackSideOffset", "homelander_cl_eye_fallback_side_offset", 1.3)
        end,
        getForwardOffset = function(target)
            return getHomelanderPlayerEyeFallbackOffset(target, "HomelanderEyeFallbackForwardOffset", "homelander_cl_eye_fallback_forward_offset", 0.45)
        end,
        getHeightOffset = function(target)
            return getHomelanderPlayerEyeFallbackOffset(target, "HomelanderEyeFallbackHeightOffset", "homelander_cl_eye_fallback_height_offset", 0)
        end
    })
end

local function isHomelanderActive(ply)
    if not IsValid(ply) then return false end

    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon:GetClass() == WEAPON_CLASS
end

local function isHomelanderCombatant(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if isHomelanderActive(ply) then return true end
    return ply.HasWeapon and ply:HasWeapon(WEAPON_CLASS)
end

local function pushPhysicsObject(ent, direction, force)
    return TBOYS.PushPhysicsObject(ent, direction, force)
end

local function combineHomelanderDamageTypes(...)
    return TBOYS.CombineDamageTypes(...)
end

local function isHomelanderCharacter(ent)
    return TBOYS.IsCharacter(ent)
end

local function isHomelanderIgnoredImpactEntity(ent)
    return TBOYS.IsIgnoredImpactEntity(ent)
end

local function isHomelanderVehicleBaseEntity(ent)
    return TBOYS.IsVehicleBaseEntity(ent, { vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS })
end

local function shouldUseHomelanderFallbackDamage(ent)
    return TBOYS.ShouldUseFallbackDamage(ent, {
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES
    })
end

local function isFlyingDamageTarget(ent, owner)
    return TBOYS.IsFlyingDamageTarget(ent, owner, {
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES
    })
end

local function isHomelanderBreakableProp(ent)
    return TBOYS.IsBreakableProp(ent)
end

local function playHomelanderPropBreakSound(ent, pos)
    if not SERVER then return end

    TBOYS.PlayRandomSound(PROP_BREAK_SOUNDS, pos, 88, math.random(96, 104), 0.8)
end

local function getHomelanderFlyingVelocity(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= WEAPON_CLASS then return vector_origin end

    return TBOYS.GetFlyingVelocity(ply, weapon, {
        superNW = "HomelanderSuperFlying",
        superSpeed = HOMELANDER_SUPER_FLY_SPEED,
        flySpeed = HOMELANDER_FLY_SPEED,
        sprintMultiplier = HOMELANDER_FLY_SPRINT_MULT,
        speedScale = 0.9
    })
end

local function slideVelocity(vel, normal)
    return TBOYS.SlideVelocity(vel, normal)
end

local function resolveHomelanderFlyingVelocity(ply, vel, collideWithEntities)
    return TBOYS.ResolveFlyingVelocity(ply, vel, collideWithEntities)
end

hook.Add("Move", "Homelander.Flying.Handle", function(ply, move)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= WEAPON_CLASS then return end
    if not weapon:GetNW2Bool("HomelanderFlying", false) then return end

    local collideWithEntities = not weapon:GetNW2Bool("HomelanderSuperFlying", false)
    local desiredVel = getHomelanderFlyingVelocity(ply)
    local vel = resolveHomelanderFlyingVelocity(ply, desiredVel, collideWithEntities)
    weapon.m_DesiredFlyingVelocity = desiredVel
    weapon.m_OverrideVelocity = vel

    if vel:LengthSqr() > 0.001 then
        move:SetOrigin(move:GetOrigin() + vel * FrameTime())
    end

    move:SetVelocity(vel)
    return true
end)

hook.Add("GetFallDamage", "Homelander.NoFallDamage", function(ply)
    if isHomelanderActive(ply) then
        return 0
    end
end)

hook.Add("PlayerFootstep", "Homelander.FlyingFootsteps", function(ply)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == WEAPON_CLASS and weapon:GetNW2Bool("HomelanderFlying", false) then
        return true
    end
end)

local function homelanderApplyGoreDismember(ragdoll, mode, boneName)
    return false
end


function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self.Calm = true
    self.LeftPunch = false
    self.RightPunch = true
    self.UpperCut = true
    self.m_OverrideVelocity = vector_origin
    self.m_NextFlyingDamageTime = {}
    util.PrecacheModel("models/props_debris/concrete_chunk03a.mdl")

    if SERVER then
        TBOYS.PrecacheBaseAssets()

        util.PrecacheSound(LASER_LOOP_SOUND)
        for _, soundPath in ipairs(EXECUTION_SOUNDS) do
            util.PrecacheSound(soundPath)
        end
        for _, soundPath in ipairs(PROP_BREAK_SOUNDS) do
            util.PrecacheSound(soundPath)
        end
        util.PrecacheSound(GRAB_RELEASE_SOUND)
        util.PrecacheSound(FLIGHT_LUNGE_SOUND)
        for _, soundPath in ipairs(GRAB_HIT_SOUNDS) do
            util.PrecacheSound(soundPath)
        end
        util.PrecacheSound(EXECUTION_LASER_TICK_SOUND)
        for _, soundPath in ipairs(VOICE_LINE_SOUNDS) do
            util.PrecacheSound(soundPath)
        end
        for i = 1, 4 do
            util.PrecacheSound("ambient/energy/spark" .. tostring(i) .. ".wav")
        end
    end
end

function SWEP:GetCurrentFlyingSpeed()
    return TBOYS.GetCurrentFlyingSpeed(self)
end

function SWEP:SetHomelanderNW2Bool(name, value)
    if not SERVER then return end

    value = value == true
    self.HomelanderNW2Cache = self.HomelanderNW2Cache or {}
    if self.HomelanderNW2Cache[name] == value and self:GetNW2Bool(name, not value) == value then return end

    self.HomelanderNW2Cache[name] = value
    self:SetNW2Bool(name, value)

    if name == "HomelanderSuperFlying" then
        if value then
            self:StartHomelanderRotorWash()
        else
            self:StopHomelanderRotorWash()
        end
    end
end

function SWEP:SetHomelanderNW2Float(name, value, epsilon)
    if not SERVER then return end

    value = tonumber(value) or 0
    epsilon = epsilon or 0
    self.HomelanderNW2Cache = self.HomelanderNW2Cache or {}

    local old = self.HomelanderNW2Cache[name]
    if old ~= nil and math.abs(old - value) <= epsilon and math.abs(self:GetNW2Float(name, value) - value) <= epsilon then return end

    self.HomelanderNW2Cache[name] = value
    self:SetNW2Float(name, value)
end

function SWEP:SetHomelanderFlying(enabled, silentStart)
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    enabled = tobool(enabled)
    if self:GetNW2Bool("HomelanderFlying", false) == enabled then return end

    self:SetHomelanderNW2Bool("HomelanderFlying", enabled)
    self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)
    timer.Remove("HomelanderSuperFlightDoubleTap" .. self:EntIndex())
    self.HomelanderCanSuperFly = false
    self.m_OverrideVelocity = vector_origin

    owner:SetLocalVelocity(owner:GetVelocity() / 3)
    owner:ViewPunchReset()
    owner:SetMoveType(enabled and MOVETYPE_NOCLIP or MOVETYPE_WALK)

    if enabled and not silentStart then
        owner:EmitSound(TBOYS.Sounds.FlightStart, 90, 100, 0.75)
    else
        self:StopHomelanderFlightLoop()
    end
end

function SWEP:DoHomelanderFlightLunge(owner)
    if not SERVER or not IsValid(owner) then return end
    if (self.HomelanderNextFlightLunge or 0) > CurTime() then return end

    local groundTrace = util.TraceHull({
        start = owner:GetPos() + vector_up * 8,
        endpos = owner:GetPos() - vector_up * (HOMELANDER_FLIGHT_LUNGE_GROUND_DISTANCE + 16),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 4),
        filter = { owner, self },
        mask = MASK_SOLID
    })

    if not groundTrace.Hit then return end
    if owner:GetPos():Distance(groundTrace.HitPos) > HOMELANDER_FLIGHT_LUNGE_GROUND_DISTANCE then return end

    self.HomelanderNextFlightLunge = CurTime() + 0.8
    self.HomelanderCanDoubleJump = false
    timer.Remove("HomelanderFlightDoubleJump" .. self:EntIndex())
    timer.Remove("HomelanderFlightLungeEnable" .. self:EntIndex())

    self:SetHomelanderNW2Bool("HomelanderFlying", false)
    self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)

    local forward = owner:EyeAngles():Forward()
    local impactPos = groundTrace.Hit and groundTrace.HitPos or owner:GetPos()
    local impactNormal = groundTrace.Hit and groundTrace.HitNormal or vector_up

    self:SendImpactFX("punch", impactPos, impactNormal, true, true)
    self:DoPunchShockwave(impactPos, forward, owner, nil, 0.5)

    local currentVelocity = owner:GetVelocity()
    local lungeVelocity = Vector(
        currentVelocity.x * 0.35 + forward.x * HOMELANDER_FLIGHT_LUNGE_FORWARD_SPEED,
        currentVelocity.y * 0.35 + forward.y * HOMELANDER_FLIGHT_LUNGE_FORWARD_SPEED,
        HOMELANDER_FLIGHT_LUNGE_UP_SPEED
    )

    owner:SetLocalVelocity(lungeVelocity)
    owner:EmitSound(FLIGHT_LUNGE_SOUND, 100, 100, 1)
    util.ScreenShake(owner:GetPos(), 4, 120, 0.45, 900, true)

    timer.Create("HomelanderFlightLungeEnable" .. self:EntIndex(), HOMELANDER_FLIGHT_LUNGE_DELAY, 1, function()
        if not IsValid(self) or not IsValid(owner) then return end
        if owner:GetActiveWeapon() ~= self then return end
        if owner.Health and owner:Health() <= 0 then return end

        self:SetHomelanderFlying(true, true)
        self:SetHomelanderNW2Bool("HomelanderSuperFlying", true)
        self:SetNW2Vector("HomelanderFlightDirection", owner:EyeAngles():Forward())
    end)
end

function SWEP:UpdateHomelanderFlightLoop()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local speed = self:GetCurrentFlyingSpeed()
    local volume = math.Clamp(speed / 2000, 0.08, 1)

    if not self.HomelanderFlightLoop or self.HomelanderFlightLoopOwner ~= owner then
        self:StopHomelanderFlightLoop()
        self.HomelanderFlightLoop = CreateSound(owner, TBOYS.Sounds.FlightLoop)
        self.HomelanderFlightLoopOwner = owner
    end

    if self.HomelanderFlightLoop then
        self.HomelanderFlightLoop:Play()
        self.HomelanderFlightLoop:ChangeVolume(volume * 0.6, 0)
        self.HomelanderFlightLoop:ChangePitch(math.Clamp(200 * (volume * 1.2), 80, 90), 0)
        self.HomelanderFlightLoop:SetSoundLevel(100 * volume)
    end
end

function SWEP:StopHomelanderFlightLoop()
    if not SERVER then return end

    if self.HomelanderFlightLoop then
        self.HomelanderFlightLoop:Stop()
        self.HomelanderFlightLoop = nil
    end

    self.HomelanderFlightLoopOwner = nil
end

function SWEP:StartHomelanderRotorWash()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if IsValid(self.HomelanderRotorWash) then return end

    local rotorWash = ents.Create("env_rotorwash_emitter")
    if not IsValid(rotorWash) then return end

    rotorWash:SetPos(owner:WorldSpaceCenter())
    rotorWash:SetParent(owner)
    rotorWash:SetLocalPos(Vector(0, 0, owner:OBBMaxs().z * 0.45))
    rotorWash:Spawn()
    rotorWash:Activate()

    self.HomelanderRotorWash = rotorWash
    self:DeleteOnRemove(rotorWash)
end

function SWEP:StopHomelanderRotorWash()
    if not SERVER then return end

    if IsValid(self.HomelanderRotorWash) then
        self.HomelanderRotorWash:Remove()
    end

    self.HomelanderRotorWash = nil
end

function SWEP:SpawnLaserDismemberFallbackGibs(pos, dir, mode)
end

function SWEP:SpawnFlightKillGibs(pos, dir, velocityScale)
end

function SWEP:FindDeathRagdoll(victim, pos, modelName)
    return NULL
end

function SWEP:RemoveDeathCorpse(corpse)
end

function SWEP:PlayExecutionSound(pos)
    if not SERVER then return end

    local owner = self:GetOwner()
    local soundPath = EXECUTION_SOUNDS[math.random(#EXECUTION_SOUNDS)] or EXECUTION_SOUND
    if pos then
        sound.Play(soundPath, pos, 100, 100, 1)
    elseif IsValid(owner) then
        owner:EmitSound(soundPath, 100, 100, 1)
    end
end

function SWEP:BroadcastGoreFX(kind, pos, dir, mode, velocityScale)
end

function SWEP:SendImpactFX(kind, pos, normal, strong, debris)
    if not SERVER or not pos then return end

    normal = normal or vector_up
    if normal:LengthSqr() <= 0.001 then
        normal = vector_up
    end
    normal:Normalize()

    net.Start("HomelanderImpactFX")
        net.WriteEntity(self)
        net.WriteString(kind or "")
        net.WriteVector(pos)
        net.WriteVector(normal)
        net.WriteBool(strong == true)
        net.WriteBool(debris == true)
    local recipients = RecipientFilter()
    recipients:AddPAS(pos)
    net.Send(recipients)
end

local HOMELANDER_BONE_MODE_HINTS = {
    head = {
        "head", "neck"
    },

    left_arm = {
        "l_upperarm", "l_forearm", "l_hand",
        "leftupperarm", "leftforearm", "lefthand",
        "left_arm", "left hand"
    },

    right_arm = {
        "r_upperarm", "r_forearm", "r_hand",
        "rightupperarm", "rightforearm", "righthand",
        "right_arm", "right hand"
    },

    left_leg = {
        "l_thigh", "l_calf", "l_foot", "l_toe",
        "leftthigh", "leftcalf", "leftfoot",
        "left_leg", "left foot"
    },

    right_leg = {
        "r_thigh", "r_calf", "r_foot", "r_toe",
        "rightthigh", "rightcalf", "rightfoot",
        "right_leg", "right foot"
    },

    upper = {
        "spine2", "spine4", "chest", "torso", "clavicle"
    },

    lower = {
        "pelvis", "hip", "spine"
    }
}

local function homelanderBoneNameMatchesMode(boneName, mode)
    if not isstring(boneName) then return false end

    local lowerName = string.lower(boneName)
    local hints = HOMELANDER_BONE_MODE_HINTS[mode]
    if not hints then return false end

    for _, hint in ipairs(hints) do
        if string.find(lowerName, hint, 1, true) then
            return true
        end
    end

    return false
end

local function homelanderGetModeFromBoneName(boneName)
    if not isstring(boneName) then return nil end

    -- РїРѕСЂСЏРґРѕРє РІР°Р¶Р»РёРІРёР№: СЃРїРѕС‡Р°С‚РєСѓ С‚РѕС‡РЅС–С€С– С‡Р°СЃС‚РёРЅРё, РїРѕС‚С–Рј torso/lower
    for _, mode in ipairs({
        "head",
        "left_arm",
        "right_arm",
        "left_leg",
        "right_leg",
        "upper",
        "lower"
    }) do
        if homelanderBoneNameMatchesMode(boneName, mode) then
            return mode
        end
    end

    return nil
end

local function homelanderGetTraceBoneName(ent, trace)
    if not IsValid(ent) or not trace then return nil end

    local physicsBone = trace.PhysicsBone
    if physicsBone and physicsBone >= 0 and ent.TranslatePhysBoneToBone then
        local bone = ent:TranslatePhysBoneToBone(physicsBone)
        if bone and bone >= 0 and ent.GetBoneName then
            local boneName = ent:GetBoneName(bone)
            if isstring(boneName) and boneName ~= "" then return boneName end
        end
    end

    if trace.HitBox and trace.HitBox >= 0 and ent.GetHitBoxBone then
        local hitBoxSet = trace.HitBoxSet or 0
        local bone = ent:GetHitBoxBone(trace.HitBox, hitBoxSet)
        if bone and bone >= 0 and ent.GetBoneName then
            local boneName = ent:GetBoneName(bone)
            if isstring(boneName) and boneName ~= "" then return boneName end
        end
    end

    return nil
end

local function homelanderGetClosestBoneMode(ent, hitPos)
    if not IsValid(ent) or not hitPos or not ent.GetBoneCount then return nil end

    local bestMode
    local bestDist

    for bone = 0, ent:GetBoneCount() - 1 do
        local boneName = ent:GetBoneName(bone)
        local mode = homelanderGetModeFromBoneName(boneName)

        if mode then
            local bonePos = ent:GetBonePosition(bone)
            if bonePos and bonePos ~= vector_origin then
                local dist = bonePos:DistToSqr(hitPos)

                if not bestDist or dist < bestDist then
                    bestDist = dist
                    bestMode = mode
                end
            end
        end
    end

    return bestMode
end

local function homelanderGetClosestDismemberBone(ent, hitPos)
    if not IsValid(ent) or not hitPos or not ent.GetBoneCount then return nil, nil end

    local bestBoneName
    local bestMode
    local bestDist

    for bone = 0, ent:GetBoneCount() - 1 do
        local boneName = ent:GetBoneName(bone)
        local mode = homelanderGetModeFromBoneName(boneName)

        if mode then
            local bonePos = ent:GetBonePosition(bone)
            if bonePos and bonePos ~= vector_origin then
                local dist = bonePos:DistToSqr(hitPos)

                if not bestDist or dist < bestDist then
                    bestDist = dist
                    bestBoneName = boneName
                    bestMode = mode
                end
            end
        end
    end

    return bestBoneName, bestMode
end

local function homelanderGetModeFromHitPos(ent, hitPos)
    if not IsValid(ent) or not hitPos then return nil end

    local mins = ent:OBBMins()
    local maxs = ent:OBBMaxs()
    local height = maxs.z - mins.z
    if height <= 1 then return nil end

    local localPos = ent:WorldToLocal(hitPos)
    local zFrac = math.Clamp((localPos.z - mins.z) / height, 0, 1)

    if zFrac >= 0.82 then
        return "head"
    elseif zFrac <= 0.45 then
        return "lower"
    end

    return "upper"
end

function SWEP:GetLaserDismemberMode(hitGroup, target, trace)
    local isNpcLike = IsValid(target) and (target:IsNPC() or (target.IsNextBot and target:IsNextBot()))

    if isNpcLike then
        local traceBoneMode = homelanderGetModeFromBoneName(homelanderGetTraceBoneName(target, trace))
        if traceBoneMode then return traceBoneMode end
    end

    -- Р”Р»СЏ NPC СЃРїРѕС‡Р°С‚РєСѓ РїСЂРѕР±СѓС”РјРѕ РєС–СЃС‚РєРё, Р±Рѕ HitGroup С‡Р°СЃС‚Рѕ Р±СЂРµС€Рµ/РґР°С” generic.
    if isNpcLike and trace and trace.HitPos then
        local boneMode = homelanderGetClosestBoneMode(target, trace.HitPos)
        if boneMode then return boneMode end
    end

    -- Р”Р»СЏ player Р°Р±Рѕ СЏРєС‰Рѕ РєС–СЃС‚РєРё РЅРµ Р·РЅР°Р№С€Р»РёСЃСЊ вЂ” СЃС‚Р°РЅРґР°СЂС‚РЅРёР№ HitGroup.
    if hitGroup == HITGROUP_HEAD then return "head" end
    if hitGroup == HITGROUP_LEFTARM then return "left_arm" end
    if hitGroup == HITGROUP_RIGHTARM then return "right_arm" end
    if hitGroup == HITGROUP_LEFTLEG then return "left_leg" end
    if hitGroup == HITGROUP_RIGHTLEG then return "right_leg" end
    if hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_STOMACH then return "upper" end
    if hitGroup == HITGROUP_GEAR then return "lower" end

    -- РЇРєС‰Рѕ HitGroup generic, РЅРµ СЂРѕР±РёРјРѕ random upper/lower.
    -- РљСЂР°С‰Рµ РїСЂРёР±Р»РёР·РЅРѕ РІРёР·РЅР°С‡РёС‚Рё РїРѕ РІРёСЃРѕС‚С– РїРѕРїР°РґР°РЅРЅСЏ.
    if IsValid(target) and trace and trace.HitPos then
        local posMode = homelanderGetModeFromHitPos(target, trace.HitPos)
        if posMode then return posMode end
    end

    return "upper"
end

function SWEP:GetLaserDismemberBone(hitGroup, target, trace, mode)
    local traceBoneName = homelanderGetTraceBoneName(target, trace)
    if traceBoneName then
        local traceBoneMode = homelanderGetModeFromBoneName(traceBoneName)
        if not mode or mode == "" or not traceBoneMode or traceBoneMode == mode then
            return traceBoneName, traceBoneMode or mode
        end
    end

    if IsValid(target) and trace and trace.HitPos then
        local boneName, boneMode = homelanderGetClosestDismemberBone(target, trace.HitPos)
        if boneName and (not mode or mode == "" or boneMode == mode) then
            return boneName, boneMode
        end
    end

    if mode == "head" then return "ValveBiped.Bip01_Head1", mode end
    if mode == "left_arm" then return "ValveBiped.Bip01_L_Forearm", mode end
    if mode == "right_arm" then return "ValveBiped.Bip01_R_Forearm", mode end
    if mode == "left_leg" then return "ValveBiped.Bip01_L_Calf", mode end
    if mode == "right_leg" then return "ValveBiped.Bip01_R_Calf", mode end
    if mode == "upper" then return "ValveBiped.Bip01_Spine2", mode end
    if mode == "lower" then return "ValveBiped.Bip01_Pelvis", mode end

    return nil, mode
end

function SWEP:BuildLaserDismemberInfo(target, trace)
    return nil
end

function SWEP:ApplyLaserDismemberInfo(target, info)
end

function SWEP:MarkLaserDismemberTarget(target, trace)
    return nil
end

function SWEP:ReserveLaserDismemberFX(key, cooldown)
    return false
end

function SWEP:TriggerLaserDismemberKillFX(target, fallbackPos, fallbackDir, fallbackMode)
end

function SWEP:TriggerInvalidLaserDismemberKillFX(info, fallbackPos, fallbackDir, fallbackMode, fallbackModel)
end

function SWEP:ApplyLaserDismemberToRagdoll(ragdoll, mode, forceVec, damageAmount, boneName)
end

function SWEP:ScheduleLaserDismemberRagdollSearch(pos, modelName, mode, dir, victim, boneName)
    return false
end

function SWEP:ScheduleRemoveDeathCorpse(victim, pos, modelName)
end

function SWEP:TriggerFlightKillFX(pos, dir, velocityScale)
end

function SWEP:CheckFlightKillFX(ent, dir, fallbackPos, wasCharacter, victimModel, velocityScale)
end

local HOMELANDER_DAMAGE_PARENT_METHODS = {
    "GetBaseEnt",
    "GetVehicle",
    "GetVehicleBase",
    "GetChassis",
    "GetBase",
    "HomelanderResolveIncapPlayer"
}

local ENT_META = FindMetaTable("Entity")
if ENT_META and not ENT_META.HomelanderResolveIncapPlayer then
    function ENT_META:HomelanderResolveIncapPlayer()
        if not IsValid(self) or self:GetClass() ~= "prop_ragdoll" then return nil end
        if not hg or not hg.RagdollOwner then return nil end
        local owner = hg.RagdollOwner(self)
        return IsValid(owner) and owner:IsPlayer() and owner or nil
    end
end

local function resolveHomelanderCharacterTarget(ent)
    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" and hg and hg.RagdollOwner then
        local incapOwner = hg.RagdollOwner(ent)
        if IsValid(incapOwner) and incapOwner:IsPlayer() then
            return incapOwner
        end
    end
    return TBOYS.ResolveCharacterTarget(ent, { damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS })
end

local function traceHomelanderCharacterHull(data)
    return TBOYS.TraceCharacterHull(data, { damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS })
end

local function traceHomelanderCharacterLine(data)
    return TBOYS.TraceCharacterLine(data, { damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS })
end

local function addHomelanderDamageTarget(targets, seen, ent)
    return TBOYS.AddDamageTarget(targets, seen, ent)
end

local function collectHomelanderDamageTargets(ent)
    return TBOYS.CollectDamageTargets(ent, { damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS })
end

function SWEP:ApplyHomelanderCompatDamage(ent, damage, options)
    options = options or {}
    options.damageParentMethods = options.damageParentMethods or HOMELANDER_DAMAGE_PARENT_METHODS
    options.vehicleClassHints = options.vehicleClassHints or HOMELANDER_VEHICLE_CLASS_HINTS
    options.flyingDamageClasses = options.flyingDamageClasses or FLYING_DAMAGE_CLASSES

    return TBOYS.ApplyCompatDamage(self, ent, damage, options)
end

function SWEP:DoHomelanderFlyingDamage()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local superFlying = self:GetNW2Bool("HomelanderSuperFlying", false)
    local velocity = self.m_DesiredFlyingVelocity or self.m_OverrideVelocity or owner:GetVelocity()
    local flightDamage = getHomelanderSettingFloat("homelander_sv_flight_damage", HOMELANDER_FLIGHT_DAMAGE, 0, 100000)

    return TBOYS.DoFlightDamage(self, {
        owner = owner,
        superFlying = superFlying,
        velocity = velocity,
        speed = self:GetCurrentFlyingSpeed(),
        minSpeed = HOMELANDER_FLY_DAMAGE_MIN_SPEED,
        damage = flightDamage,
        filter = { owner, self },
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES,
        isBlockedEntity = function(ent)
            return self:IsGrabbedEntity(ent)
        end,
        shouldSkipTarget = function(ent, isSuperFlying)
            return isHomelanderCombatant(ent) and not isSuperFlying
        end,
        scaleDamage = function(ent, amount)
            return isHomelanderCombatant(ent) and (amount * 0.1) or amount
        end,
        onTargetDamaged = function(ent, dir, killPos, wasCharacter, victimModel, isSuperFlying)
            local goreVelocityScale = isSuperFlying and 0.5 or (0.5 / 3)
            self:CheckFlightKillFX(ent, dir, killPos, wasCharacter, victimModel, goreVelocityScale)
        end,
        damageOptions = { fallbackTakeDamage = true, fallbackScale = 0.25 }
    })
end

function SWEP:HomelanderSuperFlyingCheckHit(scale)
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    local filter = { owner, self }
    if IsValid(self.HomelanderGrabbedTarget) then
        filter[#filter + 1] = self.HomelanderGrabbedTarget
    end
    if IsValid(self.HomelanderGrabbedRagdoll) then
        filter[#filter + 1] = self.HomelanderGrabbedRagdoll
    end

    return TBOYS.CheckFlightImpact(self, {
        owner = owner,
        scale = scale or 1,
        filter = filter,
        length = 90,
        mask = MASK_SOLID
    })
end

function SWEP:BreakAndScatterImpactProps(pos, aimDir, attacker, destroyRadius, scatterRadius, scatterForce, damageAmount)
    return TBOYS.BreakAndScatterImpactProps(self, {
        pos = pos,
        dir = aimDir,
        attacker = attacker,
        destroyRadius = destroyRadius,
        scatterRadius = scatterRadius,
        scatterForce = scatterForce,
        damage = damageAmount,
        onBreakProp = playHomelanderPropBreakSound,
        isBlockedEntity = function(ent)
            return self:IsGrabbedEntity(ent)
        end,
        damageOptions = { fallbackTakeDamage = true, fallbackScale = 0.3 },
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES
    })
end

function SWEP:HomelanderSuperFlyingOnHit(trace)
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local impactDir = owner:GetAimVector()
    local propDestroyRadius = getHomelanderSettingFloat("homelander_sv_flight_impact_prop_destroy_radius", HOMELANDER_SUPER_PROP_DESTROY_RADIUS, 0, 2500)
    local propScatterRadius = getHomelanderSettingFloat("homelander_sv_flight_impact_prop_scatter_radius", HOMELANDER_SUPER_PROP_SCATTER_RADIUS, 0, 3500)
    local propScatterForce = getHomelanderSettingFloat("homelander_sv_flight_impact_prop_scatter_force", HOMELANDER_SUPER_PROP_SCATTER_FORCE, 0, 300000)
    local propDamage = getHomelanderSettingFloat("homelander_sv_flight_impact_prop_damage", HOMELANDER_SUPER_PROP_DAMAGE, 0, 100000)
    local impactRadius = getHomelanderSettingFloat("homelander_sv_flight_impact_radius", HOMELANDER_SUPER_IMPACT_RADIUS, 0, 5000)
    local flightDamage = getHomelanderSettingFloat("homelander_sv_flight_damage", HOMELANDER_FLIGHT_DAMAGE, 0, 100000)

    return TBOYS.DoFlightImpact(self, {
        owner = owner,
        trace = trace,
        dir = impactDir,
        radius = impactRadius,
        damage = flightDamage,
        force = 300000,
        upForce = 200,
        shakeAmplitude = 25,
        shakeFrequency = 100,
        shakeDuration = 1,
        shakeRadius = 1500,
        propDestroyRadius = propDestroyRadius,
        propScatterRadius = propScatterRadius,
        propScatterForce = propScatterForce,
        propDamage = propDamage,
        onBreakProp = playHomelanderPropBreakSound,
        isBlockedEntity = function(ent)
            return ent == owner or self:IsGrabbedEntity(ent)
        end,
        scaleDamage = function(ent, amount)
            return isHomelanderCombatant(ent) and (amount * 0.1) or amount
        end,
        onTargetDamaged = function(ent, dir, killPos, wasCharacter, victimModel)
            self:CheckFlightKillFX(ent, dir, killPos, wasCharacter, victimModel)
        end,
        playSounds = function(soundOwner)
            TBOYS.EmitRandomSound(soundOwner, TBOYS.Sounds.SuperSpeedCrush, 100, 100, 1)
            TBOYS.EmitRandomSound(soundOwner, TBOYS.Sounds.ShockwaveHeavy, 140, 80, 0.8)
            soundOwner:EmitSound(TBOYS.Sounds.ConcreteBreak, 100, 80, 0.35)
        end,
        sendImpactFX = function(kind, pos, normal, strong, debris)
            self:SendImpactFX(kind, pos, normal, strong, debris)
        end,
        onStopSuperFlight = function()
            self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)
        end,
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES,
        damageOptions = { fallbackTakeDamage = true, fallbackScale = 0.25 }
    })
end

function SWEP:SetHomelanderMode(mode)
    if not SERVER then return end

    mode = mode % 3
    self:SetNW2Int("HomelanderMode", mode)
    self:SetHomelanderNW2Bool("HomelanderStrongPunch", mode == HOMELANDER_MODE_STRONG)
end

function SWEP:GetHomelanderMode()
    return self:GetNW2Int("HomelanderMode", HOMELANDER_MODE_NORMAL)
end

function SWEP:IsHomelanderStrongPunchMode()
    return self:GetHomelanderMode() == HOMELANDER_MODE_STRONG
        or self:GetNW2Bool("HomelanderStrongPunch", false)
end

function SWEP:IsHomelanderGrabMode()
    return self:GetHomelanderMode() == HOMELANDER_MODE_GRAB
end

function SWEP:SaveGrabbedPlayerInventory(target)
    if not SERVER or not IsValid(target) or not target:IsPlayer() then return nil end

    local saved = {
        weapons = {},
        ammo = {},
        active = IsValid(target:GetActiveWeapon()) and target:GetActiveWeapon():GetClass() or nil
    }

    for _, weapon in ipairs(target:GetWeapons()) do
        saved.weapons[#saved.weapons + 1] = weapon:GetClass()
    end

    for ammoId = 0, 255 do
        local count = target:GetAmmoCount(ammoId)
        if count and count > 0 then
            saved.ammo[ammoId] = count
        end
    end

    return saved
end

function SWEP:RestoreGrabbedPlayerInventory(target)
    if not SERVER or not IsValid(target) or not target:IsPlayer() or not self.HomelanderGrabbedInventory then return end

    local saved = self.HomelanderGrabbedInventory
    for _, className in ipairs(saved.weapons or {}) do
        if not target:HasWeapon(className) then
            target:Give(className)
        end
    end

    for ammoId, count in pairs(saved.ammo or {}) do
        target:SetAmmo(count, ammoId)
    end

    if saved.active and target:HasWeapon(saved.active) then
        target:SelectWeapon(saved.active)
    end
end

function SWEP:MaintainGrabbedNPCSuppression(target)
    if not SERVER or not IsValid(target) or not target:IsNPC() then return end

    target:SetNoDraw(true)
    target:DrawShadow(false)
    target:SetNotSolid(true)
    target:SetPos(vector_origin)
    target:SetMoveType(MOVETYPE_NONE)
    target:SetVelocity(-target:GetVelocity())
    if target.SetLocalVelocity then
        target:SetLocalVelocity(vector_origin)
    end
    if target.StopMoving then
        target:StopMoving()
    end
    if target.ClearEnemyMemory then
        target:ClearEnemyMemory()
    end
    if target.SetEnemy then
        pcall(target.SetEnemy, target, NULL)
    end
    if target.SetTarget then
        pcall(target.SetTarget, target, NULL)
    end
    if target.ClearSchedule then
        target:ClearSchedule()
    end
    if target.SetSchedule and SCHED_NONE then
        target:SetSchedule(SCHED_NONE)
    end
    if target.SetNPCState and NPC_STATE_SCRIPT then
        target:SetNPCState(NPC_STATE_SCRIPT)
    end
    if target.CapabilitiesClear then
        target:CapabilitiesClear()
    else
        local attackCaps = combineHomelanderDamageTypes(
            CAP_INNATE_RANGE_ATTACK1 or 0,
            CAP_INNATE_RANGE_ATTACK2 or 0,
            CAP_INNATE_MELEE_ATTACK1 or 0,
            CAP_INNATE_MELEE_ATTACK2 or 0,
            CAP_USE_WEAPONS or 0
        )
        if attackCaps ~= 0 and target.CapabilitiesRemove then
            target:CapabilitiesRemove(attackCaps)
        end
    end

    if target.SetSaveValue then
        local blockUntil = CurTime() + 1
        pcall(target.SetSaveValue, target, "m_flNextAttack", blockUntil)
        pcall(target.SetSaveValue, target, "m_flNextAttackTime", blockUntil)
    end

    local activeWeapon = target.GetActiveWeapon and target:GetActiveWeapon() or NULL
    if IsValid(activeWeapon) then
        if activeWeapon.SetNextPrimaryFire then
            pcall(activeWeapon.SetNextPrimaryFire, activeWeapon, CurTime() + 1)
        end
        if activeWeapon.SetNextSecondaryFire then
            pcall(activeWeapon.SetNextSecondaryFire, activeWeapon, CurTime() + 1)
        end
        if activeWeapon.SetSaveValue then
            local blockUntil = CurTime() + 1
            pcall(activeWeapon.SetSaveValue, activeWeapon, "m_flNextPrimaryAttack", blockUntil)
            pcall(activeWeapon.SetSaveValue, activeWeapon, "m_flNextSecondaryAttack", blockUntil)
        end
    end
end

function SWEP:SuppressGrabbedNPC(target)
    if not SERVER or not IsValid(target) or not target:IsNPC() then return end

    if not self.HomelanderGrabbedNPCState then
        self.HomelanderGrabbedNPCState = {
            npcState = target.GetNPCState and target:GetNPCState() or nil,
            enemy = target.GetEnemy and target:GetEnemy() or NULL,
            target = target.GetTarget and target:GetTarget() or NULL,
            capabilities = target.CapabilitiesGet and target:CapabilitiesGet() or nil
        }
    end

    self:MaintainGrabbedNPCSuppression(target)
end

function SWEP:RestoreGrabbedNPC(target)
    if not SERVER or not IsValid(target) or not target:IsNPC() then return end

    local saved = self.HomelanderGrabbedNPCState
    if not saved then return end

    if saved.capabilities and target.CapabilitiesAdd then
        target:CapabilitiesAdd(saved.capabilities)
    end
    if IsValid(saved.enemy) and target.SetEnemy then
        pcall(target.SetEnemy, target, saved.enemy)
    end
    if IsValid(saved.target) and target.SetTarget then
        pcall(target.SetTarget, target, saved.target)
    end
    if saved.npcState and target.SetNPCState then
        target:SetNPCState(saved.npcState)
    end
    if target.SetSaveValue then
        pcall(target.SetSaveValue, target, "m_flNextAttack", CurTime())
    end
    if target.ClearSchedule then
        target:ClearSchedule()
    end
end

function SWEP:ClearGrabbedTarget(restoreWeapons, preserveRagdoll, keepTargetHidden)
    if not SERVER then return end

    local target = self.HomelanderGrabbedTarget
    local ragdoll = self.HomelanderGrabbedRagdoll
    local executingTarget = self.HomelanderGrabExecutionTarget or target
    local wasExecuting = self.HomelanderGrabExecutionActive
    if IsValid(executingTarget) then
        executingTarget.HomelanderGrabExecutionPending = nil
    end
    self.HomelanderGrabExecutionActive = nil
    self.HomelanderGrabExecutionTarget = nil
    self.HomelanderGrabExecutionFinishTime = nil
    self.HomelanderNextExecutionSpark = nil
    timer.Remove("HomelanderGrabLaserExecuteFinish" .. self:EntIndex())
    self:SetNW2Bool("HomelanderGrabExecuting", false)
    if wasExecuting then
        self:SetNW2Float("HomelanderExecuteLaserUntil", 0)
        self:StopLaserLoop()
    end

    local targetIsRagdoll = IsValid(target) and target:GetClass() == "prop_ragdoll"
    local targetIsPlayerOnFakeRagdoll = IsValid(target) and target:IsPlayer()
        and IsValid(ragdoll) and self.HomelanderGrabbedRagdollOwned == false

    if IsValid(target) then
        if targetIsRagdoll then
            target:SetCollisionGroup(self.HomelanderGrabbedCollisionGroup or COLLISION_GROUP_NONE)
        elseif targetIsPlayerOnFakeRagdoll then
            target.HomelanderGrabbedBy = nil
            if not keepTargetHidden and target:Alive() and hg and hg.FakeUp then
                hg.FakeUp(target, true, true)
            end
        else
            local releasePos
            local releaseAng
            if IsValid(ragdoll) then
                releasePos = ragdoll:GetPos()
                releaseAng = Angle(0, ragdoll:GetAngles().y, 0)
            end

            local owner = self:GetOwner()
            if releasePos and IsValid(owner) then
                local releaseDir = releasePos - owner:WorldSpaceCenter()
                if releaseDir:LengthSqr() <= 0.001 then
                    releaseDir = owner:EyeAngles():Forward()
                else
                    releaseDir:Normalize()
                end

                releasePos = releasePos + releaseDir * HOMELANDER_GRAB_RELEASE_DISTANCE
            end

            if keepTargetHidden then
                target:SetNoDraw(true)
                target:DrawShadow(false)
                target:SetNotSolid(true)
            else
                target:SetNoDraw(false)
                target:DrawShadow(true)
                target:SetNotSolid(false)
            end

            if self.HomelanderGrabbedMoveType then
                target:SetMoveType(self.HomelanderGrabbedMoveType)
            end
            if not keepTargetHidden and target:IsNPC() then
                if releasePos then target:SetPos(releasePos) end
                if releaseAng then target:SetAngles(releaseAng) end
                self:RestoreGrabbedNPC(target)
            end

            if not keepTargetHidden then
                target:SetCollisionGroup(self.HomelanderGrabbedCollisionGroup or COLLISION_GROUP_NONE)
            end
        end
    end

    if IsValid(ragdoll) and not preserveRagdoll and self.HomelanderGrabbedRagdollOwned ~= false then
        ragdoll:Remove()
    end

    self.HomelanderGrabbedTarget = nil
    self.HomelanderGrabbedRagdoll = nil
    self.HomelanderGrabbedRagdollOwned = nil
    self.HomelanderGrabbedMoveType = nil
    self.HomelanderGrabbedCollisionGroup = nil
    self.HomelanderGrabbedInventory = nil
    self.HomelanderGrabbedNPCState = nil
    self:SetNW2Entity("HomelanderGrabbedTarget", NULL)
    self:SetNW2Entity("HomelanderGrabbedRagdoll", NULL)
end

function SWEP:IsGrabbedEntity(ent)
    return IsValid(ent) and (ent == self.HomelanderGrabbedTarget or ent == self.HomelanderGrabbedRagdoll)
end

function SWEP:GetGrabHoldPosition(owner)
    local ang = owner:EyeAngles()
    return owner:EyePos()
        + ang:Forward() * HOMELANDER_GRAB_HOLD_DISTANCE
        + HOMELANDER_GRAB_RAGDOLL_HOLD_OFFSET
end

function SWEP:GetTargetOutfitterModel(target)
    if not IsValid(target) then return nil, nil end

    local modelPath
    local skin
    if target.OutfitInfo then
        modelPath, _, skin = target:OutfitInfo()
    end

    modelPath = modelPath or target.outfitter_mdl
    skin = skin or target.outfitter_skin

    if (not isstring(modelPath) or modelPath == "") and target.GetNetData and outfitter and outfitter.DecodeOutfitterPayload then
        local encoded = target:GetNetData("OF")
        if isstring(encoded) and encoded ~= "" then
            modelPath = outfitter.DecodeOutfitterPayload(encoded)
        end
    end

    if not isstring(modelPath) or modelPath == "" then return nil, nil end

    local lowerPath = string.lower(modelPath)
    if not string.StartWith(lowerPath, "models/") or lowerPath:sub(-4) ~= ".mdl" then return nil, nil end
    if string.find(modelPath, "..", 1, true) or string.find(modelPath, "\n", 1, true) or string.find(modelPath, "\t", 1, true) then return nil, nil end

    return modelPath, tonumber(skin)
end

function SWEP:CreateGrabRagdoll(target)
    if not SERVER or not IsValid(target) then return NULL end

    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return NULL end

    local baseModel = target:GetModel()
    local outfitterModel, outfitterSkin = self:GetTargetOutfitterModel(target)

    ragdoll:SetModel(baseModel)
    ragdoll:SetPos(target:GetPos())
    ragdoll:SetAngles(target:GetAngles())
    ragdoll:SetSkin(target:GetSkin())
    ragdoll:SetColor(target:GetColor())
    ragdoll:SetRenderMode(target:GetRenderMode())
    ragdoll:SetMaterial(target:GetMaterial() or "")
    ragdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

    if target.GetBodyGroups then
        for _, bodygroup in ipairs(target:GetBodyGroups()) do
            ragdoll:SetBodygroup(bodygroup.id, target:GetBodygroup(bodygroup.id))
        end
    end

    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll:SetNW2String("HomelanderBaseModel", baseModel or "")
    ragdoll:SetNW2String("HomelanderOutfitterModel", outfitterModel or "")
    ragdoll:SetNW2Int("HomelanderOutfitterSkin", outfitterSkin or -1)
    ragdoll:SetNW2Entity("HomelanderOutfitterTarget", target)
    ragdoll:SetNW2Entity("HomelanderGrabVictim", target)

    local copiedPhys = {}
    if target.GetBoneCount and target.GetBonePosition then
        for bone = 0, target:GetBoneCount() - 1 do
            local physBone = ragdoll:TranslateBoneToPhysBone(bone)
            if physBone and physBone >= 0 and not copiedPhys[physBone] then
                local phys = ragdoll:GetPhysicsObjectNum(physBone)
                local pos, ang = target:GetBonePosition(bone)

                if IsValid(phys) and pos and ang then
                    phys:SetPos(pos)
                    phys:SetAngles(ang)
                    copiedPhys[physBone] = true
                end
            end
        end
    end

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:SetVelocity(vector_origin)
            phys:SetAngleVelocity(vector_origin)
        end
    end

    return ragdoll
end

function SWEP:GetGrabRagdollBodyPos(ragdoll)
    if not IsValid(ragdoll) then return vector_origin end

    local bone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
        or ragdoll:LookupBone("ValveBiped.Bip01_Spine1")
        or ragdoll:LookupBone("ValveBiped.Bip01_Spine")
        or ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")

    if bone then
        local physBone = ragdoll:TranslateBoneToPhysBone(bone)
        if physBone and physBone >= 0 then
            local phys = ragdoll:GetPhysicsObjectNum(physBone)
            if IsValid(phys) then
                return phys:GetPos() + HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET
            end
        end

        local pos = ragdoll:GetBonePosition(bone)
        if pos then
            return pos + HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET
        end
    end

    return ragdoll:WorldSpaceCenter() + HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET
end

function SWEP:GetGrabRagdollBodyPhys(ragdoll)
    if not IsValid(ragdoll) then return nil end

    local bone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
        or ragdoll:LookupBone("ValveBiped.Bip01_Spine1")
        or ragdoll:LookupBone("ValveBiped.Bip01_Spine")
        or ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")

    if bone then
        local physBone = ragdoll:TranslateBoneToPhysBone(bone)
        if physBone and physBone >= 0 then
            local phys = ragdoll:GetPhysicsObjectNum(physBone)
            if IsValid(phys) then return phys end
        end
    end

    local phys = ragdoll:GetPhysicsObject()
    if IsValid(phys) then return phys end

    return nil
end

function SWEP:GetGrabRagdollHeldPos(ragdoll)
    if not IsValid(ragdoll) then return vector_origin end

    local bodyPhys = self:GetGrabRagdollBodyPhys(ragdoll)
    if IsValid(bodyPhys) then
        return bodyPhys:GetPos() + HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET
    end

    return self:GetGrabRagdollBodyPos(ragdoll)
end

function SWEP:GetGrabRagdollHeadPos(ragdoll)
    if not IsValid(ragdoll) then return vector_origin end

    local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
        or ragdoll:LookupBone("ValveBiped.Bip01_Neck1")

    if bone then
        local physBone = ragdoll:TranslateBoneToPhysBone(bone)
        if physBone and physBone >= 0 then
            local phys = ragdoll:GetPhysicsObjectNum(physBone)
            if IsValid(phys) then return phys:GetPos() end
        end

        local pos = ragdoll:GetBonePosition(bone)
        if pos then return pos end
    end

    return ragdoll:WorldSpaceCenter() + vector_up * 28
end

function SWEP:GetGrabRagdollHeadPhys(ragdoll)
    if not IsValid(ragdoll) then return nil end

    local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
        or ragdoll:LookupBone("ValveBiped.Bip01_Neck1")

    if bone then
        local physBone = ragdoll:TranslateBoneToPhysBone(bone)
        if physBone and physBone >= 0 then
            local phys = ragdoll:GetPhysicsObjectNum(physBone)
            if IsValid(phys) then return phys end
        end
    end

    return nil
end

function SWEP:FaceGrabRagdollHeadAtOwner(ragdoll, owner)
    if not SERVER or not IsValid(ragdoll) or not IsValid(owner) then return end

    local headPhys = self:GetGrabRagdollHeadPhys(ragdoll)
    if not IsValid(headPhys) then return end

    local angularVelocity = headPhys:GetAngleVelocity()
    if angularVelocity:LengthSqr() <= 25 then return end

    headPhys:SetAngleVelocity(angularVelocity * 0.35)
end

function SWEP:HideGrabRagdollHead(ragdoll)
end

function SWEP:ThrowExecutionRagdoll(ragdoll, owner, headPos)
    if not IsValid(ragdoll) or not IsValid(owner) then return end

    ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    ragdoll:DrawShadow(true)

    local forward = owner:EyeAngles():Forward()
    local throwVelocity = forward * 210 + vector_up * 45

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:SetVelocity(throwVelocity + VectorRand() * 18)
            phys:AddAngleVelocity(VectorRand() * 55)
        end
    end

    timer.Simple(12, function()
        if IsValid(ragdoll) then
            ragdoll:Remove()
        end
    end)
end

function SWEP:SpawnExecutionHeadGib(pos, owner)
end

function SWEP:RemoveExecutionDefaultCorpse(victim, pos, modelName, preservedRagdoll)
end

function SWEP:GetGrabLaserExecutionHitInfo(owner, target, ragdoll)
    if not IsValid(owner) then return vector_origin, vector_up, vector_up end

    local headCenter
    if IsValid(ragdoll) then
        headCenter = self:GetGrabRagdollHeadPos(ragdoll)
    elseif IsValid(target) then
        headCenter = target:WorldSpaceCenter() + vector_up * 28
    else
        headCenter = owner:EyePos() + owner:EyeAngles():Forward() * 64
    end

    local aimDir = headCenter - owner:EyePos()
    if aimDir:LengthSqr() <= 0.001 then
        aimDir = owner:EyeAngles():Forward()
    else
        aimDir:Normalize()
    end

    local hitPos = headCenter - aimDir * 6
    local hitNormal = -aimDir

    if IsValid(ragdoll) then
        local trace = util.TraceLine({
            start = owner:EyePos(),
            endpos = headCenter + aimDir * 18,
            filter = owner,
            mask = MASK_SHOT
        })

        if trace.Hit and trace.Entity == ragdoll then
            hitPos = trace.HitPos
            hitNormal = trace.HitNormal
        end
    end

    return hitPos, aimDir, hitNormal
end

function SWEP:ApplyExecutionFaceDecals(ragdoll, hitPos, hitNormal)
    if not SERVER or not IsValid(ragdoll) then return end

    if not hitNormal or hitNormal:LengthSqr() <= 0.001 then
        hitNormal = vector_up
    else
        hitNormal = hitNormal:GetNormalized()
    end

    local startPos = hitPos + hitNormal * 10
    local endPos = hitPos - hitNormal * 12
    util.Decal("Blood", startPos, endPos, ragdoll)
    util.Decal("FadingScorch", startPos + VectorRand() * 1.5, endPos, ragdoll)
end

function SWEP:UpdateGrabLaserExecution()
    if not SERVER or not self.HomelanderGrabExecutionActive then return end

    local owner = self:GetOwner()
    local target = self.HomelanderGrabbedTarget
    if not IsValid(owner) or not IsValid(target) or owner:GetActiveWeapon() ~= self then
        self:ClearGrabbedTarget()
        return
    end

    local ragdoll = self.HomelanderGrabbedRagdoll
    local hitPos, aimDir, hitNormal = self:GetGrabLaserExecutionHitInfo(owner, target, ragdoll)
    self:SetNW2Vector("HomelanderHitPos", hitPos)
    self:SetNW2Vector("HomelanderHitNormal", hitNormal)
    self:SetNW2Float("HomelanderLastShot", CurTime())
    self:SetNW2Float("HomelanderExecuteLaserUntil", self.HomelanderGrabExecutionFinishTime or (CurTime() + 0.1))

    if (self.HomelanderNextExecutionSpark or 0) <= CurTime() then
        self.HomelanderNextExecutionSpark = CurTime() + 0.35
        sound.Play("ambient/energy/spark" .. tostring(math.random(1, 4)) .. ".wav", hitPos, 82, 105)
        owner:EmitSound(EXECUTION_LASER_TICK_SOUND, 75, 105, 0.45)
    end

    return hitPos, aimDir, hitNormal
end

function SWEP:FinishGrabLaserExecution()
    if not SERVER or not self.HomelanderGrabExecutionActive then return end

    local owner = self:GetOwner()
    local target = self.HomelanderGrabbedTarget
    if not IsValid(owner) or not IsValid(target) then
        self:ClearGrabbedTarget()
        return
    end

    local executionRagdoll = self.HomelanderGrabbedRagdoll
    local hitPos, aimDir, hitNormal = self:GetGrabLaserExecutionHitInfo(owner, target, executionRagdoll)

    self:ApplyExecutionFaceDecals(executionRagdoll, hitPos, hitNormal)

    self:ClearGrabbedTarget(false, false, true)
    owner:SetAnimation(PLAYER_ATTACK1)

    local damage = DamageInfo()
    damage:SetAttacker(owner)
    damage:SetInflictor(self)
    damage:SetDamage(HOMELANDER_GRAB_DAMAGE)
    damage:SetDamageType(DMG_ENERGYBEAM + DMG_BURN)
    damage:SetDamagePosition(hitPos)
    damage:SetDamageForce(aimDir * 9000)
    target:TakeDamageInfo(damage)

    if target:IsPlayer() and target:Alive() then
        target:Kill()
    end

    self:SendImpactFX("execution_blood", hitPos, hitNormal, false, false)
    sound.Play("ambient/energy/spark" .. tostring(math.random(1, 4)) .. ".wav", hitPos, 100, 100)
    self:SetNW2Vector("HomelanderHitPos", hitPos)
    self:SetNW2Vector("HomelanderHitNormal", hitNormal)
    self:SetNW2Float("HomelanderLastShot", CurTime())
    self:SetNW2Float("HomelanderExecuteLaserUntil", CurTime() + 0.2)
    self:PlayExecutionSound(hitPos)

    timer.Create("HomelanderGrabExecuteCalmDown" .. self:EntIndex(), 0.6, 1, function()
        if IsValid(self) then
            self:StopLaserLoop()
            self:SetHoldType(self.HoldType)
        end
    end)
end

function SWEP:StartGrabLaserExecution()
    if not SERVER or self.HomelanderGrabExecutionActive then return end

    local owner = self:GetOwner()
    local target = self.HomelanderGrabbedTarget
    if not IsValid(owner) or not IsValid(target) then
        self:ClearGrabbedTarget()
        return
    end

    local finishTime = CurTime() + HOMELANDER_GRAB_LASER_EXECUTION_TIME
    self.HomelanderGrabExecutionActive = true
    self.HomelanderGrabExecutionTarget = target
    self.HomelanderGrabExecutionFinishTime = finishTime
    target.HomelanderGrabExecutionPending = true
    self:SetNW2Bool("HomelanderGrabExecuting", true)
    self:SetNW2Float("HomelanderExecuteLaserUntil", finishTime)
    self:SetNextPrimaryFire(finishTime + 0.25)
    self:SetNextSecondaryFire(finishTime + 0.25)

    owner:SetAnimation(PLAYER_ATTACK1)
    self:StartLaserLoop()
    self:UpdateGrabLaserExecution()

    timer.Create("HomelanderGrabLaserExecuteFinish" .. self:EntIndex(), HOMELANDER_GRAB_LASER_EXECUTION_TIME, 1, function()
        if IsValid(self) then
            self:FinishGrabLaserExecution()
        end
    end)
end

function SWEP:TryGrabTarget()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local startPos = owner:EyePos()
    local aimDir = owner:EyeAngles():Forward()

    owner:LagCompensation(true)

    local trace = traceHomelanderCharacterHull({
        start = startPos,
        endpos = startPos + aimDir * HOMELANDER_GRAB_RANGE,
        filter = owner,
        mins = Vector(-14, -14, -14),
        maxs = Vector(14, 14, 14),
        mask = MASK_SHOT
    })

    owner:LagCompensation(false)

    local target

    if IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_ragdoll" then
        target = trace.Entity
    else
        target = resolveHomelanderCharacterTarget(trace.Entity)
        if not IsValid(target) or not (target:IsPlayer() or target:IsNPC() or (target.IsNextBot and target:IsNextBot())) then
            owner:EmitSound("WeaponFrag.Throw", 65, 80, 0.4)
            return
        end
        if target:IsPlayer() and isHomelanderCombatant(target) then
            owner:EmitSound("WeaponFrag.Throw", 65, 80, 0.4)
            return
        end
    end

    self:ClearGrabbedTarget()
    self.HomelanderGrabbedTarget = target
    self.HomelanderGrabbedMoveType = target:GetMoveType()
    self.HomelanderGrabbedCollisionGroup = target:GetCollisionGroup()

    if target:GetClass() == "prop_ragdoll" then
        self.HomelanderGrabbedInventory = nil
        self.HomelanderGrabbedRagdoll = target
        self.HomelanderGrabbedRagdollOwned = false
        target:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    elseif target:IsPlayer() then
        self.HomelanderGrabbedInventory = nil
        target.HomelanderGrabbedBy = self

        if not IsValid(target.FakeRagdoll) and hg and hg.Fake then
            hg.Fake(target, nil, true, true)
        end

        if not IsValid(target.FakeRagdoll) then
            self:ClearGrabbedTarget()
            owner:EmitSound("WeaponFrag.Throw", 65, 80, 0.4)
            return
        end

        self.HomelanderGrabbedRagdoll = target.FakeRagdoll
        self.HomelanderGrabbedRagdollOwned = false
    else
        self.HomelanderGrabbedInventory = nil
        self.HomelanderGrabbedRagdoll = self:CreateGrabRagdoll(target)
        self.HomelanderGrabbedRagdollOwned = true
        if not IsValid(self.HomelanderGrabbedRagdoll) then
            self:ClearGrabbedTarget()
            owner:EmitSound("WeaponFrag.Throw", 65, 80, 0.4)
            return
        end

        target:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        target:SetNoDraw(true)
        target:DrawShadow(false)
        target:SetNotSolid(true)
        target:SetMoveType(MOVETYPE_NONE)
        if target:IsNPC() then
            self:SuppressGrabbedNPC(target)
        end
    end

    self:SetNW2Entity("HomelanderGrabbedTarget", target)
    self:SetNW2Entity("HomelanderGrabbedRagdoll", self.HomelanderGrabbedRagdoll)

    self:SetHoldType(self.HoldType)
    owner:EmitSound(GRAB_HIT_SOUNDS[math.random(#GRAB_HIT_SOUNDS)], 85, 85, 0.75)
end

function SWEP:UpdateGrabbedTarget()
    if not SERVER then return end

    local owner = self:GetOwner()
    local target = self.HomelanderGrabbedTarget
    if not IsValid(owner) or not IsValid(target) or owner:GetActiveWeapon() ~= self then
        self:ClearGrabbedTarget()
        return
    end

    if (target.Health and target:Health() <= 0) or (owner.Health and owner:Health() <= 0) then
        self:ClearGrabbedTarget()
        return
    end

    local holdPos = self:GetGrabHoldPosition(owner)
    local ragdoll = self.HomelanderGrabbedRagdoll
    if IsValid(ragdoll) then
        local bodyPhys = self:GetGrabRagdollBodyPhys(ragdoll)
        local bodyPos = self:GetGrabRagdollHeldPos(ragdoll)
        local delta = holdPos - bodyPos
        local faceDir = owner:WorldSpaceCenter() - bodyPos
        local faceYaw = owner:EyeAngles().y

        if faceDir:LengthSqr() > 0.001 then
            faceYaw = faceDir:Angle().y
        end

        local holdAngles = Angle(-90, faceYaw + HOMELANDER_GRAB_RAGDOLL_ANGLE_OFFSET.y, 0)

        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local phys = ragdoll:GetPhysicsObjectNum(i)
            if IsValid(phys) then
                phys:EnableMotion(true)
                phys:Wake()
            end
        end

        if IsValid(bodyPhys) then
            if delta:LengthSqr() > 14400 then
                bodyPhys:SetPos(bodyPhys:GetPos() + delta)
                bodyPhys:SetVelocity(vector_origin)
            else
                bodyPhys:SetVelocity(delta * 18)
            end

            bodyPhys:SetAngles(holdAngles)
            bodyPhys:SetAngleVelocity(vector_origin)
        else
            ragdoll:SetVelocity(delta * 18)
            ragdoll:SetAngles(holdAngles)
        end

        self:FaceGrabRagdollHeadAtOwner(ragdoll, owner)
    end

    if target == ragdoll then return end

    if target:IsPlayer() then
        if (target.HomelanderNextGrabWeaponStrip or 0) <= CurTime() then
            target.HomelanderNextGrabWeaponStrip = CurTime() + 0.2
            if #target:GetWeapons() > 0 then
                target:StripWeapons()
            end
        end
    elseif target:IsNPC() then
        self:MaintainGrabbedNPCSuppression(target)
    else
        target:SetPos(IsValid(ragdoll) and ragdoll:GetPos() or holdPos)
    end
    if not target:IsPlayer() and not target:IsNPC() then
        target:SetAngles(Angle(0, owner:EyeAngles().y + 180, 0))
    end
    if not target:IsPlayer() then
        target:SetVelocity(-target:GetVelocity())

        local phys = target:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(vector_origin)
            phys:Wake()
        end
    end
end

function SWEP:ExecuteGrabbedTarget(useLaser)
    if not SERVER then return end

    if useLaser then
        self:StartGrabLaserExecution()
        return
    end

    if self.HomelanderGrabExecutionActive then return end

    local owner = self:GetOwner()
    local target = self.HomelanderGrabbedTarget
    if not IsValid(owner) or not IsValid(target) then
        self:ClearGrabbedTarget()
        return
    end

    local grabbedRagdoll = self.HomelanderGrabbedRagdoll
    local bodyPos = IsValid(grabbedRagdoll) and self:GetGrabRagdollBodyPos(grabbedRagdoll) or target:WorldSpaceCenter()
    local ragdollHeadPos = IsValid(grabbedRagdoll) and self:GetGrabRagdollHeadPos(grabbedRagdoll) or nil
    local hitPos = bodyPos
    local aimDir = (hitPos - owner:EyePos()):GetNormalized()
    if aimDir:LengthSqr() <= 0.001 then
        aimDir = owner:EyeAngles():Forward()
    end

    local executionRagdoll = grabbedRagdoll
    local victimModel = target:GetModel()
    local headPos = ragdollHeadPos or hitPos + vector_up * 28

    if IsValid(executionRagdoll) then
        self:HideGrabRagdollHead(executionRagdoll)
        self:ThrowExecutionRagdoll(executionRagdoll, owner, headPos)
        self:SpawnExecutionHeadGib(headPos, owner)
    end

    self:ClearGrabbedTarget(false, true, true)
    owner:SetAnimation(PLAYER_ATTACK1)

    local damage = DamageInfo()
    damage:SetAttacker(owner)
    damage:SetInflictor(self)
    damage:SetDamage(HOMELANDER_GRAB_DAMAGE)
    damage:SetDamageType(DMG_CLUB)
    damage:SetDamagePosition(hitPos)
    damage:SetDamageForce(aimDir * 14000)
    target:TakeDamageInfo(damage)

    if target:IsPlayer() and target:Alive() then
        target:Kill()
    end

    self:RemoveExecutionDefaultCorpse(target, hitPos, victimModel, executionRagdoll)

    self:SendImpactFX("execution_blood", hitPos, aimDir, false, false)
    self:PlayExecutionSound(hitPos)

    timer.Create("HomelanderGrabExecuteCalmDown" .. self:EntIndex(), 0.6, 1, function()
        if IsValid(self) then
            self:StopLaserLoop()
            self:SetHoldType(self.HoldType)
        end
    end)
end

function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        self:ApplyHomelanderProtection(owner)

        self:SetHomelanderNW2Bool("HomelanderEquipped", true)
        self:SetHomelanderNW2Bool("HomelanderFiring", false)
        self:SetHomelanderNW2Bool("HomelanderFlying", false)
        self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)
        self:SetHomelanderMode(self:GetNW2Int("HomelanderMode", HOMELANDER_MODE_NORMAL))
        self:SetHomelanderNW2Float("HomelanderCharge", 0.35)
    end

    self.Calm = true
    self.LeftPunch = false
    self.RightPunch = true
    self.UpperCut = true
    self.HomelanderFistsDrawn = false
    self:SetHoldType(self.HoldType)

    return true
end

function SWEP:Holster()
    if SERVER then
        self:StopLaserLoop()
        self:StopHomelanderFlightLoop()
        self:StopHomelanderRotorWash()
        self:ClearGrabbedTarget()
        self:SetHomelanderFlying(false)
        self:DisableHomelanderGod()
        timer.Remove("HomelanderPunchCalmDown" .. self:EntIndex())
        timer.Remove("HomelanderGrabExecuteCalmDown" .. self:EntIndex())
        timer.Remove("HomelanderFlightDoubleJump" .. self:EntIndex())
        timer.Remove("HomelanderFlightLungeEnable" .. self:EntIndex())
        timer.Remove("HomelanderSuperFlightDoubleTap" .. self:EntIndex())
        self.HomelanderCanDoubleJump = false
        self.HomelanderCanSuperFly = false
        self.HomelanderFistsDrawn = false
        self.Calm = true
        self.LeftPunch = false
        self.RightPunch = true
        self.UpperCut = true
        self:SetHoldType(self.HoldType)
        self:SetHomelanderNW2Bool("HomelanderEquipped", false)
        self:SetHomelanderNW2Bool("HomelanderFiring", false)
    end

    return true
end

function SWEP:OnRemove()
    if SERVER then
        self:StopLaserLoop()
        self:StopHomelanderFlightLoop()
        self:StopHomelanderRotorWash()
        self:ClearGrabbedTarget()
        self:SetHomelanderFlying(false)
        self:DisableHomelanderGod()
        timer.Remove("HomelanderPunchCalmDown" .. self:EntIndex())
        timer.Remove("HomelanderGrabExecuteCalmDown" .. self:EntIndex())
        timer.Remove("HomelanderFlightDoubleJump" .. self:EntIndex())
        timer.Remove("HomelanderFlightLungeEnable" .. self:EntIndex())
        timer.Remove("HomelanderSuperFlightDoubleTap" .. self:EntIndex())
        self.HomelanderCanDoubleJump = false
        self.HomelanderCanSuperFly = false
        self.HomelanderFistsDrawn = false
        self.Calm = true
        self.LeftPunch = false
        self.RightPunch = true
        self.UpperCut = true
        self:SetHomelanderNW2Bool("HomelanderEquipped", false)
        self:SetHomelanderNW2Bool("HomelanderFiring", false)
    end
end

function SWEP:DisableHomelanderGod()
    if not SERVER then return end

    local owner = self:GetOwner()
    if IsValid(owner) and self.HomelanderAppliedGod then
        owner:GodDisable()
    end

    self.HomelanderAppliedGod = false
end

function SWEP:RestoreHomelanderProtection()
    if not SERVER then return end

    local owner = self:GetOwner()
    self:DisableHomelanderGod()
end

function SWEP:ApplyHomelanderProtection(owner)
    if not SERVER then return end

    owner = owner or self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local godMode = getHomelanderSettingFloat("homelander_sv_owner_godmode", 0, 0, 1) >= 0.5
    if godMode then
        if not owner:HasGodMode() then
            self.HomelanderAppliedGod = true
            owner:GodEnable()
        end
    elseif self.HomelanderAppliedGod then
        owner:GodDisable()
        self.HomelanderAppliedGod = false
    end

    if owner.HomelanderSWEPHealthGranted then return end

    local healthAmount = math.floor(getHomelanderSettingFloat("homelander_sv_owner_health", HOMELANDER_DEFAULT_HEALTH, 1000, 100000))
    if owner:GetMaxHealth() ~= healthAmount then
        owner:SetMaxHealth(healthAmount)
    end

    owner:SetHealth(healthAmount)
    owner.HomelanderSWEPHealthGranted = true
end

function SWEP:StartLaserLoop()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if self.HomelanderLaserLoop and self.HomelanderLaserLoopOwner == owner then
        return
    end

    self:StopLaserLoop()

    self.HomelanderLaserLoop = CreateSound(owner, LASER_LOOP_SOUND)
    self.HomelanderLaserLoopOwner = owner

    if self.HomelanderLaserLoop then
        self.HomelanderLaserLoop:PlayEx(0.85, 100)
    end
end

function SWEP:StopLaserLoop()
    if not SERVER then return end

    if self.HomelanderLaserLoop then
        self.HomelanderLaserLoop:Stop()
        self.HomelanderLaserLoop = nil
    end

    self.HomelanderLaserLoopOwner = nil
end

function SWEP:PrimaryAttack()
    if SERVER then
        if self.HomelanderGrabExecutionActive then return end

        if IsValid(self.HomelanderGrabbedTarget) then
            self:ExecuteGrabbedTarget(false)
            return
        end

        if self:IsHomelanderGrabMode() then
            local now = CurTime()
            if self:GetNextPrimaryFire() > now then return end

            self:SetNextPrimaryFire(now + self.Primary.Delay)
            self:TryGrabTarget()
            return
        end
    end

    local now = CurTime()
    if self:GetNextPrimaryFire() > now then return end

    local strong = self:IsHomelanderStrongPunchMode()
    if strong and (self.HomelanderNextStrongPunch or 0) > now then
        self:SetNextPrimaryFire(self.HomelanderNextStrongPunch)
        return
    end

    local nextFire = now + (strong and STRONG_PUNCH_COOLDOWN or self.Primary.Delay)
    self:SetNextPrimaryFire(nextFire)

    if SERVER then
        self:StartHomelanderPunch(strong, nextFire)
    end
end

function SWEP:SecondaryAttack()
    if SERVER and self.HomelanderGrabExecutionActive then return end

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    if SERVER and IsValid(self.HomelanderGrabbedTarget) then
        self:ExecuteGrabbedTarget(true)
    end
end

function SWEP:Reload()
    if CLIENT then return end

    self.NextPunchModeToggle = self.NextPunchModeToggle or 0
    if self.NextPunchModeToggle > CurTime() then return end
    if self.HomelanderGrabExecutionActive then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if IsValid(self.HomelanderGrabbedTarget) then
        self:ClearGrabbedTarget()
        owner:EmitSound(GRAB_RELEASE_SOUND, 70, 100, 0.8)
        self.NextPunchModeToggle = CurTime() + 0.35
        return
    end

    local mode = (self:GetHomelanderMode() + 1) % 3
    self:SetHomelanderMode(mode)

    self.NextPunchModeToggle = CurTime() + 0.35
    self:SetNW2Float("HomelanderModePopupUntil", CurTime() + 1.15)
end

function SWEP:Think()
    if CLIENT then return end

    local owner = self:GetOwner()
    local active = isHomelanderActive(owner)
    self:UpdateGrabbedTarget()
    self:UpdateGrabLaserExecution()

    if active then
        self:ApplyHomelanderProtection(owner)
    end

    if IsValid(owner) and active and owner:KeyPressed(IN_JUMP) then
        if not self.HomelanderCanDoubleJump then
            self.HomelanderCanDoubleJump = true
            timer.Create("HomelanderFlightDoubleJump" .. self:EntIndex(), 0.3, 1, function()
                if IsValid(self) then
                    self.HomelanderCanDoubleJump = false
                end
            end)
        elseif not owner:Crouching() then
            self.HomelanderCanDoubleJump = false
            timer.Remove("HomelanderFlightDoubleJump" .. self:EntIndex())
            //if owner:KeyDown(IN_SPEED) and not self:GetNW2Bool("HomelanderFlying", false) and owner:IsOnGround() then
            if owner:KeyDown(IN_SPEED) and not self:GetNW2Bool("HomelanderFlying", false) then
                self:DoHomelanderFlightLunge(owner)
            else
                self:SetHomelanderFlying(not self:GetNW2Bool("HomelanderFlying", false))
            end
        end
    end

    if IsValid(owner) and active and self:GetNW2Bool("HomelanderFlying", false) then
        if self:GetNW2Bool("HomelanderSuperFlying", false) then
            self:SetNW2Vector("HomelanderFlightDirection", owner:EyeAngles():Forward())
        end

        if owner:KeyPressed(IN_SPEED) then
            if not self.HomelanderCanSuperFly then
                self.HomelanderCanSuperFly = true
                timer.Create("HomelanderSuperFlightDoubleTap" .. self:EntIndex(), 0.3, 1, function()
                    if IsValid(self) then
                        self.HomelanderCanSuperFly = false
                    end
                end)
            else
                self.HomelanderCanSuperFly = false
                timer.Remove("HomelanderSuperFlightDoubleTap" .. self:EntIndex())
                self:SetHomelanderNW2Bool("HomelanderSuperFlying", true)
                TBOYS.EmitRandomSound(owner, TBOYS.Sounds.SonicBoom, 90, 100, 1)
                util.ScreenShake(owner:GetPos(), 5, 155, 1.2, 1600, true)
            end
        end

        if owner:KeyReleased(IN_SPEED) and self:GetNW2Bool("HomelanderSuperFlying", false) then
            self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)
            owner:EmitSound(SONIC_STOP_SOUND, 90, 100, 1)
        end

        self:DoHomelanderFlyingDamage()
        self:UpdateHomelanderFlightLoop()

        if self:GetNW2Bool("HomelanderSuperFlying", false) then
            local hit, trace = self:HomelanderSuperFlyingCheckHit()
            if hit then
                self:HomelanderSuperFlyingOnHit(trace)
            end
        end
    elseif self:GetNW2Bool("HomelanderSuperFlying", false) then
        self:SetHomelanderNW2Bool("HomelanderSuperFlying", false)
    else
        self:StopHomelanderFlightLoop()
    end

    local executeLaser = self:GetNW2Float("HomelanderExecuteLaserUntil", 0) > CurTime()
    local firing = (IsValid(owner) and owner:KeyDown(IN_ATTACK2) and active and not IsValid(self.HomelanderGrabbedTarget)) or executeLaser
    local charge = self:GetNW2Float("HomelanderCharge", 0)
    local targetCharge = firing and 1 or 0.35

    charge = math.Approach(charge, targetCharge, FrameTime() * (firing and 3.8 or 2))

    self:SetHomelanderNW2Bool("HomelanderEquipped", active)
    self:SetHomelanderNW2Bool("HomelanderFiring", firing)
    self:SetHomelanderNW2Float("HomelanderCharge", charge, 0.01)

    if firing and not executeLaser then
        self:StartLaserLoop()
        self:FireHeatVision()
    elseif executeLaser then
        if self.HomelanderGrabExecutionActive then
            self:StartLaserLoop()
        else
            self:StopLaserLoop()
        end
    else
        self:StopLaserLoop()
    end

    if IsValid(owner) and self.HomelanderNextIdle and self.HomelanderNextIdle <= CurTime() then
        self.HomelanderNextIdle = nil

        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local idleSeq = vm:LookupSequence("fists_idle_01")
            if idleSeq and idleSeq >= 0 then
                vm:SendViewModelMatchingSequence(idleSeq)
            end
        end
    end
end

function SWEP:PlayPunchGesture(owner, strong)
    if not IsValid(owner) then return end

    if not owner:IsPlayer() then return end

    local vm = owner:GetViewModel()
    if not IsValid(vm) then return end

    local sequenceName
    if not self.LeftPunch and self.RightPunch and self.UpperCut then
        self.LeftPunch = true
        self.RightPunch = false
        sequenceName = "fists_left"
    elseif self.LeftPunch and not self.RightPunch and self.UpperCut then
        self.LeftPunch = true
        self.RightPunch = true
        self.UpperCut = false
        sequenceName = "fists_right"
    elseif self.LeftPunch and self.RightPunch and not self.UpperCut then
        self.LeftPunch = false
        self.RightPunch = true
        self.UpperCut = true
        sequenceName = "fists_uppercut"
    end

    local sequence = vm:LookupSequence(sequenceName)
    if not sequence or sequence < 0 then return end

    vm:SendViewModelMatchingSequence(sequence)
    self.HomelanderNextIdle = CurTime() + vm:SequenceDuration() / math.max(vm:GetPlaybackRate(), 0.01)
end

function SWEP:StartHomelanderPunch(strong, nextFire)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if strong == nil then
        strong = self:IsHomelanderStrongPunchMode()
    end

    if SERVER and strong then
        local now = CurTime()
        self.HomelanderNextStrongPunch = self.HomelanderNextStrongPunch or 0
        if self.HomelanderNextStrongPunch > now then
            self:SetNextPrimaryFire(self.HomelanderNextStrongPunch)
            return
        end

        self.HomelanderNextStrongPunch = nextFire or (now + STRONG_PUNCH_COOLDOWN)
        self:SetNextPrimaryFire(self.HomelanderNextStrongPunch)
    end

    self:SetHoldType("fist")

    if self.Calm and owner:IsPlayer() then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local drawSeq = vm:LookupSequence("fists_draw")
            if drawSeq and drawSeq >= 0 then
                vm:SendViewModelMatchingSequence(drawSeq)
            end
        end

        self.HomelanderFistsDrawn = true
    end

    self.Calm = false

    self:PlayPunchGesture(owner, strong)

    if strong then
        TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchSwing, 100, 90, 0.8)
        TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchHeavySwing, 90, math.random(97, 103), 0.45)
    else
        owner:EmitSound(PUNCH_LIGHT_SWING_SOUND, 100, math.random(97, 103), 0.8)
    end

    self.HomelanderPunchSerial = (self.HomelanderPunchSerial or 0) + 1
    local punchId = self.HomelanderPunchSerial
    self.HomelanderPendingPunch = punchId
    self.HomelanderPendingPunchStrong = strong

    timer.Simple(PUNCH_HIT_DELAY, function()
        if not IsValid(self) or self.HomelanderPendingPunch ~= punchId then return end
        if not IsValid(owner) or owner:GetActiveWeapon() ~= self then return end

        self:DoHomelanderPunch(strong)
    end)

    timer.Create("HomelanderPunchCalmDown" .. self:EntIndex(), 1, 1, function()
        if not IsValid(self) then return end
        local timerOwner = self:GetOwner()

        if IsValid(timerOwner) and timerOwner:IsPlayer() then
            local vm = timerOwner:GetViewModel()
            if IsValid(vm) then
                local holsterSeq = vm:LookupSequence("fists_holster")
                if holsterSeq and holsterSeq >= 0 then
                    vm:SendViewModelMatchingSequence(holsterSeq)
                end
            end
        end

        self.HomelanderFistsDrawn = false
        self.HomelanderPendingPunchStrong = nil
        self.Calm = true
        self.LeftPunch = false
        self.RightPunch = true
        self.UpperCut = true
        self:SetHoldType(self.HoldType)
    end)
end

function SWEP:DoPunchShockwave(pos, aimDir, owner, directHit, soundVolumeScale)
    local shockwaveRadius = getHomelanderSettingFloat("homelander_sv_strong_punch_shockwave_radius", PUNCH_SHOCKWAVE_RADIUS, 0, 3000)
    local shockwaveForce = getHomelanderSettingFloat("homelander_sv_strong_punch_shockwave_force", PUNCH_SHOCKWAVE_FORCE, 0, 250000)
    local shockwaveDamage = getHomelanderSettingFloat("homelander_sv_strong_punch_shockwave_damage", PUNCH_SHOCKWAVE_DAMAGE, 0, 50000)
    local propDestroyRadius = getHomelanderSettingFloat("homelander_sv_strong_punch_prop_destroy_radius", PUNCH_PROP_DESTROY_RADIUS, 0, 1500)
    local propScatterRadius = getHomelanderSettingFloat("homelander_sv_strong_punch_prop_scatter_radius", PUNCH_PROP_SCATTER_RADIUS, 0, 2500)
    local propScatterForce = getHomelanderSettingFloat("homelander_sv_strong_punch_prop_scatter_force", PUNCH_PROP_SCATTER_FORCE, 0, 250000)
    local propDamage = getHomelanderSettingFloat("homelander_sv_strong_punch_prop_damage", PUNCH_PROP_DAMAGE, 0, 50000)

    soundVolumeScale = math.Clamp(tonumber(soundVolumeScale) or 1, 0, 2)

    return TBOYS.DoShockwave(self, {
        pos = pos,
        dir = aimDir,
        owner = owner,
        directHit = directHit,
        radius = shockwaveRadius,
        force = shockwaveForce,
        damage = shockwaveDamage,
        propDestroyRadius = propDestroyRadius,
        propScatterRadius = propScatterRadius,
        propScatterForce = propScatterForce,
        propDamage = propDamage,
        soundVolumeScale = soundVolumeScale,
        onBreakProp = playHomelanderPropBreakSound,
        sendImpactFX = function(kind, fxPos, normal, strong, debris)
            self:SendImpactFX(kind, fxPos, normal, strong, debris)
        end,
        playSounds = function(soundOwner, _, volumeScale)
            if volumeScale <= 0 then return end
            TBOYS.EmitRandomSound(soundOwner, TBOYS.Sounds.ShockwaveHeavy, 120, 90, 0.95 * volumeScale)
            soundOwner:EmitSound(TBOYS.Sounds.PunchEarthquake, 110, 90, 0.8 * volumeScale)
        end,
        isBlockedEntity = function(ent)
            return self:IsGrabbedEntity(ent)
        end,
        scaleDamage = function(ent, amount)
            return isHomelanderCombatant(ent) and (amount * 0.1) or amount
        end,
        onCharacterDamaged = function(ent, dir, killPos, wasCharacter, victimModel)
            self:CheckFlightKillFX(ent, dir, killPos, wasCharacter, victimModel)
        end,
        damageOptions = { fallbackTakeDamage = true, fallbackScale = 0.3 },
        vehicleClassHints = HOMELANDER_VEHICLE_CLASS_HINTS,
        flyingDamageClasses = FLYING_DAMAGE_CLASSES
    })
end

function SWEP:DoHomelanderPunch(strong)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if strong == nil then
        strong = self.HomelanderPendingPunchStrong
    end
    if strong == nil then
        strong = self:IsHomelanderStrongPunchMode()
    end

    local punchDamage = strong
        and getHomelanderSettingFloat("homelander_sv_strong_punch_damage", HOMELANDER_STRONG_PUNCH_DAMAGE, 0, 50000)
        or getHomelanderSettingFloat("homelander_sv_normal_punch_damage", self.Primary.Damage, 0, 50000)
    local punchForce = strong and PUNCH_STRONG_PROP_FORCE or PUNCH_NORMAL_PROP_FORCE

    return TBOYS.DoMeleePunch(self, {
        owner = owner,
        range = self.Primary.Range,
        damage = punchDamage,
        force = punchForce,
        filter = owner,
        mins = Vector(-12, -12, -12),
        maxs = Vector(12, 12, 12),
        mask = MASK_SHOT,
        solidMask = MASK_SOLID,
        traceOptions = {
            damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS
        },
        damageType = combineHomelanderDamageTypes(DMG_CLUB, DMG_CRUSH, DMG_VEHICLE or 0, strong and (DMG_ALWAYSGIB or 0) or 0),
        damageOptions = { fallbackTakeDamage = true, fallbackScale = strong and 0.35 or 0.2 },
        onMiss = function(trace, aimDir)
            if trace.Hit then
                self:SendImpactFX("punch", trace.HitPos, trace.HitNormal, strong, strong)

                if strong then
                    TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchLightHit, 120, math.random(97, 103), 1)
                else
                    owner:EmitSound(PUNCH_NORMAL_SOUND, 120, math.random(97, 103), 1)
                end
            end

            if strong and trace.Hit then
                TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchHeavyHit, 120, math.random(97, 103), 1)
                owner:EmitSound(TBOYS.Sounds.PunchHeavyBass, 100, 50, 1, CHAN_AUTO, 0, 29)
                self:DoPunchShockwave(trace.HitPos, aimDir, owner)
            end

            if strong and not trace.Hit then
                owner:EmitSound("WeaponFrag.Throw", 70, 80, 0.55)
                TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchMiss, 80, 100, 0.55)
            end
        end,
        onPreDamageHit = function(ent, trace, _, hitCharacter)
            local doImpactArea = strong and not hitCharacter
            self:SendImpactFX("punch", trace.HitPos, trace.HitNormal, doImpactArea, doImpactArea)
        end,
        onHit = function(ent, trace, aimDir, hitCharacter, killPos, victimModel)
            if strong and hitCharacter then
                timer.Simple(0, function()
                    if IsValid(self) then
                        self:CheckFlightKillFX(ent, aimDir, killPos, hitCharacter, victimModel)
                    end
                end)
            end

            if strong then
                TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchLightHit, 120, math.random(97, 103), 1)
                owner:EmitSound(TBOYS.Sounds.PunchHeavyBass, 100, 50, 1, CHAN_AUTO, 0, 29)
            else
                owner:EmitSound(PUNCH_NORMAL_SOUND, 120, math.random(97, 103), 1)
            end

            if strong and not hitCharacter then
                TBOYS.EmitRandomSound(owner, TBOYS.Sounds.PunchHeavyHit, 120, math.random(97, 103), 1)
                util.ScreenShake(owner:GetPos(), 350, 359, 0.75, 2500, true)
                self:DoPunchShockwave(trace.HitPos, aimDir, owner, ent)
            elseif strong then
                util.ScreenShake(owner:GetPos(), 70, 120, 0.25, 700, true)
            end
        end
    })
end

function SWEP:DoLaserBurnImpact(trace, aimDir)
    if not SERVER or not trace or not trace.Hit or trace.HitSky then return end

    local normal = trace.HitNormal or -aimDir
    if normal:LengthSqr() <= 0.001 then normal = -aimDir end
    normal:Normalize()

    local now = CurTime()
    self.HomelanderLaserBurnImpactTimes = self.HomelanderLaserBurnImpactTimes or {}
    local key = tostring(math.floor(trace.HitPos.x / 12)) .. ":"
        .. tostring(math.floor(trace.HitPos.y / 12)) .. ":"
        .. tostring(math.floor(trace.HitPos.z / 12))

    if (self.HomelanderLaserBurnImpactTimes[key] or 0) > now then return end
    self.HomelanderLaserBurnImpactTimes[key] = now + 0.08

    if (self.HomelanderNextLaserBurnImpactCleanup or 0) <= now then
        self.HomelanderNextLaserBurnImpactCleanup = now + 2
        for burnKey, expireTime in pairs(self.HomelanderLaserBurnImpactTimes) do
            if expireTime < now - 1 then
                self.HomelanderLaserBurnImpactTimes[burnKey] = nil
            end
        end
    end

    local hitEnt = IsValid(trace.Entity) and trace.Entity or nil
    util.Decal("FadingScorch", trace.HitPos + normal * 2, trace.HitPos - normal * 12, hitEnt)
    self:SendImpactFX("laser_burn", trace.HitPos, normal, false, false)

    if (self.HomelanderNextLaserBurnSound or 0) <= now then
        self.HomelanderNextLaserBurnSound = now + 0.12
        sound.Play("ambient/energy/spark" .. tostring(math.random(1, 4)) .. ".wav", trace.HitPos, 82, 115, 0.65)
    end
end

local HITGROUP_TO_LIMB = {
    [HITGROUP_LEFTLEG] = "lleg",
    [HITGROUP_RIGHTLEG] = "rleg",
    [HITGROUP_LEFTARM] = "larm",
    [HITGROUP_RIGHTARM] = "rarm",
}

local LIMB_TO_BONE = {
    lleg = "ValveBiped.Bip01_L_Calf",
    rleg = "ValveBiped.Bip01_R_Calf",
    larm = "ValveBiped.Bip01_L_Forearm",
    rarm = "ValveBiped.Bip01_R_Forearm",
}

local function homelanderGibRagdollLimb(rag, limb)
    if not IsValid(rag) or not Gib_RemoveBone then return false end

    local boneName = LIMB_TO_BONE[limb]
    if not boneName then return false end

    local bone = rag:LookupBone(boneName)
    if not bone or bone < 0 then return false end

    local physBone = rag:TranslateBoneToPhysBone(bone)
    if not physBone or physBone < 0 then return false end

    rag.gibRemove = rag.gibRemove or {}
    if rag.gibRemove[physBone] then return true end

    Gib_RemoveBone(rag, bone, physBone)
    if SpawnMeatGore then
        local pos = select(1, rag:GetBonePosition(bone)) or rag:WorldSpaceCenter()
        SpawnMeatGore(rag, pos, 4)
    end
    return true
end

local function homelanderResolveTraceHitGroup(ent, trace)
    if not IsValid(ent) or not trace then return HITGROUP_GENERIC end

    if hg and hg.bonetohitgroup then
        local physBone = trace.PhysicsBone
        if physBone and physBone >= 0 and ent.TranslatePhysBoneToBone then
            local bone = ent:TranslatePhysBoneToBone(physBone)
            if bone and bone >= 0 then
                local boneName = ent:GetBoneName(bone)
                local hg_ = boneName and hg.bonetohitgroup[boneName]
                if hg_ then return hg_ end
            end
        end

        if ent.GetBoneCount and trace.HitPos then
            local bestHG, bestDist
            for b = 0, ent:GetBoneCount() - 1 do
                local boneName = ent:GetBoneName(b)
                local mapped = boneName and hg.bonetohitgroup[boneName]
                if mapped then
                    local bonePos = ent:GetBonePosition(b)
                    if bonePos and bonePos ~= vector_origin then
                        local d = bonePos:DistToSqr(trace.HitPos)
                        if not bestDist or d < bestDist then
                            bestDist = d
                            bestHG = mapped
                        end
                    end
                end
            end
            if bestHG then return bestHG end
        end
    end

    return trace.HitGroup or HITGROUP_GENERIC
end

function SWEP:HomelanderApplyZcityDismember(hitEnt, trace)
    if not SERVER or not IsValid(hitEnt) or not trace then return end

    local hitGroup = homelanderResolveTraceHitGroup(hitEnt, trace)

    if hitGroup == HITGROUP_HEAD then
        local headSubject = hitEnt
        if hitEnt:IsPlayer() and IsValid(hitEnt.FakeRagdoll) then
            headSubject = hitEnt.FakeRagdoll
        end
        if headSubject.HomelanderHeadExploded then return end
        headSubject.HomelanderHeadExploded = true
        if hg and hg.ExplodeHead then hg.ExplodeHead(headSubject) end
        return
    end

    local limb = HITGROUP_TO_LIMB[hitGroup]
    if not limb then return end

    if hitEnt:GetClass() == "prop_ragdoll" then
        homelanderGibRagdollLimb(hitEnt, limb)
        return
    end

    if not hg or not hg.organism or not hg.organism.AmputateLimb then return end

    local org = hitEnt.organism
    if not org or org[limb .. "amputated"] then return end

    hg.organism.AmputateLimb(org, limb)
end

function SWEP:FireHeatVision()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local aimDir = owner:EyeAngles():Forward()
    local laserDamage = getHomelanderSettingFloat("homelander_sv_laser_damage", self.Secondary.Damage, 1, 100000)
    local penetrationEnabled = getHomelanderSettingFloat("homelander_sv_laser_penetration_enabled", 1, 0, 1) >= 0.5
    local entityPenetrations = math.floor(getHomelanderSettingFloat(
        "homelander_sv_laser_entity_penetrations",
        HOMELANDER_LASER_MAX_ENTITY_PENETRATIONS,
        0,
        32
    ))
    local worldPenetrationDepth = math.floor(getHomelanderSettingFloat(
        "homelander_sv_laser_world_thickness",
        HOMELANDER_LASER_WORLD_PENETRATION_DEPTH,
        0,
        256
    ))
    self:SetHomelanderNW2Bool("HomelanderLaserPenetrationEnabled", penetrationEnabled)
    self:SetHomelanderNW2Float("HomelanderLaserEntityPenetrations", entityPenetrations, 0.5)
    self:SetHomelanderNW2Float("HomelanderLaserWorldThickness", worldPenetrationDepth, 0.5)

    return TBOYS.FireLaser(self, {
        owner = owner,
        dir = aimDir,
        range = self.Secondary.Range,
        filter = owner,
        damage = laserDamage,
        penetrate = penetrationEnabled,
        maxTracePasses = math.min(entityPenetrations + HOMELANDER_LASER_MAX_WORLD_PENETRATIONS + 1, 40),
        maxEntityPenetrations = entityPenetrations,
        maxWorldPenetrations = HOMELANDER_LASER_MAX_WORLD_PENETRATIONS,
        worldPenetrationDepth = worldPenetrationDepth,
        worldPenetrationStep = math.max(6, worldPenetrationDepth / 8),
        traceOptions = {
            damageParentMethods = HOMELANDER_DAMAGE_PARENT_METHODS
        },
        onTrace = function(trace)
            self:SetNW2Vector("HomelanderHitPos", trace.HitPos)
            self:SetNW2Vector("HomelanderHitNormal", trace.HitNormal)
            self:SetNW2Float("HomelanderLastShot", CurTime())

            local hitEnt = trace.Entity
            if IsValid(hitEnt) and hitEnt:GetClass() == "prop_ragdoll" then
                self:HomelanderApplyZcityDismember(hitEnt, trace)
            end
        end,
        scaleDamage = function(hitTarget, amount)
            return isHomelanderCombatant(hitTarget) and (amount * 0.1) or amount
        end,
        afterCharacterDamage = function(hitEnt, trace, _, killPos, killDir, victimModel, wasDead)
            if not IsValid(hitEnt) then return end
            self:HomelanderApplyZcityDismember(hitEnt, trace)
        end,
        onWorldHit = function(trace)
            self:DoLaserBurnImpact(trace, aimDir)
        end,
        onWorldExit = function(trace, _, _, exitPos)
            if trace and trace.Hit then
                self:DoLaserBurnImpact(trace, aimDir)
                return
            end

            self:DoLaserBurnImpact({
                Hit = true,
                HitSky = false,
                HitPos = exitPos,
                HitNormal = -aimDir,
                Entity = Entity(0)
            }, aimDir)
        end,
        shouldPenetrateEntity = function(ent)
            return not self:IsGrabbedEntity(ent)
        end,
        damageOptions = { fallbackTakeDamage = true, fallbackScale = 0.25 }
    })
end


HomelanderSWEPShared = HomelanderSWEPShared or {}
local HOMELANDER_SHARED = HomelanderSWEPShared
HOMELANDER_SHARED.addHomelanderDamageTarget = addHomelanderDamageTarget
HOMELANDER_SHARED.collectHomelanderDamageTargets = collectHomelanderDamageTargets
HOMELANDER_SHARED.combineHomelanderDamageTypes = combineHomelanderDamageTypes
HOMELANDER_SHARED.EXECUTION_LASER_TICK_SOUND = EXECUTION_LASER_TICK_SOUND
HOMELANDER_SHARED.EXECUTION_SOUND = EXECUTION_SOUND
HOMELANDER_SHARED.EXECUTION_SOUND_2 = EXECUTION_SOUND_2
HOMELANDER_SHARED.EXECUTION_SOUNDS = EXECUTION_SOUNDS
HOMELANDER_SHARED.EYES_ATTACHMENTS = EYES_ATTACHMENTS
HOMELANDER_SHARED.findAttachment = findAttachment
HOMELANDER_SHARED.FLYING_DAMAGE_CLASSES = FLYING_DAMAGE_CLASSES
HOMELANDER_SHARED.getAimAngles = getAimAngles
HOMELANDER_SHARED.getHomelanderEyeFallbackOffset = getHomelanderEyeFallbackOffset
HOMELANDER_SHARED.getHomelanderFlyingVelocity = getHomelanderFlyingVelocity
HOMELANDER_SHARED.getHomelanderPlayerEyeFallbackOffset = getHomelanderPlayerEyeFallbackOffset
HOMELANDER_SHARED.getHomelanderSettingFloat = getHomelanderSettingFloat
HOMELANDER_SHARED.debugHomelanderDismember = debugHomelanderDismember
HOMELANDER_SHARED.GRAB_HIT_SOUNDS = GRAB_HIT_SOUNDS
HOMELANDER_SHARED.GRAB_RELEASE_SOUND = GRAB_RELEASE_SOUND
HOMELANDER_SHARED.HOMELANDER_DAMAGE_PARENT_METHODS = HOMELANDER_DAMAGE_PARENT_METHODS
HOMELANDER_SHARED.HOMELANDER_DEFAULT_HEALTH = HOMELANDER_DEFAULT_HEALTH
HOMELANDER_SHARED.THEBOYS_DISMEMBER_BONES = TBOYS.DismemberBones
HOMELANDER_SHARED.HOMELANDER_FLIGHT_DAMAGE = HOMELANDER_FLIGHT_DAMAGE
HOMELANDER_SHARED.HOMELANDER_FLY_DAMAGE_MIN_SPEED = HOMELANDER_FLY_DAMAGE_MIN_SPEED
HOMELANDER_SHARED.HOMELANDER_FLY_SPEED = HOMELANDER_FLY_SPEED
HOMELANDER_SHARED.HOMELANDER_FLY_SPRINT_MULT = HOMELANDER_FLY_SPRINT_MULT
HOMELANDER_SHARED.HOMELANDER_GIB_CORPSE_REMOVE_DELAY = HOMELANDER_GIB_CORPSE_REMOVE_DELAY
HOMELANDER_SHARED.HOMELANDER_GIB_EFFECT_TIME = HOMELANDER_GIB_EFFECT_TIME
HOMELANDER_SHARED.HOMELANDER_GRAB_DAMAGE = HOMELANDER_GRAB_DAMAGE
HOMELANDER_SHARED.HOMELANDER_GRAB_HOLD_DISTANCE = HOMELANDER_GRAB_HOLD_DISTANCE
HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_ANGLE_OFFSET = HOMELANDER_GRAB_RAGDOLL_ANGLE_OFFSET
HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET = HOMELANDER_GRAB_RAGDOLL_BODY_OFFSET
HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET = HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET
HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_HEAD_ANGLE_OFFSET = HOMELANDER_GRAB_RAGDOLL_HEAD_ANGLE_OFFSET
HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_HOLD_OFFSET = HOMELANDER_GRAB_RAGDOLL_HOLD_OFFSET
HOMELANDER_SHARED.HOMELANDER_GRAB_RANGE = HOMELANDER_GRAB_RANGE
HOMELANDER_SHARED.HOMELANDER_GRAB_RELEASE_DISTANCE = HOMELANDER_GRAB_RELEASE_DISTANCE
HOMELANDER_SHARED.HOMELANDER_MODE_NORMAL = HOMELANDER_MODE_NORMAL
HOMELANDER_SHARED.HOMELANDER_MODE_STRONG = HOMELANDER_MODE_STRONG
HOMELANDER_SHARED.HOMELANDER_MODE_GRAB = HOMELANDER_MODE_GRAB
HOMELANDER_SHARED.HOMELANDER_STRONG_PUNCH_DAMAGE = HOMELANDER_STRONG_PUNCH_DAMAGE
HOMELANDER_SHARED.HOMELANDER_SUPER_FLY_SPEED = HOMELANDER_SUPER_FLY_SPEED
HOMELANDER_SHARED.HOMELANDER_SUPER_IMPACT_DAMAGE_MAX = HOMELANDER_SUPER_IMPACT_DAMAGE_MAX
HOMELANDER_SHARED.HOMELANDER_SUPER_IMPACT_DAMAGE_MIN = HOMELANDER_SUPER_IMPACT_DAMAGE_MIN
HOMELANDER_SHARED.HOMELANDER_SUPER_IMPACT_RADIUS = HOMELANDER_SUPER_IMPACT_RADIUS
HOMELANDER_SHARED.HOMELANDER_SUPER_PROP_DAMAGE = HOMELANDER_SUPER_PROP_DAMAGE
HOMELANDER_SHARED.HOMELANDER_SUPER_PROP_DESTROY_RADIUS = HOMELANDER_SUPER_PROP_DESTROY_RADIUS
HOMELANDER_SHARED.HOMELANDER_SUPER_PROP_SCATTER_FORCE = HOMELANDER_SUPER_PROP_SCATTER_FORCE
HOMELANDER_SHARED.HOMELANDER_SUPER_PROP_SCATTER_RADIUS = HOMELANDER_SUPER_PROP_SCATTER_RADIUS
HOMELANDER_SHARED.HOMELANDER_VEHICLE_CLASS_HINTS = HOMELANDER_VEHICLE_CLASS_HINTS
HOMELANDER_SHARED.homelanderApplyGoreDismember = homelanderApplyGoreDismember
HOMELANDER_SHARED.HomelanderGetEyePositions = HomelanderGetEyePositions
HOMELANDER_SHARED.invalidateHomelanderBoneCache = invalidateHomelanderBoneCache
HOMELANDER_SHARED.isFlyingDamageTarget = isFlyingDamageTarget
HOMELANDER_SHARED.isHomelanderActive = isHomelanderActive
HOMELANDER_SHARED.isHomelanderBreakableProp = isHomelanderBreakableProp
HOMELANDER_SHARED.isHomelanderCharacter = isHomelanderCharacter
HOMELANDER_SHARED.isHomelanderCombatant = isHomelanderCombatant
HOMELANDER_SHARED.isHomelanderIgnoredImpactEntity = isHomelanderIgnoredImpactEntity
HOMELANDER_SHARED.isHomelanderVehicleBaseEntity = isHomelanderVehicleBaseEntity
HOMELANDER_SHARED.LASER_LOOP_SOUND = LASER_LOOP_SOUND
HOMELANDER_SHARED.LEFT_EYE_ATTACHMENTS = LEFT_EYE_ATTACHMENTS
HOMELANDER_SHARED.playHomelanderPropBreakSound = playHomelanderPropBreakSound
HOMELANDER_SHARED.PROP_BREAK_SOUNDS = PROP_BREAK_SOUNDS
HOMELANDER_SHARED.PUNCH_HIT_DELAY = PUNCH_HIT_DELAY
HOMELANDER_SHARED.PUNCH_LIGHT_SWING_SOUND = PUNCH_LIGHT_SWING_SOUND
HOMELANDER_SHARED.PUNCH_NORMAL_PROP_FORCE = PUNCH_NORMAL_PROP_FORCE
HOMELANDER_SHARED.PUNCH_NORMAL_SOUND = PUNCH_NORMAL_SOUND
HOMELANDER_SHARED.PUNCH_PROP_DAMAGE = PUNCH_PROP_DAMAGE
HOMELANDER_SHARED.PUNCH_PROP_DESTROY_RADIUS = PUNCH_PROP_DESTROY_RADIUS
HOMELANDER_SHARED.PUNCH_PROP_SCATTER_FORCE = PUNCH_PROP_SCATTER_FORCE
HOMELANDER_SHARED.PUNCH_PROP_SCATTER_RADIUS = PUNCH_PROP_SCATTER_RADIUS
HOMELANDER_SHARED.PUNCH_SHOCKWAVE_DAMAGE = PUNCH_SHOCKWAVE_DAMAGE
HOMELANDER_SHARED.PUNCH_SHOCKWAVE_FORCE = PUNCH_SHOCKWAVE_FORCE
HOMELANDER_SHARED.PUNCH_SHOCKWAVE_RADIUS = PUNCH_SHOCKWAVE_RADIUS
HOMELANDER_SHARED.PUNCH_STRONG_PROP_FORCE = PUNCH_STRONG_PROP_FORCE
HOMELANDER_SHARED.pushPhysicsObject = pushPhysicsObject
HOMELANDER_SHARED.resolveHomelanderCharacterTarget = resolveHomelanderCharacterTarget
HOMELANDER_SHARED.resolveHomelanderFlyingVelocity = resolveHomelanderFlyingVelocity
HOMELANDER_SHARED.RIGHT_EYE_ATTACHMENTS = RIGHT_EYE_ATTACHMENTS
HOMELANDER_SHARED.SHOCKWAVE_EFFECT = SHOCKWAVE_EFFECT
HOMELANDER_SHARED.shouldUseHomelanderFallbackDamage = shouldUseHomelanderFallbackDamage
HOMELANDER_SHARED.slideVelocity = slideVelocity
HOMELANDER_SHARED.SONIC_STOP_SOUND = SONIC_STOP_SOUND
HOMELANDER_SHARED.STRONG_PUNCH_COOLDOWN = STRONG_PUNCH_COOLDOWN
HOMELANDER_SHARED.STRONG_PUNCH_EFFECT = STRONG_PUNCH_EFFECT
HOMELANDER_SHARED.traceHomelanderCharacterHull = traceHomelanderCharacterHull
HOMELANDER_SHARED.traceHomelanderCharacterLine = traceHomelanderCharacterLine
HOMELANDER_SHARED.VOICE_LINE_MIN_COOLDOWN = VOICE_LINE_MIN_COOLDOWN
HOMELANDER_SHARED.VOICE_LINE_SOUND_LEVEL = VOICE_LINE_SOUND_LEVEL
HOMELANDER_SHARED.VOICE_LINE_SOUNDS = VOICE_LINE_SOUNDS
HOMELANDER_SHARED.WEAPON_CLASS = WEAPON_CLASS

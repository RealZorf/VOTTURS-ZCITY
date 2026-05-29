
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local HOMELANDER_SHARED = HomelanderSWEPShared
local getHomelanderSettingFloat = HOMELANDER_SHARED.getHomelanderSettingFloat
local debugHomelanderDismember = HOMELANDER_SHARED.debugHomelanderDismember or function() end
local isHomelanderCharacter = HOMELANDER_SHARED.isHomelanderCharacter
local VOICE_LINE_MIN_COOLDOWN = HOMELANDER_SHARED.VOICE_LINE_MIN_COOLDOWN
local VOICE_LINE_SOUND_LEVEL = HOMELANDER_SHARED.VOICE_LINE_SOUND_LEVEL
local VOICE_LINE_SOUNDS = HOMELANDER_SHARED.VOICE_LINE_SOUNDS
local WEAPON_CLASS = HOMELANDER_SHARED.WEAPON_CLASS

if SERVER then
    local function getHomelanderGrabberWeapon(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return nil end

        local weapon = ply.HomelanderGrabbedBy
        if IsValid(weapon) and weapon:GetClass() == WEAPON_CLASS and weapon.HomelanderGrabbedTarget == ply then
            return weapon
        end

        ply.HomelanderGrabbedBy = nil
        return nil
    end

    local function isHomelanderGrabbedVictim(ply)
        return IsValid(getHomelanderGrabberWeapon(ply))
    end

    local blockedGrabbedVictimSpawnHooks = {
        "PlayerSpawnObject",
        "PlayerSpawnProp",
        "PlayerSpawnEffect",
        "PlayerSpawnNPC",
        "PlayerSpawnVehicle",
        "PlayerSpawnRagdoll",
        "PlayerSpawnSENT",
        "PlayerSpawnSWEP",
        "PlayerGiveSWEP",
        "CanTool",
        "CanProperty",
        "CanPlayerEnterVehicle",
        "PlayerNoClip",
        "PhysgunPickup",
        "GravGunPickupAllowed"
    }

    for _, hookName in ipairs(blockedGrabbedVictimSpawnHooks) do
        hook.Add(hookName, "Homelander.BlockGrabbedVictimActions", function(ply)
            if isHomelanderGrabbedVictim(ply) then
                return false
            end
        end)
    end

    hook.Add("PlayerSwitchWeapon", "Homelander.BlockGrabbedVictimWeaponSwitch", function(ply)
        if isHomelanderGrabbedVictim(ply) then
            return true
        end
    end)

    hook.Add("StartCommand", "Homelander.BlockGrabbedVictimCombatInput", function(ply, cmd)
        if not isHomelanderGrabbedVictim(ply) then return end

        cmd:RemoveKey(bit.bor(
            IN_ATTACK or 0,
            IN_ATTACK2 or 0,
            IN_RELOAD or 0,
            IN_USE or 0,
            IN_ZOOM or 0,
            IN_GRENADE1 or 0,
            IN_GRENADE2 or 0
        ))
        cmd:ClearMovement()
    end)

    local function pickHomelanderVoiceLine(ply)
        if #VOICE_LINE_SOUNDS <= 1 then return VOICE_LINE_SOUNDS[1] end

        local soundPath = VOICE_LINE_SOUNDS[math.random(#VOICE_LINE_SOUNDS)]
        if soundPath == ply.HomelanderLastVoiceLine then
            for _ = 1, 6 do
                soundPath = VOICE_LINE_SOUNDS[math.random(#VOICE_LINE_SOUNDS)]
                if soundPath ~= ply.HomelanderLastVoiceLine then break end
            end
        end

        if soundPath == ply.HomelanderLastVoiceLine then
            local index = table.KeyFromValue(VOICE_LINE_SOUNDS, soundPath) or 1
            soundPath = VOICE_LINE_SOUNDS[(index % #VOICE_LINE_SOUNDS) + 1]
        end

        ply.HomelanderLastVoiceLine = soundPath
        return soundPath
    end

    local function getHomelanderVoiceLineCooldown(soundPath)
        local duration = 0
        if SoundDuration then
            duration = SoundDuration(soundPath) or 0
        end

        if duration <= 0 then
            return VOICE_LINE_MIN_COOLDOWN
        end

        return VOICE_LINE_MIN_COOLDOWN
    end

    hook.Add("PlayerButtonDown", "Homelander.VoiceLineKey", function(ply, button)
        if button ~= KEY_G then return end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= WEAPON_CLASS then return end

        if ply.HomelanderNextVoiceLine and ply.HomelanderNextVoiceLine > CurTime() then return end

        local soundPath = pickHomelanderVoiceLine(ply)
        if not soundPath then return end

        ply.HomelanderNextVoiceLine = CurTime() + getHomelanderVoiceLineCooldown(soundPath)
        ply:EmitSound(soundPath, VOICE_LINE_SOUND_LEVEL, 100, 1)
    end)

    hook.Add("EntityTakeDamage", "Homelander.PreventOwnerSelfDamage", function(target, damage)
        if not IsValid(target) or not target:IsPlayer() or not damage then return end

        local inflictor = damage:GetInflictor()
        if IsValid(inflictor) and inflictor:GetClass() == WEAPON_CLASS and inflictor:GetOwner() == target then
            return true
        end
    end)

    hook.Add("PlayerSpawn", "Homelander.ResetGrabExecutionVisibility", function(ply)
        if not IsValid(ply) then return end

        ply:SetNoDraw(false)
        ply:DrawShadow(true)
        ply:SetNotSolid(false)
        ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        ply.HomelanderSWEPHealthGranted = nil
        ply.HomelanderGrabbedBy = nil
        ply.HomelanderGrabExecutionPending = nil
        ply.HomelanderNextGrabWeaponStrip = nil
        if ply.RemoveAllDecals then
            ply:RemoveAllDecals()
        end
    end)
end

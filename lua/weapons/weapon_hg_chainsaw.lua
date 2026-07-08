if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_melee"
SWEP.PrintName = "Chainsaw"
SWEP.Instructions = "The Chainsaw, A Widely used around the world to harvest wood. Press R to turn on/off."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Weight = 0
SWEP.bloodID = 3
SWEP.weight = 4.5

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_chainsaw.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_chainsaw.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""

SWEP.HoldType = "camera"
SWEP.HoldPos = Vector(-4, -2, 1)
SWEP.HoldAng = Angle(0, 0, 0)

SWEP.DamageType = DMG_SLASH

SWEP.AttackTime = 0.4
SWEP.AnimTime1 = 1.9
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1, 2, 0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0, 0, -2)

SWEP.attack_ang = Angle(0, 0, -15)
SWEP.sprint_ang = Angle(15, 0, 0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(0, -90, 0)

-- All damage is DMG_SLASH for chainsaw
SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 30
SWEP.DamageSecondary = 15
SWEP.DamageHoldAttack = 15 -- Damage for hold attack when ON

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 7

SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 1.5

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 35
SWEP.StaminaSecondary = 25

SWEP.AttackLen1 = 85 -- Increased range for better prop reach when ON
SWEP.AttackLen2 = 45

-- Prop damage multiplier for chainsaw ON mode
SWEP.PropDamageMultiplier = 2.5

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-4, -2, 1)
SWEP.BlockHoldAng = Angle(0, 0, 21)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet2.wav"

-- Default animation list (OFF state)
SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/hud/tfa_nmrih_chainsaw")
    SWEP.IconOverride = "vgui/hud/tfa_nmrih_chainsaw"
    SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true

-- Multiple chainsaw hit sounds for variety
SWEP.ChainsawHitSounds = {
    "chainsaw/hit1.mp3",
    "chainsaw/hit2.mp3", 
    "chainsaw/hit3.mp3",
    "chainsaw/hit4.mp3",
    "chainsaw/hit5.mp3",
    "chainsaw/hit6.mp3",
    "chainsaw/hit7.mp3",
    "chainsaw/hit8.mp3"
}

-- Keep original sounds for OFF mode
SWEP.AttackHit = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_axehit.wav"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.DeploySnd = "weapons/universal/uni_weapon_draw_01.wav"

SWEP.AttackPos = Vector(0, 0, 0)

SWEP.Ignorebelt = true
SWEP.NoHolster = true

-- Chainsaw state management
function SWEP:Initialize()
    -- Call base initialize
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize(self)
    end
    
    -- Initialize chainsaw state (OFF by default)
    self:SetNWBool("chainsawon", false)
    self:SetNWInt("Gasoline", 100)
    self.NextGasDecrease = 0
    self.lastStateChange = 0
    self.holdAttackTimer = 0
    self.isHoldAttacking = false
    self.holdAttackStarted = false
    self.transitionTimer = 0
    self.animationLocked = false -- Prevent animation conflicts
    self.animationUnlockTime = 0 -- Timer for unlocking animations instead of callbacks
    
    -- Sound system variables
    self.isPlayingIdleLoop = false -- Track if idle loop is playing
    self.soundTimers = {} -- Store timer references for cleanup
    
    -- Sound patch objects for proper loop control
    self.idleLoopSound = nil -- CSoundPatch for idle loop
    self.sawLoopSound = nil -- CSoundPatch for saw loop during attack
    
    -- Update animation list based on initial state
    self:UpdateAnimList()
end

-- Helper function to get random chainsaw hit sound
function SWEP:GetRandomChainsawHitSound()
    if not self.ChainsawHitSounds or #self.ChainsawHitSounds == 0 then
        return "snd_jack_hmcd_axehit.wav" -- Fallback
    end
    return self.ChainsawHitSounds[math.random(1, #self.ChainsawHitSounds)]
end

function SWEP:UpdateAnimList()
    if self:GetNWBool("chainsawon", false) then
        -- ON state animations
        self.AnimList = {
            ["idle"] = "IdleOn",
            ["deploy"] = "Draw",
            ["attack"] = "Idle_To_Attack", -- Transition to attack
            ["attack_on"] = "Attack_On", -- Continuous hold attack
            ["attack_end"] = "Attack_To_Idle", -- Transition back to idle (renamed from attack2)
            ["attack2"] = "Attack_To_Idle", -- Keep for compatibility but use attack_end
            ["turnon"] = "TurnOn",
            ["turnoff"] = "TurnOff",
        }
    else
        -- OFF state animations
        self.AnimList = {
            ["idle"] = "Idle",
            ["deploy"] = "Draw", 
            ["attack"] = "Attack_Quick",
            ["attack2"] = "Shove",
            ["turnon"] = "TurnOn",
            ["turnoff"] = "TurnOff",
        }
    end
end

-- Handle state changes with NWVar
hook.Add("EntityNetworkedVarChanged", "ChainsawStateChange", function(ent, name, oldval, newval)
    if name == "chainsawon" and IsValid(ent) and ent.AnimList then
        ent:UpdateAnimList()
    end
end)

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_RELOAD) then
            -- Prevent state changes during hold attack
            if self.isHoldAttacking then return end
            
            local newState = not self:GetNWBool("chainsawon", false)
            
            if newState and self:GetNWInt("Gasoline", 0) <= 0 then
                self:EmitSound("Weapon_Pistol.Empty")
                return
            end

            self:SetNWBool("chainsawon", newState)
            self.lastStateChange = CurTime()
            
            -- Lock animations during transition
            self.animationLocked = true
            
            -- End any ongoing hold attack
            if self.isHoldAttacking then
                self:EndHoldAttack()
            end
            
            -- Play appropriate animation and prevent actions during transition
            if newState then
                self:PlayAnim("turnon", 1.5, false, nil, false, true)
                self.animationUnlockTime = CurTime() + 1.5 -- Unlock after animation duration
                
                -- Turn-on sound sequence
                self:PlayTurnOnSounds()
            else
                self:PlayAnim("turnoff", 1.5, false, nil, false, true)
                self.animationUnlockTime = CurTime() + 1.5 -- Unlock after animation duration
                
                -- Turn-off sound and stop idle loop
                self:PlayTurnOffSounds()
            end
            
            -- Update animation list
            self:UpdateAnimList()
        end
    end
end

function SWEP:CanPrimaryAttack()
    -- Can't attack during any transition state
    if self:IsInTransition() then return false end
    
    -- Set damage type to slash
    self.DamageType = DMG_SLASH
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    
    return true
end

function SWEP:CanSecondaryAttack()
    -- Can't attack during any transition state
    if self:IsInTransition() then return false end
    
    -- No secondary attack when chainsaw is ON
    if self:GetNWBool("chainsawon", false) then return false end
    
    -- Set damage type to slash
    self.DamageType = DMG_SLASH
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    
    return true
end

-- Helper function to check if we're in a transition state
function SWEP:IsInTransition()
    -- Check transition conditions based on actual animation timing
    if (self.transitionTimer or 0) > CurTime() then return true end
    if self.animationLocked then return true end
    if (self.animationUnlockTime or 0) > CurTime() then return true end
    return false
end

-- Override PlayAnim to prevent attack animations during transitions
function SWEP:PlayAnim(anim, time, loop, rate, startpos, noSound)
    -- Block attack animations during transitions
    if self:IsInTransition() and (anim == "Attack_Quick" or anim == "Shove") then
        return -- Don't play attack animations during state transitions
    end
    
    -- Call the base class PlayAnim for all other animations
    if self.BaseClass and self.BaseClass.PlayAnim then
        return self.BaseClass.PlayAnim(self, anim, time, loop, rate, startpos, noSound)
    end
end

function SWEP:PrimaryAttack()
    -- ABSOLUTE FIRST CHECK: Prevent ANY action during transitions
    if self:IsInTransition() then 
        return -- No animations, no base class calls, nothing
    end
    
    if not self:CanPrimaryAttack() then return end
    
    -- Ensure animation list is updated for current state
    self:UpdateAnimList()
    
    if self:GetNWBool("chainsawon", false) then
        -- ON state: Start hold attack (completely bypass base class to prevent Attack_Quick)
        self:StartHoldAttack()
        return -- Important: return here to prevent any base class calls
    else
        -- OFF state: Normal swing attack - but only if not in transition
        if not self:IsInTransition() and self.BaseClass and self.BaseClass.PrimaryAttack then
            self.BaseClass.PrimaryAttack(self)
        end
    end
end

function SWEP:SecondaryAttack()
    -- ABSOLUTE FIRST CHECK: Prevent ANY action during transitions
    if self:IsInTransition() then 
        return -- No animations, no base class calls, nothing
    end
    
    if not self:CanSecondaryAttack() then return end
    
    -- Ensure animation list is updated for current state
    self:UpdateAnimList()
    
    -- Only available in OFF state
    if not self:GetNWBool("chainsawon", false) then
        -- Double check transition state before base class call
        if not self:IsInTransition() and self.BaseClass and self.BaseClass.SecondaryAttack then
            self.BaseClass.SecondaryAttack(self)
        end
    end
end

function SWEP:StartHoldAttack()
    if not IsFirstTimePredicted() then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    if self.isHoldAttacking then return end -- Already attacking
    if self.animationLocked then return end -- Prevent during transitions
    
    -- Start hold attack sequence
    self.isHoldAttacking = true
    self.holdAttackStarted = false
    self.animationLocked = true -- Lock animations during attack sequence
    
    -- Set transition timer to prevent other attacks
    self.transitionTimer = CurTime() + 0.5
    
    -- Ensure we're using ON state animations
    self:UpdateAnimList()
    
    -- Play transition to attack animation (Idle_To_Attack)
    self:PlayAnim("attack", 0.5, false, nil, false)
    self.holdAttackTransitionTime = CurTime() + 0.5 -- Start continuous attack after transition
    
    -- Play idle to attack transition sound
    self:PlayAttackTransitionSound("chainsaw_idletosaw")
end

function SWEP:StartContinuousAttack()
    if not self.isHoldAttacking then return end
    
    -- Start the continuous Attack_On animation
    self:PlayAnim("attack_on", 1.0, true) -- Loop the attack animation
    self.holdAttackStarted = true
    self.holdAttackTimer = CurTime() + 0.1 -- Start attacking after brief delay
    self.animationLocked = false -- Allow animation updates during continuous attack
    
    -- Start saw loop sound for continuous attack
    self:StartSawLoop()
end

function SWEP:Think()
    local is_on = self:GetNWBool("chainsawon", false)
    if SERVER and is_on then
        if not self.NextGasDecrease then self.NextGasDecrease = 0 end
        
        -- Determine consumption rate (3 per second if attacking, 1 per second otherwise)
        local interval = 1
        if self.isHoldAttacking then
            interval = 0.33
        end

        if CurTime() >= self.NextGasDecrease then
            self.NextGasDecrease = CurTime() + interval
            local currentGas = self:GetNWInt("Gasoline", 0)
            if currentGas > 0 then
                self:SetNWInt("Gasoline", currentGas - 1)
            else
                self:SetNWBool("chainsawon", false)
                self.lastStateChange = CurTime()
                
                -- End any ongoing hold attack
                if self.isHoldAttacking then
                    self:EndHoldAttack()
                end

                if IsValid(self:GetOwner()) then
                    self:PlayAnim("turnoff", 1.5, false, nil, false, true)
                    self.animationUnlockTime = CurTime() + 1.5
                end
                
                self:PlayTurnOffSounds()
                self:UpdateAnimList()
            end
        end
    end

    -- Keep thinking if dropped and on
    if SERVER and is_on and not IsValid(self:GetOwner()) then
        self:NextThink(CurTime())
        return true
    end

    -- Handle timer-based animation unlocking
    if self.animationLocked and (self.animationUnlockTime or 0) < CurTime() then
        self.animationLocked = false
    end
    
    -- Handle hold attack transition timing
    if self.isHoldAttacking and not self.holdAttackStarted and (self.holdAttackTransitionTime or 0) < CurTime() then
        if IsValid(self) and self.isHoldAttacking then
            self:StartContinuousAttack()
        end
    end
    
    -- Only call base class Think if not in hold attack mode to prevent interference
    if not (self:GetNWBool("chainsawon", false) and self.isHoldAttacking) then
        if self.BaseClass and self.BaseClass.Think then
            self.BaseClass.Think(self)
        end
    end
    
    -- Handle hold attack when chainsaw is ON
    if self:GetNWBool("chainsawon", false) and self.isHoldAttacking then
        local owner = self:GetOwner()
        if not IsValid(owner) then 
            self:EndHoldAttack()
            return 
        end
        
        -- Check if still holding primary attack
        if not owner:KeyDown(IN_ATTACK) then
            self:EndHoldAttack()
            return
        end
        
        -- Perform continuous damage if attack has started
        if self.holdAttackStarted and (self.holdAttackTimer or 0) < CurTime() then
            -- Add a small delay to prevent net message conflicts
            timer.Simple(0.01, function()
                if IsValid(self) and self.holdAttackStarted then
                    self:DoHoldAttackDamage()
                end
            end)
            self.holdAttackTimer = CurTime() + 0.1 -- Attack every 0.1 seconds
        end
    end

    --If the chainsaw is thrown out and turned on, we deal damage to players who approach it
    if SERVER and is_on and not IsValid(self:GetOwner()) then
        self:CheckDangerTouch()
    end
end

function SWEP:CheckDangerTouch()
    if not SERVER then return end
    if not self:GetNWBool("chainsawon", false) then return end
    if IsValid(self:GetOwner()) then return end --We do not check if there is an owner

    --We check once every 0.5 seconds (so as not to load the server)
    local nextCheck = self.nextDangerCheck or 0
    if CurTime() < nextCheck then return end
    self.nextDangerCheck = CurTime() + 0.5

    local pos = self:GetPos()
    --We are looking for all players within a radius of 35 units
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not ply:IsSpec() and ply:GetPos():Distance(pos) <= 45 then
            --We cause damage
            local dmg = DamageInfo()
            dmg:SetAttacker(game.GetWorld()) --or self, but so that it is not considered an attack by the player
            dmg:SetInflictor(self)
            dmg:SetDamage(5)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetDamagePosition(pos)
            ply:TakeDamageInfo(dmg)

            --Blood effects
            util.Decal("Blood", ply:GetPos() + Vector(0,0,10), ply:GetPos() - Vector(0,0,10), self)

            --The sound of a cut
            ply:EmitSound("snd_jack_hmcd_axehit.wav", 50, math.random(95,105))

            --A little push
            local dir = (ply:GetPos() - pos):GetNormalized()
            ply:SetVelocity(dir * 100 + Vector(0,0,50))
        end
    end
end

function SWEP:DoHoldAttackDamage()
    if not SERVER then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- Use the same advanced tracing system as weapon_melee for proper ragdoll/organism support
    local ent = hg.GetCurrentCharacter(owner)
    if not IsValid(ent) then return end
    
    -- Reset hit tracking for each attack cycle to allow continuous damage
    self.HitEnts = {owner, ent}
    
    owner:LagCompensation(true)
    local eyetr = hg.eyeTrace(owner, self.AttackLen1 + math.min(owner:GetVelocity():Length()/15, 40), ent)
    local trace
    
    -- Improved tracing system for better prop detection
    if not self:IsEntSoft(eyetr.Entity) then
        -- For props: Use multiple simple traces in a wider pattern for better detection
        local bestTrace = eyetr
        local found = false
        
        -- Try direct trace first
        if IsValid(eyetr.Entity) and eyetr.Entity ~= owner and eyetr.Entity ~= ent then
            bestTrace = eyetr
            found = true
        else
            -- If direct trace failed, try wider sweep for props
            for i = 1, 9 do
                local angle = owner:EyeAngles()
                local spread = 15 -- degrees
                local yawOffset = (i - 5) * (spread / 4) -- -15 to +15 degrees
                local pitchOffset = math.sin(i * 0.5) * (spread / 6) -- slight vertical variation
                
                angle.yaw = angle.yaw + yawOffset
                angle.pitch = angle.pitch + pitchOffset
                
                local tr = {}
                tr.start = owner:EyePos()
                tr.endpos = owner:EyePos() + angle:Forward() * (self.AttackLen1 + math.min(owner:GetVelocity():Length()/15, 40))
                tr.filter = self.HitEnts
                local size = 0.2 -- Slightly larger for better prop detection
                tr.mins = -Vector(size, size, size)
                tr.maxs = Vector(size, size, size)

                local sweepTrace = util.TraceLine(tr)
                
                if IsValid(sweepTrace.Entity) and sweepTrace.Entity ~= owner and sweepTrace.Entity ~= ent then
                    bestTrace = sweepTrace
                    found = true
                    break
                end
            end
        end
        
        trace = bestTrace
    else
        trace = eyetr
    end

    owner:LagCompensation(false)
    
    -- Check if we hit something (no need to check HitEnts since we reset it each cycle)
    if IsValid(trace.Entity) and trace.Entity ~= owner and trace.Entity ~= ent then
        
        -- Play appropriate hit sounds based on target type
        local soundLevel = 75 -- Sound level for range (higher = further range)
        local pitch = math.random(95, 100) -- Slight pitch variation
        
        if self:IsEntSoft(trace.Entity) then
            -- For flesh/organic targets: use chainsaw hit sounds
            local hitSound = self:GetRandomChainsawHitSound()
            self:EmitSound(hitSound, soundLevel, pitch)
        else
            -- For props: use material-specific bullet impact sounds
            local surfaceData = util.GetSurfaceData(trace.SurfaceProps)
            if surfaceData and surfaceData.bulletImpactSound then
                self:EmitSound(surfaceData.bulletImpactSound, soundLevel, pitch)
            else
                -- Fallback to generic impact sound if no surface data
                self:EmitSound("physics/concrete/concrete_impact_bullet1.wav", soundLevel, pitch)
            end
        end
        
        -- Additional effects for flesh hits
        if self:IsEntSoft(trace.Entity) then
            if self.DamageType == DMG_SLASH then
                util.Decal("Blood", trace.HitPos + trace.HitNormal * 15, trace.HitPos - trace.HitNormal * 15, owner)
                util.Decal("Blood", trace.HitPos + trace.HitNormal * 2, owner:GetPos(), trace.Entity)
            end
        end
        
        -- Calculate damage with the same multipliers as weapon_melee
        local vellen = ent:GetVelocity():Length()
        local mul = 1 / math.Clamp((180 - owner.organism.stamina[1]) / 90, 1, 1.3)
        mul = mul * math.Clamp(vellen / 250, 0.9, 1.25)
        mul = mul * (ent ~= owner and 0.75 or 1)
        mul = mul * (owner.MeleeDamageMul or 1)

        if owner.organism.superfighter then
            mul = mul * 5
        end
        
        -- Use hold attack damage but with proper multipliers
        local baseDamage = self.DamageHoldAttack
        local dmg = math.random(baseDamage - 1, baseDamage + 1) * mul
        
        -- Apply damage reduction for continuous attacks
        dmg = dmg / 1.5
        
        -- Apply prop damage multiplier for better prop destruction
        if not (trace.Entity:IsPlayer() or trace.Entity:IsRagdoll() or trace.Entity:IsNPC()) then
            dmg = dmg * (self.PropDamageMultiplier or 1)
            
            -- Special handling for doors - ensure they can be broken
            local entClass = trace.Entity:GetClass()
            if string.find(entClass, "door") or string.find(entClass, "gate") then
                dmg = dmg * 1.5 -- Extra damage for doors
            end
        end
        
        -- Handle ragdoll physics like weapon_melee
        if IsValid(hg.RagdollOwner(trace.Entity)) then
            local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)
            if IsValid(phys) then
                phys:ApplyForceOffset(trace.Normal * dmg * 100, trace.HitPos)
            end
        end
        
        -- Create damage info using the same system as weapon_melee
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(owner)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamage(dmg)
        dmginfo:SetDamageForce(trace.Normal * dmg)
        dmginfo:SetDamageType(DMG_SLASH)
        dmginfo:SetDamagePosition(trace.HitPos)
        
        -- Apply damage
        trace.Entity:TakeDamageInfo(dmginfo)
        
        -- Handle player/ragdoll effects like weapon_melee
        if trace.Entity:IsPlayer() or trace.Entity:IsRagdoll() then 
            local ply = hg.RagdollOwner(trace.Entity) or trace.Entity
            if ply:IsPlayer() then
                local normal = Angle(0, 0, 0)
                normal:RotateAroundAxis(normal:Forward(), -(self.SwingAng or -90))
                normal:RotateAroundAxis(normal:Up(), -1 * (self.AttackRads or 65))

                local dot = ply:GetAimVector():Dot(trace.Normal)
                
                ply:ViewPunch((normal * -dot) * dmg / 30 * 1.25)
                ply:SetVelocity((trace.Normal:Angle() + normal):Forward() * -5 * dmg * 1.25 + trace.Normal * dmg * 5 * 1.25)
            end
        end

        -- Apply physics force
        local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)
        if IsValid(phys) then
            phys:ApplyForceOffset(trace.Normal * dmg * 100, trace.HitPos)
        end

        -- Call additional effects
        self:PrimaryAttackAdd(trace.Entity, trace)
        
        -- Damage-based adrenaline system for attacker
        if owner.organism and (trace.Entity:IsPlayer() or trace.Entity:IsRagdoll()) then
            local adrenalineGain = math.Clamp(dmg * 0.005, 0.02, 0.1)
            owner.organism.adrenalineAdd = math.min(owner.organism.adrenalineAdd + adrenalineGain, 4)
        end
        
        -- Add view punch for feedback
        if owner:IsPlayer() then
            owner:ViewPunch(Angle(math.random(-1, 1), math.random(-2, 2), 0))
        end
    end
end

function SWEP:EndHoldAttack()
    if not self.isHoldAttacking then return end
    
    self.isHoldAttacking = false
    self.holdAttackStarted = false
    self.animationLocked = true -- Lock during end transition
    
    -- Stop saw loop and return to idle loop
    self:StopSawLoop()
    
    -- Ensure we're using ON state animations for proper end animation
    self:UpdateAnimList()
    
    -- Play transition back to idle animation (Attack_To_Idle)
    self:PlayAnim("attack_end", 0.5, false, nil, false)
    self.animationUnlockTime = CurTime() + 0.5 -- Unlock after transition
    
    -- Play attack to idle transition sound
    self:PlayAttackTransitionSound("chainsaw_sawtoidle")
    
    -- Restart idle loop after attack ends (with small delay)
    timer.Simple(0.6, function()
        if IsValid(self) and self:GetNWBool("chainsawon", false) and not self.isHoldAttacking then
            self:StartIdleLoop()
        end
    end)
end

-- Override to prevent blocking during state transitions
function SWEP:CanBlock()
    -- Can't block during state transition
    if (self.lastStateChange or 0) + 1.5 > CurTime() then return false end
    
    if self.BaseClass and self.BaseClass.CanBlock then
        return self.BaseClass.CanBlock(self)
    end
    
    return false
end

-- Overtake function - allows breaking blocks with superior condition
function SWEP:CheckOvertake(target)
    if not SERVER then return false end
    if not IsValid(target) or not target:IsPlayer() then return false end
    
    local attacker = self:GetOwner()
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    
    -- Check if target has a melee weapon and is blocking
    local targetWeapon = target:GetActiveWeapon()
    if not IsValid(targetWeapon) or not targetWeapon.ismelee then return false end
    
    local isBlocking = false
    if targetWeapon.GetIsBlocking then
        isBlocking = targetWeapon:GetIsBlocking()
    elseif targetWeapon.GetBlocking then
        isBlocking = targetWeapon:GetBlocking()
    end
    
    if not isBlocking then return false end
    
    -- Check if both players have organism data
    if not attacker.organism or not target.organism then return false end
    
    -- Calculate condition scores (stamina + adrenaline*10)
    local attackerStamina = attacker.organism.stamina and attacker.organism.stamina[1] or 0
    local attackerAdrenaline = attacker.organism.adrenaline or 0
    local attackerCondition = attackerStamina + (attackerAdrenaline * 10)
    
    local defenderStamina = target.organism.stamina and target.organism.stamina[1] or 0
    local defenderAdrenaline = target.organism.adrenaline or 0
    local defenderCondition = defenderStamina + (defenderAdrenaline * 10)
    
    -- Need at least 20 point advantage to attempt overtake
    local conditionDiff = attackerCondition - defenderCondition
    if conditionDiff < 20 then return false end
    
    -- Calculate overtake chance (15-25% base, increased by condition difference)
    local baseChance = math.random(15, 25)
    local bonusChance = math.min(conditionDiff * 0.3, 20) -- Max 20% bonus
    local totalChance = baseChance + bonusChance
    
    -- Roll for overtake success
    if math.random(1, 100) > totalChance then return false end
    
    -- Overtake successful! Break the block
    if targetWeapon.EndBlock then
        targetWeapon:EndBlock()
    end
    if targetWeapon.SetBlockCooldown then
        targetWeapon:SetBlockCooldown(CurTime() + 4.0) -- Longer cooldown than normal
    end
    
    -- Heavy stamina penalty for failed block
    local staminaPenalty = math.random(25, 40)
    target.organism.stamina.subadd = target.organism.stamina.subadd + staminaPenalty
    
    -- Brief stun effect
    if target.organism then
        target.organism.stun = CurTime() + 1.5
    end
    
    -- 30-40% chance to drop weapon on overtake
    if math.random(1, 100) <= math.random(30, 40) then
        timer.Simple(0.1, function()
            if IsValid(target) and IsValid(targetWeapon) then
                hg.drop(target)
            end
        end)
        
        -- Add knockback when weapon is dropped
        local knockbackForce = (target:GetPos() - attacker:GetPos()):GetNormalized() * 200
        target:SetVelocity(knockbackForce + Vector(0, 0, 50))
    end
    
    -- Play overtake sound effect
    attacker:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 70, math.random(90, 110))
    target:EmitSound("physics/body/body_medium_break" .. math.random(2, 4) .. ".wav", 65, math.random(95, 105))
    
    -- Small adrenaline boost for successful overtake
    if attacker.organism then
        attacker.organism.adrenalineAdd = math.min(attacker.organism.adrenalineAdd + 0.2, 4)
    end
    
    return true
end

function SWEP:PrimaryAttackAdd(ent)
    -- Check for door breaking (works in both states)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent, self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
    
    -- Check for overtake against blocking players (works in both states)
    if ent:IsPlayer() then
        self:CheckOvertake(ent)
    end
end

-- Sound system functions
function SWEP:PlayTurnOnSounds()
    -- Ensure soundTimers table exists
    if not self.soundTimers then
        self.soundTimers = {}
    end
    
    -- Clear any existing sound timers
    self:ClearSoundTimers()
    
    -- Play failed start sound after 0.1 seconds
    self.soundTimers["failedstart"] = timer.Simple(0.1, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:EmitSound("weapons/melee/chainsaw/chainsaw_failedstart.wav", 75, 100, 1, CHAN_WEAPON)
        end
    end)
    
    -- Play success start sound after 0.2 seconds (0.1 + 0.1)
    self.soundTimers["successstart"] = timer.Simple(0.2, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:EmitSound("weapons/melee/chainsaw/chainsaw_successstart.wav", 75, 100, 1, CHAN_WEAPON2)
            
            -- Start idle loop after success start plays
            timer.Simple(0.1, function()
                if IsValid(self) and IsValid(self:GetOwner()) and self:GetNWBool("chainsawon", false) then
                    self:StartIdleLoop()
                end
            end)
        end
    end)
end

function SWEP:PlayTurnOffSounds()
    -- Stop all looping sounds
    self:StopIdleLoop()
    self:StopSawLoop()
    
    -- Ensure soundTimers table exists
    if not self.soundTimers then
        self.soundTimers = {}
    end
    
    -- Clear any existing sound timers
    self:ClearSoundTimers()
    
    -- Play turn off sound immediately
    if IsValid(self) and IsValid(self:GetOwner()) then
        self:EmitSound("weapons/melee/chainsaw/chainsaw_turnoff.wav", 75, 100, 1, CHAN_WEAPON)
    end
end

function SWEP:StartIdleLoop()
    -- Stop saw loop if playing
    self:StopSawLoop()
    
    if not self.isPlayingIdleLoop then
        self.isPlayingIdleLoop = true
        if IsValid(self) and IsValid(self:GetOwner()) then
            -- Create sound patch for proper loop control
            self.idleLoopSound = CreateSound(self, "weapons/melee/chainsaw/chainsaw_idleloop.wav")
            if self.idleLoopSound then
                self.idleLoopSound:Play()
                self.idleLoopSound:SetSoundLevel(75)
            end
        end
    end
end

function SWEP:StopIdleLoop()
    if self.isPlayingIdleLoop then
        self.isPlayingIdleLoop = false
        if self.idleLoopSound then
            self.idleLoopSound:Stop()
            self.idleLoopSound = nil
        end
    end
end

function SWEP:StartSawLoop()
    -- Stop idle loop if playing
    self:StopIdleLoop()
    
    if not self.sawLoopSound then
        if IsValid(self) and IsValid(self:GetOwner()) then
            -- Create sound patch for saw loop during attack
            self.sawLoopSound = CreateSound(self, "weapons/melee/chainsaw/chainsaw_sawloop.wav")
            if self.sawLoopSound then
                self.sawLoopSound:Play()
                self.sawLoopSound:SetSoundLevel(75)
            end
        end
    end
end

function SWEP:StopSawLoop()
    if self.sawLoopSound then
        self.sawLoopSound:Stop()
        self.sawLoopSound = nil
    end
end

function SWEP:PlayAttackTransitionSound(soundName)
    if IsValid(self) and IsValid(self:GetOwner()) then
        self:EmitSound("weapons/melee/chainsaw/" .. soundName .. ".wav", 75, 100, 1, CHAN_ITEM)
    end
end

function SWEP:ClearSoundTimers()
    -- Ensure soundTimers table exists before using pairs
    if not self.soundTimers then
        self.soundTimers = {}
        return
    end
    
    for name, timerRef in pairs(self.soundTimers) do
        if timer.Exists(timerRef) then
            timer.Remove(timerRef)
        end
    end
    self.soundTimers = {}
end

-- Sound cleanup functions

function SWEP:Holster(wep)
    -- Stop all sounds and clean up timers when holstering
    self:StopIdleLoop()
    self:StopSawLoop()
    if self.soundTimers then
        self:ClearSoundTimers()
    end
    
    -- Call base class Holster if it exists
    if self.BaseClass and self.BaseClass.Holster then
        return self.BaseClass.Holster(self, wep)
    end
    
    return true
end

-- Dropped weapon sound system
function SWEP:OnDrop()
    if not SERVER then return end
    
    -- Transfer sound patches to the dropped weapon entity
    if self:GetNWBool("chainsawon", false) then
        --We do not call SetNextThink, since Think will already be called due to the condition in Think
        local droppedEnt = self
        
        -- Store sound state for transfer
        local hasIdleLoop = self.isPlayingIdleLoop and self.idleLoopSound
        local hasSawLoop = self.sawLoopSound
        
        -- Create new sound patches on the dropped entity
        if hasIdleLoop then
            timer.Simple(0.1, function()
                if IsValid(droppedEnt) then
                    droppedEnt.droppedIdleLoopSound = CreateSound(droppedEnt, "weapons/melee/chainsaw/chainsaw_idleloop.wav")
                    if droppedEnt.droppedIdleLoopSound then
                        droppedEnt.droppedIdleLoopSound:Play()
                        droppedEnt.droppedIdleLoopSound:SetSoundLevel(75)
                    end
                end
            end)
        end
        
        if hasSawLoop then
            timer.Simple(0.1, function()
                if IsValid(droppedEnt) then
                    droppedEnt.droppedSawLoopSound = CreateSound(droppedEnt, "weapons/melee/chainsaw/chainsaw_sawloop.wav")
                    if droppedEnt.droppedSawLoopSound then
                        droppedEnt.droppedSawLoopSound:Play()
                        droppedEnt.droppedSawLoopSound:SetSoundLevel(75)
                    end
                end
            end)
        end
        
        -- Mark that this dropped weapon has sounds
        self.hasDroppedSounds = true
    end
    
    -- Stop original sounds on the weapon
    self:StopIdleLoop()
    self:StopSawLoop()
    
    -- Call base class OnDrop if it exists
    if self.BaseClass and self.BaseClass.OnDrop then
        self.BaseClass.OnDrop(self)
    end
end

function SWEP:Equip(newOwner)
    if not SERVER then return end
    
    -- Stop any dropped sounds when picked up
    if self.hasDroppedSounds then
        if self.droppedIdleLoopSound then
            self.droppedIdleLoopSound:Stop()
            self.droppedIdleLoopSound = nil
        end
        if self.droppedSawLoopSound then
            self.droppedSawLoopSound:Stop()
            self.droppedSawLoopSound = nil
        end
        self.hasDroppedSounds = false
        
        -- Restart appropriate sounds on the weapon if chainsaw is still on
        if self:GetNWBool("chainsawon", false) then
            timer.Simple(0.1, function()
                if IsValid(self) and IsValid(newOwner) and self:GetOwner() == newOwner then
                    if not self.isHoldAttacking then
                        self:StartIdleLoop()
                    else
                        self:StartSawLoop()
                    end
                end
            end)
        end
    end
    
    -- Call base class Equip if it exists
    if self.BaseClass and self.BaseClass.Equip then
        self.BaseClass.Equip(self, newOwner)
    end
end

-- Enhanced OnRemove to handle dropped sounds
function SWEP:OnRemove()
    -- Stop all sounds and clean up timers
    self:StopIdleLoop()
    self:StopSawLoop()
    
    -- Stop dropped sounds if they exist
    if self.droppedIdleLoopSound then
        self.droppedIdleLoopSound:Stop()
        self.droppedIdleLoopSound = nil
    end
    if self.droppedSawLoopSound then
        self.droppedSawLoopSound:Stop()
        self.droppedSawLoopSound = nil
    end
    
    if self.soundTimers then
        self:ClearSoundTimers()
    end
    
    -- Call base class OnRemove if it exists
    if self.BaseClass and self.BaseClass.OnRemove then
        self.BaseClass.OnRemove(self)
    end
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 95
SWEP.AttackRads2 = 0

SWEP.SwingAng = -165
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.87
COMMANDS = COMMANDS or {}

local validUserGroupSuperAdmin = {
	superadmin = true,
	owner = true,
	servermanager = true,
	headdeveloper = true,
}

local validUserGroup = {
	headadmin = true,
	developer = true,
	admin = true,
}

function COMMAND_GETACCES(ply)
	if ply == Entity(0) then return 2 end

	if zb and zb.UCL and ULib and ULib.ucl then
		if ULib.ucl.query(ply, zb.UCL.SuperChat) then return 2 end
		if ULib.ucl.query(ply, zb.UCL.AdminChat) then return 1 end
	end

	local group = ply:GetUserGroup()
	if validUserGroup[group] then return 1 end
	if validUserGroupSuperAdmin[group] then return 2 end

	return 0
end

function COMMAND_ACCES(ply, cmd, cmdName)
	local access = cmd[2] or 1
	if access == 0 then return true end

	if zb and zb.UCL and zb.HasULX then
		if cmdName == "zc_god" then
			return zb.HasULX(ply, zb.UCL.Godmode)
		end

		if cmdName == "power" then
			return ULib.ucl.query(ply, "ulx power")
		end
	end

	return COMMAND_GETACCES(ply) >= access
end

function COMMAND_GETARGS(args)
	local newArgs = {}
	local waitClose,waitCloseText

	for i,text in pairs(args) do
		if not waitClose and string.sub(text,1,1) == "\"" then
			waitClose = true

			if string.sub(text,#text,#text) == "\n" then
				newArgs[#newArgs + 1] = string.sub(text,2,#text - 1)

				waitClose = nil
			else
				waitCloseText = string.sub(text,2,#text)
			end

			continue
		end

		if waitClose then
			if string.sub(text,#text,#text) == "\"" then
				waitClose = nil

				newArgs[#newArgs + 1] = waitCloseText .. string.sub(text,1,#text - 1)
			else
				waitCloseText = waitCloseText .. string.sub(text,1,#text)
			end

			continue
		end

		newArgs[#newArgs + 1] = text
	end

	return newArgs
end

function COMMAND_Input(ply, args)
	local cmd = COMMANDS[args[1]]
	if not cmd then return false end
	if not COMMAND_ACCES(ply, cmd, args[1]) then return true, false end

	table.remove(args,1)

	return true,cmd[1](ply,args)
end
-- Мдаааа А ПЛЕЙРСЕЙ ДЛЯ КОГО НУЖЕН????
hook.Add("HG_PlayerSay","commands-chat",function(ply, txtTbl, text)
	COMMAND_Input(ply, COMMAND_GETARGS(string.Split(string.sub(text, 2, #text), " ")))
end)

COMMANDS.help = {function(ply,args)
	local text = ""

	if args[1] then
		local cmd = COMMANDS[args[1]]
		local argsList = cmd[3]
		if argsList then argsList = " - " .. argsList else argsList = "" end

		text = text .. "	" .. args[1] .. argsList .. "\n"
	else
		local list = {}
		for name in pairs(COMMANDS) do list[#list + 1] = name end
		table.sort(list,function(a,b) return a > b end)
        
		for _,name in pairs(list) do
			local cmd = COMMANDS[name]
            if not COMMAND_ACCES(ply, cmd, name) then continue end
            
			local argsList = cmd[3]
			if argsList then argsList = " - " .. argsList else argsList = "" end
            
			text = text .. "	" .. name .. argsList .. "\n"
		end
	end

	text = string.sub(text,1,#text - 1)

	ply:ChatPrint(text)
end,0}

if SERVER then
    util.AddNetworkString("PunishLightningEffect")
    util.AddNetworkString("AnotherLightningEffect")
    util.AddNetworkString("PluvCommand")

    local ZC_GOD_MODEL = "models/player/jesus/jesus.mdl"
    local ZC_POWER_RECOIL_MUL = 0.25
    local ZC_POWER_MELEE_MAX_DISTANCE_SQR = 180 * 180
    local ZC_POWER_MELEE_FORCE = 22000
    local ZC_POWER_MELEE_UP_FORCE = 7000
    local ZC_POWER_MELEE_SWING_VELOCITY_MUL = 35
    local ZC_POWER_MELEE_HIT_COOLDOWN = 0.2
    local ZC_POWER_UP_VECTOR = Vector(0, 0, 1)

    local function ZC_ApplyGodModel(ply)
        if not IsValid(ply) then return end

        ply:SetNetVar("Accessories", {})
        ply:SetSubMaterial()
        ply:SetModel(ZC_GOD_MODEL)
    end

    local function ZC_RestoreGodModel(ply)
        if not IsValid(ply) then return end

        if ply.ZCGodStoredAppearance then
            hg.Appearance.ForceApplyAppearance(ply, ply.ZCGodStoredAppearance)
        elseif ply.ZCGodStoredModel then
            ply:SetSubMaterial()
            ply:SetModel(ply.ZCGodStoredModel)
        end

        ply.ZCGodStoredAppearance = nil
        ply.ZCGodStoredModel = nil
    end

    local function ZC_CanUsePowerCommand(ply)
        if ULib and ULib.ucl and ULib.ucl.query(ply, "ulx power") then
            return true
        end

        return COMMAND_GETACCES(ply) >= 2
    end

    local function ZC_HasPowerMelee(attacker)
        return IsValid(attacker)
            and attacker:IsPlayer()
            and attacker:Alive()
            and attacker.ZCPowerEnabled == true
            and attacker.organism
            and attacker.organism.superfighter == true
    end

    local function ZC_IsPowerMeleeInflictor(inflictor)
        if not IsValid(inflictor) then return false end

        if inflictor:GetClass() == "weapon_hands_sh" then
            return true
        end

        return inflictor:IsWeapon() and inflictor.ismelee == true
    end

    local function ZC_GetPowerMeleeVictim(target)
        if not IsValid(target) then return nil end

        if target:IsPlayer() then
            return target
        end

        if not target:IsRagdoll() then
            return nil
        end

        if not hg or not hg.RagdollOwner then
            return nil
        end

        local owner = hg.RagdollOwner(target)

        if not IsValid(owner) and target.GetNWEntity then
            owner = target:GetNWEntity("ply")
        end

        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end

        return nil
    end

    local function ZC_IsPowerMeleeHit(attacker, target, dmginfo)
        if not ZC_HasPowerMelee(attacker) then return false end

        local victim = ZC_GetPowerMeleeVictim(target)
        if not IsValid(victim) or victim == attacker or not victim:Alive() then return false end

        local inflictor = dmginfo:GetInflictor()
        if not ZC_IsPowerMeleeInflictor(inflictor) then return false end

        if not (
            dmginfo:IsDamageType(DMG_CLUB)
            or dmginfo:IsDamageType(DMG_SLASH)
            or dmginfo:IsDamageType(DMG_CRUSH)
        ) then
            return false
        end

        local target_pos = target.WorldSpaceCenter and target:WorldSpaceCenter() or target:GetPos()
        if attacker:WorldSpaceCenter():DistToSqr(target_pos) > ZC_POWER_MELEE_MAX_DISTANCE_SQR then
            return false
        end

        return true, victim
    end

    local function ZC_GetPowerMeleeForce(attacker, victim, dmginfo)
        local force_direction = dmginfo:GetDamageForce()

        if force_direction:LengthSqr() <= 1 then
            force_direction = attacker:GetAimVector()
        else
            force_direction = force_direction:GetNormalized()
        end

        local towards_victim = victim:WorldSpaceCenter() - attacker:WorldSpaceCenter()
        if towards_victim:LengthSqr() > 1 then
            towards_victim:Normalize()

            if force_direction:Dot(towards_victim) < 0.15 then
                force_direction = towards_victim
            end
        end

        force_direction.z = math.max(force_direction.z, 0.2)
        force_direction:Normalize()

        return force_direction * ZC_POWER_MELEE_FORCE
            + ZC_POWER_UP_VECTOR * ZC_POWER_MELEE_UP_FORCE
            + attacker:GetVelocity() * ZC_POWER_MELEE_SWING_VELOCITY_MUL
    end

    local function ZC_ApplyPowerMeleeForceToRagdoll(ragdoll, force)
        if not IsValid(ragdoll) or not ragdoll:IsRagdoll() then return end

        for phys_id = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local phys = ragdoll:GetPhysicsObjectNum(phys_id)
            if not IsValid(phys) then continue end

            phys:Wake()
            phys:ApplyForceCenter(force * (phys_id == 0 and 1 or 0.35))
        end
    end

    local function ZC_TriggerPowerMeleeKnockback(attacker, target, victim, dmginfo)
        if not hg or not hg.GetCurrentCharacter or not hg.AddForceRag or not hg.Fake or not hg.LightStunPlayer then return end

        local now = CurTime()
        if (victim.ZCPowerMeleeHitCooldown or 0) > now then return end

        victim.ZCPowerMeleeHitCooldown = now + ZC_POWER_MELEE_HIT_COOLDOWN

        local force = ZC_GetPowerMeleeForce(attacker, victim, dmginfo)
        local current_character = hg.GetCurrentCharacter(victim)
        local should_fake = not IsValid(current_character) or current_character == victim

        if should_fake then
            hg.AddForceRag(victim, 0, force, 0.5)
            hg.AddForceRag(victim, 1, force * 0.65, 0.5)
            hg.AddForceRag(victim, 2, force * 0.35, 0.5)
            hg.Fake(victim)
        elseif target:IsRagdoll() then
            ZC_ApplyPowerMeleeForceToRagdoll(target, force)
        end

        hg.LightStunPlayer(victim, 1.5)

        if not should_fake then return end

        timer.Simple(0, function()
            if not IsValid(victim) then return end

            local ragdoll = hg.GetCurrentCharacter(victim)
            if IsValid(ragdoll) and ragdoll ~= victim and ragdoll:IsRagdoll() then
                ZC_ApplyPowerMeleeForceToRagdoll(ragdoll, force)
            elseif victim:Alive() then
                victim:SetVelocity(force * 0.02)
            end
        end)
    end

    local function ZC_ApplyPowerState(ply)
        if not IsValid(ply) or not ply.organism then return end

        ply.organism.superfighter = true
        ply.organism.recoilmul = ZC_POWER_RECOIL_MUL
    end

    local function ZC_RemovePowerState(ply)
        if not IsValid(ply) or not ply.organism then return end

        ply.organism.superfighter = ply.ZCPowerStoredSuperfighter == true
        ply.organism.recoilmul = ply.ZCPowerStoredRecoilMul or 1
    end

    local function ZC_FindSinglePlayerByName(name)
        local trimmed_name = string.Trim(name or "")

        if trimmed_name == "" then
            return nil, "please specify a player name"
        end

        local lowered_name = string.lower(trimmed_name)
        local partial_matches = {}

        for _, target_ply in player.Iterator() do
            local target_name = string.lower(target_ply:Name())

            if target_name == lowered_name then
                return target_ply
            end

            if string.find(target_name, lowered_name, 1, true) then
                partial_matches[#partial_matches + 1] = target_ply
            end
        end

        if #partial_matches == 1 then
            return partial_matches[1]
        end

        if #partial_matches == 0 then
            return nil, "no player matches '" .. trimmed_name .. "'"
        end

        return nil, "multiple players match '" .. trimmed_name .. "'"
    end

    COMMANDS.zc_god = {function(ply)
        if not ply.organism then return end

        local enableGod = not ply.organism.godmode

        if enableGod then
            ply.ZCGodStoredModel = ply:GetModel()
            ply.ZCGodStoredAppearance = ply.CurAppearance and table.Copy(ply.CurAppearance) or nil
        end

        ply.organism.godmode = !ply.organism.godmode

        if ply.organism.godmode then
            ZC_ApplyGodModel(ply)
        else
            ZC_RestoreGodModel(ply)
        end

		ply:Notify(ply.organism.godmode and "now i'm immortal..." or "now i'm mortal")
		return
    end,1}

    COMMANDS.power = {function(ply, args)
        if not ZC_CanUsePowerCommand(ply) then
            if IsValid(ply) then
                ply:Notify("this command is only for the usergroups superadmin and headadmin")
            end
            return
        end

        local target_ply = ply

        if args[1] then
            local resolved_target, resolve_error = ZC_FindSinglePlayerByName(table.concat(args, " "))

            if not IsValid(resolved_target) then
                ply:Notify(resolve_error)
                return
            end

            target_ply = resolved_target
        end

        if not target_ply.organism then
            if target_ply == ply then
                ply:Notify("your organism is not ready yet")
            else
                ply:Notify(target_ply:Name() .. "'s organism is not ready yet")
            end

            return
        end

        local enablePower = not target_ply.ZCPowerEnabled

        if enablePower then
            target_ply.ZCPowerStoredSuperfighter = target_ply.organism.superfighter == true
            target_ply.ZCPowerStoredRecoilMul = target_ply.organism.recoilmul or 1
            target_ply.ZCPowerEnabled = true

            ZC_ApplyPowerState(target_ply)

            if target_ply == ply then
                ply:Notify("super power enabled")
            else
                ply:Notify("super power enabled for " .. target_ply:Name())
                target_ply:Notify("super power enabled by " .. ply:Name())
            end
        else
            target_ply.ZCPowerEnabled = nil
            ZC_RemovePowerState(target_ply)

            target_ply.ZCPowerStoredSuperfighter = nil
            target_ply.ZCPowerStoredRecoilMul = nil

            if target_ply == ply then
                ply:Notify("super power disabled")
            else
                ply:Notify("super power disabled for " .. target_ply:Name())
                target_ply:Notify("super power disabled by " .. ply:Name())
            end
        end
    end,2,"[player]"}

    hook.Add("PlayerSpawn", "ZC_GodModelPersist", function(ply)
        if not IsValid(ply) or not ply.organism or not ply.organism.godmode then return end

        timer.Simple(0, function()
            if not IsValid(ply) or not ply.organism or not ply.organism.godmode then return end
            ZC_ApplyGodModel(ply)
        end)
    end)

    hook.Add("PlayerSpawn", "ZC_PowerPersist", function(ply)
        if not IsValid(ply) or not ply.ZCPowerEnabled then return end

        timer.Simple(0, function()
            if not IsValid(ply) or not ply.ZCPowerEnabled then return end
            ZC_ApplyPowerState(ply)
        end)
    end)

    hook.Add("EntityTakeDamage", "ZC_PowerMeleeKnockback", function(target, dmginfo)
        local attacker = dmginfo:GetAttacker()
        local is_power_melee_hit, victim = ZC_IsPowerMeleeHit(attacker, target, dmginfo)

        if not is_power_melee_hit then return end
        ZC_TriggerPowerMeleeKnockback(attacker, target, victim, dmginfo)
    end)

	COMMANDS.zc_cloak = {function(ply)
        if not ply.organism then return end
		ply.cloak = !ply.cloak
        ply:SetMaterial(ply.cloak and "NULL" or nil)
		ply:DrawShadow(!ply.cloak)
		hg.SafeSetCollisionGroup(ply, ply.cloak and COLLISION_GROUP_DEBRIS or COLLISION_GROUP_PLAYER)
		ply:RemoveAllDecals()
		ply:Notify(ply.cloak and "now i'm invisible..." or "now i'm visible") -- walking by the wall
		return
    end,1}

    COMMANDS.punish = {function(ply, args)
        if #args < 1 then
            ply:ChatPrint("Give me the name of this OwO .")
            return
        end

        local targetNickPartial = string.lower(args[1]) 
        local target = nil
        for _, player in player.Iterator() do
            if string.find(string.lower(player:Nick()), targetNickPartial) then 
                target = player
                break
            end
        end

        if not IsValid(target) then
            ply:ChatPrint("I don't see that OwO .")
            return
        end

        target = hg.GetCurrentCharacter(target)

        net.Start("AnotherLightningEffect")
        net.WriteEntity(target)
        net.Broadcast()

        net.Start("PunishLightningEffect")
        net.WriteEntity(target)
        net.Broadcast()

        target:EmitSound("snd_jack_hmcd_lightning.wav")

        local dmg = DamageInfo()
        dmg:SetDamage(1000)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        dmg:SetDamageType(DMG_SHOCK)
        target:TakeDamageInfo(dmg)

        ply:ChatPrint("Fatass " .. target:Nick() .. " has been punished.")
    end, 2, "ник игрока"}

    COMMANDS.pluv = {function(ply, args)
        net.Start("PluvCommand")
        net.Send(ply)
    end, 0}

    COMMANDS.notify = {function(ply, args)
        if #args < 2 then
            ply:ChatPrint("Usage: !notify <player> <message>")
            return
        end

        local targetNickPartial = string.lower(args[1]) 
        local target = nil
        for _, player in player.Iterator() do
            if string.find(string.lower(player:Nick()), targetNickPartial) then 
                target = player
                break
            end
        end

        if not IsValid(target) then
            ply:ChatPrint("Player not found: " .. args[1])
            return
        end
        
        table.remove(args, 1) 
        local message = table.concat(args, " ")
        
        if message == "" then
            ply:ChatPrint("Message cannot be empty!")
            return
        end
        
        target:Notify(message, 0)
        ply:ChatPrint("Sent notification to " .. target:GetName() .. ": " .. message)

    end, 2, "name; message"}

	COMMANDS.setmodel = {function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 1 and args[1] or ply:Name()
		local mdl = #args > 1 and args[2] or args[1]

		for i, ply2 in pairs(player.GetListByName(plya)) do
			if ply2:Alive() then
				local Appearance = ply2.CurAppearance or hg.Appearance.GetRandomAppearance()
				Appearance.AColthes = ""
				ply2:SetNetVar("Accessories", "")
				ply2:SetModel(mdl)
				ply2:SetSubMaterial()
				ply2:SetPlayerColor(ply2:GetNWVector("PlayerColor", vector_origin))

				ply:ChatPrint(ply2:Name().. "'s model set to " .. tostring(mdl))
			end
		end
	end, 0}

	--// Aliases
	COMMANDS.model = COMMANDS.setmodel
	COMMANDS.playermodel = COMMANDS.setmodel
	COMMANDS.setplayermodel = COMMANDS.setmodel

	COMMANDS.setscale = {function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 1 and args[1] or ply:Name()
		local scale = #args > 1 and args[2] or args[1]

		for i, ply2 in pairs(player.GetListByName(plya)) do
			if ply2:Alive() then
				ply2:SetModelScale(scale)

				ply:ChatPrint(ply2:Name().. "'s model scale set to " .. tostring(scale))
			end
		end
	end, 0}

	--// Aliases
	COMMANDS.setsize = COMMANDS.setscale
	COMMANDS.scale = COMMANDS.setscale
	COMMANDS.size = COMMANDS.setscale
	COMMANDS.setmodelscale = COMMANDS.setscale
	COMMANDS.modelscale = COMMANDS.setscale
end

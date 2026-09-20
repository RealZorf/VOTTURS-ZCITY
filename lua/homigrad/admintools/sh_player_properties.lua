local PROPERTY_TARGET_RANGE = 1152
local PROPERTY_DEFAULT_COOLDOWN = 0.2

local function cleanLogValue(value)
	return string.gsub(string.sub(tostring(value or ""), 1, 256), "[\r\n]", " ")
end

local function actorLabel(ply)
	if not IsValid(ply) then return "invalid actor" end
	return cleanLogValue(ply:Nick()) .. " [" .. cleanLogValue(ply:SteamID()) .. "]"
end

local function targetLabel(ply)
	if not IsValid(ply) then return "invalid target" end
	return cleanLogValue(ply:Nick()) .. " [" .. cleanLogValue(ply:SteamID()) .. "]"
end

local function securityLog(ply, message)
	if not SERVER then return end
	if IsValid(ply) and (ply.HGPropertySecurityLogNext or 0) > CurTime() then return end
	if IsValid(ply) then ply.HGPropertySecurityLogNext = CurTime() + 1 end
	ServerLog("[ZC LOG] " .. actorLabel(ply) .. ": " .. cleanLogValue(message) .. "\n")
end

local function auditLog(ply, action, target, detail)
	if not SERVER then return end
	local suffix = detail and detail ~= "" and (" (" .. cleanLogValue(detail) .. ")") or ""
	ServerLog("[ZC LOG] " .. actorLabel(ply) .. " used " .. cleanLogValue(action) .. " on " .. targetLabel(target) .. suffix .. "\n")
end

local function resolvePlayerTarget(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent end
	if not ent:IsRagdoll() then return nil end

	local target = hg.RagdollOwner(ent) or ent.ply
	if not IsValid(target) and ent.GetNWEntity then
		target = ent:GetNWEntity("ply", NULL)
	end

	return IsValid(target) and target:IsPlayer() and target or nil
end

local function targetDisplayName(ent)
	local target = resolvePlayerTarget(ent)
	return IsValid(target) and target:Nick() or "player"
end

local function resolveCharacterTarget(ent, target)
	target = target or resolvePlayerTarget(ent)
	if not IsValid(target) then return nil end

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(target) or nil
	if IsValid(character) and character.organism then return character end
	if IsValid(ent) and ent.organism then return ent end
	if target.organism then return target end
end

local function canTargetPlayer(actor, target)
	if not IsValid(actor) or not IsValid(target) or not target:IsPlayer() then return false end
	if target ~= actor and target:IsAdmin() and not actor:IsSuperAdmin() then return false end
	return true
end

local function isTargetInRange(actor, ent, target)
	if not SERVER or actor == target then return true end
	local target_pos = IsValid(ent) and ent:WorldSpaceCenter() or target:WorldSpaceCenter()
	return actor:EyePos():DistToSqr(target_pos) <= PROPERTY_TARGET_RANGE ^ 2
end

local function check(self, ent, ply)
	if not IsValid(ply) or not ply:ZCTools_GetAccess() then return false end
	local target = resolvePlayerTarget(ent)
	return IsValid(target) and canTargetPlayer(ply, target)
end

local function checkSuper(self, ent, ply)
	if not IsValid(ply) or not ply:ZCTools_GetAccess(true) then return false end
	local target = resolvePlayerTarget(ent)
	return IsValid(target) and canTargetPlayer(ply, target)
end

local function beginRequest(ply, action, length, superadmin, cooldown, max_bits)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not ply:ZCTools_GetAccess(superadmin == true) then
		securityLog(ply, "blocked " .. action .. " without permission")
		return false
	end
	if length > (max_bits or 4096) then
		securityLog(ply, "blocked oversized " .. action .. " payload")
		return false
	end

	ply.HGPropertyCooldowns = ply.HGPropertyCooldowns or {}
	local now = CurTime()
	if (ply.HGPropertyGlobalCooldown or 0) > now then
		securityLog(ply, "rate-limited property request flood")
		return false
	end
	if (ply.HGPropertyCooldowns[action] or 0) > now then
		securityLog(ply, "rate-limited " .. action)
		return false
	end
	ply.HGPropertyGlobalCooldown = now + 0.05
	ply.HGPropertyCooldowns[action] = now + (cooldown or PROPERTY_DEFAULT_COOLDOWN)
	return true
end

local function authorizePlayerTarget(ply, ent, action, require_alive)
	local target = resolvePlayerTarget(ent)
	if not IsValid(target) or not canTargetPlayer(ply, target) then
		securityLog(ply, "blocked " .. action .. " with an invalid or protected target")
		return nil
	end
	if require_alive and not target:Alive() then return nil end
	if not isTargetInRange(ply, ent, target) then
		securityLog(ply, "blocked remote " .. action .. " outside the property range")
		return nil
	end

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(target) or nil
	if IsValid(character) and character ~= ent and not isTargetInRange(ply, character, target) then
		securityLog(ply, "blocked proxied " .. action .. " outside the property range")
		return nil
	end
	return target
end

local function readPlayerRequest(ply, action, length, superadmin, require_alive, cooldown, max_bits)
	if not beginRequest(ply, action, length, superadmin, cooldown, max_bits) then return nil end
	local ent = net.ReadEntity()
	local target = authorizePlayerTarget(ply, ent, action, require_alive)
	return target, ent
end

properties.Add("copy_steamid", {
    MenuLabel = "Copy SteamID",
    Order = 1,
    MenuIcon = "icon16/user.png",

    Filter = check,

    Action = function(self, ent) -- CLIENT
        local ply = hg.RagdollOwner(ent) or ent
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local sid = ply:SteamID()
        SetClipboardText(sid)

        chat.AddText(Color(0, 200, 255), "[Context menu] ",
            Color(255,255,255), "copied SteamID: ",
            Color(0,255,100), sid
        )
    end
} )

properties.Add( "notify", {
	MenuLabel = "Notify", -- Name to display on the context menu
	Order = 2, -- The order to display this property relative to other properties
	MenuIcon = "icon16/note_add.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_StringRequest(
			"Notify " .. targetDisplayName(ent),
            "Write a message",
            "",
            function(text) 
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteString( text )
                self:MsgEnd()
            end
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "notify", length, false, false, 0.5, 4096)
		if not IsValid(target) then return end
		local text = string.Trim(string.sub(net.ReadString(), 1, 256))
		if text == "" then return end

		target:Notify(text, 0)
		auditLog(ply, "notify", target, text)
	end 
} )

properties.Add( "givegun", {
	MenuLabel = "Give", -- Name to display on the context menu
	Order = 3, -- The order to display this property relative to other properties
	MenuIcon = "icon16/gun.png", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_StringRequest(
			"Give " .. targetDisplayName(ent),
            "Write a entity class name",
            "",
            function(text) 
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteString( text )
                self:MsgEnd()
            end
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "give weapon", length, true, true, 0.35, 2048)
		if not IsValid(target) then return end
		local class = string.lower(string.Trim(string.sub(net.ReadString(), 1, 64)))
		if class == "" or not string.match(class, "^[%w_]+$") or not weapons.GetStored(class) then
			securityLog(ply, "blocked invalid weapon class")
			return
		end

		local spawned = target:Give(class)
		if not IsValid(spawned) then return end
		spawned:Use(target)
		auditLog(ply, "give weapon", target, class)
	end 
} )

properties.Add( "strip", {
	MenuLabel = "Strip", -- Name to display on the context menu
	Order = 4, -- The order to display this property relative to other properties
	MenuIcon = "icon16/basket_delete.png", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "The player will be stripped down to only their fists.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"No"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "strip", length, true, true, 0.35, 512)
		if not IsValid(target) then return end
		target:StripWeapons()
		target:Give("weapon_hands_sh")
		auditLog(ply, "strip", target)
	end 
} )

properties.Add( "fullstrip", {
	MenuLabel = "Full Strip", -- Name to display on the context menu
	Order = 5, -- The order to display this property relative to other properties
	MenuIcon = "icon16/lorry_delete.png", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "All weapons, including fists, will be stripped.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"No"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "full strip", length, true, true, 0.35, 512)
		if not IsValid(target) then return end
		target:StripWeapons()
		auditLog(ply, "full strip", target)
	end 
} )

properties.Add( "reset_org", {
	MenuLabel = "Reset organism", -- Name to display on the context menu
	Order = 6, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart_add.png", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "Organism will be new like a respawn",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"No"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target, selected = readPlayerRequest(ply, "reset organism", length, true, true, 0.5, 512)
		if not IsValid(target) then return end
		local character = resolveCharacterTarget(selected, target)
		if not IsValid(character) or not character.organism then return end

		hg.organism.Clear(character.organism)
		auditLog(ply, "reset organism", target)
	end 
} )

properties.Add( "freeze", {
	MenuLabel = "Freeze", -- Name to display on the context menu
	Order = 7, -- The order to display this property relative to other properties
	MenuIcon = "icon16/control_pause_blue.png", -- The icon to display next to the property

	Filter = function( self, ent, ply )
		if not check(self, ent, ply) then return false end
		local target = resolvePlayerTarget(ent)
		self.MenuLabel = target:IsFrozen() and "Unfreeze" or "Freeze"
		self.MenuIcon = target:IsFrozen() and "icon16/control_pause.png" or "icon16/control_pause_blue.png"
		return true
	end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "freeze", length, false, false, 0.25, 512)
		if not IsValid(target) then return end
		local freeze = not target:IsFrozen()
		target:Freeze(freeze)
		auditLog(ply, freeze and "freeze" or "unfreeze", target)
	end 
} )

properties.Add( "snatch", {
	MenuLabel = "Snatch", -- Name to display on the context menu
	Order = 8, -- The order to display this property relative to other properties
	MenuIcon = "icon16/cross.png", -- The icon to display next to the property

	Filter = function(self, ent, ply)
        if !CurrentRound then return false end
        
		return checkSuper(self, ent, ply)
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "If no players are around, he will simply disappear.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"No"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "snatch", length, true, true, 2, 512)
		if not IsValid(target) then return end
		if not CurrentRound or not CurrentRound() or not zb or zb.ROUND_STATE ~= 1 then return end
		local bot = ents.Create("bot_fear")
		if not IsValid(bot) then return end
		bot.Victim = target
		bot:Spawn()
		auditLog(ply, "snatch", target)
	end 
} )

properties.Add( "ragdollize", {
	MenuLabel = "Stun/Get up", -- Name to display on the context menu
	Order = 9, -- The order to display this property relative to other properties
	MenuIcon = "icon16/anchor.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target = readPlayerRequest(ply, "stun toggle", length, false, true, 0.5, 512)
		if not IsValid(target) then return end

		if not IsValid(target.FakeRagdoll) then
			hg.LightStunPlayer(target, 5)
			auditLog(ply, "stun", target)
		else
			hg.FakeUp(target)
			auditLog(ply, "force get up", target)
		end
	end 
} )

properties.Add( "vomit", {
	MenuLabel = "Make vomit", -- Name to display on the context menu
	Order = 10, -- The order to display this property relative to other properties
	MenuIcon = "pluv/pluv51.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target, selected = readPlayerRequest(ply, "vomit", length, false, true, 1, 512)
		if not IsValid(target) then return end
		local character = resolveCharacterTarget(selected, target)
		if not IsValid(character) or not character.organism then return end
		hg.organism.Vomit(character)
		auditLog(ply, "vomit", target)
	end 
} )

properties.Add( "lobotomize", {
	MenuLabel = "Lobotomize", -- Name to display on the context menu
	Order = 11, -- The order to display this property relative to other properties
	MenuIcon = "pluv/pluv51.png", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local target, selected = readPlayerRequest(ply, "lobotomize", length, true, true, 0.5, 512)
		if not IsValid(target) then return end
		local character = resolveCharacterTarget(selected, target)
		if not IsValid(character) or not character.organism then return end

		character.organism.brain = math.Clamp((tonumber(character.organism.brain) or 0) + 0.05, 0, 1)
		ply:ChatPrint("Lobotomized brain to " .. math.Round(character.organism.brain * 100) .. "%")
		auditLog(ply, "lobotomize", target, tostring(math.Round(character.organism.brain * 100)) .. "%")

		if character.organism.brain >= 0.25 and character.organism.brain < 0.3 then
			ply:ChatPrint("Consciousness loss on the next lobotomization!")
		end
    end 
} )

properties.Add("killsilent", {
	MenuLabel = "Kill (Silent)",
	Order = 12,
	MenuIcon = "icon16/cross.png",

	Filter = checkSuper,
	Action = function( self, ent )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply )
		local target = readPlayerRequest(ply, "silent kill", length, true, true, 0.5, 512)
		if not IsValid(target) then return end
		auditLog(ply, "silent kill", target)
		target:Kill()
	end 
})

properties.Add("removeply", {
	MenuLabel = "Kick",
	Order = 13,
	MenuIcon = "icon16/cross.png",

	Filter = checkSuper,
	Action = function( self, ent )
		Derma_Query(
			"The player will be disconnected from the server.",
			"Are you sure?",
			"Yes",
			function()
				self:MsgStart()
					net.WriteEntity(ent)
				self:MsgEnd()
			end,
			"No"
		)
	end,
	Receive = function( self, length, ply )
		local target = readPlayerRequest(ply, "kick", length, true, false, 1, 512)
		if not IsValid(target) or target == ply then return end
		auditLog(ply, "kick", target)
		target:Kick("Removed by a server administrator.")
	end 
})

properties.Add( "setplayerclass", {
	MenuLabel = "Set player class", -- Name to display on the context menu
	Order = 14, -- The order to display this property relative to other properties
	MenuIcon = "vgui/entities/npc_nukude_proto_h", -- The icon to display next to the property

	Filter = checkSuper,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	PlayerClass = function( self, ent, name )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteString( name )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply )
		local target = readPlayerRequest(ply, "set player class", length, true, false, 0.5, 2048)
		if not IsValid(target) then return end
		local class = string.sub(net.ReadString(), 1, 64)
		if not player.classList[class] then
			securityLog(ply, "blocked invalid player class")
			return
		end

		target:SetPlayerClass(class)
		auditLog(ply, "set player class", target, class)
	end,
	MenuOpen = function( self, option, ent, tr )
		local target = resolvePlayerTarget(ent)
		if not IsValid(target) then return end
		local submenu = option:AddSubMenu()

		for name, tbl in pairs(player.classList) do
			local opt = submenu:AddOption(name)
			opt:SetRadio(true)
			opt:SetChecked(target.PlayerClassName == name)
			opt:SetIsCheckable(true)
			opt.OnChecked = function(s, checked)
				self:PlayerClass(ent, name)
			end	
		end
	end
} )

properties.Add( "break_limb", {
	MenuLabel = "Break Limb",
	Order = 15,
	MenuIcon = "pluv/pluv51.png",

	Filter = checkSuper,
	MenuOpen = function( self, option, ent, tr )
		local target = resolvePlayerTarget(ent)
		ent = resolveCharacterTarget(ent, target)
		if not IsValid(ent) or not ent.organism then return end

		local submenu = option:AddSubMenu()

		local neck = submenu:AddOption("Neck")
		neck:SetRadio(true)
		neck:SetChecked(ent.organism.larm > 0)
		neck:SetIsCheckable(true)
		neck.OnChecked = function(s, checked) self:BreakLimb(ent, 0) end

		local larm = submenu:AddOption("Left Arm")
		larm:SetRadio(true)
		larm:SetChecked(ent.organism.larm > 0)
		larm:SetIsCheckable(true)
		larm.OnChecked = function(s, checked) self:BreakLimb(ent, 1) end

		local rarm = submenu:AddOption("Right Arm")
		rarm:SetRadio(true)
		rarm:SetChecked(ent.organism.rarm > 0)
		rarm:SetIsCheckable(true)
		rarm.OnChecked = function(s, checked) self:BreakLimb(ent, 2) end

		local lleg = submenu:AddOption("Left Leg")
		lleg:SetRadio(true)
		lleg:SetChecked(ent.organism.lleg > 0)
		lleg:SetIsCheckable(true)
		lleg.OnChecked = function(s, checked) self:BreakLimb(ent, 3) end

		local rleg = submenu:AddOption("Right Leg")
		rleg:SetRadio(true)
		rleg:SetChecked(ent.organism.rleg > 0)
		rleg:SetIsCheckable(true)
		rleg.OnChecked = function(s, checked) self:BreakLimb(ent, 4) end

		local spine1 = submenu:AddOption("Spine 1")
		spine1:SetRadio(true)
		spine1:SetChecked(ent.organism.rleg > 0)
		spine1:SetIsCheckable(true)
		spine1.OnChecked = function(s, checked) self:BreakLimb(ent, 5) end

		local spine2 = submenu:AddOption("Spine 2")
		spine2:SetRadio(true)
		spine2:SetChecked(ent.organism.rleg > 0)
		spine2:SetIsCheckable(true)
		spine2.OnChecked = function(s, checked) self:BreakLimb(ent, 6) end

		local spine3 = submenu:AddOption("Spine 3")
		spine3:SetRadio(true)
		spine3:SetChecked(ent.organism.rleg > 0)
		spine3:SetIsCheckable(true)
		spine3.OnChecked = function(s, checked) self:BreakLimb(ent, 7) end
	end,

	BreakLimb = function( self, ent, id )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,

	Receive = function( self, length, ply )
		local target, selected = readPlayerRequest(ply, "break limb", length, true, true, 0.35, 768)
		if not IsValid(target) then return end
		local limb = net.ReadUInt( 8 )
		if limb > 7 then
			securityLog(ply, "blocked invalid break limb id")
			return
		end
		local ent = resolveCharacterTarget(selected, target)
		if not IsValid(ent) or not ent.organism then return end

		auditLog(ply, "break limb", target, tostring(limb))
        
        local dmgInfo = DamageInfo()
		if limb == 0 then
            hg.BreakNeck(ent)
        elseif limb == 1 then
            hg.organism.input_list.larmup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 2 then
			hg.organism.input_list.rarmup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 3 then
			hg.organism.input_list.llegup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 4 then
			hg.organism.input_list.rlegup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 5 then
			hg.organism.input_list.spine1(ent.organism, 0, 1, dmgInfo)
		elseif limb == 6 then
			hg.organism.input_list.spine2(ent.organism, 0, 1, dmgInfo)
		elseif limb == 7 then
			hg.organism.input_list.spine3(ent.organism, 0, 1, dmgInfo)
		end
	end
} )

properties.Add( "amputate_limb", {
	MenuLabel = "Amputate Limb",
	Order = 16,
	MenuIcon = "effects/arc9_eft/evil.png",

	Filter = checkSuper,
	MenuOpen = function( self, option, ent, tr )
		local target = resolvePlayerTarget(ent)
		ent = resolveCharacterTarget(ent, target)
		if not IsValid(ent) or not ent.organism then return end

		local submenu = option:AddSubMenu()

		local head = submenu:AddOption("Head")
		head:SetRadio(true)
		head:SetChecked(ent.organism.larm > 0)
		head:SetIsCheckable(true)
		head.OnChecked = function(s, checked) self:AmputateLimb(ent, 0) end

		local larm = submenu:AddOption("Left Arm")
		larm:SetRadio(true)
		larm:SetChecked(ent.organism.larm > 0)
		larm:SetIsCheckable(true)
		larm.OnChecked = function(s, checked) self:AmputateLimb(ent, 1) end

		local rarm = submenu:AddOption("Right Arm")
		rarm:SetRadio(true)
		rarm:SetChecked(ent.organism.rarm > 0)
		rarm:SetIsCheckable(true)
		rarm.OnChecked = function(s, checked) self:AmputateLimb(ent, 2) end

		local lleg = submenu:AddOption("Left Leg")
		lleg:SetRadio(true)
		lleg:SetChecked(ent.organism.lleg > 0)
		lleg:SetIsCheckable(true)
		lleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 3) end

		local rleg = submenu:AddOption("Right Leg")
		rleg:SetRadio(true)
		rleg:SetChecked(ent.organism.rleg > 0)
		rleg:SetIsCheckable(true)
		rleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 4) end
	end,

	AmputateLimb = function( self, ent, id )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,

	Receive = function( self, length, ply )
		local target, selected = readPlayerRequest(ply, "amputate limb", length, true, true, 0.5, 768)
		if not IsValid(target) then return end
		local limb = net.ReadUInt( 8 )
		if limb > 4 then
			securityLog(ply, "blocked invalid amputate limb id")
			return
		end
		local ent = resolveCharacterTarget(selected, target)
		if not IsValid(ent) or not ent.organism then return end

		auditLog(ply, "amputate limb", target, tostring(limb))

		if limb == 0 then
			if SERVER and not ent.noHead then
				hg.ExplodeHead(ent)
			end
        elseif limb == 1 then
            hg.organism.AmputateLimb(ent.organism, "larm")
		elseif limb == 2 then
			hg.organism.AmputateLimb(ent.organism, "rarm")
		elseif limb == 3 then
			hg.organism.AmputateLimb(ent.organism, "lleg")
		elseif limb == 4 then
			hg.organism.AmputateLimb(ent.organism, "rleg")
		end
	end
} )

local doorClasses = {
	func_door = true,
	func_door_rotating = true,
	prop_door_rotating = true,
}

local function doorCheck(self, ent, ply)
	return IsValid(ply) and ply:ZCTools_GetAccess() and IsValid(ent) and doorClasses[ent:GetClass()] == true
end

local function readDoorRequest(ply, action, length)
	if not beginRequest(ply, action, length, false, 0.25, 512) then return nil end
	local ent = net.ReadEntity()
	if not doorCheck(nil, ent, ply) then
		securityLog(ply, "blocked " .. action .. " on a non-door entity")
		return nil
	end
	if ply:EyePos():DistToSqr(ent:WorldSpaceCenter()) > PROPERTY_TARGET_RANGE ^ 2 then
		securityLog(ply, "blocked remote " .. action)
		return nil
	end
	return ent
end

properties.Add( "door_toggle", {
    MenuLabel = "Toggle Door",
    Order = 7,
    MenuIcon = "icon16/door.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
		local ent = readDoorRequest(ply, "toggle door", length)
		if not IsValid(ent) then return end
		ent:Fire("toggle")
		auditLog(ply, "toggle door", ply, ent:GetClass() .. " #" .. ent:EntIndex())
    end
})

properties.Add( "door_lock", {
    MenuLabel = "Lock Door",
    Order = 8,
    MenuIcon = "icon16/lock.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
		local ent = readDoorRequest(ply, "lock door", length)
		if not IsValid(ent) then return end
		ent:Fire("lock")
		auditLog(ply, "lock door", ply, ent:GetClass() .. " #" .. ent:EntIndex())
    end
})

properties.Add( "door_unlock", {
    MenuLabel = "Unlock Door",
    Order = 9,
    MenuIcon = "icon16/lock_open.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
		local ent = readDoorRequest(ply, "unlock door", length)
		if not IsValid(ent) then return end
		ent:Fire("unlock")
		auditLog(ply, "unlock door", ply, ent:GetClass() .. " #" .. ent:EntIndex())
    end
})

local defaultinv = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}

local function normalizeInventory(inventory)
	inventory = istable(inventory) and table.Copy(inventory) or table.Copy(defaultinv)
	inventory.Weapons = istable(inventory.Weapons) and inventory.Weapons or {}
	inventory.Ammo = istable(inventory.Ammo) and inventory.Ammo or {}
	inventory.Armor = istable(inventory.Armor) and inventory.Armor or {}
	inventory.Attachments = istable(inventory.Attachments) and inventory.Attachments or {}
	return inventory
end

local function Respawn(ply,body)
	if not SERVER then return false end
	if not IsValid(ply) or not ply:IsPlayer() or not IsValid(body) or not body:IsRagdoll() then return false end
	if IsValid(body.HGRespawnClaimedBy) then return false end
	body.HGRespawnClaimedBy = ply

	local function releaseClaim()
		if IsValid(body) and body.HGRespawnClaimedBy == ply then body.HGRespawnClaimedBy = nil end
	end

    if ply:Alive() then
		ply:KillSilent()
    end
    ply.gottarespawn = true

    timer.Simple(0.1, function()
		if not IsValid(ply) or not IsValid(body) or body.HGRespawnClaimedBy ~= ply then
			releaseClaim()
			return
		end

        ply:Spawn()
        timer.Simple(0.1, function()
			if not IsValid(ply) or not ply:Alive() or not IsValid(body) or body.HGRespawnClaimedBy ~= ply then
				releaseClaim()
				return
			end

			ply.inventory = normalizeInventory(body.inventory)
            
			ply:SetNetVar("Inventory", ply.inventory)
			local armor = body:GetNetVar("Armor", {})
			ply:SetNetVar("Armor", istable(armor) and table.Copy(armor) or {})
            ply:SetNetVar("HideArmorRender", body:GetNetVar("HideArmorRender", false))
			body:SetNetVar("Armor", {})
            body:SetNetVar("HideArmorRender", false)

			for _,v in pairs(ply.inventory.Weapons) do
                if v == true or not IsValid(v) then continue end
				v:SetParent(ply)
				v:SetOwner(ply)
				v:Use(ply)
            end
			for ammo_type, amount in pairs(ply.inventory.Ammo) do
				if isnumber(amount) then ply:SetAmmo(math.Clamp(math.floor(amount), 0, 65535), ammo_type) end
            end
			ply:Give("weapon_hands_sh")
			hg.Fake(ply, body)
			hg.LightStunPlayer(ply)

            timer.Simple(0.1,function()
				if not IsValid(ply) or not IsValid(body) or body.HGRespawnClaimedBy ~= ply then return end

                if body.CurAppearance then
                    local color = body:GetNWVector("PlayerColor", vector_origin)
					local appearance = table.Copy(body.CurAppearance)
					appearance.AColor = Color(color[1] * 255, color[2] * 255, color[3] * 255)
                    ply:SetPlayerColor(color)
					hg.Appearance.ForceApplyAppearance(ply, appearance)
                    ply:SetModel(body:GetModel())
                else
					local appearance = table.Copy(ply.CurAppearance or hg.Appearance.GetRandomAppearance())
					appearance.AColthes = ""
                    ply:SetNetVar("Accessories", "")
                    ply:SetModel(body:GetModel())
                    ply:SetSubMaterial()
                    ply:SetPlayerColor(ply:GetNWVector("PlayerColor", vector_origin))
					hg.Appearance.ForceApplyAppearance(ply, appearance)
                end
				ply:Give("weapon_hands_sh")
            end)
        end)
    end)

	return true
end

hg.RespawnIntoBody = Respawn

local function bodyCheck(self, body, ply)
	if not IsValid(ply) or not ply:ZCTools_GetAccess(true) then return false end
	if not IsValid(body) or not body:IsRagdoll() then return false end
	if SERVER and IsValid(body.HGRespawnClaimedBy) then return false end
	return true
end

local function readBodyRequest(ply, action, length, cooldown, max_bits)
	if not beginRequest(ply, action, length, true, cooldown or 1, max_bits or 768) then return nil end
	local body = net.ReadEntity()
	if not bodyCheck(nil, body, ply) then
		securityLog(ply, "blocked " .. action .. " with an invalid or claimed body")
		return nil
	end
	if ply:EyePos():DistToSqr(body:WorldSpaceCenter()) > PROPERTY_TARGET_RANGE ^ 2 then
		securityLog(ply, "blocked remote " .. action .. " outside the property range")
		return nil
	end
	return body
end

properties.Add( "respawn_ply_in_rag", {
	MenuLabel = "Respawn Player", -- Name to display on the context menu
	Order = 1, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = bodyCheck,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        hg.DermaPlayerQuery(
            function( ply )
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteEntity( ply )
                self:MsgEnd()
        end)
        
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local body = readBodyRequest(ply, "respawn player into body", length, 1, 1024)
		if not IsValid(body) then return end
		local target = net.ReadEntity()
		if not IsValid(target) or not target:IsPlayer() or not canTargetPlayer(ply, target) then
			securityLog(ply, "blocked respawn with an invalid or protected player")
			return
		end

		if Respawn(target, body) then auditLog(ply, "respawn into body", target, "body #" .. body:EntIndex()) end
	end 
} )

properties.Add( "respawn_lply_in_rag", {
	MenuLabel = "Spawn Self", -- Name to display on the context menu
	Order = 2, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = bodyCheck,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        Derma_Query(
            "You will take over this body, and respawn as this character.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteEntity( LocalPlayer() )
                self:MsgEnd()
            end,
        	"No"
        )    
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local body = readBodyRequest(ply, "respawn self into body", length, 1, 1024)
		if not IsValid(body) then return end
		net.ReadEntity()

		if Respawn(ply, body) then auditLog(ply, "respawn self into body", ply, "body #" .. body:EntIndex()) end
	end 
} )

properties.Add( "respawn_ragply_in_rag", {
	MenuLabel = "Spawn RagOwner", -- Name to display on the context menu
	Order = 3, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = bodyCheck,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        Derma_Query(
            "The Player of this ragdoll will be respawned into his body",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"No"
        )    
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local body = readBodyRequest(ply, "respawn body owner", length, 1, 768)
		if not IsValid(body) then return end
		local target = resolvePlayerTarget(body)
		if not IsValid(target) or not canTargetPlayer(ply, target) then return end

		if Respawn(target, body) then auditLog(ply, "respawn body owner", target, "body #" .. body:EntIndex()) end
	end 
} )


--hg.Fake(owner, body)

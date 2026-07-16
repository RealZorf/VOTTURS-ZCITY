local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Homicide"

--\\
MODE.TraitorExpectedAmtBits = 13
--

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor_SOE = "hmcd_subrole_traitor_soe"
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"
MODE.SubRole_Traitor_Disabled = "traitor_disabled"
MODE.SubRole_Traitor_Disabled_SOE = "traitor_disabled_soe"
MODE.SubRole_Traitor_Random = "traitor_random"
MODE.SubRole_Traitor_Random_SOE = "traitor_random_soe"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor_SOE = CreateClientConVar(MODE.ConVarName_SubRole_Traitor_SOE, "traitor_default_soe", true, true, "Choosing the role of a tutor in the SOE homeside mode")
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_default", true, true, "Choosing the role of a treator in the standard homeside mode")
end

function MODE.IsThiefRole(subrole)
	return subrole == "traitor_thief" or subrole == "traitor_thief_soe"
end

function MODE.IsChemistRole(subrole)
	return subrole == "traitor_chemist" or subrole == "traitor_chemist_soe"
end

function MODE.IsAssassinRole(subrole)
	return subrole == "traitor_assassin" or subrole == "traitor_assassin_soe"
		or subrole == "traitor_assasin" or subrole == "traitor_assasin_soe"
end

function MODE.NormalizeTraitorSubRole(subrole)
	if subrole == "traitor_assasin" then return "traitor_assassin" end
	if subrole == "traitor_assasin_soe" then return "traitor_assassin_soe" end

	return subrole
end

if SERVER then
	function MODE.MarkThiefStartInventory(ply)
		if not IsValid(ply) then return end

		ply.HMCD_ThiefInitializing = nil
		ply.HMCD_IsThief = true
		ply.HMCD_ThiefPickupInventory = {}
	end
end

--; TODO
--; Engineer - shahid bomb + food

function MODE.ApplyJuggernautStats(ply)
	if not IsValid(ply) or not ply.organism then return end

	if(hg and hg.SetPlayerModelScale)then
		hg.SetPlayerModelScale(ply, MODE.JuggernautModelScale or 1.15, "traitor_role")
	else
		ply:SetModelScale(MODE.JuggernautModelScale or 1.15, 0)
	end

	local stamina = ply.organism.stamina
	if(stamina)then
		local base_stamina = MODE.BaseProfessionStamina or 180
		local old_range = math.max(stamina.range or base_stamina, 1)
		local current_ratio = math.Clamp((stamina[1] or old_range) / old_range, 0, 1)
		local stamina_max = math.max(1, math.Round(base_stamina * (MODE.JuggernautStaminaMultiplier or 2)))

		stamina.range = stamina_max
		stamina.max = stamina_max
		stamina[1] = math.Clamp(math.Round(stamina_max * current_ratio), 0, stamina.max)
	end

	ply.HMCDJuggernautStatsApplied = true
	ply.MeleeDamageMul = MODE.JuggernautMeleeDamageMultiplier or 1.5
	ply.StaminaExhaustMul = MODE.JuggernautStaminaExhaustMultiplier or 0.7
	ply.JumpPowerMul = MODE.JuggernautJumpPowerMultiplier or 1.15
	ply.organism.legstrength = MODE.JuggernautLegStrengthMultiplier or 1.5
end

function MODE.GiveJuggernautCrowbar(ply)
	if not IsValid(ply) then return end

	local crowbar = ply:Give("weapon_hg_crowbar")
	if IsValid(crowbar) then
		crowbar.NoHolster = false
		crowbar.DontEquipInstantly = true
		crowbar.HMCDJuggernautCrowbar = true
	end

	timer.Simple(0, function()
		if not IsValid(ply) or not ply:Alive() then return end
		if ply:HasWeapon("weapon_hands_sh") then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)

	return crowbar
end

MODE.SubRoles = {
	--=\\Traitor
	--==\\
	--; https://youtu.be/zP7ux8WsYYI?si=S-Uw2EAehGR5WD3D
	["traitor_default"] = {
		Name = "Defoko",
		Description = [[Default.
You've prepared for a long time.
You are equipped with various weapons, poisons and explosives, grenades and your favourite heavy duty knife and a zoraki signal pistol to help you kill.]],
		Objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			local p22 = ply:Give("weapon_p22")
			if not IsValid(p22) then return end
			ply:GiveAmmo(p22:GetMaxClip1() * 1, p22:GetPrimaryAmmoType(), true)
			
			hg.AddAttachmentForce(ply, p22, "supressor4")
			
			ply:Give("weapon_buck200knife")	
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_shuriken")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_jam")
			ply:Give("weapon_hg_fiberwire")
			-- ply:Give("weapon_traitor_poison2")
			-- ply:Give("weapon_traitor_poison3")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_default_soe"] = {
		Name = "Defoko",
		Description = [[Default.
You've prepared a long time for this moment.
You are equipped with various weapons, poisons and explosives, grenades and your favourite heavy duty knife and silenced pistol with an additional mag to help you kill.]],
		Objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			local p22 = ply:Give("weapon_p22")
			if not IsValid(p22) then return end
			ply:GiveAmmo(p22:GetMaxClip1() * 1, p22:GetPrimaryAmmoType(), true)
			
			hg.AddAttachmentForce(ply, p22, "supressor4")
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory",inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_infiltrator"] = {
		Name = "Infiltrator",
		Description = [[Can break people's necks from behind.
Can completely disguise as other players if they're in ragdoll.
Has no weapons or tools except knife, epipen and smoke grenade.
For people who like to play chess.]],
		Objective = "You're an expert in diversion. Be discreet and kill one by one",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_infiltrator_soe"] = {
		Name = "Infiltrator",
		Description = [[Can break people's necks from behind.
Can completely disguise as other players if they're in ragdoll.
Has smoke grenade, walkie-talkie, knife, taser with 2 additional shooting heads and epipen.
For people who like to play chess.]],
		Objective = "You're an expert in diversion. Be discreet and kill one by one",
		SpawnFunction = function(ply)
			local taser = ply:Give("weapon_taser")
			
			ply:GiveAmmo(taser:GetMaxClip1() * 2, taser:GetPrimaryAmmoType(), true)
			ply:Give("weapon_sogknife")
			-- ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_thief"] = {
		Name = "Thief",
		Description = [[Can search standing players.
Every item found while searching a player is instantly revealed.
Your starting gear is hidden from anyone searching you; only items you pick up during the round are exposed.]],
		Objective = "You are the Thief. Pickpocket from the living, traitor items stay hidden when searched, and murder everyone.",
		SpawnFunction = function(ply)
			ply.HMCD_ThiefInitializing = true

			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")

			ply.organism.stamina.max = 280
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
			MODE.MarkThiefStartInventory(ply)
		end,
	},
	--==//
	
	--==\\
	["traitor_thief_soe"] = {
		Name = "Thief",
		Description = [[Can search standing players.
Every item found while searching a player is instantly revealed.
Your starting gear is hidden from anyone searching you; only items you pick up during the round are exposed.
Equipped with a walkie-talkie for State of Emergency coordination.]],
		Objective = "You are the Thief. Pickpocket from the living, traitor items stay hidden when searched, and murder everyone.",
		SpawnFunction = function(ply)
			ply.HMCD_ThiefInitializing = true

			ply:Give("weapon_sogknife")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")

			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 280
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
			MODE.MarkThiefStartInventory(ply)
		end,
	},
	--==//

	--==\\
	["traitor_assassin"] = {
		Name = "Assassin",
		Description = [[Can quickly disarm people from any angle.
Disarms faster from behind.
Disarms faster from front if the victim is in ragdoll.
Proficient in shooting from guns.
Has additional stamina (+ 80 units compared to other traitors).
Equipped with walkie-talkie and a katana as last resort melee weapon.
For people who like to play checkers.]],
		Objective = "You're an expert in guns and in disarmament. Disarm gunman and use his weapon against others",
		SpawnFunction = function(ply)
			ply:Give("weapon_katana")
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.6
			ply.organism.stamina.max = 300
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_sling"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_assassin_soe"] = {
		Name = "Assassin",
		Description = [[Can quickly disarm people from any angle.
Disarms faster from behind.
Disarms faster from front if the victim is in ragdoll.
Equipped with a katana as last resort melee weapon.
Proficient in shooting from guns.
Has additional stamina (+ 80 units compared to other traitors).
Equipped with walkie-talkie, knife, epipen, flashlight and a katana as last resort melee weapon.
For people who like to play checkers.]],
		Objective = "You're an expert in guns and in disarmament. Disarm gunman and use his weapon against others",
		SpawnFunction = function(ply)
			ply:Give("weapon_katana")	
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_hg_fiberwire")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.4
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {})
			--inv["Weapons"]["hg_flashlight"] = true
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_sling"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_chemist"] = {
		Name = "Chemist",
		Description = [[Has multiple chemical agents and epipen and knife.
Resistant to a certain degree to all chemical agents mentioned.
Can detect presence and potency of chemical agents in the air.]],
		Objective = "You're a chemist who decided to use his knowledge to hurt others. Poison everything.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_poison_consumable")
			ply:Give("weapon_traitor_sleepcanister")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
			if CleanChemicalsOfPlayer then
				CleanChemicalsOfPlayer(ply)
			end
		end,
	},	
	--==//

	["traitor_chemist_soe"] = {
			Name = "Chemist",
			Description = [[Has multiple chemical agents and epipen and knife.
Resistant to a certain degree to all chemical agents mentioned.
Can detect presence and potency of chemical agents in the air.]],
			Objective = "You're a chemist who decided to use his knowledge to hurt others. Poison everything.",
			SpawnFunction = function(ply)
				ply:Give("weapon_sogknife")
				ply:Give("weapon_walkie_talkie")
				ply:Give("weapon_adrenaline")
				ply:Give("weapon_traitor_poison1")
				ply:Give("weapon_traitor_poison2")
				ply:Give("weapon_traitor_poison3")
				ply:Give("weapon_traitor_poison4")
				ply:Give("weapon_traitor_poison_consumable")
				ply:Give("weapon_traitor_sleepcanister")
				ply:Give("weapon_hg_fiberwire")
			
				ply.organism.stamina.max = 220
				local inv = ply:GetNetVar("Inventory", {})
				inv["Weapons"]["hg_flashlight"] = true
			
				ply:SetNetVar("Inventory", inv)
				if CleanChemicalsOfPlayer then
					CleanChemicalsOfPlayer(ply)
				end
			end,
		},	
	
	--==\\
	["traitor_shadow"] = {
		Name = "Shadow",
		Description = [[A master of silent elimination.
Stand still next to a wall for a few seconds while upright, then press reload to camouflage with a short slip window after leaving cover.
Equipped with concealed weapons that won't be visible on your body.
Uses tranquilizer gun, tetrodoxin, handcuffs and a disguise.
Enhanced stealth capabilities with increased stamina. (+40 units)
For those who prefer to kill from the shadows.]],
		Objective = "You're a silent killer. Stay hidden, isolate targets and eliminate them without being detected.",
		SpawnFunction = function(ply)
			local tranq = ply:Give("weapon_tranquilizer")
			if IsValid(tranq) then
				local playerCount = #player.GetAll()
				local ammoAmount = math.max(1, math.floor(playerCount / 6))
				ply:GiveAmmo(tranq:GetMaxClip1() * ammoAmount, tranq:GetPrimaryAmmoType(), true)
			end
			ply:Give("weapon_sogknife")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_handcuffs")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_decoynade_tpik")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.stamina.max = 260
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_shadow_soe"] = {
		Name = "Shadow",
		Description = [[A master of silent elimination.
Stand still next to a wall for a few seconds while upright, then press reload to camouflage with a short slip window after leaving cover.
Equipped with concealed weapons that won't be visible on your body.
Uses tranquilizer gun, tetrodoxin, handcuffs and a disguise.
Enhanced stealth capabilities with increased stamina. (+40 units)
For those who prefer to kill from the shadows.]],
		Objective = "You're a silent killer. Use your concealed weapons to eliminate targets without being detected.",
		SpawnFunction = function(ply)
			-- Silent tranquilizer gun for ranged takedowns
			local tranq = ply:Give("weapon_tranquilizer")
			if IsValid(tranq) then
				-- Dynamic ammo based on player count for balance
				local playerCount = #player.GetAll()
				local ammoAmount = math.max(1, math.floor(playerCount / 6)) -- 1 mag per 6 players, minimum 1
				ply:GiveAmmo(tranq:GetMaxClip1() * ammoAmount, tranq:GetPrimaryAmmoType(), true)
			end
			ply:Give("weapon_sogknife")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_handcuffs")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_decoynade_tpik")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.stamina.max = 260
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_maniac"] = {
		Name = "Maniac",
		Description = [[A blood-crazed butcher who lives for close-range slaughter.
Armed with a vicious fire axe and brutal backup weapons, you thrive in chaos and panic.
You have massively increased stamina and extra health, allowing you to keep pushing long after others would fall.
The first serious wound you take triggers permanent adrenaline and fentanyl-like pain suppression without overdose risk.
Melee attacks build Rampage, increasing your speed, damage and attack rate. Fury lets attached injured limbs keep functioning.]],
		Objective = "You are a Maniac. Charge into the chaos, survive your first serious wound, and butcher your victims up close.",
		SpawnFunction = function(ply)
			-- Axe that will be poisonous and holsterable
			local axe = ply:Give("weapon_hg_fireaxe")
			if IsValid(axe) then
				axe.poisoned2 = true	--applys the poison
				axe.NoHolster = false	--allows holstering
			end
			ply:Give("weapon_hg_molotov_tpik")
			ply:Give("weapon_m45")
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_fiberwire")
			
			ply.organism.stamina.max = 440
			local maniacHealth = math.max(120, math.Round((ply:GetMaxHealth() > 0 and ply:GetMaxHealth() or 100) * 1.2))
			ply:SetMaxHealth(maniacHealth)
			ply:SetHealth(maniacHealth)
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			inv["Weapons"]["hg_sling"] = true
			
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_maniac_soe"] = {
		Name = "Maniac",
		Description = [[A blood-crazed butcher who lives for close-range slaughter.
Armed with a vicious fire axe and brutal backup weapons, you thrive in chaos and panic.
You have massively increased stamina and extra health, allowing you to keep pushing long after others would fall.
The first serious wound you take triggers permanent adrenaline and fentanyl-like pain suppression without overdose risk.
Melee attacks build Rampage, increasing your speed, damage and attack rate. Fury lets attached injured limbs keep functioning.]],
		Objective = "You are a Maniac. Charge into the chaos, survive your first serious wound, and butcher your victims up close.",
		SpawnFunction = function(ply)
			local axe = ply:Give("weapon_hg_fireaxe")
			if IsValid(axe) then
				axe.poisoned2 = true
				axe.NoHolster = false
			end
			ply:Give("weapon_hg_molotov_tpik")
			ply:Give("weapon_m45")
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_fiberwire")

			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 440
			local maniacHealth = math.max(120, math.Round((ply:GetMaxHealth() > 0 and ply:GetMaxHealth() or 100) * 1.2))
			ply:SetMaxHealth(maniacHealth)
			ply:SetHealth(maniacHealth)
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			inv["Weapons"]["hg_sling"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_juggernaut"] = {
		Name = "Juggernaut",
		Description = [[A towering traitor built to overpower smaller victims.
You share the Athlete's larger build, but use it for brutal close-quarters control.
You have the same stamina, melee strength, leg strength and jump boost as an Athlete.
Grab smaller non-Athlete victims and hold ALT while lifting them to strangle them.
Slam carried victims into walls or props to deal bonus impact damage and briefly stun them.
Press ALT + E over an unconscious victim's head to stomp their skull.]],
		Objective = "You are the Juggernaut. Overpower smaller victims, strangle them while lifted.",
		SpawnFunction = function(ply)
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_smokenade_tpik")
			MODE.GiveJuggernautCrowbar(ply)

			MODE.ApplyJuggernautStats(ply)

			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_juggernaut_soe"] = {
		Name = "Juggernaut",
		Description = [[A towering traitor built to overpower smaller victims.
You share the Athlete's larger build, but use it for brutal close-quarters control.
You have the same stamina, melee strength, leg strength and jump boost as an Athlete.
Grab smaller non-Athlete victims and hold ALT while lifting them to strangle them.
Slam carried victims into walls or props to deal bonus impact damage and briefly stun them.
Press ALT + E over an unconscious victim's head to stomp their skull.]],
		Objective = "You are the Juggernaut. Overpower smaller victims, strangle them while lifted.",
		SpawnFunction = function(ply)
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_smokenade_tpik")
			MODE.GiveJuggernautCrowbar(ply)

			MODE.ApplyJuggernautStats(ply)

			ply.organism.recoilmul = 1
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_cannibal"] = {
		Name = "Cannibal",
		Description = [[You're an expert in survival and close-quarters combat.
Can consume dead bodies to regain health and blood.
Each consumed body increases your stamina and melee strength for the rest of the round.
Proficient in melee combat and equipped with adrenaline.
For people who enjoy aggressive and high-risk gameplay.]],
		Objective = "You are the Cannibal. Consume fallen victims to restore yourself and grow stronger for each one",
		SpawnFunction = function(ply)
			ply.Ability_CannibalConsumedBodies = nil
			ply.Ability_CannibalBaseStaminaRange = nil
			ply:SetNWInt("HMCD_CannibalStacks", 0)

			local cleaver = ply:Give("weapon_hg_cleaver")
			if IsValid(cleaver) then
				cleaver.NoHolster = false
			end
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_fiberwire")
			ply:Give("weapon_traitor_suit")

			ply.organism.stamina.range = 240
			ply.organism.stamina.max = 240
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_cannibal_soe"] = {
		Name = "Cannibal",
		Description = [[You're an expert in survival and close-quarters combat.
Can consume dead bodies to regain health and blood.
Each consumed body increases your stamina and melee strength for the rest of the round.
Proficient in melee combat and equipped with adrenaline.
For people who enjoy aggressive and high-risk gameplay.]],
		Objective = "You are the Cannibal. Consume fallen victims to restore yourself and grow stronger for each one",
		SpawnFunction = function(ply)
			ply.Ability_CannibalConsumedBodies = nil
			ply.Ability_CannibalBaseStaminaRange = nil
			ply:SetNWInt("HMCD_CannibalStacks", 0)

			local cleaver = ply:Give("weapon_hg_cleaver")
			if IsValid(cleaver) then
				cleaver.NoHolster = false
			end
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_fiberwire")
			ply:Give("weapon_traitor_suit")

			ply.organism.recoilmul = 1
			ply.organism.stamina.range = 240
			ply.organism.stamina.max = 240
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_terrorist"] = {
		Name = "Terrorist",
		Description = [[A ruthless terrorist who wants everyone dead.
You rely on fire, explosives and a bomb vest to turn the whole round into a massacre.
Perfect for aggressive players who want to spread chaos and kill as many people as possible.]],
		Objective = "You are a terrorist. Burn, blast and butcher everyone before they can stop you.",
		SpawnFunction = function(ply)
			ply:Give("weapon_bombvest")
			ply:Give("weapon_claymore")
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_hg_type59_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_buck200knife")

			ply.organism.stamina.max = 300
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_terrorist_soe"] = {
		Name = "Terrorist",
		Description = [[A ruthless terrorist who wants everyone dead.
You rely on fire, explosives and a bomb vest to turn the whole round into a massacre.
Perfect for aggressive players who want to spread chaos and kill as many people as possible.]],
		Objective = "You are a terrorist. Burn, blast and butcher everyone before they can stop you.",
		SpawnFunction = function(ply)
			ply:Give("weapon_claymore")
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_hg_type59_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_bombvest")
			ply:Give("weapon_sogknife")

			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 300
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_lastmanstanding"] = {
		Name = "Last Man Standing",
		Description = [[A relentless killer who is ready to outlive everyone else.
Armed with a concealed De Lisle and brass knuckles, you are built for a brutal final showdown.
Pick your shots carefully, stay calm under pressure and make sure you are the only one left standing.]],
		Objective = "You are the last man standing. Hunt everyone down and be the only survivor.",
		SpawnFunction = function(ply)
			local gun = ply:Give("weapon_delisle")
			if IsValid(gun) then
				gun.shouldntDrawHolstered = true
				gun:SetNWBool("ZCityPocketHolster", true)
				ply:GiveAmmo(20, gun:GetPrimaryAmmoType(), true)
			else
				ply:GiveAmmo(20, "7.62x51mm", true)
			end

			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_sling"] = true
			inv["Weapons"]["hg_brassknuckles"] = true
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_lastmanstanding_soe"] = {
		Name = "Last Man Standing",
		Description = [[A relentless killer who is ready to outlive everyone else.
Armed with a concealed De Lisle, a sling, brass knuckles and a nail gun, you are built for a brutal final showdown.
Pick your shots carefully, stay calm under pressure and make sure you are the only one left standing.]],
		Objective = "You are the last man standing. Hunt everyone down and be the only survivor.",
		SpawnFunction = function(ply)
			local gun = ply:Give("weapon_delisle")
			if IsValid(gun) then
				gun.shouldntDrawHolstered = true
				gun:SetNWBool("ZCityPocketHolster", true)
				ply:GiveAmmo(20, gun:GetPrimaryAmmoType(), true)
			else
				ply:GiveAmmo(20, "7.62x51mm", true)
			end
			ply:Give("weapon_nailgun")
			ply.organism.recoilmul = 1
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_sling"] = true
			inv["Weapons"]["hg_brassknuckles"] = true
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_stalker"] = {
		Name = "Stalker",
		Description = [[A sonar hunter who reads the living by their pulse.
Look at victims briefly to mark up to 3 of them.
Marked victims emit a subtle color pulse through walls in rhythm with their heartbeat.
Isolated marked victims become clearer prey and make your pursuit much quieter.
Your first hit against each marked victim staggers, drains stamina and deals extra damage; isolated prey are punished harder.
You carry a hammer and nails to quietly seal routes around your prey.
Once per round, you can leave behind a dead copy of yourself to fake your death.]],
		Objective = "You are the Stalker. Mark victims, read isolated prey, kill the isolated.",
		SpawnFunction = function(ply)
			ply.HMCDStalkerDeathDecoyUsed = nil
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_fiberwire")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_stalker_decoy")
			ply:Give("weapon_hammer")
			ply:GiveAmmo(6, "Nails", true)

			ply.organism.stamina.max = 260
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_stalker_soe"] = {
		Name = "Stalker",
		Description = [[A sonar hunter who reads the living by their pulse.
Look at victims briefly to mark up to 3 of them.
Marked victims emit a subtle color pulse through walls in rhythm with their heartbeat.
Isolated marked victims become clearer prey and make your pursuit much quieter.
Your first hit against each marked victim staggers, drains stamina and deals extra damage; isolated prey are punished harder.
You carry a hammer and nails to quietly seal routes around your prey.
Once per round, you can leave behind a dead copy of yourself to fake your death.]],
		Objective = "You are the Stalker. Mark victims, read isolated prey, kill the isolated.",
		SpawnFunction = function(ply)
			ply.HMCDStalkerDeathDecoyUsed = nil
			ply:Give("weapon_sogknife")
			ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_fiberwire")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_hg_stalker_decoy")
			ply:Give("weapon_hammer")
			ply:GiveAmmo(6, "Nails", true)

			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 260
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true

			ply:SetNetVar("Inventory", inv)
		end,
	},
	--[[
	 ["traitor_demoman"] = {
		 Name = "Shaid",
		 Description = [[Has many explosives.
 Slightly more stamina than others (+40 Stamina units).
 Has an explosive vest to kill themselves and anyone nearby.
 For those who like to watch things blow up.],
		 Objective = "You're a demolision expert who decided to use your explosives to hurt others.",
		 SpawnFunction = function(ply)
			 ply:Give("weapon_sogknife")
			 ply:Give("weapon_bombvest")
			 ply:Give("weapon_adrenaline")
			 ply:Give("weapon_hg_shuriken")
			 ply:Give("weapon_hg_rgd_tpik")
			 ply:Give("weapon_hg_pipebomb_tpik")
			 ply:Give("weapon_hg_molotov_tpik")
			 ply:Give("weapon_traitor_ied")
			 ply:Give("weapon_walkie_talkie")
			
			 ply.organism.stamina.max = 260
			 local inv = ply:GetNetVar("Inventory", {})
			 inv["Weapons"]["hg_flashlight"] = true
			
			 ply:SetNetVar("Inventory", inv)
		 end,
	 },
	["traitor_zombie"] = {
		Name = "Zombie",
		Description = [[Can infect other players silently.
Infected players can be cured by a medic.
If all players are cured zombie will lose.
Instead of dying will be randomly transported to another infected player's body.
Has no weapons or any tools.
Despite being zombie, still bears appearance of a normal human.],
		Objective = "You're the zombie. Infect everyone to win. Avoid the medic.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		end,
	}, --]]
	--=//
}
--

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["soe"] = true,
	["gunfreezone"] = true,
}

MODE.Professions = {
	["medic"] = {
		Name = "Medic",
		Objective = "You are the Medic. Keep the innocents alive and treat injuries before the murderer can finish the job.",
		Loadout = {
			"weapon_bigbandage_sh",
			"weapon_defibrilator_homigrad",
			"weapon_medkit_sh",
			"weapon_painkillers",
			"weapon_needle",
			"weapon_bloodbag",
			"weapon_mannitol",
			"weapon_tourniquet",
		},
		SpawnFunction = function(ply)
			for _, weapon_class in ipairs(MODE.Professions.medic.Loadout) do
				local wep = ply:Give(weapon_class)

				if(weapon_class == "weapon_bloodbag" and IsValid(wep))then
					timer.Simple(0, function()
						if(IsValid(wep))then
							wep.modeValues = wep.modeValues or {}
							wep.modeValues[1] = 1
							wep.bloodtype = "o-"
						end
					end)
				end
			end
		end,
	},
	["lucky_guy"] = {
		Name = "Lucky Guy",
		Objective = "You are the Lucky Guy. Fortune is on your side, giving you extra health and stamina to outlast the murderer.",
		Loadout = {
			"weapon_screwdriver",
		},
		HealthMultiplier = 1.3,
		StaminaMultiplier = 1.2,
		SpawnFunction = function(ply)
			for _, weapon_class in ipairs(MODE.Professions.lucky_guy.Loadout) do
				ply:Give(weapon_class)
			end
		end,
	},
	["athlete"] = {
		Name = "Athlete",
		Objective = "You are the Athlete. Use your larger build, stamina and strength to outrun danger and win close fights.",
		ModelScale = 1.15,
		StaminaMultiplier = 2,
		StaminaExhaustMultiplier = 0.7,
		MeleeDamageMultiplier = 1.5,
		LegStrengthMultiplier = 1.5,
		JumpPowerMultiplier = 1.15,
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["thug"] = {
		Name = "Thug",
		Objective = "You are the Thug. Use your bat and fentanyl to dominate close fights and stay alive.",
		Loadout = {
			"weapon_bat",
			"weapon_fentanyl",
		},
		MaxPlayers = 2,
		SpawnFunction = function(ply)
			local delayed_bat_timer = "HMCD_ThugDelayedBat_" .. ply:EntIndex()

			timer.Remove(delayed_bat_timer)

			for _, weapon_class in ipairs(MODE.Professions.thug.Loadout) do
				if(weapon_class == "weapon_bat")then
					continue
				end

				ply:Give(weapon_class)
			end

			timer.Create(delayed_bat_timer, 3, 1, function()
				if(!IsValid(ply) or !ply:Alive() or ply.Profession != "thug" or ply:HasWeapon("weapon_bat"))then
					return
				end

				local active_weapon = ply:GetActiveWeapon()
				local active_class = IsValid(active_weapon) and active_weapon:GetClass() or nil

				if(!active_class or active_class == "weapon_bat")then
					active_class = ply:HasWeapon("weapon_fentanyl") and "weapon_fentanyl" or nil
				end

				local wep = ply:Give("weapon_bat")

				if(!IsValid(wep))then
					return
				end

				wep.bigNoDrop = true
				wep.NoHolster = false
				wep.weaponInvCategory = 0

				if(active_class and ply:HasWeapon(active_class))then
					timer.Simple(0, function()
						if(IsValid(ply) and ply:Alive() and ply:HasWeapon(active_class))then
							ply:SelectWeapon(active_class)
						end
					end)
				end
			end)
		end,
	},
	["huntsman"] = {
		Name = "Huntsman",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["engineer"] = {
		Name = "Engineer",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["cook"] = {
		Name = "Cook",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["builder"] = {
		Name = "Builder",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
}
--

--\\
--; The names of the variables are a bit messed up, I'll need to think about how to improve them
--; horror
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			["traitor_thief"] = true,
			["traitor_shadow"] = true,
			["traitor_assassin"] = true,
			["traitor_maniac"] = true, 	-- maniac killer
			["traitor_juggernaut"] = true,
			["traitor_cannibal"] = true,
			["traitor_terrorist"] = true,
			["traitor_lastmanstanding"] = true,
			["traitor_stalker"] = true,
		},
		Professions = {
			["medic"] = {
				Chance = 1,
			},
			["lucky_guy"] = {
				Chance = 1,
			},
			["athlete"] = {
				Chance = 1,
			},
			["thug"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
		},
	},	
	["gunfreezone"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			--["traitor_assassin"] = true,	there's no gunman so why have an assassin?
			--["traitor_maniac"] = true,	having a maniac in gfz is crazy
		},
		Professions = {
			["medic"] = {
				Chance = 1,
			},
			["lucky_guy"] = {
				Chance = 1,
			},
			["athlete"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
		},
	},
	["soe"] = {
		TraitorDefaultRole = "traitor_default_soe",
		Traitor = {
			["traitor_default_soe"] = true,
			["traitor_infiltrator_soe"] = true,
			["traitor_chemist_soe"] = true,
			["traitor_thief_soe"] = true,
			["traitor_shadow_soe"] = true,
			["traitor_assassin_soe"] = true,
			["traitor_maniac_soe"] = true,
			["traitor_juggernaut_soe"] = true,
			["traitor_cannibal_soe"] = true,
			["traitor_terrorist_soe"] = true,
			["traitor_lastmanstanding_soe"] = true,
			["traitor_stalker_soe"] = true,
			-- ["traitor_demoman_soe"] = true,
		},
		Professions = {
			["medic"] = {
				Chance = 1,
			},
			["lucky_guy"] = {
				Chance = 1,
			},
			["athlete"] = {
				Chance = 1,
			},
			["thug"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
		},
	},
}
--

MODE.Roles = {}
MODE.Roles.soe = {
	traitor = {
		name = "Traitor",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Innocent",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Innocent",
		color = Color(0,120,190)
	},
}

MODE.Roles.standard = {
	traitor = {
		objective = "You've been preparing for this for a long time. Kill everyone.",
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Bystander",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Bystander",
		color = Color(0,120,190)
	},
}

MODE.Roles.wildwest = {
	traitor = {
		objective = "You've been preparing for this for a long time. Kill everyone.",
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Sheriff",
		color = Color(159,85,0)
	},

	innocent = {
		name = "Bystander",
		color = Color(159,85,0)
	},
}

MODE.Roles.gunfreezone = {
	traitor = {
		name = "Murderer",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Bystander",
		color = Color(0,120,190)
	},

	innocent = {
		name = "Bystander",
		color = Color(0,120,190)
	},
}

MODE.Roles.supermario = {
	traitor = {
		objective = "You're the evil Mario! Jump around and take down everyone.",
		name = "Traitor Mario",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "You're the hero Mario! Use your jumping ability to stop the traitor.",
		name = "Hero Mario",
		color = Color(0,120,190)
	},

	innocent = {
		objective = "You're an innocent Mario, survive and avoid the traitor's traps!",
		name = "Innocent Mario",
		color = Color(0,190,0)
	},
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end

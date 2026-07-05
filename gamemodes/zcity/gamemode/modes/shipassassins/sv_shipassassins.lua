local MODE = MODE

util.AddNetworkString("ShipAssassins_Sync")
util.AddNetworkString("ShipAssassins_RoundStart")
util.AddNetworkString("ShipAssassins_RoundEnd")
util.AddNetworkString("ShipAssassins_Buy")
util.AddNetworkString("ShipAssassins_CashHint")
util.AddNetworkString("ShipAssassins_TimerSync")
util.AddNetworkString("ShipAssassins_ObjectiveSync")
util.AddNetworkString("ShipAssassins_ObjectiveComplete")
util.AddNetworkString("ShipAssassins_ShopSync")

local nextDisplaySyncThink = 0
local nextAssignmentEnsureThink = 0
local nextTimerSyncThink = 0

local function isActiveAssassin(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and ply:Team() ~= TEAM_SPECTATOR
end

local ILLEGAL_HARM_SLAY_THRESHOLD = 15
local contractWarningLines = {
	"[Assassin's Greed] Only attack your assigned target or the person hunting you.",
	"[Assassin's Greed] If two other players are fighting, leave them alone. Their fight is not your contract.",
	"[Assassin's Greed] Hurting anyone else for more than 15 harm will get you slain instantly.",
	"[Assassin's Greed] Each contract lasts 4 minutes. A successful contract gives you 30 seconds of grace before the next one starts.",
	"[Assassin's Greed] Personally killing your target pays $250. Press F3 to open the buy menu."
}

local sideObjectivePool = {
	{
		id = "search_containers",
		label = "Search 3 containers",
		goal = 3,
		reward = 150
	},
	{
		id = "search_dead_body",
		label = "Search a dead body",
		goal = 1,
		reward = 175
	},
	{
		id = "witness_death",
		label = "Witness someone die",
		goal = 1,
		reward = 125
	},
	{
		id = "bandage_someone",
		label = "Bandage someone",
		goal = 1,
		reward = 175
	}
}

local function buildShopItemMap()
	local map = {}

	for _, item in ipairs(MODE:GetAllShopItems()) do
		map[item.id] = item
	end

	return map
end

local shopItemMap = buildShopItemMap()

local function shufflePlayers(players)
	for i = #players, 2, -1 do
		local j = math.random(i)
		players[i], players[j] = players[j], players[i]
	end

	return players
end

local function samePlayerOrder(a, b)
	if #a ~= #b then return false end

	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

function MODE:GetAliveAssassins()
	local alive = {}

	for _, ply in player.Iterator() do
		if isActiveAssassin(ply) then
			alive[#alive + 1] = ply
		end
	end

	return alive
end

function MODE:GetOrder()
	self.saved.Order = self.saved.Order or {}

	return self.saved.Order
end

function MODE:GetKillCount(ply)
	self.saved.Kills = self.saved.Kills or {}

	return self.saved.Kills[ply] or 0
end

function MODE:GetIllegalHarmTable()
	self.saved.IllegalHarm = self.saved.IllegalHarm or {}

	return self.saved.IllegalHarm
end

function MODE:GetContractStateTable()
	self.saved.ContractState = self.saved.ContractState or {}

	return self.saved.ContractState
end

function MODE:GetSideObjectiveTable()
	self.saved.SideObjectives = self.saved.SideObjectives or {}

	return self.saved.SideObjectives
end

function MODE:GetMoney(ply)
	if not IsValid(ply) then return 0 end

	if SERVER then
		if isnumber(ply.ShipAssassinsMoney) then
			return ply.ShipAssassinsMoney
		end

		local fallback = ply:GetNWInt("ShipAssassins_Money", self.StartMoney or 0)
		ply.ShipAssassinsMoney = fallback
		return fallback
	end

	return ply:GetNWInt("ShipAssassins_Money", self.StartMoney or 0)
end

function MODE:SetMoney(ply, amount)
	if not IsValid(ply) then return end

	local normalized = math.max(math.floor(amount or 0), 0)
	ply.ShipAssassinsMoney = normalized
	ply:SetNWInt("ShipAssassins_Money", normalized)
end

function MODE:AddMoney(ply, amount)
	if not IsValid(ply) then return 0 end

	local newAmount = self:GetMoney(ply) + math.floor(amount or 0)
	self:SetMoney(ply, newAmount)
	return newAmount
end

function MODE:RollShopItems()
	self.saved.ShopItems = {}

	for _, category in ipairs(self.ShopCategories or {}) do
		local pool = self.ShopItemPools and self.ShopItemPools[category.id]
		if not istable(pool) or #pool == 0 then continue end

		local item = table.Copy(pool[math.random(#pool)])
		item.category = category.id
		item.categoryName = category.label
		self.saved.ShopItems[#self.saved.ShopItems + 1] = item
	end
end

function MODE:GetRolledShopItems()
	if not istable(self.saved.ShopItems) or #self.saved.ShopItems == 0 then
		self:RollShopItems()
	end

	return self.saved.ShopItems
end

function MODE:GetRolledShopItem(itemId)
	for _, item in ipairs(self:GetRolledShopItems()) do
		if item.id == itemId then
			return item
		end
	end
end

function MODE:SendShopItems(ply)
	if not IsValid(ply) then return end

	local items = self:GetRolledShopItems()
	net.Start("ShipAssassins_ShopSync")
		net.WriteUInt(math.Clamp(#items, 0, 255), 8)
		for _, item in ipairs(items) do
			net.WriteString(item.category or "")
			net.WriteString(item.categoryName or self:GetShopCategoryLabel(item.category))
			net.WriteString(item.id or "")
			net.WriteString(item.name or "")
			net.WriteUInt(math.Clamp(item.price or 0, 0, 65535), 16)
			net.WriteString(item.description or "")
		end
	net.Send(ply)
end

function MODE:SyncAllShopItems()
	for _, ply in player.Iterator() do
		self:SendShopItems(ply)
	end
end

function MODE:GetSideObjectiveState(ply)
	if not IsValid(ply) then return nil end

	return self:GetSideObjectiveTable()[ply]
end

function MODE:SendSideObjective(ply)
	if not IsValid(ply) then return end

	local objective = self:GetSideObjectiveState(ply)

	net.Start("ShipAssassins_ObjectiveSync")
		net.WriteBool(istable(objective))
		if istable(objective) then
			net.WriteString(objective.id or "")
			net.WriteString(objective.label or "")
			net.WriteUInt(math.Clamp(objective.progress or 0, 0, 255), 8)
			net.WriteUInt(math.Clamp(objective.goal or 1, 1, 255), 8)
			net.WriteUInt(math.Clamp(objective.reward or 0, 0, 65535), 16)
		end
	net.Send(ply)
end

function MODE:SyncAllSideObjectives()
	for _, ply in player.Iterator() do
		self:SendSideObjective(ply)
	end
end

function MODE:AssignSideObjective(ply, notify)
	if not isActiveAssassin(ply) then return end

	local objective = table.Copy(sideObjectivePool[math.random(#sideObjectivePool)])
	if ply.ShipAssassinsLastObjective and #sideObjectivePool > 1 then
		for _ = 1, 4 do
			if objective.id ~= ply.ShipAssassinsLastObjective then break end
			objective = table.Copy(sideObjectivePool[math.random(#sideObjectivePool)])
		end
	end

	objective.progress = 0
	objective.unique = {}
	ply.ShipAssassinsLastObjective = objective.id
	self:GetSideObjectiveTable()[ply] = objective
	self:SendSideObjective(ply)

	if notify then
		ply:ChatPrint("New side objective: " .. objective.label .. " | Reward: $" .. tostring(objective.reward or 0))
	end
end

function MODE:ClearSideObjective(ply)
	if IsValid(ply) then
		self:GetSideObjectiveTable()[ply] = nil
		self:SendSideObjective(ply)
		return
	end

	self.saved.SideObjectives = {}
end

function MODE:AdvanceSideObjective(ply, objectiveId, amount, uniqueKey)
	if not isActiveAssassin(ply) then return false end

	local objective = self:GetSideObjectiveState(ply)
	if not objective or objective.id ~= objectiveId then return false end

	if uniqueKey then
		objective.unique = objective.unique or {}
		if objective.unique[uniqueKey] then return false end
		objective.unique[uniqueKey] = true
	end

	objective.progress = math.Clamp((objective.progress or 0) + math.max(amount or 1, 1), 0, objective.goal or 1)

	if objective.progress < (objective.goal or 1) then
		self:SendSideObjective(ply)
		return true
	end

	local reward = math.max(math.floor(objective.reward or 0), 0)
	local label = objective.label or "Side objective"
	local newBalance = self:AddMoney(ply, reward)

	net.Start("ShipAssassins_ObjectiveComplete")
		net.WriteString(label)
		net.WriteUInt(math.Clamp(reward, 0, 65535), 16)
		net.WriteUInt(math.Clamp(newBalance, 0, 65535), 16)
	net.Send(ply)

	ply:ChatPrint("Side objective complete: " .. label .. " | Reward: $" .. tostring(reward) .. " | Balance: $" .. tostring(newBalance))
	self:AssignSideObjective(ply, true)
	return true
end

function MODE:IsLootContainer(ent)
	if not IsValid(ent) or ent:IsPlayer() or ent:IsRagdoll() then return false end
	if ent:GetClass() == "zbox_lootbox" then return true end
	if hg and hg.GetLootBoxData and hg.GetLootBoxData(ent) then return true end

	local inv = ent:GetNetVar("Inventory")
	if not istable(inv) then return false end

	local model = string.lower(ent:GetModel() or "")
	return string.find(model, "box", 1, true) ~= nil
		or string.find(model, "crate", 1, true) ~= nil
		or string.find(model, "locker", 1, true) ~= nil
end

function MODE:IsDeadBodyInventory(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return not ent:Alive() end
	if not ent:IsRagdoll() then return false end

	local owner = hg and hg.RagdollOwner and hg.RagdollOwner(ent) or ent:GetNWEntity("ply", NULL)
	if IsValid(owner) and owner:IsPlayer() then
		return not owner:Alive() or owner:GetNWEntity("RagdollDeath", NULL) == ent
	end

	return ent:GetNetVar("Inventory") ~= nil
end

function MODE:PlayerWitnessedDeath(witness, victim)
	if not isActiveAssassin(witness) or witness == victim then return false end
	if not IsValid(victim) then return false end

	local victimPos = victim:GetPos() + Vector(0, 0, 36)
	local eyePos = witness:EyePos()
	if eyePos:DistToSqr(victimPos) > 1200 * 1200 then return false end

	local trace = util.TraceLine({
		start = eyePos,
		endpos = victimPos,
		filter = {witness, victim},
		mask = MASK_VISIBLE
	})

	return not trace.Hit or trace.Fraction > 0.96
end

function MODE:CanUseShop(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and zb.ROUND_STATE == 1
		and CurrentRound and CurrentRound() == self
		and ply:Team() ~= TEAM_SPECTATOR
end

function MODE:GivePurchasedWeapon(ply, item)
	if not self:CanUseShop(ply) then return false, "Shop unavailable." end
	if not istable(item) or not item.class then return false, "Invalid item." end
	if ply:HasWeapon(item.class) then return false, "You already own that item." end

	local wep = ply:Give(item.class)
	if not IsValid(wep) then
		return false, "Item could not be given."
	end

	local ammoType = wep:GetPrimaryAmmoType()
	if ammoType and ammoType >= 0 and wep.Primary then
		local defaultClip = wep.Primary.DefaultClip or wep.Primary.ClipSize or 0
		if defaultClip > 0 then
			ply:GiveAmmo(math.max(defaultClip, 0), ammoType, true)
		end
	end

	return true
end

function MODE:StoreRealIdentity(ply)
	if not IsValid(ply) then return end

	ply.ShipAssassinsRealAppearance = ply.CurAppearance and table.Copy(ply.CurAppearance) or nil
	ply.ShipAssassinsRealPlayerName = ply:GetNWString("PlayerName", ply:Nick())
end

function MODE:ApplyCivilianIdentity(ply)
	if not IsValid(ply) then return end
	if not hg or not hg.Appearance or not hg.Appearance.GetRandomAppearance or not hg.Appearance.ForceApplyAppearance then return end

	local civilianAppearance = hg.Appearance.GetRandomAppearance()
	if not istable(civilianAppearance) then return end

	ply.ShipAssassinsCivilianAppearance = table.Copy(civilianAppearance)
	hg.Appearance.ForceApplyAppearance(ply, civilianAppearance)

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or nil
	if IsValid(character) then
		character.CurAppearance = table.Copy(civilianAppearance)
		character:SetNWString("PlayerName", civilianAppearance.AName or ply:GetNWString("PlayerName", ply:Nick()))
	end
end

function MODE:RestoreRealIdentity(ply)
	if not IsValid(ply) then return end

	local storedAppearance = ply.ShipAssassinsRealAppearance
	if istable(storedAppearance) and hg and hg.Appearance and hg.Appearance.ForceApplyAppearance then
		hg.Appearance.ForceApplyAppearance(ply, storedAppearance)
	else
		ApplyAppearance(ply, nil, nil, nil, true)
	end

	local restoredName = ply.ShipAssassinsRealPlayerName or ply:Nick()
	ply:SetNWString("PlayerName", restoredName)
	ply.ShipAssassinsCivilianAppearance = nil

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or nil
	if IsValid(character) then
		character:SetNWString("PlayerName", restoredName)
		if istable(storedAppearance) then
			character.CurAppearance = table.Copy(storedAppearance)
		end
	end
end

function MODE:SendContractWarnings(ply)
	if not IsValid(ply) then return end

	for _, line in ipairs(contractWarningLines) do
		ply:ChatPrint(line)
	end
end

function MODE:ResetIllegalHarm(ply)
	local tbl = self:GetIllegalHarmTable()

	if IsValid(ply) then
		tbl[ply] = nil
		return
	end

	self.saved.IllegalHarm = {}
end

function MODE:GetContractState(ply)
	if not IsValid(ply) then return nil end

	local tbl = self:GetContractStateTable()
	tbl[ply] = tbl[ply] or {
		deadline = 0,
		graceUntil = 0,
		warned = {}
	}

	return tbl[ply]
end

function MODE:ClearContractState(ply)
	local tbl = self:GetContractStateTable()

	if IsValid(ply) then
		tbl[ply] = nil
		return
	end

	self.saved.ContractState = {}
end

function MODE:SetContractGrace(ply, duration)
	local state = self:GetContractState(ply)
	if not state then return end

	state.deadline = 0
	state.graceUntil = CurTime() + math.max(duration or self.ContractGraceDuration or 30, 0)
	state.warned = {}
end

function MODE:StartContractTimer(ply, duration)
	local state = self:GetContractState(ply)
	if not state then return end

	state.deadline = CurTime() + math.max(duration or self.ContractDuration or 240, 0)
	state.graceUntil = 0
	state.warned = {}
end

function MODE:GetContractRemaining(ply)
	local state = self:GetContractState(ply)
	if not state or not state.deadline or state.deadline <= 0 then return 0 end

	return math.max(state.deadline - CurTime(), 0)
end

function MODE:GetGraceRemaining(ply)
	local state = self:GetContractState(ply)
	if not state or not state.graceUntil or state.graceUntil <= 0 then return 0 end

	return math.max(state.graceUntil - CurTime(), 0)
end

function MODE:GetVisibleTarget(ply)
	if not IsValid(ply) then return nil end
	if self:GetGraceRemaining(ply) > 0 then return nil end

	return IsValid(ply.ShipTarget) and ply.ShipTarget or nil
end

function MODE:ActivateContractForPlayer(ply, notify)
	if not isActiveAssassin(ply) then
		self:ClearContractState(ply)
		return
	end

	if not IsValid(ply.ShipTarget) then
		local state = self:GetContractState(ply)
		if state then
			state.deadline = 0
			state.graceUntil = 0
			state.warned = {}
		end
		return
	end

	self:StartContractTimer(ply, self.ContractDuration or 240)

	if notify then
		ply:ChatPrint("New contract active. Eliminate your target within 4:00 or die.")
	end
end

function MODE:AddKillCount(ply, amount)
	if not IsValid(ply) then return end

	self.saved.Kills = self.saved.Kills or {}
	self.saved.Kills[ply] = math.max((self.saved.Kills[ply] or 0) + (amount or 1), 0)
end

function MODE:ClearTargetState(ply)
	if not IsValid(ply) then return end

	ply.ShipTarget = nil
	ply.ShipHunter = nil
end

function MODE:IsProtectedVictim(attacker, victim)
	if not IsValid(attacker) or not IsValid(victim) then return false end

	return attacker.ShipTarget == victim or attacker.ShipHunter == victim
end

function MODE:HandleIllegalDamage(attacker, victim, harm)
	if zb.ROUND_STATE ~= 1 then return end
	if not IsValid(attacker) or not attacker:IsPlayer() or not attacker:Alive() then return end
	if not IsValid(victim) or not victim:IsPlayer() or victim == attacker then return end
	if attacker:Team() == TEAM_SPECTATOR or victim:Team() == TEAM_SPECTATOR then return end
	if not isnumber(harm) or harm <= 0 then return end
	if self:IsProtectedVictim(attacker, victim) then return end

	local illegalHarm = self:GetIllegalHarmTable()
	illegalHarm[attacker] = (illegalHarm[attacker] or 0) + harm

	if illegalHarm[attacker] <= ILLEGAL_HARM_SLAY_THRESHOLD then return end
	if attacker.ShipIllegalSlayQueued then return end

	attacker.ShipIllegalSlayQueued = true
	attacker:ChatPrint("You attacked too much outside your contract. You have been slain.")

	timer.Simple(0, function()
		if not IsValid(attacker) then return end

		attacker.ShipIllegalSlayQueued = nil
		illegalHarm[attacker] = nil

		if attacker:Alive() then
			attacker:Kill()
		end
	end)
end

function MODE:BuildAssignmentsFromOrder()
	local order = self:GetOrder()

	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			self:ClearTargetState(ply)
		end
	end

	if #order <= 1 then return end

	for index, ply in ipairs(order) do
		local target = order[index % #order + 1]
		local hunter = order[(index - 2) % #order + 1]

		ply.ShipTarget = target
		ply.ShipHunter = hunter
	end
end

function MODE:HasBrokenAssignments()
	local order = self:GetOrder()
	if #order <= 1 then return false end

	local seenPlayers = {}
	local seenTargets = {}
	local seenHunters = {}

	for index, ply in ipairs(order) do
		if not IsValid(ply) then
			return true
		end

		if seenPlayers[ply] then
			return true
		end

		seenPlayers[ply] = true

		if not IsValid(ply.ShipTarget) or not IsValid(ply.ShipHunter) then
			return true
		end

		if ply.ShipTarget == ply or ply.ShipHunter == ply then
			return true
		end

		local expectedTarget = order[index % #order + 1]
		local expectedHunter = order[(index - 2) % #order + 1]

		if ply.ShipTarget ~= expectedTarget or ply.ShipHunter ~= expectedHunter then
			return true
		end

		if seenTargets[ply.ShipTarget] or seenHunters[ply.ShipHunter] then
			return true
		end

		seenTargets[ply.ShipTarget] = true
		seenHunters[ply.ShipHunter] = true
	end

	return false
end

function MODE:EnsureAssignments()
	local alive = self:GetAliveAssassins()
	local order = self:GetOrder()
	local aliveSet = {}
	local newOrder = {}
	local seen = {}

	for _, ply in ipairs(alive) do
		aliveSet[ply] = true
	end

	for _, ply in ipairs(order) do
		if aliveSet[ply] and not seen[ply] then
			seen[ply] = true
			newOrder[#newOrder + 1] = ply
		end
	end

	for _, ply in ipairs(alive) do
		if not seen[ply] then
			seen[ply] = true
			newOrder[#newOrder + 1] = ply
		end
	end

	local orderChanged = not samePlayerOrder(order, newOrder)
	local assignmentsBroken = self:HasBrokenAssignments()

	if not orderChanged and not assignmentsBroken then
		return false
	end

	self.saved.Order = newOrder
	self:BuildAssignmentsFromOrder()

	for _, ply in ipairs(newOrder) do
		local state = self:GetContractState(ply)
		local hasTiming = state and ((state.deadline and state.deadline > 0) or (state.graceUntil and state.graceUntil > 0))

		if not hasTiming then
			self:ActivateContractForPlayer(ply, false)
		end
	end

	self:SyncAllPlayers()
	return true
end

function MODE:BuildTargetDossier(target)
	if not IsValid(target) or not target.CurAppearance then return nil end

	return {
		model = target:GetModel(),
		skin = target:GetSkin() or 0,
		playerColor = target.GetPlayerColor and target:GetPlayerColor() or target:GetNWVector("PlayerColor", Vector(1, 1, 1)),
		appearance = table.Copy(target.CurAppearance)
	}
end

function MODE:GetDisplaySubject(ply)
	if not IsValid(ply) then return nil end

	if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
		return ply
	end

	local spectTarget = ply.GetNWEntity and ply:GetNWEntity("spect", NULL) or nil
	spectTarget = hg and hg.RagdollOwner and hg.RagdollOwner(spectTarget) or spectTarget
	if IsValid(spectTarget) and spectTarget:IsPlayer() and spectTarget:Team() ~= TEAM_SPECTATOR then
		return spectTarget
	end

	local observerTarget = ply.GetObserverTarget and ply:GetObserverTarget() or nil
	observerTarget = hg and hg.RagdollOwner and hg.RagdollOwner(observerTarget) or observerTarget
	if IsValid(observerTarget) and observerTarget:IsPlayer() and observerTarget:Team() ~= TEAM_SPECTATOR then
		return observerTarget
	end

	return nil
end

function MODE:SyncPlayerState(ply)
	if not IsValid(ply) then return end

	local subject = self:GetDisplaySubject(ply)
	local target = self:GetVisibleTarget(subject)
	local dossier = self:BuildTargetDossier(target)
	local hunter = IsValid(subject) and subject.ShipHunter or nil
	local subjectName = IsValid(subject) and subject:Name() or ""
	local spectatingOther = IsValid(subject) and subject ~= ply
	local contractRemaining = math.ceil(self:GetContractRemaining(subject))
	local graceRemaining = math.ceil(self:GetGraceRemaining(subject))

	net.Start("ShipAssassins_Sync")
		net.WriteEntity(target or NULL)
		net.WriteEntity(IsValid(hunter) and hunter or NULL)
		net.WriteBool(dossier ~= nil)
		if dossier then
			net.WriteTable(dossier)
		end
		net.WriteUInt(self:GetKillCount(ply), 8)
		net.WriteUInt(#self:GetOrder(), 8)
		net.WriteUInt(math.Clamp(contractRemaining, 0, 65535), 16)
		net.WriteUInt(math.Clamp(graceRemaining, 0, 65535), 16)
		net.WriteBool(spectatingOther)
		net.WriteString(subjectName)
	net.Send(ply)
end

function MODE:SyncPlayerTimers(ply)
	if not IsValid(ply) then return end

	local subject = self:GetDisplaySubject(ply)
	local contractRemaining = math.ceil(self:GetContractRemaining(subject))
	local graceRemaining = math.ceil(self:GetGraceRemaining(subject))

	net.Start("ShipAssassins_TimerSync")
		net.WriteUInt(math.Clamp(contractRemaining, 0, 65535), 16)
		net.WriteUInt(math.Clamp(graceRemaining, 0, 65535), 16)
	net.Send(ply)
end

function MODE:SyncAllPlayers()
	for _, ply in player.Iterator() do
		self:SyncPlayerState(ply)
	end
end

function MODE:SyncAllPlayerTimers()
	for _, ply in player.Iterator() do
		self:SyncPlayerTimers(ply)
	end
end

function MODE:SendRoundStartInfo()
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		net.Start("ShipAssassins_RoundStart")
			net.WriteString(self.IntroTitle or self.PrintName)
			net.WriteString(self.IntroRoleName or "Assassin")
			net.WriteString(self.IntroObjective or "")
		net.Send(ply)

		zb.GiveRole(ply, self.IntroRoleName or "Assassin", self.AssassinRoleColor or color_white)
		self:SendContractWarnings(ply)
	end
end

function MODE:AssignTargets()
	local alive = self:GetAliveAssassins()

	self.saved.Order = shufflePlayers(alive)
	self:BuildAssignmentsFromOrder()

	for _, ply in ipairs(self:GetOrder()) do
		self:ActivateContractForPlayer(ply, false)
		self:AssignSideObjective(ply, false)
	end

	self:SendRoundStartInfo()
	self:SyncAllShopItems()
	self:SyncAllPlayers()
	self:SyncAllSideObjectives()
end

function MODE:RemoveFromOrder(victim)
	local order = self:GetOrder()

	for index = #order, 1, -1 do
		if order[index] == victim then
			table.remove(order, index)
			break
		end
	end
end

function MODE:ResolveKillerPlayer(attacker, inflictor)
	local function normalizeCandidate(candidate)
		candidate = hg and hg.RagdollOwner and hg.RagdollOwner(candidate) or candidate
		if IsValid(candidate) and candidate:IsPlayer() then
			return candidate
		end

		if IsValid(candidate) and candidate.GetOwner then
			local owner = candidate:GetOwner()
			owner = hg and hg.RagdollOwner and hg.RagdollOwner(owner) or owner
			if IsValid(owner) and owner:IsPlayer() then
				return owner
			end
		end

		return nil
	end

	return normalizeCandidate(attacker) or normalizeCandidate(inflictor)
end

function MODE:FindContractorForVictim(victim)
	if not IsValid(victim) then return nil end
	if IsValid(victim.ShipHunter) then return victim.ShipHunter end

	for _, ply in player.Iterator() do
		if ply.ShipTarget == victim then
			return ply
		end
	end

	return nil
end

function MODE:RewardTargetDeath(victim, attacker, inflictor)
	if not IsValid(victim) then return end

	attacker = self:ResolveKillerPlayer(attacker, inflictor)

	local contractor = self:FindContractorForVictim(victim)
	if not IsValid(contractor) then return end

	self:AddKillCount(contractor, 1)
	local newBalance = self:AddMoney(contractor, self.KillRewardMoney or 250)
	contractor:ChatPrint("Your target is dead. Contract credited.")
	contractor:ChatPrint("Contract reward: $" .. tostring(self.KillRewardMoney or 250) .. " | Balance: $" .. tostring(newBalance))
	net.Start("ShipAssassins_CashHint")
		net.WriteUInt(math.Clamp(self.KillRewardMoney or 250, 0, 65535), 16)
	net.Send(contractor)
	if contractor ~= victim and contractor:Alive() then
		self:SetContractGrace(contractor, self.ContractGraceDuration or 30)
		contractor:ChatPrint("Lay low. Your next contract goes live in 30 seconds.")
	end

	if attacker == contractor then
		if contractor.organism and contractor.organism.stamina then
			local stamina = contractor.organism.stamina
			local maxStamina = stamina.max or stamina.range or stamina[1]
			if maxStamina then
				stamina[1] = math.min((stamina[1] or maxStamina) + 30, maxStamina)
			end
		end
	end
end

function MODE:OnAssassinRemoved(victim, attacker)
	self:RemoveFromOrder(victim)
	self:ClearTargetState(victim)
	self:ClearContractState(victim)
	self:ClearSideObjective(victim)

	self:BuildAssignmentsFromOrder()
	self:SyncAllPlayers()
end

function MODE:SpawnPlayers()
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetupTeam(0)
		ApplyAppearance(ply, nil, nil, nil, true)
		self:StoreRealIdentity(ply)
		ply:Spawn()
		ply:GetRandomSpawn()

		if not ply:Alive() then continue end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:StripWeapons()
		ply:RemoveAllAmmo()

		local hands = ply:Give("weapon_hands_sh")

		local inv = ply:GetNetVar("Inventory") or {}
		inv.Weapons = inv.Weapons or {}
		inv.Weapons["hg_flashlight"] = true
		ply:SetNetVar("Inventory", inv)

		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end

		self:ApplyCivilianIdentity(ply)
		ply:SetNetVar("flashlight", false)
		self:SetMoney(ply, self.StartMoney or 0)
		self:ResetIllegalHarm(ply)
		self:ClearContractState(ply)
		ply.ShipIllegalSlayQueued = nil

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end

			ply.noSound = false
			ply:SetSuppressPickupNotices(false)
		end)
	end

	self:AssignTargets()
end

function MODE:Intermission()
	game.CleanUpMap()

	self.saved.Order = {}
	self.saved.Kills = {}
	self.saved.IllegalHarm = {}
	self.saved.ContractState = {}
	self.saved.SideObjectives = {}
	self.saved.Winner = nil

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:KillSilent()
		ply:SetupTeam(0)

		if ply.organism then
			ply.organism.recoilmul = DefaultSkillIssue
		end

		self:RestoreRealIdentity(ply)
		ply.ShipIllegalSlayQueued = nil
		self:ClearTargetState(ply)
		self:ClearSideObjective(ply)
	end
end

function MODE:RoundStart()
	self.saved.Winner = nil
	self.saved.Kills = {}
	self.saved.Order = {}
	self.saved.IllegalHarm = {}
	self.saved.ContractState = {}
	self.saved.DisplaySync = {}
	self.saved.TimerSync = {}
	self.saved.SideObjectives = {}
	self.saved.ShopItems = {}
	self:RollShopItems()

	self:SpawnPlayers()
end

function MODE:GiveEquipment()
end

function MODE:CanSpawn()
end

function MODE:ShouldRoundEnd()
	local alive = self:GetAliveAssassins()

	if #alive <= 1 then
		self.saved.Winner = alive[1]
		return true
	end

	return false
end

function MODE:EndRound()
	local winner = self.saved.Winner
	local alive = self:GetAliveAssassins()

	if not IsValid(winner) and #alive == 1 then
		winner = alive[1]
	end

	if IsValid(winner) then
		local kills = self:GetKillCount(winner)
		PrintMessage(HUD_PRINTTALK, winner:Name() .. " won Assassin's Greed with " .. kills .. " kill" .. (kills == 1 and "" or "s") .. ".")
	else
		PrintMessage(HUD_PRINTTALK, "Assassin's Greed ended with no surviving assassin.")
	end

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		net.Start("ShipAssassins_RoundEnd")
			net.WriteEntity(IsValid(winner) and winner or NULL)
			net.WriteUInt(self:GetKillCount(ply), 8)
		net.Send(ply)

		self:SetMoney(ply, self.StartMoney or 0)
		self:ClearTargetState(ply)
		self:ClearContractState(ply)
		self:ClearSideObjective(ply)
	end
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	if zb.ROUND_STATE ~= 1 then return end
	if not IsValid(victim) or victim:Team() == TEAM_SPECTATOR then return end

	self:RewardTargetDeath(victim, attacker, inflictor)

	for _, witness in player.Iterator() do
		if self:PlayerWitnessedDeath(witness, victim) then
			self:AdvanceSideObjective(witness, "witness_death")
		end
	end

	self:RestoreRealIdentity(victim)
	self:ResetIllegalHarm(victim)
	self:ClearContractState(victim)
	self:ClearSideObjective(victim)
	victim.ShipIllegalSlayQueued = nil

	timer.Simple(0, function()
		if not MODE or not MODE.saved then return end
		MODE:OnAssassinRemoved(victim, attacker)
	end)
end

function MODE:PlayerDisconnected(ply)
	if zb.ROUND_STATE ~= 1 then return end
	if not IsValid(ply) then return end

	self:RestoreRealIdentity(ply)
	self:ResetIllegalHarm(ply)
	self:ClearContractState(ply)
	self:ClearSideObjective(ply)

	self:OnAssassinRemoved(ply, NULL)
end

function MODE:RoundThink()
	self.saved.DisplaySync = self.saved.DisplaySync or {}
end

hook.Add("Think", "ShipAssassins_ContractTimers", function()
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end

	local now = CurTime()
	local changed = false

	for _, ply in ipairs(round:GetOrder()) do
		if not isActiveAssassin(ply) then continue end

		local state = round:GetContractState(ply)
		if not state then continue end

		if state.graceUntil and state.graceUntil > 0 then
			if state.graceUntil <= now then
				round:ActivateContractForPlayer(ply, true)
				changed = true
			end
		elseif state.deadline and state.deadline > 0 then
			local remaining = math.max(state.deadline - now, 0)

			for _, warnAt in ipairs(round.ContractWarningThresholds or {}) do
				if remaining <= warnAt and not state.warned[warnAt] then
					state.warned[warnAt] = true
					ply:ChatPrint("Contract timer: " .. tostring(warnAt) .. " seconds remaining.")
				end
			end

			if remaining <= 0 then
				state.deadline = 0
				state.warned = {}
				ply:ChatPrint("You failed to eliminate your target in time.")
				if ply:Alive() then
					ply:Kill()
				end
				changed = true
			end
		elseif IsValid(ply.ShipTarget) then
			round:ActivateContractForPlayer(ply, false)
			changed = true
		end
	end

	if changed then
		round:SyncAllPlayers()
	end
end)

hook.Add("Think", "ShipAssassins_AssignmentIntegrity", function()
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end
	if nextAssignmentEnsureThink > CurTime() then return end

	nextAssignmentEnsureThink = CurTime() + 0.25
	round:EnsureAssignments()
end)

hook.Add("Think", "ShipAssassins_DisplaySync", function()
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end
	if nextDisplaySyncThink > CurTime() then return end

	nextDisplaySyncThink = CurTime() + 0.1
	round.saved.DisplaySync = round.saved.DisplaySync or {}

	for _, ply in player.Iterator() do
		local subject = round:GetDisplaySubject(ply)
		local observedTarget = round:GetVisibleTarget(subject)
		local signature = table.concat({
			IsValid(subject) and subject:EntIndex() or 0,
			IsValid(observedTarget) and observedTarget:EntIndex() or 0,
			ply:Alive() and 1 or 0,
			#round:GetOrder(),
			IsValid(subject) and subject:Name() or ""
		}, ":")

		if round.saved.DisplaySync[ply] ~= signature then
			round.saved.DisplaySync[ply] = signature
			round:SyncPlayerState(ply)
		end
	end
end)

hook.Add("Think", "ShipAssassins_TimerSync", function()
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end
	if nextTimerSyncThink > CurTime() then return end

	nextTimerSyncThink = CurTime() + 1
	round.saved.TimerSync = round.saved.TimerSync or {}

	for _, ply in player.Iterator() do
		local subject = round:GetDisplaySubject(ply)
		local contractRemaining = math.ceil(round:GetContractRemaining(subject))
		local graceRemaining = math.ceil(round:GetGraceRemaining(subject))
		local signature = table.concat({
			IsValid(subject) and subject:EntIndex() or 0,
			contractRemaining,
			graceRemaining
		}, ":")

		if round.saved.TimerSync[ply] ~= signature then
			round.saved.TimerSync[ply] = signature
			round:SyncPlayerTimers(ply)
		end
	end
end)

hook.Add("ZB_InventoryOpened", "ShipAssassins_SideObjectives_Inventory", function(ply, ent)
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end
	if not isActiveAssassin(ply) or not IsValid(ent) then return end

	if round:IsLootContainer(ent) then
		round:AdvanceSideObjective(ply, "search_containers", 1, "container:" .. ent:EntIndex())
	elseif round:IsDeadBodyInventory(ent) then
		round:AdvanceSideObjective(ply, "search_dead_body", 1, "body:" .. ent:EntIndex())
	end
end)

hook.Add("ZB_PlayerBandaged", "ShipAssassins_SideObjectives_Bandage", function(healer, patient)
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end
	if not isActiveAssassin(healer) then return end

	patient = hg and hg.RagdollOwner and hg.RagdollOwner(patient) or patient
	if not IsValid(patient) or patient == healer then return end

	round:AdvanceSideObjective(healer, "bandage_someone")
end)

hook.Add("HomigradDamage", "ShipAssassins_IllegalDamageRaw", function(victim, dmgInfo, hitgroup, ent, harm)
	local rnd = CurrentRound and CurrentRound()
	if not rnd or rnd.name ~= MODE.name then return end

	local attacker = dmgInfo and dmgInfo.GetAttacker and dmgInfo:GetAttacker() or nil
	local inflictor = dmgInfo and dmgInfo.GetInflictor and dmgInfo:GetInflictor() or ent
	attacker = MODE:ResolveKillerPlayer(attacker, inflictor)
	victim = hg and hg.RagdollOwner and hg.RagdollOwner(victim) or victim
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if not IsValid(victim) or not victim:IsPlayer() then return end

	MODE:HandleIllegalDamage(attacker, victim, harm)
end)

net.Receive("ShipAssassins_Buy", function(_, ply)
	local round = CurrentRound and CurrentRound()
	if round ~= MODE then return end
	if not round:CanUseShop(ply) then return end

	local itemId = net.ReadString()
	local item = round:GetRolledShopItem(itemId)
	if not item or not shopItemMap[itemId] then
		ply:ChatPrint("That black market item is not available this round.")
		return
	end

	local currentMoney = round:GetMoney(ply)
	if currentMoney < item.price then
		ply:ChatPrint("Not enough money for " .. item.name .. ".")
		return
	end

	local ok, err = round:GivePurchasedWeapon(ply, item)
	if not ok then
		if err then
			ply:ChatPrint(err)
		end
		return
	end

	round:SetMoney(ply, currentMoney - item.price)
	ply:ChatPrint("Purchased " .. item.name .. " for $" .. item.price .. ".")
end)

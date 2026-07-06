local homicideMode = zb and zb.modes and zb.modes["hmcd"]

MODE.name = "assassinsgreed"
MODE.PrintName = "Assassin's Greed"
MODE.Description = "Every player is both hunter and hunted. Eliminate your assigned targets to survive to the end."

MODE.Chance = 0.09
MODE.ROUND_TIME = 900
MODE.start_time = 1
MODE.end_time = 7

MODE.randomSpawns = true
MODE.shouldfreeze = true
MODE.PoliceAllowed = false
MODE.OverrideSpawn = true
MODE.LootSpawn = true
MODE.LootOnTime = true
MODE.LootDivTime = 500
MODE.GuiltDisabled = true
MODE.ContractDuration = 240
MODE.ContractGraceDuration = 30
MODE.ContractWarningThresholds = {60, 30, 10}

MODE.IntroTitle = "Assassin's Greed"
MODE.IntroRoleName = "Assassin"
MODE.IntroObjective = "Only attack your target or your hunter. Other fights are not your concern, and interfering gets you slain. Each contract lasts 4 minutes, and a successful contract gives you 30 seconds of grace before the next one begins. Contract kills pay $250. Press F3 to buy equipment."
MODE.IntroColor = Color(193, 118, 36)

MODE.AssassinRoleColor = Color(193, 118, 36)
MODE.TargetColor = Color(205, 72, 72)
MODE.HunterColor = Color(90, 145, 215)
MODE.KillRewardMoney = 250
MODE.StartMoney = 0

MODE.ShopCategories = {
	{id = "melee_blunt", label = "Melee Blunt"},
	{id = "slash_stab", label = "Slash / Stab"},
	{id = "pistol", label = "Pistol"},
	{id = "rifle_sniper", label = "Rifle / Sniper"}
}

MODE.ShopItemPools = {
	melee_blunt = {
		{id = "bat", name = "Bat", class = "weapon_bat", price = 250, description = "Reliable blunt pressure for close contracts."},
		{id = "metalbat", name = "Metal Bat", class = "weapon_batmetal", price = 325, description = "Heavier blunt force with better stopping power."},
		{id = "leadpipe", name = "Lead Pipe", class = "weapon_leadpipe", price = 175, description = "Cheap street weapon for fast ambushes."},
		{id = "hammer", name = "Hammer", class = "weapon_hammer", price = 225, description = "Compact tool for brutal close-quarters work."}
	},
	slash_stab = {
		{id = "pocketknife", name = "Pocket Knife", class = "weapon_pocketknife", price = 100, description = "Silent backup blade for desperate contracts."},
		{id = "bayonet", name = "Bayonet", class = "weapon_bayonet", price = 300, description = "Longer stabbing weapon for committed attacks."}
	},
	pistol = {
		{id = "makarov", name = "Makarov Pistol", class = "weapon_makarov", price = 500, description = "Compact pistol with spare ammo for clean exits."},
		{id = "glock17", name = "Glock 17", class = "weapon_glock17", price = 550, description = "Reliable sidearm with quick follow-up shots."},
		{id = "usp", name = "HK USP", class = "weapon_hk_usp", price = 650, description = "Accurate pistol for controlled contracts."},
		{id = "m45", name = "M45", class = "weapon_m45", price = 700, description = "Heavy pistol with strong close-range impact."},
		{id = "deagle", name = "Desert Eagle", class = "weapon_deagle", price = 900, description = "Expensive hand cannon for decisive shots."}
	},
	rifle_sniper = {
		{id = "ak74u", name = "AK-74U", class = "weapon_ak74u", price = 850, description = "Compact rifle for aggressive contracts."},
		{id = "ar15", name = "AR-15", class = "weapon_ar15", price = 950, description = "Versatile rifle for mid-range pressure."},
		{id = "hk416", name = "HK416", class = "weapon_hk416", price = 1200, description = "Premium rifle with high contract control."},
		{id = "m98b", name = "M98B", class = "weapon_m98b", price = 1000, description = "Powerful marksman rifle for long contracts."}
	}
}

function MODE:GetShopCategoryLabel(categoryId)
	for _, category in ipairs(self.ShopCategories or {}) do
		if category.id == categoryId then
			return category.label
		end
	end

	return categoryId or "Gear"
end

function MODE:GetAllShopItems()
	local items = {}

	for _, category in ipairs(self.ShopCategories or {}) do
		local pool = self.ShopItemPools and self.ShopItemPools[category.id]
		if not istable(pool) then continue end

		for _, item in ipairs(pool) do
			local copy = table.Copy(item)
			copy.category = category.id
			copy.categoryName = category.label
			items[#items + 1] = copy
		end
	end

	return items
end

function MODE:GetDefaultShopItems()
	local items = {}

	for _, category in ipairs(self.ShopCategories or {}) do
		local pool = self.ShopItemPools and self.ShopItemPools[category.id]
		local item = istable(pool) and pool[1]
		if not item then continue end

		local copy = table.Copy(item)
		copy.category = category.id
		copy.categoryName = category.label
		items[#items + 1] = copy
	end

	return items
end

MODE.LootTable = table.Copy(homicideMode and homicideMode.LootTable or {})
MODE.LootTableStandard = table.Copy(homicideMode and homicideMode.LootTableStandard or {})

function MODE:CanLaunch()
	return true
end

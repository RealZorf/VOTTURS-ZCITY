zb = zb or {}
zb.TDMShop = zb.TDMShop or {}

local Shop = zb.TDMShop

Shop.AttachmentPrice = 50

function Shop.IsAmmoPurchase(category, item)
	if category == "Ammo" then return true end
	if not item then return false end
	if item.Type == "Ammo" then return true end

	local class = item.ItemClass
	return isstring(class) and string.StartWith(class, "ent_ammo_")
end

function Shop.IsWeaponPurchase(item)
	if not item then return false end
	if item.Type == "Weapon" then return true end

	local class = item.ItemClass
	return isstring(class) and string.StartWith(class, "weapon_")
end

function Shop.IsConsumableItem(item, category)
	if not item then return false end
	if category == "Medical" or category == "Ammo" then return true end
	if Shop.IsAmmoPurchase(category, item) then return true end

	local class = item.ItemClass or ""

	return string.find(class, "bandage")
		or string.find(class, "painkill")
		or string.find(class, "morphine")
		or string.find(class, "adrenaline")
		or string.find(class, "naloxone")
		or string.find(class, "mannitol")
		or string.find(class, "betablock")
		or string.find(class, "tourniquet")
		or string.find(class, "needle")
		or string.find(class, "medkit")
		or string.find(class, "bloodbag")
		or string.find(class, "fentanyl")
end

function Shop.ClearStalePurchaseIfMissing(ply, itemClass)
	if not IsValid(ply) or not itemClass then return end

	local purchaseId = Shop.FindPurchaseByClass(ply, itemClass)
	if not purchaseId then return end

	if not ply:HasWeapon(itemClass) then
		Shop.RemovePurchase(ply, purchaseId)
	end
end

function Shop.IsWeaponClass(itemClass)
	return isstring(itemClass) and string.StartWith(itemClass, "weapon_")
end

function Shop.GetWeaponPrintName(itemClass)
	local wep = weapons.GetStored(itemClass)

	return (wep and wep.PrintName) or itemClass or "Weapon"
end

function Shop.GetWeaponInvLimit(category)
	if not category then return 1 end

	if hg and hg.weaponInv and hg.weaponInv.invWeapon and hg.weaponInv.invWeapon[category] then
		return hg.weaponInv.invWeapon[category].limit or 1
	end

	if category == 2 then return 2 end

	return 1
end

function Shop.GetWeaponInvCategory(itemClass)
	if not Shop.IsWeaponClass(itemClass) then return nil end

	local wepData = weapons.GetStored(itemClass)

	return wepData and wepData.weaponInvCategory or nil
end

function Shop.GetWeaponsInSlotCategory(ply, category)
	local list = {}

	if not IsValid(ply) or not category then return list end

	for _, wep in ipairs(ply:GetWeapons()) do
		if not IsValid(wep) then continue end

		local data = weapons.GetStored(wep:GetClass())
		if data and data.weaponInvCategory == category then
			list[#list + 1] = wep:GetClass()
		end
	end

	return list
end

-- Held weapons + TDM purchase records (covers holstered / off-hand guns the buy menu still owns).
function Shop.GetOccupiedWeaponClassesInInvCategory(ply, invCategory, excludeClass)
	local seen = {}
	local list = {}

	if not IsValid(ply) or not invCategory then return list end

	local function addWeaponClass(class)
		if not class or class == excludeClass or seen[class] then return end

		local data = weapons.GetStored(class)
		if not data or data.weaponInvCategory != invCategory then return end

		seen[class] = true
		list[#list + 1] = class
	end

	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) then
			addWeaponClass(wep:GetClass())
		end
	end

	if ply.TDM_Purchases then
		for _, purchase in pairs(ply.TDM_Purchases) do
			if purchase.purchaseType != "attachment" and Shop.IsWeaponClass(purchase.itemClass) then
				addWeaponClass(purchase.itemClass)
			end
		end
	end

	return list
end

function Shop.GetWeaponSlotConflict(ply, itemClass)
	if not IsValid(ply) or not Shop.IsWeaponClass(itemClass) then return false end
	if ply:HasWeapon(itemClass) then return false end

	local category = Shop.GetWeaponInvCategory(itemClass)
	if not category then return false end

	local occupied = Shop.GetOccupiedWeaponClassesInInvCategory(ply, category, itemClass)
	local limit = Shop.GetWeaponInvLimit(category)

	if #occupied < limit then return false end

	return true, occupied[1], category
end

function Shop.GetWeaponReplacePromptInfo(ply, item, displayName, category)
	if not IsValid(ply) or not item then return false end

	displayName = displayName or item.ItemClass or "Item"
	local price = item.Price or 0
	local class = item.ItemClass

	if Shop.IsWeaponPurchase(item) and class then
		if ply:HasWeapon(class) then
			return true, "same_weapon", class, "Replace weapon?", string.format(
				"Replace %s?\n$%s — refunds your current gun.",
				displayName,
				price
			)
		end

		local slotConflict, replaceClass = Shop.GetWeaponSlotConflict(ply, class)
		if slotConflict and replaceClass then
			local oldName = Shop.GetWeaponPrintName(replaceClass)

			return true, "slot", replaceClass, "Slot occupied", string.format(
				"Refund %s and buy %s?\n$%s",
				oldName,
				displayName,
				price
			)
		end

		return false
	end

	local owns, kind = Shop.PlayerOwnsItem(ply, item, nil)
	if owns then
		if kind == "weapon" then
			return true, "same_weapon", class, "Replace weapon?", string.format(
				"Replace %s?\n$%s — refunds your current gun.",
				displayName,
				price
			)
		end

		if kind == "armor" or not Shop.IsConsumableItem(item, category) then
			return true, "item", class, "Replace item?", string.format(
				"Replace %s?\n$%s",
				displayName,
				price
			)
		end
	end

	return false
end

function Shop.RefundAndStripWeapon(ply, weaponClass)
	if not IsValid(ply) or not weaponClass then return 0 end

	local refundAmount = 0
	local purchaseId, purchase = Shop.FindPurchaseByClass(ply, weaponClass)

	if purchase then
		refundAmount = purchase.price or 0
		Shop.RemovePurchase(ply, purchaseId)
	end

	if ply:HasWeapon(weaponClass) then
		ply:StripWeapon(weaponClass)
	end

	if refundAmount > 0 then
		ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) + refundAmount)
	end

	return refundAmount
end

function Shop.HandleWeaponSlotReplace(ply, itemClass)
	local conflict, replaceClass = Shop.GetWeaponSlotConflict(ply, itemClass)
	if not conflict or not replaceClass then return 0 end

	return Shop.RefundAndStripWeapon(ply, replaceClass)
end

function Shop.GetArmorEquipmentName(itemClass)
	if itemClass == "hg_flashlight" then return "flashlight" end
	if not isstring(itemClass) then return nil end

	return string.Replace(itemClass, "ent_armor_", "")
end

function Shop.GetArmorPlacement(equipmentName)
	if not equipmentName or not hg or not hg.armor then return nil end

	for placement, tbl in pairs(hg.armor) do
		if tbl[equipmentName] then
			return placement
		end
	end
end

function Shop.GetPlayerArmors(ply)
	if not IsValid(ply) then return {} end

	return ply.armors or ply:GetNetVar("Armor", {}) or {}
end

function Shop.PlayerOwnsItem(ply, item, category)
	if not IsValid(ply) or not item then return false end
	if Shop.IsAmmoPurchase(category, item) then return false end

	local class = item.ItemClass
	if not class then return false end

	if item.Type == "Armor" or string.StartWith(class, "ent_armor_") or class == "hg_flashlight" then
		local eqName = Shop.GetArmorEquipmentName(class)
		local placement = Shop.GetArmorPlacement(eqName)
		local armors = Shop.GetPlayerArmors(ply)

		if placement and armors[placement] then
			return true, "armor"
		end

		for _, equipped in pairs(armors) do
			if equipped == eqName then
				return true, "armor"
			end
		end

		return false
	end

	if Shop.IsWeaponPurchase(item) then
		if ply:HasWeapon(class) then
			return true, "weapon"
		end

		return false
	end

	if ply:HasWeapon(class) then
		return true, "item"
	end

	return false
end

function Shop.SyncPurchases(ply)
	if not IsValid(ply) then return end
	ply:SetNetVar("TDM_Purchases", ply.TDM_Purchases or {})
end

function Shop.ClearPurchases(ply)
	if not IsValid(ply) then return end
	ply.TDM_Purchases = {}
	Shop.SyncPurchases(ply)
end

function Shop.FindPurchaseByClass(ply, itemClass)
	if not ply.TDM_Purchases then return nil end

	for id, purchase in pairs(ply.TDM_Purchases) do
		if purchase.itemClass == itemClass and purchase.purchaseType != "attachment" then
			return id, purchase
		end
	end
end

function Shop.GetAttachmentPlacement(attName)
	if not attName or not hg or not hg.attachments then return nil end

	for _, tbl in pairs(hg.attachments) do
		if tbl[attName] and tbl[attName][1] then
			return tbl[attName][1]
		end
	end
end

function Shop.GetAttachmentDisplayName(attName)
	if hg and hg.attachmentslaunguage and hg.attachmentslaunguage[attName] then
		return hg.attachmentslaunguage[attName]
	end

	return attName
end

function Shop.GetWeaponAttachments(wep)
	if not IsValid(wep) then return nil end

	return wep.attachments or wep:GetNetVar("attachments")
end

function Shop.WeaponHasAttachmentNamed(wep, attName)
	local attachments = Shop.GetWeaponAttachments(wep)
	if not attachments then return false end

	for _, att in pairs(attachments) do
		if istable(att) and att[1] == attName then
			return true
		end
	end

	return false
end

function Shop.WeaponGetAttachmentOnPlacement(wep, placement)
	local attachments = Shop.GetWeaponAttachments(wep)
	if not attachments or not attachments[placement] then return nil end

	local slot = attachments[placement]
	if not istable(slot) or table.IsEmpty(slot) or slot[1] == "empty" then return nil end

	return slot[1]
end

function Shop.GetAttachmentConflict(ply, weaponClass, attName)
	if not IsValid(ply) or not weaponClass or not attName then return false end

	local wep = ply:GetWeapon(weaponClass)
	if not IsValid(wep) then return false end

	if Shop.WeaponHasAttachmentNamed(wep, attName) then
		return true, "same", attName
	end

	local placement = Shop.GetAttachmentPlacement(attName)
	if not placement then return false end

	local existing = Shop.WeaponGetAttachmentOnPlacement(wep, placement)
	if existing then
		return true, "slot", existing
	end

	return false
end

function Shop.RemoveWeaponAttachment(wep, attName)
	if not IsValid(wep) or not wep.attachments or not attName then return end

	local placement = Shop.GetAttachmentPlacement(attName)
	if not placement then return end

	local emptyIndex
	if wep.availableAttachments and wep.availableAttachments[placement] then
		for n, atta in pairs(wep.availableAttachments[placement]) do
			if istable(atta) and atta[1] == "empty" then
				emptyIndex = n
				break
			end
		end
	end

	wep.attachments[placement] = emptyIndex and wep.availableAttachments[placement][emptyIndex] or {}

	if wep.SyncAtts then
		wep:SyncAtts()
	end
end

function Shop.FindAttachmentPurchase(ply, weaponClass, placement)
	if not ply.TDM_Purchases then return nil end

	for id, purchase in pairs(ply.TDM_Purchases) do
		if purchase.purchaseType == "attachment"
			and purchase.weaponClass == weaponClass
			and purchase.placement == placement then
			return id, purchase
		end
	end
end

function Shop.AddAttachmentPurchase(ply, category, index, weaponClass, attName, price)
	ply.TDM_Purchases = ply.TDM_Purchases or {}

	local placement = Shop.GetAttachmentPlacement(attName)
	local existingId = Shop.FindAttachmentPurchase(ply, weaponClass, placement)
	if existingId then
		ply.TDM_Purchases[existingId] = nil
	end

	local id = 1
	while ply.TDM_Purchases[id] do
		id = id + 1
	end

	local displayName = Shop.GetAttachmentDisplayName(attName)

	ply.TDM_Purchases[id] = {
		id = id,
		purchaseType = "attachment",
		category = category,
		index = index,
		itemClass = weaponClass,
		weaponClass = weaponClass,
		attachment = attName,
		placement = placement,
		price = price or Shop.AttachmentPrice,
		displayName = displayName .. " (" .. (index or weaponClass) .. ")",
	}

	Shop.SyncPurchases(ply)

	return id
end

function Shop.AddPurchase(ply, category, index, item)
	ply.TDM_Purchases = ply.TDM_Purchases or {}

	local id = 1
	while ply.TDM_Purchases[id] do
		id = id + 1
	end

	ply.TDM_Purchases[id] = {
		id = id,
		purchaseType = "item",
		category = category,
		index = index,
		itemClass = item.ItemClass,
		price = item.Price,
		itemType = item.Type,
		displayName = index,
	}

	Shop.SyncPurchases(ply)

	return id
end

function Shop.RemovePurchase(ply, purchaseId)
	if not ply.TDM_Purchases or not ply.TDM_Purchases[purchaseId] then return end
	ply.TDM_Purchases[purchaseId] = nil
	Shop.SyncPurchases(ply)
end

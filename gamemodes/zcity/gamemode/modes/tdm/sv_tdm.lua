local MODE = MODE

if not zb.TDMShop then
	include("zcity/gamemode/modes/tdm/sh_tdm_buy.lua")
end

MODE.name = "tdm"
MODE.BuyTime = 40
MODE.StartMoney = 6500
MODE.start_time = 20
MODE.buymenu = true

MODE.ROUND_TIME = 240

MODE.Chance = 0.04

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

function MODE:CanLaunch()
	return true
	--[[local points = zb.GetMapPoints( "HMCD_TDM_T" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_CT" )
    return (#points > 0) and (#points2 > 0)]] -- can work without them
end

util.AddNetworkString("tdm_start")
function MODE:Intermission()
	game.CleanUpMap()

	for i, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
		
		ply:SetNWInt( "TDM_Money", self.StartMoney )
		if zb.TDMShop then
			zb.TDMShop.ClearPurchases(ply)
		else
			ply.TDM_Purchases = {}
			ply:SetNetVar("TDM_Purchases", {})
		end
	end

	net.Start("tdm_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	return endround
end

function MODE:RoundStart()
	for k,ply in player.Iterator() do
		ply:Freeze(false)
	end
end

local tblweps = {
	[0] = {
		"weapon_akm",
	},
	[1] = {
		"weapon_m4a1",
	},
}

local tblatts = {
	[0] = {
		{""},
	},
	[1] = {
		{"holo14","laser2","grip3"},
	},
}

local tblarmors = {
	[0] = {
		{"vest4","helmet1"},
	},
	[1] = {
		{"vest4","helmet1"},
	},
}

-- local giveweapons = CreateConVar("zb_tdm_giveweapon","1",FCVAR_LUA_SERVER,"TDMSPAWNS",0,1)

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
	timer.Simple(0.1,function()
		local mrand = math.random(#tblweps[0])

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			
			local inv = ply:GetNetVar("Inventory")
			inv["Weapons"]["hg_sling"] = true
			ply:SetNetVar("Inventory",inv)

			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("swat")
				zb.GiveRole(ply, "Counter Terrorist", Color(0,0,190))
				ply:SetNetVar("CurPluv", "pluvberet")
			else
				ply:SetPlayerClass("terrorist")
				zb.GiveRole(ply, "Terrorist", Color(190,0,0))
				ply:SetNetVar("CurPluv", "pluvboss")
			end

			--[[if giveweapons:GetBool() then
				local gun = ply:Give(tblweps[ply:Team()][mrand])
				ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
				
				hg.AddAttachmentForce(ply,gun,tblatts[ply:Team()][mrand])
				hg.AddArmor(ply, tblarmors[ply:Team()][mrand])


				ply:Give("weapon_hg_rgd_tpik")
				ply:Give("weapon_walkie_talkie")
				ply:Give("weapon_bandage_sh")
				ply:Give("weapon_tourniquet")
			end--]]

			//ply:Give("weapon_melee")

			ply:Give("weapon_melee")
			ply:Give("weapon_bandage_sh")
			ply:Give("weapon_tourniquet")
			ply.organism.allowholster = true

			local Radio = ply:Give("weapon_walkie_talkie")
			Radio.Frequency = (ply:Team() == 1 and math.Round(math.Rand(88,95),1)) or math.Round(math.Rand(100,108),1)
			local hands = ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("tdm_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("tdm_roundend")
		net.Broadcast()
	end)
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end
util.AddNetworkString( "tdm_open_buymenu" )
function MODE:ShowSpare1(ply ) -- OpenMenu
	if not ply:Alive() then return end
	net.Start( "tdm_open_buymenu" )
	net.Send( ply )
end

util.AddNetworkString( "tdm_buyitem" )
util.AddNetworkString( "tdm_refunditem" )

local Shop = zb.TDMShop
local AttachmentPrice = Shop.AttachmentPrice or 50

local function canUseBuyMenu(ply, round)
	if not round or not round.buymenu then return false end
	if not IsValid(ply) or not ply:Alive() then return false end
	if ((zb.ROUND_START or 0) + 40) < CurTime() then
		ply:ChatPrint("Time's up!")
		return false
	end

	return true
end

local function stripOwnedBuyItem(ply, item, category)
	local class = item.ItemClass

	if item.Type == "Armor" or string.StartWith(class or "", "ent_armor_") or class == "hg_flashlight" then
		local eqName = Shop.GetArmorEquipmentName(class)
		local armors = Shop.GetPlayerArmors(ply)
		local placement = Shop.GetArmorPlacement(eqName)

		if placement and armors[placement] and hg and hg.DropArmor then
			hg.DropArmor(ply, armors[placement])
			return
		end

		for _, equipped in pairs(armors) do
			if equipped == eqName and hg and hg.DropArmor then
				hg.DropArmor(ply, equipped)
				return
			end
		end

		return
	end

	if ply:HasWeapon(class) then
		ply:StripWeapon(class)
	end
end

local function handleReplaceBeforePurchase(ply, item, category, replace)
	if not replace then return true end

	local owns, kind = Shop.PlayerOwnsItem(ply, item, category)
	if not owns then return true end

	if kind == "weapon" then
		local refundAmount = Shop.RefundAndStripWeapon(ply, item.ItemClass)
		if refundAmount > 0 then
			ply:ChatPrint("Refunded $" .. refundAmount .. ".")
		end

		return true
	end

	stripOwnedBuyItem(ply, item, category)

	return true
end

local function grantBuyItem(ply, item, category, index)
	local ent = ply:Give(item.ItemClass)

	if ent and ent.Use and IsValid(ent) then
		ent:Use(ply)
	end

	if IsValid(ent) and ent:GetClass() == "weapon_bloodbag" then
		ent.bloodtype = "o-"
		ent.modeValues[1] = 1
	end

	if IsValid(ent) and item.Amount then
		ent.AmmoCount = item.Amount
	end

	if IsValid(ent) and ent.GetPrimaryAmmoType then
		ply:GiveAmmo(ent:GetMaxClip1() * 1, ent:GetPrimaryAmmoType(), true)
	end

	if not Shop.IsAmmoPurchase(category, item) then
		Shop.AddPurchase(ply, category, index, item)
	end
end

net.Receive("tdm_buyitem", function(len, ply)
	local round = CurrentRound()
	if not canUseBuyMenu(ply, round) then return end

	local tItem = net.ReadTable()
	local replace = net.ReadBool()

	if not istable(tItem) then return end

	local category = tItem[1]
	local index = tItem[2]
	if not category or not index then return end

	local buyItems = round.BuyItems
	if not buyItems or not buyItems[category] or not buyItems[category][index] then return end

	local item = buyItems[category][index]
	if not item then return end

	if item.TeamBased != nil and item.TeamBased != ply:Team() then
		ply:ChatPrint("This item is not available for your team.")
		return
	end

	if tItem[3] then
		local attName = tItem[3]

		if not ply:HasWeapon(item.ItemClass) then
			ply:ChatPrint("You can't buy this attachment without a weapon.")
			return
		end

		local wep = ply:GetWeapon(item.ItemClass)
		if not IsValid(wep) then return end

		local hasConflict, _, existingAtt = Shop.GetAttachmentConflict(ply, item.ItemClass, attName)
		if hasConflict and not replace then
			return
		end

		if hasConflict and replace then
			local placement = Shop.GetAttachmentPlacement(attName)
			local purchaseId, purchase = Shop.FindAttachmentPurchase(ply, item.ItemClass, placement)

			if purchase then
				ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) + (purchase.price or AttachmentPrice))
				Shop.RemovePurchase(ply, purchaseId)
				ply:ChatPrint("Refunded $" .. (purchase.price or AttachmentPrice) .. ".")
			end

			if existingAtt then
				Shop.RemoveWeaponAttachment(wep, existingAtt)
			end
		end

		if (ply:GetNWInt("TDM_Money", 0) - AttachmentPrice) < 0 then
			ply:ChatPrint("Not enough money.")
			return
		end

		hg.AddAttachmentForce(ply, wep, attName)
		Shop.AddAttachmentPurchase(ply, category, index, item.ItemClass, attName, AttachmentPrice)
		ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) - AttachmentPrice)
		ply:EmitSound("items/itempickup.wav")

		return
	end

	Shop.ClearStalePurchaseIfMissing(ply, item.ItemClass)

	local ownsItem = Shop.PlayerOwnsItem(ply, item, category)
	local slotConflict = Shop.GetWeaponSlotConflict(ply, item.ItemClass)

	if (ownsItem or slotConflict) and not replace then
		return
	end

	if replace then
		if ownsItem then
			if not handleReplaceBeforePurchase(ply, item, category, true) then return end
		elseif slotConflict then
			local refundAmount = Shop.HandleWeaponSlotReplace(ply, item.ItemClass)
			if refundAmount > 0 then
				ply:ChatPrint("Refunded $" .. refundAmount .. ".")
			end
		end
	end

	if (ply:GetNWInt("TDM_Money", 0) - item.Price) < 0 then
		ply:ChatPrint("Not enough money.")
		return
	end

	grantBuyItem(ply, item, category, index)
	ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) - item.Price)
	ply:EmitSound("items/itempickup.wav")
end)

net.Receive("tdm_refunditem", function(len, ply)
	local round = CurrentRound()
	if not canUseBuyMenu(ply, round) then return end

	local purchaseId = net.ReadUInt(16)
	local purchases = ply.TDM_Purchases
	local purchase = purchases and purchases[purchaseId]
	if not purchase then return end

	local buyItems = round.BuyItems
	local item = buyItems and buyItems[purchase.category] and buyItems[purchase.category][purchase.index]
	local itemClass = purchase.itemClass or (item and item.ItemClass)
	if not itemClass then return end

	if purchase.purchaseType == "attachment" then
		local wep = ply:GetWeapon(purchase.weaponClass or itemClass)
		if not IsValid(wep) or not Shop.WeaponHasAttachmentNamed(wep, purchase.attachment) then
			ply:ChatPrint("You no longer have this attachment to refund.")
			return
		end

		Shop.RemoveWeaponAttachment(wep, purchase.attachment)
	elseif purchase.itemType == "Armor" or string.StartWith(itemClass, "ent_armor_") or itemClass == "hg_flashlight" then
		local eqName = Shop.GetArmorEquipmentName(itemClass)
		local armors = Shop.GetPlayerArmors(ply)
		local equippedName

		for _, equipped in pairs(armors) do
			if equipped == eqName then
				equippedName = equipped
				break
			end
		end

		if not equippedName then
			ply:ChatPrint("You no longer have this item to refund.")
			return
		end

		if hg and hg.DropArmor then
			hg.DropArmor(ply, equippedName)
		end
	else
		if not ply:HasWeapon(itemClass) then
			ply:ChatPrint("You no longer have this item to refund.")
			return
		end

		ply:StripWeapon(itemClass)
	end

	ply:SetNWInt("TDM_Money", ply:GetNWInt("TDM_Money", 0) + (purchase.price or 0))
	Shop.RemovePurchase(ply, purchaseId)
	ply:EmitSound("items/itempickup.wav")
	ply:ChatPrint("Refunded $" .. (purchase.price or 0) .. ".")
end)

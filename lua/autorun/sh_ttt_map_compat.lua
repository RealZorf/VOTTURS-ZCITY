if SERVER then
	AddCSLuaFile()
end

local function registerCompatWeapon(className)
	if weapons.GetStored(className) then return end

	weapons.Register({
		Base = "weapon_base",
		Spawnable = false,
		AdminOnly = false,
		AutoSwitchTo = false,
		AutoSwitchFrom = false,
		DrawAmmo = false,
		DrawCrosshair = false,
		ViewModel = "",
		WorldModel = "",
		PrintName = className,
		Initialize = function(self)
			if SERVER and not IsValid(self:GetOwner()) then
				SafeRemoveEntityDelayed(self, 0)
			end
		end,
	}, className)
end

local function registerCompatEntity(className)
	if scripted_ents.GetStored(className) then return end

	scripted_ents.Register({
		Type = "point",
		Base = "base_entity",
		Spawnable = false,
		AdminOnly = false,
		PrintName = className,
		Initialize = function(self)
			if SERVER then
				SafeRemoveEntityDelayed(self, 0)
			end
		end,
	}, className)
end

local inertWeapons = {
	"weapon_ttt_confgrenade",
	"weapon_ttt_smokegrenade",
	"weapon_ttt_m16",
	"weapon_ttt_flaregun",
	"weapon_zm_molotov",
	"weapon_zm_mac10",
	"weapon_zm_shotgun",
	"weapon_zm_revolver",
	"weapon_zm_rifle",
	"weapon_zm_sledge",
}

for _, className in ipairs(inertWeapons) do
	registerCompatWeapon(className)
end

local inertEntities = {
	"item_ammo_pistol_ttt",
	"item_ammo_smg1_ttt",
	"item_box_buckshot_ttt",
	"item_ammo_revolver_ttt",
	"item_ammo_357_ttt",
	"ttt_map_settings",
	"ttt_credit_adjust",
	"ttt_random_weapon",
	"ttt_random_ammo",
}

for _, className in ipairs(inertEntities) do
	registerCompatEntity(className)
end

AddCSLuaFile()
hg.ammotypes = hg.ammotypes or {}

/*
BulletSettings = {
			Damage = 8,
			Force = 5,
			Penetration = 4,
			Shell = "9x18",
			Speed = 259,
			Diameter = 11.19,
			Distance = 10,
			Mass = 10,
			AirResistMul = 0.0001,
			NumBullet = 1,
		}
*/

function SWEP:ApplyAmmoChanges(type_)
	if not self.AmmoTypes or not istable(self.AmmoTypes) then
		print("ERRAR: The table is not valid")
		return
	end

	local ammo = self.AmmoTypes[type_]
	if not ammo then
		print("ERRAR: DISABLED PATRONAAA TYPE")
		return
	end

	local ammohuy = hg.ammotypeshuy[ammo[1]]
	if not ammohuy then
		print("ERRAR: shit with Patricks in hg.ammotypeshuy")
		return
	end

	local ammotype = ammohuy.BulletSettings
	if not ammotype then
		print("ERRAR: No rump settings") --soundboard moron
		return
	end

	self.Primary.Ammo = ammo[1]
	self.newammotype = type_
	self.RealAmmoType = ammo[1]
	self.Primary.Damage = ammotype.Damage
	self.Penetration = ammotype.Penetration
	self.NumBullet = ammotype.NumBullet
	--self.Primary.Force = ammotype.Force

	if SERVER then
		net.Start("syncAmmoChanges")
		net.WriteEntity(self)
		net.WriteInt(type_, 4)
		net.Broadcast()
	end
end


if SERVER then
	util.AddNetworkString("syncAmmoChanges")
else
	net.Receive("syncAmmoChanges", function()
		local self = net.ReadEntity()
		local type_ = net.ReadInt(4)
		if self.ApplyAmmoChanges then
			self:ApplyAmmoChanges(type_)
		end
	end)
end


AddCSLuaFile()
if CLIENT then
	net.Receive("hgwep shoot", function()
		local self = net.ReadEntity()
		local shoot = net.ReadBool()
		local broadcastAnyways = net.ReadBool()
		local effectsOnly = net.ReadBool()
		
		if not IsValid(self) then return end
		if !broadcastAnyways and self:GetOwner() == LocalPlayer() and !game.SinglePlayer() then
			if self:LastShootTime() + 0.05 > CurTime() then return end
			if self.PlayShootFX then
				self:PlayShootFX()
			end
			return
		end
		
		if effectsOnly and self.PrimaryShoot then
			self:SetLastShootTime(CurTime())
			self:PrimaryShoot()
			if self.PrimaryShootPost then self:PrimaryShootPost() end
		elseif self.Shoot then
			self:Shoot(broadcastAnyways or shoot)
		end
	end)
end

function SWEP:IsClient()
	return CLIENT and self:GetOwner() == LocalPlayer()
end

function SWEP:KeyDown(key)
	return hg.KeyDown(self:GetOwner(),key)
end

include("shared.lua")

function ENT:Initialize()
	if ZCityTraps then
		ZCityTraps.RegisterButton(self)
	end
end

function ENT:OnRemove()
	if ZCityTraps then
		ZCityTraps.UnregisterButton(self)
	end
end

function ENT:Draw()
end

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.Model = Model("models/weapons/w_bugbait.mdl")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)

	local delay = tonumber(self.RawDelay) or 1
	if delay < 0 then
		self.RemoveOnPress = true
		delay = -1
	end

	if self.RemoveOnPress then
		delay = -1
	end

	self:SetDelay(delay)
	self:SetNextUseTime(0)
	self:SetLocked(self:HasSpawnFlags(2048))
	self:SetDescription(self.RawDescription or "?")

	if self:GetUsableRange() < 1 then
		self:SetUsableRange((ZCityTraps and ZCityTraps.MaxActivationRange) or 4096)
	end

	self.RawDelay = nil
	self.RawDescription = nil

	if ZCityTraps then
		ZCityTraps.RegisterButton(self)
	end
end

function ENT:OnRemove()
	if ZCityTraps then
		ZCityTraps.UnregisterButton(self)
	end
end

function ENT:KeyValue(key, value)
	local lowerKey = string.lower(key)

	if lowerKey == "onpressed" then
		self:StoreOutput("OnPressed", value)
	elseif lowerKey == "wait" then
		self.RawDelay = tonumber(value)
	elseif lowerKey == "description" then
		local description = string.Trim(tostring(value))
		self.RawDescription = description ~= "" and description or nil
	elseif lowerKey == "removeonpress" then
		self.RemoveOnPress = tobool(value)
	else
		self:SetNetworkKeyValue(key, value)
	end
end

function ENT:AcceptInput(name)
	local lowerName = string.lower(name)

	if lowerName == "toggle" then
		self:SetLocked(not self:GetLocked())
		return true
	elseif lowerName == "hide" or lowerName == "lock" then
		self:SetLocked(true)
		return true
	elseif lowerName == "unhide" or lowerName == "unlock" then
		self:SetLocked(false)
		return true
	end
end

function ENT:ActivateTrap(ply)
	if not ZCityTraps then return false end

	local allowed, code = ZCityTraps.CanUseTrap(ply, self)
	if not allowed then
		ZCityTraps.SendResult(ply, false, code)
		return false
	end

	self:TriggerOutput("OnPressed", ply)
	hook.Run("ZCityTrapActivated", self, ply)
	ZCityTraps.SendResult(ply, true, 0)

	if not IsValid(self) then return true end

	if self.RemoveOnPress then
		self:SetLocked(true)
		self:Remove()
	else
		self:SetNextUseTime(CurTime() + math.max(self:GetDelay(), 0))
	end

	return true
end

ENT.TraitorUse = ENT.ActivateTrap

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

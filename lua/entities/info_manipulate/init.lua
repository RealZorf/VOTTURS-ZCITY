AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:KeyValue(key, value)
	local lowerKey = string.lower(key)

	if lowerKey == "onpressed" then
		self.RawOutputs = self.RawOutputs or {}
		self.RawOutputs[#self.RawOutputs + 1] = value
	elseif lowerKey == "cost" then
		self.Cost = tonumber(value)
	elseif lowerKey == "active" then
		self.Active = tobool(value)
	elseif lowerKey == "removeontrigger" then
		self.RemoveOnTrigger = tobool(value)
	elseif lowerKey == "description" then
		self.Description = tostring(value)
	end
end

function ENT:CreateReplacement()
	if self.Replaced then return end

	local trap = ents.Create("ttt_traitor_button")
	if not IsValid(trap) then return end

	self.Replaced = true
	trap:SetPos(self:GetPos())
	trap:SetAngles(self:GetAngles())
	trap:SetKeyValue("targetname", self:GetName())

	if not self.Active then
		trap:SetKeyValue("spawnflags", "2048")
	end

	if isstring(self.Description) and self.Description ~= "" then
		trap:SetKeyValue("description", self.Description)
	end

	if self.Cost then
		trap:SetKeyValue("wait", tostring(self.Cost))
	end

	if self.RemoveOnTrigger then
		trap:SetKeyValue("RemoveOnPress", "1")
	end

	for _, output in ipairs(self.RawOutputs or {}) do
		trap:SetKeyValue("OnPressed", tostring(output))
	end

	trap:Spawn()
	trap:Activate()
end

function ENT:Think()
	if not self.Replaced then
		self:CreateReplacement()
	end

	self:Remove()
end

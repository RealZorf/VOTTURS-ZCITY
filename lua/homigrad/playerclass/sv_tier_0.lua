local classList = player.classList
local Player = FindMetaTable("Player")

local function ResetClassAnimationState(ply)
	if not IsValid(ply) then return end

	if ply.AnimResetGestureSlot then
		for slot = 0, 6 do
			ply:AnimResetGestureSlot(slot)
		end
	end

	if ply.AnimRestartMainSequence then ply:AnimRestartMainSequence() end
	if ply.SetCycle then ply:SetCycle(0) end
	if ply.SetPlaybackRate then ply:SetPlaybackRate(1) end
end

function Player:SetPlayerClass(value, data)
	data = data or {}

	value = value or "none"
	local old = self.PlayerClassName
	self.PlayerClassNameOld = old
	old = classList[old]
	if old and old.Off then old.Off(self) end
	self.PlayerClassName = value
	self:PlayerClassEvent("On", data) -- WHO WRITE THIS SHIT
	ResetClassAnimationState(self)
	timer.Simple(0, function()
		if IsValid(self) then ResetClassAnimationState(self) end
	end)

	net.Start("setupclass")
		net.WriteEntity(self)
		net.WriteString(value)
		net.WriteString(self.PlayerClassNameOld or "")
		net.WriteTable(data)
	net.Broadcast()
	--if self:Alive() then
	--	hg.FakeUp(self, true, true)
	--end
end

function Player:GiveSwep(list, mulClip1) -- улучшенный tdm.GiveSwep
	if not list then return end
	local wep = self:Give(type(list) == "table" and list[math.random(#list)] or list)
	mulClip1 = mulClip1 or 3
	if IsValid(wep) then
		wep:SetClip1(wep:GetMaxClip1())
		self:GiveAmmo(wep:GetMaxClip1() * mulClip1, wep:GetPrimaryAmmoType())
	end
end

util.AddNetworkString("setupclass")
hook.Add("PlayerInitializeSpawn", "PlayerClass", function(plySend)
	local delay = 0

	for _, ply in player.Iterator() do
		if not ply:GetPlayerClass() then continue end

		delay = delay + 0.03
		timer.Simple(delay, function()
			if not IsValid(plySend) or not IsValid(ply) then return end

			net.Start("setupclass")
			net.WriteEntity(ply)
			net.WriteString(ply:GetNWString("Class"))
			net.WriteString(ply:GetNWString("ClassOld"))
			net.WriteTable({})
			net.Send(plySend)
		end)
	end
end)

hook.Add("PostPostPlayerDeath", "PlayerClass", function(ply, ragdoll)
	ply:PlayerClassEvent("PlayerDeath")
	ply:SetPlayerClass()
end)

hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
	ply:PlayerClassEvent("Think", time, dtime)
end)

COMMANDS.playerclass = {
	function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 1 and args[1] or ply:Name()
		local class = #args > 1 and args[2] or args[1]

		if #args < 2 then
			ply:SetPlayerClass(class)
			ply:ChatPrint(ply:Name())
		else
			for i, ply2 in pairs(player.GetListByName(plya)) do
				ply2:SetPlayerClass(class)
				ply:ChatPrint(ply2:Name())
			end
		end
	end,
	0
}

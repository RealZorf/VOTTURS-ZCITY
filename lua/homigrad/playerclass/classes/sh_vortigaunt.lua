local CLASS = player.RegClass("Vortigaunt")

local model = "models/player/vortigaunt.mdl"
local vortWeapon = "vort_swep"
local vortNames = {
	"Va", "Zuun", "Keth", "Ruun", "Sha", "Naar", "Vek", "Thal", "Uun", "Kael",
	"Zeth", "Vraal", "Niir", "Suun", "Koss", "Rael", "Duun", "Maar", "Vel", "Tuun",
	"Xuun", "Kraal", "Sethar", "Vuun", "Neth", "Zaal", "Reth", "Orr", "Kuun", "Shael",
	"Vorr", "Taln", "Neer", "Zorr", "Ural", "Ka", "Shaal", "Veth", "Ruunak", "Kelth"
}

local function resetVortAnimationState(ply)
	if not IsValid(ply) then return end

	if ply.AnimResetGestureSlot then
		for slot = 0, 6 do
			ply:AnimResetGestureSlot(slot)
		end
	end

	if ply.AnimRestartMainSequence then
		ply:AnimRestartMainSequence()
	end

	if ply.SetCycle then
		ply:SetCycle(0)
	end

	if ply.SetPlaybackRate then
		ply:SetPlaybackRate(1)
	end
end

local function removeVortWeapon(ply)
	if not IsValid(ply) then return end

	local active = ply:GetActiveWeapon()
	local wasHoldingVort = IsValid(active) and active:GetClass() == vortWeapon

	if ply:HasWeapon(vortWeapon) then
		ply:StripWeapon(vortWeapon)
	end

	if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
		if not ply:HasWeapon("weapon_hands_sh") then
			ply:Give("weapon_hands_sh")
		end

		if wasHoldingVort and ply:HasWeapon("weapon_hands_sh") then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end
end

function CLASS.Off(self)
	if CLIENT then return end

	removeVortWeapon(self)
	resetVortAnimationState(self)
	self:SetNetVar("Accessories", "")
	self:SetNWString("PlayerRole", "")
	self:SetNWString("PlayerName", "")
	self:SetNWBool("ZC_HL3_Vort", false)
end

CLASS.NoGloves = true
CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true

function CLASS.On(self)
	if CLIENT then return end

	if IsValid(self.FakeRagdoll) then
		hg.FakeUp(self, nil, nil, true)
	end

	self:SetModel(model)
	self:SetSubMaterial()
	self:SetSkin(0)
	self:SetBodyGroups("")
	self:SetNetVar("Accessories", "")
	self.CurAppearance = nil

	if zb.GiveRole then
		zb.GiveRole(self, "Vortigaunt", Color(110, 220, 150))
	end

	self:SetNWString("PlayerRole", "Vortigaunt")
	self:SetNWString("PlayerName", table.Random(vortNames))
end

if SERVER then
	local vort_phrases = {}

	for i = 1, 30 do
		vort_phrases[i] = string.format("vortigaunt/06_%05d.wav", i)
	end

	hook.Add("HG_ReplacePhrase", "vortigaunt_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "Vortigaunt" then
			return ply, vort_phrases[math.random(#vort_phrases)], muffed, pitch
		end
	end)
end

return CLASS

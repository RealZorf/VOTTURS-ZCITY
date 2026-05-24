player.classList = player.classList or {}
local classList = player.classList
local PlayerMeta = FindMetaTable("Player")
function PlayerMeta:GetPlayerClass()
	return classList[self.PlayerClassName or ""]
end

local meta
function PlayerMeta:PlayerClassEvent(name, ...) --haha
	meta = self:GetPlayerClass()
	meta = meta and meta[name]
	if meta then return meta(self, ...) end
end

function player.RegClass(name)
	local class = classList[name] or {}
	classList[name] = class
	return class
end

function player.EventPoint(pos, name, radius, ...)
	for i, ply in player.Iterator() do
		if ply:GetPos():Distance(pos) > radius then continue end
		ply:PlayerClassEvent("EventPoint", name, pos, radius, ...)
	end
end

function player.Event(ply, name, ...)
	ply:PlayerClassEvent("Event", name, ...)
end

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

if SERVER then return end

local visualClassModels = {
	headcrabzombie = "models/zcity/player/zombie_classic.mdl",
	furry = "models/eradium/protogen_player.mdl"
}

local function ClearClientBoneCaches(ent)
	if not IsValid(ent) then return end

	ent.ZCTPIKBoneCache = nil
	ent.ZCTPIKBoneCacheModel = nil
	ent.ZCCameraBoneCache = nil
	ent.ZCCameraBoneCacheModel = nil
	ent.ZCCameraAttachmentCache = nil
	ent.ZCCameraAttachmentCacheModel = nil
	ent.ZCSpineBoneCamera = nil
	ent.ZCSpineBoneCameraModel = nil
	ent.ZCHeadBoneRender = nil
	ent.ZCHeadBoneRenderModel = nil
	ent.ZCHeadBoneFakeCam = nil
	ent.ZCHeadBoneFakeCamModel = nil
	ent.ZCHeadcrabBone = nil
	ent.ZCHeadcrabBoneModel = nil
	ent.ZCArmorBones = nil
	ent.ZCArmorBonesModel = nil
	ent.ZCClientThinkBones = nil
	ent.ZCClientThinkBonesModel = nil
	ent.ZCGoreBones = nil
	ent.ZCGoreModel = nil
	ent.ZCGoreBonesModel = nil
end

local function ResetClassVisualState(ply)
	if not IsValid(ply) then return end

	ResetClassAnimationState(ply)

	ply.ZC_FirstPersonHeadHidden = nil
	ply.ZCDisableHeadcrabHands = ply.PlayerClassName ~= "headcrabzombie" or string.lower(ply:GetModel() or "") ~= visualClassModels.headcrabzombie

	ClearClientBoneCaches(ply)
	ClearClientBoneCaches(ply:GetViewModel())
	ClearClientBoneCaches(ply:GetHands())

	if hg.ResetTPIKState then
		hg.ResetTPIKState(ply)
	end
end
local function QueueClassVisualReset(ply)
	ResetClassVisualState(ply)

	for _, delay in ipairs({0, 0.1, 0.35}) do
		timer.Simple(delay, function()
			if IsValid(ply) then ResetClassVisualState(ply) end
		end)
	end
end

local function CheckClassVisualTransition(ply)
	if not IsValid(ply) then return end

	local model = ply:GetModel()
	local className = ply.PlayerClassName or ""
	if ply.ZCClassVisualLastModel == nil then
		ply.ZCClassVisualLastModel = model
		ply.ZCClassVisualLastClass = className
		return
	end

	if ply.ZCClassVisualLastModel == model and ply.ZCClassVisualLastClass == className then return end

	ply.ZCClassVisualLastModel = model
	ply.ZCClassVisualLastClass = className
	QueueClassVisualReset(ply)
end

net.Receive("setupclass", function()
	local ply = net.ReadEntity()
	if not IsValid(ply) then --lol
		return
	end

	ply.PlayerClassName = net.ReadString()
	ply.PlayerClassNameOld = net.ReadString()
	local data = net.ReadTable()
	local old = classList[ply.PlayerClassNameOld]
	if old and old.Off then old.Off(ply) end
	ply:PlayerClassEvent("On", data)
	QueueClassVisualReset(ply)
end)

hook.Add("PostDrawAppearance", "PlayerClass", function(ent,ply) end)

if CLIENT then
	hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
		CheckClassVisualTransition(ply)
		ply:PlayerClassEvent("Think", time, dtime)
	end)
end

--hook.Add("HGReloading", "PlayerClass", function(wep) wep:GetOwner():PlayerClassEvent("HGReloading", wep) end)
--hook.Add("PlayerFootstep", "PlayerClass", function(ply, pos, foot, sound, volume, rf) ply:PlayerClassEvent("PlayerFootstep", ply, pos, foot, sound, volume, rf) end)

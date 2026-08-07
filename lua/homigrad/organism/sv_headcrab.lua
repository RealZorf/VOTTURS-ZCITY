
local PLAYER = FindMetaTable("Player")
util.AddNetworkString("hg_headcrab")
function PLAYER:AddHeadcrab(headcrab)
	if self.PlayerClassName == "headcrabzombie" or self.PlayerClassName == "fastzombie" or self.PlayerClassName == "poisonzombie" then return end
    --self.organism.headcrabon = headcrab
    self:SetNetVar("headcrab",headcrab)
   
    self.organism.headcrabon = headcrab and CurTime()
	self.organism.headcrabevent = false

    --[[net.Start("hg_headcrab")
    net.WriteEntity(self)
    net.WriteString(headcrab)
    net.Broadcast()--]]
end

local brainLobes = {
	"brainFrontal",
	"brainParietal",
	"brainTemporal",
	"brainOccipital"
}

local function isBrainDestroyed(ply, rag, org)
	if not org then return true end
	if org.headamputated or rag.headexploded or ply.headamputated then return true end
	if (org.brain or 0) >= 0.6 then return true end

	for i = 1, #brainLobes do
		if (org[brainLobes[i]] or 0) >= 0.95 then return true end
	end

	return false
end

local function releaseHeadcrab(ply, rag, org, headcrabClass)
	if rag.ZCReleasedHeadcrab or isBrainDestroyed(ply, rag, org) then return end
	rag.ZCReleasedHeadcrab = true

	local headPos
	local headBone = rag:LookupBone("ValveBiped.Bip01_Head1")
	if headBone then headPos = rag:GetBonePosition(headBone) end
	headPos = isvector(headPos) and headPos or rag:WorldSpaceCenter()

	local spawnTrace = util.TraceHull({
		start = headPos + Vector(0, 0, 2),
		endpos = headPos + Vector(0, 0, 20),
		mins = Vector(-6, -6, 0),
		maxs = Vector(6, 6, 10),
		mask = MASK_NPCSOLID,
		filter = {ply, rag}
	})

	local headcrab = ents.Create(headcrabClass or "npc_headcrab")
	if not IsValid(headcrab) then return end

	rag:SetBodygroup(1, 0)
	headcrab:SetPos(spawnTrace.HitPos)
	headcrab:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	headcrab:Spawn()
	headcrab:Activate()
	headcrab:SetVelocity(ply:GetVelocity() + ply:GetForward() * 70 + Vector(0, 0, 110))
	headcrab:EmitSound(headcrabClass == "npc_headcrab_black" and "npc/headcrab_poison/ph_rattle1.wav" or "npc/headcrab/alert1.wav", 70, math.random(95, 105))
end

hook.Add("RagdollDeath","headcrab",function(ply,rag)
    rag:SetNetVar("headcrab", ply:GetNetVar("headcrab"))
    ply:SetNetVar("headcrab", false)
	ply.organism.noHead = false

	if ply.PlayerClassName == "headcrabzombie" or ply.PlayerClassName == "poisonzombie" then
		local headcrabClass = ply.PlayerClassName == "poisonzombie" and "npc_headcrab_black" or "npc_headcrab"
		timer.Simple(0, function()
			if not IsValid(ply) or not IsValid(rag) then return end
			releaseHeadcrab(ply, rag, rag.organism or ply.organism, headcrabClass)
		end)
	end
end)

hook.Add("Org Clear", "removeheadcrab", function(org)
    org.headcrabon = nil
	org.headcrabevent = false
	if IsValid(org.owner) then
		org.owner:SetNetVar("headcrab", false)
	end
	org.noHead = false
end)

local fallbackMats = {
	["Rebel"] = {
		["main"] = "models/zombie_classic/zombie_classic_sheet",
		["pants"] = "models/zombie_classic/zombie_classic_sheet",
		["boots"] = "models/zombie_classic/zombie_classic_sheet",
	},
	["Metrocop"] = {
		["main"] = "models/balaclava_hood/berd_diff_018_a_uni",
		["pants"] = "models/humans/male/group02/lambda",
		["boots"] = "models/humans/male/group01/formal"
	},
	["Combine"] = {
		["main"] = "models/zombie_classic/combinesoldiersheet_zombie",
		["pants"] = "models/gruchk_uwrist/css_seb_swat/swat/gear2",
		["boots"] = "models/humans/male/group01/formal"
	},
}

local clr_red, lerpAng = Color(150, 0, 0), Angle(0, 0, 0)
hook.Add("Org Think", "Headcrab",function(owner, org, timeValue)
    if not IsValid(owner) then return end
    if not owner:IsPlayer() or not owner:Alive() then return end

    if org.headcrabon and (org.headcrabon + 30) < CurTime() and org.brain != 1 and owner.organism.spine3 != 1 then
		local ent = hg.GetCurrentCharacter(owner) or owner
		local mul = ((org.headcrabon + 60) - CurTime()) / 60
		if mul > 0 then
			ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul,750 * mul))
		end
	end

    if owner:IsPlayer() then
		if org.headcrabon then
			owner.noHead = true
			owner:SetNWString("PlayerName", "Body with headcrab")
			org.brain = 0.3

			if org.alive then
				lerpAng = LerpAngle(FrameTime() * 3, lerpAng, AngleRand(-90, 90))
				lerpAng.r = 0
				owner:SetEyeAngles(owner:EyeAngles() + lerpAng)
			end

			if (org.headcrabon + 60) < CurTime() and org.alive and not org.headcrabevent then
				owner:EmitSound("npc/zombie/zombie_alert" .. math.random(3) .. ".wav", 80, math.random(60, 70))
				owner:EmitSound("neck_snap_01.wav", 80, 80, 1, CHAN_AUTO)
				owner:SetPlayerClass("headcrabzombie")
				org.painadd = org.painadd + 5

				hg.StunPlayer(owner, 5)
				if zb and zb.GiveRole then
					zb.GiveRole(owner, "Zombie", clr_red)
				end

				org.headcrabevent = true
				org.headcrabon = nil
				org.headcrabevent = false
				org.noHead = false

				hg.FakeUp(owner, true)
				owner:SetNetVar("headcrab", false)
			end
		end

        if org.alive and org.headcrabon and (org.headcrabon + 20) < CurTime() then
			if (org.headcrabon + 30) > CurTime() then
				owner:EmitSound("npc/zombie/zombie_pain"..math.random(6)..".wav", 80, math.random(80, 90))
				org.painadd = org.painadd + 15
				hg.StunPlayer(owner, 5)
			end
		end

        if org.alive and org.headcrabon and (org.headcrabon + 60) < CurTime() then
			owner:SetNWString("PlayerName", "Body with headcrab")
			org.alive = false
		end
    end
end)

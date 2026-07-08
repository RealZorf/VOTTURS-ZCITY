hg.bloodparticles1 = hg.bloodparticles1 or {}
bloodparticles_hook = bloodparticles_hook or {}

local tr = {
	--filter = function(ent) return not ent:IsPlayer() and not ent:IsRagdoll() end
}

local col_red_darker = Color(122,0,0)
local col_red = Color(200,0,0)
local vecDown = Vector(0, 0, -40)
local vecZero = Vector(0, 0, 0)
local LerpVector = LerpVector
local math_random = math.random
local table_remove = table.remove
local util_Decal = util.Decal
local util_TraceLine = util.TraceLine
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local render_DrawBeam = render.DrawBeam
local render_GetLightColor = render.GetLightColor
local render_ComputeLighting = render.ComputeLighting
local math_ceil = math.ceil
local math_min = math.min
local math_max = math.max

local hg_blood_draw_distance = ConVarExists("hg_blood_draw_distance") and GetConVar("hg_blood_draw_distance") or CreateClientConVar("hg_blood_draw_distance", 1024, true, nil, "distance to draw blood", 0, 4096)
local hg_blood_sprites = ConVarExists("hg_blood_sprites") and GetConVar("hg_blood_sprites") or CreateClientConVar("hg_blood_sprites", 1, true, nil, "blood is sprites or trails", 0, 1)
local BLOOD_DRAW_SOFT_CAP = 240
local BLOOD_PARTICLE_HARD_CAP = 380
local BLOOD_POSITION_RESET_CAP = 2500
local BLOOD_DECALS_PER_POS = 3
local BLOOD_POOL_DECAL_THRESHOLD = 18
local BLOOD_LIGHT_UPDATE_INTERVAL = 0.08
local nosebleedDripNext = {}

hook.Add("PostCleanupMap","removeblooddroplets",function()
	hg.bloodparticles1 = {}
	hg.bloodpositions = {}
	hg.bloodcount = 0
	nosebleedDripNext = {}
end)

local function getNosebleedCharacter(ply)
	if hg and hg.GetCurrentCharacter then
		local character = hg.GetCurrentCharacter(ply)
		if IsValid(character) then return character end
	end

	local ragdoll = ply.GetNWEntity and ply:GetNWEntity("FakeRagdoll", NULL) or nil
	if IsValid(ragdoll) then return ragdoll end

	ragdoll = ply.GetNWEntity and ply:GetNWEntity("RagdollDeath", NULL) or nil
	if IsValid(ragdoll) then return ragdoll end

	return ply
end

local function getNosebleedHead(ent)
	if not IsValid(ent) or not ent.LookupBone then return nil end

	local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not bone then return nil end

	if ent.SetupBones then ent:SetupBones() end
	return ent:GetBoneMatrix(bone)
end

local function addNosebleedDrip(ply, pos, ang, activeFrac)
	local now = CurTime()
	if (nosebleedDripNext[ply] or 0) > now then return end

	nosebleedDripNext[ply] = now + math.Rand(0.35, 0.9)
	if math.Rand(0, 1) > math.Clamp(activeFrac + 0.15, 0.2, 0.85) then return end
	if not hg or not hg.addBloodPart then return end

	local vel = vector_up * -30 + ang:Forward() * 2
	hg.addBloodPart(pos, vel, nil, 1.8, 1.8, false, false, ply)
end

local function drawNosebleedForPlayer(ply, eyePos, maxDistanceSqr)
	local bleedUntil = ply:GetNWFloat("ZCity_NosebleedUntil", 0)
	local now = CurTime()
	if bleedUntil <= now then return end

	local character = getNosebleedCharacter(ply)
	if not IsValid(character) then return end
	if character:GetPos():DistToSqr(eyePos) > maxDistanceSqr then return end

	local matrix = getNosebleedHead(character)
	if not matrix then return end

	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles()
	local remaining = bleedUntil - now
	local activeFrac = math.Clamp(remaining / 45, 0.1, 1)

	local nostril = pos + ang:Right() * 2.7 + ang:Forward() * 3.4 - ang:Up() * 4.9
	addNosebleedDrip(ply, nostril, ang, activeFrac)
end

hook.Add("PostDrawTranslucentRenderables", "ZCity_NosebleedFaceRun", function()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local maxDistance = math.min(hg_blood_draw_distance:GetInt(), 900)
	if maxDistance <= 0 then return end

	local eyePos = EyePos()
	local maxDistanceSqr = maxDistance * maxDistance

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		drawNosebleedForPlayer(ply, eyePos, maxDistanceSqr)
	end
end)

local mat_huy = Material("effects/blood_core")
local lightcolor = Color(0, 0, 0, 255)
bloodparticles_hook[1] = function(anim_pos, mul)
	local int = hg_blood_draw_distance:GetInt()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local eyePos = lply:EyePos()
	local eyeForward = lply:EyeAngles():Forward()
	local dstsqr = int * int
	local particleCount = #hg.bloodparticles1
	local step = particleCount > BLOOD_DRAW_SOFT_CAP and math_ceil(particleCount / BLOOD_DRAW_SOFT_CAP) or 1
	local curTime = CurTime()
	for i = 1, particleCount, step do
		local part = hg.bloodparticles1[i]
		if not part then continue end
		local startPos = part[1]
		local endPos = part[2]
		if (startPos - eyePos):Dot(eyeForward) < 0 then continue end
		if (endPos - eyePos):LengthSqr() > dstsqr then continue end
		--if !hg.isVisible(part[1],LocalPlayer():GetShootPos(),LocalPlayer(),MASK_VISIBLE) then continue end
		--render_SetMaterial(part[4])
		local pos = LerpVector(anim_pos, endPos, startPos)

		if (part.nextLightSample or 0) <= curTime then
			local light1 = render_GetLightColor(pos)
			local light2 = render_ComputeLighting(pos, vector_up)
			part.cachedLightR = math_max((light1[1] + light2[1]) * 2, 0.05)
			part.nextLightSample = curTime + BLOOD_LIGHT_UPDATE_INTERVAL
		end

		local lightR = part.cachedLightR or 0.25

		if part.kishki then
			render_SetMaterial(part[4])
			lightcolor.r = math_min((part.artery and 45 or 10) * lightR, 255)
			render_DrawSprite(pos, part[5], part[6], lightcolor)
		else
			local len = (endPos - startPos):LengthSqr()
			--part.lerpeddiff = LerpVector(FrameTime() * 1, part.lerpeddiff or Vector(), (part[2] - part[1]))
			--if len > 1 * 1 then
				render_SetMaterial(mat_huy)
				lightcolor.r = math_min((part.artery and 45 or 20) * lightR, 255)
				--part.lerpedshit = LerpFT(!part.lasthit and 1 or mul * 1, part.lerpedshit or 1, part.lasthit and 7 or 1)
				--render_DrawBeam(pos - (len < 2 and (part[2] - part[1]):GetNormalized() * part.lerpedshit or (part[2] - part[1])) * 0.5 / mul / 24,pos + (part[2] - part[1]) * 0.5 / mul / 24, part.lerpedshit, 0, 1, part[9] or lightcolor )
				--render_DrawBeam(pos - (part[2] - part[1]) * part.lerpedshit / mul / 24 * 0.5,pos + (part[2] - part[1]) * part.lerpedshit / mul / 24 * 0.5, part.lerpedshit, 0, 1, part[9] or lightcolor )
				
				--render_DrawBeam(pos - (len < 2 and (part[2] - part[1]):GetNormalized() * 2 or (part[2] - part[1])) * 0.5 / mul / 24,pos + (part[2] - part[1]) * 0.5 / mul / 24, 1, 0, 1, part[9] or lightcolor )
				render_DrawBeam(pos - (endPos - startPos) * 1 / mul / 24 * 0.5,pos + (endPos - startPos) * 1 / mul / 24 * 0.5, 1, 0, 1, part[9] or lightcolor )

				--lightcolor.r = lightcolor.r * 0.25
				--debugoverlay.Line(part[2], part[1], 1, lightcolor, false)	
			--end
		end
	end
	--render.OverrideBlend( false )
end

local hg_old_blood = ConVarExists("hg_old_blood") and GetConVar("hg_old_blood") or CreateClientConVar("hg_old_blood", 0, true, false, "new decals, or old", 0, 1)

hg.bloodpositions = hg.bloodpositions or {}
hg.bloodcount = hg.bloodcount or 0
local function decalBlood(pos, normal, tr, artery, owner)
	local vec = tostring(math.Round(pos[1]))..tostring(math.Round(pos[2]))..tostring(math.Round(pos[3]))

	hg.bloodcount = hg.bloodcount + 1
	
	if hg.bloodcount > BLOOD_POSITION_RESET_CAP then
		hg.bloodpositions = {}
		hg.bloodcount = 0
	end

	--I don’t know how big you can make such tables... I hope it won’t be so scary

	if artery then
		if !hg_old_blood:GetBool() then
			local howmuch = 1
			
			--timer.Simple(0.1, function()
				hg.bloodpositions[vec] = (hg.bloodpositions[vec] or 0) + 1
				if hg.bloodpositions[vec] <= BLOOD_DECALS_PER_POS then
					util.Decal("Arterial.Blood2"..math.Clamp(hg.bloodpositions[vec], 1, 5), pos + normal, pos - normal, owner)
				end
				sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", pos, math.random(10, 60), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
				if tr.MatType == MAT_METAL then
					sound.Play("zbattle/blood_drop_metal.mp3", pos, math.random(10, 40), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
				end
			--end)
		else
			util.Decal("Arterial.Blood1", pos + normal, pos - normal, owner)
			sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", pos, math.random(10, 60), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
			if tr.MatType == MAT_METAL then
				sound.Play("zbattle/blood_drop_metal.mp3", pos, math.random(10, 40), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
			end
		end
	else
		if !hg_old_blood:GetBool() then
			local howmuch = 1
			
			--timer.Simple(0.1, function()
				hg.bloodpositions[vec] = (hg.bloodpositions[vec] or 0) + 1
				
				sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", pos, math.random(10, 60), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
				if tr.MatType == MAT_METAL then
					sound.Play("zbattle/blood_drop_metal.mp3", pos, math.random(10, 40), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
				end

				if hg.bloodpositions[vec] <= BLOOD_DECALS_PER_POS then
					util.Decal("Normal.Blood2"..math.Clamp((hg.bloodpositions[vec] or 0) + math.random(0, 2), 1, 5), pos + normal, pos - normal, owner)
				end

				if hg.bloodpositions[vec] == BLOOD_POOL_DECAL_THRESHOLD then
					util.Decal("Blood", pos + normal, pos - normal, owner)
				end

			--end)
		else
			util.Decal("Normal.Blood1", pos + normal, pos - normal, owner)
			sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", pos, math.random(10, 60), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
			if tr.MatType == MAT_METAL then
				sound.Play("zbattle/blood_drop_metal.mp3", pos, math.random(10, 40), tr.MatType == MAT_METAL and math.random(100, 120) or math.random(80, 120))
			end
		end
	end
end
--fool, just look how much the entity costs in one place
local tr2 = { collisiongroup = COLLISION_GROUP_WORLD, output = {} }

function util.IsInWorld( pos )
	tr2.start = pos
	tr2.endpos = pos

	return not util.TraceLine( tr2 ).HitWorld
end

local gravity = GetConVar("sv_gravity")

local radius = 20000
local radiusSqr = radius * radius

hook.Add("InitPostEntity", "sizeget", function()
	radius = hg.GetWorldSize()
    radiusSqr = radius * radius
end)

bloodparticles_hook[2] = function(mul)
	local grav = gravity:GetInt() / 10
    local time = CurTime()
	local gravvec = vecDown * mul * (math.max(0.0, grav))
	local particleCount = #hg.bloodparticles1
	if particleCount > BLOOD_PARTICLE_HARD_CAP then
		for trim = particleCount, BLOOD_PARTICLE_HARD_CAP + 1, -1 do
			table_remove(hg.bloodparticles1, trim)
		end
	end
	for i = #hg.bloodparticles1, 1, -1 do
		local part = hg.bloodparticles1[i]
		if not part then table_remove(hg.bloodparticles1, i) continue end
		
		local pos = part[1]
		local posSet = part[2]

		tr.start = posSet
		tr.endpos = tr.start + part[3] * mul
		tr.collisiongroup = part.kishki and COLLISION_GROUP_WORLD or COLLISION_GROUP_NONE

		result = util_TraceLine(tr)
		local hitPos = result.HitPos
		
		if radiusSqr < hitPos:LengthSqr() then table_remove(hg.bloodparticles1, i) continue end
		
        if bit.band(util.PointContents(hitPos), CONTENTS_WATER) == CONTENTS_WATER then
			hg.addBloodPart2(hitPos, part[3] / 20 + VectorRand(-1, 1), nil, nil, nil, nil, true)

			table_remove(hg.bloodparticles1, i)
			continue
		end
		
		if time - part[7] >= 30 then
			table_remove(hg.bloodparticles1, i)

			continue
		end

		if result.Hit and result.Entity:IsWorld() then
			table_remove(hg.bloodparticles1, i)
			local dir = result.HitNormal
			decalBlood(result.HitPos, dir, result, part.artery, part.owner)
			
			
			--sound.Play("zbattle/blood_drop.mp3", hitPos, math.random(10, 60), math.random(120, 120))
			--sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", hitPos, math.random(10, 60), math.random(80, 120))
			
			continue
		else
			local ph = 0
			local shouldhit = true
			if IsValid(result.Entity) then
				ph = result.Entity:TranslatePhysBoneToBone(result.PhysicsBone)
				ph = ph != -1 and ph or 0
				local nam = result.Entity:GetBoneName(ph)
				
				shouldhit = !(result.Entity.organism and hg.amputatedlimbs2[nam] and result.Entity.organism[hg.amputatedlimbs2[nam].."amputated"])
			end
			
			result.Hit = result.Hit and shouldhit

			if result.Hit then
				--local down = vecDown * mul * (math.max(0, grav))
				local down = result.HitNormal
				local nextpos = (result.Normal + down):GetNormalized() * 5
				
				if !insolid and (part.nextput or 0) < CurTime() then
					part.nextput = CurTime() + 1

					decalBlood(result.HitPos, result.HitNormal, result, part.artery, part.owner)
				end

				local insolid = result.StartSolid and IsValid(result.Entity)
				if insolid then
					if result.Entity:IsVehicle() then
						table_remove(hg.bloodparticles1, i)
					
						continue
					end

					local center = result.Entity:GetBoneMatrix(ph)
					local len = result.Entity:BoneLength(ph + 1)

					if center then
						center = center:GetTranslation() + (len and center:GetAngles():Forward() * len or vector_origin) * 0.5
						nextpos = -(center - hitPos - vecDown * 1):GetNormalized() * 5
					end
				end

				local pulldown = (-vector_up * (grav / 600)):Cross(-result.HitNormal:Angle():Right())
				nextpos:Add(pulldown)
				part.lerpedmove = LerpVector(1, part.lerpedmove or part[3] * mul, nextpos * mul * 2)
				
				if part.lerpedmove:LengthSqr() < 0.1 * mul then
					decalBlood(result.HitPos, result.HitNormal, result, part.artery, part.owner)
					
					table_remove(hg.bloodparticles1, i)
					
					continue
				end

				pos:Set(posSet + part.start_velocity * mul)
				posSet:Set(hitPos + part.lerpedmove + part.start_velocity * mul)
				part.hashitsomething = true
			else
				if part.hashitsomething then
					part.hashitsomething = nil
					--part[3][3] = 0
					part[3] = (posSet - pos) / mul * 1--part.lerpedmove / mul
					--part.lerpedmove = nil
					pos:Set(posSet)
					posSet:Set(posSet)
				else
					pos:Set(posSet + part.start_velocity * mul)
					posSet:Set(tr.start + part[3] * mul + part.start_velocity * mul)
				end
			end

			part.lasthit = result.Hit
		end

		part[3] = LerpVector(0.25 * mul, part[3], vecZero)
		if !(result.Hit) then
			part[3]:Add(gravvec)
		--else
			--part[3]:Set(vecDown * mul * (math.max(0.1, grav)))
		end
	end
end

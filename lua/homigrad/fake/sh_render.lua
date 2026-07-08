local Angle, Vector, AngleRand, VectorRand, math, hook, util, game = Angle, Vector, AngleRand, VectorRand, math, hook, util, game
local IsValid, math_Clamp = IsValid, math.Clamp

--\\ Smooth UnRagdoll
	local vecSmall = Vector(0.01, 0.01, 0.01)
	function hg.SmoothUnfake(ent, ply)
		if ply.gettingup and (ply.gettingup + 1 - CurTime()) > 0 and IsValid(ply) then
			local model = ent.GetModel and ent:GetModel() or ""
			if ent.ZCHeadBoneRenderModel ~= model then
				ent.ZCHeadBoneRenderModel = model
				ent.ZCHeadBoneRender = nil
			end

			local headBone = ent.ZCHeadBoneRender
			if headBone == nil and ent.LookupBone then
				headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
				ent.ZCHeadBoneRender = headBone or false
			end
			headBone = headBone == false and nil or headBone
			local k = math_Clamp(1 - (ply.gettingup + 0.8 - CurTime()) / 0.8, 0, 1)
			local boneCount = ent:GetBoneCount()
			for i = 0, boneCount - 1 do
				local m1 = ent:GetBoneMatrix(i)
				local m2 = ply:GetBoneMatrix(i)

				if not m1 or not m2 then continue end

				local q1 = Quaternion()
				q1:SetMatrix(m1)

				local q2 = Quaternion()
				q2:SetMatrix(m2)

				local q3 = q1:SLerp(q2, k)

				local newmat = Matrix()
				newmat:SetTranslation(LerpVector(k, m1:GetTranslation(), m2:GetTranslation()))
				newmat:SetAngles(q3:Angle())
				newmat:SetScale(m1:GetScale())

				if i == headBone and lply == GetViewEntity() and lply == ply then
					newmat:SetScale(vecSmall)
					--ply.headm = newmat
				end

				ent:SetBoneMatrix(i, newmat)
				ply:SetBoneMatrix(i, newmat)
			end
		end
	end
--
--\\ DrawPlayerRagdoll
	local hg_ragdollcombat = ConVarExists("hg_ragdollcombat") and GetConVar("hg_ragdollcombat") or CreateConVar("hg_ragdollcombat", 0, FCVAR_REPLICATED, "Toggle ragdoll combat-like ragdoll mode (walking, running in ragdoll, etc.)", 0, 1)
	
	function hg.RagdollCombatInUse(ply)
		return hg_ragdollcombat:GetBool() and IsValid(ply.FakeRagdoll)
	end
	
	local hg_firstperson_ragdoll = ConVarExists("hg_firstperson_ragdoll") and GetConVar("hg_firstperson_ragdoll") or CreateConVar("hg_firstperson_ragdoll", "0", FCVAR_ARCHIVE, "Toggle first-person ragdoll camera view", 0, 1) --!! unused??
	local hg_firstperson_death = ConVarExists("hg_firstperson_death") and GetConVar("hg_firstperson_death") or CreateClientConVar("hg_firstperson_death", "0", true, false, "Toggle first-person death camera view", 0, 1)
	local hg_thirdperson = ConVarExists("hg_thirdperson") and GetConVar("hg_thirdperson") or CreateConVar("hg_thirdperson", 0, FCVAR_REPLICATED, "Toggle third-person camera view", 0, 1)
	local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro") or CreateClientConVar("hg_gopro", "0", true, false, "Toggle GoPro-like camera view", 0, 1)
	local hg_deathfadeout = CreateClientConVar("hg_deathfadeout", "1", true, true, "Toggle screen fade and sound mute on death", 0, 1)

	local vector_full = Vector(1, 1, 1)
	local vector_small = Vector(0.01, 0.01, 0.01)
	local FULL_POSE_RENDER_DIST_SQR = 1100 * 1100
	local ARMOR_RENDER_DIST_SQR = 1450 * 1450
	local DETAIL_RENDER_DIST_SQR = 2000 * 2000
	local angfuck = Angle()
	local function updateRenderBoundsForScale(ent, scale)
		if not ent.SetRenderBounds or not ent.OBBMins or not ent.OBBMaxs then return end

		local boundScale = math.max(scale, 1)
		local pad = 48 * boundScale
		local mins = ent:OBBMins() * boundScale - Vector(pad, pad, pad)
		local maxs = ent:OBBMaxs() * boundScale + Vector(pad, pad, pad)

		ent:SetRenderBounds(mins, maxs)
	end

	local function cachedRenderHeadBone(ent)
		if not IsValid(ent) or not ent.LookupBone then return end

		local model = ent:GetModel() or ""
		if ent.ZCHeadBoneRenderModel ~= model then
			ent.ZCHeadBoneRenderModel = model
			ent.ZCHeadBoneRender = nil
		end

		local headBone = ent.ZCHeadBoneRender
		if headBone == nil then
			headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
			ent.ZCHeadBoneRender = headBone or false
		end

		return headBone ~= false and headBone or nil
	end

	local hg_no_camera_in_cars = CreateConVar("hg_no_camera_in_cars","0",FCVAR_ARCHIVE + FCVAR_REPLICATED, "disables camera in cars", 0, 1)
	local function prepareRenderModelScale(ent, ply)
		if SERVER then return 1 end
		if not IsValid(ent) then return 1 end
		if not ent.IsRagdoll or not ent:IsRagdoll() then return 1 end

		local scale = 1
		if IsValid(ply) and ply.GetNWFloat then
			scale = ply:GetNWFloat("ZCModelScale", scale)
		end

		if scale == 1 and ent.GetNWFloat then
			scale = ent:GetNWFloat("ZCModelScale", scale)
		end

		scale = math_Clamp(tonumber(scale) or 1, 0.1, 10)
		if ent.ZCLastRenderModelScale == scale and ent.ZCLastRenderModelScaleMode == "bones" then return scale end

		ent.ZCLastRenderModelScale = scale
		ent.ZCLastRenderModelScaleMode = "bones"
		updateRenderBoundsForScale(ent, scale)

		if ent.DisableMatrix then
			ent:DisableMatrix("RenderMultiply")
		end

		return scale
	end

	local function applyBoneRenderScale(ent, scale)
		scale = tonumber(scale) or 1
		if scale == 1 or not ent.GetBoneCount or not ent.GetBoneMatrix or not ent.SetBoneMatrix then return end

		local origin = ent:GetPos()
		local scale_vector = Vector(scale, scale, scale)

		for bone = 0, ent:GetBoneCount() - 1 do
			local mat = ent:GetBoneMatrix(bone)
			if not mat then continue end

			local pos = mat:GetTranslation()
			mat:SetTranslation(origin + (pos - origin) * scale)

			local current_scale = mat:GetScale()
			if current_scale then
				mat:SetScale(current_scale * scale)
			else
				mat:SetScale(scale_vector)
			end

			ent:SetBoneMatrix(bone, mat)
		end
	end

	function DrawPlayerRagdoll(ent, ply) -- actually not only ragdoll render but player too
		if ply.prevragdoll_index != nil and ply.prevragdoll_index != ply.ragdoll_index and ply.ragdoll_index == 0 then
			--print(ply.ragdoll_index, ply.prevragdoll_index, Entity(ply.ragdoll_index))

			ply.gettingup = CurTime()
			ply.OldRagdoll = Entity(ply.prevragdoll_index)
			ply.FakeRagdollOld = ply.OldRagdoll
		end
		ply.prevragdoll_index = ply.ragdoll_index

		local wep = ply.GetActiveWeapon and ply:GetActiveWeapon()

		local lkp = cachedRenderHeadBone(ent)
		if !ent.GetManipulateBoneScale or !lkp then return end
		local renderModelScale = prepareRenderModelScale(ent, ply)

		local smoothingUnfake = IsValid(ply.OldRagdoll) and ply.gettingup and (ply.gettingup + 1 - CurTime()) > 0
		local distSqr = EyePos():DistToSqr(ent:GetPos())
		local criticalView = ply == lply or GetViewEntity() == ply or follow == ent or smoothingUnfake
		local fullPoseRender = criticalView or renderModelScale ~= 1 or distSqr <= FULL_POSE_RENDER_DIST_SQR
		local armorRender = criticalView or distSqr <= ARMOR_RENDER_DIST_SQR
		local detailRender = distSqr <= DETAIL_RENDER_DIST_SQR
		if smoothingUnfake then
			ply:SetupBones()
		end

		hg.RenderWeapons(ent, ply, distSqr, criticalView)

		if fullPoseRender then
			ent:SetupBones()
		end

		if fullPoseRender then
			hg.MainTPIKFunction(ent, ply, wep)
		end

		if smoothingUnfake and fullPoseRender then
			hg.SmoothUnfake(ent, ply)
		end

		if ply:GetNetVar("handcuffed", false) and fullPoseRender then hg.CuffedAnim(ent, ply) end
		if fullPoseRender then applyBoneRenderScale(ent, renderModelScale) end

		if fullPoseRender and IsValid(wep) then
			--if wep.isTPIKBase then hg.RenderTPIKBase(ent, ply, wep) end
			--if wep.ismelee then hg.RenderMelees(ent, ply, wep) end
			if wep.DrawWorldModel2 then wep:DrawWorldModel2() end
		end

		local armors = ply:GetNetVar("Armor") or ent.PredictedArmor
		local hideArmorRender = ply:GetNetVar("HideArmorRender", false) or ent.PredictedHideArmorRender
		if armorRender and armors and next(armors) and not hideArmorRender then
			RenderArmors(ply, armors, ent)
		end

		if detailRender then
			hg.RenderBandages(ent, ply)
			hg.RenderTourniquets(ent, ply)
		end

		if fullPoseRender then
			hg.GoreCalc(ent, ply)
		end

		--local current = ent:GetManipulateBoneScale(lkp)
		local fountains = GetNetVar("fountains") or {}
		local spectatorFirstPerson = !lply:Alive() and lply:GetNWEntity("spect") == ply and viewmode == 1
		local wawanted = (GetViewEntity() != ply) and !fountains[ent] and (!spectatorFirstPerson and !(hg_firstperson_death:GetBool() and follow == ent)) and vector_full or vector_small
		--print(ent, wawanted, GetViewEntity(), ply, (GetViewEntity() != ply), !fountains[ent], !(!lply:Alive() and lply:GetNWEntity("spect") == ply and viewmode == 1))
		--if !current:IsEqualTol(wawanted, 0.01) then
			--ent:ManipulateBoneScale(lkp, wawanted)
			if fullPoseRender then
    			local mat = ent:GetBoneMatrix(lkp)
    			if mat then
            	-- glide vehicle camera exclusion gate
            	local blockGlide = Glide and Glide.Camera and not Glide.Camera.isInFirstPerson and lply == ply and lply:InVehicle() and hg_no_camera_in_cars:GetBool()

        		if not blockGlide then
            		if ((!hg_thirdperson:GetBool() and !hg_gopro:GetBool() and (ent == ply or spectatorFirstPerson or (!hg_ragdollcombat:GetBool() or hg_firstperson_ragdoll:GetBool()))) or (hg_firstperson_death:GetBool() and follow == ent))
					then
                		mat:SetScale(wawanted)
            		end
        		end

        		hg.bone_apply_matrix(ent, lkp, mat)
    		end
		end
		--end

		--hg.CoolGloves(ent, ply, wep)

		if detailRender then
			hg.ProjectilesDraw(ent, ply)
		end

		if detailRender and ply:GetNetVar("headcrab") then hg.RenderHeadcrab(ent, ply) end
	end
--

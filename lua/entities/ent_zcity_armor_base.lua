--[[             z...
    /\___/\    z
    | _ _ |  Z
   /|__-__|\            support us pls
   \--|-|--/        he sleepyhead! :3
--]]
DEFINE_BASECLASS( "ent_zcity_equipment_base" )	
AddCSLuaFile()
--[[ Armor Slots
    ZC_ARMOR_SLOT_HEAD = 4
    ZC_ARMOR_SLOT_FACE = 5
        ZC_ARMOR_SLOT_EYES = 6
    ZC_ARMOR_SLOT_EARS = 7

    ZC_ARMOR_SLOT_TORSO = 8
        ZC_ARMOR_SLOT_UPPERARM_L = 9
            ZC_ARMOR_SLOT_FOREARM_L = 10
        ZC_ARMOR_SLOT_UPPERARM_R = 11
            ZC_ARMOR_SLOT_FOREARM_R = 12  

    ZC_ARMOR_SLOT_BELLY = 13

    ZC_ARMOR_SLOT_PELVIS = 14
        ZC_ARMOR_SLOT_THIGH_L = 15
            ZC_ARMOR_SLOT_SHIN_L = 16
        ZC_ARMOR_SLOT_THIGH_R = 17
            ZC_ARMOR_SLOT_SHIN_R = 18
--]]
ENT.Type = "anim"
ENT.Base = "ent_zcity_equipment_base"
ENT.PrintName = "Armor base"
ENT.Category = "ZCity TestArmor"
ENT.Spawnable = false
ENT.Model = nil--"models/jworld_equipment/kevlar.mdl"
ENT.ModelMaterial = nil--"sal/acc/armor01_2"
ENT.IconOverride = nil--"vgui/icons/armor02"
ENT.IsZPickup = true

ENT.SlotOccupation = { -- Slots what armor occupate
    --[ZC_ARMOR_SLOT_TORSO] = true,
}
--\\ Balistic settings

--\\ HitBoxSets HitboxCreation
    ENT.HitBoxSet = "TestVest"

    local TestVest = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "TestVest", 1, Vector(1.5, 7, 0), Angle(0, -4, 0), Vector(7.5, 1, 6), Color(0, 17, 255), true)
    hg.organism:CreateHitBox("Front",TestVest) 

    local TestVest = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "TestVest", 1, Vector(1.5, -3, 0), Angle(0, 0, 0), Vector(8, 1, 6), Color(0, 17, 255), true)
    hg.organism:CreateHitBox("Back",TestVest) 

    local TestVest = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "TestVest", 1, Vector(-3.5, 2.5, 6.5), Angle(0, 0, 90), Vector(3, 1, 4.5), Color(0, 17, 255), true)
    hg.organism:CreateHitBox("LeftSide",TestVest) 

    local TestVest = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "TestVest", 1, Vector(-3.5, 2.5, -6.5), Angle(0, 0, 90), Vector(3, 1, 4.5), Color(0, 17, 255), true)
    hg.organism:CreateHitBox("RightSide",TestVest) 

    hg.organism:AddArmorInputList("TestVest", ZC_ARMOR_SLOT_TORSO)
--//

ENT.Protection = ZC_ARMOR_PROTCLASS_III_PLUS    -- protection class
    --\\ Protection classes
        -- ZC_ARMOR_PROTCLASS_II = 4
        -- ZC_ARMOR_PROTCLASS_IIIA = 8
        -- ZC_ARMOR_PROTCLASS_III = 12
        -- ZC_ARMOR_PROTCLASS_III_PLUS = 16
        -- ZC_ARMOR_PROTCLASS_IV = 22
ENT.ProtectionDamageMul = 0.6                   -- protected damage mul
ENT.PenetratedDamageMul = 0.8                   -- penetrated damage mul

ENT.BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
    --\\ BalisticMaterials
        -- ZC_ARMOR_MATERIAL_CERAMIC = 3
        -- ZC_ARMOR_MATERIAL_TITAN = 1.8
        -- ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

        -- ZC_ARMOR_MATERIAL_KEVLAR = 0.9
        -- ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
        -- ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
        -- ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
ENT.Durability = 100                            -- durability
ENT.DurabilityMax = 100                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
ENT.DurabilityWarranty = 15                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

ENT.NeedPunch = false                           -- viewpunch after impact
--//

--\\
ENT.PlateLinks = {
    -- FrontDown = "FrontPlate"
    -- etc
}

--[[
    ENT.FrontPlate = {}
    ENT.FrontPlate.Protection = ZC_ARMOR_PROTCLASS_II
        --\\ Protection classes
            -- ZC_ARMOR_PROTCLASS_II = 4
            -- ZC_ARMOR_PROTCLASS_IIIA = 8
            -- ZC_ARMOR_PROTCLASS_III = 12
            -- ZC_ARMOR_PROTCLASS_III_PLUS = 16
            -- ZC_ARMOR_PROTCLASS_IV = 22
    ENT.FrontPlate.ProtectionDamageMul = 0.6                   -- protected damage mul
    ENT.FrontPlate.PenetratedDamageMul = 0.8                   -- penetrated damage mul

    ENT.FrontPlate.BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        --\\ BalisticMaterials
            -- ZC_ARMOR_MATERIAL_CERAMIC = 3
            -- ZC_ARMOR_MATERIAL_TITAN = 1.8
            -- ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

            -- ZC_ARMOR_MATERIAL_KEVLAR = 0.9
            -- ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
            -- ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
            -- ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
    ENT.FrontPlate.Durability = 100                            -- durability
    ENT.FrontPlate.DurabilityMax = 100                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
    ENT.FrontPlate.DurabilityWarranty = 15                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

    ENT.FrontPlate.NeedPunch = false 
--]]
--//

--\\ Render male model
ENT.Male = {}
ENT.Male.Model = "models/lightvest/lightvest.mdl"
ENT.Male.ModelSubMaterials = {}                 -- submaterials on rendered model
ENT.Male.HideSubMaterails = {}                  -- playermodel hide submaterials
ENT.Male.Skin = 0                               -- skin on rendered model
ENT.Male.Bodygroups = "0000000000000"           -- bodygroups on rendered model
--
ENT.Male.BoneMerge = false
ENT.Male.ParentBone = "ValveBiped.Bip01_Spine2" -- parent bone
ENT.Male.OffsetPos = Vector(-9.8,3.5,0)
ENT.Male.OffsetAng = Angle(0,88,90)
ENT.Male.ModelSize = 0.92
--//

--\\ Render female model
ENT.FeMale = {}
ENT.FeMale.Model = "models/lightvest/lightvest.mdl"
ENT.FeMale.ModelSubMaterials = {}                 -- submaterials on rendered model
ENT.FeMale.HideSubMaterails = {}                  -- playermodel hide submaterials
ENT.FeMale.Skin = 0                               -- skin on rendered model
ENT.FeMale.Bodygroups = "0000000000000"           -- bodygroups on rendered model
--
ENT.FeMale.BoneMerge = false
ENT.FeMale.ParentBone = "ValveBiped.Bip01_Spine2" -- parent bone
ENT.FeMale.OffsetPos = Vector(-9.1,2.5,0)
ENT.FeMale.OffsetAng = Angle(0,90,90)
ENT.FeMale.ModelSize = 0.8
--//

ENT.PhysicsSounds = true
local vec30 = Vector(0,0,30)
function ENT:Initialize()
    BaseClass.Initialize( self )
    self:SetPos(self:GetPos() + vec30)
    self:SetMaterial(self.ModelMaterial)
end
ENT.EquipSound = "snd_jack_hmcd_disguise.wav"
ENT.UnEquipSound = "snd_jack_hmcd_disguise.wav"
function ENT:Use(entUser)
    BaseClass.Use( self, entUser )

    self:EmitSound(self.EquipSound, 60, math.random(95,105), 1, CHAN_AUTO)
end

function ENT:OnUnwear()

    self:EmitSound(self.UnEquipSound, 55, math.random(95,105), 1, CHAN_AUTO)
end

function ENT:DrawOverlay()
end

function ENT:Draw()
    if self:GetMoveType() == MOVETYPE_NONE or self.GetEquiped and self:GetEquiped() then self:DrawShadow(false) return end
    if IsValid(self.renderModel) then self.renderModel:Remove() end
    self:DrawModel()
end

function ENT:RenderModifyPosAng(entDrawOn, pos, ang)

end

--\\ Render Equipment
    local developer = GetConVar("developer")
    ENT.ShouldRenderLocaly = true
    local vec = Vector(1,1,1)
    function ENT:RenderOnBody(entDrawOn)
        local fem = ThatPlyIsFemale(entDrawOn)
        local ply = hg.RagdollOwner(entDrawOn) or entDrawOn:IsPlayer() and entDrawOn or nil
        if !self.ShouldRenderLocaly and IsValid(ply) and !ply:IsLocal() then return end
        if !IsValid(self.renderModel) then
            local data = fem and self.FeMale or self.Male
            self.renderModel = ClientsideModel(data.Model, RENDERGROUP_BOTH)

            local model = self.renderModel
            model:SetNoDraw(true)
            model:SetSkin(data.Skin)
            model:SetBodyGroups(data.Bodygroups)
            model:SetParent(entDrawOn)
            --print(data.BoneMerge)
            if data.BoneMerge then
                model:AddEffects(EF_BONEMERGE)
            else
                model.ParentBone = entDrawOn:LookupBone( data.ParentBone ) 
                model.OffsetPos = data.OffsetPos
                model.OffsetAng = data.OffsetAng
                model:SetModelScale(data.ModelSize)
            end
            

            if data.ModelSubMaterials then
                for k,v in pairs(data.ModelSubMaterials) do
                    local id = isnumber(k) and k or model:GetSubMaterialIdByName(k)
                    if !id then continue end
                    model:SetSubMaterial(id, v)
                end
            end

            self:CallOnRemove("RemoveEquip",function()
                if IsValid(self.renderModel) then
                    model:Remove()
                    model = nil
                end
            end)
        end

        local model = self.renderModel

        local mdl = string.Split(string.sub(entDrawOn:GetModel(),1,-5),"/")[#string.Split(string.sub(entDrawOn:GetModel(),1,-5),"/")]
        if mdl and model:GetFlexIDByName(mdl) then
            model:SetFlexWeight(model:GetFlexIDByName(mdl),1)
        end

        if model:GetParent() != entDrawOn then model:SetParent(entDrawOn) end

        if model.ParentBone then
            if developer:GetBool() then
                local data = fem and self.FeMale or self.Male
                model.ParentBone = entDrawOn:LookupBone( data.ParentBone ) 
                model.OffsetPos = data.OffsetPos
                model.OffsetAng = data.OffsetAng

                model:SetModelScale(data.ModelSize)
            end
            local matBone = entDrawOn:GetBoneMatrix(model.ParentBone)
            local pos = matBone:GetTranslation()
            local ang = matBone:GetAngles()

            pos,ang = LocalToWorld(model.OffsetPos, model.OffsetAng, pos, ang)

            self:RenderModifyPosAng(entDrawOn, pos, ang)
            model:SetPos(pos)
            model:SetAngles(ang)

            model:SetRenderOrigin(pos)
            model:SetRenderAngles(ang)
        end        
        
        model:DrawModel()
    end
--//

--\\
    function ENT:OnWearNetVars(entUser)
		local EquipmentBySlot = entUser:GetNetVar("zc_equipment_by_hitbox", {})

        EquipmentBySlot[self.HitBoxSet] = self:EntIndex()
        
        entUser:SetNetVar("zc_equipment_by_hitbox", EquipmentBySlot)
	end

    function ENT:OnUnwearNetVars(entUser)
		local EquipmentBySlot = entUser:GetNetVar("zc_equipment_by_hitbox", {})

        EquipmentBySlot[self.HitBoxSet] = nil
        
        entUser:SetNetVar("zc_equipment_by_hitbox", EquipmentBySlot)
	end
--//

--\\ Utilites
local entMeta = FindMetaTable("Entity") 
function entMeta:GetEquipmentByHitBoxSet(hitboxset)
    if not IsValid(self) then return end
    local EquipmentBySlot = self:GetNetVar("zc_equipment_by_hitbox",{})
    
    return EquipmentBySlot[hitboxset] and Entity(EquipmentBySlot[hitboxset]) or nil
end

hook.Add("ItemsTransfered", "TransferEquipmentArmor", function(ply, ragdoll)
    local Equipment = ply:GetNetVar("zc_equipment_by_hitbox", {})
    if table.Count(Equipment) < 1 then return end

    ragdoll:SetNetVar("zc_equipment_by_hitbox",Equipment)
    ply:SetNetVar("zc_equipment_by_hitbox", {})
end)

hook.Add("HG_OrganAvalible", "ArmorHitboxAvaliveCheck", function(ent, organ_name) 
    return IsValid( ent:GetEquipmentByHitBoxSet(organ_name) )
end)

--[[
    hg.organism.input_list.vest1 = function(org, bone, dmg, dmgInfo, ...)
        local protect = protec(org, bone, dmg, dmgInfo, "torso", "vest1", 0.6, 0.6, false, ...)
        return protect
    end
--]]

--[[

local ArmorEffect
local force
local function protec(org, bone, dmg, dmgInfo, placement, armor, scale, scaleprot, punch, boneindex, dir, hit, ricochet)
	if not force and org.owner.armors[placement] ~= armor then return 0 end
	force = nil
	
	local prot = placement and hg.armor[placement] and armor and hg.armor[placement][armor] and (hg.armor[placement][armor].protection - (dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1)) or (10 - ( dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1))
	
	org.owner.armors_health = org.owner.armors_health or {}

	prot = prot * (org.owner.armors_health[armor] or 1)
	
	if punch then
		if org.owner:IsPlayer() and org.alive and dmgInfo:IsDamageType(DMG_BUCKSHOT + DMG_BULLET) then
			org.owner:ViewPunch(AngleRand(-30, 30))
			
			org.owner:EmitSound("homigrad/physics/shield/bullet_hit_shield_0"..math.random(7)..".wav", 80, math.random(95, 105))

			org.owner:AddTinnitus(3, true)
			net.Start("AddFlash")
				net.WriteVector(hg.eye(org.owner) + org.owner:GetForward() * 3)
				net.WriteFloat(3)
				net.WriteInt(100, 20)
			net.Send(org.owner)

			hg.ExplosionDisorientation(org.owner, 6, 6)

			hg.organism.input_list.spine3(org, bone, (dmg/100) * math.Rand(0,0.1), dmgInfo)
			--org.spine3 = org.spine3 + math.Rand(0.05,1) * dmg / 5
		end
	end
	
	scale = scale * (dmgInfo:IsDamageType(DMG_SLASH) and 0.1 or 1)
	
	ArmorEffect(placement, armor, dmgInfo, org, hit, prot)

	if prot < 0 then
		//dmgInfo:ScaleDamage(scale)
		return 0
	end

	dmgInfo:SetDamageType(DMG_CLUB)
	dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * 0.4)
	dmgInfo:ScaleDamage(0.2)

	return 0.9
end

ArmorEffect = function(placement, armor, dmgInfo, org, hit, prot)
	local armdata = placement and hg.armor[placement] and hg.armor[placement][armor] or {}
	local eff = prot < 0 and "Impact" or armdata.effect or "Impact"
	local dir = -dmgInfo:GetDamageForce()
	dir:Normalize()
	local effdata = EffectData()
	
	effdata:SetOrigin((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) - dir)
	effdata:SetNormal(dir)
	effdata:SetMagnitude(0.25)
	effdata:SetRadius(4)
	effdata:SetNormal(dir)
	effdata:SetStart((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) + dir)
	effdata:SetEntity(org.owner)
	effdata:SetSurfaceProp(prot < 0 and 67 or armdata.surfaceprop or 67)
	effdata:SetDamageType(dmgInfo:GetDamageType())

	EmitSound("physics/metal/metal_solid_impact_bullet"..math.random(4)..".wav",dmgInfo:GetDamagePosition(),0,CHAN_AUTO,1,55,nil,100)
	util.Effect(eff,effdata)
end

local ArmorEffectEx = function(ent,dmgInfo,eff,surfaceprop)
	local dir = -dmgInfo:GetDamageForce()
	dir:Normalize()
	local effdata = EffectData()
	
	effdata:SetOrigin( dmgInfo:GetDamagePosition() - dir )
	effdata:SetNormal( dir )
	effdata:SetMagnitude(0.25)
	effdata:SetRadius(4)
	effdata:SetNormal(dir)
	effdata:SetStart(dmgInfo:GetDamagePosition() + dir)
	effdata:SetEntity(ent)
	effdata:SetSurfaceProp(surfaceprop or 67)
	effdata:SetDamageType(dmgInfo:GetDamageType())

	EmitSound("physics/metal/metal_solid_impact_bullet"..math.random(4)..".wav",dmgInfo:GetDamagePosition(),0,CHAN_AUTO,1,55,nil,100)
	util.Effect(eff,effdata)
end

--]]

--//

--\\ Armor Slots
    -- ZC_ARMOR_SLOT_HEAD = 4
    -- ZC_ARMOR_SLOT_FACE = 5
    --     ZC_ARMOR_SLOT_EYES = 6
    -- ZC_ARMOR_SLOT_EARS = 7

    -- ZC_ARMOR_SLOT_TORSO = 8
    --     ZC_ARMOR_SLOT_UPPERARM_L = 9
    --         ZC_ARMOR_SLOT_FOREARM_L = 10
    --     ZC_ARMOR_SLOT_UPPERARM_R = 11
    --         ZC_ARMOR_SLOT_FOREARM_R = 12  

    -- ZC_ARMOR_SLOT_BELLY = 13

    -- ZC_ARMOR_SLOT_PELVIS = 14
    --     ZC_ARMOR_SLOT_THIGH_L = 15
    --         ZC_ARMOR_SLOT_SHIN_L = 16
    --     ZC_ARMOR_SLOT_THIGH_R = 17
    --         ZC_ARMOR_SLOT_SHIN_R = 18
--//

if not load_from_armor_file then return end -- i'm sorry for that, but that way light than create Entity registration module
DEFINE_BASECLASS("ent_zcity_armor_base")
local ENT = {}
ENT.Type = "anim"
ENT.Base = "ent_zcity_armor_base"
ENT.PrintName = "NVG GPNVG 18"
ENT.Category = "ZCity TestArmor"
ENT.Spawnable = true
ENT.Model = "models/arctic_nvgs/nvg_gpnvg.mdl"
ENT.IconOverride = "vgui/icons/nvg"
ENT.SlotOccupation = {                              -- Slots what armor occupate
    [ZC_ARMOR_SLOT_EYES] = true,
}
ENT.ShouldRenderLocaly = false

ENT.Overlay = {}
ENT.Overlay.PosAdjust = Vector(-2,0,-2)
ENT.Overlay.AngAdjust = Angle(0,0,0)
ENT.Overlay.Fov = 0
ENT.Overlay.ModelMaterial = nil
ENT.Overlay.Model = "models/arctic_nvgs/nvg_gpnvg.mdl"

ENT.OverlayMaterial = Material("overlays/nvg_scene_opticf2.png")
ENT.LightFOV = 45
ENT.Brightness = .02
ENT.BlurAmmout = 0.02

function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)

    self:NetworkVar( "Bool", "Enabled" )
    self:NetworkVar( "Float", "BlurAfterNVG" )
    if SERVER then
        self:SetEnabled(false)
        self:SetBlurAfterNVG(0)
    end
end
local color_black = Color(0,0,0)
local hookadded = false
local bluring = 0
function ENT:Think()
    local BlurAfterNVG = self:GetBlurAfterNVG()
    if CLIENT and BlurAfterNVG > 0 then
        hookadded = true
        hook.Add("Post Pre Post Processing","renderblurNvg",function()
            local color = color_black
            color.a = bluring*55
            if !lply:IsLocal() then
                draw.RoundedBox(0,-1,-1,ScrW()+2, ScrH()+2,color)
            end
            bluring = LerpFT( 0.1, bluring, BlurAfterNVG)
            if BlurAfterNVG <= 0.01 or IsValid(lply.EZNVGlamp) then
                hook.Remove("Post Pre Post Processing","renderblurNvg")
                hookadded = false
            end
        end)
    elseif SERVER and BlurAfterNVG > 0.005 then
        self:SetBlurAfterNVG(LerpFT( 0.2, BlurAfterNVG, 0))
    end
end

function ENT:RenderModifyPosAng(entDrawOn, pos, ang)
    self.EnabledRot = LerpFT(0.2, self.EnabledRot or 0, !self:GetEnabled(false) and 25 or 0)
    ang:RotateAroundAxis(ang:Right(), self.EnabledRot)
end

function ENT:Enable(ply)
    ply:ViewPunch(Angle(2,0,0))

    hg.RunZManipAnim( ply, "visordown", self:GetEnabled(), self:GetEnabled() and 1.5 or 1.5 )
	timer.Simple(0.4,function()
		if not IsValid(ply) then return end
        timer.Simple(0.2,function()
            self:SetEnabled(not self:GetEnabled(false))
        end)
        self:SetBlurAfterNVG(8)

        self:EmitSound("universal/uni_crawl_r_04.wav",60,math.random(90,110),1,CHAN_AUTO)
	end)
end

ENT.DrawOverlay = RenderNVGOverlay
--\\ Balistic settings                              -- soon can be enchanced, per plate material, durability and other stuff

--\\ HitBoxSets Hitbox Creation
    local HitBoxSet = "new_nvg1"
    ENT.HitBoxSet = HitBoxSet                     -- you can use same hitbox sets on other armor
    --\\ Plates HitBoxSets
        local color_yellow = Color(255,102,0)
        -- Box
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Head1", HitBoxSet, 1, Vector(4.5, -9, 0), Angle(0, 90, 0), Vector(2, 1, 5), color_yellow, true)
            hg.organism:CreateHitBox("Front",HitBox, HitBoxF)
        --//
    --//
    hg.organism:AddArmorInputList(HitBoxSet, ZC_ARMOR_SLOT_HEAD)
--//
    --\\ Plates
    local FP = "Box"

    ENT.PlatesLinks = { -- this is links to armor, table down here, key is name of UID HitBox, value is string link ["FrontPlate"] etc.
        Front =         FP,
    }

    --\\ FrontPlate
        ENT[FP] = {}
        ENT[FP].Protection = ZC_ARMOR_PROTCLASS_II
            --\\ Protection classes
                -- ZC_ARMOR_PROTCLASS_II = 4
                -- ZC_ARMOR_PROTCLASS_IIIA = 8
                -- ZC_ARMOR_PROTCLASS_III = 12
                -- ZC_ARMOR_PROTCLASS_III_PLUS = 16
                -- ZC_ARMOR_PROTCLASS_IV = 22
        ENT[FP].ProtectionDamageMul = 0.6                   -- protected damage mul
        ENT[FP].PenetratedDamageMul = 0.9                   -- penetrated damage mul

        ENT[FP].BalisticMaterial = ZC_ARMOR_MATERIAL_UHMWPE -- actually this is just a mul of degradation armor
            --\\ BalisticMaterials
                -- ZC_ARMOR_MATERIAL_CERAMIC = 3
                -- ZC_ARMOR_MATERIAL_TITAN = 1.8
                -- ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

                -- ZC_ARMOR_MATERIAL_KEVLAR = 0.9
                -- ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
                -- ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
                -- ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
        ENT[FP].Durability = 20                            -- durability
        ENT[FP].DurabilityMax = 20                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[FP].DurabilityWarranty = 0                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[FP].NeedPunch = true                           -- viewpunch after impact
    --//       
--//

--\\ Render male model
ENT.Male = {}
ENT.Male.Model = "models/arctic_nvgs/nvg_gpnvg.mdl"
ENT.Male.ModelSubMaterials = {}                     -- submaterials on rendered model
ENT.Male.HideSubMaterails = {}                      -- playermodel hide submaterials
ENT.Male.Skin = 0                                   -- skin on rendered model
ENT.Male.Bodygroups = "0000000000000"               -- bodygroups on rendered model
--
ENT.Male.BoneMerge = false
ENT.Male.ParentBone = "ValveBiped.Bip01_Head1"     -- parent bone
ENT.Male.OffsetPos = Vector(1,-1,0)
ENT.Male.OffsetAng = Angle(0,280,-90)
ENT.Male.ModelSize = 1
--//

--\\ Render female model
ENT.FeMale = {}
ENT.FeMale.Model = "models/arctic_nvgs/nvg_gpnvg.mdl"
ENT.FeMale.ModelSubMaterials = {}                   -- submaterials on rendered model
ENT.FeMale.HideSubMaterails = {}                    -- playermodel hide submaterials
ENT.FeMale.Skin = 0                                 -- skin on rendered model
ENT.FeMale.Bodygroups = "0000000000000"             -- bodygroups on rendered model
--
ENT.FeMale.BoneMerge = false
ENT.FeMale.ParentBone = "ValveBiped.Bip01_Head1"   -- parent bone
ENT.FeMale.OffsetPos = Vector(0.2,-1,0)
ENT.FeMale.OffsetAng = Angle(0,280,-90)
ENT.FeMale.ModelSize = 0.95
--//
local filename = string.StripExtension(string.GetFileFromFilename( GetCurrentLuaFile() ))
scripted_ents.Register(ENT, filename)
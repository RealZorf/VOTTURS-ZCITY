
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
ENT.PrintName = "Kevlar-Plate III Vest"
ENT.Category = "ZCity TestArmor"
ENT.Spawnable = true
ENT.Model = "models/jworld_equipment/kevlar.mdl"
ENT.ModelMaterial = "models/lightvest/accs_diff_000_a_uni"
ENT.IconOverride = "vgui/icons/armor02"
ENT.SlotOccupation = {                              -- Slots what armor occupate
    [ZC_ARMOR_SLOT_TORSO] = true,
    [ZC_ARMOR_SLOT_BELLY] = true,
}

--\\ Balistic settings                              -- soon can be enchanced, per plate material, durability and other stuff

--\\ HitBoxSets Hitbox Creation
    local HitBoxSet = "new_vest4"
    ENT.HitBoxSet = HitBoxSet                     -- you can use same hitbox sets on other armor
    --\\ Plates HitBoxSets
        local color_blue = Color(0,140,255)
        local color_yellow = Color(255,238,0)
        -- Fornt Kevlar
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2, 7.5, 0), Angle(0, -10, 0), Vector(7.5, 1.5, 5.5), color_blue, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-0.5, 6.5, 0), Angle(0, 0, 0), Vector(7.5, 1.5, 5.5), color_blue, true)
            hg.organism:CreateHitBox("Front",HitBox, HitBoxF)
        --//

        -- Fornt Plate
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, 7, 0), Angle(0, -4, 0), Vector(3, 1, 3.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, 6.5, 0), Angle(0, 0, 0), Vector(3, 1, 3.5), color_yellow, true)
            hg.organism:CreateHitBox("FrontPlate",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(0, 7.5, 0), Angle(0, -4, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-3, 6.5, 0), Angle(0, 0, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            hg.organism:CreateHitBox("FrontPlateDown",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, 7, -2.9), Angle(-18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, 6.5, -2.9), Angle(-18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("FrontPlateRight",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, 7, 2.9), Angle(18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, 6.5, 2.9), Angle(18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("FrontPlateLeft",HitBox, HitBoxF)
        --//

        -- Back Kevlar
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.4, -3, 0), Angle(0, 0, 0), Vector(7.9, 1.5, 5.5), color_blue, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(0.5, -3.5, 0), Angle(0, 0, 0), Vector(7.5, 1.5, 5.5), color_blue, true)
            hg.organism:CreateHitBox("Back", HitBox, HitBoxF)
        --//

        -- Back Plate
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, -3, 0), Angle(0, 0, 0), Vector(3, 1, 3.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, -3.5, 0), Angle(0, 0, 0), Vector(3, 1, 3.5), color_yellow, true)
            hg.organism:CreateHitBox("BackPlate",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(0, -3, 0), Angle(0, 0, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-3, -3.5, 0), Angle(0, 0, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            hg.organism:CreateHitBox("BackPlateDown",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, -3, -2.9), Angle(-18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, -3.5, -2.9), Angle(-18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("BackPlateRight",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(5.8, -3, 2.9), Angle(18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(2.8, -3.5, 2.9), Angle(18, 0, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("BackPlateLeft",HitBox, HitBoxF)
        --//

        -- Side Kevlar (kevlar... but soon)
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-0.5, 2.5, 6), Angle(0, 5, 90), Vector(4.5, 1, 5), color_blue, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-3, 1, 6), Angle(0, 5, 90), Vector(4.5, 1, 5), color_blue, true)
            hg.organism:CreateHitBox("LeftSide",HitBox, HitBoxF)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-0.5, 2.5, -6), Angle(0, 5, 90), Vector(4.5, 1, 5), color_blue, true)
            local HitBoxF = hg.organism:HitBox("ValveBiped.Bip01_Spine2", HitBoxSet, 1, Vector(-3, 1, -6), Angle(0, 5, 90), Vector(4.5, 1, 5), color_blue, true)
            hg.organism:CreateHitBox("RightSide",HitBox, HitBoxF)
        --//
    --//
    hg.organism:AddArmorInputList(HitBoxSet, ZC_ARMOR_SLOT_TORSO)
--//

    --\\ Plates
    local FP = "FrontPlate"
    local BP = "BackPlate"
    local FK = "FrontKevlar"
    local BK = "BackKevlar"
    local LK = "LeftKevlar"
    local RK = "RightKevlar"

    ENT.PlatesLinks = { -- this is links to armor, table down here, key is name of UID HitBox, value is string link ["FrontPlate"] etc.
        Front =         FK,

        FrontPlate =    FP,
        FrontPlateDown =FP,
        FrontPlateRight=FP,
        FrontPlateLeft= FP,

        Back =          BK,

        BackPlate =     BP,
        BackPlateDown = BP,
        BackPlateRight= BP,
        BackPlateLeft=  BP,

        LeftSide =      LK,
        RightSide =     RK
    }

    ENT.SideLinks = {                 -- for penetration damage type change, cuz i don't want rewrite organism hitbox system fully
        Front =         "Front",
        FrontPlate =    "Front",
        FrontPlateDown ="Front",
        FrontPlateRight="Front",
        FrontPlateLeft= "Front",

        Back =          "Back",
        BackPlate =     "Back",
        BackPlateDown = "Back",
        BackPlateRight= "Back",
        BackPlateLeft=  "Back",

        LeftSide =      "Left",
        RightSide =     "Right"
    }

    --\\ FrontKevlar
        ENT[FK] = {}
        ENT[FK].Protection = ZC_ARMOR_PROTCLASS_IIIA
            --\\ Protection classes
                -- ZC_ARMOR_PROTCLASS_II = 4
                -- ZC_ARMOR_PROTCLASS_IIIA = 8
                -- ZC_ARMOR_PROTCLASS_III = 12
                -- ZC_ARMOR_PROTCLASS_III_PLUS = 16
                -- ZC_ARMOR_PROTCLASS_IV = 22
        ENT[FK].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[FK].PenetratedDamageMul = 0.8                      -- penetrated damage mul

        ENT[FK].BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
            --\\ BalisticMaterials
                -- ZC_ARMOR_MATERIAL_CERAMIC = 3
                -- ZC_ARMOR_MATERIAL_TITAN = 1.8
                -- ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

                -- ZC_ARMOR_MATERIAL_KEVLAR = 0.9
                -- ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
                -- ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
                -- ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
        ENT[FK].Durability = 60                            -- durability
        ENT[FK].DurabilityMax = 60                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[FK].DurabilityWarranty = 25                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[FK].NeedPunch = false                           -- viewpunch after impact
    --//
    
    --\\ FrontPlate
        ENT[FP] = {}
        ENT[FP].Protection = ZC_ARMOR_PROTCLASS_III
        ENT[FP].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[FP].PenetratedDamageMul = 0.6                   -- penetrated damage mul

        ENT[FP].BalisticMaterial = ZC_ARMOR_MATERIAL_ARSTEEL -- actually this is just a mul of degradation armor
        ENT[FP].Durability = 90                            -- durability
        ENT[FP].DurabilityMax = 90                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[FP].DurabilityWarranty = 55                    -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[FP].NeedPunch = false                           -- viewpunch after impact
    --//
    
    --\\ BackKevlar
        ENT[BK] = {}
        ENT[BK].Protection = ZC_ARMOR_PROTCLASS_IIIA
        ENT[BK].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[BK].PenetratedDamageMul = 0.6                   -- penetrated damage mul

        ENT[BK].BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT[BK].Durability = 60                            -- durability
        ENT[BK].DurabilityMax = 60                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[BK].DurabilityWarranty = 25                    -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[BK].NeedPunch = false                           -- viewpunch after impact
    --// 
    
    --\\ BackPlate
        ENT[BP] = {}
        ENT[BP].Protection = ZC_ARMOR_PROTCLASS_IV
        ENT[BP].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[BP].PenetratedDamageMul = 0.8                   -- penetrated damage mul

        ENT[BP].BalisticMaterial = ZC_ARMOR_MATERIAL_ARSTEEL -- actually this is just a mul of degradation armor
        ENT[BP].Durability = 90                            -- durability
        ENT[BP].DurabilityMax = 90                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[BP].DurabilityWarranty = 55                    -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[BP].NeedPunch = false                           -- viewpunch after impact
    --//

    --\\ LeftKevlar
        ENT[LK] = {}
        ENT[LK].Protection = ZC_ARMOR_PROTCLASS_IIIA
        ENT[LK].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[LK].PenetratedDamageMul = 0.8                   -- penetrated damage mul

        ENT[LK].BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT[LK].Durability = 25                            -- durability
        ENT[LK].DurabilityMax = 25                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[LK].DurabilityWarranty = 20                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[LK].NeedPunch = false                           -- viewpunch after impact
    --//  

    --\\ RightKevlar
        ENT[RK] = {}
        ENT[RK].Protection = ZC_ARMOR_PROTCLASS_IIIA
        ENT[RK].ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT[RK].PenetratedDamageMul = 0.8                   -- penetrated damage mul

        ENT[RK].BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT[RK].Durability = 25                            -- durability
        ENT[RK].DurabilityMax = 25                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT[RK].DurabilityWarranty = 20                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT[RK].NeedPunch = false                           -- viewpunch after impact
    --//  
--//

--\\ Render male model
ENT.Male = {}
ENT.Male.Model = "models/lightvest/lightvest.mdl"
ENT.Male.ModelSubMaterials = {}                     -- submaterials on rendered model
ENT.Male.HideSubMaterails = {}                      -- playermodel hide submaterials
ENT.Male.Skin = 0                                   -- skin on rendered model
ENT.Male.Bodygroups = "0000000000000"               -- bodygroups on rendered model
--
ENT.Male.BoneMerge = false
ENT.Male.ParentBone = "ValveBiped.Bip01_Spine2"     -- parent bone
ENT.Male.OffsetPos = Vector(-8, 3.2, 0)
ENT.Male.OffsetAng = Angle(0,90,90)
ENT.Male.ModelSize = 0.86
--//

--\\ Render female model
ENT.FeMale = {}
ENT.FeMale.Model = "models/lightvest/lightvest.mdl"
ENT.FeMale.ModelSubMaterials = {}                   -- submaterials on rendered model
ENT.FeMale.HideSubMaterails = {}                    -- playermodel hide submaterials
ENT.FeMale.Skin = 0                                 -- skin on rendered model
ENT.FeMale.Bodygroups = "0000000000000"             -- bodygroups on rendered model
--
ENT.FeMale.BoneMerge = false
ENT.FeMale.ParentBone = "ValveBiped.Bip01_Spine2"   -- parent bone
ENT.FeMale.OffsetPos = Vector(-10.5, 1.4, 0)
ENT.FeMale.OffsetAng = Angle(0,94,90)
ENT.FeMale.ModelSize = 0.85
--//
local filename = string.StripExtension(string.GetFileFromFilename( GetCurrentLuaFile() ))
scripted_ents.Register(ENT, filename)

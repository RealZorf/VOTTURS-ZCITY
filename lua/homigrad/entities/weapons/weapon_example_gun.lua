do return end -- That just an example,
local SWEP = {}

SWEP.Base = "homigrad_base"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.PrintName = "Glock 17"
SWEP.Author = "Glock GmbH"
SWEP.Instructions = "Glock is a brand of polymer-framed, short recoil-operated, striker-fired, locked-breech semi-automatic pistols designed and produced by Austrian manufacturer Glock Ges.m.b.H. Thats version of Glock is 17 chambered in 9x19 ammo."
SWEP.Category = "New Weapons - Pistols"
SWEP.weaponInvCategory = 2 -- Weapon Category
SWEP.ScrappersSlot = "Secondary" -- Unused, but hey that for modders!

SWEP.IconOverride = "entities/weapon_pwb_glock17.png"
SWEP.WepSelectIcon2 = Material("vgui/hud/tfa_ins2_glock_p80.png") -- selector icon

SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""

SWEP.GetDebug = true

--\\ WorldModel, FakeModel settings and other stuff
    SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl" -- THIS IS REALWORLD MODEL, THAT SHOULD BE A CSS OR LOW-POLYMODEL!
    
    SWEP.WorldPos = Vector(6, -2, 0) -- A REAL POSTION OF GUN, NOT AN FAKE MODEL, YOU NEED TO SET FIRST THIS THEN A FAKEMODEL!
    SWEP.WorldAng = Angle(0, 0, 0) -- Same but Angles

    SWEP.attPos = Vector(0, -0, 6.5) -- legacy realworld model attPos, can be unsed, use insted AttachmentPos/Ang
    SWEP.attAng = Angle(0, -0.2, 0)
    
    SWEP.WorldModelFake = "models/weapons/arccw/c_ud_glock.mdl" -- That a fake model (viewmodel) what will be using tpik on player.

    SWEP.FakePos = Vector(-17, 2.25, 9) -- The pos adjust of fake model, should be +- same as worldmodel for cool physics when droped
    SWEP.FakeAng = Angle(0, 0, 0) -- Same as previous but with angles.

    SWEP.LocalMuzzlePos = Vector(6.5,0,5.65) -- Shoot Traces poses
    SWEP.LocalMuzzleAng = Angle(0.2,0,0)

    SWEP.AttachmentPos = Vector(0.5,-1.2,-6.5) -- This is a pos of muzzle for effect
    SWEP.AttachmentAng = Angle(0,0,0) -- same but with angle

    --\\
        SWEP.vecSuicidePist = Vector(2,-6,1)
        SWEP.angSuicidePist = Angle(25,110,40)
        
        SWEP.vecSuicidePist2 = Vector(4,-6,1)
        SWEP.angSuicidePist2 = Angle(25,110,40)

        -- SWEP.vecSuicideRifle = Vector(2,-19,-1)
        -- SWEP.angSuicideRifle = Angle(15,100,90)

        -- SWEP.vecSuicideRifle2 = Vector(14, -22, 0)
        -- SWEP.angSuicideRifle2 = Angle(14,118,90)
    --//

    --\\ Zoom Poses
        SWEP.ZoomPos = Vector(0, -0.0593, 6.4068)
    --//

    SWEP.FakeBodyGroups = "0000" -- see https://gmodwiki.com/Entity:SetBodyGroups
    SWEP.FakeBodyGroupsPresets = { -- same but presets.
        "0000"
    }
    
    SWEP.FakeAttachment = "1" -- BoneID of attachment for weapon mods(attachments)
    SWEP.FakeEjectBrassATT = "2" -- Attachment id of casing drop (can be adjusted)

    --SWEP.EjectPos = Vector(0,0,2) -- adjust it here!
    --SWEP.EjectAng = Angle(-45,-80,0)

    --\\ ViewPunches
        SWEP.FakeVPShouldUseHand = true -- that for simple right hand for viewbob, viewpunch and other
        --SWEP.FakeViewBobBone = "BoneStringName" -- that for viewbob,viewpunch

        SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
        SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
        SWEP.ViewPunchDiv = 40
    --//

    --\\ Magdrop scarry code
        SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"

        SWEP.FakeMagDropBone = "glock_mag" -- BoneName of magdrop bone

        -- Adjusters for mag and mag phys
        SWEP.lmagpos = Vector(1.8,0,-0.3)
        SWEP.lmagang = Angle(-10,0,0)
        SWEP.lmagpos2 = Vector(0,3.5,0.3)
        SWEP.lmagang2 = Angle(0,0,-110)
    --//

    --\\ Animations
        SWEP.AnimList = {
            ["idle"] = "idle",
            ["reload"] = "reload",
            ["reload_empty"] = "reload_empty",
        }

        SWEP.HoldType = "revolver" -- player holdtype


        --\\ Legacy Animations Sounds
            --[[
                SWEP.FakeReloadSounds = {
                    [0.17] = "weapons/universal/uni_pistol_draw_01.wav",
                    [0.22] = "weapons/tfa_ins2/usp_tactical/magrelease.wav",
                    [0.3] = "weapons/tfa_ins2/usp_tactical/magout.wav",
                    --[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
                    --[0.5] = "weapons/universal/uni_pistol_draw_01.wav",
                    [0.45] = "weapons/universal/uni_crawl_l_03.wav",
                    [0.7] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
                    [0.8] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
                    --[0.85] = "weapons/m45/m45_boltback.wav",
                    --[0.92] = "weapons/m45/m45_boltrelease.wav",
                }

                SWEP.FakeEmptyReloadSounds = {
                    [0.16] = "weapons/universal/uni_crawl_l_03.wav",
                    [0.22] = "weapons/tfa_ins2/usp_tactical/magrelease.wav",
                    [0.3] = "weapons/tfa_ins2/usp_tactical/magout.wav",
                    --[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
                    [0.37] = "weapons/universal/uni_pistol_draw_01.wav",
                    [0.6] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
                    [0.65] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
                    [0.85] = "weapons/m45/m45_boltrelease.wav",
                    --[0.92] = "weapons/m45/m45_boltrelease.wav",
                }
            --]]
        --//
    --//

    --\\ Holster 
        SWEP.shouldntDrawHolstered = true -- should draw?

        SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
        SWEP.holsteredPos = Vector(0, -2, 1)
        SWEP.holsteredAng = Angle(0, 20, 30)
    --//

    --\\ Weapon Attachments/Mods
        SWEP.availableAttachments = {
            barrel = {
                [1] = {"supressor4", Vector(0,0,0), {}},
                [2] = {"supressor6", Vector(4.2,0,0), {}},
                ["mount"] = Vector(-0.5,1.5,0),
            },
            magwell = {
                [1] = {"mag1",Vector(-6.3,-2.2,0), {}},
            },
            sight = {
                ["mountType"] = {"picatinny","pistolmount"},
                ["mount"] = {["picatinny"] = Vector(-3.1, 2.15, 0), ["pistolmount"] = Vector(-6.2, .5, 0.025)},
                ["mountAngle"] = Angle(0,0,0),
            },
            underbarrel = {
                ["mount"] = Vector(12.5, -0.35, -1),
                ["mountAngle"] = Angle(0, -0.6, 90),
                ["mountType"] = "picatinny_small"
            },
            mount = {
                ["picatinny"] = {
                    "mount4",
                    Vector(-1.5, -.1, 0),
                    {},
                    ["mountType"] = "picatinny",
                }
            },
            grip = {
                ["mount"] = Vector(15, 1.2, 0.1), 
                ["mountType"] = "picatinny"
            }
        }
    --//

    --\\ Legacy for no fakemodel
        -- --local to head
        -- SWEP.RHPos = Vector(12,-4.5,3)
        -- SWEP.RHAng = Angle(0,-5,90)
        -- --local to rh
        -- SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
        -- SWEP.LHAng = Angle(5,9,-100)
    --//
--//

--\\ uhh legacyyyy
    --[[
        if self.stupidgun then
            addvec_fem:Add(ply:GetAimVector():Angle():Right() * 0.3)
        end
    --]]
    SWEP.stupidgun = true -- idk maybe this is a legacy code...
--//

--\\ Gun Settings
    SWEP.weight = 1
    
    SWEP.Primary = {}
    SWEP.Primary.ClipSize = 17
    SWEP.Primary.DefaultClip = 17
    SWEP.Primary.Automatic = false
    SWEP.Primary.Ammo = "9x19 mm Parabellum"
    SWEP.Primary.Wait = PISTOLS_WAIT
    SWEP.Primary.Force = 25 -- only for recoil...

    SWEP.Primary.Cone = 0
    
    SWEP.ReloadTime = 4.2

    SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
    SWEP.Ergonomics = 1.2

    SWEP.punchmul = 1.5 -- ShootPunch mult
    SWEP.punchspeed = 3 -- ShootPunch speed

    SWEP.ShootAnimMul = 3 -- Procedural Shooting Anim mul
    
    --SWEP.Penetration = 7  -- actualy unused, cuz we got ammotypes
    --SWEP.Primary.Damage = 25 -- same as Penetration
--//

--\\ Sounds
    SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/makarov/handling/makarov_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
    
    SWEP.Primary.Sound = {"zcitysnd/sound/weapons/firearms/hndg_glock17/glock_fire_01.wav", 75, 90, 100}
    SWEP.SupressedSound = {"zcitysnd/sound/weapons/m45/m45_suppressed_fp.wav", 65, 90, 100}
    SWEP.DistSound = "m9/m9_dist.wav"
   
    SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
    SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
--//

--\\ Other Settings
    SWEP.CantFireFromCollision = true -- drop safety
--//
--\\ CustomFunctions
    function SWEP:DrawPost()
        local wep = self:GetWeaponEntity()
        if CLIENT and IsValid(wep) then
            self.shooanim = LerpFT(0.4,self.shooanim or 0,((self:Clip1() > 0 or self.reload) and 0) or 1.8)
            wep:ManipulateBonePosition(48,Vector(0 ,0 ,-1*self.shooanim ),false)
            local mul = self:Clip1() > 0 and 1 or 0
            --wep:ManipulateBoneScale(12,Vector(mul,mul,mul),false)
        end
    end

    function SWEP:PostSetupDataTables()
        self:NetworkVar("Int",0,"GlockSkin")
        self:NetworkVar("String",1,"RandomBodygroups")
        if ( CLIENT ) then
            self:NetworkVarNotify( "GlockSkin", self.OnVarChanged2 )
            self:NetworkVarNotify( "RandomBodygroups", self.OnVarChanged )
        end
    end

    function SWEP:OnVarChanged( name, old, new )
        if !IsValid(self:GetWM()) then return end

        self:GetWM():SetBodyGroups(new)
    end

    function SWEP:OnVarChanged2( name, old, new )
        if !IsValid(self:GetWM()) then return end

        self:GetWM():SetSkin(new)
    end

    function SWEP:InitializePost()
        local Skin = 0
        if math.random(0,100) > 99 then
            Skin = 3
        end
        self:SetGlockSkin(Skin)
        self:SetRandomBodygroups(self.FakeBodyGroupsPresets[math.random(#self.FakeBodyGroupsPresets)] or "0000")
    end

    function SWEP:ModelCreated(model)
        model:ManipulateBoneScale(46, vector_origin)
        model:SetBodyGroups(self:GetRandomBodygroups() or "00000")
        model:SetSkin(self:GetGlockSkin())
    end
--//

local filename = string.StripExtension(string.GetFileFromFilename( GetCurrentLuaFile() ))
weapons.Register(SWEP, filename)
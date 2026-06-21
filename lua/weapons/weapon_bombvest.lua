if(SERVER)then
	AddCSLuaFile()
	util.AddNetworkString("hmcd_splodetype")
elseif(CLIENT)then
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false

	SWEP.ViewModelFOV = 66

	SWEP.Slot = 4
	SWEP.SlotPos = 1

	killicon.AddFont("wep_jack_hmcd_ied", "HL2MPTypeDeath", "5", Color(0, 0, 255, 255))

	function SWEP:DrawViewModel()	
		return false
	end

	function SWEP:DrawWorldModel()
		self:DrawModel()
	end
	
	local function drawTextShadow(t,f,x,y,c,px,py)
		color_black.a = c.a
		draw.SimpleText(t,f,x + 1,y + 1,color_black,px,py)
		draw.SimpleText(t,f,x,y,c,px,py)
		color_black.a = 255
	end
	
	net.Receive("hmcd_splodetype",function()
		local Ent=net.ReadEntity()
		Ent.SplodeType=net.ReadInt(32)
	end)

	function SWEP:DrawHUD()
		--
	end
end

SWEP.Base="weapon_base"

SWEP.ViewModel = "models/props_junk/cardboard_jox004a.mdl"
SWEP.WorldModel = "models/props_junk/cardboard_jox004a.mdl"
if(CLIENT)then SWEP.WepSelectIcon=surface.GetTextureID("vgui/wep_jack_hmcd_jihad");SWEP.BounceWeaponIcon=false end
SWEP.PrintName = "Explosive Belt"
SWEP.Instructions	= "This is a concealed belt rigged with military-grade explosives surrounded by nails and ball bearings, and a detonator. Use it to end your pathetic life with one final aloha snackbar.\n\nLMB to suicide"
SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.BobScale=2
SWEP.SwayScale=2
SWEP.Weight	= 3
SWEP.AutoSwitchTo		= true
SWEP.AutoSwitchFrom		= false

SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.Delay			= 0.5
SWEP.Primary.Recoil			= 3
SWEP.Primary.Damage			= 120
SWEP.Primary.NumShots		= 1	
SWEP.Primary.Cone			= 0.04
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Force			= 900
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic   	= true
SWEP.Primary.Ammo         	= "none"

SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= false
SWEP.Secondary.Ammo         = "none"
SWEP.CarryWeight=3500

-- Explosion properties
SWEP.BlastDis = 16
SWEP.BlastDamage = 150
SWEP.KABOOM = false

-- Explosion sounds
SWEP.SoundFar = {"iedins/ied_detonate_dist_01.wav","ied/ied_detonate_dist_02.wav","ied/ied_detonate_dist_03.wav"}
SWEP.Sound = {"ied/ied_detonate_01.wav", "ied/ied_detonate_02.wav", "ied/ied_detonate_03.wav"}
SWEP.SoundWater = "iedins/water/ied_water_detonate_01.wav"

-- Explosion disorientation function
function hg.ExplosionDisorientation(enta, tinnitus, disorientation)
	enta.organism.owner:AddTinnitus(tinnitus)
	enta.organism.disorientation = enta.organism.disorientation + (disorientation)

	net.Start("organism_send")
	local tbl = {}
	tbl.disorientation = enta.organism.disorientation
	tbl.owner = enta.organism.owner
	net.WriteTable(tbl)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.WriteBool(true)
	net.Send(enta.organism.owner)
end

-- Modern explosion function for bomb vest
local function ExplodeBombVest(self, ent)
	if not IsValid(ent) then 
		if IsValid(self) then self:Remove() end
		return 
	end

	local EntPos = ent:GetPos() + ent:OBBCenter()
	self.KABOOM = true

	local BlastDamage = self.BlastDamage
	local BlastDis = self.BlastDis
	local owner = self:GetOwner()

	ent:EmitSound("nokia.mp3", 55, 100, 1, CHAN_AUTO)

	timer.Simple(0.4, function()
		if not IsValid(ent) then return end

		timer.Simple(0.1, function()
			net.Start("projectileFarSound")
				net.WriteString(table.Random(self.Sound))
				net.WriteString(table.Random(self.SoundFar))
				net.WriteVector(EntPos)
				net.WriteEntity(ent)
				net.WriteBool(ent:WaterLevel() > 0)
				net.WriteString(self.SoundWater)
			net.Broadcast()

			if ent:WaterLevel() == 0 then
				ParticleEffect("pcf_jack_groundsplode_medium", ent:GetPos(), -vector_up:Angle())
			else
				local effectdata = EffectData()
				effectdata:SetOrigin(ent:GetPos())
				effectdata:SetScale(3)
				effectdata:SetNormal(-ent:GetAngles():Forward())
				util.Effect("eff_jack_genericboom", effectdata)
			end

			hg.ExplosionEffect(EntPos, BlastDis / 0.2, 80)

			local Poof = EffectData()
			Poof:SetOrigin(EntPos)
			Poof:SetScale(1)
			util.Effect("eff_jack_hmcd_shrapnel", Poof, true, true)
		end)

		timer.Simple(0.2, function()
			if not IsValid(ent) then 
				if IsValid(self) then self:Remove() end
				return 
			end

			local radius = BlastDis / 0.01905
			util.BlastDamage(self, owner, EntPos, radius, BlastDamage)

			for _, enta in ipairs(ents.FindInSphere(EntPos, radius)) do
				local tr = hg.ExplosionTrace(EntPos, enta:GetPos(), {ent})

				local phys = enta:GetPhysicsObject()

				local dir = (enta:GetPos() - EntPos)
				local len = dir:Length()
				if len == 0 then continue end

				dir:Div(len)

				local frac = math.Clamp((radius - len) / radius, 0, 1)
				frac = frac ^ 1.6

				local proximityBoost = 1 + (1 - frac) * 1.8
				local forceadd = dir * frac * proximityBoost * 50000

				-- disorientation
				if enta.organism then
					local behindwall = tr.Entity != enta
					if IsValid(enta.organism.owner) and enta.organism.owner:IsPlayer() then
						hg.ExplosionDisorientation(
							enta,
							(behindwall and 3 or 5) * frac * 1.6,
							(behindwall and 4 or 6) * frac * 1.6
						)
					end
				end

				-- physics through walls
				if tr.Entity != enta then 					
					if IsValid(phys) then
						phys:ApplyForceCenter((forceadd/20) + vector_up * math.random(500,550))
					end
					continue
				end

				-- player impact
				if enta:IsPlayer() then
					hg.AddForceRag(enta, 0, forceadd * 0.6, 0.5)
					hg.AddForceRag(enta, 1, forceadd * 0.6, 0.5)
					hg.LightStunPlayer(enta)
				end

				-- physics impact
				if IsValid(phys) then
					phys:ApplyForceCenter(forceadd)
				end
			end

			-- Building and door destruction
			hgWreckBuildings(ent, EntPos, BlastDamage / 400, BlastDis/8, false)
			hgBlastDoors(ent, EntPos, BlastDamage / 400, BlastDis/8, false)

			-- Screen shake
			util.ScreenShake(EntPos, 35, 35, 1, 5000)

			-- Remove the weapon
			if IsValid(self) then
				self:Remove()
			end
		end)
	end)
end

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:SetupDataTables()
	--
end

function SWEP:PrimaryAttack()
	if not(IsFirstTimePredicted())then return end
	if(self.Owner:KeyDown(IN_SPEED))then return end
	self:SetNextPrimaryFire(CurTime()+2)
	if(CLIENT)then 
		LocalPlayer():ConCommand("act zombie")
		return
	end
	sound.Play("snd_jack_hmcd_jihad"..math.random(1,3)..".wav",self.Owner:GetShootPos(),75,math.random(95,105))
	timer.Simple(math.Rand(.9,1.1),function()
		if((IsValid(self))and(self.Owner)and(self.Owner:Alive()))then
			ExplodeBombVest(self, self.Owner)
		end
	end)
end

function SWEP:Deploy()
	if not(IsFirstTimePredicted())then return end
	self.DownAmt=16
	self:SetNextPrimaryFire(CurTime()+1)
	self:SetNextSecondaryFire(CurTime()+1)
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
	--
end

function SWEP:SecondaryAttack()
	--
end

function SWEP:Think()
	--
end

function SWEP:Reload()
	--
end

if(CLIENT)then
	local Hidden=0
	function SWEP:GetViewModelPosition(pos,ang)
		if not(self.DownAmt)then self.DownAmt=16 end
		if(self.Owner:KeyDown(IN_SPEED))then
			self.DownAmt=math.Clamp(self.DownAmt+.8,0,16)
		else
			self.DownAmt=math.Clamp(self.DownAmt-.9,0,16)
		end
		Hidden=22
		local NewPos=pos+ang:Forward()*50-ang:Up()*(20+self.DownAmt+Hidden)+ang:Right()*20
		return NewPos,ang
	end
	function SWEP:DrawWorldModel()
	if(self.Owner:IsValid())then
		local Pos,Ang=self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"))
		if(self.DatDetModel)then
			self.DatDetModel:SetRenderOrigin(Pos+Ang:Forward()*4+Ang:Right()*1)
			Ang:RotateAroundAxis(Ang:Up(),90)
			Ang:RotateAroundAxis(Ang:Right(),180)
			self.DatDetModel:SetRenderAngles(Ang)
			self.DatDetModel:DrawModel()
		else
			self.DatDetModel=ClientsideModel("models/saraphines/insurgency explosives/ied/insurgency_ied_phone.mdl")
			self.DatDetModel:SetPos(self:GetPos())
			self.DatDetModel:SetParent(self)
			self.DatDetModel:SetNoDraw(true)
			self.DatDetModel:SetModelScale(.35,0)
		end
	end
	end
	function SWEP:ViewModelDrawn(model)
		local Pos,Ang=model:GetPos(),model:GetAngles()
		if(self.DatDetViewModel)then
			if((Pos)and(Ang))then
				self.DatDetViewModel:SetRenderOrigin(Pos+Ang:Up()*20)
				Ang:RotateAroundAxis(Ang:Up(),180)
				Ang:RotateAroundAxis(Ang:Right(),30)
				self.DatDetViewModel:SetRenderAngles(Ang)
				self.DatDetViewModel:DrawModel()
			end
		else
			self.DatDetViewModel=ClientsideModel("models/weapons/w_models/w_jda_engineer.mdl")
			self.DatDetViewModel:SetPos(self:GetPos())
			self.DatDetViewModel:SetParent(self)
			self.DatDetViewModel:SetNoDraw(true)
			self.DatDetViewModel:SetModelScale(.5,0)
		end
	end
end
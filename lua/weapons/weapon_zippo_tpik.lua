
if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("hg_zippo_refill")
end

SWEP.Base = "weapon_tpik_base"
SWEP.PrintName = "Zippo Lighter"
SWEP.Category = "ZCity Other"
SWEP.Instructions = "LMB to light. Hold LMB when lit to reach out."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 3
SWEP.SlotPos = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Weight = 0

SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_zippolg.mdl"
SWEP.WorldModelReal = "models/weapons/c_zippolg.mdl"

SWEP.UseHands = false

SWEP.HoldType = "slam"

if(CLIENT)then
	SWEP.WepSelectIcon = Material("vgui/zippo.png")
	SWEP.IconOverride = "vgui/zippo.png"
	SWEP.BounceWeaponIcon = false
end


SWEP.MaxFuel = 80 -- 60-80 seconds
SWEP.FuelConsumption = 1 -- Per second

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.HoldPos = Vector(-7, 0, 0)

-- Assets
game.AddParticles("particles/lighter.pcf")
PrecacheParticleSystem("lighter_flame")

SWEP.Sound_Draw = Sound("zippoopen.mp3")
SWEP.Sound_Holster = Sound("zippoclose.mp3")
SWEP.Sound_IgniteSuccess = Sound("zipposuccess.mp3")
SWEP.Sound_IgniteFail = Sound("zippoattempt.mp3")


SWEP.AnimList = {
	["draw"] = {"Draw", 1.0, false},
	["idle"] = {"Idle", 5.0, true},
	["ignite_success"] = {"Ignite_Success", 1.0, false}, 
	["ignite_fail"] = {"Ignite_Fail", 0.7, false}, 
	["reach_start"] = {"Reach_out_Start", 1.0, false}, 
	["reach_idle"] = {"Reach_out_Idle", 25.0, true}, 
	["reach_end"] = {"Reach_out_End", 1.0, false} 
}

function SWEP:Initialize()
	if self.BaseClass.Initialize then self.BaseClass.Initialize(self) end
	self:SetNWBool("IsLit", false)
	self:SetNWFloat("Fuel", self.MaxFuel)
	self:SetNWBool("IsReaching", false)
end

function SWEP:Deploy()
	self:EmitSound(self.Sound_Draw)
	self:PlayAnim("draw")
	self:SetNWBool("IsLit", false)
	self:SetNWBool("IsReaching", false)
	
	-- Stop particles
	self:StopParticles()
	
	return true
end

function SWEP:Holster()
	self:EmitSound(self.Sound_Holster)
	self:SetNWBool("IsLit", false)
	self:SetNWBool("IsReaching", false)
	
	if CLIENT then
		self:StopParticles()
	else
		self:CallOnClient("StopParticles")
	end
	
	return true
end

function SWEP:OnRemove()
	if CLIENT then
		self:StopParticles()
	end
end

function SWEP:StopParticles()
	if CLIENT then
		if IsValid(self.fire) then
			self.fire:StopEmissionAndDestroyImmediately()
			self.fire = nil
		end
	end
end

function SWEP:StartParticles(ent)
	if CLIENT then
		local target = ent or self:GetWM()
		if IsValid(target) then
			local att = target:LookupAttachment("lighter_fire_point")
			if att <= 0 then att = 1 end
			
			if IsValid(self.fire) then self.fire:StopEmissionAndDestroyImmediately() end
			self.fire = CreateParticleSystem( target, "vFire_Flames_Tiny", PATTACH_POINT_FOLLOW, att )
		end
	end
end

function SWEP:PrimaryAttack()
	if self:GetNWBool("IsReaching") then return end -- Already reaching?
	
	if self:GetNWBool("IsLit") then
		-- Start Reach Out
		self:SetNWBool("IsReaching", true)
		
		self:PlayAnim("reach_start", 1.0, false)
		self:SetNextPrimaryFire(CurTime() + 1.0)
		
		-- Use timer instead of callback for networking safety
		timer.Simple(1.0, function()
			if IsValid(self) and self:GetNWBool("IsReaching") then
				self:PlayAnim("reach_idle", 15.0, true)
			end
		end)
	else
		-- Try to ignite
		if self:GetNWFloat("Fuel") <= 0 then
			self:PlayAnim("ignite_fail")
			return
		end
		
		-- Chance calculation based on fuel
		local fuelPct = self:GetNWFloat("Fuel") / self.MaxFuel
		local chance = 40 + (fuelPct * 40) -- 40% to 80% chance?
		
		if math.random(1, 100) <= chance then
			-- Success
			self:EmitSound(self.Sound_IgniteSuccess)
			self:PlayAnim("ignite_success", 1.0, false)
			
			timer.Simple(1.0, function()
				if IsValid(self) then
					self:SetNWBool("IsLit", true)
					-- Start particles (client logic handles this via Think/NWBool, but force update here)
					if SERVER then
						self:CallOnClient("StartParticles") 
					end
				end
			end)
		else
			-- Fail
			self:EmitSound(self.Sound_IgniteFail)
			self:PlayAnim("ignite_fail")
		end
		
		self:SetNextPrimaryFire(CurTime() + 1.0)
	end
end

function SWEP:UpdateEffects()
	if not CLIENT then return end

	-- Failsafe: If we are not the active weapon (and have an owner), stop particles
	if IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon() ~= self then
		self:StopParticles()
		return
	end
	
	if self:GetNWBool("IsLit") then
		-- Ensure particles are playing
		if not self.ParticlesCreated then
			self:StartParticles()
			self.ParticlesCreated = true
		end
		
		-- Dynamic Light
		local dlight = DynamicLight(self:EntIndex())
		if dlight then
			local wm = self:GetWM()
			local pos = self:GetPos()
			
			if IsValid(wm) then
				-- Try to get attachment
				local att = wm:LookupAttachment("lighter_fire_point")
				if att and att > 0 then
					local attData = wm:GetAttachment(att)
					if attData then pos = attData.Pos end
				else
					-- Fallback to bone or just model pos
					pos = wm:GetPos() + wm:GetUp() * 5 
				end
			elseif IsValid(self:GetOwner()) then 
				pos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 20 
			end
			
			dlight.Pos = pos
			dlight.r = 255
			dlight.g = 150
			dlight.b = 50
			dlight.Brightness = 2
			dlight.Size = 200
			dlight.Decay = 1000
			dlight.DieTime = CurTime() + 0.1
		end
	else
		if self.ParticlesCreated then
			self:StopParticles()
			self.ParticlesCreated = false
		end
	end
end

function SWEP:DrawPostWorldModel()
	self:UpdateEffects()
end

function SWEP:Think()
	-- Handle Dropped Logic (No Owner)
	if not IsValid(self:GetOwner()) then
		if self:GetNWBool("IsLit") then
			if SERVER then
				-- Fuel Consumption
				local fuel = self:GetNWFloat("Fuel")
				fuel = fuel - FrameTime()
				self:SetNWFloat("Fuel", fuel)
				
				if fuel <= 0 then
					self:SetNWBool("IsLit", false)
					self:CallOnClient("StopParticles")
				else
					-- Ignite gasoline on touch (Dropped logic)
					local pos = self:GetPos()
					if hg and hg.gasolinePath then
						for k, v in pairs(hg.gasolinePath) do
							local gasPos = v[1]
							if pos:DistToSqr(gasPos) < 30*30 then -- Close enough
								if v[2] == false then -- Not ignited
									v[2] = CurTime() -- Ignite
								end
							end
						end
					end
				end
			end
			
			if CLIENT then
				self:UpdateEffects()
			end
		else
			if CLIENT then
				self:UpdateEffects() -- To stop particles if they were running
			end
		end
		return -- Skip base Think if dropped
	end

	if self.BaseClass.Think then self.BaseClass.Think(self) end

	local isLit = self:GetNWBool("IsLit")
	local isReaching = self:GetNWBool("IsReaching")
	
	-- Handle Reaching Release
	if isReaching and not self.Owner:KeyDown(IN_ATTACK) then
		self:SetNWBool("IsReaching", false)
		self:PlayAnim("reach_end", 1.0, false)
		self:SetNextPrimaryFire(CurTime() + 1.0)
		
		timer.Simple(1.0, function()
			if IsValid(self) then
				self:PlayAnim("idle", 10.0, true)
			end
		end)
	end
	
	-- Fuel Consumption & Burnout
	if isLit then
		if SERVER then
			local fuel = self:GetNWFloat("Fuel")
			fuel = fuel - FrameTime()
			self:SetNWFloat("Fuel", fuel)
			
			if fuel <= 0 then
				self:SetNWBool("IsLit", false)
				self:SetNWBool("IsReaching", false)
				self:CallOnClient("StopParticles")
				self:PlayAnim("ignite_fail") -- Flicker out?
			end
		end
		
		-- Reaching Logic (Igniting things)
		if isReaching and SERVER then
			-- Trace forward
			local tr = util.TraceLine({
				start = self.Owner:GetShootPos(),
				endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 60,
				filter = self.Owner
			})
			
			if tr.Hit then
				-- Check gasoline path (Strictly following weapon_matches.lua logic)
				if hg and hg.gasolinePath then
					for k, v in pairs(hg.gasolinePath) do
						-- v[1] is position, v[2] is ignition time (false if not lit)
						if v[1]:Distance(tr.HitPos) > 30 or v[2] ~= false then continue end
						v[2] = CurTime() -- Ignite
					end
				end
			end
		end
	end
	
	-- Client side particle management
	if CLIENT then
		self:UpdateEffects()
	end
end

-- Refill Logic
if SERVER then
	net.Receive("hg_zippo_refill", function(len, ply)
		local ent = net.ReadEntity()
		if not IsValid(ent) or ply:GetPos():DistToSqr(ent:GetPos()) > 150*150 then return end
		
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_zippo_tpik" then return end
		
		-- Check drum volume
		if hg and hg.drums and hg.drums[ent:EntIndex()] then
			local drumData = hg.drums[ent:EntIndex()]
			if drumData.Volume <= 0 then
				ply:ChatPrint("This drum is empty!")
				return
			end
			
			wep:SetNWFloat("Fuel", wep.MaxFuel)
			wep:EmitSound("ambient/water/water_spray1.wav")
			ply:ChatPrint("Lighter refilled!")
			
			drumData.Volume = math.max(0, drumData.Volume - 10)
		end
	end)
end

if CLIENT then
	hook.Add("radialOptions", "RefillZippoOption", function()
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_zippo_tpik" then return end
		
		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
			filter = ply
		})
		
		local ent = tr.Entity
		if not IsValid(ent) then return end
		
		if hg and hg.gas_models and hg.gas_models[ent:GetModel()] then
			return {
				["Refill Lighter"] = function()
					net.Start("hg_zippo_refill")
					net.WriteEntity(ent)
					net.SendToServer()
				end
			}
		end
	end)
end

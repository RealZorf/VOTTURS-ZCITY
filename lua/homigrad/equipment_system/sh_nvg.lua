local colormodify01 = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0.15,
	["$pp_colour_addb"] = 0.17,
	["$pp_colour_brightness"] = 0.01,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local colormodify02 = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0.15,
	["$pp_colour_addb"] = 0.17,
	["$pp_colour_brightness"] = -0.1,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local blurMat2, Dynamic2 = Material("pp/blurscreen"), 0

local function BlurScreen(density,alpha)
	local layers, density, alpha = 1, density or .4, alpha or 255
	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(blurMat2)
	local FrameRate, Num, Dark = 1 / FrameTime(), 3, 150

	for i = 1, Num do
		blurMat2:SetFloat("$blur", (i / layers) * density * Dynamic2)
		blurMat2:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	Dynamic2 = math.Clamp(Dynamic2 + (1 / FrameRate) * 7, 0, 1)
end			 

local function DrawNoise(amt, alpha)
	local W, H = ScrW(), ScrH()

	for i = 0, amt do
		local Bright = math.random(0, 255)
		surface.SetDrawColor(Bright, Bright, Bright, alpha)
		local X, Y = math.random(0, W), math.random(0, H)
		surface.DrawRect(X, Y, 1, 1)
	end
end

function RenderNVGOverlay(self, ply)
	if not self:GetEnabled() then
		hg.DrawFirstPersonHelmet(self,ply)
	end
    if !self.GetEnabled or !self:GetEnabled() then 
        if IsValid(lply.NVGLamp) then
            lply.NVGLamp:Remove()
            lply.NVGLamp = nil
        end
    return end
    local overlayMaterial = self.OverlayMaterial
    local lightFOV = self.LightFOV
    local brightness = self.Brightness
    local blurAmmout = self.BlurAmmout
    
    if not IsValid(lply.NVGLamp) then
		lply.NVGLamp = ProjectedTexture()
		lply.NVGLamp:SetTexture("effects/flashlight001")
		lply.NVGLamp:SetBrightness(0.2)
		lply.NVGLamp:SetEnableShadows(false)
		local FoV = lply:GetFOV()
		lply.NVGLamp:SetFOV(FoV + 10)
		lply.NVGLamp:SetFarZ(500000 / FoV)
        lply.NVGLamp:SetNearZ( 15 )
		lply.NVGLamp:SetConstantAttenuation(.1)
	else
		local Ang = EyeAngles()
		lply.NVGLamp:SetPos(lply:EyePos())
		lply.NVGLamp:SetAngles(Ang)
		lply.NVGLamp:Update()
	end

	BlurScreen(blurAmmout or 0.2,65)

	DrawColorModify(colormodify01)
	DrawColorModify(colormodify02)
	DrawBloom(0.4, 1, 4, 4, 1, 0, 12, 12, 6)

	DrawNoise(500,25)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(overlayMaterial)

	local viewpunching = GetViewPunchAngles()
	local w, h = ScrW(), ScrH()
	surface.DrawTexturedRect(-w + (w * 1.5) / 2 - viewpunching.r * 6, -20 - viewpunching.x * 6, w * 1.5, h + 40)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(-w + (w * 1.5) / 2, (h + 20) - viewpunching.x * 6, w * 1.5, h + 40)
	surface.DrawRect(-w + (w * 1.5) / 2, -(h + 40) - viewpunching.x * 6, w * 1.5, h + 40)
end
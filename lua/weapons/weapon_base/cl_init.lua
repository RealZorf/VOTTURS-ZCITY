
include( "ai_translations.lua" )
include( "sh_anim.lua" )
include( "shared.lua" )

SWEP.Slot				= 0						-- Slot in the weapon selection menu
SWEP.SlotPos			= 10					-- Position in the slot
SWEP.DrawAmmo			= true					-- Should draw the default HL2 ammo counter
SWEP.DrawCrosshair		= true					-- Should draw the default crosshair
SWEP.DrawWeaponInfoBox	= true					-- Should draw the weapon info box
SWEP.BounceWeaponIcon	= true					-- Should the weapon icon bounce?
SWEP.SwayScale			= 1.0					-- The scale of the viewmodel sway
SWEP.BobScale			= 1.0					-- The scale of the viewmodel bob

SWEP.RenderGroup		= RENDERGROUP_OPAQUE

-- Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "weapons/swep" )

-- This is the corner of the speech bubble
SWEP.SpeechBubbleLid	= surface.GetTextureID( "gui/speech_lid" )

--[[---------------------------------------------------------
	You can draw to the HUD here - it will only draw when
	the client has the weapon deployed..
-----------------------------------------------------------]]
function SWEP:DrawHUD()
end

--[[---------------------------------------------------------
	Checks the objects before any action is taken
	This is to make sure that the entities haven't been removed
-----------------------------------------------------------]]
function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )

	-- Set us up the texture
	surface.SetDrawColor( 255, 255, 255, alpha )
	if isnumber( self.WepSelectIcon ) then
		surface.SetTexture( self.WepSelectIcon )
	else
		surface.SetMaterial( self.WepSelectIcon )
	end

	-- Lets get a sin wave to make it bounce
	local fsin = 0

	if ( self.BounceWeaponIcon == true ) then
		fsin = math.sin( CurTime() * 10 ) * 5
	end

	-- Borders
	y = y + 10
	x = x + 10
	wide = wide - 20

	-- Draw that mother
	surface.DrawTexturedRect( x + fsin, y - fsin,  wide - fsin * 2 , ( wide / 2 ) + fsin )

	-- Draw weapon info box
	self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )

end

--[[---------------------------------------------------------
	This draws the weapon info box
-----------------------------------------------------------]]

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateWeaponInfoFonts()
	surface.CreateFont("WepInfo_CRT_Header", {
		font = "Bahnschrift",
		size = math.max(16, S(24)),
		weight = 700,
		antialias = true,
		extended = true
	})
	surface.CreateFont("WepInfo_CRT_Body", {
		font = "Bahnschrift",
		size = math.max(12, S(17)),
		weight = 600,
		antialias = true,
		extended = true
	})
end

CreateWeaponInfoFonts()
hook.Add("OnScreenSizeChanged", "WeaponInfo_CRTFonts", CreateWeaponInfoFonts)

local function WrapText(text, maxW)
	surface.SetFont("WepInfo_CRT_Body")
	local lines = {}
	for _, paragraph in ipairs(string.Explode("\n", text or "")) do
		if paragraph == "" then
			lines[#lines + 1] = ""
		else
			local current = ""
			for _, word in ipairs(string.Explode(" ", paragraph)) do
				local trial = current == "" and word or (current .. " " .. word)
				if current ~= "" and surface.GetTextSize(trial) > maxW then
					lines[#lines + 1] = current
					current = word
				else
					current = trial
				end
			end
			if current ~= "" then
				lines[#lines + 1] = current
			end
		end
	end
	return lines
end

function SWEP:PrintWeaponInfo(x, y, alpha)
	if self.DrawWeaponInfoBox == false then return end

	local manufacturer = self.Author or ""
	local information = hg.ResolveKeybindText and hg.ResolveKeybindText(self.Instructions or "") or (self.Instructions or "")
	if manufacturer == "" and information == "" then return end

	alpha = math.Clamp(alpha or 255, 0, 255)
	local ply = LocalPlayer()
	local ar, ag, ab = CRT_R, CRT_G, CRT_B
	if IsValid(ply) and ply.isTraitor then
		ar, ag, ab = TRAITOR_R, TRAITOR_G, TRAITOR_B
	end

	local sw = ScrW()
	local bezel = S(3)
	local pad = S(4)
	local textPad = S(4)
	local stroke = math.max(1, S(1))
	local thick = S(2)
	local len = S(10)
	local panelW = S(307)
	local headerH = S(24)
	local lineH = S(19)
	local innerW = panelW - (bezel + pad) * 2
	local textW = innerW - textPad * 2
	local mfg = manufacturer ~= "" and WrapText(manufacturer, textW) or nil
	local info = information ~= "" and WrapText(information, textW) or nil

	local bodyH = 0
	if mfg then bodyH = bodyH + textPad + lineH * (1 + #mfg) end
	if info then bodyH = bodyH + textPad + lineH * #info end

	local colH = bezel * 2 + pad + headerH + pad + bodyH + pad
	x = sw - panelW - S(23)
	y = S(19)

	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, alpha * 0.90)
	surface.DrawRect(x, y, panelW, colH)

	local ix, iy, iw, ih = x + bezel, y + bezel, panelW - bezel * 2, colH - bezel * 2
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, alpha * 0.78)
	surface.DrawOutlinedRect(ix, iy, iw, ih, stroke)

	surface.SetDrawColor(ar, ag, ab, alpha * 0.9)
	surface.DrawRect(ix, iy, len, thick)
	surface.DrawRect(ix, iy, thick, len)
	surface.DrawRect(ix + iw - len, iy, len, thick)
	surface.DrawRect(ix + iw - thick, iy, thick, len)
	surface.DrawRect(ix, iy + ih - thick, len, thick)
	surface.DrawRect(ix, iy + ih - len, thick, len)
	surface.DrawRect(ix + iw - len, iy + ih - thick, len, thick)
	surface.DrawRect(ix + iw - thick, iy + ih - len, thick, len)

	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, alpha * 0.82)
	surface.DrawRect(ix + stroke, iy + stroke, iw - stroke * 2, ih - stroke * 2)

	local innerX = x + bezel + pad
	local innerY = y + bezel + pad
	surface.SetDrawColor(32, 34, 33, alpha * 0.82)
	surface.DrawRect(innerX, innerY, innerW, headerH)
	surface.SetDrawColor(ar, ag, ab, alpha * 0.14)
	surface.DrawRect(innerX, innerY, innerW, headerH)

	surface.SetFont("WepInfo_CRT_Header")
	local title = "INFORMATION"
	local tw, th = surface.GetTextSize(title)
	surface.SetTextColor(color_text.r, color_text.g, color_text.b, alpha)
	surface.SetTextPos(x + (panelW - tw) * 0.5, innerY + (headerH - th) * 0.5)
	surface.DrawText(title)

	local textX = innerX + textPad
	local textY = innerY + headerH + pad + textPad
	surface.SetFont("WepInfo_CRT_Body")
	surface.SetTextColor(color_text.r, color_text.g, color_text.b, alpha)

	if mfg then
		surface.SetTextPos(textX, textY)
		surface.DrawText("MANUFACTURER")
		textY = textY + lineH
		for i = 1, #mfg do
			surface.SetTextPos(textX, textY)
			surface.DrawText(mfg[i])
			textY = textY + lineH
		end
	end
	if info then
		for i = 1, #info do
			surface.SetTextPos(textX, textY)
			surface.DrawText(info[i])
			textY = textY + lineH
		end
	end
end
--[[---------------------------------------------------------
	Name: SWEP:FreezeMovement()
	Desc: Return true to freeze moving the view
-----------------------------------------------------------]]
function SWEP:FreezeMovement()
	return false
end

--[[---------------------------------------------------------
	Name: SWEP:ViewModelDrawn( viewModel )
	Desc: Called straight after the viewmodel has been drawn
-----------------------------------------------------------]]
function SWEP:ViewModelDrawn( vm )
end

--[[---------------------------------------------------------
	Name: OnRestore
	Desc: Called immediately after a "load"
-----------------------------------------------------------]]
function SWEP:OnRestore()
end

--[[---------------------------------------------------------
	Name: CustomAmmoDisplay
	Desc: Return a table
-----------------------------------------------------------]]
function SWEP:CustomAmmoDisplay()
end

--[[---------------------------------------------------------
	Name: GetViewModelPosition
	Desc: Allows you to re-position the view model
-----------------------------------------------------------]]
function SWEP:GetViewModelPosition( pos, ang )

	return pos, ang

end

--[[---------------------------------------------------------
	Name: TranslateFOV
	Desc: Allows the weapon to translate the player's FOV (clientside)
-----------------------------------------------------------]]
function SWEP:TranslateFOV( current_fov )

	return current_fov

end

--[[---------------------------------------------------------
	Name: DrawWorldModel
	Desc: Draws the world model (not the viewmodel)
-----------------------------------------------------------]]
function SWEP:DrawWorldModel()

	self:DrawModel()

end

--[[---------------------------------------------------------
	Name: DrawWorldModelTranslucent
	Desc: Draws the world model (not the viewmodel)
-----------------------------------------------------------]]
function SWEP:DrawWorldModelTranslucent()

	self:DrawModel()

end

--[[---------------------------------------------------------
	Name: AdjustMouseSensitivity
	Desc: Allows you to adjust the mouse sensitivity.
-----------------------------------------------------------]]
function SWEP:AdjustMouseSensitivity()

	return nil

end

--[[---------------------------------------------------------
	Name: GetTracerOrigin
	Desc: Allows you to override where the tracer comes from (in first person view)
		 returning anything but a vector indicates that you want the default action
-----------------------------------------------------------]]
function SWEP:GetTracerOrigin()

--[[
	local ply = self:GetOwner()
	local pos = ply:EyePos() + ply:EyeAngles():Right() * -5
	return pos
--]]

end

--[[---------------------------------------------------------
	Name: FireAnimationEvent
	Desc: Allows you to override weapon animation events
-----------------------------------------------------------]]

function SWEP:FireAnimationEvent( pos, ang, event, options )
	
	if ( !self.CSMuzzleFlashes ) then return end

	-- CS Muzzle flashes
	if ( event == 5001 or event == 5011 or event == 5021 or event == 5031 ) then

		local data = EffectData()
		data:SetFlags( 0 )
		data:SetEntity( self:GetOwner():GetViewModel() )
		data:SetAttachment( math.floor( ( event - 4991 ) / 10 ) )
		data:SetScale( 1 )

		if ( self.CSMuzzleX ) then
			util.Effect( "CS_MuzzleFlash_X", data )
		else
			util.Effect( "CS_MuzzleFlash", data )
		end

		return true
	end

end
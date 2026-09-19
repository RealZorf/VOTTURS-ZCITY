
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
local color_crt_soft = Color(160, 255, 200)
local color_traitor_soft = Color(255, 160, 160)
local color_idle = Color(172, 180, 174)
local color_bezel = Color(8, 9, 9)

local function CreateWeaponInfoFonts()
	surface.CreateFont("WepInfo_CRT_Header", {
		font = "Bahnschrift",
		size = math.max(16, ScreenScale(8)),
		weight = 700,
		antialias = true,
		extended = true
	})
	surface.CreateFont("WepInfo_CRT_Body", {
		font = "Bahnschrift",
		size = math.max(12, ScreenScale(5.5)),
		weight = 600,
		antialias = true,
		extended = true
	})
end

CreateWeaponInfoFonts()
hook.Add("OnScreenSizeChanged", "WeaponInfo_CRTFonts", CreateWeaponInfoFonts)

local function DrawWeaponInfoText(text, font, posX, posY, color, textAlign, alpha)
	surface.SetFont(font)
	if textAlign == TEXT_ALIGN_CENTER then
		local tw = surface.GetTextSize(text)
		posX = posX - tw * 0.5
	end
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.SetTextPos(posX, posY)
	surface.DrawText(text)
end

local function DrawWeaponInfoCorners(x, y, w, h, len, r, g, b, a)
	surface.SetDrawColor(r, g, b, a)
	surface.DrawRect(x, y, len, 2)
	surface.DrawRect(x, y, 2, len)
	surface.DrawRect(x + w - len, y, len, 2)
	surface.DrawRect(x + w - 2, y, 2, len)
	surface.DrawRect(x, y + h - 2, len, 2)
	surface.DrawRect(x, y + h - len, 2, len)
	surface.DrawRect(x + w - len, y + h - 2, len, 2)
	surface.DrawRect(x + w - 2, y + h - len, 2, len)
end

local function WrapWeaponInfoText(text, font, maxW)
	surface.SetFont(font)
	local lines = {}
	local paragraphs = string.Explode("\n", text or "")

	for _, paragraph in ipairs(paragraphs) do
		if paragraph == "" then
			lines[#lines + 1] = ""
		else
			local words = string.Explode(" ", paragraph)
			local current = ""
			for _, word in ipairs(words) do
				local trial = current == "" and word or (current .. " " .. word)
				if surface.GetTextSize(trial) > maxW and current ~= "" then
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

local infoCaretW
local INFO_PAD = 4
local INFO_TEXT_PAD = 4
local INFO_BEZEL = 3

local function DrawInfoRow(boxX, boxY, boxW, lineH, title, lines, alpha, activeColor)
	if not infoCaretW then
		surface.SetFont("WepInfo_CRT_Body")
		infoCaretW = surface.GetTextSize(">")
	end
	local caretGap = 3
	local caretX = boxX + INFO_TEXT_PAD
	local textX = caretX + infoCaretW + caretGap
	local nameY = boxY + INFO_TEXT_PAD
	DrawWeaponInfoText(">", "WepInfo_CRT_Body", caretX, nameY, activeColor, TEXT_ALIGN_LEFT, alpha)
	DrawWeaponInfoText(title, "WepInfo_CRT_Body", textX, nameY, activeColor, TEXT_ALIGN_LEFT, alpha)

	local textY = nameY + lineH
	for i = 1, #lines do
		DrawWeaponInfoText(lines[i], "WepInfo_CRT_Body", textX, textY, color_idle, TEXT_ALIGN_LEFT, alpha)
		textY = textY + lineH
	end

	return boxY + INFO_TEXT_PAD + lineH * (1 + #lines)
end

function SWEP:PrintWeaponInfo(x, y, alpha)
	if self.DrawWeaponInfoBox == false then return end

	local manufacturer = self.Author or ""
	local information = hg.ResolveKeybindText and hg.ResolveKeybindText(self.Instructions or "") or (self.Instructions or "")
	if manufacturer == "" and information == "" then return end

	alpha = math.Clamp(alpha or 255, 0, 255)
	local owner = self:GetOwner()
	local isTraitor = IsValid(owner) and owner.isTraitor
	local activeR, activeG, activeB = isTraitor and TRAITOR_R or CRT_R, isTraitor and TRAITOR_G or CRT_G, isTraitor and TRAITOR_B or CRT_B
	local activeColor = isTraitor and color_traitor_soft or color_crt_soft
	local scrW, scrH = ScrW(), ScrH()
	local panelW = math.max(220, math.floor(scrW * 0.16))
	local headerH = math.max(18, math.floor(scrH * 0.022))
	local lineH = math.max(14, math.floor(scrH * 0.018))
	if not infoCaretW then
		surface.SetFont("WepInfo_CRT_Body")
		infoCaretW = surface.GetTextSize(">")
	end
	local textW = panelW - INFO_PAD * 2 - INFO_TEXT_PAD * 2 - infoCaretW - 3
	local cacheKey = manufacturer .. "\n" .. information .. "\n" .. textW

	if self.InfoCRTCacheKey ~= cacheKey then
		self.InfoCRTCacheKey = cacheKey
		self.InfoCRTManufacturer = manufacturer ~= "" and WrapWeaponInfoText(manufacturer, "WepInfo_CRT_Body", textW) or nil
		self.InfoCRTInformation = information ~= "" and WrapWeaponInfoText(information, "WepInfo_CRT_Body", textW) or nil
	end

	local sectionCount = 0
	local bodyH = 0
	if self.InfoCRTManufacturer then
		sectionCount = sectionCount + 1
		bodyH = bodyH + INFO_TEXT_PAD + lineH * (1 + #self.InfoCRTManufacturer)
	end
	if self.InfoCRTInformation then
		sectionCount = sectionCount + 1
		bodyH = bodyH + INFO_TEXT_PAD + lineH * (1 + #self.InfoCRTInformation)
	end
	if sectionCount > 1 then
		bodyH = bodyH + 1
	end

	local colH = INFO_PAD + headerH + INFO_PAD + bodyH + INFO_PAD
	x = scrW - panelW - math.max(10, math.floor(scrW * 0.012))
	y = math.floor(scrH * 0.018)

	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, alpha * 0.8)
	surface.DrawRect(x - INFO_BEZEL, y - INFO_BEZEL, panelW + INFO_BEZEL * 2, colH + INFO_BEZEL * 2)
	surface.SetDrawColor(activeR, activeG, activeB, alpha * 0.7)
	surface.DrawOutlinedRect(x, y, panelW, colH, 1)
	DrawWeaponInfoCorners(x, y, panelW, colH, 10, activeR, activeG, activeB, alpha * 0.95)

	local innerX = x + INFO_PAD
	local innerW = panelW - INFO_PAD * 2
	local innerY = y + INFO_PAD
	local innerH = colH - INFO_PAD * 2

	surface.SetDrawColor(0, 0, 0, alpha * 0.45)
	surface.DrawRect(innerX, innerY, innerW, innerH)
	surface.SetDrawColor(activeR, activeG, activeB, alpha * 0.16)
	surface.DrawRect(innerX, innerY, innerW, headerH)
	DrawWeaponInfoText("INTEL-01", "WepInfo_CRT_Header", x + panelW * 0.5, innerY + 1, activeColor, TEXT_ALIGN_CENTER, alpha)

	local boxX = innerX
	local boxY = innerY + headerH + INFO_PAD
	local boxW = innerW

	if self.InfoCRTManufacturer then
		boxY = DrawInfoRow(boxX, boxY, boxW, lineH, "MANUFACTURER", self.InfoCRTManufacturer, alpha, activeColor)
	end

	if self.InfoCRTInformation then
		DrawInfoRow(boxX, boxY, boxW, lineH, "INFORMATION", self.InfoCRTInformation, alpha, activeColor)
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

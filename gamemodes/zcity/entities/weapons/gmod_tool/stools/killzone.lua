TOOL.Category = "ZCity"
TOOL.Name = "Killzone"
TOOL.Command = nil
TOOL.ConfigName = ""

local function allowed(ply)
	if not IsValid(ply) then return false end

	local ucl = ULib and ULib.ucl
	if not ucl or not ucl.query or not ucl.authed then return false end

	local id = (CLIENT and game.SinglePlayer()) and "1" or ply:UniqueID()
	if not ucl.authed[id] then return false end

	return ucl.query(ply, "zc_killzone") == true
end

function TOOL:Allowed()
	return allowed(self:GetOwner())
end

function TOOL:LeftClick(trace)
	local ply = self:GetOwner()
	if not allowed(ply) then return false end

	if SERVER and ZC_Killzone then
		ZC_Killzone.SetZ(trace.HitPos.z, ply)
	end

	return true
end

function TOOL:RightClick()
	local ply = self:GetOwner()
	if not allowed(ply) then return false end

	if SERVER and ZC_Killzone then
		ZC_Killzone.Clear(ply)
	end

	return true
end

function TOOL:Reload()
	local ply = self:GetOwner()
	if not allowed(ply) then return false end

	if SERVER and ZC_Killzone then
		ZC_Killzone.Print(ply)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
		Description = "Left click sets the map killzone at the clicked Z height.\nRight click clears it.\nAnyone alive below the line is killed, including fake/unconscious ragdolls."
	})

	panel:Button("Set to my current height", "zc_killzone_here")
	panel:Button("Print current killzone", "zc_killzone_print")
	panel:Button("Clear killzone for this map", "zc_killzone_clear")
end

if CLIENT then
	language.Add("tool.killzone.name", "Killzone")
	language.Add("tool.killzone.desc", "Set a map-saved horizontal death line.")
	language.Add("tool.killzone.0", "Left click to set killzone height. Right click to clear it. Reload prints current status.")

	local lineColor = Color(255, 25, 25, 230)
	local gridColor = Color(255, 25, 25, 90)
	local fillColor = Color(255, 0, 0, 18)
	local textColor = Color(255, 235, 235)
	local offColor = Color(180, 180, 180)

	function TOOL:DrawHUD()
		if not allowed(LocalPlayer()) then return end
		if not GetGlobalBool("zc_killzone_active", false) then return end

		local z = GetGlobalFloat("zc_killzone_z", 0)
		local eye = EyePos()
		local size, step = 4096, 512
		local cx = math.floor(eye.x / step) * step
		local cy = math.floor(eye.y / step) * step
		local minX, maxX = cx - size, cx + size
		local minY, maxY = cy - size, cy + size

		cam.Start3D()
			render.SetColorMaterial()
			cam.IgnoreZ(true)

			render.DrawLine(Vector(minX, minY, z), Vector(maxX, minY, z), lineColor, true)
			render.DrawLine(Vector(maxX, minY, z), Vector(maxX, maxY, z), lineColor, true)
			render.DrawLine(Vector(maxX, maxY, z), Vector(minX, maxY, z), lineColor, true)
			render.DrawLine(Vector(minX, maxY, z), Vector(minX, minY, z), lineColor, true)

			for x = minX, maxX, step do
				render.DrawLine(Vector(x, minY, z), Vector(x, maxY, z), gridColor, true)
			end

			for y = minY, maxY, step do
				render.DrawLine(Vector(minX, y, z), Vector(maxX, y, z), gridColor, true)
			end

			render.DrawQuad(
				Vector(minX, minY, z),
				Vector(maxX, minY, z),
				Vector(maxX, maxY, z),
				Vector(minX, maxY, z),
				fillColor
			)

			cam.IgnoreZ(false)
		cam.End3D()

		draw.SimpleTextOutlined("KILLZONE Z " .. math.Round(z, 2), "DermaLarge", ScrW() * 0.5, ScrH() * 0.16, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
	end

	function TOOL:DrawToolScreen(width, height)
		surface.SetDrawColor(18, 5, 5)
		surface.DrawRect(0, 0, width, height)
		draw.SimpleText("KILLZONE", "DermaLarge", width * 0.5, height * 0.36, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if GetGlobalBool("zc_killzone_active", false) then
			draw.SimpleText("Z " .. math.Round(GetGlobalFloat("zc_killzone_z", 0), 2), "DermaDefaultBold", width * 0.5, height * 0.62, lineColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("OFF", "DermaDefaultBold", width * 0.5, height * 0.62, offColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

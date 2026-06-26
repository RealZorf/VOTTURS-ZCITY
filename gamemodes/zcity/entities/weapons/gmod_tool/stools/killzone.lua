TOOL.Category = "ZCity"
TOOL.Name = "Killzone"
TOOL.Command = nil
TOOL.ConfigName = ""

local ACCESS_GROUPS = {
	superadmin = true,
	owner = true,
	servermanager = true,
	headdeveloper = true,
	headadmin = true,
	developer = true,
	admin = true
}

local function hasKillzoneAccess(ply)
	if not IsValid(ply) then return false end
	if ply:IsSuperAdmin() or ply:IsAdmin() then return true end

	if ply.GetUserGroup then
		local group = string.lower(tostring(ply:GetUserGroup() or ""))
		if ACCESS_GROUPS[group] then return true end
	end

	return false
end

if CLIENT then
	language.Add("tool.killzone.name", "Killzone")
	language.Add("tool.killzone.desc", "Set a map-saved horizontal death line.")
	language.Add("tool.killzone.0", "Left click to set killzone height. Right click to clear it. Reload prints current status.")
end

function TOOL:Allowed()
	return hasKillzoneAccess(self:GetOwner())
end

function TOOL:LeftClick(trace)
	local ply = self:GetOwner()
	if not hasKillzoneAccess(ply) then return false end

	if SERVER then
		if not ZC_Killzone or not ZC_Killzone.SetZ then return false end

		ZC_Killzone.SetZ(trace.HitPos.z, ply)
	end

	return true
end

function TOOL:RightClick(trace)
	local ply = self:GetOwner()
	if not hasKillzoneAccess(ply) then return false end

	if SERVER then
		if not ZC_Killzone or not ZC_Killzone.Clear then return false end

		ZC_Killzone.Clear(ply)
	end

	return true
end

function TOOL:Reload(trace)
	local ply = self:GetOwner()
	if not hasKillzoneAccess(ply) then return false end

	if SERVER then
		if not ZC_Killzone then return false end

		local msg = ZC_Killzone.Active and ("Killzone active at Z " .. tostring(ZC_Killzone.Z) .. " for " .. game.GetMap() .. ".") or ("No active killzone for " .. game.GetMap() .. ".")
		ply:ChatPrint(msg)
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
	local lineColor = Color(255, 25, 25, 230)
	local fillColor = Color(255, 0, 0, 18)
	local textColor = Color(255, 235, 235)

	local function drawKillzonePlane(z)
		local eye = EyePos()
		local size = 4096
		local step = 512
		local cx = math.floor(eye.x / step) * step
		local cy = math.floor(eye.y / step) * step
		local minX, maxX = cx - size, cx + size
		local minY, maxY = cy - size, cy + size

		render.SetColorMaterial()
		cam.IgnoreZ(true)

		render.DrawLine(Vector(minX, minY, z), Vector(maxX, minY, z), lineColor, true)
		render.DrawLine(Vector(maxX, minY, z), Vector(maxX, maxY, z), lineColor, true)
		render.DrawLine(Vector(maxX, maxY, z), Vector(minX, maxY, z), lineColor, true)
		render.DrawLine(Vector(minX, maxY, z), Vector(minX, minY, z), lineColor, true)

		for x = minX, maxX, step do
			render.DrawLine(Vector(x, minY, z), Vector(x, maxY, z), ColorAlpha(lineColor, 90), true)
		end

		for y = minY, maxY, step do
			render.DrawLine(Vector(minX, y, z), Vector(maxX, y, z), ColorAlpha(lineColor, 90), true)
		end

		render.DrawQuad(
			Vector(minX, minY, z),
			Vector(maxX, minY, z),
			Vector(maxX, maxY, z),
			Vector(minX, maxY, z),
			fillColor
		)

		cam.IgnoreZ(false)
	end

	function TOOL:DrawHUD()
		local ply = LocalPlayer()
		if not hasKillzoneAccess(ply) then return end
		if not GetGlobalBool("zc_killzone_active", false) then return end

		local z = GetGlobalFloat("zc_killzone_z", 0)

		cam.Start3D()
			drawKillzonePlane(z)
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
			draw.SimpleText("OFF", "DermaDefaultBold", width * 0.5, height * 0.62, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

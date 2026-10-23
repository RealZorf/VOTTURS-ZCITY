local CLASS = player.RegClass("roadman")

function CLASS.Off(self)
	if CLIENT then return end
end

local nicknames = {
	"Young ", "Big ", "Lil ", "Trap ", "Skeng ",
	"Mandem ", "Endz ", "Nines ", "Tiny ", "G ",
}

local maleModels = {
	"Male 01", "Male 02", "Male 03", "Male 04", "Male 05",
	"Male 06", "Male 07", "Male 08", "Male 09",
}

local clothesMain = {"dbgclothes_28m", "ftptop", "puffer"}
local clothesPants = {"bebra", "adidas", "furblack"}
local clothesBoots = {"halloween_30m"}
local sheets = {"Hoodie", "Standard", "Odessa"}
local hats = {"head_leather_cap", "bling cap", "panama1"}
local faces = {"arctic_balaclava", "baff", "facecover_mask"}
local extras = {"bp_sling_bag", "slingbag", "vest_normal"}
local colors = {
	{r = 22, g = 22, b = 24, a = 255},
	{r = 40, g = 40, b = 45, a = 255},
	{r = 55, g = 55, b = 58, a = 255},
	{r = 70, g = 70, b = 75, a = 255},
	{r = 32, g = 34, b = 40, a = 255},
}

local function Pick(pool)
	return pool[math.random(#pool)]
end

local function RandomFacemap(modelName)
	local models = hg.Appearance and hg.Appearance.PlayerModels and hg.Appearance.PlayerModels[1]
	local tMdl = models and models[modelName]
	local slot = tMdl and hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[tMdl.mdl]
	local faceslots = slot and hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[slot]
	if not istable(faceslots) then return "Default" end

	local _, facemap = table.Random(faceslots)
	return facemap or "Default"
end

local function ApplyRoadmanLook(ply)
	local modelName = Pick(maleModels)
	local baseName
	if ply.CurAppearance and isstring(ply.CurAppearance.AName) then
		baseName = ply.CurAppearance.AName
	elseif hg.Appearance and hg.Appearance.GenerateRandomName then
		baseName = hg.Appearance.GenerateRandomName(1)
	else
		baseName = "Mandem"
	end

	local appearance = {
		AModel = modelName,
		AFacemap = RandomFacemap(modelName),
		AAttachments = {
			Pick(hats),
			Pick(faces),
			Pick(extras),
		},
		AClothes = {
			main = Pick(clothesMain),
			pants = Pick(clothesPants),
			boots = Pick(clothesBoots),
		},
		ABodygroups = {
			TORSO = "Robotic Arm",
			shoes = "Sneakers",
			sheet = Pick(sheets),
			HANDS = "Gloves",
			pants = "Standard",
		},
		AColor = table.Copy(Pick(colors)),
		AName = Pick(nicknames) .. baseName,
	}

	if hg.Appearance and hg.Appearance.ForceApplyAppearance then
		hg.Appearance.ForceApplyAppearance(ply, appearance)
	end

	local clr = appearance.AColor
	local vec = Vector((clr.r or 255) / 255, (clr.g or 255) / 255, (clr.b or 255) / 255)
	ply:SetPlayerColor(vec)
	ply:SetNWVector("PlayerColor", vec)
	ply:SetNWString("PlayerName", appearance.AName)
	ply:SetNetVar("Accessories", appearance.AAttachments)
	ply.CurAppearance = appearance
end

function CLASS.On(self)
	if CLIENT then return end

	ApplyAppearance(self, nil, nil, nil, true)
	ApplyRoadmanLook(self)

	timer.Simple(0.2, function()
		if not IsValid(self) or self.PlayerClassName ~= "roadman" then return end
		ApplyRoadmanLook(self)
	end)
end

function CLASS.Guilt(self, victim)
	if CLIENT then return end

	if IsValid(victim) and victim:GetPlayerClass() == self:GetPlayerClass() then
		return 1
	end
end

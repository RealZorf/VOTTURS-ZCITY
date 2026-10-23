local CLASS = player.RegClass("hooligan")

function CLASS.Off(self)
	if CLIENT then return end
end

local nicknames = {
	"Mad ", "Big ", "Scarred ", "Cockney ", "Casuals ",
	"Irons ", "Fat ", "Stevie ", "Tony ", "Nobby ",
}

local maleModels = {
	"Male 01", "Male 02", "Male 03", "Male 04", "Male 05",
	"Male 06", "Male 07", "Male 08", "Male 09",
}

local clothesMain = {"dbgclothes_40m", "dbgclothes_57m", "shirtmale"}
local clothesPants = {"Hawaiian_Shirt", "dbgclothes_57m", "dbgclothes_54m"}
local clothesBoots = {"autumn_3m", "coolskeleton"}
local sheets = {"Closed", "Standard", "T-Shirt"}
local pantsFits = {"Standard", "Wide"}
local hats = {"cap gop", "hw_flat_cap", "green cap"}
local faces = {"aviators", "glasses_duduma"}
local extras = {"black scarf", "vest_normal", "slingbag"}
local colors = {
	{r = 190, g = 30, b = 45, a = 255},
	{r = 220, g = 90, b = 20, a = 255},
	{r = 210, g = 170, b = 40, a = 255},
	{r = 30, g = 140, b = 55, a = 255},
	{r = 30, g = 90, b = 190, a = 255},
	{r = 150, g = 40, b = 170, a = 255},
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

local function ApplyHooliganLook(ply)
	local modelName = Pick(maleModels)
	local baseName
	if ply.CurAppearance and isstring(ply.CurAppearance.AName) then
		baseName = ply.CurAppearance.AName
	elseif hg.Appearance and hg.Appearance.GenerateRandomName then
		baseName = hg.Appearance.GenerateRandomName(1)
	else
		baseName = "Lad"
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
			HANDS = "None",
			pants = Pick(pantsFits),
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
	ApplyHooliganLook(self)

	timer.Simple(0.2, function()
		if not IsValid(self) or self.PlayerClassName ~= "hooligan" then return end
		ApplyHooliganLook(self)
	end)
end

function CLASS.Guilt(self, victim)
	if CLIENT then return end

	if IsValid(victim) and victim:GetPlayerClass() == self:GetPlayerClass() then
		return 1
	end
end

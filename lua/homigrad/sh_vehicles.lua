local noCameraInCars = GetConVar("hg_no_camera_in_cars") or CreateConVar("hg_no_camera_in_cars", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "disables camera in cars", 0, 1)
local noFakeInCars = GetConVar("hg_no_fake_in_cars") or CreateConVar("hg_no_fake_in_cars", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "disables fake in cars", 0, 1)

hg.vehicleragblacklist = hg.vehicleragblacklist or {}
hg.vehiclecamblacklist = hg.vehiclecamblacklist or {}

local function NormalizeClass(class)
	if not isstring(class) then return end

	class = string.Trim(string.lower(class))
	if class == "" then return end

	return class
end

local function IsBlockedEntity(ent, blacklist)
	if not IsValid(ent) then return false end

	local class = NormalizeClass(ent:GetClass())
	if not class then return false end

	return class == "prop_vehicle_crane" or blacklist[class] == true
end

local function IsVehicleBlocked(vehicle, blacklist)
	if not IsValid(vehicle) then return false end
	if IsBlockedEntity(vehicle, blacklist) then return true end

	local parent = vehicle:GetParent()
	if IsBlockedEntity(parent, blacklist) then return true end

	for _, child in ipairs(vehicle:GetChildren()) do
		if IsBlockedEntity(child, blacklist) then return true end
	end

	return false
end

function hg.NoFakeInCar(vehicle)
	if noFakeInCars:GetBool() then return true end

	return IsVehicleBlocked(vehicle, hg.vehicleragblacklist)
end

function hg.NoCameraInCar(vehicle)
	if noCameraInCars:GetBool() then return true end

	return IsVehicleBlocked(vehicle, hg.vehiclecamblacklist)
end

local NET_BLACKLISTS = "SendVehicleRagBlacklist"

if SERVER then
	local DATA_DIRECTORY = "zcity"
	local RAG_BLACKLIST_PATH = DATA_DIRECTORY .. "/vehicles_ragblacklist.json"
	local CAMERA_BLACKLIST_PATH = DATA_DIRECTORY .. "/vehicles_camblacklist.json"

	local function ReadBlacklist(path)
		local decoded = util.JSONToTable(file.Read(path, "DATA") or "")
		if not istable(decoded) then return {} end

		local blacklist = {}

		for class, blocked in pairs(decoded) do
			class = NormalizeClass(class)

			if class and blocked then
				blacklist[class] = true
			end
		end

		return blacklist
	end

	local function LoadBlacklists()
		file.CreateDir(DATA_DIRECTORY)
		hg.vehicleragblacklist = ReadBlacklist(RAG_BLACKLIST_PATH)
		hg.vehiclecamblacklist = ReadBlacklist(CAMERA_BLACKLIST_PATH)
	end

	local function SaveBlacklists()
		file.CreateDir(DATA_DIRECTORY)
		file.Write(RAG_BLACKLIST_PATH, util.TableToJSON(hg.vehicleragblacklist, true))
		file.Write(CAMERA_BLACKLIST_PATH, util.TableToJSON(hg.vehiclecamblacklist, true))
	end

	local function SendBlacklists(ply)
		net.Start(NET_BLACKLISTS)
		net.WriteTable(hg.vehicleragblacklist)
		net.WriteTable(hg.vehiclecamblacklist)

		if IsValid(ply) and ply:IsPlayer() then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end

	local function CanManageBlacklists(ply)
		return not IsValid(ply) or ply:IsSuperAdmin()
	end

	local function SetBlacklistEntry(ply, args, blacklist, blocked)
		if not CanManageBlacklists(ply) then return end

		local class = NormalizeClass(args[1])
		if not class then return end

		blacklist[class] = blocked and true or nil
		SaveBlacklists()
		SendBlacklists()
	end

	util.AddNetworkString(NET_BLACKLISTS)
	LoadBlacklists()

	concommand.Add("hg_addvehicletoragblacklist", function(ply, _, args)
		SetBlacklistEntry(ply, args, hg.vehicleragblacklist, true)
	end)

	concommand.Add("hg_removevehiclefromragblacklist", function(ply, _, args)
		SetBlacklistEntry(ply, args, hg.vehicleragblacklist, false)
	end)

	concommand.Add("hg_addvehicletocamblacklist", function(ply, _, args)
		SetBlacklistEntry(ply, args, hg.vehiclecamblacklist, true)
	end)

	concommand.Add("hg_removevehiclefromcamblacklist", function(ply, _, args)
		SetBlacklistEntry(ply, args, hg.vehiclecamblacklist, false)
	end)

	net.Receive(NET_BLACKLISTS, function(_, ply)
		if ply.ZCityNextVehicleBlacklistSync and ply.ZCityNextVehicleBlacklistSync > CurTime() then return end

		ply.ZCityNextVehicleBlacklistSync = CurTime() + 1
		SendBlacklists(ply)
	end)

	hook.Add("PlayerInitialSpawn", "ZCity.VehicleBlacklists.Sync", function(ply)
		timer.Simple(1, function()
			if IsValid(ply) then
				SendBlacklists(ply)
			end
		end)
	end)

	timer.Simple(0, SendBlacklists)
else
	local trackedLists = setmetatable({}, {__mode = "k"})

	local function RefreshList(listView, blacklist)
		if not IsValid(listView) then return end

		listView:Clear()

		local classes = table.GetKeys(blacklist)
		table.sort(classes)

		for _, class in ipairs(classes) do
			listView:AddLine(class)
		end
	end

	local function RefreshTrackedLists()
		for listView, blacklistName in pairs(trackedLists) do
			RefreshList(listView, hg[blacklistName])
		end
	end

	local function RequestBlacklists()
		net.Start(NET_BLACKLISTS)
		net.SendToServer()
	end

	net.Receive(NET_BLACKLISTS, function()
		hg.vehicleragblacklist = net.ReadTable()
		hg.vehiclecamblacklist = net.ReadTable()
		RefreshTrackedLists()
	end)

	local function PopulateBlacklistPanel(panel, blacklistName, addCommand, removeCommand)
		local textEntry = panel:TextEntry("Type a vehicle class", "")
		local listView = vgui.Create("DListView", panel)
		listView:Dock(TOP)
		listView:SetTall(200)
		listView:SetMultiSelect(false)
		listView:AddColumn("Blacklist")
		trackedLists[listView] = blacklistName
		RefreshList(listView, hg[blacklistName])

		local addButton = panel:Button("Add", "")
		addButton.DoClick = function()
			local ply = LocalPlayer()
			if not IsValid(ply) or not ply:IsSuperAdmin() then return end

			local class = NormalizeClass(textEntry:GetValue())
			if class then
				RunConsoleCommand(addCommand, class)
			end
		end

		local removeButton = panel:Button("Remove", "")
		removeButton.DoClick = function()
			local ply = LocalPlayer()
			if not IsValid(ply) or not ply:IsSuperAdmin() then return end

			local index = listView:GetSelectedLine()
			local line = index and listView:GetLine(index)
			if IsValid(line) then
				RunConsoleCommand(removeCommand, line:GetValue(1))
			end
		end
	end

	hook.Add("InitPostEntity", "ZCity.VehicleBlacklists.Request", RequestBlacklists)

	if IsValid(LocalPlayer()) then
		timer.Simple(0, RequestBlacklists)
	end

	hook.Add("AddToolMenuCategories", "ZCity.VehicleBlacklists.Category", function()
		spawnmenu.AddToolCategory("Utilities", "zvehicles", "ZCity vehicle settings")
	end)

	hook.Add("PopulateToolMenu", "ZCity.VehicleBlacklists.Menu", function()
		RequestBlacklists()

		spawnmenu.AddToolMenuOption("Utilities", "zvehicles", "zvehiclesmenu", "Vehicle ragdoll blacklist", "", "", function(panel)
			PopulateBlacklistPanel(panel, "vehicleragblacklist", "hg_addvehicletoragblacklist", "hg_removevehiclefromragblacklist")
		end)

		spawnmenu.AddToolMenuOption("Utilities", "zvehicles", "zvehiclesmenu2", "Vehicle camera blacklist", "", "", function(panel)
			PopulateBlacklistPanel(panel, "vehiclecamblacklist", "hg_addvehicletocamblacklist", "hg_removevehiclefromcamblacklist")
		end)
	end)
end

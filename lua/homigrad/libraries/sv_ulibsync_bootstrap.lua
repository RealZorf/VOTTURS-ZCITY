if not SERVER then return end

local function bootULibSync()
	if not ULibSync or not isfunction(ULibSync.Init) then
		return false
	end

	if ULibSync.ready then
		return true
	end

	ULibSync.Init()
	return true
end

hook.Add("ZCITY_DatabaseReady", "ZCity_ULibSyncBoot", function(useMySQL)
	if not useMySQL then return end
	timer.Simple(0, bootULibSync)
end)

hook.Add("DatabaseConnected", "ZCity_ULibSyncBootDB", function()
	timer.Simple(4, function()
		if not ULibSync or ULibSync.ready then return end
		if not mysql or mysql.module ~= "mysqloo" or not mysql.connection then return end
		bootULibSync()
	end)
end)

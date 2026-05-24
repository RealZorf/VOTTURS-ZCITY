if not ULibSync then return end

hook.Add("ULibSyncReady", "ZCity_ULibSyncBridge", function()
	MsgC(Color(120, 220, 255), "[ZCITY] ULibSync is using the shared database connection.\n")
	MsgC(Color(180, 200, 220), "[ZCITY] Run !syncall once on your main server to seed ULX data, then !getall on others.\n")
end)

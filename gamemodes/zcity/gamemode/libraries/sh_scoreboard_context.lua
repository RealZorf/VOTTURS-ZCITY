zb = zb or {}

function zb.LocalPlayerHasAccess(access)
	if not isstring(access) or access == "" then return true end
	if not ULib or not ULib.ucl then return false end
	return ULib.ucl.query(LocalPlayer(), access) == true
end

function zb.AddScoreboardPlayerMenu(menu, targetPly)
	if not IsValid(menu) or not IsValid(targetPly) then return end

	menu:AddOption("Copy SteamID", function()
		SetClipboardText(targetPly:SteamID())
	end)

	if zb.Experience and zb.Experience.AccountMenu then
		menu:AddOption("Account", function()
			zb.Experience.AccountMenu(targetPly)
		end)
	end

	if not zb.LocalPlayerHasAccess(zb.UCL.AdminTools) then return end

	menu:AddSpacer()

	if zb.LocalPlayerHasAccess(zb.UCL.Notify) then
		menu:AddOption("Notify", function()
			Derma_StringRequest(
				"Notify " .. targetPly:Nick(),
				"Message to send:",
				"",
				function(text)
					if text == "" then return end
					RunConsoleCommand("ulx", "zcnotify", targetPly:Nick(), text)
				end
			)
		end)
	end

	if zb.LocalPlayerHasAccess(zb.UCL.Respawn) then
		menu:AddOption("Respawn", function()
			RunConsoleCommand("ulx", "zcrespawn", targetPly:Nick())
		end)
	end

	if zb.LocalPlayerHasAccess(zb.UCL.Give) then
		menu:AddOption("Give weapon/entity", function()
			Derma_StringRequest(
				"Give to " .. targetPly:Nick(),
				"Class name:",
				"",
				function(className)
					if className == "" then return end
					RunConsoleCommand("ulx", "zcgive", targetPly:Nick(), className)
				end
			)
		end)
	end

	if zb.LocalPlayerHasAccess(zb.UCL.SendToSpawn) then
		menu:AddOption("Send to spawn", function()
			RunConsoleCommand("ulx", "zcsendtospawn", targetPly:Nick())
		end)
	end

	if zb.LocalPlayerHasAccess(zb.UCL.Godmode) then
		menu:AddOption("Toggle godmode", function()
			RunConsoleCommand("ulx", "zcgod", targetPly:Nick())
		end)
	end
end

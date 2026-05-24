print("[ZBattle] Test library loaded!")
if CLIENT then
	net.Receive("FadeScreen", function()
		if zb.IsEndRoundMenuOpen and zb.IsEndRoundMenuOpen() then
			zb.pendingFadeAfterMenu = true
			return
		end

		if (zb.endMenuUntil or 0) > CurTime() then
			zb.pendingFadeAfterMenu = true
			return
		end

		local round = CurrentRound and CurrentRound()
		if round and round.buymenu then
			return
		end

		zb.fade = math.max(zb.fade or 0, 1.25)
	end)

	function zb.ClearClientFade()
		hook.Remove("RenderScreenspaceEffects", "ZB_ScreenFade")
		zb.fade = 0
	end

	-- Clears stuck engine ScreenFade without a visible fade-in flash.
	function zb.ClearEngineScreenFade()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		if (zb._engineFadeClearedAt or 0) > CurTime() then return end

		zb._engineFadeClearedAt = CurTime() + 0.35
		ply:ScreenFade(SCREENFADE.IN, color_black, 0, 0)
	end

	function zb.RemoveFade()
		zb.ClearClientFade()
		zb.ClearEngineScreenFade()
	end
end

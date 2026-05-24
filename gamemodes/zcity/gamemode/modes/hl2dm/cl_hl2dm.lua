MODE.name = "hl2dm"
MODE.IntroTitle = "ZBattle | Half-Life 2 Deathmatch"

local MODE = MODE

net.Receive("hl2dm_start",function()
    surface.PlaySound("hl2mode1.wav")
	zb.RemoveFade()
	hg.DynaMusic:Start( "hl_coop" )
end)

local teams = {
	[0] = {
		objective = "Kill all combines and survive.",
		name = "a Rebel",
		name_refugee = "the Refugee",
		color1 = Color(230,100,5),
		color2 = Color(210,80,0),
		color3 = Color(25, 110, 25),
        color4 = Color(5, 90, 5),
		color_subrole = Color(180, 15, 15),
	},
	[1] = {
        objective = "Destroy all rebel forces.",
        name = "a Combine Soldier",
        name_elite = "the Elite Combine Soldier",
        name_shotgunner = "the Combine Shotgunner",
        color1 = Color(0, 200, 220), -- самый
        color2 = Color(0, 180, 200),
        color3 = Color(180, 15, 15),
		color4 = Color(160, 0, 0),
        color5 = Color(190, 185, 185),
		color6 = Color(170, 175, 175),
	},
}

MODE.IntroTeams = teams

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:DrawRoundIntro(fade)
	if not IsValid(lply) or not lply:Alive() then return end

	local team_data = teams[lply:Team()]
	if not team_data then return end

	draw.SimpleText(MODE.IntroTitle, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local roleColor = Color(team_data.color1.r, team_data.color1.g, team_data.color1.b, 255 * fade)
	draw.SimpleText("You are " .. team_data.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local objectiveColor = Color(team_data.color2.r, team_data.color2.g, team_data.color2.b, 255 * fade)
	draw.SimpleText(team_data.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objectiveColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("radialOptions", "CMB_Airstrike", function()
     
	local org = lply.organism
	
    if lply:GetNWString("PlayerRole") == "Elite" and not org.otrub then -- that's a feature apparently
		local tbl = {
			function()
				net.Start("ZB_RequestAirStrike") 
				net.SendToServer()
			end,
			"Request Airstrike"
		}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
    end
end)

local winnersounds = {
	[0] = { -- rebel wins
		"vo/episode_1/npc/male01/cit_kill04.wav",
		"vo/episode_1/npc/male01/cit_kill01.wav",
		"vo/episode_1/npc/male01/cit_kill09.wav",
		"vo/episode_1/npc/male01/cit_kill14.wav"
	},
	[1] = { -- combine wins
		"vo/episode_1/npc/male01/cit_buddykilled11.wav",
		"vo/episode_1/npc/male01/cit_buddykilled07.wav",
		"vo/episode_1/npc/male01/cit_buddykilled10.wav",
		"vo/episode_1/npc/male01/cit_buddykilled04.wav"
	},
	[2] = {"npc/combine_soldier/vo/overwatchtargetcontained.wav"}, -- draw
	[3] = {"npc/combine_soldier/vo/overwatchsectoroverrun.wav"} -- everybody died
}

function MODE:HUDPaint()
	zb.RoundFade.PaintStandardIntro(self)
end

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end

local MODE = MODE

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HMCD_TDM_CT = zb.Points.HMCD_TDM_CT or {}
zb.Points.HMCD_TDM_CT.Color = Color(40, 40, 45)
zb.Points.HMCD_TDM_CT.Name = "HMCD_TDM_CT"

zb.Points.HMCD_TDM_T = zb.Points.HMCD_TDM_T or {}
zb.Points.HMCD_TDM_T.Color = Color(150, 20, 45)
zb.Points.HMCD_TDM_T.Name = "HMCD_TDM_T"

MODE.PrintName = "Hooligans vs Roadmen"
MODE.Description = "Football hooligans versus roadmen. Street weapons, smoke, last crew standing."

MODE.ThemeMusicFile = "zorf/tdmmelee/grimetdmmelee.mp3"
MODE.ThemeMusicVolume = 0.4
MODE.ThemeLoopFade = 1.4
MODE.FallbackDynaMusic = "swat4"

MODE.TeamNames = {
	[0] = "Hooligans",
	[1] = "Roadmen",
	[3] = "Nobody",
}

MODE.TeamColors = {
	[0] = Color(150, 20, 45),
	[1] = Color(40, 40, 45),
}

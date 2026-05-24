MODE.name = "event"

local MODE = MODE

function MODE:DrawRoundIntro(fade)
	if not IsValid(lply) or not lply:Alive() then return end

	local eventname = GetGlobalString("ZB_EventName", "Event")
	draw.SimpleText("ZCity | " .. eventname, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local isEventer = EventersList[LocalPlayer():SteamID()]
	local roleName = isEventer and "Eventer" or GetGlobalString("ZB_EventRole", "Player")
	local colorRole = isEventer and eventer.color1 or fighter.color1
	colorRole = Color(colorRole.r, colorRole.g, colorRole.b, 255 * fade)
	draw.SimpleText("You are a " .. roleName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local objective = GetGlobalString("ZB_EventObjective", "")
	local colorObj = isEventer and eventer.color1 or fighter.color1
	colorObj = Color(colorObj.r, colorObj.g, colorObj.b, 255 * fade)
	draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local radius = nil
local mapsize = 7500

local EventersList = {}

ZonePos = ZonePos or Vector(0,0,0)

local roundend = false

net.Receive("event_start",function()
    roundend = false
    zb.RemoveFade()
end)


net.Receive("event_eventers_update", function()
    EventersList = {}
    local data = net.ReadTable()
    for _, id in ipairs(data) do
        EventersList[id] = true
    end
end)

local fighter = {
    color1 = Color(0,120,190)
}

local eventer = {
    color1 = Color(50,200,50)
}

local mat = Material("hmcd_dmzone")

local mapsize = 7500

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	zb.RoundFade.PaintStandardIntro(self)
end

local wonply = nil

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

concommand.Add("zb_event_loot_menu", function()
    RunConsoleCommand("zb_event_lootpoll")
end)


net.Receive("event_loot_request", function()
    CreateLootPollingMenu()
end)
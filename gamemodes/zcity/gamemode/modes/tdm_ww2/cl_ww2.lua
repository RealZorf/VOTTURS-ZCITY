local MODE = MODE

local teams = {
    [0] = {
        objective = {"Hold the line.", "Plant the charge, guard the captive, and stop the Allied advance."},
        name = "a German soldier",
        color = Color(180, 150, 110),
        objectiveColor = Color(210, 180, 135),
    },
    [1] = {
        objective = {"Break the line.", "Defuse the charge, extract the captive, and secure the field."},
        name = "an American soldier",
        color = Color(110, 170, 120),
        objectiveColor = Color(140, 210, 155),
    },
}

local function WithAlpha(color, alpha)
    return Color(color.r, color.g, color.b, alpha)
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()
    local w, h = ScrW(), ScrH()
    local ply = LocalPlayer()

    self:AddHudPaint()

    if StartTime + 20 > CurTime() then
        draw.SimpleText(string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", w * 0.5, h * 0.95, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Press F3 to open the field shop", "ZB_HomicideMedium", w * 0.5, h * 0.9, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local time = string.FormattedTime(math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i")
        draw.SimpleText(time, "ZB_HomicideMedium", w * 0.5, h * 0.95, Color(230, 230, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if StartTime + 20 < CurTime() then return end
    if not ply:Alive() then return end

    zb.RemoveFade()

    local fade = math.Clamp(StartTime + 8 - CurTime(), 0, 1)
    local info = teams[ply:Team()] or teams[0]
    local alpha = 255 * fade

    draw.SimpleText("ZBattle | " .. (self.PrintName or "World War II Frontline"), "ZB_HomicideMediumLarge", w * 0.5, h * 0.1, WithAlpha(Color(235, 220, 190), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("You are " .. info.name, "ZB_HomicideMediumLarge", w * 0.5, h * 0.5, WithAlpha(info.color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    for line, text in ipairs(info.objective) do
        draw.SimpleText(text, "ZB_HomicideMedium", w * 0.5, h * (0.78 + line * 0.045), WithAlpha(info.objectiveColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local text = Color(29, 167, 52)
local subtitle = Color(65, 201, 92)
local outline = Color(0, 0, 0, 180)

hook.Add("HUDPaint", "ZB_FirstRoundJoinWindow", function()
    if zb.ROUND_STATE == 1 then return end
    local remaining = GetGlobalFloat("ZB_FirstRoundWaitUntil", 0) - CurTime()
    if remaining <= 0 then return end

    draw.SimpleTextOutlined("Waiting for players: " .. string.FormattedTime(math.ceil(remaining), "%02i:%02i"),
        "ZB_InterfaceMediumLarge", ScrW() * 0.5, ScrH() * 0.12, text,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, outline)
    draw.SimpleTextOutlined("Letting people with potato computers join after mapchange",
        "ZB_InterfaceSmall", ScrW() * 0.5, ScrH() * 0.12 + 30, subtitle,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, outline)
end)

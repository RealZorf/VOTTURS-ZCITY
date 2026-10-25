zb = zb or {}
zb.MaximumHarm = 10
zb.MaxKarma = 120

ZCITY_GUILT = ZCITY_GUILT or {}

local function colorData(r, g, b, a)
    return {
        r = r,
        g = g,
        b = b,
        a = a or 255
    }
end

ZCITY_GUILT.ThemeDefaults = ZCITY_GUILT.ThemeDefaults or {
    panelBg = colorData(8, 8, 8, 220),
    panelInner = colorData(18, 18, 18, 235),
    panelAlt = colorData(28, 28, 28, 220),
    accent = colorData(190, 20, 20, 220),
    accentSoft = colorData(255, 45, 45, 120),
    textMain = colorData(245, 245, 245, 255),
    textSub = colorData(220, 220, 220, 255),
    muted = colorData(160, 160, 160, 255),
    success = colorData(70, 170, 95, 255),
    info = colorData(80, 140, 220, 255),
    disabled = colorData(100, 100, 100, 120)
}

ZCITY_GUILT.ThemeGroups = ZCITY_GUILT.ThemeGroups or {
    {
        title = "Base",
        keys = { "panelBg", "panelInner", "panelAlt", "accent", "accentSoft" }
    },
    {
        title = "Text",
        keys = { "textMain", "textSub", "muted" }
    },
    {
        title = "Status",
        keys = { "success", "info", "disabled" }
    }
}

ZCITY_GUILT.ThemeLabels = ZCITY_GUILT.ThemeLabels or {
    panelBg = "Panel BG",
    panelInner = "Panel Inner",
    panelAlt = "Panel Alt",
    accent = "Accent",
    accentSoft = "Soft Accent",
    textMain = "Main Text",
    textSub = "Sub Text",
    muted = "Muted Text",
    success = "Success",
    info = "Info",
    disabled = "Disabled"
}

ZCITY_GUILT.DefaultConfig = {
    PromptKey = KEY_F,
    PromptText = "Press F to open the guilt menu.",
    MinHarm = 1,
    HarmExpiry = 180,
    CaseExpiry = 45,
    AutoExpireMinHarm = 15,
    AutoExpireAmount = 2,
    AutoExpireRoundCap = 5,
    SelfDefenseWindow = 12,
    SelfDefenseMinIncomingHarm = 5,
    SelfDefenseAttackerCount = 2,
    ManualPunishRoundCap = 15,
    AllowForgive = true,
    AllowPunish = true,
    AllowReport = true,
    LogAdminActions = true,
    StaffReportPrefix = "[GUILT REPORT] ",
    Theme = table.Copy(ZCITY_GUILT.ThemeDefaults),
    Presets = {
        { id = "punish_minor", name = "Minor Punish (-5 Karma)", amount = 5, minharm = 5, color = { r = 210, g = 210, b = 90 } },
        { id = "punish_major", name = "Major Punish (-10 Karma)", amount = 10, minharm = 10, color = { r = 255, g = 170, b = 60 } },
        { id = "punish_severe", name = "Severe Punish (-15 Karma)", amount = 15, minharm = 15, color = { r = 255, g = 90, b = 90 } }
    }
}

ZCITY_GUILT.Config = ZCITY_GUILT.Config or table.Copy(ZCITY_GUILT.DefaultConfig)

local function normalizeColorEntry(v)
    if IsColor and IsColor(v) then
        return { r = v.r, g = v.g, b = v.b }
    end

    if istable(v) then
        return {
            r = tonumber(v.r) or 255,
            g = tonumber(v.g) or 255,
            b = tonumber(v.b) or 255
        }
    end

    return { r = 255, g = 255, b = 255 }
end

function ZCITY_GUILT.GetPreset(action)
    local presets = (ZCITY_GUILT.Config and ZCITY_GUILT.Config.Presets)
        or (ZCITY_GUILT.DefaultConfig and ZCITY_GUILT.DefaultConfig.Presets)
        or {}

    for _, preset in ipairs(presets) do
        if preset.id == action then
            return preset
        end
    end
end

function ZCITY_GUILT.GetPunishAmount(preset, row)
    local requested = math.max(0, tonumber(preset and preset.amount) or 0)
    local minharm = math.max(0, tonumber(preset and preset.minharm) or 0)
    local harm = math.max(0, tonumber(row and row.harm) or 0)
    if harm < minharm then return 0 end
    return math.min(requested, harm)
end

function ZCITY_GUILT.GetPresetColor(preset)
    local c = normalizeColorEntry(preset and preset.color)
    return Color(c.r, c.g, c.b)
end

if SERVER then
    util.AddNetworkString("zcity_guilt_open")
    util.AddNetworkString("zcity_guilt_action")
    util.AddNetworkString("zcity_guilt_feedback")
    util.AddNetworkString("zcity_guilt_config")
    util.AddNetworkString("zcity_guilt_admin_open")
    util.AddNetworkString("zcity_guilt_admin_save")
    util.AddNetworkString("zcity_guilt_admin_openmenu")
end

zb = zb or {}
zb.MaximumHarm = 10
zb.MaxKarma = 120

ZCITY_GUILT = ZCITY_GUILT or {}

-- Old saved keys are remapped when a config file is loaded.
ZCITY_GUILT.SettingAliases = {
    PromptKey = "MenuOpenKey",
    PromptText = "MenuPromptText",
    MinHarm = "MinHarmToOpenCase",
    HarmExpiry = "HarmMemorySeconds",
    CaseExpiry = "MenuTimeoutSeconds",
    AutoExpireMinHarm = "UnresolvedMinHarm",
    AutoExpireAmount = "UnresolvedKarmaPenalty",
    AutoExpireRoundCap = "UnresolvedKarmaCapPerRound",
    SelfDefenseWindow = "SelfDefenseSeconds",
    SelfDefenseMinIncomingHarm = "MultiAttackerMinHarm",
    SelfDefenseAttackerCount = "MultiAttackerCount",
    ManualPunishRoundCap = "ManualPunishCapPerRound",
    AllowForgive = "EnableForgive",
    AllowPunish = "EnablePunish",
    AllowReport = "EnableReport"
}

ZCITY_GUILT.Settings = {
    { group = "Menu", key = "MenuOpenKey", label = "Menu open key", desc = "GMod key code that opens the guilt menu while a case is pending. F is 16.", type = "int", default = KEY_F, min = 1, max = 255 },
    { group = "Menu", key = "MenuPromptText", label = "On-screen prompt", desc = "Hint shown at the bottom of the screen when the victim has a pending case.", type = "string", default = "Press F to open the guilt menu." },

    { group = "Cases", key = "MinHarmToOpenCase", label = "Minimum harm to list a player", desc = "A player only appears in the death menu if they dealt at least this much harm, unless they got the killing blow.", type = "number", default = 1, min = 0, max = 50 },
    { group = "Cases", key = "HarmMemorySeconds", label = "Harm memory (seconds)", desc = "How long recorded hits stay eligible after they happen. Older hits are dropped from the case.", type = "number", default = 180, min = 1, max = 3600 },
    { group = "Cases", key = "MenuTimeoutSeconds", label = "Menu timeout (seconds)", desc = "How long the victim has to decide. After this, unresolved rows can auto-punish.", type = "number", default = 45, min = 5, max = 600 },

    { group = "Unresolved cases", key = "UnresolvedMinHarm", label = "Auto-punish minimum harm", desc = "If the victim never decides, auto-punish only runs when recorded harm is at least this high (also limited by the smallest punish preset).", type = "number", default = 15, min = 0, max = 50 },
    { group = "Unresolved cases", key = "UnresolvedKarmaPenalty", label = "Auto-punish karma", desc = "Karma removed from the attacker when a case expires unresolved.", type = "int", default = 2, min = 0, max = 120 },
    { group = "Unresolved cases", key = "UnresolvedKarmaCapPerRound", label = "Auto-punish cap per round", desc = "Maximum karma one attacker can lose from expired cases in a single round.", type = "int", default = 5, min = 0, max = 120 },

    { group = "Player actions", key = "EnableForgive", label = "Enable forgive", desc = "Lets the victim resolve a case without removing extra karma. Native karma already taken can still be refunded.", type = "bool", default = true },
    { group = "Player actions", key = "EnablePunish", label = "Enable punish", desc = "Lets the victim use punish presets. Also required for unresolved auto-punish.", type = "bool", default = true },
    { group = "Player actions", key = "EnableReport", label = "Enable report", desc = "Lets the victim send the case to online admins.", type = "bool", default = true },
    { group = "Player actions", key = "ManualPunishCapPerRound", label = "Manual punish cap per round", desc = "Maximum karma one attacker can lose from victim punish buttons in a single round.", type = "int", default = 15, min = 0, max = 120 },
    { group = "Player actions", key = "RespectKarmaReward", label = "Respect reward", desc = "Karma given when a Homicide victim uses Give Respect on the player who killed them as a traitor.", type = "number", default = 3, min = 0, max = 50 },

    { group = "Self-defense locks", key = "SelfDefenseSeconds", label = "Self-defense window (seconds)", desc = "How long a recent hit counts for threat review, protected self-defense, and multi-attacker lockout.", type = "number", default = 12, min = 0, max = 120 },
    { group = "Self-defense locks", key = "MultiAttackerMinHarm", label = "Multi-attacker min harm", desc = "Incoming harm needed from each attacker before they count toward a multi-attacker self-defense lock.", type = "number", default = 5, min = 0, max = 50 },
    { group = "Self-defense locks", key = "MultiAttackerCount", label = "Multi-attacker count", desc = "If this many recent attackers hit the defender, punishing the defender is locked as group self-defense.", type = "int", default = 2, min = 1, max = 16 },
    { group = "Self-defense locks", key = "PunishLockMaxResponseRatio", label = "Lock if response ratio is at most", desc = "Punish stays locked when outgoing harm / incoming harm is at or below this (a proportional reply).", type = "number", default = 1.25, min = 0, max = 10 },
    { group = "Self-defense locks", key = "PunishLockKarmaScale", label = "Lock if native karma scale is at most", desc = "Punish stays locked when the native self-defense karma multiplier is this low or lower (0 = fully protected).", type = "number", default = 0.2, min = 0, max = 1 },
    { group = "Self-defense locks", key = "PunishLockIncomingVsHarm", label = "Lock if incoming harm fraction", desc = "Punish stays locked when incoming harm is at least this fraction of the defender's recorded harm and threat is high enough.", type = "number", default = 0.8, min = 0, max = 2 },
    { group = "Self-defense locks", key = "PunishLockMinThreatScore", label = "Lock if threat score is at least", desc = "Used with the incoming-harm fraction above. 1 is maximum threat.", type = "number", default = 0.35, min = 0, max = 1 },

    { group = "Threat & engagement", key = "ThreatMinIncomingHarm", label = "Minimum incoming harm for threat", desc = "Tiny threshold so blocked melee / near-miss gunfire can still count as a threat without needing real damage.", type = "number", default = 0.01, min = 0, max = 10 },
    { group = "Threat & engagement", key = "ProportionalResponseMaxRatio", label = "Proportional response max ratio", desc = "Outgoing / incoming harm at or below this is treated as a proportional reply and uses the light self-defense karma scale.", type = "number", default = 1.25, min = 0.1, max = 10 },
    { group = "Threat & engagement", key = "ModerateResponseMaxRatio", label = "Moderate response max ratio", desc = "Ratios between proportional and this use the medium self-defense karma scale. Higher ratios use the excessive scale.", type = "number", default = 2, min = 0.1, max = 20 },
    { group = "Threat & engagement", key = "SDKarmaProportional", label = "Karma scale: proportional", desc = "Native karma penalty multiplier for a proportional reply when the defender did not strike first.", type = "number", default = 0.15, min = 0, max = 1 },
    { group = "Threat & engagement", key = "SDKarmaProportionalRetaliation", label = "Karma scale: proportional retaliation", desc = "Same as above, but the victim struck first so this is treated as retaliation.", type = "number", default = 0.10, min = 0, max = 1 },
    { group = "Threat & engagement", key = "SDKarmaModerate", label = "Karma scale: moderate over-response", desc = "Native karma penalty multiplier when the reply is heavier than proportional but not extreme.", type = "number", default = 0.45, min = 0, max = 1 },
    { group = "Threat & engagement", key = "SDKarmaModerateRetaliation", label = "Karma scale: moderate retaliation", desc = "Moderate over-response after the victim struck first.", type = "number", default = 0.35, min = 0, max = 1 },
    { group = "Threat & engagement", key = "SDKarmaExcessive", label = "Karma scale: excessive (base)", desc = "Starting native karma penalty multiplier when the reply is far above incoming harm.", type = "number", default = 0.65, min = 0, max = 1 },
    { group = "Threat & engagement", key = "SDKarmaExcessivePerRatio", label = "Karma scale: excessive extra per ratio", desc = "Added to the excessive base for each extra ratio point above the moderate cap, up to 1.", type = "number", default = 0.15, min = 0, max = 1 },
    { group = "Threat & engagement", key = "LethalMeleeMinDamage", label = "Lethal melee weapon damage", desc = "A melee weapon whose primary, secondary, or heavy attack reaches this damage counts as a lethal threat even on a glancing hit.", type = "number", default = 25, min = 0, max = 200 },
    { group = "Threat & engagement", key = "GunfireNearMissRadius", label = "Gunfire near-miss radius", desc = "Units around the head or torso. A bullet passing this close counts as incoming gunfire for self-defense.", type = "number", default = 24, min = 0, max = 128 },
    { group = "Threat & engagement", key = "GuiltyThisLifeThreshold", label = "Guilty-this-life guilt score", desc = "A player is treated as guilty this life if their accumulated guilt exceeds this, or their aggression score is high enough.", type = "number", default = 1, min = 0, max = 100 },
    { group = "Threat & engagement", key = "AggressionScoreThreshold", label = "Guilty aggression score", desc = "Aggression score (0-1) at which a player is treated as already guilty this life.", type = "number", default = 0.15, min = 0, max = 1 },
    { group = "Threat & engagement", key = "RetaliationKillKarmaCap", label = "Retaliation kill karma cap", desc = "Maximum native karma lost for a kill that still looks like credible lethal self-defense.", type = "number", default = 5, min = 0, max = 50 },
    { group = "Threat & engagement", key = "LethalDefenseMinIncoming", label = "Lethal defense min incoming fraction", desc = "Incoming harm / max harm needed before a killing blow can use the retaliation kill cap. 0.35 means 35% of a full life.", type = "number", default = 0.35, min = 0, max = 1 },
    { group = "Threat & engagement", key = "LethalDefenseMaxRatio", label = "Lethal defense max response ratio", desc = "Killing blows above this outgoing/incoming ratio are treated as disproportionate, not capped self-defense.", type = "number", default = 2.5, min = 0.1, max = 20 },
    { group = "Threat & engagement", key = "ForceArmedPenaltyMul", label = "Police vs armed target multiplier", desc = "Native karma/guilt multiplier when law enforcement shoots someone holding a firearm or lethal melee weapon. 0.5 is half penalty.", type = "number", default = 0.5, min = 0, max = 1 },
    { group = "Threat & engagement", key = "AimDotThreshold", label = "Looking-at aim threshold", desc = "Dot product of aim vs target. 1 is dead-on. Used for the armed-look karma reduction.", type = "number", default = 0.8, min = 0, max = 1 },
    { group = "Threat & engagement", key = "ArmedLookPenaltyMul", label = "Armed-and-looking penalty multiplier", desc = "If the victim is aiming at the attacker with a weapon, native harm is multiplied by this (0.5 is half).", type = "number", default = 0.5, min = 0, max = 1 },
    { group = "Threat & engagement", key = "ArmedMeleeLookDistance", label = "Melee look distance", desc = "Max distance for the fists/melee looking-at reduction to apply.", type = "number", default = 90, min = 0, max = 500 },
    { group = "Threat & engagement", key = "PoliceLookDistance", label = "Police melee look distance", desc = "Distance used by police class guilt checks when the target is aiming with fists or melee.", type = "number", default = 72, min = 0, max = 500 },
    { group = "Threat & engagement", key = "PoliceRecentAttackWindow", label = "Police recent-attack window (seconds)", desc = "If the victim attacked anyone this recently, police class guilt treats them as an active threat.", type = "number", default = 10, min = 0, max = 120 },
    { group = "Threat & engagement", key = "ActiveThreatScore", label = "Active threat score", desc = "Threat score needed (with incoming harm) before an exchange is treated as an active fight.", type = "number", default = 0.15, min = 0, max = 1 },

    { group = "Karma economy", key = "MaxHarm", label = "Max harm per attacker", desc = "Harm from one attacker to one victim is capped here. 10 is a full lethal contribution.", type = "number", default = 10, min = 1, max = 50 },
    { group = "Karma economy", key = "MaxKarma", label = "Default max karma", desc = "Karma ceiling for players without a rank-specific cap.", type = "number", default = 120, min = 1, max = 99999 },
    { group = "Karma economy", key = "DefaultKarma", label = "Starting karma", desc = "Karma given to new players and used as the fallback when a value is missing.", type = "number", default = 100, min = 0, max = 99999 },
    { group = "Karma economy", key = "MinKarma", label = "Minimum karma", desc = "Lowest karma before low-karma ban logic. Going to 0 or below bans non-immune players.", type = "number", default = -60, min = -500, max = 0 },
    { group = "Karma economy", key = "BanResetKarma", label = "Karma after low-karma ban", desc = "Karma written after a player is banned for hitting 0 karma.", type = "number", default = 10, min = 0, max = 120 },
    { group = "Karma economy", key = "BanMinutesBase", label = "Low-karma ban minutes (base)", desc = "Ban length is base minus (karma * per-point), with a floor. More negative karma means a longer ban.", type = "number", default = 60, min = 1, max = 10080 },
    { group = "Karma economy", key = "BanMinutesPerNegativeKarma", label = "Low-karma ban extra minutes per karma", desc = "Each karma point below 0 adds this many minutes (the formula uses a negative karma value).", type = "number", default = 4, min = 0, max = 60 },
    { group = "Karma economy", key = "TeamDamageBanMinutes", label = "Team-damage guilt ban minutes", desc = "Ban length when a mode's GuiltCheck requests a ban and the attacker's guilt reaches the team-damage limit.", type = "int", default = 30, min = 0, max = 10080 },
    { group = "Karma economy", key = "TeamDamageGuiltLimit", label = "Team-damage guilt ban threshold", desc = "Guilt score needed, together with a mode GuiltCheck ban flag, to issue the team-damage ban.", type = "number", default = 100, min = 0, max = 1000 },
    { group = "Karma economy", key = "NativeGuiltMul", label = "Native karma penalty multiplier", desc = "Global multiplier on native karma removed from harm. 2 is the current default.", type = "number", default = 2, min = 0, max = 10 },
    { group = "Karma economy", key = "NativeGuiltScale", label = "Native guilt points per full life", desc = "Guilt added for a full lethal contribution before engagement scaling. Also used to fade extra karma on repeat hits to the same victim.", type = "number", default = 60, min = 1, max = 500 },
    { group = "Karma economy", key = "NativeGuiltPairCap", label = "Guilt cap vs one victim", desc = "Maximum stored guilt from one attacker toward one victim.", type = "number", default = 200, min = 1, max = 1000 },
    { group = "Karma economy", key = "TraitorKillKarmaReward", label = "Auto traitor-kill reward", desc = "Karma given immediately for killing a traitor when enough players are on the server. Separate from the Respect button.", type = "number", default = 3, min = 0, max = 50 },
    { group = "Karma economy", key = "HelpfulActionMinPlayers", label = "Minimum players for rewards", desc = "Traitor-kill auto reward, round-survive bonus, and bandage bonus only apply at this player count or higher.", type = "int", default = 10, min = 0, max = 128 },
    { group = "Karma economy", key = "RoundSurviveKarma", label = "Round survive bonus", desc = "Karma given at round end to living non-traitors when the player-count requirement is met.", type = "number", default = 1, min = 0, max = 50 },
    { group = "Karma economy", key = "BandageKarma", label = "Bandage bonus", desc = "Karma given for bandaging another player during an active round.", type = "number", default = 0.6, min = 0, max = 50 },
    { group = "Karma economy", key = "KarmaRegenInterval", label = "Passive regen interval (seconds)", desc = "How often living players gain the passive karma amount during an active round.", type = "number", default = 120, min = 1, max = 3600 },
    { group = "Karma economy", key = "KarmaRegenDefault", label = "Passive regen amount", desc = "Karma added each regen interval. Also the reset value after a dirty round.", type = "number", default = 0.75, min = 0, max = 50 },
    { group = "Karma economy", key = "KarmaRegenCleanBonus", label = "Clean-round regen bonus", desc = "Added to the player's regen amount at round start if they stayed below the clean-round guilt threshold.", type = "number", default = 0.25, min = 0, max = 50 },
    { group = "Karma economy", key = "KarmaRegenMin", label = "Minimum regen amount", desc = "Lowest the per-player regen amount can fall.", type = "number", default = 0.75, min = 0, max = 50 },
    { group = "Karma economy", key = "KarmaRegenMax", label = "Maximum regen amount", desc = "Highest the per-player regen amount can climb from clean rounds.", type = "number", default = 1.5, min = 0, max = 50 },
    { group = "Karma economy", key = "CleanRoundGuiltThreshold", label = "Clean-round guilt threshold", desc = "At round start, guilt below this counts as a clean round and increases regen.", type = "number", default = 1, min = 0, max = 100 },
    { group = "Karma economy", key = "FallPushGuilt", label = "Fall-push guilt", desc = "Guilt added when knocking someone into a lethal fall, after engagement scaling.", type = "number", default = 5, min = 0, max = 100 },
    { group = "Karma economy", key = "SuicideRefundRate", label = "Innocent-kill suicide refund rate", desc = "Fraction of karma lost for killing innocents that is refunded if that player suicides soon after.", type = "number", default = 0.1, min = 0, max = 1 },
    { group = "Karma economy", key = "SuicideRefundWindow", label = "Suicide refund window (seconds)", desc = "The suicide has to happen within this many seconds of the player's own suicide damage to refund innocent-kill losses.", type = "number", default = 30, min = 0, max = 300 },

    { group = "Low karma effects", key = "SeizureKarmaBelow", label = "Seizure below karma", desc = "Players under this karma can randomly seize during a round (staff-immune groups are skipped).", type = "number", default = 50, min = 0, max = 120 },
    { group = "Low karma effects", key = "SeizureDuration", label = "Seizure duration (seconds)", desc = "How long a low-karma seizure lasts.", type = "number", default = 15, min = 1, max = 120 },
    { group = "Low karma effects", key = "VomitKarmaBelow", label = "Vomit below karma", desc = "Players under this karma can randomly vomit.", type = "number", default = 35, min = 0, max = 120 },
    { group = "Low karma effects", key = "VomitChance", label = "Vomit chance (1 in N)", desc = "Each organism think, 1 in this many chance to vomit when below the vomit karma threshold.", type = "int", default = 2000, min = 1, max = 100000 },

    { group = "Logging", key = "LogAdminActions", label = "Log guilt actions", desc = "Append forgive / punish / report / auto-punish lines to data/zcity_guilt/log.txt.", type = "bool", default = true },
    { group = "Logging", key = "StaffReportPrefix", label = "Staff report prefix", desc = "Text placed in front of admin chat when a victim reports a player.", type = "string", default = "[GUILT REPORT] " }
}

local function clampSetting(field, value)
    if field.type == "bool" then
        return value == true
    end

    if field.type == "string" then
        if value == nil then return field.default end
        return tostring(value)
    end

    value = tonumber(value)
    if value == nil then value = field.default end
    if field.min then value = math.max(field.min, value) end
    if field.max then value = math.min(field.max, value) end
    if field.type == "int" then value = math.floor(value) end
    return value
end

local function defaultConfig()
    local cfg = {
        Presets = {
            { id = "punish_minor", name = "Minor Punish", amount = 5, minharm = 5, color = { r = 210, g = 210, b = 90 } },
            { id = "punish_major", name = "Major Punish", amount = 10, minharm = 10, color = { r = 255, g = 170, b = 60 } },
            { id = "punish_severe", name = "Severe Punish", amount = 15, minharm = 15, color = { r = 255, g = 90, b = 90 } }
        }
    }

    for _, field in ipairs(ZCITY_GUILT.Settings) do
        cfg[field.key] = field.default
    end

    return cfg
end

ZCITY_GUILT.DefaultConfig = defaultConfig()

local function applyAliases(src)
    if not istable(src) then return src end

    for old, new in pairs(ZCITY_GUILT.SettingAliases) do
        if src[new] == nil and src[old] ~= nil then
            src[new] = src[old]
        end
    end

    return src
end

function ZCITY_GUILT.SanitizeConfig(incoming)
    local src = applyAliases(istable(incoming) and table.Copy(incoming) or {})
    local out = defaultConfig()

    for _, field in ipairs(ZCITY_GUILT.Settings) do
        out[field.key] = clampSetting(field, src[field.key])
    end

    out.Presets = istable(src.Presets) and src.Presets or out.Presets
    local presets = {}
    for i, p in ipairs(out.Presets) do
        if istable(p) then
            local color = istable(p.color) and p.color or {}
            presets[#presets + 1] = {
                id = tostring(p.id or ("preset_" .. i)),
                name = tostring(p.name or ("Preset " .. i)),
                amount = math.Clamp(math.floor(tonumber(p.amount) or 0), 0, 120),
                minharm = math.max(0, tonumber(p.minharm) or 0),
                color = {
                    r = math.Clamp(math.floor(tonumber(color.r) or 255), 0, 255),
                    g = math.Clamp(math.floor(tonumber(color.g) or 255), 0, 255),
                    b = math.Clamp(math.floor(tonumber(color.b) or 255), 0, 255)
                }
            }
        end
    end
    out.Presets = presets

    zb.MaximumHarm = out.MaxHarm
    zb.MaxKarma = out.MaxKarma
    return out
end

ZCITY_GUILT.Config = ZCITY_GUILT.SanitizeConfig(ZCITY_GUILT.Config)

function ZCITY_GUILT.GetPreset(action)
    for _, preset in ipairs((ZCITY_GUILT.Config and ZCITY_GUILT.Config.Presets) or {}) do
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
    local c = istable(preset and preset.color) and preset.color or {}
    return Color(tonumber(c.r) or 255, tonumber(c.g) or 255, tonumber(c.b) or 255)
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

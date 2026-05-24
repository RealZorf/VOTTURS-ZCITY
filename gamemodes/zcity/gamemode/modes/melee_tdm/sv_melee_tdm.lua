local MODE = MODE

MODE.name = "melee_tdm"
MODE.start_time = 20
MODE.ROUND_TIME = 240
MODE.Chance = 0.04
MODE.buymenu = false

local meleeWeapons = {
    "weapon_hg_wrench",
    "weapon_hg_razor",
    "weapon_hg_pitchfork",
    "weapon_hg_pitchfork",
    "weapon_pan",
    "weapon_bat",
    "weapon_brick",
    "weapon_hg_machete",
    "weapon_kitchenknife",
    "weapon_screwdriver",
    "weapon_hg_fubar",
    "weapon_hg_bottle",
    "weapon_hg_cinderblock",
}

local supportItems = {
    "weapon_bigbandage_sh",
    "weapon_painkillers",
    "weapon_ducttape",
}

function MODE.GuiltCheck(attacker, victim, add, harm, amt)
    return 1, true
end

function MODE:CanLaunch()
    return true
end

util.AddNetworkString("melee_tdm_start")
function MODE:Intermission()
    game.CleanUpMap()

    for _, ply in player.Iterator() do
        ply:SetupTeam(ply:Team())
    end

    net.Start("melee_tdm_start")
        net.WriteString(self.name)
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
    local endround = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end

function MODE:RoundStart()
    for _, ply in player.Iterator() do
        ply:Freeze(false)
    end
end

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in player.Iterator() do
            if not ply:Alive() then continue end

            local inv = ply:GetNetVar("Inventory") or {}
            inv["Weapons"] = inv["Weapons"] or {}
            inv["Weapons"]["hg_sling"] = true
            ply:SetNetVar("Inventory", inv)

            ply:SetSuppressPickupNotices(true)
            ply.noSound = true

            if ply:Team() == 1 then
                ply:SetPlayerClass("swat")
                zb.GiveRole(ply, "Counter Terrorist", Color(0, 0, 190))
                ply:SetNetVar("CurPluv", "pluvberet")
            else
                ply:SetPlayerClass("terrorist")
                zb.GiveRole(ply, "Terrorist", Color(190, 0, 0))
                ply:SetNetVar("CurPluv", "pluvboss")
            end

            local meleeWeapon = ply:Give(table.Random(meleeWeapons))
            for _, itemClass in ipairs(supportItems) do
                ply:Give(itemClass)
            end

            ply.organism.allowholster = true

            local radio = ply:Give("weapon_walkie_talkie")
            if IsValid(radio) then
                radio.Frequency = (ply:Team() == 1 and math.Round(math.Rand(88, 95), 1)) or math.Round(math.Rand(100, 108), 1)
            end

            local hands = ply:Give("weapon_hands_sh")
            if IsValid(meleeWeapon) then
                ply:SelectWeapon(meleeWeapon:GetClass())
            elseif IsValid(hands) then
                ply:SelectWeapon("weapon_hands_sh")
            end

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply.noSound = false
                    ply:SetSuppressPickupNotices(false)
                end
            end)
        end
    end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
    return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
end

function MODE:CanSpawn()
end

util.AddNetworkString("melee_tdm_roundend")
function MODE:EndRound()
    timer.Simple(2, function()
        net.Start("melee_tdm_roundend")
        net.Broadcast()
    end)

    local _, winner = zb:CheckWinner(self:CheckAlivePlayers())
    for _, ply in player.Iterator() do
        if ply:Team() == winner then
            ply:GiveExp(math.random(15, 30))
            ply:GiveSkill(math.Rand(0.1, 0.15))
        else
            ply:GiveSkill(-math.Rand(0.05, 0.1))
        end
    end
end

function MODE:PlayerDeath(ply)
end

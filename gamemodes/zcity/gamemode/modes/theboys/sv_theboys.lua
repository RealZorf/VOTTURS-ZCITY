local MODE = MODE

MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.ForBigMaps = false
MODE.Chance = 0.03

MODE.ROUND_TIME = MODE.HideTime + MODE.HuntTime

util.AddNetworkString("theboys_start")
util.AddNetworkString("theboys_end")
util.AddNetworkString("theboys_hunt_begin")

function MODE:CanLaunch()
    local active = 0
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            active = active + 1
        end
    end
    return active >= 2
end

function MODE:Intermission()
    game.CleanUpMap()

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        if ply.PlayerClassName == "homelander" then
            ply:SetPlayerClass()
        end

        ApplyAppearance(ply)
        ply:SetupTeam(0)
    end

    self.Homelander = nil
    self.HuntStarted = false

    net.Start("theboys_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    local alive = {}
    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end
        if ply.organism and ply.organism.incapacitated then continue end
        alive[#alive + 1] = ply
    end
    return alive
end

function MODE:GetHidersAlive()
    local count = 0
    for _, ply in player.Iterator() do
        if ply.PlayerClassName == "homelander" then continue end
        if ply:Team() == TEAM_SPECTATOR then continue end
        if not ply:Alive() then continue end
        if ply.organism and ply.organism.incapacitated then continue end
        count = count + 1
    end
    return count
end

function MODE:ShouldRoundEnd()
    if not IsValid(self.Homelander) or not self.Homelander:Alive() then
        return true
    end
    return self:GetHidersAlive() <= 0
end

local function pickHomelander()
    local candidates = {}
    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        if not ply:Alive() then continue end
        candidates[#candidates + 1] = ply
    end
    return candidates[math.random(#candidates)]
end

function MODE:MakeHider(ply)
    if not IsValid(ply) then return end

    ply:Give("weapon_hands_sh")

    local fb = ply:Give(MODE.PlayerFlashbang)
    if IsValid(fb) then
        fb.count = 3
    end

    ply:SelectWeapon("weapon_hands_sh")

    zb.GiveRole(ply, "Hider", Color(0, 120, 190))
end

local function computeHuntDuration(hiderCount)
    return math.Clamp(180 + hiderCount * 60, 180, MODE.HuntTime)
end

function MODE:RoundStart()
    self.HuntStarted = false
    self.HuntDeadline = nil

    local home = pickHomelander()
    if not IsValid(home) then return end
    self.Homelander = home

    local hiderCount = 0
    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end
        ply:SetSuppressPickupNotices(true)
        ply.noSound = true

        if ply == home then
            ply:SetPlayerClass("homelander")
            ply:SetNWBool("TheBoysHidden", true)
        else
            if ply.PlayerClassName == "homelander" then
                ply:SetPlayerClass()
            end
            self:MakeHider(ply)
            hiderCount = hiderCount + 1
        end

        timer.Simple(0.1, function()
            if IsValid(ply) then ply.noSound = false end
        end)
        ply:SetSuppressPickupNotices(false)
    end

    self.CurrentHuntTime = computeHuntDuration(hiderCount)
    SetGlobalFloat("TheBoysHuntTime", self.CurrentHuntTime)
    self.HuntDeadline = CurTime() + MODE.HideTime + self.CurrentHuntTime
end

function MODE:GiveWeapons() end
function MODE:GiveEquipment() end

function MODE:RoundThink()
    if not self.HuntStarted and (zb.ROUND_START or 0) + MODE.HideTime <= CurTime() then
        self.HuntStarted = true
        if IsValid(self.Homelander) then
            self.Homelander:SetNWBool("TheBoysHidden", false)
        end
        net.Start("theboys_hunt_begin")
        net.Broadcast()
    end

    if self.HuntDeadline and self.HuntDeadline <= CurTime() then
        zb:EndRound()
    end
end

hook.Add("StartCommand", "TheBoysFreezeHide", function(ply, cmd)
    local mode = CurrentRound()
    if not mode or mode.name ~= "theboys" then return end
    if not cmd then return end

    if ply.PlayerClassName == "homelander" then
        if (zb.ROUND_START or 0) + MODE.HideTime > CurTime() then
            cmd:ClearMovement()
            cmd:ClearButtons()
        end
    end
end)

function MODE:PlayerDeath(ply)
    if ply == self.Homelander then
        self.Homelander = nil
    end
end

function MODE:CanSpawn() end

function MODE:EndRound()
    self.HuntDeadline = nil
    self.HuntStarted = false

    local home = self.Homelander
    local hidersAlive = self:GetHidersAlive() > 0
    local winnerSide = (IsValid(home) and home:Alive() and not hidersAlive) and 0 or 1

    timer.Simple(2, function()
        net.Start("theboys_end")
        net.WriteUInt(winnerSide, 2)
        net.WriteEntity(IsValid(home) and home or NULL)
        net.Broadcast()
    end)

    for _, ply in player.Iterator() do
        if ply.PlayerClassName == "homelander" then
            ply:SetPlayerClass()
        end
        ply:SetNWBool("TheBoysHidden", false)
    end
end

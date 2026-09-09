local MODE = MODE
local zombieClasses = {headcrabzombie = true, fastzombie = true, poisonzombie = true}

function MODE:CanGiveUpInfected(ply)
    if CurrentRound() ~= self or zb.ROUND_STATE ~= 1 then return false end
    if not IsValid(ply) or not ply:Alive() or ply:GetNWBool("ZS_Extracted", false) then return false end
    if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then return false end
    if not ply.organism or ply.organism.otrub ~= true then return false end
    if SERVER and not self.InfectionStarted then return false end
    if CLIENT and not GetGlobalBool("ZS_InfectionStarted", false) then return false end
    return ply:GetNWBool("ZS_IsZombie", false) or zombieClasses[ply.PlayerClassName] == true
        or (ply:GetNetVar("headcrab", false) and true or false)
end

if SERVER then
    util.AddNetworkString("ZS_GiveUpInfected")
    net.Receive("ZS_GiveUpInfected", function(_, ply)
        if not MODE:CanGiveUpInfected(ply) then return end
        if (ply.ZSNextGiveUp or 0) > CurTime() then return end
        ply.ZSNextGiveUp = CurTime() + 1
        if not ply.ZSIsZombie then
            local class = ply.organism.headcrabZombieClass
            if not zombieClasses[class] then class = zombieClasses[ply.PlayerClassName] and ply.PlayerClassName or "headcrabzombie" end
            ply.ZSPendingDeathZombieClass = class
        end
        MODE:StopZombieDrag(ply)
        MODE:StopZombieConsume(ply)
        ply:Kill()
    end)
else
    local nextRequest = 0
    hook.Add("PlayerButtonDown", "ZS_GiveUpInfected", function(ply, button)
        if ply ~= LocalPlayer() or button ~= KEY_R or not MODE:CanGiveUpInfected(ply) then return end
        if gui.IsGameUIVisible() or vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus()) then return end
        if CurTime() < nextRequest then return end
        nextRequest = CurTime() + 1
        net.Start("ZS_GiveUpInfected")
        net.SendToServer()
    end)
    hook.Add("PostDrawHUD", "ZS_GiveUpInfectedHint", function()
        if not MODE:CanGiveUpInfected(LocalPlayer()) then return end
        draw.SimpleTextOutlined("PRESS R TO DIE AND REANIMATE", "ZC_ZS_Status", ScrW() / 2, ScrH() * 0.72,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
    end)
end

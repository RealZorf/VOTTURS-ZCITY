local MODE = MODE

function MODE:TryZombieDrag(hands)
    local ply = hands:GetOwner()
    if zb.ROUND_STATE ~= 1 or ply.PlayerClassName ~= "headcrabzombie" then return false end
    if SERVER then self:StartZombieDrag(ply, hands) end
    return true
end

if CLIENT then
    hook.Add("HUDPaint", "ZS_DragHelp", function()
        if CurrentRound() ~= MODE or zb.ROUND_STATE ~= 1 then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or ply.PlayerClassName ~= "headcrabzombie" or not ply:GetNWBool("ZS_IsZombie", false) then return end
        local text
        if IsValid(ply:GetNWEntity("ZS_DragVictim")) then
            text = "DRAGGING — hold RMB • release to let go"
        else
            local tr = hg.eyeTrace(ply, 90)
            local victim = tr and IsValid(tr.Entity) and (tr.Entity:IsPlayer() and tr.Entity or hg.RagdollOwner(tr.Entity))
            if IsValid(victim) and victim:Alive() and not victim:GetNWBool("ZS_IsZombie", false) then
                text = "HOLD RMB — DRAG SURVIVOR"
            end
        end
        if text then draw.SimpleTextOutlined(text, "ZC_ZS_SpawnReason", ScrW() / 2, ScrH() / 2 + 65, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black) end
    end)
end

hook.Add("HG_MovementCalc_2", "ZS_DragSpeed", function(mul, ply)
    if CurrentRound() == MODE and IsValid(ply:GetNWEntity("ZS_DragVictim")) then mul[1] = (mul[1] or 1) * 0.7 end
end)

if not SERVER then return end
local dragging = {}

function MODE:StopZombieDrag(ply)
    local data = dragging[ply]
    if not data then return end
    dragging[ply] = nil
    if IsValid(data.rag) and data.rag.ZSDragger == ply then data.rag.ZSDragger = nil end
    if IsValid(ply) then
        ply.ZSDragData = nil
        ply.ZSNextDrag = CurTime() + 1
        ply:SetNWEntity("ZS_DragVictim", NULL)
    end
    if IsValid(data.hands) and data.hands.CarryEnt == data.rag then data.hands:SetCarrying() end
end

local function CanDrag(ply)
    return IsValid(ply) and ply:Alive() and ply.ZSIsZombie and ply.PlayerClassName == "headcrabzombie" and not ply.ZSConsumeData
        and not IsValid(ply.FakeRagdoll) and not (ply.organism and ply.organism.otrub)
        and ply:KeyDown(IN_ATTACK2) and not ply:KeyDown(IN_ATTACK)
        and not ply:GetNetVar("handcuffed", false)
end

hook.Remove("KeyPress", "ZS_StartDrag")
function MODE:StartZombieDrag(ply, hands)
    if CurrentRound() ~= self or zb.ROUND_STATE ~= 1 then return end
    if not CanDrag(ply) or dragging[ply] or (ply.ZSNextDrag or 0) > CurTime() then return end
    if not IsValid(hands) or ply:GetActiveWeapon() ~= hands or hands:GetClass() ~= "weapon_hands_sh" or IsValid(hands.CarryEnt) then return end
    local origin = hg.eye(ply)
    local tr = util.TraceLine({start = origin, endpos = origin + ply:GetAimVector() * hands.ReachDistance,
        filter = {ply, hg.GetCurrentCharacter(ply)}})
    if not tr.Hit then
        tr = util.TraceHull({start = origin, endpos = origin + ply:GetAimVector() * hands.ReachDistance,
            filter = {ply, hg.GetCurrentCharacter(ply)}, mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6)})
    end
    local rag = tr and tr.Entity
    local victim = IsValid(rag) and (rag:IsPlayer() and rag or hg.RagdollOwner(rag))
    if not IsValid(victim) or not victim:Alive() or victim.ZSIsZombie or victim == ply then return end
    if victim:Team() == TEAM_SPECTATOR or victim:Team() == TEAM_UNASSIGNED or IsValid(rag.ZSDragger) then return end
    local bone = tr.PhysicsBone or 0
    if rag:IsPlayer() then
        ply.ZSNextDrag = CurTime() + 0.5
        hg.LightStunPlayer(victim, 3)
        rag = victim.FakeRagdoll
        if not IsValid(rag) or hg.RagdollOwner(rag) ~= victim then return end
        local nearestDistance = math.huge
        for index = 0, rag:GetPhysicsObjectCount() - 1 do
            local candidate = rag:GetPhysicsObjectNum(index)
            if IsValid(candidate) then
                local distance = candidate:GetPos():DistToSqr(tr.HitPos)
                if distance < nearestDistance then bone, nearestDistance = index, distance end
            end
        end
        local grabbed = rag:GetPhysicsObjectNum(bone)
        if not IsValid(grabbed) then return end
        tr.HitPos = grabbed:GetPos()
    end
    local phys = rag:GetPhysicsObjectNum(bone)
    if not IsValid(phys) or not phys:IsMotionEnabled() then return end
    local data = {rag = rag, victim = victim, hands = hands, bone = bone}
    dragging[ply] = data
    ply.ZSDragData = data
    rag.ZSDragger = ply
    ply:SetNWEntity("ZS_DragVictim", victim)
    hands:SetCarrying(rag, bone, tr.HitPos, origin:Distance(tr.HitPos))
    hands:ApplyForce()
end

local nextUpdate = 0
hook.Add("Think", "ZS_UpdateDrag", function()
    if CurTime() < nextUpdate then return end
    nextUpdate = CurTime() + 0.05
    for ply, data in pairs(dragging) do
        local rag, victim, hands = data.rag, data.victim, data.hands
        if CurrentRound() ~= MODE or zb.ROUND_STATE ~= 1 or not CanDrag(ply)
            or not IsValid(rag) or not IsValid(victim) or not victim:Alive() or victim.ZSIsZombie
            or hg.RagdollOwner(rag) ~= victim or not IsValid(hands) or ply:GetActiveWeapon() ~= hands
            or hands.CarryEnt ~= rag then MODE:StopZombieDrag(ply) continue end
        local phys = rag:GetPhysicsObjectNum(data.bone)
        if not IsValid(phys) or not phys:IsMotionEnabled() then MODE:StopZombieDrag(ply) continue end
        local origin = ply:GetShootPos()
        local pos = phys:GetPos()
        local trace = util.TraceLine({start = origin, endpos = pos, filter = {ply, rag}, mask = MASK_SOLID})
        if origin:DistToSqr(pos) > 150 ^ 2 or trace.Hit then MODE:StopZombieDrag(ply) continue end
    end
end)

hook.Add("HomigradDamage", "ZS_RescueDragVictim", function(ent, damage, hitgroup, source, harm)
    local ply = IsValid(ent) and (ent:IsPlayer() and ent or hg.RagdollOwner(ent))
    if IsValid(ply) and dragging[ply] and (tonumber(harm) or 0) >= 4 then MODE:StopZombieDrag(ply) end
end)

hook.Add("ZB_EndRound", "ZS_ClearDragging", function()
    for ply in pairs(dragging) do MODE:StopZombieDrag(ply) end
end)
hook.Add("PlayerDisconnected", "ZS_ClearDisconnectedDrag", function(ply)
    MODE:StopZombieDrag(ply)
end)

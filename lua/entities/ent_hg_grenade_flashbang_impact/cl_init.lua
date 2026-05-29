include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local view = render.GetViewSetup(true)
    local diff = (view.origin - targetVec):GetNormalized()
    return view.angles:Forward():Dot(diff)
end

net.Receive("flashbang_impact", function()
    local pos = net.ReadVector()
    local mul = net.ReadFloat()
    if not mul or mul <= 0 then mul = 1 end

    local time = math.Clamp(5200 - (lply:GetPos():Distance(pos)), 1, 5) * mul

    lply:AddTinnitus(time, true)

    local IsLookingFlash = IsLookingAt(lply, pos)
    local viewsetup = render.GetViewSetup(true)

    if IsLookingFlash < -0.5 then
        hg.AddFlash(viewsetup.origin, IsLookingFlash, pos, time * 5, 50000)
    end

    hook.Add("RenderScreenspaceEffects", "FlashedImpact", function()
        if lply.tinnitus - CurTime() < 0 then
            lply.tinnitus = nil
            hook.Remove("RenderScreenspaceEffects", "FlashedImpact")
            return
        end
    end)
end)

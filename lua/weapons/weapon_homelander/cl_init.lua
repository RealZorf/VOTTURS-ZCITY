
include("shared.lua")

local TBOYS = theboysbase
local HOMELANDER_SHARED = HomelanderSWEPShared
local THEBOYS_DISMEMBER_BONES = HOMELANDER_SHARED.THEBOYS_DISMEMBER_BONES or TBOYS.DismemberBones
local HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET = HOMELANDER_SHARED.HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET
local HOMELANDER_MODE_NORMAL = HOMELANDER_SHARED.HOMELANDER_MODE_NORMAL
local HOMELANDER_MODE_STRONG = HOMELANDER_SHARED.HOMELANDER_MODE_STRONG
local HOMELANDER_MODE_GRAB = HOMELANDER_SHARED.HOMELANDER_MODE_GRAB
local HomelanderGetEyePositions = HOMELANDER_SHARED.HomelanderGetEyePositions
local invalidateHomelanderBoneCache = HOMELANDER_SHARED.invalidateHomelanderBoneCache
local debugHomelanderDismember = HOMELANDER_SHARED.debugHomelanderDismember or function() end
local isHomelanderActive = HOMELANDER_SHARED.isHomelanderActive
local isHomelanderCharacter = HOMELANDER_SHARED.isHomelanderCharacter or function(ent)
    return IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()))
end
local SHOCKWAVE_EFFECT = HOMELANDER_SHARED.SHOCKWAVE_EFFECT
local STRONG_PUNCH_EFFECT = HOMELANDER_SHARED.STRONG_PUNCH_EFFECT
local WEAPON_CLASS = HOMELANDER_SHARED.WEAPON_CLASS

if CLIENT then
    CreateClientConVar("homelander_cl_eye_fallback_side_offset", "1.3", true, true, "Fallback side eye offset.", -20, 20)
    CreateClientConVar("homelander_cl_eye_fallback_forward_offset", "0.45", true, true, "Fallback forward eye offset.", -20, 20)
    CreateClientConVar("homelander_cl_eye_fallback_height_offset", "0", true, true, "Fallback height eye offset.", -20, 20)
    CreateClientConVar("homelander_cl_idle_eye_glow", "1", true, false, "Draw idle eye glow when heat vision is not firing.", 0, 1)
    CreateClientConVar("homelander_cl_dismember_debug", "0", true, false, "Print Homelander client dismember debug events.", 0, 1)

    SWEP.WepSelectIcon = surface.GetTextureID("vgui/entities/weapon_homelander")
    SWEP.IconOverride = "vgui/entities/weapon_homelander"


    local matEyeWide = Material("effects/lensflare/bar")
    local matEyeThin = Material("effects/lensflare/bar_3")
    local matLaserCore = Material("homelander/laser_core")
    local matLaserGlow = Material("homelander/laser_glow")
    local matHitFlare = Material("effects/lensflare/bar")
    local matHitCenter = Material("effects/lensflare/bar_3")
    local matSonicBoomCone = Material("effects/select_ring")

    local whiteCore = Color(255, 255, 255, 255)
    local beamCore = Color(255, 255, 255, 255)
    local beamGlow = Color(255, 120, 120, 210)
    local lastFlightState = {}
    local activeFlightTrails = {}
    local flightRenderState = {}
    local grabArmPoseState = {}
    local eyeAfterglowUntil = {}
    local activeDebris = {}
    local outfitterVisualRagdolls = {}
    local laserDismemberOwners = {}
    local resetHomelanderDismemberBones
    local matImpactSmoke = Material("particle/particle_smokegrenade")
    local MAX_ACTIVE_PUNCH_DEBRIS = 90
    local activeGoreGibs = {}
    local MAX_GIB_BLOOD_DECALS_PER_THINK = 8
    local GIB_BLOOD_DECAL_INTERVAL = 0.28
    local goreBloodDecalMaterials = {
        Material("decals/blood1"),
        Material("decals/blood2"),
        Material("decals/blood3"),
        Material("decals/blood4"),
        Material("decals/blood5"),
        Material("decals/blood6")
    }
    local modeIconMaterials = {
        [HOMELANDER_MODE_NORMAL] = Material("homelander/normal_punch.png", "smooth"),
        [HOMELANDER_MODE_STRONG] = Material("homelander/strong_punch.png", "smooth"),
        [HOMELANDER_MODE_GRAB] = Material("homelander/grab.png", "smooth")
    }

    local function getClientBool(cvarName, fallback)
        local cvar = GetConVar(cvarName)
        if not cvar then return fallback end
        return cvar:GetBool()
    end

    local function getClientFloat(cvarName, fallback, minValue, maxValue)
        local cvar = GetConVar(cvarName)
        local value = cvar and cvar:GetFloat() or fallback
        return math.Clamp(value, minValue, maxValue)
    end

    local function isHomelanderBloodEnabled()
        return getClientBool("theboysbase_cl_blood_enabled", true)
    end

    local function isHomelanderGoreEnabled()
        return getClientBool("theboysbase_cl_gore_enabled", true)
    end

    local function isHomelanderDismemberEnabled()
        return not TBOYS.IsDismemberEnabled or TBOYS.IsDismemberEnabled()
    end

    local function getHomelanderBloodDecalAmount()
        return getClientFloat("theboysbase_cl_blood_amount", getClientFloat("theboysbase_cl_gore_amount", 1, 0, 2), 0, 2)
    end

    local function getHomelanderBloodDecalScatter(amount, baseScatter)
        amount = math.Clamp(amount or getHomelanderBloodDecalAmount(), 0, 2)
        return (baseScatter or 24) * (0.35 + amount * 0.85)
    end

    local function buildGoreModelsForMode(kind, mode, gibAmount)
        return TBOYS.BuildGoreModelsForMode(kind, mode, gibAmount)
    end

    local function pruneClientGoreGibs()
        local limit = math.max(math.floor(getClientFloat("theboysbase_cl_gore_gib_limit", 180, 0, 1000)), 0)

        for i = #activeGoreGibs, 1, -1 do
            local ent = activeGoreGibs[i]
            if not IsValid(ent) then
                table.remove(activeGoreGibs, i)
            end
        end

        while #activeGoreGibs > limit do
            local ent = table.remove(activeGoreGibs, 1)
            if IsValid(ent) then ent:Remove() end
        end
    end

    local function placeRandomBloodDecal(hitPos, hitNormal, sizeMin, sizeMax, ent)
        local material = goreBloodDecalMaterials[math.random(#goreBloodDecalMaterials)]
        if type(material) ~= "IMaterial" or material:IsError() then
            util.Decal("Blood", hitPos + hitNormal * 2, hitPos - hitNormal * 10, ent)
            return
        end

        local size = math.Rand(sizeMin or 0.7, sizeMax or 1.15)
        util.DecalEx(material, IsValid(ent) and ent or Entity(0), hitPos, hitNormal, color_white, size, size)
    end

    local function spawnClientGoreGib(modelData, pos, dir, velocityScale)
        local model = istable(modelData) and modelData.model or modelData
        local gib = ClientsideModel(model, RENDERGROUP_OPAQUE)
        if not IsValid(gib) then return end

        gib:SetPos(pos + VectorRand() * math.Rand(2, 12))
        gib:SetAngles(AngleRand())
        gib:SetModelScale((istable(modelData) and modelData.scale or 1) or 1, 0)
        gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        if gib.PhysicsInit then
            gib:PhysicsInit(SOLID_VPHYSICS)
        end
        if gib.SetMoveType then
            gib:SetMoveType(MOVETYPE_VPHYSICS)
        end
        if gib.SetSolid then
            gib:SetSolid(SOLID_VPHYSICS)
        end

        local phys = gib:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocity((dir * math.Rand(280, 760) + VectorRand() * math.Rand(170, 460) + vector_up * math.Rand(80, 240)) * velocityScale)
            phys:AddAngleVelocity(VectorRand() * math.Rand(120, 360))
        end

        activeGoreGibs[#activeGoreGibs + 1] = gib
        gib.HomelanderLastBloodDecalPos = gib:GetPos()
        gib.HomelanderNextBloodDecalTime = CurTime() + math.Rand(0.04, 0.2)
        pruneClientGoreGibs()

        local lifetime = math.floor(getClientFloat("theboysbase_cl_gore_gib_lifetime", 45, -1, 180))
        if lifetime ~= -1 then
            timer.Simple(lifetime, function()
                if IsValid(gib) then gib:Remove() end
            end)
        end
    end

    local function spawnClientBloodFX(pos, dir, bloodDecalAmount)
        if not isHomelanderBloodEnabled() then return end

        local bounds = 10
        local effect = EffectData()
        effect:SetFlags(BLOOD_COLOR_RED)
        effect:SetOrigin(pos - Vector(bounds, bounds, bounds))
        effect:SetStart(pos + Vector(bounds, bounds, bounds))
        util.Effect("theboys_gib_burst", effect, true, true)
        ParticleEffect(TBOYS.Particles.BloodImpactRed, pos, dir:Angle())

        local count = math.random(10, 18)
        for _ = 1, count do
            local bloodDir = (dir + VectorRand() * 0.65 + vector_up * math.Rand(0.05, 0.75)):GetNormalized()
            local bloodPos = pos + VectorRand() * math.Rand(0, 18)

            local impact = EffectData()
            impact:SetOrigin(bloodPos)
            impact:SetNormal(bloodDir)
            impact:SetScale(math.Rand(18, 42))
            impact:SetMagnitude(math.Rand(10, 24))
            impact:SetRadius(math.Rand(10, 24))
            impact:SetColor(BLOOD_COLOR_RED or 0)
            util.Effect("BloodImpact", impact, true, true)
        end

        local decalCount = math.floor(math.Rand(6, 12) * bloodDecalAmount + 0.5)
        local scatter = getHomelanderBloodDecalScatter(bloodDecalAmount, 32)
        for _ = 1, decalCount do
            local bloodDir = (dir + VectorRand() * 0.75 + vector_up * math.Rand(0.05, 0.65)):GetNormalized()
            local bloodPos = pos + VectorRand() * math.Rand(0, scatter)
            local tr = util.TraceLine({
                start = bloodPos + bloodDir * math.Rand(8, 18),
                endpos = bloodPos - bloodDir * math.Rand(45, 90 + scatter),
                mask = MASK_NPCWORLDSTATIC
            })
            if tr.Hit then
                placeRandomBloodDecal(tr.HitPos, tr.HitNormal, 0.65, 1.25, tr.Entity)
            end
        end
    end

    local function placeGibBloodDecal(gib, startPos, endPos)
        local amount = getHomelanderBloodDecalAmount()
        local scatter = getHomelanderBloodDecalScatter(amount, 6)
        startPos = startPos + VectorRand() * scatter
        endPos = endPos + VectorRand() * scatter

        local trace = util.TraceLine({
            start = startPos,
            endpos = endPos,
            filter = gib,
            mask = MASK_NPCWORLDSTATIC
        })

        if not trace.Hit then
            trace = util.TraceLine({
                start = endPos + vector_up * 5,
                endpos = endPos - vector_up * 16,
                filter = gib,
                mask = MASK_NPCWORLDSTATIC
            })
        end

        if not trace.Hit then return false end

        placeRandomBloodDecal(trace.HitPos, trace.HitNormal, 0.35, 0.7, trace.Entity)
        return true
    end

    hook.Add("Think", "HomelanderSWEP_GoreGibBloodDecals", function()
        if not isHomelanderBloodEnabled() then return end
        local bloodAmount = getHomelanderBloodDecalAmount()
        if bloodAmount <= 0 then return end

        local now = CurTime()
        local placed = 0
        local maxDecals = math.max(1, math.floor(MAX_GIB_BLOOD_DECALS_PER_THINK * math.Clamp(bloodAmount, 0.25, 2)))

        for i = #activeGoreGibs, 1, -1 do
            local gib = activeGoreGibs[i]
            if not IsValid(gib) then
                table.remove(activeGoreGibs, i)
                continue
            end

            local currentPos = gib:GetPos()
            local lastPos = gib.HomelanderLastBloodDecalPos or currentPos
            gib.HomelanderLastBloodDecalPos = currentPos

            if (gib.HomelanderNextBloodDecalTime or 0) > now then continue end

            local phys = gib:GetPhysicsObject()
            local speedSqr = IsValid(phys) and phys:GetVelocity():LengthSqr() or currentPos:DistToSqr(lastPos) / math.max(FrameTime() * FrameTime(), 0.0001)
            if speedSqr < 1600 then continue end

            local decalStart = lastPos
            local decalEnd = currentPos
            if decalStart:DistToSqr(decalEnd) < 9 then
                decalStart = currentPos + vector_up * 8
                decalEnd = currentPos - vector_up * 18
            end

            if placeGibBloodDecal(gib, decalStart, decalEnd) then
                placed = placed + 1
                gib.HomelanderNextBloodDecalTime = now + (GIB_BLOOD_DECAL_INTERVAL / math.Clamp(bloodAmount, 0.5, 2)) + math.Rand(0, 0.22)
                if placed >= maxDecals then return end
            else
                gib.HomelanderNextBloodDecalTime = now + 0.08
            end
        end
    end)

    local function spawnHomelanderClientGore(kind, mode, pos, dir, velocityScale)
        dir = dir or vector_up
        if dir:LengthSqr() <= 0.001 then dir = vector_up end
        dir:Normalize()

        local legacyAmount = getClientFloat("theboysbase_cl_gore_amount", 1, 0, 2)
        local gibAmount = getClientFloat("theboysbase_cl_gore_gib_amount", legacyAmount, 0, 2)
        local bloodAmount = getHomelanderBloodDecalAmount()

        spawnClientBloodFX(pos, dir, bloodAmount)
        if not isHomelanderGoreEnabled() then return end

        local modelKind = kind == "execution_head" and "dismember" or kind
        local modelMode = kind == "execution_head" and "head" or mode
        local models = buildGoreModelsForMode(modelKind, modelMode, gibAmount)
        for _, modelData in ipairs(models) do
            spawnClientGoreGib(modelData, pos, dir, velocityScale or 1)
        end
    end

    function SWEP:DrawHUD()
        local untilTime = self:GetNW2Float("HomelanderModePopupUntil", 0)
        local remaining = untilTime - CurTime()
        if remaining <= 0 then return end

        if self.HomelanderLastModePopupSound ~= untilTime then
            self.HomelanderLastModePopupSound = untilTime
            surface.PlaySound("buttons/lightswitch2.wav")
        end

        local mode = self:GetNW2Int("HomelanderMode", HOMELANDER_MODE_NORMAL)
        local material = modeIconMaterials[mode]
        if not material or material:IsError() then return end

        local fade = math.Clamp(remaining / 0.25, 0, 1)
        local alpha = 255 * fade
        local width = math.floor(math.min(ScrW(), ScrH()) * 0.16)
        width = math.Clamp(width, 128, 213)
        local height = math.floor(width * 9 / 16)

        local x = math.floor(ScrW() * 0.5 - width * 0.5)
        local y = math.floor(ScrH() * 0.25 - height * 0.5)

        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(material)
        surface.DrawTexturedRect(x, y, width, height)
    end

    net.Receive("HomelanderDismember", function()
        local owner = net.ReadEntity()
        local mode = net.ReadString()
        local boneName = net.ReadString()
        local expire = net.ReadFloat()
        debugHomelanderDismember("net HomelanderDismember", {
            ent = owner or NULL,
            mode = mode or "",
            boneName = boneName or "",
            expire = expire or 0,
            now = CurTime()
        })
        if not IsValid(owner) then return end

        if mode == "" or expire <= CurTime() then
            laserDismemberOwners[owner] = nil
            if resetHomelanderDismemberBones and owner.HomelanderDismemberApplied then
                resetHomelanderDismemberBones(owner)
            end
            return
        end

        laserDismemberOwners[owner] = {
            mode = mode,
            boneName = boneName,
            expire = expire
        }
    end)

    net.Receive("HomelanderGoreFX", function()
        local kind = net.ReadString()
        local mode = net.ReadString()
        local pos = net.ReadVector()
        local dir = net.ReadVector()
        local velocityScale = net.ReadFloat()

        spawnHomelanderClientGore(kind, mode, pos, dir, velocityScale)
    end)

    local lastEyeFallbackOffsets = {}
    local function updateLocalEyeFallbackOffsets()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local sideCvar = GetConVar("homelander_cl_eye_fallback_side_offset")
        local forwardCvar = GetConVar("homelander_cl_eye_fallback_forward_offset")
        local heightCvar = GetConVar("homelander_cl_eye_fallback_height_offset")
        local sideOffset = sideCvar and sideCvar:GetFloat() or 1.3
        local forwardOffset = forwardCvar and forwardCvar:GetFloat() or 0.45
        local heightOffset = heightCvar and heightCvar:GetFloat() or 0

        sideOffset = math.Clamp(sideOffset, -20, 20)
        forwardOffset = math.Clamp(forwardOffset, -20, 20)
        heightOffset = math.Clamp(heightOffset, -20, 20)

        if lastEyeFallbackOffsets.side ~= sideOffset then
            lastEyeFallbackOffsets.side = sideOffset
            ply:SetNWFloat("HomelanderEyeFallbackSideOffset", sideOffset)
        end
        if lastEyeFallbackOffsets.forward ~= forwardOffset then
            lastEyeFallbackOffsets.forward = forwardOffset
            ply:SetNWFloat("HomelanderEyeFallbackForwardOffset", forwardOffset)
        end
        if lastEyeFallbackOffsets.height ~= heightOffset then
            lastEyeFallbackOffsets.height = heightOffset
            ply:SetNWFloat("HomelanderEyeFallbackHeightOffset", heightOffset)
        end
    end

    cvars.AddChangeCallback("homelander_cl_eye_fallback_side_offset", updateLocalEyeFallbackOffsets, "HomelanderSWEP_EyeFallbackOffsets")
    cvars.AddChangeCallback("homelander_cl_eye_fallback_forward_offset", updateLocalEyeFallbackOffsets, "HomelanderSWEP_EyeFallbackOffsets")
    cvars.AddChangeCallback("homelander_cl_eye_fallback_height_offset", updateLocalEyeFallbackOffsets, "HomelanderSWEP_EyeFallbackOffsets")
    hook.Add("InitPostEntity", "HomelanderSWEP_UpdateLocalEyeFallbackOffsets", function()
        timer.Simple(0, updateLocalEyeFallbackOffsets)
    end)

    local homelanderServerCVarPanels = {}
    local homelanderServerCVarLoading = false

    local function setHomelanderServerConVar(cvarName, value)
        if homelanderServerCVarLoading then return end

        net.Start("homelander_send_sv_cvar")
        net.WriteString(cvarName)
        net.WriteString(tostring(value))
        net.SendToServer()
    end

    local function requestHomelanderServerCVars()
        net.Start("homelander_request_sv_cvars")
        net.SendToServer()
    end

    local function sendHomelanderServerSliderValue(slider, cvarName)
        if homelanderServerCVarLoading or not IsValid(slider) then return end
        setHomelanderServerConVar(cvarName, slider:GetValue())
    end

    local function addHomelanderServerNumSlider(panel, label, cvarName, minValue, maxValue, decimals, defaultValue)
        local slider = vgui.Create("DNumSlider", panel)
        slider:SetText(label)
        slider:SetMinMax(minValue, maxValue)
        slider:SetDark(true)
        slider:SetDecimals(decimals or 0)
        slider:SetValue(defaultValue or minValue)

        local innerSlider = slider.Slider
        if IsValid(innerSlider) then
            local oldOnMouseReleased = innerSlider.OnMouseReleased
            innerSlider.OnMouseReleased = function(self, mouseCode)
                if oldOnMouseReleased then oldOnMouseReleased(self, mouseCode) end
                sendHomelanderServerSliderValue(slider, cvarName)
            end

            if IsValid(innerSlider.Knob) then
                local oldKnobOnMouseReleased = innerSlider.Knob.OnMouseReleased
                innerSlider.Knob.OnMouseReleased = function(self, mouseCode)
                    if oldKnobOnMouseReleased then
                        oldKnobOnMouseReleased(self, mouseCode)
                    elseif DButton and DButton.OnMouseReleased then
                        DButton.OnMouseReleased(self, mouseCode)
                    end

                    sendHomelanderServerSliderValue(slider, cvarName)
                end
            end
        end

        if IsValid(slider.TextArea) then
            slider.TextArea.OnEnter = function()
                sendHomelanderServerSliderValue(slider, cvarName)
            end
        end

        if IsValid(slider.Scratch) then
            local oldScratchOnMouseReleased = slider.Scratch.OnMouseReleased
            slider.Scratch.OnMouseReleased = function(self, mouseCode)
                if oldScratchOnMouseReleased then oldScratchOnMouseReleased(self, mouseCode) end
                sendHomelanderServerSliderValue(slider, cvarName)
            end
        end

        panel:AddItem(slider)
        homelanderServerCVarPanels[cvarName] = slider
        return slider
    end

    local function addHomelanderServerCheckBox(panel, label, cvarName, defaultValue)
        local checkbox = vgui.Create("DCheckBoxLabel", panel)
        checkbox:SetText(label)
        checkbox:SetDark(true)
        checkbox:SetValue((defaultValue or 0) >= 0.5 and 1 or 0)
        checkbox.OnChange = function(_, value)
            if homelanderServerCVarLoading then return end
            setHomelanderServerConVar(cvarName, value and 1 or 0)
        end
        panel:AddItem(checkbox)
        homelanderServerCVarPanels[cvarName] = checkbox
        return checkbox
    end

    net.Receive("homelander_send_cvars_to_client", function()
        local cvarsTable = net.ReadTable()
        homelanderServerCVarLoading = true

        for cvarName, value in pairs(cvarsTable) do
            local panel = homelanderServerCVarPanels[cvarName]
            if IsValid(panel) then
                panel:SetValue(value)
            end
        end

        homelanderServerCVarLoading = false
    end)

    hook.Add("PopulateToolMenu", "HomelanderSWEP_Options", function()
        if spawnmenu.AddToolCategory then
            spawnmenu.AddToolCategory("Options", "HomelanderSWEP", "Homelander SWEP")
        end

        spawnmenu.AddToolMenuOption("Options", "HomelanderSWEP", "HomelanderSWEP_EyeFallback", "Eye settings", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Eye settings")
            panel:ControlHelp("Fallback eye offsets are local client settings. They are used when a player model has one shared eyes attachment instead of separate left/right eye attachments.")

            panel:NumSlider("Side offset", "homelander_cl_eye_fallback_side_offset", -20, 20, 2)
            panel:NumSlider("Forward offset", "homelander_cl_eye_fallback_forward_offset", -20, 20, 2)
            panel:NumSlider("Height offset", "homelander_cl_eye_fallback_height_offset", -20, 20, 2)
            panel:CheckBox("Enable eye glow", "homelander_cl_idle_eye_glow")
        end)

        spawnmenu.AddToolMenuOption("Options", "HomelanderSWEP", "HomelanderSWEP_ServerCombat", "Server combat settings", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Server combat settings")
            panel:ControlHelp("These values are server-side. Only server admins can change them.")

            local ply = LocalPlayer()
            if not IsValid(ply) or not ply:IsAdmin() then
                panel:ControlHelp("You must be a server admin to change these settings.")
                return
            end

            panel:Help("")
            panel:Help("=== Punch damage ===")
            addHomelanderServerNumSlider(panel, "Normal punch direct damage", "homelander_sv_normal_punch_damage", 0, 50000, 0, 80)
            panel:ControlHelp("Damage dealt by the direct normal punch hit.")
            addHomelanderServerNumSlider(panel, "Strong punch direct damage", "homelander_sv_strong_punch_damage", 0, 50000, 0, 1000)
            panel:ControlHelp("Damage dealt by the direct strong punch hit.")
            addHomelanderServerNumSlider(panel, "Strong punch shockwave damage", "homelander_sv_strong_punch_shockwave_damage", 0, 50000, 0, 250)
            panel:ControlHelp("Damage dealt to entities inside the strong punch area.")
            addHomelanderServerNumSlider(panel, "Strong punch damage radius", "homelander_sv_strong_punch_shockwave_radius", 0, 3000, 0, 50)
            panel:ControlHelp("Area radius for strong punch damage and push.")
            addHomelanderServerNumSlider(panel, "Strong punch shockwave force", "homelander_sv_strong_punch_shockwave_force", 0, 250000, 0, 32000)
            panel:ControlHelp("Physics force applied by the strong punch area.")
            addHomelanderServerNumSlider(panel, "Strong punch prop destroy radius", "homelander_sv_strong_punch_prop_destroy_radius", 0, 1500, 0, 200)
            panel:ControlHelp("Props inside this radius are directly damaged/destroyed.")
            addHomelanderServerNumSlider(panel, "Strong punch prop scatter radius", "homelander_sv_strong_punch_prop_scatter_radius", 0, 2500, 0, 400)
            panel:ControlHelp("Props inside this radius are unfrozen and pushed.")
            addHomelanderServerNumSlider(panel, "Strong punch prop scatter force", "homelander_sv_strong_punch_prop_scatter_force", 0, 250000, 0, 27200)
            panel:ControlHelp("Force used when scattering props from strong punch impact.")
            addHomelanderServerNumSlider(panel, "Strong punch prop damage", "homelander_sv_strong_punch_prop_damage", 0, 50000, 0, 2500)
            panel:ControlHelp("Damage applied to breakable props near strong punch impact.")

            panel:Help("")
            panel:Help("=== Laser ===")
            addHomelanderServerNumSlider(panel, "Laser damage", "homelander_sv_laser_damage", 1, 100000, 0, 100)
            panel:ControlHelp("Base damage dealt by heat vision laser hits.")
            addHomelanderServerCheckBox(panel, "Enable laser burn-through", "homelander_sv_laser_penetration_enabled", 1)
            panel:ControlHelp("Allow heat vision to burn through entities and thin world surfaces.")
            addHomelanderServerNumSlider(panel, "Laser entity penetrations", "homelander_sv_laser_entity_penetrations", 0, 32, 0, 24)
            panel:ControlHelp("How many entities heat vision can burn through before stopping.")
            addHomelanderServerNumSlider(panel, "Laser world burn-through thickness", "homelander_sv_laser_world_thickness", 0, 256, 0, 32)
            panel:ControlHelp("Maximum world surface thickness heat vision can burn through, in source units.")

            panel:Help("")
            panel:Help("")
            panel:Help("=== Flight impact ===")
            addHomelanderServerNumSlider(panel, "Flight collision damage", "homelander_sv_flight_damage", 0, 100000, 0, 1000)
            panel:ControlHelp("Damage dealt by flight collisions and super flight impacts.")
            addHomelanderServerNumSlider(panel, "Flight impact damage radius", "homelander_sv_flight_impact_radius", 0, 5000, 0, 200)
            panel:ControlHelp("Area radius for damage after hitting a surface during super flight.")
            addHomelanderServerNumSlider(panel, "Flight impact prop destroy radius", "homelander_sv_flight_impact_prop_destroy_radius", 0, 2500, 0, 300)
            panel:ControlHelp("Props inside this radius are directly damaged/destroyed by super flight impact.")
            addHomelanderServerNumSlider(panel, "Flight impact prop scatter radius", "homelander_sv_flight_impact_prop_scatter_radius", 0, 3500, 0, 400)
            panel:ControlHelp("Props inside this radius are unfrozen and pushed by super flight impact.")
            addHomelanderServerNumSlider(panel, "Flight impact prop scatter force", "homelander_sv_flight_impact_prop_scatter_force", 0, 300000, 0, 90000)
            panel:ControlHelp("Force used when scattering props from super flight impact.")
            addHomelanderServerNumSlider(panel, "Flight impact prop damage", "homelander_sv_flight_impact_prop_damage", 0, 100000, 0, 5000)
            panel:ControlHelp("Damage applied to breakable props near super flight impact.")

            panel:Help("")
            local resetButton = panel:Button("Reset combat settings to defaults")
            resetButton.DoClick = function()
                setHomelanderServerConVar("homelander_sv_normal_punch_damage", 80)
                setHomelanderServerConVar("homelander_sv_strong_punch_damage", 1000)
                setHomelanderServerConVar("homelander_sv_strong_punch_shockwave_damage", 250)
                setHomelanderServerConVar("homelander_sv_strong_punch_shockwave_radius", 50)
                setHomelanderServerConVar("homelander_sv_strong_punch_shockwave_force", 32000)
                setHomelanderServerConVar("homelander_sv_strong_punch_prop_destroy_radius", 200)
                setHomelanderServerConVar("homelander_sv_strong_punch_prop_scatter_radius", 400)
                setHomelanderServerConVar("homelander_sv_strong_punch_prop_scatter_force", 27200)
                setHomelanderServerConVar("homelander_sv_strong_punch_prop_damage", 2500)
                setHomelanderServerConVar("homelander_sv_laser_damage", 100)
                setHomelanderServerConVar("homelander_sv_laser_penetration_enabled", 1)
                setHomelanderServerConVar("homelander_sv_laser_entity_penetrations", 24)
                setHomelanderServerConVar("homelander_sv_laser_world_thickness", 32)
                setHomelanderServerConVar("homelander_sv_flight_damage", 1000)
                setHomelanderServerConVar("homelander_sv_flight_impact_radius", 200)
                setHomelanderServerConVar("homelander_sv_flight_impact_prop_destroy_radius", 300)
                setHomelanderServerConVar("homelander_sv_flight_impact_prop_scatter_radius", 400)
                setHomelanderServerConVar("homelander_sv_flight_impact_prop_scatter_force", 90000)
                setHomelanderServerConVar("homelander_sv_flight_impact_prop_damage", 5000)
                timer.Simple(0.1, requestHomelanderServerCVars)
            end

            requestHomelanderServerCVars()
        end)

        spawnmenu.AddToolMenuOption("Options", "HomelanderSWEP", "HomelanderSWEP_ServerUtility", "Server utility settings", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Server utility settings")
            panel:ControlHelp("Other server-side settings useful for admins. Only server admins can change them.")

            local ply = LocalPlayer()
            if not IsValid(ply) or not ply:IsAdmin() then
                panel:ControlHelp("You must be a server admin to change these settings.")
                return
            end

            addHomelanderServerCheckBox(panel, "SWEP owner god mode", "homelander_sv_owner_godmode", 0)
            panel:ControlHelp("When enabled, the Homelander SWEP owner becomes fully invulnerable while holding the SWEP.")
            addHomelanderServerNumSlider(panel, "SWEP owner health", "homelander_sv_owner_health", 1000, 100000, 0, 30000)
            panel:ControlHelp("Health and max health given to the Homelander SWEP owner when god mode is disabled.")

            requestHomelanderServerCVars()
        end)
    end)
    local function homelanderOutfitterEnabled()
        local enabled = GetConVar("outfitter_enabled")
        return enabled and enabled:GetBool()
    end

    local function isSafeHomelanderOutfitterRagdollModel(modelPath)
        if not isstring(modelPath) or modelPath == "" then return false end

        local lowerPath = string.lower(modelPath)
        if not string.StartWith(lowerPath, "models/") or lowerPath:sub(-4) ~= ".mdl" then return false end
        if string.find(modelPath, "..", 1, true) or string.find(modelPath, "\n", 1, true) or string.find(modelPath, "\t", 1, true) then return false end

        local physPath = string.gsub(modelPath, "%.mdl$", ".phy")
        local physSize = file.Size(physPath, "GAME")
        return not physSize or physSize <= 100 * 1000
    end

    local function applyHomelanderOutfitterSkinAndBodygroups(ent, skin, bodygroups)
        if not IsValid(ent) then return end

        if skin and skin >= 0 then
            ent:SetSkin(skin)
        end

        if istable(bodygroups) then
            for group, value in pairs(bodygroups) do
                local id = tonumber(group)
                if not id and isstring(group) then
                    id = ent:FindBodygroupByName(group)
                end

                value = tonumber(value)
                if id and id >= 0 and value then
                    ent:SetBodygroup(id, value)
                end
            end
        end
    end

    local applyHomelanderDismember

    local function applyHomelanderHeadHide(ent, hide)
        if not IsValid(ent) then return end

        if hide then
            if applyHomelanderDismember then
                applyHomelanderDismember(ent, "head")
            end
            return
        end
    end

    local function getHomelanderClientDismemberOptions(boneName)
        return {
            dismemberBones = THEBOYS_DISMEMBER_BONES,
            boneName = boneName,
            appliedField = "HomelanderDismemberApplied",
            rootsField = "HomelanderDismemberBoneRoots",
            callbackField = "HomelanderDismemberBuildBoneCallback",
            inBuildField = "HomelanderDismemberInBuildBones",
            checkedOwnerField = "HomelanderDismemberCheckedOwner",
            moveHiddenBonesToOrigin = true,
            debugLog = debugHomelanderDismember
        }
    end

    applyHomelanderDismember = function(ent, mode, boneName)
        if not IsValid(ent) or not mode or mode == "" then
            debugHomelanderDismember("client apply skipped invalid", {
                ent = ent or NULL,
                mode = mode or "",
                boneName = boneName or ""
            })
            return false
        end
        if not isHomelanderDismemberEnabled() then
            if ent.HomelanderDismemberApplied then
                resetHomelanderDismemberBones(ent)
            end
            debugHomelanderDismember("client apply skipped dismember disabled", {
                ent = ent,
                mode = mode,
                boneName = boneName or ""
            })
            return false
        end
        local appliedKey = mode .. ":" .. tostring(boneName or "")
        if ent.HomelanderDismemberApplied == appliedKey then return true end

        local applied = TBOYS.ApplyClientBoneDismember(ent, mode, getHomelanderClientDismemberOptions(boneName))
        if applied then invalidateHomelanderBoneCache(ent) end
        debugHomelanderDismember("client apply result", {
            ent = ent,
            mode = mode,
            boneName = boneName or "",
            applied = applied,
            appliedKey = ent.HomelanderDismemberApplied or ""
        })
        return applied
    end

    resetHomelanderDismemberBones = function(ent)
        if not IsValid(ent) then return end

        TBOYS.ResetClientBoneDismember(ent, getHomelanderClientDismemberOptions())
        invalidateHomelanderBoneCache(ent)
    end

    local function clearHomelanderDismemberState()
        for owner in pairs(laserDismemberOwners) do
            laserDismemberOwners[owner] = nil
        end

        for _, ent in ipairs(ents.GetAll()) do
            if ent.HomelanderDismemberApplied then
                resetHomelanderDismemberBones(ent)
            end
        end
    end

    cvars.AddChangeCallback("theboysbase_cl_gore_enabled", function(_, _, newValue)
        if tonumber(newValue) and tonumber(newValue) >= 0.5 then return end

        for i = #activeGoreGibs, 1, -1 do
            local gib = activeGoreGibs[i]
            if IsValid(gib) then gib:Remove() end
            activeGoreGibs[i] = nil
        end

    end, "HomelanderSWEP_GoreEnabled")

    local lastDismemberEnabled = isHomelanderDismemberEnabled()
    hook.Add("Think", "HomelanderSWEP_DismemberEnabled", function()
        local enabled = isHomelanderDismemberEnabled()
        if lastDismemberEnabled == enabled then return end
        lastDismemberEnabled = enabled

        if not enabled then
            clearHomelanderDismemberState()
        end
    end)

    local function applyHomelanderDismemberFromOwner(ragdoll)
        if not IsValid(ragdoll) or ragdoll.HomelanderDismemberCheckedOwner then return end
        if ragdoll:IsPlayer() then return end

        local directMode = ragdoll:GetNW2String("HomelanderDismemberMode", "")
        local directExpire = ragdoll:GetNW2Float("HomelanderDismemberExpire", 0)
        if directMode ~= "" and directExpire >= CurTime() then
            debugHomelanderDismember("client from ragdoll NW2", {
                ragdoll = ragdoll,
                mode = directMode,
                boneName = ragdoll:GetNW2String("HomelanderDismemberBone", ""),
                expire = directExpire
            })
            ragdoll.HomelanderDismemberApplied = nil
            if applyHomelanderDismember(ragdoll, directMode, ragdoll:GetNW2String("HomelanderDismemberBone", "")) then
                ragdoll.HomelanderDismemberCheckedOwner = true
            end
            return
        end

        local owner = ragdoll.GetRagdollOwner and ragdoll:GetRagdollOwner() or nil
        if not isHomelanderCharacter(owner) then return end

        local expire = owner:GetNW2Float("HomelanderDismemberExpire", 0)
        local mode = owner:GetNW2String("HomelanderDismemberMode", "")
        local boneName = owner:GetNW2String("HomelanderDismemberBone", "")
        local localInfo = laserDismemberOwners[owner]
        if (mode == "" or expire < CurTime()) and localInfo then
            mode = localInfo.mode or ""
            boneName = localInfo.boneName or ""
            expire = localInfo.expire or 0
        end

        if mode == "" or expire < CurTime() then
            debugHomelanderDismember("client from owner no valid info", {
                ragdoll = ragdoll,
                owner = owner or NULL,
                mode = mode or "",
                boneName = boneName or "",
                expire = expire or 0,
                now = CurTime()
            })
            return
        end

        ragdoll.HomelanderDismemberApplied = nil
        debugHomelanderDismember("client from owner applying", {
            ragdoll = ragdoll,
            owner = owner,
            mode = mode,
            boneName = boneName or "",
            expire = expire
        })
        if applyHomelanderDismember(ragdoll, mode, boneName) then
            ragdoll.HomelanderDismemberCheckedOwner = true
        end
    end

    local function applyHomelanderDismemberFromSource(source, ragdoll)
        if not IsValid(ragdoll) or ragdoll.HomelanderDismemberCheckedOwner then return end

        local info = laserDismemberOwners[source]
        local mode = info and info.mode or ""
        local boneName = info and info.boneName or ""
        local expire = info and info.expire or 0

        if mode == "" and IsValid(source) then
            mode = source:GetNW2String("HomelanderDismemberMode", "")
            boneName = source:GetNW2String("HomelanderDismemberBone", "")
            expire = source:GetNW2Float("HomelanderDismemberExpire", 0)
        end

        if mode == "" or expire < CurTime() then return end

        ragdoll.HomelanderDismemberApplied = nil
        if applyHomelanderDismember(ragdoll, mode, boneName) then
            ragdoll.HomelanderDismemberCheckedOwner = true
        end
    end

    hook.Add("NetworkEntityCreated", "HomelanderSWEP_LaserDismemberRagdoll", function(ent)
        if not IsValid(ent) then return end

        timer.Simple(0, function()
            if not IsValid(ent) then return end
            applyHomelanderDismemberFromOwner(ent)
        end)
    end)

    hook.Add("CreateClientsideRagdoll", "HomelanderSWEP_LaserDismemberClientsideRagdoll", function(source, ragdoll)
        if not IsValid(source) or not IsValid(ragdoll) then return end

        applyHomelanderDismemberFromSource(source, ragdoll)
        timer.Simple(0, function()
            if IsValid(ragdoll) then
                applyHomelanderDismemberFromSource(source, ragdoll)
            end
        end)
        timer.Simple(0.05, function()
            if IsValid(ragdoll) then
                applyHomelanderDismemberFromSource(source, ragdoll)
            end
        end)
    end)

    hook.Add("PlayerSpawn", "HomelanderSWEP_ResetDismemberBones", function(ply)
        timer.Simple(0, function()
            if IsValid(ply) then
                resetHomelanderDismemberBones(ply)
                laserDismemberOwners[ply] = nil
                if ply.RemoveAllDecals then
                    ply:RemoveAllDecals()
                end
            end
        end)
    end)

    local function removeHomelanderOutfitterVisualRagdoll(ragdoll)
        local data = outfitterVisualRagdolls[ragdoll]
        if not data then return end

        if IsValid(data.ent) then
            data.ent:Remove()
        end

        outfitterVisualRagdolls[ragdoll] = nil
    end

    local function getHomelanderOutfitterVisualRagdoll(ragdoll)
        local modelPath = ragdoll.HomelanderOutfitterRenderModel
        if not modelPath or modelPath == "" then return nil end

        local data = outfitterVisualRagdolls[ragdoll]
        if data and data.modelPath == modelPath and IsValid(data.ent) then
            return data.ent
        end

        removeHomelanderOutfitterVisualRagdoll(ragdoll)

        local ok, visual = pcall(ClientsideRagdoll, modelPath, RENDERGROUP_OPAQUE)
        if not ok or not IsValid(visual) then return nil end

        visual:SetNoDraw(true)
        visual:SetPos(ragdoll:GetPos())
        visual:SetAngles(ragdoll:GetAngles())
        visual:SetColor(ragdoll:GetColor())
        visual:SetRenderMode(ragdoll:GetRenderMode())
        visual:SetMaterial(ragdoll:GetMaterial() or "")
        visual:DrawShadow(true)

        for i = 0, visual:GetPhysicsObjectCount() - 1 do
            local phys = visual:GetPhysicsObjectNum(i)
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:SetVelocity(vector_origin)
                phys:SetAngleVelocity(vector_origin)
            end
        end

        data = {
            ent = visual,
            modelPath = modelPath
        }
        outfitterVisualRagdolls[ragdoll] = data

        return visual
    end

    local function syncHomelanderOutfitterVisualRagdoll(ragdoll, visual)
        if not IsValid(ragdoll) or not IsValid(visual) then return end

        visual:SetPos(ragdoll:GetPos())
        visual:SetAngles(ragdoll:GetAngles())
        visual:SetColor(ragdoll:GetColor())
        visual:SetRenderMode(ragdoll:GetRenderMode())
        visual:SetMaterial(ragdoll:GetMaterial() or "")

        for i = 0, visual:GetPhysicsObjectCount() - 1 do
            local visualPhys = visual:GetPhysicsObjectNum(i)
            if not IsValid(visualPhys) then continue end

            local visualBone = visual:TranslatePhysBoneToBone(i)
            local boneName = visualBone and visual:GetBoneName(visualBone)
            local sourceBone = boneName and ragdoll:LookupBone(boneName)

            if sourceBone then
                local sourcePhysBone = ragdoll:TranslateBoneToPhysBone(sourceBone)
                local sourcePhys = sourcePhysBone and sourcePhysBone >= 0 and ragdoll:GetPhysicsObjectNum(sourcePhysBone) or nil

                if IsValid(sourcePhys) then
                    visualPhys:SetPos(sourcePhys:GetPos())
                    visualPhys:SetAngles(sourcePhys:GetAngles())
                else
                    local pos, ang = ragdoll:GetBonePosition(sourceBone)
                    if pos and ang then
                        visualPhys:SetPos(pos)
                        visualPhys:SetAngles(ang)
                    end
                end
            end

            visualPhys:SetVelocity(vector_origin)
            visualPhys:SetAngleVelocity(vector_origin)
            visualPhys:Sleep()
        end

        invalidateHomelanderBoneCache(visual)
    end

    local function shouldHideGrabRagdollFromLocalPlayer(ragdoll)
        if not IsValid(ragdoll) then return false end

        local localPly = LocalPlayer()
        if not IsValid(localPly) then return false end
        return ragdoll:GetNW2Entity("HomelanderGrabVictim") == localPly
    end

    local function updateGrabVictimRagdollVisibility(ragdoll)
        if not IsValid(ragdoll) then return end

        local shouldHide = shouldHideGrabRagdollFromLocalPlayer(ragdoll)
        if ragdoll.HomelanderHiddenFromGrabVictim == shouldHide then return end

        ragdoll.HomelanderHiddenFromGrabVictim = shouldHide
        ragdoll:SetNoDraw(shouldHide)
    end

    local function drawHomelanderOutfitterRagdoll(ragdoll)
        if shouldHideGrabRagdollFromLocalPlayer(ragdoll) then return end

        local visual = getHomelanderOutfitterVisualRagdoll(ragdoll)
        if IsValid(visual) then
            syncHomelanderOutfitterVisualRagdoll(ragdoll, visual)
            applyHomelanderOutfitterSkinAndBodygroups(visual, ragdoll.HomelanderOutfitterRenderSkin, ragdoll.HomelanderOutfitterRenderBodygroups)
            applyHomelanderDismember(visual, ragdoll:GetNW2String("HomelanderDismemberMode", ""), ragdoll:GetNW2String("HomelanderDismemberBone", ""))
            applyHomelanderHeadHide(visual, ragdoll:GetNW2Bool("HomelanderHideHead", false))
            visual:DrawModel()
            return
        end

        applyHomelanderDismember(ragdoll, ragdoll:GetNW2String("HomelanderDismemberMode", ""), ragdoll:GetNW2String("HomelanderDismemberBone", ""))
        applyHomelanderHeadHide(ragdoll, ragdoll:GetNW2Bool("HomelanderHideHead", false))
        ragdoll:DrawModel()
    end

    local function clearHomelanderOutfitterRagdoll(ragdoll)
        if not IsValid(ragdoll) or not ragdoll.HomelanderOutfitterApplied then return end

        removeHomelanderOutfitterVisualRagdoll(ragdoll)

        ragdoll.RenderOverride = nil
        ragdoll.HomelanderOutfitterApplied = nil
        ragdoll.HomelanderOutfitterRenderModel = nil
        ragdoll.HomelanderOutfitterRenderSkin = nil
        ragdoll.HomelanderOutfitterRenderBodygroups = nil
    end

    local function getHomelanderOutfitterRagdollInfo(ragdoll)
        local modelPath = ragdoll:GetNW2String("HomelanderOutfitterModel", "")
        local skin = ragdoll:GetNW2Int("HomelanderOutfitterSkin", -1)
        local bodygroups

        if modelPath ~= "" then
            return modelPath, skin, bodygroups
        end

        local target = ragdoll:GetNW2Entity("HomelanderOutfitterTarget")
        if not IsValid(target) then return "", -1, nil end

        if target.OutfitInfo then
            local outfitModel, _, outfitSkin, outfitBodygroups = target:OutfitInfo()
            modelPath = outfitModel or ""
            skin = tonumber(outfitSkin) or -1
            bodygroups = outfitBodygroups
        else
            modelPath = target.outfitter_mdl or ""
            skin = tonumber(target.outfitter_skin) or -1
            bodygroups = target.outfitter_bodygroups
        end

        if modelPath == "" and target.GetNetData and outfitter and outfitter.DecodeOutfitterPayload then
            local encoded = target:GetNetData("OF")
            if isstring(encoded) and encoded ~= "" then
                local decodedModel = outfitter.DecodeOutfitterPayload(encoded)
                modelPath = decodedModel or ""
            end
        end

        return modelPath, skin, bodygroups
    end

    local function updateHomelanderOutfitterRagdoll(ragdoll)
        if not IsValid(ragdoll) or ragdoll:GetClass() ~= "prop_ragdoll" then return end

        local modelPath, skin, bodygroups = getHomelanderOutfitterRagdollInfo(ragdoll)
        if modelPath == "" or not homelanderOutfitterEnabled() or not isSafeHomelanderOutfitterRagdollModel(modelPath) then
            clearHomelanderOutfitterRagdoll(ragdoll)
            return
        end

        ragdoll.HomelanderOutfitterApplied = true
        ragdoll.HomelanderOutfitterRenderModel = modelPath
        ragdoll.HomelanderOutfitterRenderSkin = skin
        ragdoll.HomelanderOutfitterRenderBodygroups = bodygroups
        ragdoll.RenderOverride = drawHomelanderOutfitterRagdoll
    end

    local nextGrabVictimRagdollVisibilityCheck = 0
    hook.Add("Think", "HomelanderSWEP_GrabVictimRagdollVisibility", function()
        if nextGrabVictimRagdollVisibilityCheck > CurTime() then return end
        nextGrabVictimRagdollVisibilityCheck = CurTime() + 0.05

        for _, ragdoll in ipairs(ents.FindByClass("prop_ragdoll")) do
            if IsValid(ragdoll:GetNW2Entity("HomelanderGrabVictim")) or ragdoll.HomelanderHiddenFromGrabVictim ~= nil then
                updateGrabVictimRagdollVisibility(ragdoll)
            end
        end
    end)

    local function drawEyeGlow(pos, firing, charge)
        local perctg = math.Clamp(charge, 0.05, 1)
        local minJitter = firing and -255 or -50
        local oneHeight = firing and 99.46 or 33.29
        local twoHeight = firing and 2.19 or 1.45
        local threeHeight = firing and 0.78 or 0.28
        local oneWidth = firing and 13.32 or 4.14
        local twoWidth = firing and 3.81 or 2.67
        local threeWidth = firing and 5.38 or 2.76

        for _ = 0, 5 do
            render.SetMaterial(matEyeWide)
            render.DrawSprite(pos, oneWidth, oneHeight, Color(255, 0, 0, 255 * perctg + math.random(minJitter, 50)))

            render.SetMaterial(matEyeThin)
            render.DrawSprite(pos, twoWidth, twoHeight, Color(255, 155, 155, 255 * perctg + math.random(minJitter, 50)))
            render.DrawSprite(pos, threeWidth, threeHeight, Color(255, 255, 255, 255 * perctg + math.random(minJitter, 50)))
        end
    end

    local function drawHitGlow(pos, viewPos, charge, pulse)
        local distance = viewPos:Distance(pos)
        local size = math.Clamp(distance * 0.14, 45, 900) * charge

        render.SetMaterial(matHitFlare)
        render.DrawSprite(pos, size, size, Color(255, 0, 0, 190 + pulse * 45))

        render.SetMaterial(matHitCenter)
        render.DrawSprite(pos, size * 0.42, size * 0.42, Color(255, 150, 150, 230 + pulse * 25))

        render.SetMaterial(matHitFlare)
        render.DrawSprite(pos, size * 0.16, size * 0.16, whiteCore)
    end

    local function makeLight(index, pos, size, brightness, decay)
        local light = DynamicLight(index)
        if not light then return end

        light.pos = pos
        light.r = 255
        light.g = 20
        light.b = 10
        light.brightness = brightness
        light.Decay = decay
        light.Size = size
        light.DieTime = CurTime() + 0.08
    end

    local function getHomelanderWeapon(ply)
        if not isHomelanderActive(ply) then return nil end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= WEAPON_CLASS then return nil end

        return weapon
    end

    local function traceLocalLaserRenderHit(ply, weapon)
        local startPos = ply:EyePos()
        local aimDir = ply:EyeAngles():Forward()
        if aimDir:LengthSqr() <= 0.001 then aimDir = vector_up end
        aimDir:Normalize()

        local range = weapon.Secondary.Range
        local penetrationEnabled = weapon:GetNW2Bool("HomelanderLaserPenetrationEnabled", true)
        local entityPenetrations = math.Clamp(math.floor(weapon:GetNW2Float("HomelanderLaserEntityPenetrations", 24)), 0, 32)
        local worldThickness = math.Clamp(math.floor(weapon:GetNW2Float("HomelanderLaserWorldThickness", 32)), 0, 256)
        local maxWorldPenetrations = 8
        local maxPasses = penetrationEnabled and math.min(entityPenetrations + maxWorldPenetrations + 1, 40) or 1
        local filter = { ply }
        local traceStart = startPos
        local remainingRange = range
        local usedEntityPenetrations = 0
        local usedWorldPenetrations = 0
        local lastTrace

        local function addFilter(ent)
            if not IsValid(ent) then return end
            for _, existing in ipairs(filter) do
                if existing == ent then return end
            end
            filter[#filter + 1] = ent
        end

        local function findWorldExit(trace)
            if worldThickness <= 0 then return nil end

            local step = math.max(6, worldThickness / 8)
            for depth = step, worldThickness, step do
                local probeStart = trace.HitPos + aimDir * depth
                local probe = util.TraceLine({
                    start = probeStart,
                    endpos = trace.HitPos + aimDir,
                    filter = filter,
                    mask = MASK_SHOT
                })

                if not probe.StartSolid and not probe.AllSolid then
                    if not probe.Hit then
                        return probeStart, depth
                    end

                    if probe.HitWorld or (IsValid(probe.Entity) and probe.Entity:IsWorld()) then
                        return probe.HitPos, depth
                    end
                end
            end
        end

        for _ = 1, maxPasses do
            local trace = util.TraceLine({
                start = traceStart,
                endpos = traceStart + aimDir * remainingRange,
                filter = filter,
                mask = MASK_SHOT
            })

            lastTrace = trace
            if not penetrationEnabled or not trace.Hit or trace.HitSky then break end
            if IsValid(trace.Entity) and isHomelanderCharacter(trace.Entity) then break end

            local traveled = traceStart:Distance(trace.HitPos)
            remainingRange = remainingRange - traveled
            if remainingRange <= 1 then break end

            if IsValid(trace.Entity) and not trace.Entity:IsWorld() then
                if usedEntityPenetrations >= entityPenetrations then break end

                usedEntityPenetrations = usedEntityPenetrations + 1
                addFilter(trace.Entity)
                traceStart = trace.HitPos + aimDir * 3
                remainingRange = remainingRange - 3
            elseif trace.HitWorld or (IsValid(trace.Entity) and trace.Entity:IsWorld()) then
                if usedWorldPenetrations >= maxWorldPenetrations then break end

                local exitPos, depth = findWorldExit(trace)
                if not exitPos then break end

                usedWorldPenetrations = usedWorldPenetrations + 1
                traceStart = exitPos + aimDir * 3
                remainingRange = remainingRange - (depth or 0) - 3
            else
                break
            end

            if remainingRange <= 1 then break end
        end

        if lastTrace then
            return lastTrace.HitPos, lastTrace.HitNormal
        end

        return startPos + aimDir * range, vector_origin
    end

    local function getRenderHitPos(ply, weapon)
        if weapon:GetNW2Float("HomelanderExecuteLaserUntil", 0) > CurTime() then
            return weapon:GetNW2Vector("HomelanderHitPos", ply:EyePos() + ply:EyeAngles():Forward() * 128),
                weapon:GetNW2Vector("HomelanderHitNormal", vector_origin)
        end

        if ply == LocalPlayer() then
            return traceLocalLaserRenderHit(ply, weapon)
        end

        return weapon:GetNW2Vector("HomelanderHitPos", ply:EyePos() + ply:EyeAngles():Forward() * 2048),
            weapon:GetNW2Vector("HomelanderHitNormal", vector_origin)
    end

    local function drawEyeBeam(startPos, hitPos, charge, pulse, sideOffset)
        local flow = CurTime() * -5 + sideOffset
        local glowWidth = (4.2 + pulse * 1.6) * charge
        local coreWidth = (2.2 + pulse * 1.1) * charge

        render.SetMaterial(matLaserGlow)
        render.DrawBeam(startPos, hitPos, glowWidth, flow, flow + 12.5, beamGlow)

        render.SetMaterial(matLaserCore)
        render.DrawBeam(startPos, hitPos, coreWidth, flow, flow + 12.5, beamCore)
        render.DrawBeam(startPos, hitPos, math.max(1.1, coreWidth * 0.45), flow + 0.6, flow + 13.1, whiteCore)
    end

    local function drawSonicBoomCone(ply, weapon)
        if not weapon:GetNW2Bool("HomelanderSuperFlying", false) then return end

        local dir = ply:EyeAngles():Forward()
        if dir:LengthSqr() <= 0.001 then return end
        dir:Normalize()

        local center
        local pelvis = ply:LookupBone("ValveBiped.Bip01_Pelvis")
        if pelvis then
            local pelvisPos = ply:GetBonePosition(pelvis)
            if pelvisPos then
                center = pelvisPos
            end
        end
        center = center or (ply:GetPos() + vector_up * (ply:OBBMaxs().z * 0.42))
        center = center + dir

        local time = CurTime() * 3.2 + ply:EntIndex() * 0.17

        render.SetMaterial(matSonicBoomCone)

        for i = 0, 5 do
            local phase = (i / 6 + time) % 1
            local distance = 8 + phase * 185
            local size = 52 + phase * 185
            local alpha = (1 - phase) * 105
            local pos = center - dir * distance
            local twist = time * 80 + i * 24

            render.DrawQuadEasy(pos, dir, size, size, Color(245, 250, 255, alpha), twist)
        end

        for i = 0, 3 do
            local phase = i / 3
            local distance = 20 + phase * 135
            local size = 85 + phase * 155
            local alpha = 34 * (1 - phase)
            local pos = center - dir * distance

            render.DrawQuadEasy(pos, dir, size, size, Color(180, 225, 255, alpha), -time * 55 + i * 32)
        end
    end

    local function addAnimatedDebris(model, pos, ang, targetScale, velocity, angularVelocity, lifetime)
        while #activeDebris >= MAX_ACTIVE_PUNCH_DEBRIS do
            local old = table.remove(activeDebris, 1)
            if old and IsValid(old.ent) then
                old.ent:Remove()
            end
        end

        local debris = ClientsideModel(model)
        if not IsValid(debris) then return end

        debris:SetNoDraw(false)
        debris:SetPos(pos)
        debris:SetAngles(ang)
        debris:SetModelScale(0.04, 0)

        activeDebris[#activeDebris + 1] = {
            ent = debris,
            pos = pos,
            ang = ang,
            scale = targetScale,
            velocity = velocity,
            angularVelocity = angularVelocity,
            startTime = CurTime(),
            growTime = math.Rand(0.16, 0.26),
            shrinkTime = 0.35,
            lifetime = lifetime
        }
    end

    local function spawnImpactDebris(center, normal, radiusScale, debrisScale, amountScale)
        radiusScale = radiusScale or 1
        debrisScale = debrisScale or 1
        amountScale = math.Clamp(amountScale or getClientFloat("theboysbase_cl_destruction_debris_amount", 1, 0, 2), 0, 2)
        if amountScale <= 0 then return end

        normal = normal:GetNormalized()
        if normal:LengthSqr() <= 0.001 then
            normal = vector_up
        end

        local normalAng = normal:Angle()
        local tangent1 = normalAng:Right()
        local tangent2 = normalAng:Up()
        local tangent3 = normalAng:Forward()
        local lifetime = 4.5 * math.Clamp(debrisScale, 1, 1.5)
        local debrisModel = "models/props_debris/concrete_chunk03a.mdl"

        local emitter = ParticleEmitter(center, false)
        if emitter then
            local smokeCount = math.floor(18 * radiusScale * amountScale + 0.5)
            for _ = 1, smokeCount do
                local spread = tangent1 * math.Rand(-92, 92) * radiusScale + tangent2 * math.Rand(-92, 92) * radiusScale
                local particle = emitter:Add(matImpactSmoke, center + spread * math.Rand(0.15, 0.55) + normal * math.Rand(4, 24))
                if particle then
                    local size = math.Rand(42, 92) * radiusScale * debrisScale
                    local dir = spread:GetNormalized()
                    if dir:LengthSqr() <= 0.001 then dir = VectorRand():GetNormalized() end

                    particle:SetVelocity(dir * math.Rand(24, 95) + normal * math.Rand(35, 115) + VectorRand() * 18)
                    particle:SetDieTime(math.Rand(0.75, 1.45) * math.Clamp(radiusScale, 0.75, 1.6))
                    particle:SetStartAlpha(math.Rand(85, 145))
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(size * 0.25)
                    particle:SetEndSize(size)
                    particle:SetRoll(math.Rand(0, 360))
                    particle:SetRollDelta(math.Rand(-0.55, 0.55))
                    particle:SetAirResistance(80)
                    particle:SetGravity(normal * math.Rand(8, 28) + vector_up * math.Rand(8, 32))

                    local shade = math.random(70, 105)
                    particle:SetColor(shade, shade, shade)
                end
            end
            emitter:Finish()
        end

        local function createDebris(angleDeg, radius, minScale, maxScale, delay)
            if amountScale < 1 and math.Rand(0, 1) > amountScale then return end
            local duplicateCount = amountScale > 1 and (math.Rand(0, 1) < (amountScale - 1) and 2 or 1) or 1

            timer.Simple(delay or 0, function()
                for _ = 1, duplicateCount do
                    local radians = math.rad(angleDeg + math.Rand(-5, 5))
                    local offset = math.cos(radians) * tangent1 + math.sin(radians) * tangent2
                    local pos = center + offset * radius + normal * 2
                    local trace = util.TraceLine({
                        start = pos,
                        endpos = pos + tangent3 * -radius / 5,
                        mask = MASK_NPCWORLDSTATIC
                    })

                    local targetScale = math.Rand(minScale, maxScale)
                    local spawnPos = (trace.Hit and trace.HitPos or pos) + normal * -4
                    local velocity = offset * math.Rand(80, 190) + normal * math.Rand(70, 180)
                    local angularVelocity = Angle(math.Rand(-220, 220), math.Rand(-220, 220), math.Rand(-220, 220))

                    addAnimatedDebris(
                        debrisModel,
                        spawnPos,
                        normal:Angle() + AngleRand(),
                        targetScale,
                        velocity,
                        angularVelocity,
                        lifetime + math.Rand(-0.2, 0.6)
                    )
                end
            end)
        end

        for i = 0, 360, 40 do
            createDebris(i, 86 * radiusScale * math.Rand(1.1, 1.65), 1.05 * debrisScale, 3.4 * debrisScale, math.Rand(0, 0.04))
        end

        for i = 0, 360, 14 do
            createDebris(i, 155 * radiusScale * math.Rand(1.1, 1.65), 1.7 * debrisScale, 5.9 * debrisScale, 0.035 + math.Rand(0, 0.1))
        end
    end

    hook.Add("Think", "HomelanderSWEP_AnimatedDebris", function()
        local now = CurTime()

        for i = #activeDebris, 1, -1 do
            local data = activeDebris[i]
            local debris = data.ent

            if not IsValid(debris) then
                table.remove(activeDebris, i)
                continue
            end

            local age = now - data.startTime
            if age >= data.lifetime then
                debris:Remove()
                table.remove(activeDebris, i)
                continue
            end

            if not data.resting then
                local dt = FrameTime()
                data.velocity = data.velocity + Vector(0, 0, -420) * dt
                local nextPos = data.pos + data.velocity * dt
                local trace = util.TraceLine({
                    start = data.pos,
                    endpos = nextPos,
                    mask = MASK_NPCWORLDSTATIC
                })

                if trace.Hit then
                    data.pos = trace.HitPos + trace.HitNormal * 1.5
                    data.velocity = data.velocity - 2 * data.velocity:Dot(trace.HitNormal) * trace.HitNormal
                    data.velocity = data.velocity * 0.22

                    if data.velocity:LengthSqr() < 900 then
                        data.velocity = vector_origin
                        data.angularVelocity = angle_zero
                        data.resting = true
                    end
                else
                    data.pos = nextPos
                end

                data.ang:RotateAroundAxis(data.ang:Forward(), data.angularVelocity.p * dt)
                data.ang:RotateAroundAxis(data.ang:Right(), data.angularVelocity.y * dt)
                data.ang:RotateAroundAxis(data.ang:Up(), data.angularVelocity.r * dt)
            end

            local growFrac = math.Clamp(age / data.growTime, 0, 1)
            local shrinkFrac = math.Clamp((age - (data.lifetime - data.shrinkTime)) / data.shrinkTime, 0, 1)
            local scale = Lerp(shrinkFrac, data.scale * growFrac, 0.01)

            debris:SetPos(data.pos)
            debris:SetAngles(data.ang)
            debris:SetModelScale(scale, 0)
        end
    end)

    local nextOutfitterRagdollCheck = 0
    local dismemberPlayerAliveState = {}
    hook.Add("Think", "HomelanderSWEP_OutfitterGrabRagdolls", function()
        if nextOutfitterRagdollCheck > CurTime() then return end
        nextOutfitterRagdollCheck = CurTime() + 0.35

        for _, ent in ipairs(ents.GetAll()) do
            if ent:IsPlayer() then
                local alive = ent:Alive()
                if alive and dismemberPlayerAliveState[ent] == false then
                    resetHomelanderDismemberBones(ent)
                    laserDismemberOwners[ent] = nil
                end
                dismemberPlayerAliveState[ent] = alive
            end

            local directInfo = laserDismemberOwners[ent]
            local directActive = directInfo and (directInfo.expire or 0) >= CurTime() and directInfo.mode and directInfo.mode ~= ""
            local dismemberMode = ent:GetNW2String("HomelanderDismemberMode", "")
            local dismemberExpire = ent:GetNW2Float("HomelanderDismemberExpire", 0)

            if ent:IsPlayer() and not directActive and (dismemberMode == "" or dismemberExpire < CurTime()) then
                if ent.HomelanderDismemberApplied then
                    resetHomelanderDismemberBones(ent)
                end
                continue
            end

            if not isHomelanderDismemberEnabled() then
                if ent.HomelanderDismemberApplied then
                    resetHomelanderDismemberBones(ent)
                end
                continue
            end

            applyHomelanderDismemberFromOwner(ent)

            if directActive then
                applyHomelanderDismember(ent, directInfo.mode, directInfo.boneName or "")
            end

            if dismemberMode ~= "" and (not ent:IsPlayer() or dismemberExpire >= CurTime()) then
                applyHomelanderDismember(ent, dismemberMode, ent:GetNW2String("HomelanderDismemberBone", ""))
            end
        end

        for owner, data in pairs(laserDismemberOwners) do
            if not IsValid(owner) or not data or (data.expire or 0) < CurTime() then
                laserDismemberOwners[owner] = nil
            end
        end

        for ply in pairs(dismemberPlayerAliveState) do
            if not IsValid(ply) then
                dismemberPlayerAliveState[ply] = nil
            end
        end

        for _, ragdoll in ipairs(ents.FindByClass("prop_ragdoll")) do
            if ragdoll:GetNW2String("HomelanderOutfitterModel", "") ~= ""
                or IsValid(ragdoll:GetNW2Entity("HomelanderOutfitterTarget"))
                or ragdoll.HomelanderOutfitterApplied then
                updateHomelanderOutfitterRagdoll(ragdoll)
            end
        end

        for ragdoll in pairs(outfitterVisualRagdolls) do
            if not IsValid(ragdoll) then
                removeHomelanderOutfitterVisualRagdoll(ragdoll)
            end
        end
    end)

    local function playHomelanderImpactFX(kind, pos, normal, strong, debris)
        normal = normal or vector_up
        if normal:LengthSqr() <= 0.001 then normal = vector_up end
        normal:Normalize()

        if kind == "execution_blood" then
            if isHomelanderBloodEnabled() then
                local amount = getHomelanderBloodDecalAmount()
                local count = 22

                for i = 1, count do
                    local bloodDir = (normal + VectorRand() * 0.55 + vector_up * math.Rand(0.05, 0.75)):GetNormalized()
                    local bloodPos = pos + VectorRand() * math.Rand(0, 14)

                    local impact = EffectData()
                    impact:SetOrigin(bloodPos)
                    impact:SetNormal(bloodDir)
                    impact:SetScale(math.Rand(20, 46))
                    impact:SetMagnitude(math.Rand(12, 28))
                    impact:SetRadius(math.Rand(12, 26))
                    impact:SetColor(BLOOD_COLOR_RED or 0)
                    util.Effect("BloodImpact", impact, true, true)

                    local spray = EffectData()
                    spray:SetOrigin(bloodPos)
                    spray:SetNormal(bloodDir)
                    spray:SetScale(math.Rand(1.6, 3.4))
                    spray:SetMagnitude(math.Rand(16, 36))
                    spray:SetColor(BLOOD_COLOR_RED or 0)
                    util.Effect("bloodspray", spray, true, true)
                end

                local decalCount = math.floor(math.Rand(10, 18) * amount + 0.5)
                local scatter = getHomelanderBloodDecalScatter(amount, 42)
                for _ = 1, decalCount do
                    local bloodDir = (normal + VectorRand() * 0.8 + vector_up * math.Rand(0.05, 0.7)):GetNormalized()
                    local bloodPos = pos + VectorRand() * math.Rand(0, scatter)
                    local tr = util.TraceLine({
                        start = bloodPos + bloodDir * math.Rand(8, 20),
                        endpos = bloodPos - bloodDir * math.Rand(55, 120 + scatter),
                        mask = MASK_NPCWORLDSTATIC
                    })
                    if tr.Hit then
                        placeRandomBloodDecal(tr.HitPos, tr.HitNormal, 0.75, 1.45, tr.Entity)
                    end
                end
            end
            return
        end

        if kind == "laser_burn" then
            local sparks = EffectData()
            sparks:SetOrigin(pos + normal * 1.5)
            sparks:SetNormal(normal)
            sparks:SetScale(0.37)
            sparks:SetMagnitude(1)
            sparks:SetRadius(3)
            util.Effect("Sparks", sparks, true, true)

            local emitter = ParticleEmitter(pos, false)
            if emitter then
                for _ = 1, 4 do
                    local particle = emitter:Add(matImpactSmoke, pos + normal * math.Rand(1, 5) + VectorRand() * 2)
                    if particle then
                        particle:SetVelocity(normal * math.Rand(12, 34) + VectorRand() * math.Rand(4, 16))
                        particle:SetDieTime(math.Rand(0.18, 0.35))
                        particle:SetStartAlpha(math.Rand(55, 90))
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(math.Rand(3, 6))
                        particle:SetEndSize(math.Rand(10, 18))
                        particle:SetRoll(math.Rand(0, 360))
                        particle:SetRollDelta(math.Rand(-1.6, 1.6))
                        particle:SetColor(28, 28, 28)
                        particle:SetAirResistance(80)
                    end
                end

                emitter:Finish()
            end
            return
        end

        if kind == "punch" then
            local angle = normal:Angle()
            angle:RotateAroundAxis(angle:Right(), 90)

            if strong then
                ParticleEffect(STRONG_PUNCH_EFFECT, pos, angle)
            end

            if debris and getClientBool("theboysbase_cl_destruction_effects", true) then
                local debrisScale = getClientFloat("theboysbase_cl_destruction_debris_scale", 1, 0.1, 3)
                local debrisAmount = getClientFloat("theboysbase_cl_destruction_debris_amount", 1, 0, 2)
                spawnImpactDebris(pos, normal, 1, debrisScale, debrisAmount)
            end
            return
        end

        if kind == "shockwave" then
            ParticleEffect(SHOCKWAVE_EFFECT, pos, angle_zero)
            return
        end

        if kind == "flight_impact" then
            local angle = normal:Angle()
            angle:RotateAroundAxis(angle:Right(), 90)

            ParticleEffect(STRONG_PUNCH_EFFECT, pos, angle)
            ParticleEffect(SHOCKWAVE_EFFECT, pos, angle_zero)

            if getClientBool("theboysbase_cl_destruction_effects", true) then
                local debrisScale = getClientFloat("theboysbase_cl_destruction_debris_scale", 1, 0.1, 3)
                local debrisAmount = getClientFloat("theboysbase_cl_destruction_debris_amount", 1, 0, 2)

                ParticleEffect(TBOYS.Particles.SuperFlightHit, pos, angle)
                spawnImpactDebris(pos, normal, 1.55, 1.35 * debrisScale, debrisAmount)
            end
        end
    end

    net.Receive("HomelanderImpactFX", function()
        local weapon = net.ReadEntity()
        local kind = net.ReadString()
        local pos = net.ReadVector()
        local normal = net.ReadVector()
        local strong = net.ReadBool()
        local debris = net.ReadBool()
        if IsValid(weapon) and weapon:GetClass() ~= WEAPON_CLASS then return end

        playHomelanderImpactFX(kind, pos, normal, strong, debris)
    end)

    local function stopFlightTrail(ply)
        local trail = activeFlightTrails[ply]
        activeFlightTrails[ply] = nil

        if trail and isfunction(trail.StopEmission) then
            pcall(trail.StopEmission, trail)
        end
    end

    local function playFlightParticles(ply, weapon)
        local superFlying = weapon:GetNW2Bool("HomelanderSuperFlying", false)

        if superFlying and not lastFlightState[weapon] then
            ParticleEffect(TBOYS.Particles.SuperFlightBoom, ply:WorldSpaceCenter(), angle_zero)
        end

        if superFlying and not activeFlightTrails[ply] then
            local trail = CreateParticleSystem(ply, TBOYS.Particles.SuperFlightTrail, PATTACH_ABSORIGIN_FOLLOW, 0)
            if trail then
                activeFlightTrails[ply] = trail
            end
        elseif not superFlying and activeFlightTrails[ply] then
            stopFlightTrail(ply)
        end

        lastFlightState[weapon] = superFlying

    end

    hook.Add("Think", "HomelanderSWEP_FlightFX", function()
        local seen = {}

        for _, ply in ipairs(player.GetAll()) do
            local weapon = getHomelanderWeapon(ply)
            if IsValid(weapon) then
                seen[ply] = true
                playFlightParticles(ply, weapon)
            end
        end

        for ply in pairs(activeFlightTrails) do
            if not IsValid(ply) or not seen[ply] then
                stopFlightTrail(ply)
            end
        end

    end)

    local superFlightPoseBones = {
        pelvis = "ValveBiped.Bip01_Pelvis",
        neck = "ValveBiped.Bip01_Neck1",
        rightFoot = "ValveBiped.Bip01_R_Foot",
        leftFoot = "ValveBiped.Bip01_L_Foot",
        leftUpperArm = "ValveBiped.Bip01_L_UpperArm",
        rightUpperArm = "ValveBiped.Bip01_R_UpperArm"
    }

    local superFlightFixedPose = {
        neck = Angle(0, 45, 0),
        rightFoot = Angle(0, 60, 0),
        leftFoot = Angle(0, 60, 0),
        leftUpperArm = Angle(-8, 10, -33),
        rightUpperArm = Angle(8, 10, 33)
    }

    local function setSuperFlightBonePose(ply, key, ang)
        local boneName = superFlightPoseBones[key]
        if not boneName then return end

        local bone = ply:LookupBone(boneName)
        if bone then
            ply:ManipulateBoneAngles(bone, ang)
        end
    end

    local function resetSuperFlightPose(ply, instant)
        local state = flightRenderState[ply]
        if not state then return end

        if instant then
            for key in pairs(superFlightPoseBones) do
                setSuperFlightBonePose(ply, key, angle_zero)
            end

            flightRenderState[ply] = nil
            return
        end

        local lerp = math.Clamp(FrameTime() * 16, 0, 1)
        local finished = true

        state.pelvis = LerpAngle(lerp, state.pelvis or angle_zero, angle_zero)
        setSuperFlightBonePose(ply, "pelvis", state.pelvis)
        if math.abs(state.pelvis.p) > 0.2 or math.abs(state.pelvis.y) > 0.2 or math.abs(state.pelvis.r) > 0.2 then
            finished = false
        end

        for key, current in pairs(state.fixed or {}) do
            current = LerpAngle(lerp, current, angle_zero)
            state.fixed[key] = current
            setSuperFlightBonePose(ply, key, current)

            if math.abs(current.p) > 0.2 or math.abs(current.y) > 0.2 or math.abs(current.r) > 0.2 then
                finished = false
            end
        end

        if finished then
            for key in pairs(superFlightPoseBones) do
                setSuperFlightBonePose(ply, key, angle_zero)
            end

            flightRenderState[ply] = nil
        end
    end

    local function applySuperFlightPose(ply, weapon)
        if not IsValid(weapon) or not weapon:GetNW2Bool("HomelanderSuperFlying", false) then
            resetSuperFlightPose(ply)
            return
        end

        local dir = weapon:GetNW2Vector("HomelanderFlightDirection", ply:EyeAngles():Forward())
        if dir:LengthSqr() <= 0.001 then
            dir = ply:EyeAngles():Forward()
        else
            dir:Normalize()
        end

        local pitchToDirection = -math.deg(math.asin(math.Clamp(dir.z, -1, 1))) + 90
        local targetPelvis = Angle(0, 0, pitchToDirection)
        local state = flightRenderState[ply] or {}
        state.pelvis = LerpAngle(math.Clamp(FrameTime() * 12, 0, 1), state.pelvis or targetPelvis, targetPelvis)
        state.fixed = state.fixed or {}
        flightRenderState[ply] = state

        setSuperFlightBonePose(ply, "pelvis", state.pelvis)

        for key, pose in pairs(superFlightFixedPose) do
            state.fixed[key] = LerpAngle(math.Clamp(FrameTime() * 16, 0, 1), state.fixed[key] or pose, pose)
            setSuperFlightBonePose(ply, key, state.fixed[key])
        end
    end

    hook.Add("Think", "HomelanderSWEP_SuperFlightPose", function()
        local seen = {}

        for _, ply in ipairs(player.GetAll()) do
            local weapon = getHomelanderWeapon(ply)
            if IsValid(weapon) then
                seen[ply] = true
                applySuperFlightPose(ply, weapon)
            else
                resetSuperFlightPose(ply)
            end
        end

        for ply in pairs(flightRenderState) do
            if not IsValid(ply) or not seen[ply] then
                if IsValid(ply) then
                    resetSuperFlightPose(ply, true)
                else
                    flightRenderState[ply] = nil
                end
            end
        end
    end)

    local grabArmBoneName = "ValveBiped.Bip01_R_UpperArm"

    local function resetGrabArmPose(ply)
        if not grabArmPoseState[ply] then return end

        local bone = ply:LookupBone(grabArmBoneName)
        if bone then
            ply:ManipulateBoneAngles(bone, angle_zero)
        end

        grabArmPoseState[ply] = nil
    end

    local function applyGrabArmPose(ply, weapon)
        local target = weapon:GetNW2Entity("HomelanderGrabbedTarget")
        if not IsValid(target) then
            resetGrabArmPose(ply)
            return
        end

        local bone = ply:LookupBone(grabArmBoneName)
        if not bone then return end

        local bonePos = ply:GetBonePosition(bone)
        if not bonePos then
            bonePos = ply:GetShootPos()
        end

        local ragdoll = weapon:GetNW2Entity("HomelanderGrabbedRagdoll")
        local heldPos = IsValid(ragdoll) and weapon:GetGrabRagdollHeldPos(ragdoll) or target:WorldSpaceCenter()
        local dir = heldPos - bonePos
        if dir:LengthSqr() <= 0.001 then return end

        dir:Normalize()

        local bodyAng = Angle(0, ply:EyeAngles().y, 0)
        local localForward = dir:Dot(bodyAng:Forward())
        local localRight = dir:Dot(bodyAng:Right())
        local localUp = dir:Dot(vector_up)
        local horizontalDistance = math.max(math.sqrt(localForward * localForward + localRight * localRight), 0.001)
        local horizontalAngle = math.deg(math.atan2(localRight, math.max(localForward, 0.001)))
        local verticalAngle = math.deg(math.atan2(localUp, horizontalDistance))
        local pitchToTarget = math.Clamp(5 - horizontalAngle, -80, 80)
        local yawToTarget = math.Clamp(-verticalAngle - 90, -130, 130)
        local targetBoneAng = Angle(pitchToTarget, yawToTarget, 0)

        grabArmPoseState[ply] = targetBoneAng
        ply:ManipulateBoneAngles(bone, targetBoneAng)
    end

    hook.Add("Think", "HomelanderSWEP_GrabArmPose", function()
        local seen = {}

        for _, ply in ipairs(player.GetAll()) do
            local weapon = getHomelanderWeapon(ply)
            if IsValid(weapon) then
                seen[ply] = true
                applyGrabArmPose(ply, weapon)
            end
        end

        for ply in pairs(grabArmPoseState) do
            if not IsValid(ply) or not seen[ply] then
                resetGrabArmPose(ply)
            end
        end
    end)

    local function getGrabRagdollHeadView(ragdoll)
        if not IsValid(ragdoll) then return nil end

        local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
            or ragdoll:LookupBone("ValveBiped.Bip01_Neck1")

        if bone then
            local pos, ang = ragdoll:GetBonePosition(bone)
            if pos then
                return pos + HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET, ang
            end
        end

        return ragdoll:WorldSpaceCenter() + HOMELANDER_GRAB_RAGDOLL_CAMERA_OFFSET, ragdoll:GetAngles()
    end

    hook.Add("CalcView", "HomelanderSWEP_GrabVictimView", function(ply, pos, angles, fov)
        for _, holder in ipairs(player.GetAll()) do
            local weapon = getHomelanderWeapon(holder)
            if IsValid(weapon) and weapon:GetNW2Entity("HomelanderGrabbedTarget") == ply then
                local ragdoll = weapon:GetNW2Entity("HomelanderGrabbedRagdoll")
                local origin = getGrabRagdollHeadView(ragdoll)
                if origin then
                    return {
                        origin = origin,
                        angles = angles,
                        fov = fov,
                        drawviewer = false
                    }
                end
            end
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "HomelanderSWEP_EyeAndLaserFX", function()
        for _, ply in ipairs(player.GetAll()) do
            local weapon = getHomelanderWeapon(ply)
            if not IsValid(weapon) then continue end

            drawSonicBoomCone(ply, weapon)

            local leftEye, rightEye, eyeAng = HomelanderGetEyePositions(ply)
            if not leftEye or not rightEye then continue end

            local firing = weapon:GetNW2Bool("HomelanderFiring", false)
            local charge = weapon:GetNW2Float("HomelanderCharge", firing and 1 or 0.35)
            local pulse = (math.sin(CurTime() * 38 + ply:EntIndex()) + 1) * 0.5
            local now = CurTime()

            local localPly = LocalPlayer()
            local isFirstPersonLocal = ply == localPly
                and localPly:GetViewEntity() == localPly
                and not localPly:ShouldDrawLocalPlayer()

            local drawIdleEyeGlow = getClientBool("homelander_cl_idle_eye_glow", true)
            local afterglowCharge = 0

            if firing then
                eyeAfterglowUntil[weapon] = now + 1
            elseif not drawIdleEyeGlow then
                local afterglowRemaining = (eyeAfterglowUntil[weapon] or 0) - now
                if afterglowRemaining > 0 then
                    afterglowCharge = math.Clamp(afterglowRemaining / 1, 0, 1)
                else
                    eyeAfterglowUntil[weapon] = nil
                end
            end

            if firing or drawIdleEyeGlow or afterglowCharge > 0 then
                if not isFirstPersonLocal or firing or afterglowCharge > 0 then
                    local glowCharge = afterglowCharge > 0 and afterglowCharge or charge
                    drawEyeGlow(leftEye, firing, glowCharge)
                    drawEyeGlow(rightEye, firing, glowCharge)
                end
            end

            if firing then
                local hitPos = getRenderHitPos(ply, weapon)
                local leftStart = leftEye
                local rightStart = rightEye

                drawEyeBeam(leftStart, hitPos, charge, pulse, 0)
                drawEyeBeam(rightStart, hitPos, charge, 1 - pulse, 0.35)

                drawHitGlow(hitPos, EyePos(), charge, pulse)

                makeLight(ply:EntIndex(), hitPos, 110 + charge * 130, 3 + charge * 4, 1200)

                if ply == LocalPlayer() then
                    makeLight(ply:EntIndex() + 2048, (leftEye + rightEye) * 0.5, 55 + charge * 75, 1.8 + charge * 3, 900)
                end
            end
        end
    end)
end 


local entMeta = FindMetaTable("Entity")
-- meow

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Equipment base"
ENT.Category = "ZCity Equipment"
ENT.Spawnable = false
ENT.Model = "models/props_junk/cardboard_box003a.mdl"
ENT.IconOverride = ""

ENT.SlotOccupation = {
    --[zc_equipment_SLOT_TORSO] = true,
    --[zc_equipment_SLOT_PANTS] = true,
    --[zc_equipment_SLOT_BOOTS] = true,
}

ENT.Male = {}
ENT.Male.Model = ""
ENT.Male.HideSubMaterails = {}
ENT.Male.Skin = 0
ENT.Male.Bodygroups = "0000000000000"

ENT.FeMale = {}
ENT.FeMale.Model = ""
ENT.FeMale.HideSubMaterails = {}
ENT.FeMale.Skin = 0
ENT.FeMale.Bodygroups = "0000000000000"

ENT.PhysicsSounds = true

ENT.NamePos = Vector(12,1.5,4.6)
ENT.NameAng = Angle(0,-90,0)

local textcolor = Color(0, 0, 0)

function ENT:Draw()
    if self:GetMoveType() == MOVETYPE_NONE or self.GetEquiped and self:GetEquiped() then self:DrawShadow(false) return end
    self:DrawModel()

    local pos, ang = LocalToWorld(self.NamePos * self:GetModelScale(), self.NameAng, self:GetPos(), self:GetAngles())
    cam.Start3D2D(pos,ang, 0.10 * self:GetModelScale())
        local light1 = render.ComputeLighting(pos, ang:Up() * 1)
        local light2 = render.ComputeDynamicLighting(pos, ang:Up() * 1)

        local light = (light1 + light2) * 2
        textcolor.r = 255 * light[1]
        textcolor.g = 55 * light[2]
        textcolor.b = 55 * light[3]
        draw.SimpleText(self.PrintName, "HomigradFontSmall", 1, 1, color_black, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        draw.SimpleText(self.PrintName, "HomigradFontSmall", 0, 0, textcolor, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", "Equiped" )
    if SERVER then
        self:SetEquiped(false)
    end
end

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:DrawShadow(true)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
    	phys:SetMass(15)
    	phys:Wake()
    	phys:EnableMotion(true)
    end

    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end
end

--\\ CanWear
    function ENT:CanWear(entUser)
        local Equipment = entUser:GetNetVar("zc_equipment", {})
        if IsValid(self.WearOwner) then return false end

        for _,v in ipairs(Equipment) do
            local Equip = Entity(v)
            if !IsValid(Equip) then continue end
            -- PrintTable(Equip.SlotOccupation)
            -- PrintTable(self.SlotOccupation)
            for slot, _ in pairs(Equip.SlotOccupation) do
                if isnumber(slot) and self.SlotOccupation[slot] then return false, slot end
            end

            for slot, _ in pairs(self.SlotOccupation) do
                if isnumber(slot) and Equip.SlotOccupation[slot] then return false, slot end
            end
        end

        return true
    end
--//
--\\ Use function
    function ENT:Use(entUser)
        local CanWear, Slot = self:CanWear(entUser) 
        if !CanWear then entUser:GetEquipmentBySlot(Slot):Unwear(entUser) return end

        self:Wear(entUser)
    end
--//
--\\ Wear Unwear functions
    function ENT:Wear(entUser, bDontChangeMaterials, noChange)
        if !self.Respawned then -- I'M VERRY SORRY FOR THIS SILLY SHIT, BUT GMOD IS BULLSHIT I CAN'T REMOVE ENT FROM PLAYERS CLEANUP ACTUALY I CAN BUT IS MORE JANKY THAN THAT!!!
            local class = self:GetClass()
            local ent = ents.Create(class)
            if !IsValid(ent) then return end
            ent.Respawned = true
            ent:Spawn()
            ent:Wear(entUser, bDontChangeMaterials, noChange)

            SafeRemoveEntity(self)
            return
        end

        if !noChange then
            local Equipment = entUser:GetNetVar("zc_equipment", {})
            Equipment[#Equipment + 1] = self:EntIndex()
            entUser:SetNetVar("zc_equipment", Equipment)

            local EquipmentBySlot = entUser:GetNetVar("zc_equipment_slot", {})
            for k,v in pairs(self.SlotOccupation) do
                EquipmentBySlot[k] = self:EntIndex()
            end
            entUser:SetNetVar("zc_equipment_slot", EquipmentBySlot)
            
            self:OnWearNetVars(entUser)
        end

        local fem = ThatPlyIsFemale(entUser)
        local data = fem and self.FeMale or self.Male
        if !bDontChangeMaterials then
            for k,v in ipairs(data.HideSubMaterails) do
                local mat = entUser:GetSubMaterialIdByName(v)
                if !mat then continue end
                self.OldSubMaterials = self.OldSubMaterials or {}
                self.OldSubMaterials[mat] = entUser:GetSubMaterial(mat)

                entUser:SetSubMaterial(mat,"NULL")
                local curchar = hg.GetCurrentCharacter(entUser)
                if IsValid(curchar) and curchar:IsRagdoll() then
                    curchar:SetSubMaterial(mat,"NULL")
                end
            end
        end

        self:SetPos(entUser:GetPos())
        self:SetParent(entUser, 0)
        self.WearOwner = entUser

        self:SetNoDraw(false)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:AddSolidFlags(FSOLID_NOT_SOLID)
        self:SetSolid(SOLID_NONE)
        self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        self:DrawShadow(false)
        self:SetEquiped(true)

        self:OnWear(entUser)
    end

    function ENT:OnWearNetVars(entUser)
		--// Write your code here
	end

    function ENT:OnWear(entUser)
		--// Write your code here
	end
---------------------------------------------------------------
    function ENT:Unwear(entUser, bDontChangeMaterials, noChange)
        if !noChange then
            local Equipment = entUser:GetNetVar("zc_equipment", {})
            table.RemoveByValue(Equipment, self:EntIndex())
            entUser:SetNetVar("zc_equipment", Equipment)

            local EquipmentBySlot = entUser:GetNetVar("zc_equipment_slot", {})
            for k,v in pairs(self.SlotOccupation) do
                EquipmentBySlot[k] = nil
            end
            entUser:SetNetVar("zc_equipment_slot", EquipmentBySlot)

            self:OnUnwearNetVars(entUser)
        end

        if !bDontChangeMaterials and self.OldSubMaterials then
            for k,v in pairs(self.OldSubMaterials) do
                entUser:SetSubMaterial(k,v)
                local curchar = hg.GetCurrentCharacter(entUser)
                if IsValid(curchar) and curchar:IsRagdoll() then
                    curchar:SetSubMaterial(k,v)
                end
            end
            table.Empty(self.OldSubMaterials)
        end

        self:SetParent(nil)
        self:SetNoDraw(false)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:RemoveSolidFlags(FSOLID_NOT_SOLID)
        self:SetSolid(SOLID_VPHYSICS)
        self:RemoveEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        self:DrawShadow(true)
        self:SetEquiped(false)

        timer.Simple(0,function()
            if !IsValid(self) or !IsValid(entUser) then return end
            self:SetPos(entUser:IsPlayer() and hg.eyeTrace(entUser).StartPos or entUser:GetPos())
        end)
        if !noChange then
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:AddVelocity(entUser:IsPlayer() and hg.eyeTrace(entUser).Normal * 65 or vector_origin)
            end

            self:SetAngles(entUser:EyeAngles())
        end

        self.WearOwner = nil

        self:OnUnwear(entUser)
    end

    function ENT:OnUnwearNetVars(entUser)
		--// Write your code here
	end

    function ENT:OnUnwear(entUser)
		--// Write your code here
	end
--//

--\\
    function ENT:OnRemove()
        if !IsValid(self.WearOwner) then return end

        self:Unwear(self.WearOwner)
    end
--//

--\\ Render Equipment
    local vec = Vector(1,1,1)
    function ENT:RenderOnBody(entDrawOn)
    end
--//

--\\ Render hook
    hook.Add("CoolPostDrawAppearance", "zc_equipmentDraw",function(ent, ply)
        local Equipment = ply:GetNetVar("zc_equipment", {})
        if #Equipment < 1 then return end
        for i = 1, #Equipment do
            local Equip = Entity(Equipment[i])
            if !IsValid(Equip) or !Equip.RenderOnBody then continue end
            Equip:RenderOnBody(ent)
        end
    end)
--//

--\\ Transfer items
    hook.Add("ItemsTransfered", "TransferEquipment", function(ply, ragdoll)
        local Equipment = ply:GetNetVar("zc_equipment", {})
        local EquipmentBySlot = ply:GetNetVar("zc_equipment_slot", {})
        if Equipment and #Equipment < 1 then return end

        for i = 1, #Equipment do
            local Equip = Entity(Equipment[i])
            if !IsValid(Equip) then continue end
            Equip:Unwear(ply, true, true)
            Equip:Wear(ragdoll, true, true)
        end
        ragdoll:SetNetVar("zc_equipment",Equipment)
        ragdoll:SetNetVar("zc_equipment_slot", EquipmentBySlot)
        ply:SetNetVar("zc_equipment", {})
        ply:SetNetVar("zc_equipment_slot", {})
    end)
--//

--\\ Die items
    hook.Add("ItemsRemoved", "TransferEquipment", function(ply, ragdoll)
        local Equipment = ply:GetNetVar("zc_equipment", {})
        local EquipmentBySlot = ply:GetNetVar("zc_equipment_slot", {})
        if Equipment and #Equipment < 1 then return end

        for i = 1, #Equipment do
            local Equip = Entity(Equipment[i])
            if !IsValid(Equip) then continue end
            Equip:Remove()
        end
    end)
--//

--\\
    function entMeta:GetEquipmentBySlot(slot)
        local EquipmentBySlot = self:GetNetVar("zc_equipment_slot",{})

        return EquipmentBySlot[slot] and Entity(EquipmentBySlot[slot]) or nil
    end

    function entMeta:GetEquipments(slot)

        return self:GetNetVar("zc_equipment", {})
    end
--//

--\\ Equipment drop command
    if SERVER then
        concommand.Add("hg_drop_new_equipment", function(ply, cmd, args)
            if !IsValid(ply) then return end
            if !ply:Alive() or !ply.organism or ply.organism.otrub then return end
            if !args[1] or !tonumber(args[1]) then return end
            local Equipment = ply:GetNetVar("zc_equipment", {})
            if not Equipment[tonumber(args[1])] then return end
            local Equip = Entity(Equipment[tonumber(args[1])])
            if !IsValid(Equip) then return end

            Equip:Unwear(ply)
        end)
    end
    
    hook.Add("radialOptions", "1_zc_equipment", function()
        local ply = LocalPlayer()
        local organism = ply.organism or {}

        if ply:Alive() and !organism.otrub then
            local Equipment = ply:GetNetVar("zc_equipment", {})
            if !Equipment or #Equipment < 1 then return end
            local tbl = {function()
                local commands = {}
                for i = 1, #Equipment do
                    local Equip = Entity(Equipment[i])

                    for slot, _ in pairs(Equip.SlotOccupation) do
                        --Equip.IconInv = isstring(Equip.IconOverride) and Material(Equip.IconOverride) or Equip.IconInv or nil -- soon
                        commands[i] = {
                            [1] = function()
                                RunConsoleCommand("hg_drop_new_equipment", i)
                                return 0
                            end,
                            [2] = "Drop:" .. " " .. Equip.PrintName,
                        }
                    end
                end
                hg.CreateRadialMenu(commands)
                return -1
            end, "Drop\nEquipment"}
            hg.radialOptions[#hg.radialOptions + 1] = tbl
        end
    end)
--//
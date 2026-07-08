AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:SetModel(self.Model) --| Standard Spawn Features

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(75) --| GIVE HIM WEIGHT
		phys:Wake()
		phys:EnableMotion(true)
	end

    self.Loot = {
        --[[ 
            [ ID ] = { 
                class = "CLASS NAME",
                entData = {
                    DataETC = "DATE" --| For player containers where things can be stored.
                    --| By the way, with the help of this you can make unique entities that will have their own jokes, even though they are essentially the same class
                }
            }, 
        --]]
    }
    self.ShowContainer = {
        --| Players who opened the container

    }
end

local loottypes = {
    [ "entity" ] = function( self, user, class, spawnFunctions, entData )
        if not IsValid( user ) or not user:IsPlayer() then return false end --| We check the player's validity.
        --| After verification, we create an entity.
        local ent = ents.Create( class )
        --| Don't forget to set the spawn property. Disables auto-selection.
        ent.IsSpawned = true
        --| We are looking for a position to spawn our entity.
        local spawnPos = util.TraceEntityHull( {
            start = self:GetPos() + ( vector_up * 5 ),
            endpos = user:GetPos() + ( vector_up * 15 ),
            filter = { self },
            mask = MASK_SHOT
        }, ent ).HitPos
        ent:SetPos( spawnPos ) --| We set a position.
        ent:Spawn() --| And let's spawn.

        --| If there was any recorded date, we give it to the entity.
        if entData then
            for k,data in pairs( entData ) do
                ent[ k ] = data
            end
        end
        --| We produce spawn functions, if they exist.
        if spawnFunctions then
            for _, func in ipairs( spawnFunctions ) do
                func( ent )
            end
        end

        return ent --| Return the entity.
    end,
}

ZBox = ZBox or {}
ZBox.LootSystem = ZBox.LootSystem or {}

function ENT:TakeItem( ply, itemID ) --| Grab it for free
    local item = self.Loot[itemID]
    local spawnFunctions = ZBox.LootSystem.spawnFunctions or {}
    if item then
        loottypes[ "entity" ]( self, ply, item.class, spawnFunctions[ item.class ], item.entData )
        self.Loot[itemID] = nil
        item = nil
    end
end

function ENT:Use( activator ) --| Transfer of data about the crate only at the moment of opening. So as not to SHIT
    if !IsValid( activator ) or !activator:IsPlayer() then return false end --| We are checking the player's validity...
    if ( activator:GetPos() - self:GetPos() ):Length() > 400 then 
        print( "[ ZBox | LootSystem ]: ".. activator .. "[SteamID:".. activator:SteamID() .. "]" .." trying USE CONTAINER but, he not in radius CHEATS?" ) 
        return false 
    end

    self:OpenContainer( activator )
end

util.AddNetworkString( "ZBox_LootSystem_net" )

function ZBox.LootSystem.SendLootTable( ent, ply, tbl ) --| Sending cool nets.

    net.Start( "ZBox_LootSystem_net" )
        net.WriteEntity( ent )
        net.WriteString( util.TableToJSON( tbl ) ) --| Why waste extra resources on a table, let's just convert it to a string lol.
    net.Send( ply )--resources one "with" moron

    return true
end

net.Receive( "ZBox_LootSystem_net", function( len, ply ) 
    local Container = net.ReadEntity()
    Container.TakeCD = Container.TakeCD or 0
    if Container.TakeCD > CurTime() then 
        print( "[ ZBox | LootSystem ]: ".. ply .. "[SteamID:".. ply:SteamID() .. "]" .." trying TAKE ITEM but, cooldown is on." ) 
        return false 
    end

    Container.TakeCD = CurTime() + 0.1

    if ( ply:GetPos() - Container:GetPos() ):Length() > 400 then 
        print( "[ ZBox | LootSystem ]: ".. ply .. "[SteamID:".. ply:SteamID() .. "]" .." trying TAKE ITEM but, he not in radius CHEATS?!" ) 
        return false 
    end

    local ItemID = net.ReadUInt(10)

    if not Container.Loot[ItemID] then 
        print( "[ ZBox | LootSystem ]: ".. ply .. "[SteamID:".. ply:SteamID() .. "]" .." trying TAKE ITEM but, item is invalid." ) 
        return false 
    end

    Container:TakeItem( ply, ItemID ) 
end)

local SendLootTable = ZBox.LootSystem.SendLootTable

function ENT:OpenContainer( ply ) --| Open the container to the player.
    local OptimizedTable = {} --| We create an empty table to send to the client.
    for k, data in pairs( self.Loot ) do --| Recording in a table.
        OptimizedTable[ k ] = { class = data.class }
    end
    self:EmitSound("items/ammocrate_open.wav")
    SendLootTable( self, ply, OptimizedTable ) --| Sending to the client.
    self.ShowContainer[ ply:EntIndex() ] = ply
end


function ENT:GenerateLoot()
    if not self.CanGenerate then return end
    local count = 0
    local ammout = math.random( 1, self.LootCountMul or 3)
    for i = 1, ammout do
        if #self.Loot > 6 then return end
        local item = table.Random(self.LootTable)
		
		if(istable(item))then
			_, item = hg.WeightedRandomSelect(tab, mul)
		end
		
        if count >= ammout then return end
        count = count + 1
        self.Loot[#self.Loot + 1] = { class = item.class }
    end
    self.LastLootGenerate = CurTime()
end

function ENT:Think()
    self.LastLootGenerate = self.LastLootGenerate or 0

    if self.LastLootGenerate + 1200 < CurTime() then
        self:GenerateLoot()
    end

    self:NextThink( CurTime() + 60 )
    return true
end
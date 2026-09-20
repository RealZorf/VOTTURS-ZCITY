zb = zb or {}

if (CLIENT) then
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.globals = zb.net.globals or {}

    net.Receive("zbGlobalVarSet", function()
        local key, var = net.ReadString(), net.ReadType()

    	zb.net.globals[key] = var

        hook.Run("OnGlobalVarSet", key, var)
    end)

    net.Receive("zbNetVarSet", function()
        local index = net.ReadUInt(16)

		local key = net.ReadString()
    	local var = net.ReadType()
		
        zb.net[index] = zb.net[index] or {}
        zb.net[index][key] = var

		-- print(index, key)
		
		if IsValid(Entity(index)) then
			hook.Run("OnNetVarSet", index, key, var)
		else
			zb.net[index].waiting = true
		end
    end)
	
    net.Receive("zbNetVarDelete", function()
    	zb.net[net.ReadUInt(16)] = nil
    end)

    net.Receive("zbSyncBatch", function()
    	local kind = net.ReadUInt(2)
    	local count = net.ReadUInt(16)
    	for i = 1, count do
    		if kind == 3 then
    			local index = net.ReadUInt(16)
    			local key = net.ReadString()
    			local var = net.ReadType()

    			zb.net[index] = zb.net[index] or {}
    			zb.net[index][key] = var

    			if IsValid(Entity(index)) then
    				hook.Run("OnNetVarSet", index, key, var)
    			else
    				zb.net[index].waiting = true
    			end
    		elseif kind == 1 then
    			local key = net.ReadString()
    			local var = net.ReadType()

    			zb.net.globals[key] = var
    			hook.Run("OnGlobalVarSet", key, var)
    		elseif kind == 2 then
    			local key = net.ReadString()
    			local var = net.ReadType()

    			local idx = LocalPlayer():EntIndex()
    			zb.net[idx] = zb.net[idx] or {}
    			zb.net[idx][key] = var

    			hook.Run("OnLocalVarSet", key, var)
    		end
    	end
    end)

    net.Receive("zbLocalVarSet", function()
    	local key = net.ReadString()
    	local var = net.ReadType()

    	zb.net[LocalPlayer():EntIndex()] = zb.net[LocalPlayer():EntIndex()] or {}
    	zb.net[LocalPlayer():EntIndex()][key] = var

    	hook.Run("OnLocalVarSet", key, var)
    end)

    function GetNetVar(key, default) -- luacheck: globals GetNetVar
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function entityMeta:GetNetVar(key, default)
    	local index = self:EntIndex()

    	if (zb.net[index] and zb.net[index][key] != nil) then
    		return zb.net[index][key]
    	end

    	return default
    end

    playerMeta.GetLocalVar = entityMeta.GetNetVar

	hook.Add("InitPostEntity", "OnRequestFullUpdate_zb", function()
		LocalPlayer():SyncVars()
	end)

	function playerMeta:SyncVars()
		net.Start("ZB_request_fullupdate")
		net.SendToServer()
	end
else
	util.AddNetworkString("ZB_request_fullupdate")

	net.Receive("ZB_request_fullupdate",function(len,ply)
		ply.cooldown_sendnet = ply.cooldown_sendnet or 0
		if ply.cooldown_sendnet < CurTime() then
			ply.cooldown_sendnet = CurTime() + 1

			ply:SyncVars()
		end
	end)

	gameevent.Listen( "OnRequestFullUpdate" )
	hook.Add("OnRequestFullUpdate", "OnRequestFullUpdate_zb", function(data)
		local id = data.userid
		local ply = Player(id)

		if not IsValid(ply) then return end
		ply:SyncVars()
	end)
	
	
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.list = zb.net.list or {}
    zb.net.locals = zb.net.locals or {}
    zb.net.globals = zb.net.globals or {}

    util.AddNetworkString("zbGlobalVarSet")
    util.AddNetworkString("zbLocalVarSet")
    util.AddNetworkString("zbNetVarSet")
    util.AddNetworkString("zbNetVarDelete")
    util.AddNetworkString("zbSyncBatch")

    local function CheckBadType(name, object)
		return false
    	--[[if (isfunction(object)) then
    		ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")

    		return true
    	elseif (istable(object)) then
    		for k, v in pairs(object) do
    			if (CheckBadType(name, k) or CheckBadType(name, v)) then
    				return true
    			end
    		end
    	end--]]
    end

    function GetNetVar(key, default)
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function SetNetVar(key, value, receiver, unreliable)
    	if (CheckBadType(key, value)) then return end
    	--if (GetNetVar(key) == value) then return end
		
    	zb.net.globals[key] = value

    	net.Start("zbGlobalVarSet", unreliable)
    	net.WriteString(key)
    	net.WriteType(value)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
    -- Chunked, paced full-sync to avoid overflowing the reliable buffer
    -- (the per-message limit is ~64 KB and the per-client reliable buffer
    -- is 256 KB; firing a separate net.Send per netvar pegged it during
    -- round restarts when game.CleanUpMap triggers OnRequestFullUpdate
    -- for every player at once).
    local SYNC_CHUNK_BYTES = 24 * 1024
    local SYNC_QUEUE = SYNC_QUEUE or {}

    local function syncEstimateValueBytes(v)
    	local t = TypeID(v)
    	if t == TYPE_STRING then
    		return #v + 4
    	elseif t == TYPE_TABLE then
    		local ok, json = pcall(util.TableToJSON, v)
    		return ok and #json + 8 or 256
    	elseif t == TYPE_VECTOR or t == TYPE_ANGLE then
    		return 16
    	elseif t == TYPE_BOOL then
    		return 2
    	end
    	return 16
    end

    local function syncFlushChunk(ply, kind, chunk)
    	if #chunk == 0 then return end
    	net.Start("zbSyncBatch")
    	net.WriteUInt(kind, 2)
    	net.WriteUInt(#chunk, 16)
    	for i = 1, #chunk do
    		local entry = chunk[i]
    		if kind == 3 then
    			net.WriteUInt(entry[1], 16)
    			net.WriteString(entry[2])
    			net.WriteType(entry[3])
    		else
    			net.WriteString(entry[1])
    			net.WriteType(entry[2])
    		end
    	end
    	net.Send(ply)
    end

    local function syncEnqueueChunks(ply, kind, entries)
    	if #entries == 0 then return end
    	SYNC_QUEUE[ply] = SYNC_QUEUE[ply] or {}
    	local queue = SYNC_QUEUE[ply]

    	local chunk = {}
    	local chunkBytes = 0
    	for i = 1, #entries do
    		local entry = entries[i]
    		local size
    		if kind == 3 then
    			size = 2 + #entry[2] + 1 + syncEstimateValueBytes(entry[3])
    		else
    			size = #entry[1] + 1 + syncEstimateValueBytes(entry[2])
    		end

    		if chunkBytes + size > SYNC_CHUNK_BYTES and #chunk > 0 then
    			queue[#queue + 1] = { kind = kind, entries = chunk }
    			chunk = {}
    			chunkBytes = 0
    		end
    		chunk[#chunk + 1] = entry
    		chunkBytes = chunkBytes + size
    	end
    	if #chunk > 0 then
    		queue[#queue + 1] = { kind = kind, entries = chunk }
    	end
    end

    hook.Add("Tick", "ZB_SyncBatchPacer", function()
    	for ply, queue in pairs(SYNC_QUEUE) do
    		if not IsValid(ply) then
    			SYNC_QUEUE[ply] = nil
    		elseif #queue == 0 then
    			SYNC_QUEUE[ply] = nil
    		else
    			local job = table.remove(queue, 1)
    			syncFlushChunk(ply, job.kind, job.entries)
    		end
    	end
    end)

    hook.Add("PlayerDisconnected", "ZB_SyncBatchPacer_Cleanup", function(ply)
    	SYNC_QUEUE[ply] = nil
    end)

    function playerMeta:SyncVars()
    	self.lastSyncVars = self.lastSyncVars or 0
    	if self.lastSyncVars > CurTime() - 0.5 then return end
    	self.lastSyncVars = CurTime()

    	local globalEntries = {}
    	for k, v in pairs(zb.net.globals) do
    		globalEntries[#globalEntries + 1] = { k, v }
    	end
    	syncEnqueueChunks(self, 1, globalEntries)

    	local localEntries = {}
    	for k, v in pairs(zb.net.locals[self] or {}) do
    		localEntries[#localEntries + 1] = { k, v }
    	end
    	syncEnqueueChunks(self, 2, localEntries)

    	local entEntries = {}
    	for entity, data in pairs(zb.net.list) do
    		if IsValid(entity) then
    			local index = entity:EntIndex()
    			for k, v in pairs(data) do
                    if hg.WoundNet and hg.WoundNet.IsWoundKey and hg.WoundNet.IsWoundKey(k) then continue end
    				entEntries[#entEntries + 1] = { index, k, v }
    			end
    		else
    			zb.net.list[entity] = nil
    		end
    	end
    	syncEnqueueChunks(self, 3, entEntries)
        if hg.WoundNet and hg.WoundNet.ForceViewer then hg.WoundNet.ForceViewer(self) end
    end
	
    function playerMeta:GetLocalVar(key, default)
    	if (zb.net.locals[self] and zb.net.locals[self][key] != nil) then
    		return zb.net.locals[self][key]
    	end

    	return default
    end

    function playerMeta:SetLocalVar(key, value)
    	if (CheckBadType(key, value)) then return end

    	zb.net.locals[self] = zb.net.locals[self] or {}
    	zb.net.locals[self][key] = value

    	net.Start("zbLocalVarSet")
    		net.WriteString(key)
    		net.WriteType(value)
    	net.Send(self)
    end

    function entityMeta:GetNetVar(key, default)
		if hg.WoundNet and hg.WoundNet.GetLegacyValue then
			local handled, value = hg.WoundNet.GetLegacyValue(self, key)
			if handled then return value != nil and value or default end
		end

    	if (zb.net.list[self] and zb.net.list[self][key] != nil) then
    		return zb.net.list[self][key]
    	end

    	return default
    end

    function entityMeta:SetNetVar(key, value, receiver)
    	if (CheckBadType(key, value)) then return end
		if hg.WoundNet and hg.WoundNet.HandleLegacySet and hg.WoundNet.HandleLegacySet(self, key, value) then return end

		zb.net.list[self] = zb.net.list[self] or {}

		--if not hg.IsChanged(value, key, zb.net.list[self]) then return end

    	if (zb.net.list[self][key] != value) then
    		zb.net.list[self][key] = value 
    	end
		
		self:SendNetVar(key, receiver)
	end

    function entityMeta:SendNetVar(key, receiver)
		if hg.WoundNet and hg.WoundNet.IsWoundKey and hg.WoundNet.IsWoundKey(key) then
			if hg.WoundNet.HandleLegacySet then hg.WoundNet.HandleLegacySet(self, key, self:GetNetVar(key)) end
			return
		end

    	net.Start("zbNetVarSet")
    	net.WriteUInt(self:EntIndex(), 16)
    	net.WriteString(key)
    	net.WriteType(zb.net.list[self] and zb.net.list[self][key])

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end

    function entityMeta:ClearNetVars(receiver)
		if hg.WoundNet and hg.WoundNet.EntityRemoved then hg.WoundNet.EntityRemoved(self) end
    	zb.net.list[self] = nil
    	zb.net.locals[self] = nil

    	net.Start("zbNetVarDelete")
    	net.WriteUInt(self:EntIndex(), 16)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
	hook.Add("EntityRemoved","ZB_clear_net",function(ent,fullUpdate)
		ent:ClearNetVars()
	end)

	hook.Add("PlayerDisconnected","ZB_clear_net",function(ply)
		ply:ClearNetVars()
	end)
end

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

	local function ShouldSkipNetVarResend(currentValue, newValue, receiver)
		if receiver ~= nil then return false end
		if istable(currentValue) or istable(newValue) then return false end

		return currentValue == newValue
	end

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
		if not IsValid(ply) then
			for _, candidate in player.Iterator() do
				if candidate:UserID() == id then
					ply = candidate
					break
				end
			end
		end
		
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

		if ShouldSkipNetVarResend(zb.net.globals[key], value, receiver) then return end
		
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
	
	local syncBatchSize = CreateConVar("zb_netvar_sync_batch_size", "12", FCVAR_ARCHIVE, "How many Z-City netvars to send per full-update batch.", 4, 64)
	local syncBatchDelay = CreateConVar("zb_netvar_sync_batch_delay", "0.05", FCVAR_ARCHIVE, "Delay between Z-City netvar full-update batches.", 0.01, 0.25)

	local function queueSyncItem(queue, kind, a, b)
		queue[#queue + 1] = {kind, a, b}
	end

	local function sendQueuedSyncItem(ply, item)
		if not IsValid(ply) then return false end

		local kind = item[1]
		if kind == "global" then
			local key = item[2]
			local value = zb.net.globals[key]
			if value == nil then return false end

			net.Start("zbGlobalVarSet")
				net.WriteString(key)
				net.WriteType(value)
			net.Send(ply)

			return true
		elseif kind == "local" then
			local key = item[2]
			local localVars = zb.net.locals[ply]
			if not localVars then return false end

			local value = localVars[key]
			if value == nil then return false end

			net.Start("zbLocalVarSet")
				net.WriteString(key)
				net.WriteType(value)
			net.Send(ply)

			return true
		elseif kind == "entity" then
			local entity, key = item[2], item[3]
			if not IsValid(entity) then
				zb.net.list[entity] = nil
				return false
			end

			local data = zb.net.list[entity]
			if not data then return false end

			local value = data[key]
			if value == nil then return false end

			net.Start("zbNetVarSet")
				net.WriteUInt(entity:EntIndex(), 16)
				net.WriteString(key)
				net.WriteType(value)
			net.Send(ply)

			return true
		end

		return false
	end

	local function runSyncQueue(ply)
		if not IsValid(ply) then return end

		local queue = ply.ZBNetVarSyncQueue
		if not queue then return end

		local sent = 0
		local maxPerBatch = syncBatchSize:GetInt()
		local queueIndex = ply.ZBNetVarSyncQueueIndex or 1

		while sent < maxPerBatch and queueIndex <= #queue do
			local item = queue[queueIndex]
			queue[queueIndex] = nil
			queueIndex = queueIndex + 1

			if sendQueuedSyncItem(ply, item) then
				sent = sent + 1
			end
		end

		ply.ZBNetVarSyncQueueIndex = queueIndex

		if queueIndex > #queue then
			ply.ZBNetVarSyncQueue = nil
			ply.ZBNetVarSyncQueueIndex = nil
			ply.ZBNetVarSyncActive = nil
			ply.ZBNetVarLastSync = CurTime()
			timer.Remove("ZB_SyncVars_" .. ply:UserID())
		end
	end

	function playerMeta:SyncVars(force)
		if not IsValid(self) then return end

		if self.ZBNetVarSyncActive then return end
		if not force and (self.ZBNetVarLastSync or 0) > CurTime() - 5 then return end

		local queue = {}

		for k in pairs(zb.net.globals) do
			queueSyncItem(queue, "global", k)
		end

		for k in pairs(zb.net.locals[self] or {}) do
			queueSyncItem(queue, "local", k)
		end

		for entity, data in pairs(zb.net.list) do
			if IsValid(entity) then
				for k in pairs(data) do
					queueSyncItem(queue, "entity", entity, k)
				end
			else
				zb.net.list[entity] = nil
			end
		end

		self.ZBNetVarSyncQueue = queue
		self.ZBNetVarSyncQueueIndex = 1

		if #queue <= 0 then
			self.ZBNetVarSyncQueueIndex = nil
			self.ZBNetVarLastSync = CurTime()
			return
		end

		self.ZBNetVarSyncActive = true

		local timerName = "ZB_SyncVars_" .. self:UserID()
		timer.Remove(timerName)
		timer.Create(timerName, syncBatchDelay:GetFloat(), 0, function()
			runSyncQueue(self)
		end)

		runSyncQueue(self)
	end

	hook.Add("PlayerDisconnected", "ZB_StopNetVarSync", function(ply)
		timer.Remove("ZB_SyncVars_" .. ply:UserID())
		ply.ZBNetVarSyncQueue = nil
		ply.ZBNetVarSyncQueueIndex = nil
		ply.ZBNetVarSyncActive = nil
	end)
	
    function playerMeta:GetLocalVar(key, default)
    	if (zb.net.locals[self] and zb.net.locals[self][key] != nil) then
    		return zb.net.locals[self][key]
    	end

    	return default
    end

    function playerMeta:SetLocalVar(key, value)
    	if (CheckBadType(key, value)) then return end

    	zb.net.locals[self] = zb.net.locals[self] or {}
		if ShouldSkipNetVarResend(zb.net.locals[self][key], value, nil) then return end
    	zb.net.locals[self][key] = value

    	net.Start("zbLocalVarSet")
    		net.WriteString(key)
    		net.WriteType(value)
    	net.Send(self)
    end

    function entityMeta:GetNetVar(key, default)
    	if (zb.net.list[self] and zb.net.list[self][key] != nil) then
    		return zb.net.list[self][key]
    	end

    	return default
    end

    function entityMeta:SetNetVar(key, value, receiver)
    	if (CheckBadType(key, value)) then return end

		zb.net.list[self] = zb.net.list[self] or {}

		if ShouldSkipNetVarResend(zb.net.list[self][key], value, receiver) then return end
    	zb.net.list[self][key] = value
		
		self:SendNetVar(key, receiver)
	end

    function entityMeta:SendNetVar(key, receiver)
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
		local hadNetVars = zb.net.list[self] ~= nil or zb.net.locals[self] ~= nil
		if not hadNetVars then return end

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

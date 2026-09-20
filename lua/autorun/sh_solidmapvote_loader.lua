local root = "solidmapvote/"

local function LoadClient(path)
    if SERVER then
        AddCSLuaFile(path)
    else
        include(path)
    end
end

local function LoadServer(path)
    if SERVER then
        include(path)
    end
end

local function LoadShared(path)
    if SERVER then
        AddCSLuaFile(path)
    end
    include(path)
end

print("[SolidMapVote] Starting Manual Load...")

SolidMapVote = SolidMapVote or {}

if SERVER then
    resource.AddFile("sound/rtv.wav")
    resource.AddFile("sound/nortv.wav")
end

if file.Exists(root .. "sh_mapvote_config.lua", "LUA") then
    LoadShared(root .. "sh_mapvote_config.lua")
elseif file.Exists(root .. "mapvote_config.lua", "LUA") then
    LoadShared(root .. "mapvote_config.lua")
end

LoadClient(root .. "core/lib/b-draw_lib.lua")

LoadClient(root .. "core/client/cl_net.lua")
LoadClient(root .. "core/client/cl_mapvote.lua")

LoadServer(root .. "core/server/sv_net.lua")
LoadServer(root .. "core/server/sv_mapvote.lua")
LoadServer(root .. "core/server/sv_hooks.lua")

local vgui_files = file.Find(root .. "vgui/*.lua", "LUA")
for _, f in ipairs(vgui_files) do
    LoadClient(root .. "vgui/" .. f)
end

if SERVER then
    local function OverrideZCityVoteSystem()
        zb = zb or {}

        zb.StartRTV = function()
            if not SolidMapVote or not SolidMapVote.start then
                print("[SolidMapVote] Error: SolidMapVote not found, cannot start mapvote!")
                return
            end

            if SolidMapVote.isOpen then return end

            zb.votestarted = true
            SolidMapVote.start()
        end

        zb.CheckRTVVotes = function()
            return SolidMapVote.RTVCompleted or SolidMapVote.startVoteAfterRound or SolidMapVote.isOpen
        end

        zb.ClearRTVVotes = function()
            SolidMapVote.RTVs = {}
            SolidMapVote.PleaseRTVs = {}
            SolidMapVote.DontRTVs = {}
            SolidMapVote.RTVCompleted = false
            SolidMapVote.startVoteAfterRound = false
        end

        zb.EndRTV = function() end
        zb.ThinkRTV = function() end
        zb.RTVMenu = function() end

        if COMMANDS then
            COMMANDS.rtv = nil
            COMMANDS.forcertv = nil
            COMMANDS.who = nil
            COMMANDS["кем"] = nil
        end
    end

    hook.Add("PostGamemodeLoaded", "SolidMapVote_OverrideZCity", OverrideZCityVoteSystem)
    hook.Add("InitPostEntity", "SolidMapVote_OverrideZCity", OverrideZCityVoteSystem)
end

print("[SolidMapVote] Loaded successfully!")

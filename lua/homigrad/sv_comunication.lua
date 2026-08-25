local chat_dist_normal = 3000
local chat_dist_whisper = 100
local voice_dist_normal = 2000
local voice_occlusion_cache_time = 0.2
local voice_dist_partial = 1700
local voice_dist_indirect = 1400
local voice_dist_wall = 850
local voice_dist_floor = 500
local voice_dist_multiple = 350
local voice_up = Vector(0, 0, 1)
local voice_chest_offset = Vector(0, 0, 12)

local voice_occlusion_cache = setmetatable({}, {__mode = "k"})

local function VoiceTraceFilter(ent)
	if ent:IsPlayer() or ent:IsRagdoll() then return false end

	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then return false end

	local parent = ent:GetParent()
	if IsValid(parent) and parent:IsPlayer() then return false end

	return true
end

local function GetVoicePairCache(listener, speaker)
	local first, second = listener, speaker
	if listener:EntIndex() > speaker:EntIndex() then
		first, second = speaker, listener
	end

	local pairs = voice_occlusion_cache[first]
	if not pairs then
		pairs = setmetatable({}, {__mode = "k"})
		voice_occlusion_cache[first] = pairs
	end

	return pairs, second
end

local function TraceVoicePath(traceData, startPos, endPos)
	traceData.start = startPos
	traceData.endpos = endPos

	return util.TraceLine(traceData)
end

local function ClassifyVoicePath(listener, speaker)
	local listenerHead = listener:EyePos()
	local speakerHead = speaker:EyePos()
	local listenerChest = listener:WorldSpaceCenter() + voice_chest_offset
	local speakerChest = speaker:WorldSpaceCenter() + voice_chest_offset
	local directDistance = speakerHead:Distance(listenerHead)
	local traceData = {
		mask = MASK_SOLID,
		filter = VoiceTraceFilter
	}
	local directTrace = TraceVoicePath(traceData, speakerHead, listenerHead)
	if not directTrace.Hit then return "clear", directDistance end
	if not TraceVoicePath(traceData, speakerChest, listenerHead).Hit then return "partial", directDistance end
	if not TraceVoicePath(traceData, speakerHead, listenerChest).Hit then return "partial", directDistance end

	local hitNormal = directTrace.HitNormal
	local tangent = hitNormal:Cross(voice_up)
	if tangent:LengthSqr() < 0.01 then
		local path = listenerHead - speakerHead
		tangent = Vector(-path.y, path.x, 0)
		if tangent:LengthSqr() < 0.01 then
			tangent = speaker:GetRight()
			tangent.z = 0
		end
	end

	if tangent:LengthSqr() >= 0.01 then
		tangent:Normalize()
		local bendOffset = math.Clamp(directDistance * 0.18, 72, 180)
		local shortestPath

		for direction = -1, 1, 2 do
			local bend = directTrace.HitPos + tangent * bendOffset * direction + hitNormal * 6
			if not TraceVoicePath(traceData, speakerHead, bend).Hit and not TraceVoicePath(traceData, bend, listenerHead).Hit then
				local pathDistance = speakerHead:Distance(bend) + bend:Distance(listenerHead)
				if pathDistance <= directDistance * 1.35 and (not shortestPath or pathDistance < shortestPath) then
					shortestPath = pathDistance
				end
			end
		end

		if shortestPath then return "indirect", shortestPath end
	end

	local reverse = TraceVoicePath(traceData, listenerHead, speakerHead)
	local path = listenerHead - speakerHead
	local verticalRatio = directDistance > 0 and math.abs(path.z) / directDistance or 0
	local blockedSpan = reverse.Hit and directTrace.HitPos:Distance(reverse.HitPos) or 0
	local sameBlocker = reverse.Hit and directTrace.Entity == reverse.Entity

	if verticalRatio >= 0.4 then return "floor", directDistance end
	if reverse.Hit and (blockedSpan > 96 or not sameBlocker) then return "multiple", directDistance end

	return "wall", directDistance
end

local function GetVoiceAcousticRange(listener, speaker)
	local pairs, key = GetVoicePairCache(listener, speaker)
	local cached = pairs[key]
	local now = CurTime()
	if cached and cached.expires > now then return cached.range, cached.pathDistance end

	local classification, pathDistance = ClassifyVoicePath(listener, speaker)
	local allowedDistance = classification == "clear" and voice_dist_normal
		or classification == "partial" and voice_dist_partial
		or classification == "indirect" and voice_dist_indirect
		or classification == "floor" and voice_dist_floor
		or classification == "multiple" and voice_dist_multiple
		or voice_dist_wall

	pairs[key] = {
		expires = now + voice_occlusion_cache_time,
		range = allowedDistance,
		pathDistance = pathDistance
	}

	return allowedDistance, pathDistance
end

--\\Whisper
	util.AddNetworkString("ChatWhisper")
	
	net.Receive("ChatWhisper", function(len, ply)
		ply.ChatWhisper = net.ReadBool()
	end)
--

local function ChatLogic(output, input, isChat, teamonly, text, skipOverrides)

	if not IsValid(output) then return true, true end
	if not IsValid(input) then return false end
	if not skipOverrides then
		local result, is3D = hook.Run("CanListenOthers",output,input,isChat,teamonly,text)
		if result ~= nil then return result,is3D end
	end

	local chat_dist = isChat and chat_dist_normal or voice_dist_normal

	if(IsValid(output) and output.ChatWhisper)then
		chat_dist = chat_dist_whisper
	end

	local outputOrganism = output.organism
	local inputOrganism = input.organism
	local outputOxygen = outputOrganism and outputOrganism.o2
	local canSpeakAlive = output:Alive()
		and input:Alive()
		and outputOrganism
		and inputOrganism
		and istable(outputOxygen)
		and not outputOrganism.otrub
		and not inputOrganism.otrub
		and (tonumber(outputOxygen[1]) or 0) >= 15
		and not outputOrganism.holdingbreath
		and input:TestPVS(output)

	if canSpeakAlive then
		local distance = input:GetPos():Distance(output:GetPos())
		if teamonly or distance >= chat_dist then return false end
		if not isChat then
			local acousticRange, acousticDistance = GetVoiceAcousticRange(input, output)
			if acousticDistance >= acousticRange then return false end
		end

		return true, true
	elseif not output:Alive() and not input:Alive() then
		return true
	else
		if not input:Alive() and output:Alive() then
			if teamonly or not input:TestPVS(output) then return false end

			local distance = input:GetPos():Distance(output:GetPos())
			if distance >= chat_dist then return false end
			if not isChat then
				local acousticRange, acousticDistance = GetVoiceAcousticRange(input, output)
				if acousticDistance >= acousticRange then return false end
			end

			return true, true
		end
		if not output:Alive() and input:Team() == 1002 and input:Alive() then return true end

		return false
	end
end

function hg.CanHearLocalProximityVoice(listener, speaker)
	local canHear, is3D = ChatLogic(speaker, listener, false, false, nil, true)
	return canHear == true, is3D
end

hook.Add("PlayerCanSeePlayersChat", "RealiticChar", function(text, teamOnly, listener, speaker)
	if not IsValid(speaker) then return end
    local result = ChatLogic(speaker,listener,true,false,text)

    if not IsValid(speaker) then speaker = Entity(0) end

	local Hook = hook.Run("HG_PlayerCanSeePlayersChat", listener, speaker )
	if Hook then
		return Hook
	end

    return result
end)

local function funca(ply, txt)
	if !ply:Alive() or !ply.organism then return end
	local starttxt = txt

	if ply.organism.pain > 80 then
		txt = table.Random(hg.sharp_pain)
	end

	local bJawBroken = ply.organism.jaw == 1 or ply.organism.jawdislocation
	local bUnintelligeble = ply.organism.brain > 0.05
	local bHasMassiveBrainDamage = ply.organism.brain > 0.14

	txt = utf8.force(txt)

	if bJawBroken then
		local iter = utf8.codes(txt)
		local len = 0
		local chars = {}
		local minus = utf8.codepoint("-", 1, 1)
		for i, code in iter do
			if math.random(3) == 1 then -- max dist 640
				code = minus
			end

			len = len + 1
			chars[len] = utf8.char(code)
		end
		txt = table.concat(chars)
	end
	
	if bUnintelligeble then
		local iter = utf8.codes(txt)
		local len = 0
		local chars = {}

		for i, code in iter do
			len = len + 1
			chars[len] = utf8.char(code)
		end

		for i, code in ipairs(chars) do
			if i > 1 and math.random(bHasMassiveBrainDamage and 2 or 3) == 1 then
				local old = chars[i]
				chars[i] = chars[i - 1]
				chars[i - 1] = old
			end

			if bHasMassiveBrainDamage then
				if math.random(3) == 1 then
					chars[i] = math.random(1, 2) == 1 and "m" or "b"
				end
			end
		end

		txt = table.concat(chars)

		if bHasMassiveBrainDamage and math.random(2) == 1 then txt = hg.utf8_reverse(utf8.codes(txt), utf8.len(txt)) end
	end

	if ply.organism.o2[1] < 15 or (ply.organism.brain > 0.15 and math.random(4) == 1) then return "..." end

	return txt
end

local hg_furcity = ConVarExists("hg_furcity") and GetConVar("hg_furcity") or CreateConVar("hg_furcity", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_LUA_SERVER), "Toggle phrase furryfier :3", 0, 1)

hook.Add("HG_PlayerSay", "huy", function(ply, txt)
	local text = txt[1]

	txt[1] = funca(ply, text)
end)

hook.Add("HG_PlayerSay", "furrifyPhraseOwO", function(ply, txt)
	local text = txt[1]
	
	if hg_furcity:GetBool() or ply.PlayerClassName == "furry" then
		text = hg.FurrifyPhrase(text)
	end

	txt[1] = text
end)

hook.Add("HG_PlayerCanHearPlayersVoice","BrainDamage", function(listener, speaker)
	local organism = speaker.organism
	if organism and (tonumber(organism.brain) or 0) > 0.05 then return false, false end
end, -1)

local braindeadphrase_male = {
	"vo/episode_1/npc/male01/cit_behindyousfx01.wav",
	"vo/episode_1/npc/male01/cit_behindyousfx02.wav",
}
local braindeadphrase_female = {
	"vo/episode_1/npc/female01/cit_behindyousfx01.wav",
	"vo/episode_1/npc/female01/cit_behindyousfx02.wav",
}
hook.Add("HG_ReplacePhrase", "BraindeadPhrase", function(ply, phrase, muffed, pitch)
	if IsValid(ply) and ply.organism and ply.organism.brain >= 0.5 then
		local phr = ThatPlyIsFemale(ply) and braindeadphrase_female[math.random(#braindeadphrase_female)] or braindeadphrase_male[math.random(#braindeadphrase_male)]
		return ply, phr, muffed, pitch
	end
end)

hook.Add("PlayerCanHearPlayersVoice", "RealisticVoice", function(listener,speaker)
	local speak = speaker:IsSpeaking()
	speaker.IsSpeak = speak

	if speak and hg.AdminVoicePanelMarkSpeaking then
		hg.AdminVoicePanelMarkSpeaking(speaker)
	end
	
	if speaker.IsOldSpeak ~= speaker.IsSpeak then
		speaker.IsOldSpeak = speak
		--print("huy")
		if speak then hook.Run( "StartVoice", speaker, listener ) else hook.Run( "EndVoice", speaker, listener )  end
	end

	local canHear, is3D = hook.Run("HG_PlayerCanHearPlayersVoice", listener, speaker)
	if canHear ~= nil then
		return canHear, is3D
	end

	local result,is3D = ChatLogic(speaker,listener,false,false)
	return result,is3D
end, 1)

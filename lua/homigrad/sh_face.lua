local expressions = {
	Smile = {right_corner_puller = 0.7, left_corner_puller = 0.7},
	["Wide Smile"] = {right_corner_puller = 1, left_corner_puller = 1, right_part = 1, left_part = 1, jaw_drop = 0.4},
	Butcher = {right_corner_puller = 0.7, left_corner_puller = 0.7, right_lid_closer = 1, left_lid_closer = 1},
	Sad = {right_corner_depressor = 1, left_corner_depressor = 1, right_inner_raiser = 0.8, left_inner_raiser = 0.8},
	Pain = {
		right_upper_raiser = 1, left_upper_raiser = 1,
		right_lowerer = 1, left_lowerer = 1,
		right_corner_depressor = 0.7, left_corner_depressor = 0.7,
		right_part = 1, left_part = 1,
		right_lid_closer = 1, left_lid_closer = 1,
		jaw_drop = 0.5
	},
	Sleep = {right_lid_closer = 1, left_lid_closer = 1},
}

local faceOrder = {"Smile", "Wide Smile", "Butcher", "Sad", "Pain", "Sleep"}
local mouthFlex = {jaw_drop = true, left_part = true, right_part = true}
local allFlexes = {}
for _, flexes in pairs(expressions) do
	for name in pairs(flexes) do
		allFlexes[name] = true
	end
end

if SERVER then
	util.AddNetworkString("HG_SetFace")

	net.Receive("HG_SetFace", function(_, ply)
		if not IsValid(ply) or not ply:Alive() then return end

		local name = net.ReadString()
		if name ~= "" and not expressions[name] then return end
		ply:SetNetVar("Face", name)
	end)

	hook.Add("PlayerDeath", "HG_FaceClear", function(ply) ply:SetNetVar("Face", "") end)
	hook.Add("PlayerSpawn", "HG_FaceClear", function(ply) ply:SetNetVar("Face", "") end)
end

if CLIENT then
	local function applyFace(ply, ent)
		if not IsValid(ent) or not ent.GetFlexIDByName then return end

		local face = expressions[ply:GetNetVar("Face", "")]
		for flexName in pairs(allFlexes) do
			local id = ent:GetFlexIDByName(flexName)
			if not id then continue end

			local target = face and face[flexName]
			if target then
				if mouthFlex[flexName] then
					ent:SetFlexWeight(id, math.max(ent:GetFlexWeight(id), target))
				else
					ent:SetFlexWeight(id, target)
				end
			elseif not mouthFlex[flexName] then
				ent:SetFlexWeight(id, 0)
			end
		end
	end

	hook.Add("PreDrawOpaqueRenderables", "HG_Face", function()
		local viewer = LocalPlayer()
		if not IsValid(viewer) then return end

		local viewPos = viewer:GetPos()
		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end

			local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
			if viewPos:DistToSqr(ent:GetPos()) > 1500 * 1500 then continue end
			applyFace(ply, ent)
		end
	end)

	hook.Add("radialOptions", "HG_Face", function()
		local ply = lply or LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		if ply.organism and ply.organism.otrub then return end

		hg.radialOptions[#hg.radialOptions + 1] = {
			function()
				local tbl = {}
				for i = 1, #faceOrder do
					local name = faceOrder[i]
					tbl[i] = {
						function()
							net.Start("HG_SetFace")
							net.WriteString(name)
							net.SendToServer()
						end,
						name
					}
				end
				tbl[#tbl + 1] = {
					function()
						net.Start("HG_SetFace")
						net.WriteString("")
						net.SendToServer()
					end,
					"Reset Face"
				}
				hg.CreateRadialMenu(tbl)
			end,
			"Face\nRMB - Menu"
		}
	end)
end

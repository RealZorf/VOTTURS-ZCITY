local MODE = MODE

net.Receive("theboys_start", function()
    zb.RemoveFade()
end)

net.Receive("theboys_hunt_begin", function()
    surface.PlaySound("ambient/alarms/warningbell1.wav")
end)

hook.Add("PrePlayerDraw", "TheBoysHideHomelander", function(ply)
    if ply == LocalPlayer() then return end
    if ply:GetNWBool("TheBoysHidden") then return true end
end)

local roleColors = {
    homelander = Color(255, 215, 0),
    hider = Color(0, 120, 190)
}

function MODE:RenderScreenspaceEffects()
    local ply = LocalPlayer()
    local isHomelander = IsValid(ply) and (ply.PlayerClassName == "homelander" or ply:GetNWBool("IsHomelander"))
    local roundStart = zb.ROUND_START or 0

    local fade
    if isHomelander then
        local huntStart = roundStart + self.HideTime
        if CurTime() >= huntStart + 1 then return end
        fade = CurTime() < huntStart and 1 or math.Clamp(huntStart + 1 - CurTime(), 0, 1)
    else
        if roundStart + 7.5 < CurTime() then return end
        fade = math.Clamp(roundStart + 7.5 - CurTime(), 0, 1)
    end

    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local isHomelander = ply.PlayerClassName == "homelander" or ply:GetNWBool("IsHomelander")
    local huntStart = (zb.ROUND_START or 0) + self.HideTime
    local huntEnd = huntStart + GetGlobalFloat("TheBoysHuntTime", self.HuntTime)

    if CurTime() < huntStart then
        local left = huntStart - CurTime()
        local txt = isHomelander
            and ("You arrive in " .. string.FormattedTime(left, "%02i:%02i"))
            or ("Hide! Homelander arrives in " .. string.FormattedTime(left, "%02i:%02i"))
        draw.SimpleText(txt, "ZB_HomicideMedium", sw * 0.5, sh * 0.05, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif CurTime() < huntEnd then
        local left = huntEnd - CurTime()
        local txt = isHomelander
            and ("Kill everyone - " .. string.FormattedTime(left, "%02i:%02i"))
            or ("Survive - " .. string.FormattedTime(left, "%02i:%02i"))
        draw.SimpleText(txt, "ZB_HomicideMedium", sw * 0.5, sh * 0.05, Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if zb.ROUND_START + 8.5 < CurTime() then return end
    if not lply:Alive() then return end
    zb.RemoveFade()

    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

    draw.SimpleText("THE BOYS", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(255, 215, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local roleName, roleColor, objective
    if isHomelander then
        roleName = "Homelander"
        roleColor = Color(roleColors.homelander.r, roleColors.homelander.g, roleColors.homelander.b, 255 * fade)
        objective = "You are invincible. Kill every hider before time runs out."
    else
        roleName = "a Hider"
        roleColor = Color(roleColors.hider.r, roleColors.hider.g, roleColors.hider.b, 255 * fade)
        objective = "Hide. Survive. Your flashbang is the only thing that can buy you time."
    end

    draw.SimpleText("You are " .. roleName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local CreateEndMenu

net.Receive("theboys_end", function()
    local winnerSide = net.ReadUInt(2)
    local home = net.ReadEntity()
    CreateEndMenu(winnerSide, home)
end)

local colGray = Color(85, 85, 85, 255)
local colHome = Color(180, 140, 0)
local colHomeUp = Color(220, 175, 0)
local colHider = Color(10, 60, 160)
local colHiderUp = Color(40, 90, 200)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local col = Color(255, 255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function(winnerSide, home)
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end

    hmcdEndMenu = vgui.Create("ZFrame")
    surface.PlaySound("ambient/alarms/warningbell1.wav")

    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

    hmcdEndMenu:SetPos(posX, posY)
    hmcdEndMenu:SetSize(sizeX, sizeY)
    hmcdEndMenu:MakePopup()
    hmcdEndMenu:SetKeyboardInputEnabled(false)
    hmcdEndMenu:ShowCloseButton(false)

    local closebutton = vgui.Create("DButton", hmcdEndMenu)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function()
        if IsValid(hmcdEndMenu) then
            hmcdEndMenu:Close()
            hmcdEndMenu = nil
        end
    end
    closebutton.Paint = function(self, w, h)
        surface.SetDrawColor(122, 122, 122, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lengthX = surface.GetTextSize("Close")
        surface.SetTextPos(lengthX - lengthX / 1.1, 4)
        surface.DrawText("Close")
    end

    hmcdEndMenu.Paint = function(self, w, h)
        BlurBackground(self)

        local headline
        if winnerSide == 0 then
            headline = "Homelander wins" .. (IsValid(home) and (": " .. home:Nick()) or "")
        else
            headline = "The Hiders survived"
        end

        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lengthX = surface.GetTextSize(headline)
        surface.SetTextPos(w / 2 - lengthX / 2, 20)
        surface.DrawText(headline)

        surface.SetDrawColor(255, 215, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
    function DScrollPanel:Paint(w, h)
        BlurBackground(self)
        surface.SetDrawColor(255, 215, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100, 50)
        but:Dock(TOP)
        but:DockMargin(8, 6, 8, -1)
        but:SetText("")
        but.Paint = function(self, w, h)
            local isHome = ply.PlayerClassName == "homelander" or ply:GetNWBool("IsHomelander")
            local col1 = isHome and colHome or (ply:Alive() and colHider or colGray)
            local col2 = isHome and colHomeUp or (ply:Alive() and colHiderUp or colSpect1)

            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)

            local plyCol = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local _, lengthY = surface.GetTextSize(ply:GetPlayerName() or "?")

            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
            surface.DrawText(ply:GetPlayerName() or "?")

            surface.SetTextColor(plyCol.r, plyCol.g, plyCol.b, plyCol.a)
            surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
            surface.DrawText(ply:GetPlayerName() or "?")

            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            local label = ply:Name() .. (isHome and " - Homelander" or (not ply:Alive() and " - died" or ""))
            surface.SetTextPos(15, h / 2 - lengthY / 2)
            surface.DrawText(label)

            local fragsTxt = tostring(ply:Frags() or 0)
            local fragLen = surface.GetTextSize(fragsTxt)
            surface.SetTextPos(w - fragLen - 15, h / 2 - lengthY / 2)
            surface.DrawText(fragsTxt)
        end
        function but:DoClick()
            if ply:IsBot() then chat.AddText(Color(255, 0, 0), "no, you can't") return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end
        DScrollPanel:AddItem(but)
    end
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end

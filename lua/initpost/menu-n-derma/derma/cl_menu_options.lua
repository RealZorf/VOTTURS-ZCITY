hg.settings = hg.settings or {}
hg.settings.tbl = {}
hg.settings.categoryOrder = {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category, strHelp )
    if not self.tbl[strCategory] then
        self.tbl[strCategory] = {}
        self.categoryOrder[#self.categoryOrder + 1] = strCategory
    end

    for _, data in ipairs(self.tbl[strCategory]) do
        if data[2] == strConVar then
            return
        end
    end

    self.tbl[strCategory][#self.tbl[strCategory] + 1] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category, strHelp }
end
local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "Toggle first-person death camera view", 0, 1)
local hg_font = CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")
local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "distance to draw attachments", 0, 4096)
xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local sw, sh = ScrW(), ScrH()

local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZCity_setiings_tiny", {
	font = font(),
	size = ScreenScale(7),
	weight = 100
})

surface.CreateFont("ZCity_setiings_fine", {
	font = font(),
	size = ScreenScale(10),
	weight = 100
})

surface.CreateFont("ZCity_setiings_category", {
	font = font(),
	size = ScreenScale(15),
	weight = 100
})


hg.settings:AddOpt("Gameplay", "hg_showthoughts", "Character thoughts", nil, nil, nil, "Show pain and status thoughts from your character")
hg.settings:AddOpt("Gameplay", "hg_hints", "Object hints", nil, nil, nil, "Show interaction hints when you look at usable objects")
hg.settings:AddOpt("Gameplay", "hg_old_notificate", "Old notifications", nil, nil, nil, "Unused. Was meant to print damage notices in chat")
hg.settings:AddOpt("Gameplay", "hg_deathfadeout", "Death fade", nil, nil, nil, "Fade the screen and mute sound when you die")
hg.settings:AddOpt("Gameplay", "hg_gary", "Center gun when downed", nil, nil, nil, "When ragdolled, keep the gun pointed with your head")
hg.settings:AddOpt("Gameplay", "hg_cheats", "Invert mouse and strafe", nil, nil, nil, "Flips look-left/right and A/D movement")
hg.settings:AddOpt("Gameplay", "hg_wos_animmenus", "Emote menu", nil, nil, nil, "Adds emotes to the radial menu. Press F3 to pick which ones")

hg.settings:AddOpt("View", "hg_fov", "Field of view", nil, nil, nil, "How wide your view is while not aiming")
hg.settings:AddOpt("View", "hg_nofovzoom", "Disable aiming zoom", nil, nil, nil, "Stop the camera from zooming in when you aim")
hg.settings:AddOpt("View", "hg_leancam_mul", "Lean tilt", true, nil, "int", "How much the camera tilts when you lean")
hg.settings:AddOpt("View", "hg_firstperson_death", "First-person death", nil, nil, nil, "Stay in first person on your body after you die")
hg.settings:AddOpt("View", "hg_newspectate", "Smooth spectate", nil, nil, nil, "Smoothly blend the camera when switching players")
hg.settings:AddOpt("View", "hg_newfakecam", "New downed camera", nil, nil, nil, "Unused. The new downed camera code is turned off")
hg.settings:AddOpt("View", "hg_cshs_fake", "Locked downed camera", nil, nil, nil, "Lock the camera to your head while down instead of free-look")
hg.settings:AddOpt("View", "hg_gopro", "Head camera", nil, nil, nil, "Put the camera on your head. Also changes footsteps and gun sound")
hg.settings:AddOpt("View", "hg_realismcam", "Weapon camera lag", nil, nil, nil, "Camera lags with the gun. Can feel nauseating")
hg.settings:AddOpt("View", "hg_gun_cam", "Gun camera (admin)", nil, nil, nil, "Put the camera on the gun. Admins only")

hg.settings:AddOpt("Weapons", "hg_dynamic_mags", "Auto ammo HUD", nil, nil, nil, "Show remaining ammo after you shoot when the mag is low")
hg.settings:AddOpt("Weapons", "hg_zoomsensitivity", "Aiming mouse speed", nil, nil, nil, "Mouse speed while aiming. Lower is slower")
hg.settings:AddOpt("Weapons", "hg_weaponshotblur_enable", "Shot blur", nil, nil, nil, "Blur the screen when you fire")
hg.settings:AddOpt("Weapons", "hg_highpitchgunfire", "Indoor gunshots", nil, nil, nil, "Add extra indoor echo when shooting inside")

hg.settings:AddOpt("UI", "hg_font", "HUD font", false, true, nil, "Font name used by HUD text")
hg.settings:AddOpt("UI", "mzb_MoodleHud_enabled", "Status icons", nil, nil, "bool", "Show status icons like pain and bleeding")
hg.settings:AddOpt("UI", "zb_spectator_esp", "Spectator names", nil, nil, "bool", "Show player names through walls only while you are dead")
hg.settings:AddOpt("UI", "zb_esp_show_outlines", "Player outlines", nil, nil, "bool", "Draw a colored outline around players")
hg.settings:AddOpt("UI", "zb_esp_outline_limit", "Max outlines (0 = all)", true, nil, "int", "How many player outlines can draw at once")
hg.settings:AddOpt("UI", "zb_esp_range_limit", "Outline range (0 = all)", true, nil, "int", "How far away outlines still draw, in meters")

hg.settings:AddOpt("Sound", "hg_dmusic", "Dynamic music", nil, nil, nil, "Play mood music. GMod music volume must be on")
hg.settings:AddOpt("Sound", "hg_quietshots", "Quieter gunshots", nil, nil, nil, "Play each gunshot once instead of stacking extra copies")

hg.settings:AddOpt("Blood", "hg_blood_draw_distance", "Blood draw range", nil, nil, nil, "How far away blood still draws")
hg.settings:AddOpt("Blood", "hg_blood_fps", "Blood update rate", nil, nil, nil, "How often blood updates. Lower is cheaper")
hg.settings:AddOpt("Blood", "hg_old_blood", "Old blood splats", nil, nil, nil, "Use the old blood textures on walls")
hg.settings:AddOpt("Blood", "hg_blood_sprites", "Sprite blood", nil, nil, nil, "Unused. Does not change blood right now")

hg.settings:AddOpt("Optimization", "hg_potatopc", "Lighter effects", nil, nil, nil, "Turns off extra blur and shell effects. Does not change GMod graphics")
hg.settings:AddOpt("Optimization", "hg_low_graphics", "Low graphics", nil, nil, nil, "Lowers shadows, details, and effects. Restores them when off. Can freeze")
hg.settings:AddOpt("Optimization", "hg_multicore", "Multicore rendering", nil, nil, nil, "Uses extra CPU threads for rendering. Can crash")
hg.settings:AddOpt("Optimization", "hg_anims_draw_distance", "Body animation range", true, nil, "int", "How far you see other players' body animations. 0 = unlimited")
hg.settings:AddOpt("Optimization", "hg_anim_fps", "Body animation FPS", nil, nil, "int", "How often other players' bodies update. Not your gun. 0 = unlimited")
hg.settings:AddOpt("Optimization", "hg_attachment_draw_distance", "Attachment range", true, nil, "int", "How far you see sights, grips, and other attachments")
hg.settings:AddOpt("Optimization", "hg_tpik_distance", "Gun arm range", true, nil, "int", "How far you see other players holding guns with animated arms")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_near_fps", "Close arm FPS", nil, nil, "int", "How often nearby gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_mid_fps", "Mid arm FPS", nil, nil, "int", "How often mid-range gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_far_fps", "Far arm FPS", nil, nil, "int", "How often distant gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_near_distance", "Close arm range", nil, nil, "int", "Distance where close arm FPS switches to mid")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_mid_distance", "Mid arm range", nil, nil, "int", "Distance where mid arm FPS switches to far")
hg.settings:AddOpt("Optimization", "hg_maxsmoketrails", "Max smoke trails", nil, nil, "int", "How many gun smoke trails can exist at once. High values lag")
hg.settings:AddOpt("Optimization", "hg_player_occlusion", "Hide players behind walls", nil, nil, nil, "Skip drawing players you cannot see")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_full", "Hide gear behind walls", nil, nil, nil, "Also hide their gun, armor, and arms. Needs the option above")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_checks", "Wall checks per frame", nil, nil, "int", "How many players are wall-checked each frame")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_delay", "Wall check delay", true, nil, "int", "Seconds between checks on the same player. Higher uses less CPU")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_hide_delay", "Hide delay", true, nil, "int", "Seconds they must stay behind a wall before hiding. Stops flicker")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_side", "Side peek check", true, nil, "int", "How far to check left and right so peeking players stay visible")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_top", "Head peek check", true, nil, "int", "How far to check above the head so only-head peeks stay visible")

if not game.IsDedicated() then
	hg.settings:AddOpt("Server", "hg_thirdperson", "Third person", nil, nil, nil, "Server-wide third-person camera. Unfinished")
	hg.settings:AddOpt("Server", "hg_legacycam", "Legacy camera", nil, nil, nil, "Use the old first-person camera if third person is on")
	hg.settings:AddOpt("Server", "hg_ragdollcombat", "Ragdoll combat", nil, nil, nil, "Let people walk and fight while ragdolled")
	hg.settings:AddOpt("Server", "hg_healanims", "Heal animations", nil, nil, nil, "Play animations when using meds or food")
	hg.settings:AddOpt("Server", "hg_aimtoshoot", "Aim to shoot", nil, nil, nil, "Guns only fire while aiming")
	hg.settings:AddOpt("Server", "hg_slings", "Weapon slings", nil, nil, nil, "Show unused guns slung on the body")
	hg.settings:AddOpt("Server", "hg_movement_stamina_debuff", "Tired speed floor", true, nil, "int", "Slowest you can move when stamina is low. 1 = no slowdown")
	hg.settings:AddOpt("Server", "hg_toughnpcs", "Tougher NPCs", nil, nil, nil, "Give NPCs more health")
	hg.settings:AddOpt("Server", "hg_furcity", "Furry chat", nil, nil, nil, "Rewrite chat and thoughts in furry speak")
	hg.settings:AddOpt("Server", "hg_appearance_access_for_all", "Free appearance items", nil, nil, "bool", "Let everyone use all appearance items, not just unlocked ones")
	hg.settings:AddOpt("Server", "homicide_traitoramount", "Homicide traitors", nil, nil, "int", "How many traitors spawn in Homicide")
end

hg.settings:AddOpt("Debug", "hg_show_hitbox", "Show hitboxes", nil, nil, nil, "Draw player hitboxes. Admins or sv_cheats 1")
hg.settings:AddOpt("Debug", "hg_show_hitposmuzzle", "Show muzzle point", nil, nil, nil, "Draw where the gun is aiming. Admins or sv_cheats 1")
hg.settings:AddOpt("Debug", "hg_setzoompos", "Edit aim zoom", nil, nil, nil, "Superadmin only. Hold RMB to move iron-sight zoom and print values")


function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide() / 1.05, ParentPanel:GetTall() * 0.07)
    pppanel:SetPos(ParentPanel:GetWide() / 2 -pppanel:GetWide() / 2, yPos)
    --pppanel:SetText(ctgName)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(60,60,60,145)
        surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(42, 42, 42, 184)
		surface.DrawRect(0, h-5, w, 5)
    
        draw.SimpleText(ctgName, 'ZCity_setiings_category', w / 2, h / 2, color3, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    return pppanel
end

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) and math.floor(stringv) == floatVal then
        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

local clr_1 = Color(255,255,255,104)
local clr_2 = Color(122,122,122,104)
local clr_3 = Color(28,28,28)
local clr_4 = Color(0, 0, 0, 30)
local clr_5 = Color(30, 29, 29, 30)
local clr_6 = Color(255, 255, 255, 100)
local clr_7 = Color(255, 255, 255, 200)
local clr_8 = Color(35, 225, 110)
local clr_entry_bg = Color(255, 255, 255, 245)
local clr_entry_border = Color(35, 225, 110, 255)
local clr_entry_text = Color(12, 18, 28, 255)
function hg.CreateButton(buttonData, convarName, ParentPanel, yPos)
    local convar = GetConVar(convarName)

    if not convar then 
        return 
    end
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide()/1.05, ParentPanel:GetTall()/15)
    pppanel:SetPos(ParentPanel:GetWide()/2-pppanel:GetWide()/2, yPos)
    
    surface.SetFont('ZCity_setiings_fine')
    local width2, height2 = surface.GetTextSize(buttonData[3])
    
    convarType = buttonData[6] or hg.GetConVarType(convar)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(43, 43, 43,145)
        surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(47, 47, 47,145)
		surface.DrawRect(0, h-3, w, 3)
        
        draw.SimpleText(buttonData[3], 'ZCity_setiings_fine', 30, h / 2 -height2/2.5, clr_1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(buttonData[7] or convar:GetHelpText(), 'ZCity_setiings_tiny', 30, h / 2+height2/2, clr_2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if convarType == 'bool' then
        local toggle = vgui.Create('DButton', pppanel)
        toggle:SetSize(pppanel:GetWide() / 18, pppanel:GetTall() / 2)

        
        toggle:SetPos(pppanel:GetWide() - toggle:GetWide()*1.4 - pppanel:GetWide() / 20, pppanel:GetTall() / 2 - toggle:GetTall() / 2)
        toggle:SetText('')
        
        local animProgress = convar:GetBool() and 1 or 0
        local targetProgress = animProgress
        
        function toggle:Paint(w, h)
            if animProgress ~= targetProgress then
                animProgress = Lerp(FrameTime() * 8, animProgress, targetProgress)
            end
            
            local bgColor = Color(
                Lerp(animProgress, 180, 80),  
                Lerp(animProgress, 30, 120),  
                Lerp(animProgress, 30, 50)   
            )
            
            local shadowColor = Color(0, 0, 0, Lerp(animProgress, 150, 40))
            surface.SetDrawColor(clr_3)
            draw.RoundedBox(0, 0, 0, w, h, clr_3)
            
            surface.SetDrawColor(clr_5)
            draw.RoundedBox(0, 2, 2, w - 4, h - 4, clr_4)
            
            local slsize = h - 12
            local slPos = Lerp(animProgress, 6, w - slsize - 6)
            surface.SetDrawColor(bgColor)
            draw.RoundedBox(0, slPos, 6, slsize, slsize, bgColor)
            surface.SetDrawColor(shadowColor)
            surface.DrawRect(slPos, slsize+4, slsize, 3)
    
            surface.SetDrawColor(clr_6)
        end
        
        function toggle:DoClick()
            if convar then
                local newValue = not convar:GetBool()
                SetConVarValue(convar, newValue)

                surface.PlaySound('glide/headlights_on.wav')
                targetProgress = newValue and 1 or 0
            end
        end
        
    elseif convarType == 'int' then
        local slider = vgui.Create('DNumSlider', pppanel)
        slider:SetSize(280, 30)
        slider:SetPos(pppanel:GetWide() - 300, pppanel:GetTall() / 2 - 15)
        slider:SetText('')
        
        local min = convar:GetMin() or 0
        local max = convar:GetMax() or 100
        local decimals = buttonData[4] and 2 or 0
        
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals)
        slider:SetValue(decimals > 0 and convar:GetFloat() or convar:GetInt())
        
        function slider:OnValueChanged(val)
            if convar then
                SetConVarValue(convar, decimals > 0 and math.Round(val, decimals) or math.Round(val))
            end
        end
        
        local valueLabel = vgui.Create('DLabel', pppanel)
        valueLabel:SetPos(pppanel:GetWide() - 350, pppanel:GetTall() / 2 - 8)
        valueLabel:SetSize(50, 20)
        valueLabel:SetText(decimals > 0 and tostring(convar:GetFloat()) or tostring(convar:GetInt()))
        valueLabel:SetTextColor(clr_7)
        valueLabel:SetFont('ZCity_setiings_tiny')
        
        slider.Think = function()
            if convar then
                valueLabel:SetText(decimals > 0 and tostring(math.Round(convar:GetFloat(), decimals)) or tostring(convar:GetInt()))
            end
        end
        
    elseif convarType == 'string' then
        local textEntry = vgui.Create('DTextEntry', pppanel)
        textEntry:SetSize(pppanel:GetWide()/8, pppanel:GetTall()/2)
        textEntry:SetPos(pppanel:GetWide()-pppanel:GetWide()/8-20, pppanel:GetTall()/2-textEntry:GetTall()/2)
        textEntry:SetText(convar:GetString())
        textEntry:SetUpdateOnType(true) 
        textEntry:SetFont('ZCity_Tiny')
        
    
        textEntry.Paint = function(self, w, h)
            surface.SetDrawColor(clr_entry_bg)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(clr_entry_border)
            surface.DrawOutlinedRect(0, 0, w, h)
            
            self:DrawTextEntryText(clr_entry_text, clr_8, clr_entry_text)
        end
        
        function textEntry:OnValueChange(val)
            if convar then
                SetConVarValue(convar, val)
            end
        end
    end
    
    return pppanel
end

function hg.DrawSettings(ParentPanel)
    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self,w,h)

        surface.SetDrawColor(28,28,28,255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(107, 107, 107,20)

        for i = 1, (ybars + 1) do
            surface.DrawRect((sw / ybars) * i - (CurTime() * 30 % (sw / ybars)), 0, ScreenScale(1), sh)
        end

        for i = 1, (xbars + 1) do
            surface.DrawRect(0, (sh / xbars) * (i - 1) + (CurTime() * 30 % (sh / xbars)), sw, ScreenScale(1))
        end

        local border_size = ScreenScale(2)

        surface.SetDrawColor(0, 0, 0)
        surface.SetMaterial(gradient_l)
        surface.DrawTexturedRect(0, 0, border_size, sh)
		surface.SetMaterial(blur)
        surface.SetDrawColor(28,28,28,208)
        surface.DrawRect(0, 0, w, h)
    end
    hg.DrawBlur(ParentPanel, 5)
    ParentPanel:AlphaTo(255,0.15,0)
    local pppanel3 = vgui.Create('DScrollPanel', ParentPanel)
    pppanel3:SetSize(ParentPanel:GetWide(), ParentPanel:GetTall())
    pppanel3:SetPos(0,0)
    --pppanel3:SetAlpha(0)
    pppanel3.Paint = function()end
    --🥴 <- best emoticon

    local yOffset = pppanel3:GetTall()/100

    for _, categoryName in ipairs(hg.settings.categoryOrder) do
        local categoryTable = hg.settings.tbl[categoryName]
        local category = hg.CreateCategory(categoryName, pppanel3, yOffset)
        yOffset = yOffset + category:GetTall() + 12
        for _, settingData in ipairs(categoryTable) do
            local vbv = hg.CreateButton(settingData, settingData[2], pppanel3, yOffset)
            if not vbv then continue end
            yOffset = yOffset + (vbv:GetTall()) + 12
        end
    end
    local pppanel23 = vgui.Create('DPanel', pppanel3)
    pppanel23:SetSize(0, 0)
    pppanel23:SetPos(0,yOffset+12)
end

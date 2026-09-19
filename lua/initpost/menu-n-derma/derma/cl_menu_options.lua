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


hg.settings:AddOpt("Gameplay", "hg_showthoughts", "Character thoughts", nil, nil, nil, "Show thought text from your character")
hg.settings:AddOpt("Gameplay", "hg_hints", "Gameplay hints", nil, nil, nil, "Show tutorial-style hints on screen")
hg.settings:AddOpt("Gameplay", "hg_old_notificate", "Old notification style", nil, nil, nil, "Use the older popup notifications instead of the new ones")
hg.settings:AddOpt("Gameplay", "hg_deathfadeout", "Fade screen on death", nil, nil, nil, "Fade the screen to black when you die")
hg.settings:AddOpt("Gameplay", "hg_gary", "Gary mode", nil, nil, nil, "Replace player models with Gary")
hg.settings:AddOpt("Gameplay", "hg_cheats", "Client cheats", nil, nil, nil, "Allow client cheat commands where the server permits them")

hg.settings:AddOpt("View", "hg_fov", "Walking field of view", nil, nil, nil, "Your normal camera FOV while not aiming")
hg.settings:AddOpt("View", "hg_nofovzoom", "Aiming FOV zoom", nil, nil, nil, "Zoom the camera in when aiming down sights")
hg.settings:AddOpt("View", "hg_leancam_mul", "Lean camera amount", true, nil, "int", "How far the camera tilts when you lean")
hg.settings:AddOpt("View", "hg_firstperson_death", "Stay in first person on death", nil, nil, nil, "Keep your eyes on the body after you die")
hg.settings:AddOpt("View", "hg_newspectate", "Smooth spectator switching", nil, nil, nil, "Blend the camera when you jump between players you are spectating")
hg.settings:AddOpt("View", "hg_newfakecam", "New downed ragdoll camera", nil, nil, nil, "Newer camera that follows your ragdoll while you are down")
hg.settings:AddOpt("View", "hg_cshs_fake", "C'sHS downed ragdoll camera", nil, nil, nil, "Older C'sHS-style camera on your ragdoll while you are down")
hg.settings:AddOpt("View", "hg_gopro", "Helmet-mounted camera", nil, nil, nil, "Camera sits on the head like a GoPro, not at eye height")
hg.settings:AddOpt("View", "hg_realismcam", "Walking head-bob camera", nil, nil, nil, "Adds extra head bounce while you walk. Can feel nauseating")
hg.settings:AddOpt("View", "hg_gun_cam", "Weapon-mounted camera (admin)", nil, nil, nil, "Camera locked to the gun. Admin only")

hg.settings:AddOpt("Weapons", "hg_dynamic_mags", "Animated mag inspect", nil, nil, nil, "Play a mag animation when you check ammo")
hg.settings:AddOpt("Weapons", "hg_zoomsensitivity", "Scope mouse sensitivity", nil, nil, nil, "Mouse speed while looking through a scope")
hg.settings:AddOpt("Weapons", "hg_weaponshotblur_enable", "Recoil screen blur", nil, nil, nil, "Blur the screen when you fire")
hg.settings:AddOpt("Weapons", "hg_highpitchgunfire", "Higher-pitched indoor gunshots", nil, nil, nil, "Raise gunshot pitch when you are inside a building")

hg.settings:AddOpt("UI", "hg_font", "HUD font", false, true, nil, "Font used by Homigrad HUD text")
hg.settings:AddOpt("UI", "mzb_MoodleHud_enabled", "Status icons on the HUD", nil, nil, "bool", "Show moodle-style status icons (pain, bleeding, and so on)")
hg.settings:AddOpt("UI", "zb_spectator_esp", "Show players while spectating", nil, nil, "bool", "Draw player info through walls only while you are dead / spectating")
hg.settings:AddOpt("UI", "zb_esp_show_outlines", "Glow outline around players", nil, nil, "bool", "Draw a colored outline on players. Separate from spectator info")
hg.settings:AddOpt("UI", "zb_esp_outline_limit", "Max glow outlines (0 = unlimited)", true, nil, "int", "How many player outlines can draw at once")
hg.settings:AddOpt("UI", "zb_esp_range_limit", "Glow outline range (0 = unlimited)", true, nil, "int", "How far away outlines still draw, in meters")

hg.settings:AddOpt("Sound", "hg_dmusic", "Dynamic music", nil, nil, nil, "Play situation music. GMod music must also be enabled")
hg.settings:AddOpt("Sound", "hg_quietshots", "Quieter gunshots", nil, nil, nil, "Lower the volume of gunfire")

hg.settings:AddOpt("Blood", "hg_blood_draw_distance", "Blood particle range", nil, nil, nil, "How far away blood particles still render")
hg.settings:AddOpt("Blood", "hg_blood_fps", "Blood particle update rate", nil, nil, nil, "How often blood particles update. Lower is cheaper")
hg.settings:AddOpt("Blood", "hg_old_blood", "Old blood decals", nil, nil, nil, "Use the old blood splat textures on walls instead of the new ones")
hg.settings:AddOpt("Blood", "hg_blood_sprites", "Sprite blood (disabled)", nil, nil, nil, "Old sprite blood. Currently disabled for everyone")

hg.settings:AddOpt("Optimization", "hg_potatopc", "Lighter Homigrad effects", nil, nil, nil, "Turns off Homigrad extras: menu blur, suppression blur, extra shells. Does not change Source engine graphics")
hg.settings:AddOpt("Optimization", "hg_low_graphics", "Lowest Source graphics preset", nil, nil, nil, "Forces engine quality down (shadows, textures, sky, bloom) and also enables lighter Homigrad effects. Restores your old settings when off")
hg.settings:AddOpt("Optimization", "hg_multicore", "Extra CPU render threads", nil, nil, nil, "Lets GMod use more CPU threads for rendering. Can raise FPS, can also crash")
hg.settings:AddOpt("Optimization", "hg_anims_draw_distance", "Other players' body animation range", true, nil, "int", "How far away you still see other players' body/bone animations. 0 = unlimited. Not guns")
hg.settings:AddOpt("Optimization", "hg_anim_fps", "Other players' body animation FPS", nil, nil, "int", "How often other players' body animations update. Does not affect your first-person gun. 0 = uncapped")
hg.settings:AddOpt("Optimization", "hg_attachment_draw_distance", "Sights and attachments range", true, nil, "int", "How far away you still see sights, grips, and other attachments on guns")
hg.settings:AddOpt("Optimization", "hg_tpik_distance", "Other players' gun-in-hands range", true, nil, "int", "How far away you still see other people holding guns with animated arms (TPIK)")
hg.settings:AddOpt("Optimization", "hg_maxsmoketrails", "Max lingering gun smoke trails", nil, nil, "int", "How many smoke trails from guns can exist at once")
hg.settings:AddOpt("Optimization", "hg_player_occlusion", "Don't draw players behind walls", nil, nil, nil, "Hides the player model if they are behind the world. Nearby players stay visible")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_full", "Also hide their gear behind walls", nil, nil, nil, "When someone is hidden behind a wall, also hide their gun, armor, and third-person arms. Needs the option above")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_checks", "Players wall-checked per frame", nil, nil, "int", "How many players to test against walls each frame. Higher is more accurate, lower is cheaper")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_delay", "Wait between checks on one player", true, nil, "int", "Minimum seconds before the same player is wall-tested again. Higher saves FPS")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_hide_delay", "Wait before they disappear", true, nil, "int", "Seconds they must stay behind a wall before vanishing. Stops flickering around corners")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_side", "Trace width around their sides", true, nil, "int", "How far extra traces go left/right. Higher keeps people visible when they peek")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_top", "Trace height above their head", true, nil, "int", "How high extra traces go. Higher keeps people visible if only their head is showing")

if not game.IsDedicated() then
	hg.settings:AddOpt("Server", "hg_thirdperson", "Thirdperson (WIP)", nil, nil, nil, "Server thirdperson camera. Still unfinished")
	hg.settings:AddOpt("Server", "hg_legacycam", "Legacy camera", nil, nil, nil, "Use the older shared camera system")
	hg.settings:AddOpt("Server", "hg_ragdollcombat", "Ragdoll combat", nil, nil, nil, "Let people fight while ragdolled")
	hg.settings:AddOpt("Server", "hg_healanims", "Heal and eat animations", nil, nil, nil, "Play animations when using medical items or food")
	hg.settings:AddOpt("Server", "hg_aimtoshoot", "Must aim to shoot", nil, nil, nil, "Guns only fire while aiming, like DarkRP")
	hg.settings:AddOpt("Server", "hg_slings", "Weapon slings", nil, nil, nil, "Show slung weapons on the body")
	hg.settings:AddOpt("Server", "hg_movement_stamina_debuff", "Low stamina slows movement", nil, nil, nil, "Running speed drops when stamina is low")
	hg.settings:AddOpt("Server", "hg_toughnpcs", "Stronger NPCs", nil, nil, nil, "NPCs take more damage to kill")
	hg.settings:AddOpt("Server", "hg_furcity", "Furcity models", nil, nil, nil, "Enable Furcity player models")
	hg.settings:AddOpt("Server", "hg_appearance_access_for_all", "Anyone can change appearance", nil, nil, "bool", "Let every player use the full appearance menu")
	hg.settings:AddOpt("Server", "homicide_traitoramount", "Homicide traitor count", nil, nil, "int", "How many traitors spawn in Homicide")
end

hg.settings:AddOpt("Debug", "hg_show_hitbox", "Show hitboxes", nil, nil, nil, "Draw player hitboxes")
hg.settings:AddOpt("Debug", "hg_show_hitposmuzzle", "Show muzzle aim point", nil, nil, nil, "Draw where the gun's muzzle trace hits")
hg.settings:AddOpt("Debug", "hg_setzoompos", "Edit ads zoom position", nil, nil, nil, "Move iron-sight zoom position and print values to console")


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

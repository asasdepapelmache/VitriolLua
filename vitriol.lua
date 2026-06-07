-- Vitriol.lua by larihvh (State-Based AA + Exploits Update)

local TAB, CONTAINER = "LUA", "B"
local ffi = require("ffi")

local function get_refs(...) return { ui.reference(...) } end

local refs = {
    dt = get_refs("Rage", "Aimbot", "Double tap"),
    hs = get_refs("AA", "Other", "On shot anti-aim"),
    fd = get_refs("Rage", "Other", "Duck peek assist"),
    baim = get_refs("Rage", "Aimbot", "Force body aim"),
    sp = get_refs("Rage", "Aimbot", "Force safe point"),
    fs = get_refs("AA", "Anti-aimbot angles", "Freestanding"),
    dmg = get_refs("RAGE", "Aimbot", "Minimum damage"),
    ovr = get_refs("RAGE", "Aimbot", "Minimum damage override"),
    qpeek = get_refs("Rage", "Other", "Quick peek assist"),
    yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw_slider = select(2, ui.reference("AA", "Anti-aimbot angles", "Yaw")),
    yaw_jitter = get_refs("AA", "Anti-aimbot angles", "Yaw jitter"),
    body_yaw = get_refs("AA", "Anti-aimbot angles", "Body yaw"),
    fl_enabled = ui.reference("AA", "Fake lag", "Enabled"),
    fl_amount = ui.reference("AA", "Fake lag", "Amount"),
    fl_variance = ui.reference("AA", "Fake lag", "Variance"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit")
}

-- ==========================================
-- [ FFI - SPARKLES & SAFE AUDIO ]
-- ==========================================
ffi.cdef [[
    struct spark_vec3_t { float x, y, z; };
    typedef void(__fastcall*FX_ElectricSparkFn)(const struct spark_vec3_t*, int, int, const struct spark_vec3_t*);
]]

local FX_ElectricSpark
pcall(function()
    FX_ElectricSpark = ffi.cast("FX_ElectricSparkFn", client.find_signature("client.dll", "\x55\x8B\xEC\x83\xEC\x3C\x53\x8B\xD9\x89\x55\xFC\x8B\x0D\xCC\xCC\xCC\xCC\x56\x57"))
end)

local spark_material = nil
pcall(function()
    if materialsystem then
        spark_material = materialsystem.find_material("effects/spark", true)
    elseif materials then
        spark_material = materials.find("effects/spark")
    end
end)

local native_Surface_PlaySound
pcall(function()
    local surface = client.create_interface("vguimatsurface.dll", "VGUI_Surface031")
    local fnptr = ffi.cast("void(__thiscall*)(void*, const char*)", (ffi.cast("void***", surface)[0])[82])
    native_Surface_PlaySound = function(path) return fnptr(surface, path) end
end)

-- ==========================================
-- [ MENU UI ]
-- ==========================================
local m = {}
ui.new_label(TAB, CONTAINER, "====== [ Vitriol.lua ] ======")

-- Clantag
ui.new_label(TAB, CONTAINER, "--- Clantag ---")
m.clantag_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Vitriol.lua Clantag")
m.clantag_type = ui.new_combobox(TAB, CONTAINER, "Clantag Type", { "Animated", "Static", "Clock" })
m.clantag_timezone = ui.new_combobox(TAB, CONTAINER, "Clock Timezone", { "Brasília", "Amazonas" })
m.clantag_speed = ui.new_slider(TAB, CONTAINER, "Animation Speed", 1, 10, 3, true, "s", 0.1)
m.clantag_sync = ui.new_button(TAB, CONTAINER, "Sync Clantag", function() end)

-- Advanced Anti-Aim Builder
ui.new_label(TAB, CONTAINER, "--- Advanced Anti-Aim ---")
m.aa_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable State-Based AA & FL")
m.anti_brute = ui.new_checkbox(TAB, CONTAINER, "Enable Anti-Bruteforce (Auto-Flip)")
m.lc_breaker = ui.new_checkbox(TAB, CONTAINER, "Enable LC Breaker")

m.aa_state_edit = ui.new_combobox(TAB, CONTAINER, "Edit State", { "Stand", "Move", "Air", "Crouch" })

m.aa_settings = {}
local aa_states = { "Stand", "Move", "Air", "Crouch" }
for i=1, #aa_states do
    local st = aa_states[i]
    m.aa_settings[st] = {
        yaw = ui.new_slider(TAB, CONTAINER, "["..st.."] Yaw Add", -180, 180, 0),
        jitter_mode = ui.new_combobox(TAB, CONTAINER, "["..st.."] Jitter Mode", {"Off", "Offset", "Center", "Random"}),
        jitter_range = ui.new_slider(TAB, CONTAINER, "["..st.."] Jitter Range", -180, 180, 0),
        body_yaw = ui.new_combobox(TAB, CONTAINER, "["..st.."] Body Yaw", {"Off", "Opposite", "Jitter", "Static"}),
        desync = ui.new_slider(TAB, CONTAINER, "["..st.."] Desync Limit", -60, 60, 60),
        fl_limit = ui.new_slider(TAB, CONTAINER, "["..st.."] Fake Lag Limit", 1, 15, 14),
        fl_amount = ui.new_combobox(TAB, CONTAINER, "["..st.."] Fake Lag Amount", {"Dynamic", "Maximum", "Fluctuate"}),
        fl_variance = ui.new_slider(TAB, CONTAINER, "["..st.."] Fake Lag Variance", 0, 100, 0)
    }
end

-- Crosshair Indicators
ui.new_label(TAB, CONTAINER, "--- Indicators ---")
m.hud_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Crosshair HUD")
m.hud_style = ui.new_combobox(TAB, CONTAINER, "HUD Text Style", { "Normal", "Bold" })
m.hud_color = ui.new_color_picker(TAB, CONTAINER, "HUD Accent Color", 255, 105, 180, 255)

-- New ESP / Indicators
ui.new_label(TAB, CONTAINER, "--- Extra ESP ---")
m.manual_aa_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Manual AA Arrows")
m.manual_aa_color = ui.new_color_picker(TAB, CONTAINER, "Manual AA Color", 255, 105, 180, 255)
m.hotkey_left = ui.new_hotkey(TAB, CONTAINER, "Manual AA: Left")
m.hotkey_back = ui.new_hotkey(TAB, CONTAINER, "Manual AA: Back")
m.hotkey_right = ui.new_hotkey(TAB, CONTAINER, "Manual AA: Right")

m.taser_warning_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Taser Warning ESP")
m.range_rings_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Zeus & Knife Range Rings")
m.range_color = ui.new_color_picker(TAB, CONTAINER, "Range Ring Color", 255, 105, 180, 255)

-- Logs na Tela, Hitmarker, Sparkles & Watermark
ui.new_label(TAB, CONTAINER, "--- Visuals ---")
m.watermark_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Watermark")
m.watermark_color = ui.new_color_picker(TAB, CONTAINER, "Watermark Accent", 255, 105, 180, 255)

m.logs_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Event Logs")
m.logs_pos_ui = ui.new_combobox(TAB, CONTAINER, "Screen Logs Position", { "Left (Default)", "Neverlose", "Center" })

m.hitmarker_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable 3D Heart Hitmarker")
m.hitmarker_style = ui.new_combobox(TAB, CONTAINER, "Hitmarker Style", { "Text (<3)", "Icon (❤)", "Damage Number" })

m.slowdown_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Slowdown Warning")
m.slowdown_color = ui.new_color_picker(TAB, CONTAINER, "Slowdown Accent Color", 255, 105, 180, 255)

m.stamina_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Stamina Meter")
m.stamina_color = ui.new_color_picker(TAB, CONTAINER, "Stamina Accent Color", 255, 105, 180, 255)

m.sparkles_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Death Sparkles")
m.sparkles_color = ui.new_color_picker(TAB, CONTAINER, "Sparkle Color", 255, 255, 255, 255)
m.sparkles_radius = ui.new_slider(TAB, CONTAINER, "Sparkle Radius", 3, 10, 3)
m.sparkles_length = ui.new_slider(TAB, CONTAINER, "Sparkle Length", 1, 10, 2)

-- Netgraph (Aesthetic Style)
ui.new_label(TAB, CONTAINER, "--- Netgraph ---")
m.netgraph_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Custom Netgraph")
m.netgraph_color = ui.new_color_picker(TAB, CONTAINER, "Netgraph Color", 255, 255, 255, 255)
m.netgraph_size = ui.new_combobox(TAB, CONTAINER, "Netgraph Size", { "Mini", "Normal" })
m.netgraph_x = ui.new_slider(TAB, CONTAINER, "Netgraph X Offset (%)", 0, 100, 85, true, "%")
m.netgraph_y = ui.new_slider(TAB, CONTAINER, "Netgraph Y Offset (%)", 0, 100, 90, true, "%")

-- Camera & Viewmodel
ui.new_label(TAB, CONTAINER, "--- Camera & Viewmodel ---")
m.camera_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Camera Mods")
m.aspect_ratio_slider = ui.new_slider(TAB, CONTAINER, "Aspect Ratio (0 = Default)", 0, 200, 0, true, "%", 0.01)
m.viewmodel_fov = ui.new_slider(TAB, CONTAINER, "Viewmodel FOV", 40, 120, 68)
m.viewmodel_x = ui.new_slider(TAB, CONTAINER, "Viewmodel X", -20, 20, 2)
m.viewmodel_y = ui.new_slider(TAB, CONTAINER, "Viewmodel Y", -20, 20, 0)
m.viewmodel_z = ui.new_slider(TAB, CONTAINER, "Viewmodel Z", -20, 20, -1)

-- Custom Sounds
ui.new_label(TAB, CONTAINER, "--- Custom Sounds ---")
m.hitsound_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Custom Hitsound")
m.hitsound_file = ui.new_textbox(TAB, CONTAINER, "Hitsound File (in csgo/sound/)")
m.killsound_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Custom Killsound")
m.killsound_file = ui.new_textbox(TAB, CONTAINER, "Killsound File (in csgo/sound/)")
m.sound_volume = ui.new_slider(TAB, CONTAINER, "Sound Volume Multiplier", 1, 5, 1, true, "x")

-- Trash Talk
ui.new_label(TAB, CONTAINER, "--- Trash Talk ---")
m.killsay_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Trash Talk")
m.killsay_name = ui.new_checkbox(TAB, CONTAINER, "Name on Killsay")
m.killsay_death = ui.new_checkbox(TAB, CONTAINER, "Enable Deathsay (When you die)")
m.killsay_molly = ui.new_checkbox(TAB, CONTAINER, "Enable Molotov Say")
m.killsay_revenge = ui.new_checkbox(TAB, CONTAINER, "Enable Revenge Say")
m.killsay_delay = ui.new_slider(TAB, CONTAINER, "Message Delay (s)", 0, 5, 0, true, "s", 1)

-- Buybot
ui.new_label(TAB, CONTAINER, "--- Buybot ---")
m.buybot_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Buybot")
m.buybot_primary = ui.new_combobox(TAB, CONTAINER, "Primary weapon", { "None", "Auto", "Scout", "Awp", "Primary rifle", "Scoped rifle", "Machine gun" })
m.buybot_secondary = ui.new_combobox(TAB, CONTAINER, "Secondary weapon", { "None", "Default pistol", "P250", "Dual Berettas", "Light pistol", "Heavy pistol" })
m.buybot_utility = ui.new_multiselect(TAB, CONTAINER, "Utility", { "Grenade", "Smoke", "Incendiary", "Flashbang", "Kevlar + Helmet", "Defuse kit", "Zeus" })

-- Misc
ui.new_label(TAB, CONTAINER, "--- Misc ---")
m.crouch_jump_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Train Jump Assist")
m.crouch_jump_hotkey = ui.new_hotkey(TAB, CONTAINER, "Train Jump Hotkey", true)
m.crouch_jump_delay = ui.new_slider(TAB, CONTAINER, "Delay before jump", 0, 1000, 20, true, "ms")
m.crouch_release_delay = ui.new_slider(TAB, CONTAINER, "Delay before duck release", 0, 1000, 450, true, "ms")

m.drop_nades_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Nade Dropper")
m.drop_nades_hotkey = ui.new_hotkey(TAB, CONTAINER, "Nade Dropper Hotkey", true)
m.drop_nades_select = ui.new_multiselect(TAB, CONTAINER, "Nades to drop", { "HE", "Smoke", "Molotov", "Flashbang", "Decoy" })

m.quick_switch_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Quick Switch")
m.quick_switch_select = ui.new_multiselect(TAB, CONTAINER, "Quick Switch Weapons", { "AWP", "Scout" })
m.knife_retreat_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Knife Retreat (Auto Peek)")
m.sync_hotkeys_enabled = ui.new_checkbox(TAB, CONTAINER, "Sync Ragebot Hotkeys")

ui.new_label(TAB, CONTAINER, "=========================")


-- ==========================================
-- [ CAMERA & VIEWMODEL LOGIC ]
-- ==========================================
local orig_cvars = {
    ar = cvar.r_aspectratio:get_float() or 0,
    fov = cvar.viewmodel_fov:get_float() or 68,
    x = cvar.viewmodel_offset_x:get_float() or 2.5,
    y = cvar.viewmodel_offset_y:get_float() or 0,
    z = cvar.viewmodel_offset_z:get_float() or -1.5,
    preset = cvar.viewmodel_presetpos:get_int() or 1
}

local camera_was_on = false

local function handle_camera_mods()
    if ui.get(m.camera_enabled) then
        local ar = ui.get(m.aspect_ratio_slider)
        cvar.r_aspectratio:set_raw_float(ar == 0 and 0 or (ar / 100))
        cvar.viewmodel_presetpos:set_raw_int(0)
        cvar.viewmodel_fov:set_raw_float(ui.get(m.viewmodel_fov))
        cvar.viewmodel_offset_x:set_raw_float(ui.get(m.viewmodel_x))
        cvar.viewmodel_offset_y:set_raw_float(ui.get(m.viewmodel_y))
        cvar.viewmodel_offset_z:set_raw_float(ui.get(m.viewmodel_z))
        camera_was_on = true
    elseif camera_was_on then
        cvar.r_aspectratio:set_raw_float(orig_cvars.ar)
        cvar.viewmodel_presetpos:set_raw_int(orig_cvars.preset)
        cvar.viewmodel_fov:set_raw_float(orig_cvars.fov)
        cvar.viewmodel_offset_x:set_raw_float(orig_cvars.x)
        cvar.viewmodel_offset_y:set_raw_float(orig_cvars.y)
        cvar.viewmodel_offset_z:set_raw_float(orig_cvars.z)
        camera_was_on = false
    end
end

-- ==========================================
-- [ CLANTAG FUNCTIONS ]
-- ==========================================
local clantag_frames = {
    " ", "V", "Vi", "Vit", "Vitr", "Vitri", "Vitrio", "Vitriol", "Vitriol.", "Vitriol.l", "Vitriol.lu", "Vitriol.lua",
    "Vitriol.lua :3", "Vitriol.lua <3", "Vitriol.lua ♡", "Vitriol.lua ♡", "Vitriol.lua <3", "Vitriol.lua :3",
    "Vitriol.lua", "Vitriol.lu", "Vitriol.l", "Vitriol.", "Vitriol", "Vitrio", "Vitri", "Vitr", "Vit", "Vi", "V", " "
}

local static_tag = "Vitriol.lua ♡"
local current_frame = 1
local last_update_time = globals.realtime()
local current_server_tag = ""

local function set_tag(tag)
    if tag ~= current_server_tag then
        client.set_clan_tag(tag)
        current_server_tag = tag
    end
end

ui.set_callback(m.clantag_sync, function()
    current_frame = 1
    last_update_time = globals.realtime()
end)

local function update_clantag()
    if not ui.get(m.clantag_enabled) then return end

    local c_type = ui.get(m.clantag_type)

    if c_type == "Clock" then
        local unix = client.unix_time()
        local offset = ui.get(m.clantag_timezone) == "Brasília" and -3 or -4
        local total_seconds = unix + (offset * 3600)
        local h = math.floor(total_seconds % 86400 / 3600)
        local min = math.floor(total_seconds % 3600 / 60)
        local s = total_seconds % 60
        set_tag(string.format("%02d:%02d:%02d", h, min, s))
        return
    elseif c_type == "Static" then
        set_tag(static_tag)
        return
    elseif c_type == "Animated" then
        local current_time = globals.realtime()
        local speed = ui.get(m.clantag_speed) * 0.1

        if current_time - last_update_time >= speed then
            set_tag(clantag_frames[current_frame])
            current_frame = current_frame + 1
            if current_frame > #clantag_frames then current_frame = 1 end
            last_update_time = current_time
        end
    end
end

local function reset_clantag()
    client.set_clan_tag("")
    current_server_tag = ""
    current_frame = 1
end

-- ==========================================
-- [ VISIBILITY HANDLER ]
-- ==========================================
local function handle_menu()
    local c_state = ui.get(m.clantag_enabled)
    local c_type = ui.get(m.clantag_type)
    ui.set_visible(m.clantag_type, c_state)
    ui.set_visible(m.clantag_timezone, c_state and c_type == "Clock")
    ui.set_visible(m.clantag_speed, c_state and c_type == "Animated")
    ui.set_visible(m.clantag_sync, c_state and c_type == "Animated")

    -- Advanced AA Visibility
    local aa_on = ui.get(m.aa_enabled)
    local cur_edit = ui.get(m.aa_state_edit)
    ui.set_visible(m.anti_brute, aa_on)
    ui.set_visible(m.lc_breaker, aa_on)
    ui.set_visible(m.aa_state_edit, aa_on)

    for i=1, #aa_states do
        local st = aa_states[i]
        local show = aa_on and (cur_edit == st)
        ui.set_visible(m.aa_settings[st].yaw, show)
        ui.set_visible(m.aa_settings[st].jitter_mode, show)
        ui.set_visible(m.aa_settings[st].jitter_range, show)
        ui.set_visible(m.aa_settings[st].body_yaw, show)
        ui.set_visible(m.aa_settings[st].desync, show)
        ui.set_visible(m.aa_settings[st].fl_limit, show)
        ui.set_visible(m.aa_settings[st].fl_amount, show)
        ui.set_visible(m.aa_settings[st].fl_variance, show)
    end

    local h_state = ui.get(m.hud_enabled)
    ui.set_visible(m.hud_style, h_state)
    ui.set_visible(m.hud_color, h_state)

    local maa_state = ui.get(m.manual_aa_enabled)
    ui.set_visible(m.manual_aa_color, maa_state)
    ui.set_visible(m.hotkey_left, maa_state)
    ui.set_visible(m.hotkey_back, maa_state)
    ui.set_visible(m.hotkey_right, maa_state)
    ui.set_visible(m.range_color, ui.get(m.range_rings_enabled))

    local wm_state = ui.get(m.watermark_enabled)
    ui.set_visible(m.watermark_color, wm_state)

    local hm_state = ui.get(m.hitmarker_enabled)
    ui.set_visible(m.hitmarker_style, hm_state)

    local sd_state = ui.get(m.slowdown_enabled)
    ui.set_visible(m.slowdown_color, sd_state)

    local st_state = ui.get(m.stamina_enabled)
    ui.set_visible(m.stamina_color, st_state)

    local lg_state = ui.get(m.logs_enabled)
    ui.set_visible(m.logs_pos_ui, lg_state)

    local sp_state = ui.get(m.sparkles_enabled)
    ui.set_visible(m.sparkles_color, sp_state)
    ui.set_visible(m.sparkles_radius, sp_state)
    ui.set_visible(m.sparkles_length, sp_state)
    
    local ng_state = ui.get(m.netgraph_enabled)
    ui.set_visible(m.netgraph_color, ng_state)
    ui.set_visible(m.netgraph_size, ng_state)
    ui.set_visible(m.netgraph_x, ng_state)
    ui.set_visible(m.netgraph_y, ng_state)

    local cam_state = ui.get(m.camera_enabled)
    ui.set_visible(m.aspect_ratio_slider, cam_state)
    ui.set_visible(m.viewmodel_fov, cam_state)
    ui.set_visible(m.viewmodel_x, cam_state)
    ui.set_visible(m.viewmodel_y, cam_state)
    ui.set_visible(m.viewmodel_z, cam_state)

    local hs_state = ui.get(m.hitsound_enabled)
    ui.set_visible(m.hitsound_file, hs_state)
    local ks_state = ui.get(m.killsound_enabled)
    ui.set_visible(m.killsound_file, ks_state)
    ui.set_visible(m.sound_volume, hs_state or ks_state)

    local k_state = ui.get(m.killsay_enabled)
    ui.set_visible(m.killsay_name, k_state)
    ui.set_visible(m.killsay_death, k_state)
    ui.set_visible(m.killsay_molly, k_state)
    ui.set_visible(m.killsay_revenge, k_state)
    ui.set_visible(m.killsay_delay, k_state)

    local b_state = ui.get(m.buybot_enabled)
    ui.set_visible(m.buybot_primary, b_state)
    ui.set_visible(m.buybot_secondary, b_state)
    ui.set_visible(m.buybot_utility, b_state)

    local cj_state = ui.get(m.crouch_jump_enabled)
    ui.set_visible(m.crouch_jump_hotkey, cj_state)
    ui.set_visible(m.crouch_jump_delay, cj_state)
    ui.set_visible(m.crouch_release_delay, cj_state)

    local dn_state = ui.get(m.drop_nades_enabled)
    ui.set_visible(m.drop_nades_hotkey, dn_state)
    ui.set_visible(m.drop_nades_select, dn_state)

    local qs_state = ui.get(m.quick_switch_enabled)
    ui.set_visible(m.quick_switch_select, qs_state)
end

local callbacks_list = { m.clantag_enabled, m.camera_enabled, m.clantag_type, m.clantag_timezone, m.hud_enabled, m.watermark_enabled, m.hitmarker_enabled, m.slowdown_enabled, m.stamina_enabled, m.logs_enabled, m.sparkles_enabled, m.manual_aa_enabled, m.range_rings_enabled, m.hitsound_enabled, m.killsound_enabled, m.killsay_enabled, m.buybot_enabled, m.crouch_jump_enabled, m.drop_nades_enabled, m.quick_switch_enabled, m.netgraph_enabled, m.aa_enabled, m.aa_state_edit }
for i=1, #callbacks_list do
    ui.set_callback(callbacks_list[i], handle_menu)
end

ui.set_callback(m.clantag_enabled, function()
    if not ui.get(m.clantag_enabled) then reset_clantag() end
end)
handle_menu()

-- ==========================================
-- [ UTILS ]
-- ==========================================
local function trim_string(s) return s:match("^%s*(.-)%s*$") end
local function lerp(a, b, t) return a + (b - a) * t end

local function is_active(ref_tbl)
    if not ref_tbl or ref_tbl[1] == nil then return false end
    local val = ui.get(ref_tbl[1])
    local enabled = false

    if type(val) == "boolean" then enabled = val
    elseif type(val) == "table" then enabled = #val > 0
    elseif type(val) == "string" then enabled = (val ~= "Off" and val ~= "-")
    else enabled = true end

    if not enabled then return false end
    if ref_tbl[2] ~= nil and type(ui.get(ref_tbl[2])) == "boolean" then return ui.get(ref_tbl[2]) end
    return true
end

local function table_contains(tbl, val)
    for i = 1, #tbl do if tbl[i] == val then return true end end
    return false
end

-- ==========================================
-- [ MANUAL AA ARROWS & LOGIC ]
-- ==========================================
local manual_state = 0
local last_press_l, last_press_r, last_press_b = 0, 0, 0

local function handle_manual_aa()
    if not ui.get(m.manual_aa_enabled) then return end
    
    local left = ui.get(m.hotkey_left)
    local right = ui.get(m.hotkey_right)
    local back = ui.get(m.hotkey_back)

    if left and globals.realtime() > last_press_l + 0.2 then
        manual_state = manual_state == 1 and 0 or 1
        last_press_l = globals.realtime()
    elseif right and globals.realtime() > last_press_r + 0.2 then
        manual_state = manual_state == 2 and 0 or 2
        last_press_r = globals.realtime()
    elseif back and globals.realtime() > last_press_b + 0.2 then
        manual_state = 0
        last_press_b = globals.realtime()
    end

    ui.set(refs.yaw_base, "Local view")
    if manual_state == 1 then 
        ui.set(refs.yaw_slider, -90)
    elseif manual_state == 2 then 
        ui.set(refs.yaw_slider, 90) 
    elseif not ui.get(m.aa_enabled) then
        ui.set(refs.yaw_slider, 0)
    end
end

local function draw_manual_aa()
    if not ui.get(m.manual_aa_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local sw, sh = client.screen_size()
    local cx, cy = sw / 2, sh / 2
    local r, g, b, a = ui.get(m.manual_aa_color)
    local offset = 40

    local function get_color(state)
        if manual_state == state then return r, g, b, a end
        return 25, 25, 25, 150
    end

    local lr, lg, lb, la = get_color(1)
    renderer.triangle(cx - offset, cy, cx - offset + 10, cy - 5, cx - offset + 10, cy + 5, lr, lg, lb, la)
    local rr, rg, rb, ra = get_color(2)
    renderer.triangle(cx + offset, cy, cx + offset - 10, cy - 5, cx + offset - 10, cy + 5, rr, rg, rb, ra)
    local br, bg, bb, ba = get_color(0)
    renderer.triangle(cx, cy + offset, cx - 5, cy + offset - 10, cx + 5, cy + offset - 10, br, bg, bb, ba)
end

-- ==========================================
-- [ EXPLOITS: ANTI-BRUTEFORCE & LC BREAKER ]
-- ==========================================
local bruteforce_flip = false
local math_sqrt = math.sqrt
local bit_band = bit.band

client.set_event_callback("bullet_impact", function(e)
    if not ui.get(m.aa_enabled) or not ui.get(m.anti_brute) then return end
    
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    local shooter = client.userid_to_entindex(e.userid)
    if shooter == me or not entity.is_enemy(shooter) then return end

    local ex, ey, ez = entity.get_prop(shooter, "m_vecOrigin")
    local ex_v, ey_v, ez_v = entity.get_prop(shooter, "m_vecViewOffset")
    if not ex or not ex_v then return end
    local sx, sy, sz = ex + ex_v, ey + ey_v, ez + ez_v

    local lx, ly, lz = entity.get_prop(me, "m_vecOrigin")
    local l_vx, l_vy, l_vz = entity.get_prop(me, "m_vecViewOffset")
    if not lx or not l_vx then return end
    local hx, hy, hz = lx + l_vx, ly + l_vy, lz + l_vz

    local dx, dy, dz = e.x - sx, e.y - sy, e.z - sz
    local len = math_sqrt(dx*dx + dy*dy + dz*dz)
    if len == 0 then return end
    dx, dy, dz = dx/len, dy/len, dz/len

    local vx, vy, vz = hx - sx, hy - sy, hz - sz
    local dot = vx*dx + vy*dy + vz*dz

    if dot > 0 then
        local px, py, pz = sx + dx*dot, sy + dy*dot, sz + dz*dot
        local dist = math_sqrt((px-hx)^2 + (py-hy)^2 + (pz-hz)^2)
        
        if dist < 60 then
            bruteforce_flip = not bruteforce_flip
            if ui.get(m.logs_enabled) then
                client.color_log(255, 105, 180, "[Vitriol.lua] Anti-Bruteforce: Miss detected! Flipped Desync.")
            end
        end
    end
end)

-- ==========================================
-- [ ADVANCED ANTI-AIM LOGIC ]
-- ==========================================
local function handle_advanced_aa(cmd)
    if not ui.get(m.aa_enabled) then return end
    
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    local flags = entity.get_prop(me, "m_fFlags")
    local vx, vy = entity.get_prop(me, "m_vecVelocity")
    local speed = math_sqrt(vx * vx + vy * vy)
    local in_air = bit_band(flags, 1) == 0
    local duck_amount = entity.get_prop(me, "m_flDuckAmount")
    
    local current_state = "Stand"
    if in_air then 
        current_state = "Air"
    elseif duck_amount > 0.5 then 
        current_state = "Crouch"
    elseif speed > 5 then 
        current_state = "Move" 
    end
    
    local set = m.aa_settings[current_state]
    
    if manual_state == 0 then
        ui.set(refs.yaw_slider, ui.get(set.yaw))
    end
    
    ui.set(refs.yaw_jitter[1], ui.get(set.jitter_mode))
    ui.set(refs.yaw_jitter[2], ui.get(set.jitter_range))
    ui.set(refs.body_yaw[1], ui.get(set.body_yaw))
    
    local target_desync = ui.get(set.desync)
    if bruteforce_flip then target_desync = -target_desync end
    ui.set(refs.body_yaw[2], target_desync)
    
    ui.set(refs.fl_amount, ui.get(set.fl_amount))
    ui.set(refs.fl_variance, ui.get(set.fl_variance))
    
    local final_limit = ui.get(set.fl_limit)
    if ui.get(m.lc_breaker) and current_state == "Move" then
        if cmd.command_number % 3 == 0 then
            final_limit = math.max(1, final_limit - math.random(3, 7))
        end
    end
    ui.set(refs.fl_limit, final_limit)
end

-- ==========================================
-- [ TASER WARNING ESP ]
-- ==========================================
local taser_svg_raw = "<svg id=\"svg\" version=\"1.1\" width=\"608\" height=\"689\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" ><g id=\"svgg\"><path id=\"path0\" d=\"M185.803 18.945 C 184.779 19.092,182.028 23.306,174.851 35.722 C 169.580 44.841,157.064 66.513,147.038 83.882 C 109.237 149.365,100.864 163.863,93.085 177.303 C 88.686 184.901,78.772 202.072,71.053 215.461 C 63.333 228.849,53.959 245.069,50.219 251.505 C 46.480 257.941,43.421 263.491,43.421 263.837 C 43.421 264.234,69.566 264.530,114.025 264.635 L 184.628 264.803 181.217 278.618 C 179.342 286.217,174.952 304.128,171.463 318.421 C 167.974 332.714,160.115 364.836,153.999 389.803 C 147.882 414.770,142.934 435.254,143.002 435.324 C 143.127 435.452,148.286 428.934,199.343 364.145 C 215.026 344.243,230.900 324.112,234.619 319.408 C 238.337 314.704,254.449 294.276,270.423 274.013 C 286.397 253.750,303.090 232.582,307.519 226.974 C 340.870 184.745,355.263 166.399,355.263 166.117 C 355.263 165.937,323.554 165.789,284.798 165.789 C 223.368 165.789,214.380 165.667,214.701 164.831 C 215.039 163.949,222.249 151.366,243.554 114.474 C 280.604 50.317,298.192 19.768,298.267 19.444 C 298.355 19.064,188.388 18.576,185.803 18.945 \" stroke=\"none\" fill=\"#ffffff\" fill-rule=\"evenodd\"></path></g></svg>"
local taser_svg = renderer.load_svg(taser_svg_raw, 150, 150)

local function draw_taser_warning()
    if not ui.get(m.taser_warning_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    local lpx, lpy, lpz = entity.get_prop(me, "m_vecOrigin")
    local players = entity.get_players(true)

    for i=1, #players do
        local enemy = players[i]
        if entity.is_alive(enemy) then
            local wpn = entity.get_player_weapon(enemy)
            if wpn and entity.get_classname(wpn) == "CWeaponTaser" then
                local ex, ey, ez = entity.get_prop(enemy, "m_vecOrigin")
                if lpx and ex then
                    local dist = math.sqrt((lpx-ex)^2 + (lpy-ey)^2 + (lpz-ez)^2)
                    local bbox = { entity.get_bounding_box(enemy) }
                    if bbox[1] ~= nil and dist < 190 then
                        local a = math.floor(255 * math.abs(math.sin(globals.curtime() * 8)))
                        renderer.texture(taser_svg, bbox[1] - 22, bbox[2], 20, 20, 255, 50, 50, a * bbox[5], "f")
                    end
                end
            end
        end
    end
end

-- ==========================================
-- [ ZEUS & KNIFE RANGE RINGS ]
-- ==========================================
local function draw_range_rings()
    if not ui.get(m.range_rings_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    local wpn = entity.get_player_weapon(me)
    if not wpn then return end
    
    local classname = entity.get_classname(wpn)
    local is_knife = classname:find("Knife") or classname:find("Bayonet")
    local is_zeus = classname == "CWeaponTaser"
    
    if is_knife or is_zeus then
        local x, y, z = entity.get_prop(me, "m_vecOrigin")
        local radius = is_zeus and 190 or 60
        local r, g, b, a = ui.get(m.range_color)
        
        local accuracy = 60
        local step = (math.pi * 2) / accuracy
        local offsets = { -1, 0, 1 }
        local alphas = { math.floor(a * 0.3), a, math.floor(a * 0.3) }
        
        for j = 1, 3 do
            local current_radius = radius + offsets[j]
            local current_alpha = alphas[j]
            local prev_sx, prev_sy
            
            for i = 0, accuracy do
                local theta = i * step
                local px = x + (current_radius * math.cos(theta))
                local py = y + (current_radius * math.sin(theta))
                local sx, sy = renderer.world_to_screen(px, py, z)
                if sx and sy then
                    if prev_sx and prev_sy then
                        renderer.line(prev_sx, prev_sy, sx, sy, r, g, b, current_alpha)
                    end
                    prev_sx, prev_sy = sx, sy
                else
                    prev_sx, prev_sy = nil, nil
                end
            end
        end
    end
end

-- ==========================================
-- [ SOUND PLAYER HELPER ]
-- ==========================================
local function play_custom_sound(type)
    local file = type == "hit" and ui.get(m.hitsound_file) or ui.get(m.killsound_file)
    if file == "" then return end
    if not file:find("%.wav") and not file:find("%.mp3") then file = file .. ".wav" end

    local vol = ui.get(m.sound_volume)
    if native_Surface_PlaySound then
        for i=1, vol do native_Surface_PlaySound(file) end
    else
        for i=1, vol do client.exec("play " .. file) end
    end
end

-- ==========================================
-- [ RAGEBOT HOTKEY SYNC ]
-- ==========================================
local syncing = true
local hotkey_type_names = { [0] = "Always on", "On hotkey", "Toggle", "Off hotkey" }
local weapon_names = { "Global", "G3SG1 / SCAR-20", "SSG 08", "AWP", "R8 Revolver", "Desert Eagle", "Pistol", "Zeus", "Rifle", "Shotgun", "SMG", "Machine gun" }
local weapon_type_ref = ui.reference("RAGE", "Weapon type", "Weapon type")

local function sync_hotkey_to_all(ref)
    if not syncing or not ui.get(m.sync_hotkeys_enabled) then return end
    local _, htype_num, bind = ui.get(ref)
    local htype_str = hotkey_type_names[htype_num] or "Always on"
    bind = bind or 0
    local current_weapon = ui.get(weapon_type_ref)

    for i = 1, #weapon_names do
        ui.set(weapon_type_ref, weapon_names[i])
        ui.set(ref, htype_str, bind)
    end
    ui.set(weapon_type_ref, current_weapon)
end

local sync_refs = {
    select(2, ui.reference("RAGE", "Aimbot", "Enabled")), select(2, ui.reference("RAGE", "Aimbot", "Multi-point")), select(2, ui.reference("RAGE", "Aimbot", "Minimum damage override")),
    select(1, ui.reference("RAGE", "Aimbot", "Force safe point")), select(1, ui.reference("RAGE", "Aimbot", "Force body aim")), select(2, ui.reference("RAGE", "Aimbot", "Quick stop")), select(2, ui.reference("RAGE", "Aimbot", "Double tap")),
}
for i = 1, #sync_refs do
    local ref = sync_refs[i]
    if ui.type(ref) == "hotkey" then
        ui.set_callback(ref, function() sync_hotkey_to_all(ref) end)
    end
end

client.set_event_callback("pre_config_load", function() syncing = false end)
client.set_event_callback("post_config_load", function() syncing = true end)


-- ==========================================
-- [ NADE DROPPER ]
-- ==========================================
local nade_mappings = { ["CHEGrenade"] = { cmd = "weapon_hegrenade", menu = "HE" }, ["CSmokeGrenade"] = { cmd = "weapon_smokegrenade", menu = "Smoke" }, ["CMolotovGrenade"] = { cmd = "weapon_molotov", menu = "Molotov" }, ["CIncendiaryGrenade"] = { cmd = "weapon_incgrenade", menu = "Molotov" }, ["CFlashbang"] = { cmd = "weapon_flashbang", menu = "Flashbang" }, ["CDecoyGrenade"] = { cmd = "weapon_decoy", menu = "Decoy" } }
local nade_drop_queue = {}
local nade_drop_throwing = false
local nade_drop_old_state = false

local function handle_nade_dropper(cmd)
    if not ui.get(m.drop_nades_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local state = ui.get(m.drop_nades_hotkey)
    if state and not nade_drop_old_state and not nade_drop_throwing then
        nade_drop_queue = {}
        local selected = ui.get(m.drop_nades_select)

        for i = 0, 63 do
            local weapon_ent = entity.get_prop(me, "m_hMyWeapons", i)
            if weapon_ent and weapon_ent ~= 0 and weapon_ent ~= -1 then
                local class_name = entity.get_classname(weapon_ent)
                local mapped = nade_mappings[class_name]
                if mapped and table_contains(selected, mapped.menu) then table.insert(nade_drop_queue, mapped.cmd) end
            end
        end
        if #nade_drop_queue > 0 then nade_drop_throwing = true end
    end
    nade_drop_old_state = state

    if #nade_drop_queue > 0 then
        local latency = client.latency() + (globals.tickinterval() * 4)
        for i, weapon_cmd in ipairs(nade_drop_queue) do
            local is_last = (i == #nade_drop_queue)
            client.delay_call(latency * i, function()
                client.exec("use " .. weapon_cmd .. "; drop")
                if is_last then client.delay_call(0.1, function() nade_drop_throwing = false end) end
            end)
        end
        nade_drop_queue = {}
    end

    if nade_drop_throwing then
        local pitch, yaw = client.camera_angles()
        local offset = pitch > 0 and -0.0001 or 0.0001
        cmd.yaw = yaw; cmd.pitch = pitch + offset; cmd.no_choke = true; cmd.allow_send_packet = true
    end
end


-- ==========================================
--            [ WATERMARK ]
-- ==========================================
local function draw_watermark()
    if not ui.get(m.watermark_enabled) then return end

    local sw, sh = client.screen_size()
    local r, g, b, a = ui.get(m.watermark_color)
    local fps = math.floor(1 / globals.absoluteframetime())
    local ping = math.floor(client.latency() * 1000)
    local h, min, s = client.system_time()
    local time_str = string.format("%02d:%02d:%02d", h, min, s)

    local me = entity.get_local_player()
    local user = "unknown"
    if me then
        user = entity.get_player_name(me) or "unknown"
        if string.len(user) > 15 then user = string.sub(user, 1, 12) .. "..." end
    end

    local str_base = string.format("♡ vitriol.lua | %s | ", user)
    local str_fps_suf = "fps | "
    local str_ping_suf = "ms | "

    local w_base = renderer.measure_text("", str_base)
    local w_num = renderer.measure_text("", "999")
    local w_fps_suf = renderer.measure_text("", str_fps_suf)
    local w_ping_suf = renderer.measure_text("", str_ping_suf)
    local w_time = renderer.measure_text("", "00:00:00")

    local padding = 8
    local w = w_base + (w_num * 2) + w_fps_suf + w_ping_suf + w_time + (padding * 2)
    local h_box = 20
    local x = sw - w - 15
    local y = 15

    renderer.rectangle(x, y, w, h_box, 15, 15, 15, 200)
    renderer.rectangle(x, y, w, 2, r, g, b, a)

    local cx = x + padding
    renderer.text(cx, y + 4, 255, 255, 255, 255, "", 0, str_base)
    cx = cx + w_base
    renderer.text(cx + w_num, y + 4, 255, 255, 255, 255, "r", 0, tostring(fps))
    cx = cx + w_num
    renderer.text(cx, y + 4, 255, 255, 255, 255, "", 0, str_fps_suf)
    cx = cx + w_fps_suf
    renderer.text(cx + w_num, y + 4, 255, 255, 255, 255, "r", 0, tostring(ping))
    cx = cx + w_num
    renderer.text(cx, y + 4, 255, 255, 255, 255, "", 0, str_ping_suf)
    cx = cx + w_ping_suf
    renderer.text(cx, y + 4, 255, 255, 255, 255, "", 0, time_str)
end


-- ==========================================
-- [ STAMINA METER ]
-- ==========================================
local function draw_stamina_meter()
    if not ui.get(m.stamina_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local stamina = entity.get_prop(me, "m_flStamina") or 0
    if stamina <= 0.5 then return end

    local sw, sh = client.screen_size()
    local cx = sw / 2
    local cy = sh / 2

    local bar_width = 174
    local bar_height = 8
    local bar_x = cx - (bar_width / 2)
    local bar_y = cy - (cy / 1.5) + 25

    local max_stamina = 80
    local fraction = math.min(1, stamina / max_stamina)
    local fill_width = math.floor(bar_width * fraction)

    local r, g, b, a = ui.get(m.stamina_color)
    renderer.rectangle(bar_x, bar_y, bar_width, bar_height, 25, 25, 25, math.floor(a * 0.8))

    if fill_width > 0 then
        renderer.rectangle(bar_x, bar_y, fill_width, bar_height, r, g, b, a)
        for i = 1, 3 do
            local glow_a = math.floor(a / (i * 2.5))
            renderer.rectangle(bar_x - i, bar_y - i, fill_width + (i * 2), bar_height + (i * 2), r, g, b, glow_a)
        end
    end

    local text = string.format("Stamina Penalty: %.0f", stamina)
    renderer.text(cx + 1, bar_y - 12 + 1, 10, 10, 10, math.floor(a * 0.8), "c", 0, text)
    renderer.text(cx, bar_y - 12, 255, 255, 255, a, "c", 0, text)
end


-- ==========================================
-- [ INDICADORES DA HUD E SLOWDOWN ]
-- ==========================================
local anim_data = { dt = 0, dt_charge = 1.0, hs = 0, fs = 0, fd = 0, baim = 0, sp = 0 }
local dmg_anim = { val = 0, r = 220, g = 180, b = 255 }

local function draw_slowdown_warning()
    if not ui.get(m.slowdown_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local velocity_modifier = entity.get_prop(me, "m_flVelocityModifier") or 1.0
    local fade_threshold = 0.95
    local fade_alpha = 1.0

    if velocity_modifier > fade_threshold then
        fade_alpha = (1.0 - velocity_modifier) / (1.0 - fade_threshold)
        fade_alpha = math.max(0, math.min(1, fade_alpha))
    end
    if fade_alpha <= 0.01 then return end

    local sw, sh = client.screen_size()
    local cx = sw / 2
    local cy = sh / 2

    local bar_width = 174
    local bar_height = 8
    local bar_x = cx - (bar_width / 2)
    local bar_y = cy - (cy / 1.5)

    local fill_width = math.floor(bar_width * velocity_modifier)
    local r, g, b, a = ui.get(m.slowdown_color)
    local final_a = math.floor(a * fade_alpha)
    local bg_a = math.floor(255 * fade_alpha)

    renderer.rectangle(bar_x, bar_y, bar_width, bar_height, 25, 25, 25, math.floor(bg_a * 0.8))

    if fill_width > 0 then
        renderer.rectangle(bar_x, bar_y, fill_width, bar_height, r, g, b, final_a)
        for i = 1, 3 do
            local glow_a = math.floor(final_a / (i * 2.5))
            renderer.rectangle(bar_x - i, bar_y - i, fill_width + (i * 2), bar_height + (i * 2), r, g, b, glow_a)
        end
    end

    local percentage = (1.0 - velocity_modifier) * 100
    local text = string.format("Max velocity reduced by %.0f%%", percentage)
    renderer.text(cx + 1, bar_y - 12 + 1, 10, 10, 10, math.floor(final_a * 0.8), "c", 0, text)
    renderer.text(cx, bar_y - 12, 255, 255, 255, final_a, "c", 0, text)
end

local function draw_indicator(x, y, r, g, b, a, text, value, is_dt)
    if value <= 0 then return y end
    local current_alpha = math.floor(a * value)
    local style = ui.get(m.hud_style)
    local flag = style == "Bold" and "cb" or "c"

    renderer.text(x + 1, y + 1, 10, 10, 10, math.floor(current_alpha * 0.8), flag, 0, text)
    renderer.text(x, y, r, g, b, current_alpha, flag, 0, text)

    if is_dt then
        local tw, th = renderer.measure_text(flag, text)
        local bar_x = x + (tw / 2) + 4
        local bar_y = y - 3
        for i = 0, 5 do
            local is_filled = (i / 5) <= anim_data.dt_charge
            local block_a = is_filled and current_alpha or math.floor(current_alpha * 0.2)
            renderer.rectangle(bar_x + (i * 4) + 1, bar_y + 1, 2, 6, 10, 10, 10, math.floor(current_alpha * 0.5))
            renderer.rectangle(bar_x + (i * 4), bar_y, 2, 6, r, g, b, block_a)
        end
    end
    return y + (13 * value)
end

local function draw_crosshair_hud()
    if not ui.get(m.hud_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local sw, sh = client.screen_size()
    local cx = sw / 2
    local cy = sh / 2
    local y_offset = cy + 25
    local frametime = globals.frametime() * 8
    local r, g, b, a = ui.get(m.hud_color)

    local style = ui.get(m.hud_style)
    local flag = style == "Bold" and "cb" or "c"

    local weapon_ent = entity.get_player_weapon(me)
    if weapon_ent then
        local weapon_class = entity.get_classname(weapon_ent) or ""
        local is_knife = weapon_class:find("Knife") or weapon_class:find("Bayonet")
        local is_grenade = weapon_class:find("Grenade") or weapon_class:find("Flashbang") or weapon_class:find("Molotov") or weapon_class:find("Decoy") or weapon_class:find("Smoke") or weapon_class:find("Incendiary")

        if not is_knife and not is_grenade then
            local normal_dmg = refs.dmg[1] ~= nil and ui.get(refs.dmg[1]) or 1
            local is_override_active = false
            local override_dmg = 1
            if #refs.ovr == 2 then is_override_active = ui.get(refs.ovr[1]); override_dmg = ui.get(refs.ovr[2])
            elseif #refs.ovr == 3 then is_override_active = ui.get(refs.ovr[2]); override_dmg = ui.get(refs.ovr[3]) end

            local target_dmg = is_override_active and override_dmg or normal_dmg
            dmg_anim.val = lerp(dmg_anim.val, target_dmg, globals.frametime() * 25)
            if math.abs(dmg_anim.val - target_dmg) < 0.5 then dmg_anim.val = target_dmg end

            local display_num = math.floor(dmg_anim.val + 0.5)
            local display_text = display_num == 0 and "Auto" or (display_num > 100 and "HP+" .. tostring(display_num - 100) or tostring(display_num))

            local target_r, target_g, target_b = 220, 180, 255
            if is_override_active then target_r, target_g, target_b = 255, 105, 180 end

            dmg_anim.r = lerp(dmg_anim.r, target_r, globals.frametime() * 15)
            dmg_anim.g = lerp(dmg_anim.g, target_g, globals.frametime() * 15)
            dmg_anim.b = lerp(dmg_anim.b, target_b, globals.frametime() * 15)

            local dmg_x = cx + 12
            local dmg_y = cy - 15
            renderer.text(dmg_x + 1, dmg_y + 1, 10, 10, 10, math.floor(a * 0.8), flag, 0, display_text)
            renderer.text(dmg_x, dmg_y, math.floor(dmg_anim.r), math.floor(dmg_anim.g), math.floor(dmg_anim.b), a, flag, 0, display_text)
        end
    end

    y_offset = draw_indicator(cx, y_offset, r, g, b, a, "VITRIOL", 1.0)
    y_offset = y_offset + 2

    local is_dt = is_active(refs.dt)
    local is_hs = is_active(refs.hs)
    local is_fs = is_active(refs.fs)
    local is_fd = is_active(refs.fd)
    local is_baim = is_active(refs.baim)
    local is_sp = is_active(refs.sp)

    anim_data.dt = math.max(0, math.min(1, anim_data.dt + (is_dt and frametime or -frametime)))
    anim_data.hs = math.max(0, math.min(1, anim_data.hs + (is_hs and frametime or -frametime)))
    anim_data.fs = math.max(0, math.min(1, anim_data.fs + (is_fs and frametime or -frametime)))
    anim_data.fd = math.max(0, math.min(1, anim_data.fd + (is_fd and frametime or -frametime)))
    anim_data.baim = math.max(0, math.min(1, anim_data.baim + (is_baim and frametime or -frametime)))
    anim_data.sp = math.max(0, math.min(1, anim_data.sp + (is_sp and frametime or -frametime)))
    anim_data.dt_charge = math.max(0, math.min(1, anim_data.dt_charge + globals.frametime() * 1.5))

    local flags = entity.get_prop(me, "m_fFlags")
    local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
    local speed = math_sqrt(vx * vx + vy * vy)
    local duck_amount = entity.get_prop(me, "m_flDuckAmount")

    local state = "IDLE"
    if bit_band(flags, 1) == 0 then state = duck_amount > 0.5 and "AIR-C" or "AIR"
    elseif duck_amount > 0.5 then state = speed > 5 and "CROUCH-M" or "CROUCH"
    elseif speed > 5 then state = "MOVE" end

    y_offset = draw_indicator(cx, y_offset, 255, 255, 255, a, string.format("<%s>", state), 1.0)
    y_offset = y_offset + 2

    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "DT", anim_data.dt, true)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "HS", anim_data.hs)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "FS", anim_data.fs)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "FD", anim_data.fd)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "BAIM", anim_data.baim)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "SAFE", anim_data.sp)
end


-- ==========================================
-- [ LOGS E HITMARKER ]
-- ==========================================
local hitgroup_names = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }
local aim_data = {}
local screen_logs = {}
local hit_markers = {}
local max_logs = 6

local function add_screen_log(text, color)
    table.insert(screen_logs, 1, { text = text, color = color, time = globals.realtime(), alpha = 0 })
    if #screen_logs > max_logs then table.remove(screen_logs, #screen_logs) end
end

local function draw_screen_logs()
    if not ui.get(m.logs_enabled) or #screen_logs == 0 then return end

    local sw, sh = client.screen_size()
    local pos_style = ui.get(m.logs_pos_ui)
    local current_time = globals.realtime()

    local base_x, base_y = 10, sh / 2 + 100
    local center_x = false
    local stack_dir = -1

    if pos_style == "Neverlose" then base_x = 10; base_y = 10; stack_dir = 1
    elseif pos_style == "Center" then center_x = true; base_y = sh / 2 + 200 end

    local y = base_y
    for i = #screen_logs, 1, -1 do
        local log = screen_logs[i]
        local time_alive = current_time - log.time

        if time_alive < 0.2 then log.alpha = time_alive / 0.2
        elseif time_alive > 4.8 then log.alpha = 1.0 - ((time_alive - 4.8) / 0.2)
        else log.alpha = 1.0 end

        if time_alive > 5.0 then table.remove(screen_logs, i)
        else
            local a = math.max(0, math.floor(log.alpha * 255))
            local tw, th = renderer.measure_text("", log.text)
            local box_w = tw + 20
            local draw_x = center_x and ((sw / 2) - (box_w / 2)) or base_x

            renderer.rectangle(draw_x, y, box_w, 20, 15, 15, 15, math.floor(a * 0.6))
            renderer.rectangle(draw_x, y, 2, 20, log.color[1], log.color[2], log.color[3], a)
            renderer.text(draw_x + 5, y + 4, log.color[1], log.color[2], log.color[3], a, "", 0, "❤")
            renderer.text(draw_x + 18, y + 4, 255, 255, 255, a, "", 0, log.text)
            y = y + (22 * stack_dir)
        end
    end
end

local function draw_3d_hitmarkers()
    if not ui.get(m.hitmarker_enabled) or #hit_markers == 0 then return end

    local style = ui.get(m.hitmarker_style)
    local is_dmg = style == "Damage Number"
    local symbol = style == "Icon (❤)" and "❤" or "<3"
    local flag = style == "Icon (❤)" and "c" or "cb"

    local current_time = globals.realtime()
    for i = #hit_markers, 1, -1 do
        local marker = hit_markers[i]
        local time_alive = current_time - marker.time

        if time_alive > 1.5 then table.remove(hit_markers, i)
        else
            local sx, sy = renderer.world_to_screen(marker.x, marker.y, marker.z)
            if sx and sy then
                sy = sy - (time_alive * 30)
                local alpha = 255
                if time_alive > 1.0 then alpha = math.max(0, math.floor(255 * (1.5 - time_alive) / 0.5)) end

                if is_dmg then
                    local dmg_str = tostring(marker.damage or 0)
                    renderer.text(sx + 1, sy + 1, 10, 10, 10, alpha, "c", 0, dmg_str)
                    renderer.text(sx, sy, 255, 105, 180, alpha, "c", 0, dmg_str)
                else
                    renderer.text(sx + 1, sy + 1, 10, 10, 10, alpha, flag, 0, symbol)
                    renderer.text(sx, sy, 255, 105, 180, alpha, flag, 0, symbol)
                end
            end
        end
    end
end

local function on_aim_fire(e)
    anim_data.dt_charge = 0
    aim_data[e.id] = { target = e.target, hit_chance = e.hit_chance, damage = e.damage, backtrack = globals.tickcount() - e.tick, x = e.x, y = e.y, z = e.z }
end

local function on_aim_hit(e)
    local data = aim_data[e.id]
    if not data then return end

    if ui.get(m.hitmarker_enabled) and data.x and data.y and data.z then table.insert(hit_markers, { x = data.x, y = data.y, z = data.z, time = globals.realtime(), damage = e.damage }) end
    if not ui.get(m.logs_enabled) then return end

    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
    local hp_left = entity.get_prop(e.target, "m_iHealth")
    local log_text = string.format("Hit %s in the %s for %d dmg (hc: %d%% | bt: %d) [hp: %d]", target_name, hitgroup, e.damage, math.floor(data.hit_chance), data.backtrack, hp_left)

    client.color_log(255, 105, 180, "\n[Vitriol.lua] " .. log_text)
    add_screen_log(log_text, { 255, 105, 180 })
end

local function on_aim_miss(e)
    if not ui.get(m.logs_enabled) then return end
    local data = aim_data[e.id]
    if not data then return end

    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
    local log_text = string.format("Missed %s's %s due to %s (hc: %d%% | bt: %d)", target_name, hitgroup, e.reason, math.floor(data.hit_chance), data.backtrack)

    client.color_log(255, 105, 180, "\n[Vitriol.lua] " .. log_text)
    add_screen_log(log_text, { 200, 60, 60 })
end

-- ==========================================
-- [ DEATH SPARKLES ]
-- ==========================================
local function on_player_death_sparkles(e)
    if not ui.get(m.sparkles_enabled) then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    if not victim then return end

    if attacker == lp and victim ~= lp then
        local radius = ui.get(m.sparkles_radius)
        local length = ui.get(m.sparkles_length)
        local r, g, b, a = ui.get(m.sparkles_color)

        if spark_material then
            pcall(function()
                if spark_material.alpha_modulate then spark_material:alpha_modulate(a); spark_material:color_modulate(r, g, b) end
            end)
        end

        local vx, vy, vz = entity.get_prop(victim, "m_vecOrigin")
        if vx and vy and vz then
            local pos = ffi.new("struct spark_vec3_t", { vx, vy, vz + 40 })
            local dir = ffi.new("struct spark_vec3_t", { 0, 0, 0 })
            if FX_ElectricSpark then FX_ElectricSpark(pos, radius, length, dir) end
        end
    end
end


-- ==========================================
-- [ TRASH TALK ]
-- ==========================================
local messages = { "VITRIOL.lua dissolve voce", "Vitriol.lua > ALL :3", "Deita ai random", "Owned by Vitriol.lua ♡", "voce foi ownado", "voce foi dissolvido" }
local molly_msgs = { "Churrasco de random kkk", "Assado vivo", "Fogo na inveja", "Virou cinza kkk", "Dançando no fogo" }
local death_msgs = { "Sério isso? kk", "Cagada do século", "Milagre arrombado", "Aí é foda", "Sorte kkk da próxima te deito", "Isso foi clutch?", "Era free kill" }

local current_idx, molly_idx, death_idx = 1, 1, 1
local revenge_target_userid = nil
local next_chat_time = 0

local function is_spectator()
    local lp = entity.get_local_player()
    return not lp or entity.get_prop(lp, "m_iTeamNum") == 1
end

local function format_message(msg, victim_ent)
    if ui.get(m.killsay_name) and victim_ent then
        local victim_name = trim_string(entity.get_player_name(victim_ent) or "voce")
        msg = msg:gsub("voce", victim_name)
    end
    return msg
end

local function queue_message(msg)
    local current_time = globals.realtime()
    if next_chat_time < current_time then next_chat_time = current_time end

    local delay_to_exec = next_chat_time - current_time
    next_chat_time = next_chat_time + 0.85

    if delay_to_exec <= 0.01 then client.exec('say "' .. msg .. '"')
    else client.delay_call(delay_to_exec, function() client.exec('say "' .. msg .. '"') end) end
end

local function queue_with_delay(msg)
    local user_delay = ui.get(m.killsay_delay)
    if user_delay <= 0.01 then queue_message(msg) else client.delay_call(user_delay, function() queue_message(msg) end) end
end

local function on_killsay_player_death(e)
    local lp = entity.get_local_player()
    local attacker_ent = client.userid_to_entindex(e.attacker)
    local victim_ent = client.userid_to_entindex(e.userid)

    if attacker_ent == lp and victim_ent ~= lp then
        if ui.get(m.killsound_enabled) then play_custom_sound("kill") end
    end

    if not ui.get(m.killsay_enabled) or is_spectator() then return end

    if victim_ent == lp and attacker_ent ~= lp and attacker_ent then
        if ui.get(m.killsay_death) then
            local msg = format_message(death_msgs[death_idx], attacker_ent)
            queue_with_delay(msg)
            death_idx = death_idx % #death_msgs + 1
        end
        if ui.get(m.killsay_revenge) then revenge_target_userid = e.attacker end
        return
    end

    if ui.get(m.killsay_revenge) and revenge_target_userid and e.userid == revenge_target_userid then
        local killed_by = attacker_ent
        revenge_target_userid = nil
        client.delay_call(0.05, function()
            queue_with_delay("1")
            if killed_by == lp then
                client.delay_call(0.4, function()
                    if not is_spectator() then
                        local msg = format_message(messages[current_idx], victim_ent)
                        queue_with_delay(msg)
                        current_idx = current_idx % #messages + 1
                    end
                end)
            end
        end)
        return
    end

    if attacker_ent == lp and victim_ent ~= lp then
        if e.weapon == "inferno" and ui.get(m.killsay_molly) then
            local msg = format_message(molly_msgs[molly_idx], victim_ent)
            queue_with_delay(msg)
            molly_idx = molly_idx % #molly_msgs + 1
        else
            local msg = format_message(messages[current_idx], victim_ent)
            queue_with_delay(msg)
            current_idx = current_idx % #messages + 1
        end
    end
end

client.set_event_callback("player_disconnect", function(e)
    if ui.get(m.killsay_enabled) and ui.get(m.killsay_revenge) and revenge_target_userid then
        if e.userid == revenge_target_userid and not is_spectator() then
            queue_message("rq")
            revenge_target_userid = nil
        end
    end
end)


-- ==========================================
-- [ BUYBOT ]
-- ==========================================
local buy_cmds = { ["Auto"] = "scar20", ["Scout"] = "ssg08", ["Awp"] = "awp", ["Primary rifle"] = "ak47", ["Scoped rifle"] = "sg556", ["Machine gun"] = "negev", ["Default pistol"] = "glock", ["P250"] = "p250", ["Dual Berettas"] = "elite", ["Light pistol"] = "tec9", ["Heavy pistol"] = "deagle", ["Grenade"] = "hegrenade", ["Smoke"] = "smokegrenade", ["Incendiary"] = "molotov", ["Flashbang"] = "flashbang", ["Kevlar + Helmet"] = "vesthelm", ["Defuse kit"] = "defuser", ["Zeus"] = "taser" }

local function on_round_prestart()
    if not ui.get(m.buybot_enabled) then return end
    local cmds_to_run = {}
    local primary, secondary, utility = ui.get(m.buybot_primary), ui.get(m.buybot_secondary), ui.get(m.buybot_utility)

    if primary ~= "None" and buy_cmds[primary] then table.insert(cmds_to_run, "buy " .. buy_cmds[primary]) end
    if secondary ~= "None" and buy_cmds[secondary] then table.insert(cmds_to_run, "buy " .. buy_cmds[secondary]) end
    if #utility > 0 then
        for i = 1, #utility do if buy_cmds[utility[i]] then table.insert(cmds_to_run, "buy " .. buy_cmds[utility[i]]) end end
    end
    if #cmds_to_run > 0 then client.exec(table.concat(cmds_to_run, "; ")) end
end

-- ==========================================
-- [ QUICK SWITCH E KNIFE RETREAT ]
-- ==========================================
local retreat_data = { is_retreating = false, start_time = 0 }

local function handle_quick_switch(weapon_name)
    if not ui.get(m.quick_switch_enabled) then return end
    local selected_weapons = ui.get(m.quick_switch_select)
    local should_switch = false

    if table_contains(selected_weapons, "AWP") and (weapon_name == "awp" or weapon_name == "weapon_awp") then should_switch = true end
    if table_contains(selected_weapons, "Scout") and (weapon_name == "ssg08" or weapon_name == "weapon_ssg08") then should_switch = true end

    if should_switch then
        client.delay_call(0.02, function()
            client.exec("slot3")
            client.delay_call(0.05, function() client.exec("slot1") end)
        end)
    end
end

-- ==========================================
-- [ CUSTOM NETGRAPH ]
-- ==========================================
local function draw_netgraph()
    if not ui.get(m.netgraph_enabled) then return end
    
    local sw, sh = client.screen_size()
    local fps = math.floor(1 / globals.absoluteframetime())
    local ping = math.floor(client.latency() * 1000)
    local tickrate = math.floor(1 / globals.tickinterval())
    
    local sv = (globals.absoluteframetime() * 1000) + math.random(1, 3)/10
    local var = math.random(1, 5) / 10
    local up = tickrate
    local cmd = tickrate
    local loss = 0
    local choke = 0
    
    local is_mini = ui.get(m.netgraph_size) == "Mini"
    local font_flag = (is_mini and "d" or "") .. "bo"
    
    local x_pct = ui.get(m.netgraph_x) / 100
    local y_pct = ui.get(m.netgraph_y) / 100
    
    local x = math.floor(sw * x_pct)
    local y = math.floor(sh * y_pct)
    
    local gap = is_mini and 10 or 14
    local r, g, b, a = ui.get(m.netgraph_color)
    
    renderer.text(x, y, r, g, b, a, font_flag, 0, string.format("fps: %3d", fps))
    renderer.text(x, y + gap, r, g, b, a, font_flag, 0, string.format("loss: %2d%%", loss))
    renderer.text(x, y + (gap*2), r, g, b, a, font_flag, 0, string.format("tick: %4.1f", tickrate))
    
    local col2 = x + (is_mini and 45 or 65)
    renderer.text(col2, y, r, g, b, a, font_flag, 0, string.format("ping: %d ms", ping))
    renderer.text(col2, y + gap, r, g, b, a, font_flag, 0, string.format("choke: %2d%%", choke))
    renderer.text(col2, y + (gap*2), r, g, b, a, font_flag, 0, string.format("sv: %4.1f + - %.1f ms", sv, var))

    local col3 = x + (is_mini and 130 or 180)
    renderer.text(col3, y + gap, r, g, b, a, font_flag, 0, string.format("up: %4.1f/s", up))
    renderer.text(col3, y + (gap*2), r, g, b, a, font_flag, 0, string.format("cmd: %4.1f/s", cmd))
end

-- ==========================================
-- [ REGISTRO DE EVENTOS E SHUTDOWN ]
-- ==========================================
local cjump_start_time = nil
local cjump_was_active = false
local cjump_jumped = false

local function handle_advanced_aa(cmd)
    if not ui.get(m.aa_enabled) then return end
    
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    local flags = entity.get_prop(me, "m_fFlags")
    local vx, vy = entity.get_prop(me, "m_vecVelocity")
    local speed = math_sqrt(vx * vx + vy * vy)
    local in_air = bit_band(flags, 1) == 0
    local duck_amount = entity.get_prop(me, "m_flDuckAmount")
    
    local current_state = "Stand"
    if in_air then 
        current_state = "Air"
    elseif duck_amount > 0.5 then 
        current_state = "Crouch"
    elseif speed > 5 then 
        current_state = "Move" 
    end
    
    local set = m.aa_settings[current_state]
    
    -- Sync Angles
    if manual_state == 0 then
        ui.set(refs.yaw_slider, ui.get(set.yaw))
    end
    
    ui.set(refs.yaw_jitter[1], ui.get(set.jitter_mode))
    ui.set(refs.yaw_jitter[2], ui.get(set.jitter_range))
    ui.set(refs.body_yaw[1], ui.get(set.body_yaw))
    
    -- Apply Bruteforce Flip
    local target_desync = ui.get(set.desync)
    if bruteforce_flip then target_desync = -target_desync end
    ui.set(refs.body_yaw[2], target_desync)
    
    -- Sync Fake Lag
    ui.set(refs.fl_amount, ui.get(set.fl_amount))
    ui.set(refs.fl_variance, ui.get(set.fl_variance))
    
    -- LC Breaker Logic
    local final_limit = ui.get(set.fl_limit)
    if ui.get(m.lc_breaker) and current_state == "Move" then
        if cmd.command_number % 3 == 0 then
            final_limit = math.max(1, final_limit - math.random(3, 7))
        end
    end
    ui.set(refs.fl_limit, final_limit)
end

local function on_setup_command(cmd)
    handle_nade_dropper(cmd)

    if ui.get(m.crouch_jump_enabled) and globals.mapname() == "de_train" then
        local active = ui.get(m.crouch_jump_hotkey)
        local on_press = active and not cjump_was_active
        if on_press then cjump_start_time = globals.realtime(); cjump_jumped = false end
        cjump_was_active = active

        if cjump_start_time ~= nil then
            local elapsed = (globals.realtime() - cjump_start_time) * 1000
            cmd.in_duck = 1
            if elapsed >= ui.get(m.crouch_jump_delay) and not cjump_jumped then cmd.in_jump = 1; cjump_jumped = true end
            if elapsed >= ui.get(m.crouch_release_delay) then cmd.in_duck = 0; cjump_start_time = nil end
        end
    end

    if retreat_data.is_retreating then
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then retreat_data.is_retreating = false; return end

        local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
        local speed = math_sqrt(vx * vx + vy * vy)
        local time_passed = globals.realtime() - retreat_data.start_time
        local qp_active = ui.get(refs.qpeek[1]) and ui.get(refs.qpeek[2])

        if not qp_active or (time_passed > 0.25 and speed < 25) then client.exec("slot1"); retreat_data.is_retreating = false end
    end
    
    handle_advanced_aa(cmd)
end

client.set_event_callback("paint", function()
    handle_manual_aa()
    draw_manual_aa()
    draw_taser_warning()
    draw_range_rings()
    update_clantag()
    draw_crosshair_hud()
    draw_slowdown_warning()
    draw_stamina_meter()
    draw_screen_logs()
    draw_3d_hitmarkers()
    draw_watermark()
    draw_netgraph()
end)

client.set_event_callback("weapon_fire", function(e)
    local me = entity.get_local_player()
    if client.userid_to_entindex(e.userid) == me then
        anim_data.dt_charge = 0
        local qp_active = ui.get(refs.qpeek[1]) and ui.get(refs.qpeek[2])
        if ui.get(m.knife_retreat_enabled) and qp_active then
            retreat_data.is_retreating = true
            retreat_data.start_time = globals.realtime()
            client.delay_call(0.02, function() client.exec("slot3") end)
        else
            handle_quick_switch(e.weapon)
        end
    end
end)

client.set_event_callback("player_hurt", function(e)
    local me = entity.get_local_player()
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    
    if attacker == me and victim ~= me then
        if e.health > 0 then
            if ui.get(m.hitsound_enabled) then play_custom_sound("hit") end
        end
    end
end)

client.set_event_callback("setup_command", on_setup_command)
client.set_event_callback("player_death", function(e)
    on_killsay_player_death(e)
    on_player_death_sparkles(e)
end)
client.set_event_callback("round_prestart", on_round_prestart)
client.set_event_callback("aim_fire", on_aim_fire)
client.set_event_callback("aim_hit", on_aim_hit)
client.set_event_callback("aim_miss", on_aim_miss)

client.set_event_callback("shutdown", function()
    reset_clantag()
    cvar.r_aspectratio:set_raw_float(orig_cvars.ar)
    cvar.viewmodel_presetpos:set_raw_int(orig_cvars.preset)
    cvar.viewmodel_fov:set_raw_float(orig_cvars.fov)
    cvar.viewmodel_offset_x:set_raw_float(orig_cvars.x)
    cvar.viewmodel_offset_y:set_raw_float(orig_cvars.y)
    cvar.viewmodel_offset_z:set_raw_float(orig_cvars.z)
end)
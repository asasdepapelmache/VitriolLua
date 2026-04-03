--[[
    =============================================
                 Vitriol.lua by larihvh
    =============================================
]]

local TAB, CONTAINER = "LUA", "B"
local ffi = require("ffi")

local function get_refs(...) return { ui.reference(...) } end

local ref_dt = get_refs("Rage", "Aimbot", "Double tap")
local ref_hs = get_refs("AA", "Other", "On shot anti-aim")
local ref_fd = get_refs("Rage", "Other", "Duck peek assist")
local ref_baim = get_refs("Rage", "Aimbot", "Force body aim")
local ref_sp = get_refs("Rage", "Aimbot", "Force safe point")
local ref_fs = get_refs("AA", "Anti-aimbot angles", "Freestanding")
local ref_dmg = get_refs("RAGE", "Aimbot", "Minimum damage")
local ref_ovr = get_refs("RAGE", "Aimbot", "Minimum damage override")
local ref_qpeek = get_refs("Rage", "Other", "Quick peek assist")

-- ==========================================
-- [ FFI - SPARKLES SETUP ]
-- ==========================================
ffi.cdef [[
    struct spark_vec3_t { float x, y, z; };
    typedef void(__fastcall*FX_ElectricSparkFn)(const struct spark_vec3_t*, int, int, const struct spark_vec3_t*);
]]
local FX_ElectricSpark = ffi.cast("FX_ElectricSparkFn",
    client.find_signature("client.dll",
        "\x55\x8B\xEC\x83\xEC\x3C\x53\x8B\xD9\x89\x55\xFC\x8B\x0D\xCC\xCC\xCC\xCC\x56\x57"))
local spark_material = nil
pcall(function()
    if materialsystem then
        spark_material = materialsystem.find_material("effects/spark", true)
    elseif materials then
        spark_material = materials.find("effects/spark")
    end
end)


-- ==========================================
-- [ MENU UI ]
-- ==========================================
ui.new_label(TAB, CONTAINER, "====== [ Vitriol.lua ] ======")

-- Clantag
ui.new_label(TAB, CONTAINER, "--- Clantag ---")
local clantag_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Vitriol.lua Clantag")
local clantag_type = ui.new_combobox(TAB, CONTAINER, "Clantag Type", { "Animated", "Static" })
local clantag_speed = ui.new_slider(TAB, CONTAINER, "Animation Speed", 1, 10, 3, true, "s", 0.1)
local clantag_sync = ui.new_button(TAB, CONTAINER, "Sync Clantag", function() end)

-- Crosshair Indicators
ui.new_label(TAB, CONTAINER, "--- Indicators ---")
local hud_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Crosshair HUD")
local hud_style = ui.new_combobox(TAB, CONTAINER, "HUD Text Style", { "Normal", "Bold" })
local hud_color = ui.new_color_picker(TAB, CONTAINER, "HUD Accent Color", 255, 105, 180, 255)

-- Logs na Tela, Hitmarker & Sparkles
ui.new_label(TAB, CONTAINER, "--- Visuals ---")
local logs_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Event Logs")
local logs_pos_ui = ui.new_combobox(TAB, CONTAINER, "Screen Logs Position", { "Left (Default)", "Neverlose", "Center" })

local hitmarker_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable 3D Heart Hitmarker")
local hitmarker_style = ui.new_combobox(TAB, CONTAINER, "Hitmarker Style", { "Text (<3)", "Icon (❤)", "Damage Number" })

local slowdown_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Slowdown Warning")
local slowdown_color = ui.new_color_picker(TAB, CONTAINER, "Slowdown Accent Color", 255, 105, 180, 255)

local sparkles_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Death Sparkles")
local sparkles_color = ui.new_color_picker(TAB, CONTAINER, "Sparkle Color", 255, 255, 255, 255)
local sparkles_radius = ui.new_slider(TAB, CONTAINER, "Sparkle Radius", 3, 10, 3)
local sparkles_length = ui.new_slider(TAB, CONTAINER, "Sparkle Length", 1, 10, 2)


-- Trash Talk
ui.new_label(TAB, CONTAINER, "--- Trash Talk ---")
local killsay_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Trash Talk")
local killsay_name = ui.new_checkbox(TAB, CONTAINER, "Name on Killsay")
local killsay_death = ui.new_checkbox(TAB, CONTAINER, "Enable Deathsay (When you die)")
local killsay_molly = ui.new_checkbox(TAB, CONTAINER, "Enable Molotov Say")
local killsay_revenge = ui.new_checkbox(TAB, CONTAINER, "Enable Revenge Say")
local killsay_delay = ui.new_slider(TAB, CONTAINER, "Message Delay (s)", 0, 5, 0, true, "s", 1)

-- Buybot
ui.new_label(TAB, CONTAINER, "--- Buybot ---")
local buybot_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Buybot")
local buybot_primary = ui.new_combobox(TAB, CONTAINER, "Primary weapon",
    { "None", "Auto", "Scout", "Awp", "Primary rifle", "Scoped rifle", "Machine gun" })
local buybot_secondary = ui.new_combobox(TAB, CONTAINER, "Secondary weapon",
    { "None", "Default pistol", "P250", "Dual Berettas", "Light pistol", "Heavy pistol" })
local buybot_utility = ui.new_multiselect(TAB, CONTAINER, "Utility",
    { "Grenade", "Smoke", "Incendiary", "Flashbang", "Kevlar + Helmet", "Defuse kit", "Zeus" })

-- Misc
ui.new_label(TAB, CONTAINER, "--- Misc ---")
local drop_nades_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Nade Dropper")
local drop_nades_hotkey = ui.new_hotkey(TAB, CONTAINER, "Nade Dropper Hotkey", true)
local drop_nades_select = ui.new_multiselect(TAB, CONTAINER, "Nades to drop",
    { "HE", "Smoke", "Molotov", "Flashbang", "Decoy" })

local quick_switch_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Quick Switch")
local quick_switch_select = ui.new_multiselect(TAB, CONTAINER, "Quick Switch Weapons", { "AWP", "Scout" })
local knife_retreat_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Knife Retreat (Auto Peek)")
local sync_hotkeys_enabled = ui.new_checkbox(TAB, CONTAINER, "Sync Ragebot Hotkeys")

ui.new_label(TAB, CONTAINER, "=========================")


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

ui.set_callback(clantag_sync, function()
    current_frame = 1
    last_update_time = globals.realtime()
end)

local function update_clantag()
    if not ui.get(clantag_enabled) then return end

    if ui.get(clantag_type) == "Static" then
        set_tag(static_tag)
        return
    end

    local current_time = globals.realtime()
    local speed = ui.get(clantag_speed) * 0.1

    if current_time - last_update_time >= speed then
        set_tag(clantag_frames[current_frame])
        current_frame = current_frame + 1

        if current_frame > #clantag_frames then
            current_frame = 1
        end
        last_update_time = current_time
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
    -- Clantag
    local c_state = ui.get(clantag_enabled)
    local c_type = ui.get(clantag_type)
    ui.set_visible(clantag_type, c_state)
    ui.set_visible(clantag_speed, c_state and c_type == "Animated")
    ui.set_visible(clantag_sync, c_state and c_type == "Animated")

    -- HUD
    local h_state = ui.get(hud_enabled)
    ui.set_visible(hud_style, h_state)
    ui.set_visible(hud_color, h_state)

    -- Visuals
    local hm_state = ui.get(hitmarker_enabled)
    ui.set_visible(hitmarker_style, hm_state)
    local sd_state = ui.get(slowdown_enabled)
    ui.set_visible(slowdown_color, sd_state)

    local lg_state = ui.get(logs_enabled)
    ui.set_visible(logs_pos_ui, lg_state)

    local sp_state = ui.get(sparkles_enabled)
    ui.set_visible(sparkles_color, sp_state)
    ui.set_visible(sparkles_radius, sp_state)
    ui.set_visible(sparkles_length, sp_state)

    -- Trash Talk
    local k_state = ui.get(killsay_enabled)
    ui.set_visible(killsay_name, k_state)
    ui.set_visible(killsay_death, k_state)
    ui.set_visible(killsay_molly, k_state)
    ui.set_visible(killsay_revenge, k_state)
    ui.set_visible(killsay_delay, k_state)

    -- Buybot
    local b_state = ui.get(buybot_enabled)
    ui.set_visible(buybot_primary, b_state)
    ui.set_visible(buybot_secondary, b_state)
    ui.set_visible(buybot_utility, b_state)

    -- Misc
    local m_state = ui.get(drop_nades_enabled)
    ui.set_visible(drop_nades_hotkey, m_state)
    ui.set_visible(drop_nades_select, m_state)

    local qs_state = ui.get(quick_switch_enabled)
    ui.set_visible(quick_switch_select, qs_state)
end

ui.set_callback(clantag_enabled, function()
    handle_menu()
    if not ui.get(clantag_enabled) then
        reset_clantag()
    end
end)

-- Callbacks Normais
ui.set_callback(clantag_type, handle_menu)
ui.set_callback(hud_enabled, handle_menu)
ui.set_callback(hitmarker_enabled, handle_menu)
ui.set_callback(slowdown_enabled, handle_menu)
ui.set_callback(logs_enabled, handle_menu)
ui.set_callback(sparkles_enabled, handle_menu)
ui.set_callback(killsay_enabled, handle_menu)
ui.set_callback(buybot_enabled, handle_menu)
ui.set_callback(drop_nades_enabled, handle_menu)
ui.set_callback(quick_switch_enabled, handle_menu)

handle_menu()


-- ==========================================
-- [ UTILS ]
-- ==========================================
local function trim_string(s) return s:match("^%s*(.-)%s*$") end
local function lerp(a, b, t) return a + (b - a) * t end

local function is_active(refs)
    if not refs or refs[1] == nil then return false end
    local val = ui.get(refs[1])
    local enabled = false

    if type(val) == "boolean" then
        enabled = val
    elseif type(val) == "table" then
        enabled = #val > 0
    elseif type(val) == "string" then
        enabled = (val ~= "Off" and val ~= "-")
    else
        enabled = true
    end

    if not enabled then return false end

    if refs[2] ~= nil and type(ui.get(refs[2])) == "boolean" then
        return ui.get(refs[2])
    end

    return true
end

local function table_contains(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then return true end
    end
    return false
end

-- ==========================================
-- [ RAGEBOT HOTKEY SYNC ]
-- ==========================================
local syncing = true

local hotkey_type_names = {
    [0] = "Always on",
    "On hotkey",
    "Toggle",
    "Off hotkey"
}

local weapon_names = {
    "Global", "G3SG1 / SCAR-20", "SSG 08", "AWP", "R8 Revolver",
    "Desert Eagle", "Pistol", "Zeus", "Rifle", "Shotgun", "SMG", "Machine gun"
}

local weapon_type_ref = ui.reference("RAGE", "Weapon type", "Weapon type")

local function sync_hotkey_to_all(ref)
    if not syncing or not ui.get(sync_hotkeys_enabled) then return end

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
    select(2, ui.reference("RAGE", "Aimbot", "Enabled")),
    select(2, ui.reference("RAGE", "Aimbot", "Multi-point")),
    select(2, ui.reference("RAGE", "Aimbot", "Minimum damage override")),
    select(1, ui.reference("RAGE", "Aimbot", "Force safe point")),
    select(1, ui.reference("RAGE", "Aimbot", "Force body aim")),
    select(2, ui.reference("RAGE", "Aimbot", "Quick stop")),
    select(2, ui.reference("RAGE", "Aimbot", "Double tap")),
}

for i = 1, #sync_refs do
    local ref = sync_refs[i]
    if ui.type(ref) == "hotkey" then
        ui.set_callback(ref, function()
            sync_hotkey_to_all(ref)
        end)
    end
end

client.set_event_callback("pre_config_load", function() syncing = false end)
client.set_event_callback("post_config_load", function() syncing = true end)


-- ==========================================
-- [ NADE DROPPER ]
-- ==========================================
local nade_mappings = {
    ["CHEGrenade"] = { cmd = "weapon_hegrenade", menu = "HE" },
    ["CSmokeGrenade"] = { cmd = "weapon_smokegrenade", menu = "Smoke" },
    ["CMolotovGrenade"] = { cmd = "weapon_molotov", menu = "Molotov" },
    ["CIncendiaryGrenade"] = { cmd = "weapon_incgrenade", menu = "Molotov" },
    ["CFlashbang"] = { cmd = "weapon_flashbang", menu = "Flashbang" },
    ["CDecoyGrenade"] = { cmd = "weapon_decoy", menu = "Decoy" }
}

local nade_drop_queue = {}
local nade_drop_throwing = false
local nade_drop_old_state = false

local function handle_nade_dropper(cmd)
    if not ui.get(drop_nades_enabled) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local state = ui.get(drop_nades_hotkey)
    if state and not nade_drop_old_state and not nade_drop_throwing then
        nade_drop_queue = {}
        local selected = ui.get(drop_nades_select)

        for i = 0, 63 do
            local weapon_ent = entity.get_prop(me, "m_hMyWeapons", i)
            if weapon_ent and weapon_ent ~= 0 and weapon_ent ~= -1 then
                local class_name = entity.get_classname(weapon_ent)
                local mapped = nade_mappings[class_name]
                if mapped and table_contains(selected, mapped.menu) then
                    table.insert(nade_drop_queue, mapped.cmd)
                end
            end
        end

        if #nade_drop_queue > 0 then
            nade_drop_throwing = true
        end
    end
    nade_drop_old_state = state

    if #nade_drop_queue > 0 then
        local latency = client.latency() + (globals.tickinterval() * 4)

        for i, weapon_cmd in ipairs(nade_drop_queue) do
            local is_last = (i == #nade_drop_queue)
            client.delay_call(latency * i, function()
                client.exec("use " .. weapon_cmd .. "; drop")
                if is_last then
                    client.delay_call(0.1, function()
                        nade_drop_throwing = false
                    end)
                end
            end)
        end
        nade_drop_queue = {}
    end

    if nade_drop_throwing then
        local pitch, yaw = client.camera_angles()
        local offset = pitch > 0 and -0.0001 or 0.0001
        cmd.yaw = yaw
        cmd.pitch = pitch + offset
        cmd.no_choke = true
        cmd.allow_send_packet = true
    end
end


-- ==========================================
-- [ INDICADORES DA HUD E SLOWDOWN ]
-- ==========================================
local anim_data = { dt = 0, dt_charge = 1.0, hs = 0, fs = 0, fd = 0, baim = 0, sp = 0 }
local dmg_anim = { val = 0, r = 220, g = 180, b = 255 }
local bit_band = bit.band
local math_sqrt = math.sqrt
local slowdown_anim_alpha = 0

local function draw_slowdown_warning()
    if not ui.get(slowdown_enabled) then return end
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

    local r, g, b, a = ui.get(slowdown_color)
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

    local style = ui.get(hud_style)
    local flag = "c"
    if style == "Normal" then
        flag = "c"
    elseif style == "Bold" then
        flag = "cb"
    end

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
    if not ui.get(hud_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local sw, sh = client.screen_size()
    local cx = sw / 2
    local cy = sh / 2
    local y_offset = cy + 25
    local frametime = globals.frametime() * 8
    local r, g, b, a = ui.get(hud_color)

    local style = ui.get(hud_style)
    local flag = "c"
    if style == "Normal" then
        flag = "c"
    elseif style == "Bold" then
        flag = "cb"
    end

    local weapon_ent = entity.get_player_weapon(me)
    if weapon_ent then
        local weapon_class = entity.get_classname(weapon_ent) or ""
        local is_knife = weapon_class:find("Knife") or weapon_class:find("Bayonet")
        local is_grenade = weapon_class:find("Grenade") or weapon_class:find("Flashbang") or
            weapon_class:find("Molotov") or weapon_class:find("Decoy") or
            weapon_class:find("Smoke") or weapon_class:find("Incendiary")

        if not is_knife and not is_grenade then
            local normal_dmg = 1
            if ref_dmg[1] ~= nil then normal_dmg = ui.get(ref_dmg[1]) end

            local is_override_active = false
            local override_dmg = 1
            if #ref_ovr == 2 then
                is_override_active = ui.get(ref_ovr[1])
                override_dmg = ui.get(ref_ovr[2])
            elseif #ref_ovr == 3 then
                is_override_active = ui.get(ref_ovr[2])
                override_dmg = ui.get(ref_ovr[3])
            end

            local target_dmg = is_override_active and override_dmg or normal_dmg

            dmg_anim.val = lerp(dmg_anim.val, target_dmg, globals.frametime() * 25)
            if math.abs(dmg_anim.val - target_dmg) < 0.5 then dmg_anim.val = target_dmg end

            local display_num = math.floor(dmg_anim.val + 0.5)
            local display_text = ""
            if display_num == 0 then
                display_text = "Auto"
            elseif display_num > 100 then
                display_text = "HP+" .. tostring(display_num - 100)
            else
                display_text = tostring(display_num)
            end

            local target_r, target_g, target_b = 220, 180, 255
            if is_override_active then target_r, target_g, target_b = 255, 105, 180 end

            dmg_anim.r = lerp(dmg_anim.r, target_r, globals.frametime() * 15)
            dmg_anim.g = lerp(dmg_anim.g, target_g, globals.frametime() * 15)
            dmg_anim.b = lerp(dmg_anim.b, target_b, globals.frametime() * 15)

            local dmg_x = cx + 12
            local dmg_y = cy - 15
            renderer.text(dmg_x + 1, dmg_y + 1, 10, 10, 10, math.floor(a * 0.8), flag, 0, display_text)
            renderer.text(dmg_x, dmg_y, math.floor(dmg_anim.r), math.floor(dmg_anim.g), math.floor(dmg_anim.b), a, flag,
                0, display_text)
        end
    end

    y_offset = draw_indicator(cx, y_offset, r, g, b, a, "VITRIOL", 1.0)
    y_offset = y_offset + 2

    local is_dt = is_active(ref_dt)
    local is_hs = is_active(ref_hs)
    local is_fs = is_active(ref_fs)
    local is_fd = is_active(ref_fd)
    local is_baim = is_active(ref_baim)
    local is_sp = is_active(ref_sp)

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
    if bit_band(flags, 1) == 0 then
        state = duck_amount > 0.5 and "AIR-C" or "AIR"
    elseif duck_amount > 0.5 then
        state = speed > 5 and "CROUCH-M" or "CROUCH"
    elseif speed > 5 then
        state = "MOVE"
    end

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
local hitgroup_names = {
    "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"
}

local aim_data = {}
local screen_logs = {}
local hit_markers = {}
local max_logs = 6

local function add_screen_log(text, color)
    table.insert(screen_logs, 1, { text = text, color = color, time = globals.realtime(), alpha = 0 })
    if #screen_logs > max_logs then table.remove(screen_logs, #screen_logs) end
end

local function draw_screen_logs()
    if not ui.get(logs_enabled) or #screen_logs == 0 then return end

    local sw, sh = client.screen_size()
    local pos_style = ui.get(logs_pos_ui)
    local current_time = globals.realtime()

    local base_x, base_y = 10, sh / 2 + 100
    local align_right = false
    local center_x = false
    local stack_dir = -1

    if pos_style == "Neverlose" then
        base_x = 10
        base_y = 10
        stack_dir = 1
    elseif pos_style == "Center" then
        center_x = true
        base_y = sh / 2 + 200
    end

    local y = base_y

    for i = #screen_logs, 1, -1 do
        local log = screen_logs[i]
        local time_alive = current_time - log.time

        if time_alive < 0.2 then
            log.alpha = time_alive / 0.2
        elseif time_alive > 4.8 then
            log.alpha = 1.0 - ((time_alive - 4.8) / 0.2)
        else
            log.alpha = 1.0
        end

        if time_alive > 5.0 then
            table.remove(screen_logs, i)
        else
            local a = math.max(0, math.floor(log.alpha * 255))
            local tw, th = renderer.measure_text("", log.text)
            local box_w = tw + 20
            local draw_x = base_x

            if center_x then
                draw_x = (sw / 2) - (box_w / 2)
            end

            renderer.rectangle(draw_x, y, box_w, 20, 15, 15, 15, math.floor(a * 0.6))
            renderer.rectangle(draw_x, y, 2, 20, log.color[1], log.color[2], log.color[3], a)
            renderer.text(draw_x + 5, y + 4, log.color[1], log.color[2], log.color[3], a, "", 0, "❤")
            renderer.text(draw_x + 18, y + 4, 255, 255, 255, a, "", 0, log.text)
            y = y + (22 * stack_dir)
        end
    end
end

local function draw_3d_hitmarkers()
    if not ui.get(hitmarker_enabled) or #hit_markers == 0 then return end

    local style = ui.get(hitmarker_style)
    local is_dmg = style == "Damage Number"
    local symbol = style == "Icon (❤)" and "❤" or "<3"
    local flag = style == "Icon (❤)" and "c" or "cb"

    local current_time = globals.realtime()
    for i = #hit_markers, 1, -1 do
        local marker = hit_markers[i]
        local time_alive = current_time - marker.time

        if time_alive > 1.5 then
            table.remove(hit_markers, i)
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
    aim_data[e.id] = {
        target = e.target,
        hit_chance = e.hit_chance,
        damage = e.damage,
        backtrack = globals.tickcount() - e.tick,
        x = e.x,
        y = e.y,
        z = e.z
    }
end

local function on_aim_hit(e)
    local data = aim_data[e.id]
    if not data then return end

    if ui.get(hitmarker_enabled) and data.x and data.y and data.z then
        table.insert(hit_markers, { x = data.x, y = data.y, z = data.z, time = globals.realtime(), damage = e.damage })
    end

    if not ui.get(logs_enabled) then return end
    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
    local hp_left = entity.get_prop(e.target, "m_iHealth")
    local log_text = string.format("Hit %s in the %s for %d dmg (hc: %d%% | bt: %d) [hp: %d]", target_name, hitgroup,
        e.damage, math.floor(data.hit_chance), data.backtrack, hp_left)

    print("[Vitriol.lua] " .. log_text)
    add_screen_log(log_text, { 255, 105, 180 })
end

local function on_aim_miss(e)
    if not ui.get(logs_enabled) then return end
    local data = aim_data[e.id]
    if not data then return end
    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
    local log_text = string.format("Missed %s's %s due to %s (hc: %d%% | bt: %d)", target_name, hitgroup, e.reason,
        math.floor(data.hit_chance), data.backtrack)

    print("[Vitriol.lua] " .. log_text)
    add_screen_log(log_text, { 200, 60, 60 })
end

-- ==========================================
-- [ DEATH SPARKLES ]
-- ==========================================
local function on_player_death_sparkles(e)
    if not ui.get(sparkles_enabled) then return end
    local lp = entity.get_local_player()
    if not lp then return end
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    if not victim then return end

    if attacker == lp and victim ~= lp then
        local radius = ui.get(sparkles_radius)
        local length = ui.get(sparkles_length)
        local r, g, b, a = ui.get(sparkles_color)

        if spark_material then
            pcall(function()
                if spark_material.alpha_modulate then
                    spark_material:alpha_modulate(a)
                    spark_material:color_modulate(r, g, b)
                end
            end)
        end

        local vx, vy, vz = entity.get_prop(victim, "m_vecOrigin")
        if vx and vy and vz then
            -- Altura do peito/cabeça
            local pos = ffi.new("struct spark_vec3_t", { vx, vy, vz + 40 })
            local dir = ffi.new("struct spark_vec3_t", { 0, 0, 0 })
            FX_ElectricSpark(pos, radius, length, dir)
        end
    end
end


-- ==========================================
-- [ TRASH TALK ]
-- ==========================================
local messages = { "VITRIOL.lua dissolve voce", "Vitriol.lua > ALL :3", "Deita ai random", "Owned by Vitriol.lua ♡",
    "voce foi ownado", "voce foi dissolvido" }
local molly_msgs = { "Churrasco de random kkk", "Assado vivo", "Fogo na inveja", "Virou cinza kkk", "Dançando no fogo" }
local death_msgs = { "Sério isso? kk", "Cagada do século", "Milagre arrombado", "Aí é foda",
    "Sorte kkk da próxima te deito", "Isso foi clutch?", "Era free kill" }

local current_idx, molly_idx, death_idx = 1, 1, 1
local revenge_target_userid = nil

local next_chat_time = 0

local function is_spectator()
    local lp = entity.get_local_player()
    return not lp or entity.get_prop(lp, "m_iTeamNum") == 1
end

local function format_message(msg, victim_ent)
    if ui.get(killsay_name) and victim_ent then
        local victim_name = trim_string(entity.get_player_name(victim_ent) or "voce")
        msg = msg:gsub("voce", victim_name)
    end
    return msg
end

local function queue_message(msg)
    local current_time = globals.realtime()

    if next_chat_time < current_time then
        next_chat_time = current_time
    end

    local delay_to_exec = next_chat_time - current_time
    next_chat_time = next_chat_time + 0.85

    if delay_to_exec <= 0.01 then
        client.exec('say "' .. msg .. '"')
    else
        client.delay_call(delay_to_exec, function()
            client.exec('say "' .. msg .. '"')
        end)
    end
end

local function queue_with_delay(msg)
    local user_delay = ui.get(killsay_delay)
    if user_delay <= 0.01 then
        queue_message(msg)
    else
        client.delay_call(user_delay, function() queue_message(msg) end)
    end
end

local function on_killsay_player_death(e)
    if not ui.get(killsay_enabled) or is_spectator() then return end

    local lp = entity.get_local_player()
    local attacker_ent = client.userid_to_entindex(e.attacker)
    local victim_ent = client.userid_to_entindex(e.userid)

    if victim_ent == lp and attacker_ent ~= lp and attacker_ent then
        if ui.get(killsay_death) then
            local msg = format_message(death_msgs[death_idx], attacker_ent)
            queue_with_delay(msg)
            death_idx = death_idx % #death_msgs + 1
        end
        if ui.get(killsay_revenge) then
            revenge_target_userid = e.attacker
        end
        return
    end

    if ui.get(killsay_revenge) and revenge_target_userid and e.userid == revenge_target_userid then
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
        if e.weapon == "inferno" and ui.get(killsay_molly) then
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
    if ui.get(killsay_enabled) and ui.get(killsay_revenge) and revenge_target_userid then
        if e.userid == revenge_target_userid and not is_spectator() then
            queue_message("rq")
            revenge_target_userid = nil
        end
    end
end)


-- ==========================================
-- [ BUYBOT ]
-- ==========================================
local buy_cmds = {
    ["Auto"] = "scar20",
    ["Scout"] = "ssg08",
    ["Awp"] = "awp",
    ["Primary rifle"] = "ak47",
    ["Scoped rifle"] = "sg556",
    ["Machine gun"] = "negev",
    ["Default pistol"] = "glock",
    ["P250"] = "p250",
    ["Dual Berettas"] = "elite",
    ["Light pistol"] = "tec9",
    ["Heavy pistol"] = "deagle",
    ["Grenade"] = "hegrenade",
    ["Smoke"] = "smokegrenade",
    ["Incendiary"] = "molotov",
    ["Flashbang"] = "flashbang",
    ["Kevlar + Helmet"] = "vesthelm",
    ["Defuse kit"] = "defuser",
    ["Zeus"] = "taser"
}

local function on_round_prestart()
    if not ui.get(buybot_enabled) then return end
    local cmds_to_run = {}
    local primary, secondary, utility = ui.get(buybot_primary), ui.get(buybot_secondary), ui.get(buybot_utility)

    if primary ~= "None" and buy_cmds[primary] then table.insert(cmds_to_run, "buy " .. buy_cmds[primary]) end
    if secondary ~= "None" and buy_cmds[secondary] then table.insert(cmds_to_run, "buy " .. buy_cmds[secondary]) end
    if #utility > 0 then
        for i = 1, #utility do
            if buy_cmds[utility[i]] then table.insert(cmds_to_run, "buy " .. buy_cmds[utility[i]]) end
        end
    end
    if #cmds_to_run > 0 then client.exec(table.concat(cmds_to_run, "; ")) end
end

-- ==========================================
-- [ QUICK SWITCH E KNIFE RETREAT ]
-- ==========================================
local retreat_data = {
    is_retreating = false,
    start_time = 0
}

local function handle_quick_switch(weapon_name)
    if not ui.get(quick_switch_enabled) then return end

    local selected_weapons = ui.get(quick_switch_select)
    local should_switch = false

    if table_contains(selected_weapons, "AWP") and (weapon_name == "awp" or weapon_name == "weapon_awp") then should_switch = true end
    if table_contains(selected_weapons, "Scout") and (weapon_name == "ssg08" or weapon_name == "weapon_ssg08") then should_switch = true end

    if should_switch then
        client.delay_call(0.02, function()
            client.exec("slot3")
            client.delay_call(0.05, function()
                client.exec("slot1")
            end)
        end)
    end
end

-- ==========================================
-- [ REGISTRO DE EVENTOS E SHUTDOWN ]
-- ==========================================
local function on_setup_command(cmd)
    handle_nade_dropper(cmd)

    if retreat_data.is_retreating then
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            retreat_data.is_retreating = false
            return
        end

        local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
        local speed = math.sqrt(vx * vx + vy * vy)
        local time_passed = globals.realtime() - retreat_data.start_time

        local qp_active = ui.get(ref_qpeek[1]) and ui.get(ref_qpeek[2])

        if not qp_active or (time_passed > 0.25 and speed < 25) then
            client.exec("slot1")
            retreat_data.is_retreating = false
        end
    end
end

client.set_event_callback("paint", function()
    update_clantag()
    draw_crosshair_hud()
    draw_slowdown_warning()
    draw_screen_logs()
    draw_3d_hitmarkers()
end)

client.set_event_callback("weapon_fire", function(e)
    local me = entity.get_local_player()
    if client.userid_to_entindex(e.userid) == me then
        anim_data.dt_charge = 0

        local qp_active = ui.get(ref_qpeek[1]) and ui.get(ref_qpeek[2])
        if ui.get(knife_retreat_enabled) and qp_active then
            retreat_data.is_retreating = true
            retreat_data.start_time = globals.realtime()

            client.delay_call(0.02, function()
                client.exec("slot3")
            end)
        else
            handle_quick_switch(e.weapon)
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
client.set_event_callback("shutdown", reset_clantag)

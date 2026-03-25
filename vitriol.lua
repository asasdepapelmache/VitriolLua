--[[
    =============================================
                 Vitriol.lua
    =============================================
]]

local TAB, CONTAINER = "LUA", "B"

-- Referências Nativas do Gamesense
local ref_dt, ref_dt_key = ui.reference("Rage", "Aimbot", "Double tap")
local ref_hs, ref_hs_key = ui.reference("AA", "Other", "On shot anti-aim")
local ref_fd = ui.reference("Rage", "Other", "Duck peek assist")
local ref_baim = ui.reference("Rage", "Aimbot", "Force body aim")
local ref_sp = ui.reference("Rage", "Aimbot", "Force safe point")


-- ==========================================
-- [ MENU UI ]
-- ==========================================
ui.new_label(TAB, CONTAINER, "====== [ Vitriol.lua ] ======")

-- Clantag
ui.new_label(TAB, CONTAINER, "--- Clantag ---")
local clantag_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Vitriol.lua Clantag")
local clantag_type = ui.new_combobox(TAB, CONTAINER, "Clantag Type", { "Animated", "Static" })
local clantag_speed = ui.new_slider(TAB, CONTAINER, "Animation Speed", 1, 10, 3, true, "s", 0.1)

-- Crosshair Indicators
ui.new_label(TAB, CONTAINER, "--- Indicators ---")
local hud_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Crosshair HUD")
local hud_color = ui.new_color_picker(TAB, CONTAINER, "HUD Accent Color", 185, 130, 255, 255)

-- Logs na Tela
ui.new_label(TAB, CONTAINER, "--- On-Screen Logs ---")
local logs_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Event Logs")

-- Killsay
ui.new_label(TAB, CONTAINER, "--- Killsay ---")
local killsay_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Killsay")
local killsay_delay = ui.new_slider(TAB, CONTAINER, "Delay (s)", 0, 5, 0, true, "s", 1)
local killsay_team = ui.new_checkbox(TAB, CONTAINER, "Use Team Chat")

-- Buybot
ui.new_label(TAB, CONTAINER, "--- Buybot ---")
local buybot_enabled = ui.new_checkbox(TAB, CONTAINER, "Enable Buybot")
local buybot_primary = ui.new_combobox(TAB, CONTAINER, "Primary weapon",
    { "None", "Auto", "Scout", "Awp", "Primary rifle", "Scoped rifle", "Machine gun" })
local buybot_secondary = ui.new_combobox(TAB, CONTAINER, "Secondary weapon",
    { "None", "Default pistol", "P250", "Dual Berettas", "Light pistol", "Heavy pistol" })
local buybot_utility = ui.new_multiselect(TAB, CONTAINER, "Utility",
    { "Grenade", "Smoke", "Incendiary", "Flashbang", "Kevlar + Helmet", "Defuse kit", "Zeus" })

ui.new_label(TAB, CONTAINER, "=========================")


-- ==========================================
-- [ VISIBILITY HANDLER ]
-- ==========================================
local function handle_menu()
    local c_state = ui.get(clantag_enabled)
    ui.set_visible(clantag_type, c_state)
    ui.set_visible(clantag_speed, c_state and ui.get(clantag_type) == "Animated")

    local hud_state = ui.get(hud_enabled)
    ui.set_visible(hud_color, hud_state)

    local k_state = ui.get(killsay_enabled)
    ui.set_visible(killsay_delay, k_state)
    ui.set_visible(killsay_team, k_state)

    local b_state = ui.get(buybot_enabled)
    ui.set_visible(buybot_primary, b_state)
    ui.set_visible(buybot_secondary, b_state)
    ui.set_visible(buybot_utility, b_state)
end

ui.set_callback(clantag_enabled, handle_menu)
ui.set_callback(clantag_type, handle_menu)
ui.set_callback(hud_enabled, handle_menu)
ui.set_callback(killsay_enabled, handle_menu)
ui.set_callback(buybot_enabled, handle_menu)
handle_menu()


-- ==========================================
-- [ LÓGICA DOS INDICADORES (HUD) ]
-- ==========================================
local function draw_indicator(x, y, r, g, b, a, text, value)
    if value <= 0 then return y end
    local current_alpha = math.floor(a * value)

    renderer.text(x + 1, y + 1, 10, 10, 10, current_alpha, "-c", 0, text)
    renderer.text(x, y, r, g, b, current_alpha, "-c", 0, text)

    return y + (12 * value)
end

local anim_data = { dt = 0, hs = 0, fd = 0, baim = 0, sp = 0 }
local bit_band = bit.band
local math_sqrt = math.sqrt

local function draw_crosshair_hud()
    if not ui.get(hud_enabled) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local sw, sh = client.screen_size()
    local cx = sw / 2
    local y_offset = (sh / 2) + 25
    local frametime = globals.frametime() * 8

    local r, g, b, a = ui.get(hud_color)

    y_offset = draw_indicator(cx, y_offset, r, g, b, a, "V I T R I O L", 1.0)
    y_offset = y_offset + 2

    local is_dt = ui.get(ref_dt) and ui.get(ref_dt_key)
    local is_hs = ui.get(ref_hs) and ui.get(ref_hs_key)
    local is_fd = ui.get(ref_fd)
    local is_baim = ui.get(ref_baim)
    local is_sp = ui.get(ref_sp)

    anim_data.dt = math.max(0, math.min(1, anim_data.dt + (is_dt and frametime or -frametime)))
    anim_data.hs = math.max(0, math.min(1, anim_data.hs + (is_hs and frametime or -frametime)))
    anim_data.fd = math.max(0, math.min(1, anim_data.fd + (is_fd and frametime or -frametime)))
    anim_data.baim = math.max(0, math.min(1, anim_data.baim + (is_baim and frametime or -frametime)))
    anim_data.sp = math.max(0, math.min(1, anim_data.sp + (is_sp and frametime or -frametime)))

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

    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "DT", anim_data.dt)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "HS", anim_data.hs)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "FD", anim_data.fd)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "BAIM", anim_data.baim)
    y_offset = draw_indicator(cx, y_offset, 200, 200, 200, a, "SAFE", anim_data.sp)
end


-- ==========================================
-- [ LÓGICA DO CLANTAG ]
-- ==========================================
local clantag_frames = {
    " ", "V", "Vi", "Vit", "Vitr", "Vitri", "Vitrio", "Vitriol", "Vitriol.", "Vitriol.l", "Vitriol.lu", "Vitriol.lua",
    "Vitriol.lua :3", "Vitriol.lua <3", "Vitriol.lua ♡", "Vitriol.lua ♡", "Vitriol.lua <3", "Vitriol.lua :3",
    "Vitriol.lua", "Vitriol.lu", "Vitriol.l", "Vitriol.", "Vitriol", "Vitrio", "Vitri", "Vitr", "Vit", "Vi", "V", " "
}

local current_frame = 1
local last_update_time = globals.realtime()
local current_server_tag = ""

-- Função otimizada para não floodar o servidor
local function set_tag(tag)
    if tag ~= current_server_tag then
        client.set_clan_tag(tag)
        current_server_tag = tag
    end
end

local function update_clantag()
    if not ui.get(clantag_enabled) then return end

    local tag_type = ui.get(clantag_type)

    if tag_type == "Static" then
        set_tag("Vitriol.lua ♡")
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

ui.set_callback(clantag_enabled, function()
    if not ui.get(clantag_enabled) then
        reset_clantag()
    end
end)


-- ==========================================
-- [ LÓGICA DO KILLSAY ]
-- ==========================================
local phrases = {
    "VITRIOL.lua transmuted you",
    "solve et coagula.",
    "VITRIOL.lua dissolves you",
    "Vitriol.lua > ALL :3",
    "OWNED BY Vitriol.lua ♡",
    "Vitriol.lua runs you",
    "Vitriol.lua on top!",
    "1"
}

local function on_killsay_player_death(e)
    if not ui.get(killsay_enabled) then return end

    local me = entity.get_local_player()
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)

    if attacker == me and victim ~= me then
        local delay = ui.get(killsay_delay)
        local cmd = ui.get(killsay_team) and "say_team" or "say"
        local text = phrases[math.random(1, #phrases)]
        local full_cmd = string.format('%s "%s"', cmd, text)

        if delay <= 0.01 then
            client.exec(full_cmd)
        else
            client.delay_call(delay, function()
                if ui.get(killsay_enabled) then
                    client.exec(full_cmd)
                end
            end)
        end
    end
end


-- ==========================================
-- [ LÓGICA DOS LOGS (HIT/MISS) ]
-- ==========================================
local hitgroup_names = {
    "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"
}

local aim_data = {}
local screen_logs = {}
local max_logs = 6

-- Remove espaços inúteis no final do nome do jogador (Resolve o problema do Aim Botz)
local function trim_string(s)
    return s:match("^%s*(.-)%s*$")
end

local function add_screen_log(text, color)
    table.insert(screen_logs, 1, {
        text = text,
        color = color,
        time = globals.realtime(),
        alpha = 0
    })

    if #screen_logs > max_logs then
        table.remove(screen_logs, #screen_logs)
    end
end

local function draw_screen_logs()
    if not ui.get(logs_enabled) or #screen_logs == 0 then return end

    local sw, sh = client.screen_size()
    local x = 10
    local y = sh / 2 + 100
    local current_time = globals.realtime()

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
            renderer.rectangle(x, y, tw + 20, 20, 15, 15, 15, math.floor(a * 0.6))
            renderer.rectangle(x, y, 2, 20, log.color[1], log.color[2], log.color[3], a)

            -- Ícone de Coraçãozinho
            renderer.text(x + 5, y + 4, log.color[1], log.color[2], log.color[3], a, "", 0, "♡")

            -- Texto do Log
            renderer.text(x + 16, y + 4, 255, 255, 255, a, "", 0, log.text)

            y = y - 22
        end
    end
end

local function on_aim_fire(e)
    if not ui.get(logs_enabled) then return end

    aim_data[e.id] = {
        target = e.target,
        hit_chance = e.hit_chance,
        damage = e.damage,
        backtrack = globals.tickcount() - e.tick
    }
end

local function on_aim_hit(e)
    if not ui.get(logs_enabled) then return end
    local data = aim_data[e.id]
    if not data then return end

    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"
    local hp_left = entity.get_prop(e.target, "m_iHealth")

    local log_text = string.format("Hit %s in the %s for %d dmg (hc: %d%% | bt: %d) [hp: %d]",
        target_name, hitgroup, e.damage, math.floor(data.hit_chance), data.backtrack, hp_left)

    print("[Vitriol.lua] " .. log_text)
    -- Rosinha Aesthetic para Hits
    add_screen_log(log_text, { 255, 105, 180 })
end

local function on_aim_miss(e)
    if not ui.get(logs_enabled) then return end
    local data = aim_data[e.id]
    if not data then return end

    local target_name = trim_string(entity.get_player_name(e.target) or "?")
    local hitgroup = hitgroup_names[e.hitgroup + 1] or "?"

    local log_text = string.format("Missed %s's %s due to %s (hc: %d%% | bt: %d)",
        target_name, hitgroup, e.reason, math.floor(data.hit_chance), data.backtrack)

    print("[Vitriol.lua] " .. log_text)
    -- Vermelho para Misses
    add_screen_log(log_text, { 200, 60, 60 })
end


-- ==========================================
-- [ LÓGICA DO BUYBOT ]
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
    local primary = ui.get(buybot_primary)
    local secondary = ui.get(buybot_secondary)
    local utility = ui.get(buybot_utility)

    if primary ~= "None" and buy_cmds[primary] then
        table.insert(cmds_to_run, "buy " .. buy_cmds[primary])
    end

    if secondary ~= "None" and buy_cmds[secondary] then
        table.insert(cmds_to_run, "buy " .. buy_cmds[secondary])
    end

    if #utility > 0 then
        for i = 1, #utility do
            if buy_cmds[utility[i]] then
                table.insert(cmds_to_run, "buy " .. buy_cmds[utility[i]])
            end
        end
    end

    if #cmds_to_run > 0 then
        client.exec(table.concat(cmds_to_run, "; "))
    end
end


-- ==========================================
-- [ REGISTRO DE EVENTOS E SHUTDOWN ]
-- ==========================================
client.set_event_callback("paint", function()
    update_clantag()
    draw_crosshair_hud()
    draw_screen_logs()
end)

client.set_event_callback("player_death", on_killsay_player_death)
client.set_event_callback("round_prestart", on_round_prestart)
client.set_event_callback("aim_fire", on_aim_fire)
client.set_event_callback("aim_hit", on_aim_hit)
client.set_event_callback("aim_miss", on_aim_miss)

client.set_event_callback("shutdown", function()
    reset_clantag()
end)

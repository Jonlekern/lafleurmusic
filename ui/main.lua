-- LAFLEURMUSIC : interface LÖVE qui pilote le moteur MPD (127.0.0.1:6601).
love.filesystem.setRequirePath("?.lua;?/init.lua;src/?.lua;common/?.lua")

local C = require("mpd_client")
local I = require("i18n")
local S = require("settings")
local In = require("input")
local theme = require("theme")
local toast = require("screens.toast")
local K = require("keymap")

local APPDIR = os.getenv("LAFLEUR_APPDIR") or "/storage/roms/lafleur-music"
local SYSCFG = os.getenv("LAFLEUR_SYSCFG") or "/storage/.config/system/configs/system.cfg"
local BATTERY = os.getenv("LAFLEUR_BATTERY") or "/sys/class/power_supply/battery/capacity"
local PADDB = "/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt"

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local t = f:read("*a")
  f:close()
  return t
end

app = {
  appdir = APPDIR,
  state_dir = os.getenv("LAFLEUR_STATE_DIR") or (APPDIR .. "/engine/state"),
  settings_path = APPDIR .. "/settings.txt",
  stack = {},
  songs = {},
  battery = nil,
}

function app.log(msg)
  local f = io.open(APPDIR .. "/log.txt", "a")
  if f then
    f:write(os.date("%H:%M:%S") .. " [ui] " .. msg .. "\n")
    f:close()
  end
end

function app.t(key, ...) return I.t(app.lang, key, ...) end

function app.current() return app.stack[#app.stack] end
function app.push(s)
  app.stack[#app.stack + 1] = s
  if s.enter then s.enter() end
end
function app.pop()
  if #app.stack > 1 then app.stack[#app.stack] = nil end
  local s = app.current()
  if s.enter then s.enter() end
end
function app.replace(s)
  app.stack[#app.stack] = nil
  app.push(s)
end
function app.home()
  while #app.stack > 1 do app.stack[#app.stack] = nil end
  local s = app.current()
  if s.enter then s.enter() end
end

function app.quit()
  app.log("sortie (arrière-plan " .. S.read_background(app.state_dir) .. ")")
  love.event.quit(0)
end

function app.reload_library()
  app.songs = app.mpd:songs()
  app.log(#app.songs .. " morceaux dans la bibliothèque")
end

function app.playing()
  return app.status and app.status.state == "play"
end

-- Joue une liste de morceaux à partir de index (1 = premier).
function app.play_list(tracks, index)
  local P = require("mpd_protocol")
  local lines = { "command_list_begin", "clear" }
  for _, t in ipairs(tracks) do lines[#lines + 1] = "add " .. P.quote(t.file) end
  lines[#lines + 1] = "play " .. ((index or 1) - 1)
  lines[#lines + 1] = "command_list_end"
  local r = app.mpd:command(table.concat(lines, "\n"))
  if not r.ok then app.log("lecture impossible : " .. tostring(r.err)) end
  app.push(require("screens.nowplaying")())
end

local input = In.new()

-- Touches personnalisées : enregistrées dans settings.txt et appliquées tout de suite.
function app.apply_keys()
  K.store(app.settings, app.keys)
  pcall(S.save, app.settings_path, app.settings)
  input:set_bindings(app.keys.open, app.keys.ab_swap)
end
function app.key_label(action) return K.label(app.keys.open[action]) end
local status_timer, battery_timer = 0, 0

local function global_action(a)
  if a == "playpause" then
    local st = app.status or {}
    app.mpd:command(st.state == "play" and "pause 1" or (st.state == "pause" and "pause 0" or "play"))
    status_timer = 0
    return true
  elseif a == "previous" then
    app.mpd:command("previous"); status_timer = 0; return true
  elseif a == "next" then
    app.mpd:command("next"); status_timer = 0; return true
  elseif a == "now_playing" then
    local cur = app.current()
    if not cur.is_nowplaying and app.songs and #app.songs > 0 then app.push(require("screens.nowplaying")()) end
    return true
  elseif a == "quit" then
    app.quit()
    return true
  elseif a == "shuffle" then
    local PM = require("playmode")
    local cmd = PM.shuffle_command(app.mpd:status())
    app.mpd:command(cmd)
    local on = cmd == "random 1"
    toast.show_text(app.t("shuffle") .. " " .. app.t(on and "on" or "off"), on, nil, app.key_label("shuffle"))
    status_timer = 0
    return true
  elseif a == "repeat" then
    local PM = require("playmode")
    local mode = PM.next_repeat(PM.repeat_mode(app.mpd:status()))
    app.mpd:command(PM.repeat_commands(mode))
    toast.show_text(app.t("repeat") .. " : " .. app.t("repeat_" .. mode), mode ~= "off", nil, app.key_label("repeat"))
    status_timer = 0
    return true
  elseif a == "toggle_background" then
    local new = S.read_background(app.state_dir) == "on" and "off" or "on"
    S.write_background(app.state_dir, new)
    app.log("arrière-plan " .. new)
    toast.show(new == "on")
    return true
  end
  return false
end

local function dispatch(actions)
  for _, a in ipairs(actions) do
    local cur = app.current()
    -- les touches globales ne s'appliquent qu'une fois l'appli prête
    if not (cur.ready and global_action(a)) then
      if cur.action then cur.action(a) end
    end
  end
end

local PAD = {
  a = "a", b = "b", x = "x", y = "y", guide = "menu", start = "start", back = "select", leftshoulder = "l1", rightshoulder = "r1",
  dpup = "up", dpdown = "down", dpleft = "left", dpright = "right",
}
local KEYS = {
  ["return"] = "a", escape = "b", backspace = "b", space = "start", tab = "select",
  q = "l1", e = "r1", z = "x", c = "y", up = "up", down = "down", left = "left", right = "right",
}
local logged_buttons = 0

-- Un écran en train de capturer une touche (Touches) reçoit les boutons bruts.
local function press(btn)
  if not btn then return end
  local t, cur = love.timer.getTime(), app.current()
  if cur.raw_press and cur.raw_press(btn, t) then return end
  dispatch(input:press(btn, t))
end
local function release(btn)
  if not btn then return end
  local t, cur = love.timer.getTime(), app.current()
  if cur.raw_release and cur.raw_release(btn, t) then return end
  dispatch(input:release(btn, t))
end

function love.gamepadpressed(_, button)
  if logged_buttons < 40 then
    logged_buttons = logged_buttons + 1
    app.log("bouton " .. button)
  end
  press(PAD[button])
end
function love.gamepadreleased(_, button) release(PAD[button]) end
function love.keypressed(key) press(KEYS[key]) end
function love.keyreleased(key) release(KEYS[key]) end
-- L2 / R2 arrivent comme axes : appui au-dessus de 0,5, relâchement en dessous de 0,3.
local TRIGGERS, trigger_down = { triggerleft = "l2", triggerright = "r2" }, {}
function love.gamepadaxis(_, axis, value)
  local btn = TRIGGERS[axis]
  if not btn then return end
  if value > 0.5 and not trigger_down[btn] then
    trigger_down[btn] = true
    press(btn)
  elseif value < 0.3 and trigger_down[btn] then
    trigger_down[btn] = false
    release(btn)
  end
end

local function read_battery()
  local v = read_file(BATTERY)
  app.battery = v and tonumber(v:match("%d+")) or nil
end

function love.load()
  local f = io.open(APPDIR .. "/log.txt", "a")
  if f then f:close() end
  app.lang = I.detect(read_file(SYSCFG))
  app.settings = S.load(app.settings_path)
  app.keys = K.load(app.settings)
  input:set_bindings(app.keys.open, app.keys.ab_swap)
  -- « Arrière-plan par défaut » : valeur appliquée à chaque lancement.
  pcall(S.write_background, app.state_dir, app.settings.background_default)
  app.mpd = C.new({ port = tonumber(os.getenv("LAFLEUR_MPD_PORT") or "6601") })
  local db = read_file(PADDB)
  if db then pcall(love.joystick.loadGamepadMappings, db) end
  love.mouse.setVisible(false)
  theme.setup(love.graphics.getDimensions())
  app.log(string.format("écran %dx%d, échelle %.2f", theme.W, theme.H, theme.k))
  love.graphics.setBackgroundColor(theme.colors.bg)
  read_battery()
  app.log("démarrage, langue " .. app.lang)
  app.push(require("screens.splash")())
end

function love.update(dt)
  dispatch(input:update(love.timer.getTime()))
  local cur = app.current()
  if cur.ready then
    status_timer = status_timer - dt
    if status_timer <= 0 then
      status_timer = 0.5
      app.status = app.mpd:status()
      app.song = app.mpd:currentsong()
      -- MPD indexe encore la carte (premier lancement, ajout de morceaux) : recharger quand il a fini.
      local scanning = app.status and app.status.updating_db ~= nil
      if app.was_scanning and not scanning and app.status then
        app.reload_library()
        app.stack[1] = require("screens.menu")() -- menu reconstruit avec la bibliothèque complète
      end
      app.was_scanning = scanning
    end
  end
  battery_timer = battery_timer - dt
  if battery_timer <= 0 then
    battery_timer = 30
    read_battery()
  end
  require("covers").update()
  if cur.update then cur.update(dt) end
  toast.update(dt)
end

function love.draw()
  local cur = app.current()
  if cur.draw then cur.draw() end
  toast.draw()
end

function love.errorhandler(msg)
  app.log("ERREUR : " .. tostring(msg) .. "\n" .. debug.traceback("", 2))
  return nil
end

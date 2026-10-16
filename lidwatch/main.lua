-- Gardien du clapet : arrière-plan ON → clapet fermé en lecture = écran éteint, la musique continue ;
-- arrière-plan OFF → clapet fermé = pause + écran éteint, reprise à l'ouverture.
-- Ne met jamais la console en veille ; rallume toujours l'écran avant de sortir.
love.filesystem.setRequirePath("?.lua;?/init.lua;src/?.lua;common/?.lua")

local lid = require("lid")
local rule = require("rule")
local S = require("settings")
local C = require("mpd_client")

local APPDIR = os.getenv("LAFLEUR_APPDIR") or "/storage/roms/lafleur-music"
local STATE = os.getenv("LAFLEUR_STATE_DIR") or (APPDIR .. "/engine/state")
local BL_POWER = os.getenv("LAFLEUR_BL_POWER") or "/sys/class/backlight/backlight/bl_power"
local POLL, TICK, MAX_MISSES = 2, 0.1, 3

local function log(msg)
  local f = io.open(APPDIR .. "/log.txt", "a")
  if f then
    f:write(os.date("%H:%M:%S") .. " [lidwatch] " .. msg .. "\n")
    f:close()
  end
end

local screen = nil -- true = allumé, false = éteint, nil = inconnu
local function set_screen(on)
  if screen == on then return end
  local f = io.open(BL_POWER, "w")
  if f then
    f:write(on and "0" or "4")
    f:close()
    screen = on
    log("écran " .. (on and "allumé" or "éteint"))
  else
    log("impossible d'écrire " .. BL_POWER)
  end
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local t = f:read("*a")
  f:close()
  return t
end

local function finish(reason)
  screen = nil
  set_screen(true)
  os.remove(STATE .. "/lidwatch.pid")
  log("arrêt : " .. reason)
end

local function main()
  local pid = read_file("/proc/self/stat")
  pid = pid and pid:match("^(%d+)")
  if pid then
    local f = io.open(STATE .. "/lidwatch.pid", "w")
    if f then f:write(pid) f:close() end
  end

  local devices = read_file("/proc/bus/input/devices")
  local device = os.getenv("LAFLEUR_LID_DEVICE") or lid.find_device(devices)
  if not device then return "aucun interrupteur de clapet trouvé" end
  log("clapet : " .. device)

  local channel = love.thread.getChannel("lid")
  local thread = love.thread.newThread("src/reader_thread.lua")
  thread:start(device, "lid")
  local pad = lid.find_gamepad(devices)
  local pad_thread
  if pad then
    log("manette : " .. pad)
    pad_thread = love.thread.newThread("src/reader_thread.lua")
    pad_thread:start(pad, "pad")
  else
    log("manette introuvable : pas de touches clapet fermé")
  end
  local logged_keys = 0

  local mpd = C.new({ port = tonumber(os.getenv("LAFLEUR_MPD_PORT") or "6601") })
  local closed, state, misses, next_poll, paused_by_us = false, nil, 0, 0, false

  while true do
    local msg = channel:pop()
    while msg do
      if msg:match("^error") then return msg end
      local code, value = msg:match("^key:(%d+):(%-?%d+)")
      if code then
        if logged_keys < 60 and value ~= "2" then
          logged_keys = logged_keys + 1
          log("touche " .. code .. " " .. value .. (closed and " (clapet fermé)" or ""))
        end
      else
        closed = (msg == "closed")
        next_poll = 0 -- relire l'état de lecture tout de suite après un mouvement du clapet
      end
      msg = channel:pop()
    end
    local now = love.timer.getTime()
    if now >= next_poll then
      next_poll = now + POLL
      local st = mpd:status()
      if st then
        misses, state = 0, st.state
      else
        misses, state = misses + 1, nil
        if misses >= MAX_MISSES then return "moteur audio arrêté" end
      end
    end
    local on, action
    on, action, paused_by_us = rule.decide(closed, S.read_background(STATE), state, paused_by_us)
    if action == "pause" then
      mpd:command("pause 1"); state = "pause"; log("clapet fermé, arrière-plan OFF : pause")
    elseif action == "resume" then
      mpd:command("pause 0"); state = "play"; log("clapet rouvert : reprise")
    end
    set_screen(on)
    love.timer.sleep(TICK)
  end
end

-- Boucle maison : pas de fenêtre, pas de rendu, réveil toutes les 100 ms.
function love.run()
  return function()
    local ok, reason = xpcall(main, debug.traceback)
    finish(ok and tostring(reason) or ("erreur : " .. tostring(reason)))
    return 0
  end
end

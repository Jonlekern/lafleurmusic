-- Gardien du clapet : clapet fermé + arrière-plan ON + lecture → rétroéclairage éteint.
-- Ne met jamais la console en veille ; rallume toujours l'écran avant de sortir.
love.filesystem.setRequirePath("?.lua;?/init.lua;src/?.lua;common/?.lua")

local lid = require("lid")
local rule = require("rule")
local S = require("settings")
local C = require("mpd_client")

local APPDIR = os.getenv("LAFLEUR_APPDIR") or "/storage/roms/lafleur-music"
local STATE = APPDIR .. "/engine/state"
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

  local device = os.getenv("LAFLEUR_LID_DEVICE") or lid.find_device(read_file("/proc/bus/input/devices"))
  if not device then return "aucun interrupteur de clapet trouvé" end
  log("clapet : " .. device)

  local channel = love.thread.getChannel("lid")
  local thread = love.thread.newThread("src/reader_thread.lua")
  thread:start(device)

  local mpd = C.new({ port = tonumber(os.getenv("LAFLEUR_MPD_PORT") or "6601") })
  local closed, state, misses, next_poll = false, nil, 0, 0

  while true do
    local msg = channel:pop()
    while msg do
      if msg:match("^error") then return msg end
      closed = (msg == "closed")
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
    set_screen(rule.screen_on(closed, S.read_background(STATE), state))
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

-- Plein écran à la taille native de la console (640×480, 720×480, 720×720, 1280×720…).
-- En fenêtre pour le développement : LAFLEUR_WINDOWED=1, taille LAFLEUR_SIZE=LxH (720x480 par défaut).
function love.conf(t)
  t.identity = "lafleur-music"
  t.window.title = "LAFLEURMUSIC"
  local windowed = os.getenv("LAFLEUR_WINDOWED") ~= nil
  local w, h = (os.getenv("LAFLEUR_SIZE") or ""):match("^(%d+)x(%d+)$")
  t.window.width = windowed and tonumber(w or 720) or 0
  t.window.height = windowed and tonumber(h or 480) or 0
  t.window.fullscreen = not windowed
  t.window.fullscreentype = "desktop"
  t.window.vsync = 1
  t.modules.physics = false
  t.modules.video = false
  t.modules.audio = false
  t.modules.sound = false
end

function love.conf(t)
  t.identity = "lafleur-music"
  t.window.title = "LAFLEUR Music"
  t.window.width = 720
  t.window.height = 480
  t.window.fullscreen = (os.getenv("LAFLEUR_WINDOWED") == nil)
  t.window.vsync = 1
  t.modules.physics = false
  t.modules.video = false
  t.modules.audio = false
  t.modules.sound = false
end

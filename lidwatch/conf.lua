function love.conf(t)
  t.identity = "lafleur-lidwatch"
  t.window = nil
  for _, m in ipairs({ "graphics", "audio", "sound", "joystick", "keyboard", "mouse", "touch",
    "image", "font", "physics", "video", "window" }) do
    t.modules[m] = false
  end
end

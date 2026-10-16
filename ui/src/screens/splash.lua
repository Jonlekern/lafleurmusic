-- Démarrage : fleur + logo texte, le temps de joindre MPD (essai toutes les 0,5 s pendant 5 s).
local theme = require("theme")
local message = require("screens.message")

return function()
  local s = { elapsed = 0, next_try = 0, done = false }

  function s.update(dt)
    if s.done then return end
    s.elapsed = s.elapsed + dt
    if s.elapsed < s.next_try then return end
    s.next_try = s.elapsed + 0.5
    local st = app.mpd:status()
    if st then
      s.done = true
      app.log("MPD joint après " .. string.format("%.1f", s.elapsed) .. " s")
      app.reload_library()
      if #app.songs == 0 then
        app.replace(message("empty_library"))
      else
        app.replace(require("screens.menu")())
      end
    elseif s.elapsed >= 5 then
      s.done = true
      app.log("MPD injoignable après 5 s")
      app.replace(message("engine_down"))
    end
  end

  function s.draw()
    local flower, logo = theme.image("fleur"), theme.image("logo-texte-grand")
    local fw = 260
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(flower, (720 - fw) / 2, 110, 0, fw / flower:getWidth())
    local lw = 450
    love.graphics.draw(logo, (720 - lw) / 2, 340, 0, lw / logo:getWidth())
  end

  function s.action(a) end
  return s
end

-- Écran plein avec un message (bibliothèque vide, moteur indisponible). B quitte.
local theme = require("theme")

return function(text_key)
  local s = {}
  function s.draw()
    theme.title_bar(nil, false, app.battery)
    local k, W, H = theme.k, theme.W, theme.H
    local oy = (H - 480 * k) / 2
    local flower = theme.image("fleur")
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.draw(flower, W / 2 - 90 * k, oy + 120 * k, 0, 180 * k / flower:getWidth())
    theme.color(theme.colors.text)
    theme.print(app.t(text_key), theme.font("Bold", 24), 40 * k, oy + 300 * k, W - 80 * k, "center")
  end
  function s.action(a)
    if a == "back" or a == "ok" then app.quit() end
  end
  return s
end

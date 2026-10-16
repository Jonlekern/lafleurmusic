-- Écran plein avec un message (bibliothèque vide, moteur indisponible). B quitte.
local theme = require("theme")

return function(text_key)
  local s = {}
  function s.draw()
    theme.title_bar(nil, false, app.battery)
    local flower = theme.image("fleur")
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.draw(flower, 360 - 90, 120, 0, 180 / flower:getWidth())
    theme.color(theme.colors.text)
    theme.print(app.t(text_key), theme.font("Bold", 24), 40, 300, 640, "center")
  end
  function s.action(a)
    if a == "back" or a == "ok" then app.quit() end
  end
  return s
end

-- Petit écran de 1,5 s par-dessus l'écran courant : arrière-plan (L1 + R1), aléatoire (Y), répéter (X).
local theme = require("theme")

local toast = { left = 0, on = true }

-- title : texte principal ; on : rose (actif) ou gris ; msg : explication ou nil ; hint : bouton.
function toast.show_text(title, on, msg, hint)
  toast.title, toast.on, toast.msg, toast.hint, toast.left = title, on, msg, hint, 1.5
end

function toast.show(on)
  toast.show_text(app.t("background") .. " " .. app.t(on and "on" or "off"), on,
    app.t(on and "bg_on_msg" or "bg_off_msg"), "L1 + R1")
end

function toast.update(dt)
  if toast.left > 0 then toast.left = math.max(0, toast.left - dt) end
end

function toast.draw()
  if toast.left <= 0 then return end
  local c = theme.colors
  local fade = math.min(1, toast.left / 0.2)
  love.graphics.setColor(0, 0, 0, 0.55 * fade)
  love.graphics.rectangle("fill", 0, 0, 720, 480)
  local x, y, w, h = 170, 110, 380, 260
  theme.color({ 24 / 255, 24 / 255, 24 / 255 }, fade)
  love.graphics.rectangle("fill", x, y, w, h, 26, 26)
  love.graphics.setLineWidth(3)
  theme.color(toast.on and c.pink or { 0.35, 0.35, 0.35 }, fade)
  love.graphics.rectangle("line", x, y, w, h, 26, 26)
  local flower = theme.image("fleur")
  love.graphics.setColor(1, 1, 1, (toast.on and 1 or 0.35) * fade)
  love.graphics.draw(flower, 360 - 45, 135, 0, 90 / flower:getWidth())
  theme.color(toast.on and c.pink or { 0.8, 0.8, 0.8 }, fade)
  theme.print(toast.title, theme.font("Bold", 30), x + 10, toast.msg and 228 or 252, w - 20, "center")
  if toast.msg then
    theme.color({ 0.86, 0.86, 0.86 }, fade)
    love.graphics.setFont(theme.font("Regular", 19))
    love.graphics.printf(toast.msg, x, 276, w, "center")
  end
  theme.color({ 0.55, 0.55, 0.55 }, fade)
  theme.print(toast.hint or "", theme.font("Regular", 14), x, 340, w, "center")
end

return toast

-- Couleurs LAFLEURSTUDIO, polices Inter, barre de titre et pochettes avec reflet.
local text = require("text")

local theme = {}

local function hex(h)
  return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 }
end

theme.colors = {
  bg = hex("0D0D0D"), bar = hex("1C1C1C"), text = hex("FFFFFF"), sub = hex("969696"),
  pink = hex("F26EF2"), ink = hex("1F1F1F"), tile = hex("1A1A1A"), line = hex("282828"),
}
theme.W, theme.H, theme.BAR_H = 720, 480, 44

local fonts, images = {}, {}

function theme.font(kind, size)
  local key = kind .. size
  if not fonts[key] then fonts[key] = love.graphics.newFont("assets/fonts/Inter-" .. kind .. ".otf", size) end
  return fonts[key]
end

function theme.image(name)
  if not images[name] then
    images[name] = love.graphics.newImage("assets/" .. name .. ".png")
    images[name]:setFilter("linear", "linear")
  end
  return images[name]
end

function theme.color(c, a)
  love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

-- Texte coupé avec « … » pour tenir dans max_w. align : "left" | "center" | "right".
function theme.print(s, font, x, y, max_w, align)
  s = text.fit_text(s or "", max_w, function(v) return font:getWidth(v) end)
  love.graphics.setFont(font)
  love.graphics.printf(s, x, y, max_w, align or "left")
end

local function battery_icon(x, y, level)
  theme.color(theme.colors.text)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, 38, 18, 3, 3)
  love.graphics.rectangle("fill", x + 39, y + 5, 3, 8)
  theme.color(level and level <= 15 and { 0.95, 0.3, 0.3 } or theme.colors.pink)
  love.graphics.rectangle("fill", x + 4, y + 4, 30 * math.max(0, math.min(1, (level or 0) / 100)), 10)
end

-- title nil → logo texte LAFLEURSTUDIO ; playing : icône lecture (sinon pause).
function theme.title_bar(title, playing, battery)
  local c, W, B = theme.colors, theme.W, theme.BAR_H
  theme.color(c.bar)
  love.graphics.rectangle("fill", 0, 0, W, B)
  theme.color(c.line)
  love.graphics.line(0, B, W, B)
  theme.color(c.text)
  if playing then
    love.graphics.polygon("fill", 16, 14, 16, 30, 30, 22)
  else
    love.graphics.rectangle("fill", 16, 14, 5, 16)
    love.graphics.rectangle("fill", 25, 14, 5, 16)
  end
  if title == nil then
    local logo = theme.image("logo-texte")
    love.graphics.draw(logo, math.floor((W - logo:getWidth()) / 2), math.floor((B - logo:getHeight()) / 2))
  else
    theme.print(title, theme.font("Bold", 20), 130, 10, W - 260, "center")
  end
  if battery then
    theme.print(battery .. "%", theme.font("Regular", 15), W - 160, 13, 92, "right")
  end
  battery_icon(W - 62, 13, battery)
end

-- Pochette carrée + reflet dégradé dessous.
function theme.cover(img, x, y, size, reflect_h)
  local sx = size / img:getWidth()
  local sy = size / img:getHeight()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, x, y, 0, sx, sy)
  if reflect_h and reflect_h > 0 then
    love.graphics.setScissor(x, y + size, size, reflect_h)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.draw(img, x, y + 2 * size, 0, sx, -sy)
    love.graphics.setScissor()
    -- fondu vers le fond
    for i = 0, reflect_h - 1 do
      theme.color(theme.colors.bg, i / reflect_h)
      love.graphics.rectangle("fill", x, y + size + i, size, 1)
    end
  end
end

return theme

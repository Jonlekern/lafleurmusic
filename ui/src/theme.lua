-- Couleurs LAFLEURSTUDIO, polices Inter, barre de titre et pochettes avec reflet.
-- Les tailles sont celles de la maquette 720×480 ; theme.k les adapte à l'écran (theme.setup).
local text = require("text")
local Lay = require("layout")

local theme = {}

local function hex(h)
  return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 }
end

theme.colors = {
  bg = hex("0D0D0D"), bar = hex("1C1C1C"), text = hex("FFFFFF"), sub = hex("969696"),
  pink = hex("F26EF2"), ink = hex("1F1F1F"), tile = hex("1A1A1A"), line = hex("282828"),
}

local fonts, images = {}, {}

function theme.setup(W, H)
  theme.W, theme.H = W, H
  theme.k = Lay.scale(W, H)
  theme.BAR_H = math.floor(44 * theme.k + 0.5)
  fonts = {}
end
theme.setup(720, 480)

-- size : taille de la maquette 720×480, mise à l'échelle de l'écran.
function theme.font(kind, size)
  local px = math.max(8, math.floor(size * theme.k + 0.5))
  local key = kind .. px
  if not fonts[key] then fonts[key] = love.graphics.newFont("assets/fonts/Inter-" .. kind .. ".otf", px) end
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

local function battery_icon(x, y, level, k)
  theme.color(theme.colors.text)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, 38 * k, 18 * k, 3, 3)
  love.graphics.rectangle("fill", x + 39 * k, y + 5 * k, 3 * k, 8 * k)
  theme.color(level and level <= 15 and { 0.95, 0.3, 0.3 } or theme.colors.pink)
  love.graphics.rectangle("fill", x + 4 * k, y + 4 * k, 30 * k * math.max(0, math.min(1, (level or 0) / 100)), 10 * k)
end

-- title nil → logo texte LAFLEURMUSIC ; playing : icône lecture (sinon pause).
function theme.title_bar(title, playing, battery)
  local c, W, B, k = theme.colors, theme.W, theme.BAR_H, theme.k
  theme.color(c.bar)
  love.graphics.rectangle("fill", 0, 0, W, B)
  theme.color(c.line)
  love.graphics.line(0, B, W, B)
  theme.color(c.text)
  if playing then
    love.graphics.polygon("fill", 16 * k, 14 * k, 16 * k, 30 * k, 30 * k, 22 * k)
  else
    love.graphics.rectangle("fill", 16 * k, 14 * k, 5 * k, 16 * k)
    love.graphics.rectangle("fill", 25 * k, 14 * k, 5 * k, 16 * k)
  end
  if title == nil then
    local logo = theme.image(k > 1.2 and "logo-texte-grand" or "logo-texte")
    local s = 250 * k / logo:getWidth()
    love.graphics.draw(logo, math.floor((W - 250 * k) / 2), math.floor((B - logo:getHeight() * s) / 2), 0, s, s)
  else
    theme.print(title, theme.font("Bold", 20), 130 * k, 10 * k, W - 260 * k, "center")
  end
  if battery then
    theme.print(battery .. "%", theme.font("Regular", 15), W - 160 * k, 13 * k, 92 * k, "right")
  end
  battery_icon(W - 62 * k, 13 * k, battery, k)
end

-- Pochette carrée + reflet dégradé dessous (reflect_h en pixels d'écran).
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
    for i = 0, reflect_h - 1 do
      theme.color(theme.colors.bg, i / reflect_h)
      love.graphics.rectangle("fill", x, y + size + i, size, 1)
    end
  end
end

return theme

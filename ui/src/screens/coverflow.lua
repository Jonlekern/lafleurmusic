-- Cover Flow : pochettes des playlists (albums) en perspective, celle du centre de face.
local theme = require("theme")
local covers = require("covers")
local L = require("library")
local CF = require("coverflow_layout")

local OUTER = 0.76 -- hauteur relative du bord extérieur des pochettes latérales
local mesh -- réutilisé à chaque dessin

local function side_mesh(img, e)
  local x, y, w, h = e.x, e.y, e.w, e.h
  local inset = h * (1 - OUTER) / 2
  local verts
  if e.side == "left" then
    verts = { { x, y + inset, 0, 0, 1, 1, 1, 1 }, { x + w, y, 1, 0, 1, 1, 1, 1 }, { x + w, y + h, 1, 1, 1, 1, 1, 1 }, { x, y + h - inset, 0, 1, 1, 1, 1, 1 } }
  else
    verts = { { x, y, 0, 0, 1, 1, 1, 1 }, { x + w, y + inset, 1, 0, 1, 1, 1, 1 }, { x + w, y + h - inset, 1, 1, 1, 1, 1, 1 }, { x, y + h, 0, 1, 1, 1, 1, 1 } }
  end
  if not mesh then mesh = love.graphics.newMesh(4, "fan", "dynamic") end
  mesh:setVertices(verts)
  mesh:setTexture(img)
  return mesh
end

return function()
  local albums = L.albums(app.songs)
  local s = { ready = true, pos = 1, target = 1 }
  -- commence sur l'album en cours si possible
  if app.song then
    for i, a in ipairs(albums) do
      if a.name == (app.song.Album or "") then s.pos, s.target = i, i end
    end
  end

  function s.update(dt) s.pos = CF.step(s.pos, s.target, dt) end

  function s.action(a)
    if a == "left" then s.target = math.max(1, s.target - 1)
    elseif a == "right" then s.target = math.min(#albums, s.target + 1)
    elseif a == "ok" and albums[s.target] then app.nav.album(albums[s.target].name)
    elseif a == "back" then app.pop()
    end
  end

  function s.draw()
    local c, k, W, H = theme.colors, theme.k, theme.W, theme.H
    local oy = math.floor((H - 480 * k) / 2) -- écrans plus hauts que 3:2 : on centre verticalement
    theme.title_bar(app.t("cover_flow"), app.playing(), app.battery)
    for _, e in ipairs(CF.layout(s.pos, #albums, W, H)) do
      local img = covers.get(albums[e.index].first_file, 300)
      e.y = e.y + oy
      if e.side == "center" then
        theme.cover(img, e.x, e.y, e.w, math.floor(60 * k))
      else
        love.graphics.setColor(0.65, 0.65, 0.65, 1)
        love.graphics.draw(side_mesh(img, e))
      end
    end
    local a = albums[s.target]
    if a then
      theme.color(c.text)
      theme.print(a.name ~= "" and a.name or app.t("unknown"), theme.font("Bold", 24), 40 * k, oy + 386 * k, W - 80 * k, "center")
      theme.color(c.sub)
      theme.print(app.t("playlist_n", a.count), theme.font("Regular", 17), 40 * k, oy + 420 * k, W - 80 * k, "center")
    end
    local n = #albums
    for i = 1, n do
      theme.color(i == s.target and c.pink or { 0.27, 0.27, 0.27 })
      love.graphics.circle("fill", W / 2 + ((i - 1) - (n - 1) / 2) * 20 * k, oy + 460 * k, 4 * k)
    end
  end

  return s
end

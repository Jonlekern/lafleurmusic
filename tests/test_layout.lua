local Lay = require("layout")

return {
  ["échelle : la hauteur en paysage, la largeur en carré"] = function()
    eq(Lay.scale(720, 480), 1)
    eq(Lay.scale(640, 480), 1)
    eq(Lay.scale(1280, 720), 1.5)
    eq(Lay.scale(720, 720), 1)
  end,
  ["liste en 720x480 (RG SP)"] = function()
    local l = Lay.list(720, 480)
    eq({ l.bar, l.list_w, l.rows, l.row_h }, { 44, 381, 8, 54.5 })
    eq(l.cover.size, 278)
    eq(l.cover.x, 381 + math.floor((339 - 278) / 2))
  end,
  ["liste en 1280x720 : plus grand, toujours 8 lignes"] = function()
    local l = Lay.list(1280, 720)
    eq(l.bar, 66)
    eq(l.rows, 8)
    truthy(l.cover.size > 400, "pochette " .. l.cover.size)
  end,
  ["liste en 720x720 : plus de lignes visibles"] = function()
    local l = Lay.list(720, 720)
    truthy(l.rows > 8, "lignes " .. l.rows)
    truthy(l.cover.x + l.cover.size <= 720, "pochette hors écran")
  end,
  ["En cours : paysage ou carré"] = function()
    eq(Lay.nowplaying(720, 480).mode, "landscape")
    eq(Lay.nowplaying(1280, 720).mode, "landscape")
    eq(Lay.nowplaying(720, 720).mode, "square")
  end,
  ["En cours en 720x480 : identique à la maquette d'origine"] = function()
    local n = Lay.nowplaying(720, 480)
    eq({ n.cover.x, n.cover.y, n.cover.size }, { 30, 66, 270 })
    eq({ n.text.x, n.text.y, n.text.w }, { 330, 82, 360 })
    eq({ n.progress_y, n.hints_y, n.badge_y }, { 300, 372, 420 })
  end,
  ["En cours : tout tient dans l'écran"] = function()
    for _, s in ipairs({ { 640, 480 }, { 720, 480 }, { 720, 720 }, { 1280, 720 } }) do
      local n = Lay.nowplaying(s[1], s[2])
      truthy(n.cover.x + n.cover.size <= s[1] and n.cover.y + n.cover.size <= s[2], "pochette " .. s[1] .. "x" .. s[2])
      truthy(n.text.x + n.text.w <= s[1], "texte " .. s[1] .. "x" .. s[2])
      truthy(n.badge_y + 36 * n.k <= s[2], "badge " .. s[1] .. "x" .. s[2])
    end
  end,
}

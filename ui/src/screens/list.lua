-- Liste façon iPod Classic 6G : lignes à gauche, pochette de l'élément sélectionné à droite.
-- items : { {label, value?, cover_file?, caption?, on_ok} } ; value() → texte à droite à la place du chevron.
-- Mise en page : layout.list (s'adapte à la taille de l'écran).
local theme = require("theme")
local covers = require("covers")
local Lay = require("layout")

return function(opts)
  local s = { ready = true, sel = 1, top = 1, title = opts.title, items = opts.items }
  local L = Lay.list(theme.W, theme.H)
  local VISIBLE = L.rows

  local function clamp(dir)
    local n = #s.items
    if n == 0 then s.sel = 1 return end
    s.sel = math.max(1, math.min(n, s.sel))
    -- un titre de section ne se sélectionne pas : on continue dans le même sens
    while s.items[s.sel] and s.items[s.sel].header do
      local nxt = s.sel + (dir or 1)
      if nxt < 1 or nxt > n then dir = -(dir or 1) nxt = s.sel + dir end
      s.sel = nxt
    end
    if s.sel < s.top then s.top = s.sel end
    if s.sel > s.top + VISIBLE - 1 then s.top = s.sel - VISIBLE + 1 end
  end

  function s.action(a)
    local dir = (a == "up" or a == "left") and -1 or 1
    if a == "up" then s.sel = s.sel - 1
    elseif a == "down" then s.sel = s.sel + 1
    elseif a == "left" then s.sel = s.sel - VISIBLE
    elseif a == "right" then s.sel = s.sel + VISIBLE
    elseif a == "ok" then
      local it = s.items[s.sel]
      if it and it.on_ok then it.on_ok(it) end
    elseif a == "back" then
      if opts.on_back then opts.on_back() else app.pop() end
    end
    clamp(dir)
  end

  function s.draw()
    local c, k, W, H = theme.colors, theme.k, theme.W, theme.H
    local LIST_W, ROW_H = L.list_w, L.row_h
    theme.title_bar(s.title, app.playing(), app.battery)
    local row_font, chev_font = theme.font("Bold", 21), theme.font("Bold", 28)
    for i = s.top, math.min(#s.items, s.top + VISIBLE - 1) do
      local it = s.items[i]
      local y = L.bar + (i - s.top) * ROW_H
      local ty = y + (ROW_H - row_font:getHeight()) / 2
      local selected = i == s.sel
      if it.header then
        theme.color(c.sub)
        theme.print(it.label, theme.font("Bold", 15), 22 * k, y + (ROW_H - theme.font("Bold", 15):getHeight()) / 2 + 6 * k, LIST_W - 44 * k)
        goto continue
      end
      if selected then
        theme.color(c.pink)
        love.graphics.rectangle("fill", 0, y, LIST_W, ROW_H)
      end
      theme.color(selected and c.ink or c.text)
      local value = it.value and it.value()
      local right_w = (value and 90 or 30) * k
      theme.print(it.label, row_font, 22 * k, ty, LIST_W - 22 * k - right_w - 10 * k)
      if value then
        theme.print(value, theme.font("Bold", 18), LIST_W - 110 * k, ty + 2 * k, 92 * k, "right")
      elseif it.on_ok then
        theme.print("›", chev_font, LIST_W - 50 * k, y + (ROW_H - chev_font:getHeight()) / 2, 32 * k, "right")
      end
      ::continue::
    end
    -- barre de défilement
    if #s.items > VISIBLE then
      local track = H - L.bar
      local h = math.max(24 * k, track * VISIBLE / #s.items)
      local y = L.bar + (track - h) * (s.top - 1) / (#s.items - VISIBLE)
      theme.color(c.sub, 0.5)
      love.graphics.rectangle("fill", LIST_W - 4 * k, y, 3 * k, h)
    end
    theme.color(c.line)
    love.graphics.line(LIST_W, L.bar, LIST_W, H)
    -- panneau de droite
    local it = s.items[s.sel]
    local file = it and (it.cover_file or (opts.default_cover and opts.default_cover()))
    if file or (it and it.show_tile) then
      local cv = L.cover
      theme.cover(covers.get(file, 300), cv.x, cv.y, cv.size, math.floor(70 * k))
      local caption = it.caption or (opts.default_caption and opts.default_caption())
      if caption then
        theme.color(c.sub)
        theme.print(caption, theme.font("Regular", 15), LIST_W + 10 * k, L.caption_y, W - LIST_W - 20 * k, "center")
      end
    end
  end

  clamp()
  return s
end

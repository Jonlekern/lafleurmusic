-- Liste façon iPod Classic 6G : lignes à gauche (380 px), pochette de l'élément sélectionné à droite.
-- items : { {label, value?, cover_file?, caption?, on_ok} } ; value() → texte à droite à la place du chevron.
local theme = require("theme")
local covers = require("covers")

local ROW_H, VISIBLE, LIST_W = 54, 8, 380

return function(opts)
  local s = { ready = true, sel = 1, top = 1, title = opts.title, items = opts.items }

  local function clamp()
    local n = #s.items
    if n == 0 then s.sel = 1 return end
    s.sel = math.max(1, math.min(n, s.sel))
    if s.sel < s.top then s.top = s.sel end
    if s.sel > s.top + VISIBLE - 1 then s.top = s.sel - VISIBLE + 1 end
  end

  function s.action(a)
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
    clamp()
  end

  function s.draw()
    local c = theme.colors
    theme.title_bar(s.title, app.playing(), app.battery)
    local row_font, chev_font = theme.font("Bold", 21), theme.font("Bold", 28)
    for i = s.top, math.min(#s.items, s.top + VISIBLE - 1) do
      local it = s.items[i]
      local y = theme.BAR_H + (i - s.top) * ROW_H
      local selected = i == s.sel
      if selected then
        theme.color(c.pink)
        love.graphics.rectangle("fill", 0, y, LIST_W, ROW_H)
      end
      theme.color(selected and c.ink or c.text)
      local value = it.value and it.value()
      local right_w = value and 90 or 30
      theme.print(it.label, row_font, 22, y + 14, LIST_W - 22 - right_w - 10)
      if value then
        theme.print(value, theme.font("Bold", 18), LIST_W - 110, y + 16, 92, "right")
      elseif it.on_ok then
        theme.print("›", chev_font, LIST_W - 50, y + 8, 32, "right")
      end
    end
    -- barre de défilement
    if #s.items > VISIBLE then
      local track = 480 - theme.BAR_H
      local h = math.max(24, track * VISIBLE / #s.items)
      local y = theme.BAR_H + (track - h) * (s.top - 1) / (#s.items - VISIBLE)
      theme.color(c.sub, 0.5)
      love.graphics.rectangle("fill", LIST_W - 4, y, 3, h)
    end
    theme.color(c.line)
    love.graphics.line(LIST_W, theme.BAR_H, LIST_W, 480)
    -- panneau de droite
    local it = s.items[s.sel]
    local file = it and (it.cover_file or (opts.default_cover and opts.default_cover()))
    if file or (it and it.show_tile) then
      theme.cover(covers.get(file, 300), 400, 64, 300, 70)
      local caption = it.caption or (opts.default_caption and opts.default_caption())
      if caption then
        theme.color(c.sub)
        theme.print(caption, theme.font("Regular", 15), 390, 444, 320, "center")
      end
    end
  end

  clamp()
  return s
end

-- En cours : grande pochette, titre / artiste / album, progression, aléatoire, répéter, badge arrière-plan.
local theme = require("theme")
local covers = require("covers")
local S = require("settings")
local Lay = require("layout")

local function clock(sec)
  sec = math.max(0, math.floor(sec or 0))
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

return function()
  local s = { ready = true, is_nowplaying = true }
  local L = Lay.nowplaying(theme.W, theme.H)

  function s.action(a)
    if a == "back" or a == "ok" then app.pop()
    elseif a == "left" then app.mpd:command("previous")
    elseif a == "right" then app.mpd:command("next")
    end
  end

  function s.draw()
    local c, k = theme.colors, theme.k
    local st, song = app.status or {}, app.song
    theme.title_bar(app.t("now_playing"), app.playing(), app.battery)
    local cv = L.cover
    -- en carré le texte est juste sous la pochette : pas de reflet
    theme.cover(covers.get(song and song.file, 300), cv.x, cv.y, cv.size, L.mode == "landscape" and math.floor(60 * k) or 0)
    local x, w, ty, py = L.text.x, L.text.w, L.text.y, L.progress_y
    if song then
      local pos, total = tonumber(st.song), tonumber(st.playlistlength)
      if pos and total then
        theme.color(c.sub)
        theme.print(app.t("n_of", pos + 1, total), theme.font("Regular", 16), x, ty, w)
      end
      theme.color(c.text)
      theme.print(song.Title or song.file:match("[^/]+$"), theme.font("Bold", 32), x, ty + 34 * k, w)
      theme.print(song.Artist or app.t("unknown"), theme.font("Regular", 22), x, ty + 84 * k, w)
      theme.color(c.sub)
      theme.print(song.Album or "", theme.font("Regular", 20), x, ty + 118 * k, w)
    end
    local elapsed, duration = tonumber(st.elapsed) or 0, tonumber(st.duration) or 0
    local f = duration > 0 and math.min(1, elapsed / duration) or 0
    theme.color({ 0.24, 0.24, 0.24 })
    love.graphics.rectangle("fill", x, py, w, 8 * k, 4 * k, 4 * k)
    theme.color(c.pink)
    love.graphics.rectangle("fill", x, py, w * f, 8 * k, 4 * k, 4 * k)
    theme.color(c.text)
    love.graphics.circle("fill", x + w * f, py + 4 * k, 7 * k)
    theme.color(c.sub)
    theme.print(clock(elapsed), theme.font("Regular", 16), x, py + 22 * k, 100 * k)
    theme.print("-" .. clock(duration - elapsed), theme.font("Regular", 16), x + w - 100 * k, py + 22 * k, 100 * k, "right")
    -- Aléatoire (Y) · Répéter (X) · ⏯ START, avec les touches choisies
    local small = theme.font("Regular", 16)
    local mode = require("playmode").repeat_mode(st)
    local hints = {
      { app.t("shuffle") .. " (" .. app.key_label("shuffle") .. ")", st.random == "1", key = "shuffle" },
      { app.t("repeat") .. (mode ~= "off" and (" : " .. app.t("repeat_" .. mode)) or "") .. " (" .. app.key_label("repeat") .. ")",
        mode ~= "off", key = "repeat" },
      { app.key_label("playpause"), st.state == "play", icon = true, key = "playpause" }, -- ⏯ dessiné, rose pendant la lecture
    }
    -- un raccourci sans touche n'a pas d'inscription
    for i = #hints, 1, -1 do
      if app.keys.open[hints[i].key] == "" then table.remove(hints, i) end
    end
    local hx, hy = x, L.hints_y
    for i, h in ipairs(hints) do
      local need = small:getWidth(h[1]) + (h.icon and 25 * k or 0)
      if i > 1 and hx + need > x + w then hx, hy = x, hy + 22 * k end -- écran étroit : ligne suivante
      local room = x + w - hx
      theme.color(h[2] and c.pink or c.sub)
      if h.icon then
        local ih, iy = 12 * k, hy + (small:getHeight() - 12 * k) / 2
        love.graphics.polygon("fill", hx, iy, hx, iy + ih, hx + 9 * k, iy + ih / 2)
        love.graphics.rectangle("fill", hx + 11 * k, iy, 3 * k, ih)
        love.graphics.rectangle("fill", hx + 16 * k, iy, 3 * k, ih)
        hx, room = hx + 25 * k, room - 25 * k
      end
      theme.print(h[1], small, hx, hy, room)
      hx = hx + math.min(room, small:getWidth(h[1])) + 22 * k
    end
    local bg = S.read_background(app.state_dir) == "on"
    theme.color(bg and { 40 / 255, 20 / 255, 40 / 255 } or { 0.12, 0.12, 0.12 })
    local by, bh = L.badge_y, 36 * k
    love.graphics.rectangle("fill", x, by, w, bh, bh / 2, bh / 2)
    love.graphics.setLineWidth(2)
    theme.color(bg and c.pink or c.sub)
    love.graphics.rectangle("line", x, by, w, bh, bh / 2, bh / 2)
    local bg_key = app.keys.open.toggle_background ~= "" and ("   ·   " .. app.key_label("toggle_background")) or ""
    theme.print(app.t("background") .. " : " .. app.t(bg and "on" or "off") .. bg_key,
      theme.font("Bold", 15), x, by + 9 * k, w, "center")
  end

  return s
end

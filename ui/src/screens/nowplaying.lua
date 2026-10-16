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
    -- Aléatoire (Y) · Répéter (X) · Pause/Lecture (START), à la suite sur une ligne
    local small = theme.font("Regular", 16)
    local mode = require("playmode").repeat_mode(st)
    local hints = {
      { app.t("shuffle") .. " (Y)", st.random == "1" },
      { app.t("repeat") .. (mode ~= "off" and (" : " .. app.t("repeat_" .. mode)) or "") .. " (X)", mode ~= "off" },
      { app.t(st.state == "play" and "pause" or "play") .. " (START)", false },
    }
    local hx = x
    for _, h in ipairs(hints) do
      local room = x + w - hx
      if room <= 20 * k then break end
      theme.color(h[2] and c.pink or c.sub)
      theme.print(h[1], small, hx, L.hints_y, room)
      hx = hx + math.min(room, small:getWidth(h[1])) + 22 * k
    end
    local bg = S.read_background(app.state_dir) == "on"
    theme.color(bg and { 40 / 255, 20 / 255, 40 / 255 } or { 0.12, 0.12, 0.12 })
    local by, bh = L.badge_y, 36 * k
    love.graphics.rectangle("fill", x, by, w, bh, bh / 2, bh / 2)
    love.graphics.setLineWidth(2)
    theme.color(bg and c.pink or c.sub)
    love.graphics.rectangle("line", x, by, w, bh, bh / 2, bh / 2)
    theme.print(app.t("background") .. " : " .. app.t(bg and "on" or "off") .. "   ·   L1 + R1",
      theme.font("Bold", 15), x, by + 9 * k, w, "center")
  end

  return s
end

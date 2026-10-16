-- En cours : grande pochette, titre / artiste / album, progression, aléatoire, répéter, badge arrière-plan.
local theme = require("theme")
local covers = require("covers")
local S = require("settings")

local function clock(sec)
  sec = math.max(0, math.floor(sec or 0))
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

return function()
  local s = { ready = true, is_nowplaying = true }

  function s.action(a)
    if a == "back" or a == "ok" then app.pop()
    elseif a == "left" then app.mpd:command("previous")
    elseif a == "right" then app.mpd:command("next")
    end
  end

  function s.draw()
    local c = theme.colors
    local st, song = app.status or {}, app.song
    theme.title_bar(app.t("now_playing"), app.playing(), app.battery)
    theme.cover(covers.get(song and song.file, 300), 30, 66, 270, 60)
    local x, w = 330, 360
    if song then
      local pos, total = tonumber(st.song), tonumber(st.playlistlength)
      if pos and total then
        theme.color(c.sub)
        theme.print(app.t("n_of", pos + 1, total), theme.font("Regular", 16), x, 82, w)
      end
      theme.color(c.text)
      theme.print(song.Title or song.file:match("[^/]+$"), theme.font("Bold", 32), x, 116, w)
      theme.print(song.Artist or app.t("unknown"), theme.font("Regular", 22), x, 166, w)
      theme.color(c.sub)
      theme.print(song.Album or "", theme.font("Regular", 20), x, 200, w)
    end
    local elapsed, duration = tonumber(st.elapsed) or 0, tonumber(st.duration) or 0
    local f = duration > 0 and math.min(1, elapsed / duration) or 0
    theme.color({ 0.24, 0.24, 0.24 })
    love.graphics.rectangle("fill", x, 300, w, 8, 4, 4)
    theme.color(c.pink)
    love.graphics.rectangle("fill", x, 300, w * f, 8, 4, 4)
    theme.color(c.text)
    love.graphics.circle("fill", x + w * f, 304, 7)
    theme.color(c.sub)
    theme.print(clock(elapsed), theme.font("Regular", 16), x, 322, 100)
    theme.print("-" .. clock(duration - elapsed), theme.font("Regular", 16), x + w - 100, 322, 100, "right")
    local small = theme.font("Regular", 16)
    theme.color(st.random == "1" and c.pink or c.sub)
    theme.print(app.t("shuffle") .. "  (Y)", small, x, 372, 150)
    local mode = require("playmode").repeat_mode(st)
    theme.color(mode ~= "off" and c.pink or c.sub)
    theme.print(app.t("repeat") .. (mode ~= "off" and (" : " .. app.t("repeat_" .. mode)) or "") .. "  (X)", small, x + 150, 372, 210)
    local bg = S.read_background(app.state_dir) == "on"
    theme.color(bg and { 40 / 255, 20 / 255, 40 / 255 } or { 0.12, 0.12, 0.12 })
    love.graphics.rectangle("fill", x, 420, w, 36, 18, 18)
    love.graphics.setLineWidth(2)
    theme.color(bg and c.pink or c.sub)
    love.graphics.rectangle("line", x, 420, w, 36, 18, 18)
    theme.print(app.t("background") .. " : " .. app.t(bg and "on" or "off") .. "   ·   L1 + R1",
      theme.font("Bold", 15), x, 429, w, "center")
  end

  return s
end

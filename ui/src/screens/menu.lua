-- Menu principal et navigation vers les listes (spec §4).
local L = require("library")
local list = require("screens.list")

local nav = {}

local function name_or_unknown(n) return n ~= "" and n or app.t("unknown") end

function nav.tracks(title, tracks)
  local items = {}
  for i, t in ipairs(tracks) do
    items[i] = {
      label = t.Title or t.file:match("[^/]+$"),
      cover_file = t.file,
      caption = name_or_unknown(t.Artist or ""),
      on_ok = function() app.play_list(tracks, i) end,
    }
  end
  app.push(list({ title = title, items = items }))
end

function nav.album(name)
  nav.tracks(name_or_unknown(name), L.tracks_of_album(app.songs, name))
end

local function album_items(albums)
  local items = {}
  for i, a in ipairs(albums) do
    items[i] = {
      label = name_or_unknown(a.name),
      cover_file = a.first_file,
      caption = app.t("n_songs", a.count),
      on_ok = function() nav.album(a.name) end,
    }
  end
  return items
end

function nav.playlists()
  app.push(list({ title = app.t("playlists"), items = album_items(L.albums(app.songs)) }))
end

function nav.artists()
  local items = {}
  for i, a in ipairs(L.artists(app.songs)) do
    local tracks = L.tracks_of_artist(app.songs, a.name)
    items[i] = {
      label = name_or_unknown(a.name),
      cover_file = tracks[1] and tracks[1].file,
      caption = app.t("n_songs", a.count),
      on_ok = function() nav.tracks(name_or_unknown(a.name), tracks) end,
    }
  end
  app.push(list({ title = app.t("artists"), items = items }))
end

function nav.genres()
  local items = {}
  for i, g in ipairs(L.genres(app.songs)) do
    local albums = L.albums_of_genre(app.songs, g.name)
    items[i] = {
      label = name_or_unknown(g.name),
      cover_file = albums[1] and albums[1].first_file,
      caption = app.t("n_songs", g.count),
      on_ok = function()
        app.push(list({ title = name_or_unknown(g.name), items = album_items(albums) }))
      end,
    }
  end
  app.push(list({ title = app.t("genres"), items = items }))
end

function nav.songs()
  nav.tracks(app.t("songs"), L.all_tracks(app.songs))
end

function nav.shuffle_all()
  local r = app.mpd:command("command_list_begin\nclear\nadd \"\"\nrandom 1\nplay\ncommand_list_end")
  if not r.ok then app.log("lecture aléatoire impossible : " .. tostring(r.err)) end
  app.push(require("screens.nowplaying")())
end

return function()
  local albums = L.albums(app.songs)
  local counts = {}
  for _, a in ipairs(albums) do counts[a.name] = a.count end
  local function current_cover()
    if app.song and app.song.file then return app.song.file end
    return albums[1] and albums[1].first_file
  end
  local function current_caption()
    local name = app.song and app.song.file and (app.song.Album or "") or (albums[1] and albums[1].name)
    if not name or not counts[name] then return nil end
    return name_or_unknown(name) .. " · " .. app.t("n_songs", counts[name])
  end
  local items = {
    { label = app.t("cover_flow"), on_ok = function() app.push(require("screens.coverflow")()) end },
    { label = app.t("playlists"), on_ok = nav.playlists },
    { label = app.t("artists"), on_ok = nav.artists },
    { label = app.t("songs"), on_ok = nav.songs },
    { label = app.t("genres"), on_ok = nav.genres },
    { label = app.t("shuffle_all"), on_ok = nav.shuffle_all },
    { label = app.t("now_playing"), on_ok = function() app.push(require("screens.nowplaying")()) end },
    { label = app.t("settings"), on_ok = function() app.push(require("screens.settings")()) end },
  }
  app.nav = nav
  return list({
    title = nil, items = items, on_back = app.quit,
    default_cover = current_cover, default_caption = current_caption,
  })
end

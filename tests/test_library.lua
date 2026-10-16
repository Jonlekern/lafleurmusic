local L = require("library")

local function song(file, title, artist, album, genre, track)
  return { file = file, Title = title, Artist = artist, Album = album, Genre = genre, Track = track }
end

local SONGS = {
  song("1.mp3", "Zèbre", "Öwnboss", "Émo", "Emo", "10"),
  song("2.mp3", "alpha", "Phoenix", "Émo", "Emo", "2/12"),
  song("3.mp3", "Beta", "Phoenix", "abc", "EDM", nil),
  song("4.mp3", "gamma", "Avril", "Émo", "Emo", "03"),
  song("5.mp3", "Delta", "Avril", "Zed", "EDM", "1"),
  song("6.mp3", "Sans tags", nil, nil, nil, nil),
}

local function names(list)
  local out = {}
  for i, x in ipairs(list) do out[i] = x.name end
  return out
end

local function titles(list)
  local out = {}
  for i, x in ipairs(list) do out[i] = x.Title end
  return out
end

return {
  ["sort_key ignore casse et accents"] = function()
    eq(L.sort_key("Émo"), "emo")
    eq(L.sort_key("Öwnboss Ça"), "ownboss ca")
  end,
  ["track_number lit les formats courants"] = function()
    eq(L.track_number("3/12"), 3)
    eq(L.track_number("03"), 3)
    eq(L.track_number(""), math.huge)
    eq(L.track_number(nil), math.huge)
  end,
  ["albums triés sans tenir compte des accents"] = function()
    eq(names(L.albums(SONGS)), { "", "abc", "Émo", "Zed" })
  end,
  ["albums comptent les morceaux et gardent un fichier"] = function()
    local emo = L.albums(SONGS)[3]
    eq(emo.count, 3)
    eq(emo.first_file, "1.mp3")
  end,
  ["morceaux d'un album triés par piste puis titre"] = function()
    eq(titles(L.tracks_of_album(SONGS, "Émo")), { "alpha", "gamma", "Zèbre" })
  end,
  ["piste absente en dernier"] = function()
    local s = {
      song("a", "B", "x", "A", "g", nil),
      song("b", "A", "x", "A", "g", "1"),
    }
    eq(titles(L.tracks_of_album(s, "A")), { "A", "B" })
  end,
  ["artistes triés avec compte"] = function()
    local a = L.artists(SONGS)
    eq(names(a), { "", "Avril", "Öwnboss", "Phoenix" })
    eq(a[2].count, 2)
  end,
  ["morceaux d'un artiste"] = function()
    eq(titles(L.tracks_of_artist(SONGS, "Phoenix")), { "alpha", "Beta" })
  end,
  ["genres avec compte"] = function()
    local g = L.genres(SONGS)
    eq(names(g), { "", "EDM", "Emo" })
    eq(g[2].count, 2)
  end,
  ["albums d'un genre seulement"] = function()
    eq(names(L.albums_of_genre(SONGS, "EDM")), { "abc", "Zed" })
  end,
  ["tous les morceaux triés par titre"] = function()
    eq(titles(L.all_tracks(SONGS)), { "alpha", "Beta", "Delta", "gamma", "Sans tags", "Zèbre" })
  end,
}

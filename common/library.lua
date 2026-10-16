-- Regroupements et tris de la bibliothèque (morceaux venant de MPD listallinfo).
local L = {}

local FOLD = {}
do
  local groups = {
    a = "àáâãäåÀÁÂÃÄÅ", c = "çÇ", e = "èéêëÈÉÊË", i = "ìíîïÌÍÎÏ", n = "ñÑ",
    o = "òóôõöøÒÓÔÕÖØ", u = "ùúûüÙÚÛÜ", y = "ýÿÝ", ae = "æÆ", oe = "œŒ", ss = "ß",
  }
  for base, chars in pairs(groups) do
    for ch in chars:gmatch("[\192-\244][\128-\191]*") do FOLD[ch] = base end
  end
end

function L.sort_key(s)
  s = (s or ""):gsub("[\192-\244][\128-\191]*", function(ch) return FOLD[ch] end)
  return s:lower()
end

function L.track_number(t)
  local n = t and tonumber(t:match("^%s*(%d+)"))
  return n or math.huge
end

local function by_key(field)
  return function(a, b)
    local ka, kb = L.sort_key(a[field]), L.sort_key(b[field])
    if ka ~= kb then return ka < kb end
    return (a[field] or "") < (b[field] or "")
  end
end

local function sort_tracks_by_title(list)
  table.sort(list, function(a, b)
    local ka, kb = L.sort_key(a.Title), L.sort_key(b.Title)
    if ka ~= kb then return ka < kb end
    return a.file < b.file
  end)
  return list
end

-- Groupes {name, count, first_file} sur un tag, filtrés par keep(song) si donné.
local function group(songs, tag, keep)
  local by, out = {}, {}
  for _, s in ipairs(songs) do
    if not keep or keep(s) then
      local name = s[tag] or ""
      local g = by[name]
      if not g then
        g = { name = name, count = 0, first_file = s.file }
        by[name] = g
        out[#out + 1] = g
      end
      g.count = g.count + 1
    end
  end
  table.sort(out, by_key("name"))
  return out
end

local function filter(songs, tag, value)
  local out = {}
  for _, s in ipairs(songs) do
    if (s[tag] or "") == value then out[#out + 1] = s end
  end
  return out
end

function L.albums(songs) return group(songs, "Album") end
function L.artists(songs) return group(songs, "Artist") end
function L.genres(songs) return group(songs, "Genre") end

function L.albums_of_genre(songs, genre)
  return group(songs, "Album", function(s) return (s.Genre or "") == genre end)
end

function L.tracks_of_album(songs, album)
  local list = filter(songs, "Album", album)
  table.sort(list, function(a, b)
    local na, nb = L.track_number(a.Track), L.track_number(b.Track)
    if na ~= nb then return na < nb end
    local ka, kb = L.sort_key(a.Title), L.sort_key(b.Title)
    if ka ~= kb then return ka < kb end
    return a.file < b.file
  end)
  return list
end

function L.tracks_of_artist(songs, artist)
  return sort_tracks_by_title(filter(songs, "Artist", artist))
end

function L.all_tracks(songs)
  local list = {}
  for i, s in ipairs(songs) do list[i] = s end
  return sort_tracks_by_title(list)
end

return L

local P = require("mpd_protocol")

return {
  ["quote échappe les guillemets"] = function()
    eq(P.quote('Little "Talks"'), '"Little \\"Talks\\""')
  end,
  ["quote échappe l'antislash"] = function()
    eq(P.quote("a\\b"), '"a\\\\b"')
  end,
  ["quote garde les accents"] = function()
    eq(P.quote("Öwnboss"), '"Öwnboss"')
  end,
  ["parse une réponse OK"] = function()
    local r = P.parse({ "volume: 60", "state: play", "OK" })
    eq(r.ok, true)
    eq(r.pairs, { { "volume", "60" }, { "state", "play" } })
  end,
  ["parse une erreur ACK"] = function()
    local r = P.parse({ "ACK [50@0] {find} no such song" })
    eq(r.ok, false)
    eq(r.err, "no such song")
  end,
  ["parse garde tout après le premier deux-points"] = function()
    local r = P.parse({ "Title: Ça: va", "OK" })
    eq(r.pairs, { { "Title", "Ça: va" } })
  end,
  ["records découpe sur la première clé"] = function()
    local recs = P.records({ { "file", "a.mp3" }, { "Title", "A" }, { "file", "b.mp3" }, { "Title", "B" } }, "file")
    eq(recs, { { file = "a.mp3", Title = "A" }, { file = "b.mp3", Title = "B" } })
  end,
  ["records ignore les paires avant la première clé"] = function()
    local recs = P.records({ { "directory", "EDM" }, { "file", "a.mp3" } }, "file")
    eq(recs, { { file = "a.mp3" } })
  end,
  ["binary_header lit size et binary"] = function()
    eq(P.binary_header({ { "size", "6" }, { "type", "image/jpeg" }, { "binary", "3" } }), { size = 6, binary = 3 })
  end,
}

local C = require("mpd_client")
local F = require("fake_socket")

local BANNER = "OK MPD 0.23.17\n"

return {
  ["command renvoie les paires"] = function()
    local connect = F.connector({ F.new({ output = BANNER .. "state: play\nOK\n" }) })
    local c = C.new({ connect = connect })
    local r = c:command("status")
    eq(r.ok, true)
    eq(r.pairs, { { "state", "play" } })
  end,
  ["command envoie la ligne terminée par un retour"] = function()
    local s = F.new({ output = BANNER .. "OK\n" })
    local c = C.new({ connect = F.connector({ s }) })
    c:command("pause")
    eq(s.sent, { "pause\n" })
  end,
  ["command se reconnecte une fois"] = function()
    local connect, calls = F.connector({
      F.new({ output = BANNER, fail_send = 1 }),
      F.new({ output = BANNER .. "OK\n" }),
    })
    local c = C.new({ connect = connect })
    local r = c:command("play")
    eq(r.ok, true)
    eq(calls.n, 2)
  end,
  ["deux échecs donnent unavailable sans troisième essai"] = function()
    local connect, calls = F.connector({
      F.new({ output = BANNER, fail_send = 1 }),
      F.new({ output = BANNER, fail_send = 1 }),
      F.new({ output = BANNER .. "OK\n" }),
    })
    local c = C.new({ connect = connect })
    local r = c:command("play")
    eq(r, { ok = false, err = "unavailable", pairs = {} })
    eq(calls.n, 2)
  end,
  ["connexion refusée donne unavailable"] = function()
    local c = C.new({ connect = F.connector({}) })
    eq(c:command("status").err, "unavailable")
  end,
  ["songs renvoie des enregistrements file"] = function()
    local out = BANNER .. "directory: EDM\nfile: a.mp3\nTitle: A\nfile: b.mp3\nTitle: B\nOK\n"
    local c = C.new({ connect = F.connector({ F.new({ output = out }) }) })
    eq(c:songs(), { { file = "a.mp3", Title = "A" }, { file = "b.mp3", Title = "B" } })
  end,
  ["status et currentsong"] = function()
    local out = BANNER .. "state: pause\nelapsed: 3.5\nOK\nfile: a.mp3\nTitle: A\nOK\nOK\n"
    local c = C.new({ connect = F.connector({ F.new({ output = out }) }) })
    eq(c:status(), { state = "pause", elapsed = "3.5" })
    eq(c:currentsong(), { file = "a.mp3", Title = "A" })
    eq(c:currentsong(), nil)
  end,
  ["picture reconstitue l'image en deux morceaux"] = function()
    local out = BANNER
      .. "size: 6\ntype: image/jpeg\nbinary: 3\nabc\nOK\n"
      .. "size: 6\nbinary: 3\ndef\nOK\n"
    local s = F.new({ output = out })
    local c = C.new({ connect = F.connector({ s }) })
    eq(c:picture("x.mp3"), "abcdef")
    eq(s.sent, { 'readpicture "x.mp3" 0\n', 'readpicture "x.mp3" 3\n' })
  end,
  ["picture renvoie nil sans pochette"] = function()
    local c = C.new({ connect = F.connector({ F.new({ output = BANNER .. "OK\n" }) }) })
    eq(c:picture("x.mp3"), nil)
  end,
  ["picture renvoie nil sur ACK"] = function()
    local c = C.new({ connect = F.connector({ F.new({ output = BANNER .. "ACK [50@0] {readpicture} No file exists\n" }) }) })
    eq(c:picture("x.mp3"), nil)
  end,
}

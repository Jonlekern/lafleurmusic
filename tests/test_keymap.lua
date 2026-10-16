local K = require("keymap")

return {
  ["défauts sans réglages"] = function()
    local km = K.load({})
    eq(km.open.toggle_background, "l1+r1")
    eq(km.closed.next, "r1+r2")
    eq(km.closed.shuffle, "")
    eq(km.ab_swap, false)
  end,
  ["relit ce qui a été stocké"] = function()
    local km, t = K.load({}), {}
    eq(K.assign(km, "open", "shuffle", "l2"), true)
    K.store(t, km)
    eq(t.key_open_shuffle, "l2")
    eq(K.load(t).open.shuffle, "l2")
  end,
  ["touche fixe refusée"] = function()
    local km = K.load({})
    eq({ K.assign(km, "open", "shuffle", "a") }, { false, "reserved" })
    eq(km.open.shuffle, "y")
  end,
  ["touche seule refusée clapet fermé"] = function()
    local km = K.load({})
    eq({ K.assign(km, "closed", "next", "r1") }, { false, "reserved" })
    eq(km.closed.next, "r1+r2")
  end,
  ["clapet fermé accepte A + B"] = function()
    local km = K.load({})
    eq(K.assign(km, "closed", "shuffle", "b+a"), true)
    eq(km.closed.shuffle, "a+b")
  end,
  ["conflit = échange"] = function()
    local km = K.load({})
    K.assign(km, "open", "shuffle", "x")
    eq({ km.open.shuffle, km.open["repeat"] }, { "x", "y" })
  end,
  ["réglage invalide = défaut"] = function()
    eq(K.load({ key_open_shuffle = "a" }).open.shuffle, "y")
    eq(K.load({ key_closed_next = "r1" }).closed.next, "r1+r2")
    eq(K.load({ key_open_shuffle = "x+y+l1" }).open.shuffle, "y")
  end,
  ["doublon à la main : le premier garde"] = function()
    local km = K.load({ key_open_shuffle = "x" })
    eq({ km.open.shuffle, km.open["repeat"] }, { "x", "" })
  end,
  ["ab_swap relu"] = function()
    eq(K.load({ ab_swap = "on" }).ab_swap, true)
    local t = {}
    local km = K.load({}) km.ab_swap = true
    K.store(t, km)
    eq(t.ab_swap, "on")
  end,
  ["libellés"] = function()
    eq(K.label("l1+r1"), "L1 + R1")
    eq(K.label("select"), "SELECT")
    eq(K.label(""), "—")
    eq(K.label("a+up"), "A + ↑")
  end,
  ["normalize : ordre indifférent"] = function()
    eq(K.normalize("r1", "l1"), "l1+r1")
    eq(K.normalize("x"), "x")
    eq(K.split("l1+r1"), { "l1", "r1" })
  end,
  ["reset"] = function()
    local km = K.load({})
    K.assign(km, "open", "shuffle", "l2")
    K.reset(km, "open")
    eq(km.open.shuffle, "y")
  end,
}

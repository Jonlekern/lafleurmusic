local In = require("input")

local function new() return In.new({ window = 0.15, repeat_delay = 0.4, repeat_rate = 0.08 }) end

return {
  ["L1 puis R1 rapprochés basculent l'arrière-plan"] = function()
    local i = new()
    eq(i:press("l1", 0), {})
    eq(i:press("r1", 0.1), { "toggle_background" })
    eq(i:update(0.5), {})
    eq(i:release("l1", 0.6), {})
    eq(i:release("r1", 0.6), {})
  end,
  ["R1 puis L1 basculent aussi"] = function()
    local i = new()
    i:press("r1", 0)
    eq(i:press("l1", 0.05), { "toggle_background" })
  end,
  ["L1 seul donne précédent après la fenêtre"] = function()
    local i = new()
    i:press("l1", 0)
    eq(i:update(0.1), {})
    eq(i:update(0.16), { "previous" })
  end,
  ["R1 trop tard donne suivant sans bascule"] = function()
    local i = new()
    i:press("l1", 0)
    eq(i:update(0.16), { "previous" })
    eq(i:press("r1", 0.2), {})
    eq(i:update(0.36), { "next" })
  end,
  ["L1 maintenu ne répète pas"] = function()
    local i = new()
    i:press("l1", 0)
    eq(i:update(2), { "previous" })
    eq(i:update(3), {})
  end,
  ["L1 relâché tôt donne précédent tout de suite"] = function()
    local i = new()
    i:press("l1", 0)
    eq(i:release("l1", 0.05), { "previous" })
    eq(i:update(0.5), {})
  end,
  ["la croix répète quand elle est maintenue"] = function()
    local i = new()
    eq(i:press("down", 0), { "down" })
    eq(i:update(0.39), {})
    eq(i:update(0.41), { "down" })
    eq(i:update(0.49), { "down" })
    eq(i:release("down", 0.5), {})
    eq(i:update(1), {})
  end,
  ["X et Y pilotent répéter et aléatoire"] = function()
    local i = new()
    eq(i:press("y", 0), { "shuffle" })
    eq(i:press("x", 0), { "repeat" })
  end,
  ["boutons simples"] = function()
    local i = new()
    eq(i:press("start", 0), { "playpause" })
    eq(i:press("select", 0), { "now_playing" })
    eq(i:press("a", 0), { "ok" })
    eq(i:press("b", 0), { "back" })
    eq(i:press("left", 0), { "left" })
    eq(i:press("right", 0), { "right" })
    eq(i:press("up", 0), { "up" })
  end,
}

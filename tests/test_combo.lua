local Combo = require("combo")
local K = require("keymap")

local function new() return Combo.new(K.DEFAULTS.closed) end

return {
  ["L2 puis R2 : lecture / pause"] = function()
    local c = new()
    eq(c:press("l2", 0), {})
    eq(c:press("r2", 0.1), { "playpause" })
  end,
  ["une touche seule ne fait rien"] = function()
    local c = new()
    eq(c:press("r1", 0), {})
    eq(c:release("r1", 3), {})
  end,
  ["trop espacées : rien"] = function()
    local c = new()
    c:press("r1", 0)
    eq(c:press("r2", 0.3), {})
  end,
  ["trois touches : une seule action"] = function()
    local c = new()
    c:press("l1", 0)
    eq(c:press("l2", 0.05), { "previous" })
    eq(c:press("r1", 0.1), {})
  end,
  ["relâcher annule l'attente"] = function()
    local c = new()
    c:press("r1", 0)
    c:release("r1", 0.05)
    eq(c:press("r2", 0.1), {})
  end,
}

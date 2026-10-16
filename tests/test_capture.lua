local Cap = require("capture")

return {
  ["ouvert : une touche relâchée"] = function()
    local c = Cap.new("open", 0)
    eq(c:press("x", 1), nil)
    eq(c:release("x", 1.05), nil)
    eq(c:update(1.1), nil)
    eq(c:update(1.16), { done = "x" })
  end,
  ["ouvert : deux touches ensemble"] = function()
    local c = Cap.new("open", 0)
    c:press("y", 1)
    eq(c:press("x", 1.1), { done = "x+y" })
  end,
  ["fermé : une touche seule ne suffit pas"] = function()
    local c = Cap.new("closed", 0)
    c:press("r1", 1)
    eq(c:update(1.16), nil)
    eq(c:update(2), nil)
  end,
  ["fermé : deux touches"] = function()
    local c = Cap.new("closed", 0)
    c:press("r1", 1)
    eq(c:press("r2", 1.05), { done = "r1+r2" })
  end,
  ["fermé : la croix et A sont réservées (inaccessibles clapet fermé)"] = function()
    eq(Cap.new("closed", 0):press("up", 1), { reserved = true })
    eq(Cap.new("closed", 0):press("a", 1), { reserved = true })
  end,
  ["ouvert : touche fixe réservée"] = function()
    eq(Cap.new("open", 0):press("a", 1), { reserved = true })
    eq(Cap.new("open", 0):press("menu", 1), { reserved = true })
  end,
  ["fermé : MENU réservé"] = function()
    eq(Cap.new("closed", 0):press("menu", 1), { reserved = true })
  end,
  ["rien pendant 5 s : annulé"] = function()
    local c = Cap.new("open", 0)
    eq(c:update(4.9), nil)
    eq(c:update(5), { cancelled = true })
  end,
  ["un appui relance les 5 s"] = function()
    local c = Cap.new("closed", 0)
    c:press("r1", 4)
    eq(c:update(5.5), nil)
    eq(c:update(9), { cancelled = true })
  end,
}

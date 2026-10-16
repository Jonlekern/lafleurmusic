local T = require("text")

local function m(s) return #s * 10 end

local function utf8_ok(s)
  local i, n = 1, #s
  while i <= n do
    local c = s:byte(i)
    local len = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or 4
    if c >= 0x80 and c < 0xC0 then return false end
    for j = i + 1, i + len - 1 do
      local cc = s:byte(j)
      if not cc or cc < 0x80 or cc >= 0xC0 then return false end
    end
    i = i + len
  end
  return true
end

return {
  ["texte court inchangé"] = function()
    eq(T.fit_text("1901", 100, m), "1901")
  end,
  ["texte long coupé avec points de suspension"] = function()
    local r = T.fit_text("Long Cool Woman", 80, m)
    truthy(r:sub(-3) == "…", "finit par … : " .. r)
    truthy(m(r) <= 80, "trop large : " .. r)
    local prefix = r:sub(1, -4)
    eq(("Long Cool Woman"):sub(1, #prefix), prefix)
    truthy(#prefix > 0, "préfixe vide")
  end,
  ["ne coupe jamais au milieu d'un caractère"] = function()
    for w = 30, 120, 10 do
      local r = T.fit_text("Ééééééé", w, m)
      truthy(utf8_ok(r), "UTF-8 invalide pour " .. w .. " : " .. r)
    end
  end,
  ["place nulle donne juste les points"] = function()
    eq(T.fit_text("abc", 0, m), "…")
  end,
}

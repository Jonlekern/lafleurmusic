local S = require("settings")

local function tmpdir()
  local d = os.tmpname()
  os.remove(d)
  os.execute("mkdir -p '" .. d .. "'")
  return d
end

local function write(path, text)
  local f = assert(io.open(path, "w"))
  f:write(text)
  f:close()
end

return {
  ["save puis load"] = function()
    local d = tmpdir()
    S.save(d .. "/settings.txt", { background_default = "off" })
    eq(S.load(d .. "/settings.txt"), { background_default = "off" })
  end,
  ["fichier absent donne les valeurs par défaut"] = function()
    eq(S.load(tmpdir() .. "/rien.txt"), { background_default = "off" })
  end,
  ["load ne modifie pas DEFAULTS"] = function()
    local t = S.load(tmpdir() .. "/rien.txt")
    t.background_default = "on"
    eq(S.DEFAULTS.background_default, "off")
  end,
  ["ligne mal formée ignorée"] = function()
    local d = tmpdir()
    write(d .. "/s.txt", "n'importe quoi\nbackground_default=off\n=vide\n")
    eq(S.load(d .. "/s.txt"), { background_default = "off" })
  end,
  ["read_background sans fichier donne off"] = function()
    eq(S.read_background(tmpdir()), "off")
  end,
  ["write puis read_background"] = function()
    local d = tmpdir()
    S.write_background(d, "off")
    eq(S.read_background(d), "off")
    S.write_background(d, "on")
    eq(S.read_background(d), "on")
  end,
  ["read_background valeur inconnue donne off"] = function()
    local d = tmpdir()
    write(d .. "/background", "peut-être\n")
    eq(S.read_background(d), "off")
  end,
}

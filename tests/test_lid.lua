local lid = require("lid")

local DEVICES = [[
I: Bus=0019 Vendor=0001 Product=0001 Version=0100
N: Name="axp20x-pek"
P: Phys=m1kbd/input2
H: Handlers=kbd event0
B: PROP=0
B: EV=3
B: KEY=10000000000000 0

I: Bus=0019 Vendor=0000 Product=0000 Version=0000
N: Name="gpio-keys-lid"
H: Handlers=event2
B: PROP=0
B: EV=21
B: SW=1
]]

local function u16(n) return string.char(n % 256, math.floor(n / 256) % 256) end
local function s32(n)
  if n < 0 then n = n + 2 ^ 32 end
  return string.char(n % 256, math.floor(n / 256) % 256, math.floor(n / 65536) % 256, math.floor(n / 16777216) % 256)
end
local function event(type_, code, value)
  return string.rep("\0", 16) .. u16(type_) .. u16(code) .. s32(value)
end

return {
  ["find_device trouve le bloc avec SW_LID"] = function()
    eq(lid.find_device(DEVICES), "/dev/input/event2")
  end,
  ["find_device ignore un bloc sans SW"] = function()
    eq(lid.find_device(DEVICES:gsub("B: SW=1\n", "")), nil)
  end,
  ["find_device ignore SW sans le bit 0"] = function()
    eq(lid.find_device(DEVICES:gsub("B: SW=1", "B: SW=2")), nil)
  end,
  ["find_device accepte SW=3"] = function()
    eq(lid.find_device(DEVICES:gsub("B: SW=1", "B: SW=3")), "/dev/input/event2")
  end,
  ["find_device sans texte"] = function()
    eq(lid.find_device(nil), nil)
  end,
  ["decode un événement clapet fermé"] = function()
    eq(lid.decode(event(5, 0, 1)), { type = 5, code = 0, value = 1 })
  end,
  ["decode une valeur négative"] = function()
    eq(lid.decode(event(3, 1, -2)).value, -2)
  end,
  ["decode refuse moins de 24 octets"] = function()
    eq(lid.decode(string.rep("\0", 23)), nil)
  end,
  ["lid_state reconnaît fermé et ouvert"] = function()
    eq(lid.lid_state({ type = 5, code = 0, value = 1 }), "closed")
    eq(lid.lid_state({ type = 5, code = 0, value = 0 }), "open")
    eq(lid.lid_state({ type = 1, code = 0, value = 1 }), nil)
  end,
}

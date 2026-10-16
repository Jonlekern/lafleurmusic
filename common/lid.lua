-- Interrupteur du clapet : périphérique evdev qui annonce SW_LID, et décodage des événements.
local lid = {}

local EV_SW, SW_LID = 5, 0

-- Codes evdev de la manette « H700 Gamepad » de la RG SP (relevés le 16.10.2026).
lid.KEYCODES = {
  [304] = "b", [305] = "a", [307] = "y", [308] = "x", [310] = "l1", [311] = "r1", [312] = "l2", [313] = "r2",
  [314] = "select", [315] = "start", [316] = "menu", [544] = "up", [545] = "down", [546] = "left", [547] = "right",
}

-- Premier bloc de /proc/bus/input/devices dont « B: SW= » a le bit SW_LID.
function lid.find_device(text)
  if not text then return nil end
  for block in (text .. "\n\n"):gmatch("(.-)\n%s*\n") do
    local sw = block:match("B: SW=([%x ]+)")
    local handler = block:match("H: Handlers=[^\n]*(event%d+)")
    if sw and handler then
      local words = {}
      for w in sw:gmatch("%x+") do words[#words + 1] = w end
      local low = tonumber(words[#words], 16) or 0
      if low % 2 == 1 then return "/dev/input/" .. handler end
    end
  end
  return nil
end

-- Manette : premier bloc dont « B: KEY= » a le bit BTN_SOUTH (304). Mots hexa de 64 bits, le dernier = bits 0-63.
local BTN_SOUTH = 304
function lid.find_gamepad(text)
  if not text then return nil end
  for block in (text .. "\n\n"):gmatch("(.-)\n%s*\n") do
    local keys = block:match("B: KEY=([%x ]+)")
    local handler = block:match("H: Handlers=[^\n]*(event%d+)")
    if keys and handler then
      local words = {}
      for w in keys:gmatch("%x+") do table.insert(words, 1, w) end
      local word = words[math.floor(BTN_SOUTH / 64) + 1]
      local bit = BTN_SOUTH % 64
      local pos = #(word or "") - math.floor(bit / 4)
      local digit = pos >= 1 and tonumber(word:sub(pos, pos), 16)
      if digit and math.floor(digit / 2 ^ (bit % 4)) % 2 == 1 then
        return "/dev/input/" .. handler
      end
    end
  end
  return nil
end

local function u16(s, i) return s:byte(i) + s:byte(i + 1) * 256 end

-- Événement input_event aarch64 : timeval (16 octets), u16 type, u16 code, s32 value, little-endian.
function lid.decode(bytes)
  if not bytes or #bytes < 24 then return nil end
  local v = u16(bytes, 21) + u16(bytes, 23) * 65536
  if v >= 2 ^ 31 then v = v - 2 ^ 32 end
  return { type = u16(bytes, 17), code = u16(bytes, 19), value = v }
end

-- EV_KEY (1) : renvoie code, valeur (1 appui, 0 relâchement, 2 répétition) ; sinon nil.
function lid.key_event(ev)
  if ev and ev.type == 1 then return ev.code, ev.value end
  return nil
end

-- Message du canal « lid » : erreur du clapet (arrête le gardien), erreur de la manette (on continue sans), touche ou clapet.
function lid.message_kind(msg)
  if msg:match("^error") then return "fatal" end
  if msg:match("^paderror") then return "pad_error" end
  if msg:match("^key:") then return "key" end
  return "lid"
end

function lid.lid_state(ev)
  if ev and ev.type == EV_SW and ev.code == SW_LID then
    return ev.value ~= 0 and "closed" or "open"
  end
  return nil
end

return lid

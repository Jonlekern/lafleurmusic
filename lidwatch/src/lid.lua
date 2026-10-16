-- Interrupteur du clapet : périphérique evdev qui annonce SW_LID, et décodage des événements.
local lid = {}

local EV_SW, SW_LID = 5, 0

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

local function u16(s, i) return s:byte(i) + s:byte(i + 1) * 256 end

-- Événement input_event aarch64 : timeval (16 octets), u16 type, u16 code, s32 value, little-endian.
function lid.decode(bytes)
  if not bytes or #bytes < 24 then return nil end
  local v = u16(bytes, 21) + u16(bytes, 23) * 65536
  if v >= 2 ^ 31 then v = v - 2 ^ 32 end
  return { type = u16(bytes, 17), code = u16(bytes, 19), value = v }
end

function lid.lid_state(ev)
  if ev and ev.type == EV_SW and ev.code == SW_LID then
    return ev.value ~= 0 and "closed" or "open"
  end
  return nil
end

return lid

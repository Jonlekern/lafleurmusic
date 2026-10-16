-- Fil de lecture bloquante d'un périphérique evdev, sur le canal « lid » :
-- mode "lid" → "closed" / "open" ; mode "pad" → "key:<code>:<valeur>".
love.filesystem.setRequirePath("?.lua;src/?.lua;common/?.lua")
local lid = require("lid")
local device, mode = ...
local channel = love.thread.getChannel("lid")

local f = io.open(device, "rb")
if not f then
  channel:push("error:open " .. device)
  return
end
while true do
  local bytes = f:read(24)
  if not bytes then
    channel:push("error:read " .. device)
    break
  end
  local ev = lid.decode(bytes)
  if mode == "pad" then
    local code, value = lid.key_event(ev)
    if code then channel:push("key:" .. code .. ":" .. value) end
  else
    local state = lid.lid_state(ev)
    if state then channel:push(state) end
  end
end
f:close()

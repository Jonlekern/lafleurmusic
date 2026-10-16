-- Fil de lecture bloquante du périphérique du clapet ; envoie "closed" / "open" sur le canal « lid ».
love.filesystem.setRequirePath("?.lua;src/?.lua")
local lid = require("lid")
local device = ...
local channel = love.thread.getChannel("lid")

local f = io.open(device, "rb")
if not f then
  channel:push("error:open " .. device)
  return
end
while true do
  local bytes = f:read(24)
  if not bytes then
    channel:push("error:read")
    break
  end
  local state = lid.lid_state(lid.decode(bytes))
  if state then channel:push(state) end
end
f:close()

-- Modes de lecture : aléatoire (random) et répéter off / tout / un seul (repeat + single de MPD).
local PM = {}

local NEXT = { off = "all", all = "one", one = "off" }
local FLAGS = { off = { 0, 0 }, all = { 1, 0 }, one = { 1, 1 } }

function PM.repeat_mode(status)
  status = status or {}
  if status["repeat"] ~= "1" then return "off" end
  return status.single == "1" and "one" or "all"
end

function PM.next_repeat(mode) return NEXT[mode] or "all" end

function PM.repeat_commands(mode)
  local f = FLAGS[mode]
  return "command_list_begin\nrepeat " .. f[1] .. "\nsingle " .. f[2] .. "\ncommand_list_end"
end

function PM.shuffle_command(status)
  return (status and status.random == "1") and "random 0" or "random 1"
end

return PM

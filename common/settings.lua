-- Réglages de l'appli (fichier key=value) et état « background » partagé UI / lanceur / lidwatch.
-- Aléatoire et répéter sont gardés par MPD lui-même (state_file).
local S = {}

S.DEFAULTS = { background_default = "on" }

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function write_atomic(path, text)
  local tmp = path .. ".tmp"
  local f = assert(io.open(tmp, "w"))
  f:write(text)
  f:close()
  assert(os.rename(tmp, path))
end

function S.load(path)
  local t = {}
  for k, v in pairs(S.DEFAULTS) do t[k] = v end
  local text = read_file(path)
  if text then
    for key, value in text:gmatch("([%w_]+)=([^\n]*)") do t[key] = value end
  end
  return t
end

function S.save(path, tbl)
  local keys = {}
  for k in pairs(tbl) do keys[#keys + 1] = k end
  table.sort(keys)
  local lines = {}
  for _, k in ipairs(keys) do lines[#lines + 1] = k .. "=" .. tostring(tbl[k]) end
  write_atomic(path, table.concat(lines, "\n") .. "\n")
end

function S.read_background(state_dir)
  local text = read_file(state_dir .. "/background")
  if text and text:match("^off") then return "off" end
  return "on"
end

function S.write_background(state_dir, value)
  write_atomic(state_dir .. "/background", (value == "off" and "off" or "on") .. "\n")
end

return S

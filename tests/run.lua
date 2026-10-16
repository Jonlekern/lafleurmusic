-- Lanceur de tests minimal : luajit tests/run.lua [filtre]
-- Chaque tests/test_*.lua renvoie { ["nom"] = function() ... end }.
package.path = "common/?.lua;ui/src/?.lua;lidwatch/src/?.lua;tests/?.lua;" .. package.path

local function deep_eq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do
    if not deep_eq(v, b[k]) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

local function show(v, depth)
  depth = depth or 0
  if type(v) == "string" then return string.format("%q", v) end
  if type(v) ~= "table" or depth > 3 then return tostring(v) end
  local parts = {}
  for k, x in pairs(v) do
    parts[#parts + 1] = "[" .. show(k, depth + 1) .. "]=" .. show(x, depth + 1)
  end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end

function eq(actual, expected, msg)
  if not deep_eq(actual, expected) then
    error((msg and (msg .. ": ") or "") .. "attendu " .. show(expected) .. ", obtenu " .. show(actual), 2)
  end
end

function truthy(v, msg)
  if not v then error(msg or "valeur fausse", 2) end
end

local filter = arg[1]
local files = {}
local p = io.popen("ls tests/test_*.lua 2>/dev/null")
for line in p:lines() do files[#files + 1] = line end
p:close()

local failed, passed = 0, 0
for _, file in ipairs(files) do
  local mod = file:match("tests/(test_[%w_]+)%.lua")
  if not filter or mod:find(filter, 1, true) then
    local ok, tests = pcall(dofile, file)
    if not ok then
      failed = failed + 1
      print("FAIL " .. mod .. " (chargement) : " .. tostring(tests))
    else
      local names = {}
      for name in pairs(tests) do names[#names + 1] = name end
      table.sort(names)
      for _, name in ipairs(names) do
        local ok2, err = pcall(tests[name])
        if ok2 then
          passed = passed + 1
          print("ok   " .. mod .. ": " .. name)
        else
          failed = failed + 1
          print("FAIL " .. mod .. ": " .. name .. "\n     " .. tostring(err))
        end
      end
    end
  end
end

print(string.format("\n%d ok, %d échec(s)", passed, failed))
os.exit(failed == 0 and 0 or 1)

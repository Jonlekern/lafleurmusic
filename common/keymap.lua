-- Touches personnalisées : une touche ou deux ensemble par raccourci, clapet ouvert et clapet fermé.
-- Données pures, partagées par l'interface et le gardien du clapet ; rangées dans settings.txt.
local K = {}

K.ACTIONS = { "playpause", "next", "previous", "shuffle", "repeat", "now_playing", "toggle_background" }
K.CLOSED_ACTIONS = { "playpause", "next", "previous", "shuffle", "repeat" }

K.DEFAULTS = {
  open = { playpause = "start", next = "r1", previous = "l1", shuffle = "y", ["repeat"] = "x",
    now_playing = "select", toggle_background = "l1+r1" },
  closed = { playpause = "l2+r2", next = "r1+r2", previous = "l1+l2", shuffle = "", ["repeat"] = "" },
}

local BASE = { x = true, y = true, start = true, select = true, l1 = true, r1 = true, l2 = true, r2 = true }
local USABLE = {
  open = BASE,
  closed = setmetatable({ a = true, b = true, up = true, down = true, left = true, right = true }, { __index = BASE }),
}
local NAMES = { up = "↑", down = "↓", left = "←", right = "→" }

local function actions_of(side) return side == "open" and K.ACTIONS or K.CLOSED_ACTIONS end

function K.split(combo)
  local t = {}
  for b in (combo or ""):gmatch("[^+]+") do t[#t + 1] = b end
  return t
end

function K.normalize(a, b)
  if not b or a == b then return a end
  if b < a then a, b = b, a end
  return a .. "+" .. b
end

-- Touche utilisable seule ou dans une combinaison de ce côté.
function K.usable(side, btn) return USABLE[side][btn] == true end

-- "" (aucune touche) est toujours valable ; clapet fermé, il faut deux touches.
function K.valid(side, combo)
  if combo == "" then return true end
  local parts = K.split(combo)
  if #parts < 1 or #parts > 2 then return false end
  if side == "closed" and #parts ~= 2 then return false end
  if #parts == 2 and parts[1] == parts[2] then return false end
  for _, b in ipairs(parts) do
    if not USABLE[side][b] then return false end
  end
  return true
end

local function copy(t)
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end

function K.load(settings)
  settings = settings or {}
  local km = { ab_swap = settings.ab_swap == "on" }
  for _, side in ipairs({ "open", "closed" }) do
    local map, used = {}, {}
    for _, action in ipairs(actions_of(side)) do
      local v = settings["key_" .. side .. "_" .. action]
      if v then
        local p = K.split(v)
        v = p[1] and K.normalize(p[1], p[2]) or ""
        if #p > 2 then v = nil end
      end
      if v == nil or not K.valid(side, v) then v = K.DEFAULTS[side][action] end
      map[action] = v
    end
    -- un doublon (réglage modifié à la main) : la première action dans l'ordre garde la combinaison
    for _, action in ipairs(actions_of(side)) do
      local v = map[action]
      if v ~= "" then
        if used[v] then map[action] = "" else used[v] = true end
      end
    end
    km[side] = map
  end
  return km
end

function K.store(settings, km)
  for _, side in ipairs({ "open", "closed" }) do
    for _, action in ipairs(actions_of(side)) do
      settings["key_" .. side .. "_" .. action] = km[side][action]
    end
  end
  settings.ab_swap = km.ab_swap and "on" or "off"
end

-- Combinaison déjà prise par une autre action → celle-ci reçoit l'ancienne combinaison de `action`.
function K.assign(km, side, action, combo)
  local p = K.split(combo)
  combo = p[1] and K.normalize(p[1], p[2]) or ""
  if #p > 2 or not K.valid(side, combo) then return false, "reserved" end
  local map = km[side]
  local old = map[action]
  for _, other in ipairs(actions_of(side)) do
    if other ~= action and combo ~= "" and map[other] == combo then map[other] = old end
  end
  map[action] = combo
  return true
end

function K.reset(km, side)
  km[side] = copy(K.DEFAULTS[side])
  if side == "open" then km.ab_swap = false end
end

function K.label(combo)
  if not combo or combo == "" then return "—" end
  local parts = {}
  for i, b in ipairs(K.split(combo)) do parts[i] = NAMES[b] or b:upper() end
  return table.concat(parts, " + ")
end

return K

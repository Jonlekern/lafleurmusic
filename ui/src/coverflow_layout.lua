-- Disposition du Cover Flow sur 720×480 (valeurs de maquettes/2-coverflow.png).
local CF = {}

local Y, H, CENTER_W, SIDE_W = 70, 240, 240, 110
-- x du bord gauche pour un écart d = index - pos de -3 à +3.
local SLOT_X = { [-3] = 20, [-2] = 75, [-1] = 130, [0] = 240, [1] = 480, [2] = 535, [3] = 590 }
local SPEED = 12

local function slot(d)
  local lo = math.floor(d)
  local f = d - lo
  local x0, x1 = SLOT_X[lo], SLOT_X[lo + 1]
  local w0 = lo == 0 and CENTER_W or SIDE_W
  local w1 = lo + 1 == 0 and CENTER_W or SIDE_W
  if f == 0 then return x0, w0 end
  return x0 + (x1 - x0) * f, w0 + (w1 - w0) * f
end

function CF.layout(pos, count)
  local out = {}
  for index = 1, count do
    local d = index - pos
    if d >= -3 and d <= 3 then
      local x, w = slot(d)
      local side = math.abs(d) < 0.5 and "center" or (d < 0 and "left" or "right")
      out[#out + 1] = { index = index, x = x, y = Y, w = w, h = H, side = side, dist = math.abs(d) }
    end
  end
  table.sort(out, function(a, b) return a.dist > b.dist end)
  for _, e in ipairs(out) do e.dist = nil end
  return out
end

function CF.step(pos, target, dt)
  local diff = target - pos
  local move = diff * math.min(1, SPEED * dt)
  local new = pos + move
  if math.abs(target - new) < 0.01 then return target end
  return new
end

return CF

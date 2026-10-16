-- Touches clapet fermé : seules les combinaisons de deux touches (à moins de `window` s) donnent une action.
local K = require("keymap")

local Combo = {}
Combo.__index = Combo

function Combo.new(map, opts)
  local self = setmetatable({ window = (opts and opts.window) or 0.15, pending = {}, combo = {} }, Combo)
  for action, c in pairs(map) do
    local p = K.split(c)
    if #p == 2 then self.combo[K.normalize(p[1], p[2])] = action end
  end
  return self
end

function Combo:press(btn, t)
  for other, t0 in pairs(self.pending) do
    local action = self.combo[K.normalize(btn, other)]
    if action and t - t0 <= self.window then
      self.pending = {}
      return { action }
    end
  end
  self.pending[btn] = t
  return {}
end

function Combo:release(btn)
  self.pending[btn] = nil
  return {}
end

return Combo

-- Capture d'une nouvelle touche pour un raccourci : une touche ou deux à moins de `window` s
-- (clapet fermé : deux obligatoires) ; touche fixe → réservée ; 5 s sans appui → annulé.
local K = require("keymap")

local Cap = {}
Cap.__index = Cap

function Cap.new(side, now, opts)
  opts = opts or {}
  return setmetatable({ side = side, window = opts.window or 0.15, timeout = opts.timeout or 5,
    last = now }, Cap)
end

-- Toutes renvoient nil tant que la capture continue, sinon { done = combo } | { reserved = true } | { cancelled = true }.
function Cap:press(btn, t)
  self.last = t
  if not K.usable(self.side, btn) then return { reserved = true } end
  if self.first and self.first ~= btn and t - self.t0 <= self.window then
    return { done = K.normalize(self.first, btn) }
  end
  self.first, self.t0 = btn, t
  return nil
end

function Cap:release(btn, t)
  if self.side == "closed" and btn == self.first then self.first = nil end
  return nil
end

function Cap:update(t)
  if self.first and t > self.t0 + self.window then
    if self.side == "open" then return { done = self.first } end
  end
  if t - self.last >= self.timeout then return { cancelled = true } end
  return nil
end

return Cap

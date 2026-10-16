-- Traduction des boutons en actions : combo L1 + R1, répétition de la croix haut/bas.
local In = {}
In.__index = In

local SIMPLE = {
  a = "ok", b = "back", start = "playpause", select = "now_playing",
  left = "left", right = "right", up = "up", down = "down", x = "repeat", y = "shuffle", menu = "quit",
}
local REPEATS = { up = true, down = true }
local SHOULDER = { l1 = "previous", r1 = "next" }
local OTHER = { l1 = "r1", r1 = "l1" }

function In.new(opts)
  opts = opts or {}
  return setmetatable({
    window = opts.window or 0.15,
    repeat_delay = opts.repeat_delay or 0.4,
    repeat_rate = opts.repeat_rate or 0.08,
    pending = {},   -- l1/r1 en attente : instant d'appui
    held = {},      -- croix maintenue : prochain instant de répétition
  }, In)
end

function In:press(btn, t)
  if SHOULDER[btn] then
    local other = OTHER[btn]
    if self.pending[other] and t - self.pending[other] <= self.window then
      self.pending[other] = nil
      return { "toggle_background" }
    end
    self.pending[btn] = t
    return {}
  end
  local action = SIMPLE[btn]
  if not action then return {} end
  if REPEATS[btn] then self.held[btn] = t + self.repeat_delay end
  return { action }
end

function In:release(btn, t)
  local out = {}
  if self.pending[btn] then
    self.pending[btn] = nil
    out[1] = SHOULDER[btn]
  end
  self.held[btn] = nil
  return out
end

function In:update(t)
  local out = {}
  for _, btn in ipairs({ "l1", "r1" }) do
    local t0 = self.pending[btn]
    if t0 and t > t0 + self.window then
      self.pending[btn] = nil
      out[#out + 1] = SHOULDER[btn]
    end
  end
  for _, btn in ipairs({ "up", "down" }) do
    local next_t = self.held[btn]
    if next_t and t >= next_t then
      self.held[btn] = next_t + self.repeat_rate
      out[#out + 1] = SIMPLE[btn]
    end
  end
  return out
end

return In

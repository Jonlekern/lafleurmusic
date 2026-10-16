-- Traduction des boutons en actions : touches fixes (croix, A, B, MENU), raccourcis personnalisés
-- d'une touche ou de deux ensemble (keymap), répétition de la croix haut/bas.
local K = require("keymap")

local In = {}
In.__index = In

local NAV = { up = "up", down = "down", left = "left", right = "right", a = "ok", b = "back", menu = "quit" }
local REPEATS = { up = true, down = true }

function In.new(opts)
  opts = opts or {}
  local self = setmetatable({
    window = opts.window or 0.15,
    repeat_delay = opts.repeat_delay or 0.4,
    repeat_rate = opts.repeat_rate or 0.08,
    pending = {},   -- touche d'une combinaison en attente : instant d'appui
    held = {},      -- croix maintenue : prochain instant de répétition
  }, In)
  self:set_bindings(opts.bindings or K.DEFAULTS.open, opts.ab_swap)
  return self
end

function In:set_bindings(map, ab_swap)
  self.single, self.combo, self.in_combo = {}, {}, {}
  for action, c in pairs(map) do
    local p = K.split(c)
    if #p == 1 then
      self.single[p[1]] = action
    elseif #p == 2 then
      self.combo[K.normalize(p[1], p[2])] = action
      self.in_combo[p[1]], self.in_combo[p[2]] = true, true
    end
  end
  self.nav = {}
  for k, v in pairs(NAV) do self.nav[k] = v end
  if ab_swap then self.nav.a, self.nav.b = "back", "ok" end
  self.pending = {}
end

function In:press(btn, t)
  local nav = self.nav[btn]
  if nav then
    if REPEATS[btn] then self.held[btn] = t + self.repeat_delay end
    return { nav }
  end
  if self.in_combo[btn] then
    for other, t0 in pairs(self.pending) do
      local action = self.combo[K.normalize(btn, other)]
      if action and t - t0 <= self.window then
        self.pending[other] = nil
        return { action }
      end
    end
    self.pending[btn] = t
    return {}
  end
  local action = self.single[btn]
  return action and { action } or {}
end

function In:release(btn, t)
  local out = {}
  if self.pending[btn] then
    self.pending[btn] = nil
    out[1] = self.single[btn]
  end
  self.held[btn] = nil
  return out
end

function In:update(t)
  local out = {}
  local expired = {}
  for btn, t0 in pairs(self.pending) do
    if t > t0 + self.window then expired[#expired + 1] = btn end
  end
  table.sort(expired)
  for _, btn in ipairs(expired) do
    self.pending[btn] = nil
    out[#out + 1] = self.single[btn]
  end
  for _, btn in ipairs({ "up", "down" }) do
    local next_t = self.held[btn]
    if next_t and t >= next_t then
      self.held[btn] = next_t + self.repeat_rate
      out[#out + 1] = self.nav[btn]
    end
  end
  return out
end

return In

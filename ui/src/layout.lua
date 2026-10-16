-- Mise en page selon la taille de l'écran (maquettes/formats : 640×480, 720×480, 720×720, 1280×720…).
-- Toutes les tailles de la maquette d'origine (720×480) sont multipliées par k.
local Lay = {}

local function round(v) return math.floor(v + 0.5) end

-- Paysage (3:2, 4:3, 16:9…) : on suit la hauteur ; écrans presque carrés : on suit la largeur.
function Lay.scale(W, H)
  if W / H >= 1.2 then return H / 480 end
  return W / 720
end

-- Listes et menu : lignes à gauche (53 % de la largeur), pochette à droite.
function Lay.list(W, H)
  local k = Lay.scale(W, H)
  local bar = round(44 * k)
  local list_w = math.floor(W * 0.53)
  local rows = math.max(8, math.floor((H - bar) / (54 * k)))
  local pane_w = W - list_w
  local size = round(math.min(pane_w * 0.82, (H - bar) * 0.72))
  local cy = bar + math.floor((H - bar - size) * 0.35)
  return {
    k = k, bar = bar, list_w = list_w, rows = rows, row_h = (H - bar) / rows,
    cover = { x = list_w + math.floor((pane_w - size) / 2), y = cy, size = size },
    caption_y = cy + size + round(22 * k),
  }
end

-- En cours : pochette à gauche en paysage, en haut en carré ; text = bloc titre/progression/badge.
function Lay.nowplaying(W, H)
  local k = Lay.scale(W, H)
  local bar = round(44 * k)
  local n = { k = k, bar = bar }
  if W / H >= 1.2 then
    local size = math.floor(math.min(W * 0.4, (H - bar) * 0.62))
    n.mode = "landscape"
    n.cover = { x = round(30 * k), y = bar + round(22 * k), size = size }
    n.text = { x = round(60 * k) + size, y = bar + round(38 * k), w = W - (round(90 * k) + size) }
  else
    local size = math.floor((H - bar) * 0.33)
    n.mode = "square"
    n.cover = { x = math.floor((W - size) / 2), y = bar + round(20 * k), size = size }
    n.text = { x = round(40 * k), y = bar + size + round(34 * k), w = W - round(80 * k) }
  end
  n.progress_y = n.text.y + round(218 * k)
  n.hints_y = n.progress_y + round(72 * k)
  n.badge_y = n.progress_y + round(120 * k)
  return n
end

return Lay

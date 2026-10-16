-- Texte qui tient dans une largeur donnée, coupé avec « … » sans casser l'UTF-8.
local T = {}

local ELLIPSIS = "…"

function T.fit_text(s, max_w, measure)
  if measure(s) <= max_w then return s end
  -- début de chaque caractère UTF-8
  local starts = {}
  for pos in s:gmatch("()[\1-\127\192-\247][\128-\191]*") do starts[#starts + 1] = pos end
  local lo, hi = 0, #starts -- nombre de caractères gardés
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    local cut = (starts[mid + 1] or #s + 1) - 1
    if measure(s:sub(1, cut) .. ELLIPSIS) <= max_w then lo = mid else hi = mid - 1 end
  end
  local cut = (starts[lo + 1] or #s + 1) - 1
  return s:sub(1, cut):gsub("%s+$", "") .. ELLIPSIS
end

return T

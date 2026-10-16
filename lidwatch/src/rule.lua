-- Ce que fait le gardien selon le clapet, l'arrière-plan et l'état de lecture.
local rule = {}

-- Arrière-plan ON : clapet fermé = écran éteint, en lecture comme en pause (pause possible clapet fermé).
function rule.screen_on(lid_closed, background, state)
  return not (lid_closed and background == "on")
end

-- Touche lecture / pause clapet fermé : commande MPD, nouvel état, et override (pas de re-pause par le gardien).
function rule.toggle(state)
  if state == "play" then return "pause 1", "pause", false end
  return state == "pause" and "pause 0" or "play", "play", true
end

-- Renvoie screen_on, action ("pause" | "resume" | nil), paused_by_us.
-- Arrière-plan OFF : clapet fermé = pause + écran éteint ; à l'ouverture, reprise seulement
-- si c'est le gardien qui avait mis en pause.
-- user_override : l'utilisateur a relancé la musique clapet fermé (touches) → pas de nouvelle pause.
function rule.decide(lid_closed, background, state, paused_by_us, user_override)
  if background == "on" then
    return rule.screen_on(lid_closed, background, state), nil, false
  end
  if lid_closed and user_override then return false, nil, false end
  if lid_closed then
    if state == "play" then return false, "pause", true end
    return false, nil, paused_by_us
  end
  if paused_by_us and state == "pause" then return true, "resume", false end
  return true, nil, false
end

return rule

-- Ce que fait le gardien selon le clapet, l'arrière-plan et l'état de lecture.
local rule = {}

-- Arrière-plan ON : l'écran ne s'éteint que clapet fermé et musique en lecture (la musique continue).
function rule.screen_on(lid_closed, background, state)
  return not (lid_closed and background == "on" and state == "play")
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

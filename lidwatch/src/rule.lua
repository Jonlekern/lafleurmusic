-- L'écran ne s'éteint que clapet fermé, arrière-plan ON et musique en lecture.
local rule = {}

function rule.screen_on(lid_closed, background, state)
  return not (lid_closed and background == "on" and state == "play")
end

return rule

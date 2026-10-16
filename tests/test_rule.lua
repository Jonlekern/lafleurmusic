local rule = require("rule")

local function d(...) return { rule.decide(...) } end

return {
  ["écran éteint seulement clapet fermé, arrière-plan ON et lecture"] = function()
    eq(rule.screen_on(true, "on", "play"), false)
  end,
  ["toutes les autres combinaisons gardent l'écran allumé"] = function()
    eq(rule.screen_on(false, "on", "play"), true)
    eq(rule.screen_on(true, "on", "pause"), true)
    eq(rule.screen_on(true, "on", "stop"), true)
    eq(rule.screen_on(true, "on", nil), true)
    eq(rule.screen_on(false, "off", nil), true)
    eq(rule.screen_on(false, "off", "pause"), true)
  end,
  ["ON : clapet fermé en lecture → écran éteint, pas de pause"] = function()
    eq(d(true, "on", "play", false), { false, nil, false })
  end,
  ["ON : clapet fermé en pause → écran allumé"] = function()
    eq(d(true, "on", "pause", false), { true, nil, false })
  end,
  ["OFF : clapet fermé en lecture → pause et écran éteint"] = function()
    eq(d(true, "off", "play", false), { false, "pause", true })
  end,
  ["OFF : clapet toujours fermé après notre pause → rien de plus"] = function()
    eq(d(true, "off", "pause", true), { false, nil, true })
  end,
  ["OFF : clapet rouvert après notre pause → reprise"] = function()
    eq(d(false, "off", "pause", true), { true, "resume", false })
  end,
  ["OFF : pause mise par toi, clapet rouvert → pas de reprise"] = function()
    eq(d(false, "off", "pause", false), { true, nil, false })
  end,
  ["OFF : clapet fermé déjà en pause → écran éteint, pas de reprise prévue"] = function()
    eq(d(true, "off", "pause", false), { false, nil, false })
  end,
}

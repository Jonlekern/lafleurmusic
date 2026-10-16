local rule = require("rule")

local function d(...) return { rule.decide(...) } end

return {
  ["écran éteint clapet fermé, arrière-plan ON"] = function()
    eq(rule.screen_on(true, "on", "play"), false)
  end,
  ["clapet ouvert : écran allumé"] = function()
    eq(rule.screen_on(false, "on", "play"), true)
    eq(rule.screen_on(false, "off", nil), true)
    eq(rule.screen_on(false, "off", "pause"), true)
  end,
  ["ON : clapet fermé en lecture → écran éteint, pas de pause"] = function()
    eq(d(true, "on", "play", false), { false, nil, false })
  end,
  ["ON : clapet fermé en pause → écran éteint aussi"] = function()
    eq(d(true, "on", "pause", false), { false, nil, false })
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
  ["OFF : relancé clapet fermé, le gardien ne remet pas en pause"] = function()
    eq(d(true, "off", "play", false, true), { false, nil, false })
  end,
  ["OFF : sans relance, clapet fermé en lecture = pause"] = function()
    eq(d(true, "off", "play", false, false), { false, "pause", true })
  end,
  ["touche lecture clapet fermé : relance toujours sans re-pause"] = function()
    eq({ rule.toggle("pause") }, { "pause 0", "play", true })
    eq({ rule.toggle("stop") }, { "play", "play", true })
    eq({ rule.toggle(nil) }, { "play", "play", true })
    eq({ rule.toggle("play") }, { "pause 1", "pause", false })
  end,
  ["ON : clapet fermé, écran toujours éteint (même en pause)"] = function()
    eq(rule.screen_on(true, "on", "pause"), false)
    eq(rule.screen_on(true, "on", "stop"), false)
    eq(rule.screen_on(false, "on", "pause"), true)
  end,
}

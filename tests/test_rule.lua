local rule = require("rule")

return {
  ["écran éteint seulement clapet fermé, arrière-plan ON et lecture"] = function()
    eq(rule.screen_on(true, "on", "play"), false)
  end,
  ["toutes les autres combinaisons gardent l'écran allumé"] = function()
    eq(rule.screen_on(false, "on", "play"), true)
    eq(rule.screen_on(true, "off", "play"), true)
    eq(rule.screen_on(true, "on", "pause"), true)
    eq(rule.screen_on(true, "on", "stop"), true)
    eq(rule.screen_on(true, "on", nil), true)
    eq(rule.screen_on(false, "off", nil), true)
    eq(rule.screen_on(false, "off", "pause"), true)
  end,
}

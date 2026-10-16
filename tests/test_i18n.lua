local I = require("i18n")

return {
  ["detect trouve le français"] = function()
    eq(I.detect("x=1\nsystem.language=fr_FR\n"), "fr")
  end,
  ["detect anglais"] = function()
    eq(I.detect("system.language=en_US"), "en")
  end,
  ["detect sans fichier donne anglais"] = function()
    eq(I.detect(nil), "en")
  end,
  ["detect autre langue donne anglais"] = function()
    eq(I.detect("system.language=de_DE"), "en")
  end,
  ["t formate les nombres"] = function()
    eq(I.t("fr", "n_of", 3, 88), "3 sur 88")
    eq(I.t("en", "n_songs", 18), "18 songs")
  end,
  ["textes exacts du plan"] = function()
    eq(I.t("fr", "shuffle_all"), "Lecture aléatoire")
    eq(I.t("en", "shuffle_all"), "Shuffle Songs")
    eq(I.t("fr", "bg_on_msg"), "La musique continue\nquand tu quittes l'appli")
    eq(I.t("en", "engine_down"), "Audio engine unavailable")
  end,
  ["modes de répétition"] = function()
    eq(I.t("fr", "repeat_one"), "Un seul")
    eq(I.t("en", "repeat_all"), "All")
  end,
  ["indication du bouton START"] = function()
    eq(I.t("fr", "pause"), "Pause")
    eq(I.t("fr", "play"), "Lecture")
    eq(I.t("en", "play"), "Play")
  end,
  ["chaque clé existe dans les deux langues"] = function()
    for key in pairs(I.strings.fr) do truthy(I.strings.en[key], "en manque " .. key) end
    for key in pairs(I.strings.en) do truthy(I.strings.fr[key], "fr manque " .. key) end
  end,
}

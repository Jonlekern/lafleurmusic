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
  ["textes des touches"] = function()
    local fr = {
      keys_open = "Touches clapet ouvert", keys_closed = "Touches clapet fermé", ab_swap = "A/B inversés",
      reset_keys = "Réinitialiser", press_key = "Appuie sur une touche",
      press_two_keys = "Appuie sur deux touches\nen même temps", key_reserved = "Touche réservée",
      cancelled_in = "Annulé dans 5 s si rien", act_playpause = "Lecture / Pause", act_next = "Morceau suivant",
      act_previous = "Morceau précédent", act_shuffle = "Aléatoire", act_repeat = "Répéter",
      act_now_playing = "En cours", act_toggle_background = "Arrière-plan",
    }
    local en = {
      keys_open = "Keys (lid open)", keys_closed = "Keys (lid closed)", ab_swap = "Swap A/B", reset_keys = "Reset",
      press_key = "Press a key", press_two_keys = "Press two keys\nat the same time", key_reserved = "Reserved key",
      cancelled_in = "Cancelled after 5 s", act_playpause = "Play / Pause", act_next = "Next track",
      act_previous = "Previous track", act_shuffle = "Shuffle", act_repeat = "Repeat",
      act_now_playing = "Now Playing", act_toggle_background = "Background",
    }
    for k, v in pairs(fr) do eq(I.t("fr", k), v, k) end
    for k, v in pairs(en) do eq(I.t("en", k), v, k) end
  end,
}

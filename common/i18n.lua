-- Langue de la console (system.language dans system.cfg) et textes FR/EN.
-- « LAFLEURSTUDIO » ne se traduit jamais.
local I = {}

I.strings = {
  fr = {
    cover_flow = "Cover Flow", playlists = "Playlists", artists = "Artistes", songs = "Morceaux",
    genres = "Genres", shuffle_all = "Lecture aléatoire", now_playing = "En cours", settings = "Réglages",
    shuffle = "Aléatoire", ["repeat"] = "Répéter", background = "Arrière-plan",
    background_default = "Arrière-plan par défaut", update_library = "Mettre à jour la bibliothèque",
    on = "ON", off = "OFF",
    bg_on_msg = "La musique continue\nquand tu quittes l'appli",
    bg_off_msg = "La musique s'arrêtera\nquand tu quittes l'appli",
    n_songs = "%d morceaux", n_of = "%d sur %d", playlist_n = "Playlist · %d morceaux",
    empty_library = "Ajoute de la musique dans roms/music",
    engine_down = "Moteur audio indisponible", unknown = "Inconnu", updating = "Mise à jour…",
    repeat_off = "OFF", repeat_all = "Tout", repeat_one = "Un seul", pause = "Pause", play = "Lecture",
    keys = "Touches", lid_open = "CLAPET OUVERT", lid_closed = "CLAPET FERMÉ", ab_swap = "A/B inversés",
    reset_keys = "Réinitialiser", press_key = "Appuie sur une touche",
    press_two_keys = "Appuie sur deux touches\nen même temps", key_reserved = "Touche réservée",
    cancelled_in = "Annulé dans 5 s si rien", act_playpause = "Lecture / Pause", act_next = "Morceau suivant",
    act_previous = "Morceau précédent", act_shuffle = "Aléatoire", act_repeat = "Répéter",
    act_now_playing = "En cours", act_toggle_background = "Arrière-plan",
  },
  en = {
    cover_flow = "Cover Flow", playlists = "Playlists", artists = "Artists", songs = "Songs",
    genres = "Genres", shuffle_all = "Shuffle Songs", now_playing = "Now Playing", settings = "Settings",
    shuffle = "Shuffle", ["repeat"] = "Repeat", background = "Background",
    background_default = "Background by default", update_library = "Update Library",
    on = "ON", off = "OFF",
    bg_on_msg = "Music keeps playing\nwhen you quit the app",
    bg_off_msg = "Music will stop\nwhen you quit the app",
    n_songs = "%d songs", n_of = "%d of %d", playlist_n = "Playlist · %d songs",
    empty_library = "Add music to roms/music",
    engine_down = "Audio engine unavailable", unknown = "Unknown", updating = "Updating…",
    repeat_off = "OFF", repeat_all = "All", repeat_one = "One", pause = "Pause", play = "Play",
    keys = "Keys", lid_open = "LID OPEN", lid_closed = "LID CLOSED", ab_swap = "Swap A/B", reset_keys = "Reset",
    press_key = "Press a key", press_two_keys = "Press two keys\nat the same time", key_reserved = "Reserved key",
    cancelled_in = "Cancelled after 5 s", act_playpause = "Play / Pause", act_next = "Next track",
    act_previous = "Previous track", act_shuffle = "Shuffle", act_repeat = "Repeat",
    act_now_playing = "Now Playing", act_toggle_background = "Background",
  },
}

function I.detect(syscfg_text)
  local lang = syscfg_text and syscfg_text:match("system%.language=(%S*)")
  if lang and lang:sub(1, 2) == "fr" then return "fr" end
  return "en"
end

function I.t(lang, key, ...)
  local s = (I.strings[lang] or I.strings.en)[key] or key
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end

return I

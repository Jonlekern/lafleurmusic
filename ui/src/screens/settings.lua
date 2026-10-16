-- Réglages : aléatoire, répéter (MPD), arrière-plan par défaut (settings.txt), mise à jour de la bibliothèque.
local list = require("screens.list")
local S = require("settings")

return function()
  local updating = false
  local function onoff(b) return app.t(b and "on" or "off") end
  local function st() return app.mpd:status() or {} end

  local items = {
    {
      label = app.t("shuffle"),
      value = function() return onoff((app.status or {}).random == "1") end,
      on_ok = function() app.mpd:command("random " .. (st().random == "1" and 0 or 1)); app.status = st() end,
    },
    {
      label = app.t("repeat"),
      value = function() return onoff((app.status or {})["repeat"] == "1") end,
      on_ok = function() app.mpd:command("repeat " .. (st()["repeat"] == "1" and 0 or 1)); app.status = st() end,
    },
    {
      label = app.t("background_default"),
      value = function() return onoff(app.settings.background_default == "on") end,
      on_ok = function()
        app.settings.background_default = app.settings.background_default == "on" and "off" or "on"
        S.save(app.settings_path, app.settings)
      end,
    },
    {
      label = app.t("update_library"),
      value = function() return updating and app.t("updating") or "" end,
      on_ok = function()
        if updating then return end
        local r = app.mpd:command("update")
        updating = r.ok
      end,
    },
  }

  local s = list({ title = app.t("settings"), items = items })
  local check = 0
  function s.update(dt)
    if not updating then return end
    check = check - dt
    if check > 0 then return end
    check = 0.5
    local status = app.mpd:status()
    if status and not status.updating_db then
      updating = false
      app.reload_library()
    end
  end
  return s
end

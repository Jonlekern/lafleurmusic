-- Touches clapet ouvert / fermé : un raccourci par ligne avec sa touche ; Valider → capture de la nouvelle touche.
local list = require("screens.list")
local K = require("keymap")
local Cap = require("capture")
local toast = require("screens.toast")

return function(side)
  local km = app.keys
  local cap, cap_action
  local items = {}
  for _, action in ipairs(side == "open" and K.ACTIONS or K.CLOSED_ACTIONS) do
    items[#items + 1] = {
      label = app.t("act_" .. action),
      value = function() return K.label(km[side][action]) end,
      on_ok = function() cap, cap_action = Cap.new(side, love.timer.getTime()), action end,
    }
  end
  if side == "open" then
    items[#items + 1] = {
      label = app.t("ab_swap"),
      value = function() return app.t(km.ab_swap and "on" or "off") end,
      on_ok = function() km.ab_swap = not km.ab_swap; app.apply_keys() end,
    }
  end
  items[#items + 1] = {
    label = app.t("reset_keys"), value = function() return "" end,
    on_ok = function() K.reset(km, side); app.apply_keys() end,
  }
  local s = list({ title = app.t(side == "open" and "keys_open" or "keys_closed"), items = items })

  local function finish(r)
    if not r then return end
    cap = nil
    toast.left = 0
    if r.done then
      K.assign(km, side, cap_action, r.done)
      app.apply_keys()
      app.log("touche " .. side .. " " .. cap_action .. " = " .. r.done)
    elseif r.reserved then
      toast.show_text(app.t("key_reserved"), false, nil, nil)
    end
  end

  -- Pendant la capture, les boutons bruts arrivent ici au lieu de passer par les raccourcis.
  function s.raw_press(btn, t) if cap then finish(cap:press(btn, t)) return true end end
  function s.raw_release(btn, t) if cap then finish(cap:release(btn, t)) return true end end
  function s.update()
    if not cap then return end
    finish(cap:update(love.timer.getTime()))
    if cap then
      toast.show_text(app.t("act_" .. cap_action), true,
        app.t(side == "open" and "press_key" or "press_two_keys"), app.t("cancelled_in"))
    end
  end
  return s
end

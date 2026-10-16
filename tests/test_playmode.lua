local PM = require("playmode")

return {
  ["mode de répétition lu depuis le statut MPD"] = function()
    eq(PM.repeat_mode({ ["repeat"] = "0", single = "0" }), "off")
    eq(PM.repeat_mode({ ["repeat"] = "1", single = "0" }), "all")
    eq(PM.repeat_mode({ ["repeat"] = "1", single = "1" }), "one")
    eq(PM.repeat_mode(nil), "off")
  end,
  ["le cycle off → all → one → off"] = function()
    eq(PM.next_repeat("off"), "all")
    eq(PM.next_repeat("all"), "one")
    eq(PM.next_repeat("one"), "off")
  end,
  ["commandes MPD pour chaque mode"] = function()
    eq(PM.repeat_commands("off"), "command_list_begin\nrepeat 0\nsingle 0\ncommand_list_end")
    eq(PM.repeat_commands("all"), "command_list_begin\nrepeat 1\nsingle 0\ncommand_list_end")
    eq(PM.repeat_commands("one"), "command_list_begin\nrepeat 1\nsingle 1\ncommand_list_end")
  end,
  ["bascule de l'aléatoire"] = function()
    eq(PM.shuffle_command({ random = "0" }), "random 1")
    eq(PM.shuffle_command({ random = "1" }), "random 0")
    eq(PM.shuffle_command(nil), "random 1")
  end,
}

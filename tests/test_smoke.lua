return {
  ["eq compare les tables"] = function()
    eq({ a = { 1, 2 } }, { a = { 1, 2 } })
  end,
  ["eq détecte une différence"] = function()
    local ok = pcall(eq, { a = 1 }, { a = 2 })
    truthy(not ok, "eq aurait dû échouer")
  end,
}

local CF = require("coverflow_layout")

local function find(list, index)
  for _, e in ipairs(list) do if e.index == index then return e end end
end

return {
  ["position 4 sur 6 : 7 pochettes, centre en dernier"] = function()
    local l = CF.layout(4, 6)
    eq(#l, 6) -- 1,2,3 à gauche ; 5,6 à droite ; 4 au centre
    local c = l[#l]
    eq({ c.index, c.x, c.y, c.w, c.h, c.side }, { 4, 240, 70, 240, 240, "center" })
  end,
  ["voisines aux positions de la maquette"] = function()
    local l = CF.layout(4, 7)
    eq(#l, 7)
    eq(find(l, 3).x, 130); eq(find(l, 2).x, 75); eq(find(l, 1).x, 20)
    eq(find(l, 5).x, 480); eq(find(l, 6).x, 535); eq(find(l, 7).x, 590)
    eq({ find(l, 3).w, find(l, 3).h, find(l, 3).side }, { 110, 240, "left" })
    eq(find(l, 5).side, "right")
  end,
  ["première pochette : rien à gauche"] = function()
    for _, e in ipairs(CF.layout(1, 6)) do truthy(e.side ~= "left", "pochette à gauche") end
  end,
  ["ordre de dessin du plus loin au plus proche"] = function()
    local l = CF.layout(4, 7)
    local pos = {}
    for i, e in ipairs(l) do pos[e.index] = i end
    truthy(pos[1] < pos[3], "1 avant 3")
    truthy(pos[7] < pos[5], "7 avant 5")
  end,
  ["position fractionnaire : centre arrondi"] = function()
    local l = CF.layout(2.6, 6)
    eq(l[#l].index, 3)
  end,
  ["à l'échelle en 1280x720 : centré et agrandi"] = function()
    local l = CF.layout(4, 7, 1280, 720)
    local c = l[#l]
    eq({ c.index, c.x, c.y, c.w, c.h }, { 4, 460, 105, 360, 360 })
  end,
  ["sans taille donnée : comme en 720x480"] = function()
    eq(CF.layout(4, 7), CF.layout(4, 7, 720, 480))
  end,
  ["en 720x720 : reste dans l'écran"] = function()
    for _, e in ipairs(CF.layout(4, 7, 720, 720)) do
      truthy(e.x >= 0 and e.x + e.w <= 720, "x " .. e.x)
    end
  end,
  ["step atteint la cible"] = function()
    eq(CF.step(1, 2, 1), 2)
  end,
  ["step avance sans dépasser"] = function()
    local p = CF.step(1, 2, 0.01)
    truthy(p > 1 and p < 2, "entre 1 et 2 : " .. p)
  end,
  ["step recule aussi"] = function()
    eq(CF.step(3, 2, 1), 2)
  end,
}

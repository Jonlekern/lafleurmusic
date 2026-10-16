-- Pochettes : cache mémoire → cache disque (cache/covers/<md5>-<taille>.png) → readpicture MPD → fleur.
-- Au plus une pochette chargée par image affichée, pour que le défilement reste fluide.
local theme = require("theme")

local covers = { mem = {}, queue = {}, queued = {} }

local function key(file, size)
  return love.data.encode("string", "hex", love.data.hash("md5", file)) .. "-" .. size
end

local function cache_path(k)
  return app.appdir .. "/cache/covers/" .. k .. ".png"
end

local function read(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*a")
  f:close()
  return d
end

local function image_from_bytes(bytes, name)
  local ok, img = pcall(function()
    return love.graphics.newImage(love.image.newImageData(love.filesystem.newFileData(bytes, name)))
  end)
  return ok and img or nil
end

-- Réduit une image à size×size (rognée au centre) et renvoie l'Image + les octets PNG.
local function square(img, size)
  local canvas = love.graphics.newCanvas(size, size)
  local w, h = img:getDimensions()
  local s = size / math.min(w, h)
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, size / 2, size / 2, 0, s, s, w / 2, h / 2)
  love.graphics.pop()
  local data = canvas:newImageData()
  return love.graphics.newImage(data), data:encode("png"):getString()
end

local function load_one(file, size)
  local k = key(file, size)
  local bytes = read(cache_path(k))
  if bytes then
    local img = image_from_bytes(bytes, k .. ".png")
    if img then return img end
  end
  local pic = app.mpd:picture(file)
  local raw = pic and image_from_bytes(pic, "cover")
  if not raw then
    if pic then app.log("pochette illisible : " .. file) end
    return theme.image("fleur-tile")
  end
  local img, png = square(raw, size)
  os.execute("mkdir -p '" .. app.appdir .. "/cache/covers'")
  local f = io.open(cache_path(k), "wb")
  if f then f:write(png) f:close() end
  return img
end

-- Renvoie tout de suite une image (la fleur en attendant), la vraie pochette arrive plus tard.
function covers.get(file, size)
  if not file then return theme.image("fleur-tile") end
  local k = key(file, size)
  local img = covers.mem[k]
  if img then return img end
  if not covers.queued[k] then
    covers.queued[k] = true
    covers.queue[#covers.queue + 1] = { file = file, size = size, k = k }
  end
  return theme.image("fleur-tile")
end

function covers.update()
  local job = table.remove(covers.queue, 1)
  if not job then return end
  covers.mem[job.k] = load_one(job.file, job.size)
end

return covers

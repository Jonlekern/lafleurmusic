-- Client TCP pour MPD. Le socket vient de LuaSocket (intégré à LÖVE) ; il est injectable pour les tests.
local P = require("mpd_protocol")

local C = {}
C.__index = C

local UNAVAILABLE = { ok = false, err = "unavailable", pairs = {} }

local function default_connect(host, port)
  local socket = require("socket")
  local s, err = socket.connect(host, port)
  if s then s:settimeout(5) end
  return s, err
end

function C.new(opts)
  opts = opts or {}
  return setmetatable({
    host = opts.host or "127.0.0.1",
    port = opts.port or 6601,
    connect = opts.connect or default_connect,
    sock = nil,
  }, C)
end

function C:close()
  if self.sock then self.sock:close() end
  self.sock = nil
end

function C:_open()
  if self.sock then return true end
  local s = self.connect(self.host, self.port)
  if not s then return false end
  local banner = s:receive("*l")
  if not banner or not banner:match("^OK MPD") then
    s:close()
    return false
  end
  self.sock = s
  return true
end

-- Lit des lignes jusqu'à OK/ACK. stop_key : s'arrête juste après cette clé (réponse binaire).
function C:_read_lines(stop_key)
  local lines = {}
  while true do
    local line = self.sock:receive("*l")
    if not line then return nil end
    lines[#lines + 1] = line
    if line == "OK" or line:match("^ACK ") then return lines end
    if stop_key and line:match("^" .. stop_key .. ": ") then return lines end
  end
end

-- Envoie une commande et renvoie les lignes brutes, ou nil si le socket a lâché.
function C:_try(line, stop_key)
  if not self:_open() then return nil end
  if not self.sock:send(line .. "\n") then return nil end
  return self:_read_lines(stop_key)
end

-- Une tentative, puis une reconnexion si l'envoi ou la lecture échoue.
function C:_exchange(line, stop_key)
  local lines = self:_try(line, stop_key)
  if lines then return lines end
  self:close()
  lines = self:_try(line, stop_key)
  if lines then return lines end
  self:close()
  return nil
end

function C:command(line)
  local lines = self:_exchange(line)
  if not lines then return UNAVAILABLE end
  return P.parse(lines)
end

function C:songs()
  local r = self:command("listallinfo")
  if not r.ok then return {} end
  return P.records(r.pairs, "file")
end

local function to_table(pairs_)
  local t = {}
  for _, kv in ipairs(pairs_) do t[kv[1]] = kv[2] end
  return t
end

function C:status()
  local r = self:command("status")
  if not r.ok then return nil end
  return to_table(r.pairs)
end

function C:currentsong()
  local r = self:command("currentsong")
  if not r.ok or #r.pairs == 0 then return nil end
  return to_table(r.pairs)
end

-- Pochette intégrée au fichier, morceau par morceau (readpicture), ou nil.
function C:picture(file)
  local chunks, offset, size = {}, 0, nil
  repeat
    local lines = self:_exchange("readpicture " .. P.quote(file) .. " " .. offset, "binary")
    if not lines then return nil end
    local last = lines[#lines]
    if last == "OK" or last:match("^ACK ") then return nil end
    local h = P.binary_header(P.parse(lines).pairs)
    size = size or h.size
    if not size or not h.binary or h.binary == 0 then return nil end
    local data = self.sock:receive(h.binary)
    if not data then self:close() return nil end
    self.sock:receive("*l") -- fin de ligne après les octets
    local tail = self.sock:receive("*l")
    if tail ~= "OK" then self:close() return nil end
    chunks[#chunks + 1] = data
    offset = offset + h.binary
  until offset >= size
  return table.concat(chunks)
end

return C

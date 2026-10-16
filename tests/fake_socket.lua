-- Faux socket LuaSocket pour les tests : on lui donne tout ce que « le serveur » renverra.
local F = {}

-- opts.output : texte renvoyé par le serveur ; opts.fail_send : nombre de send() qui échouent.
function F.new(opts)
  local s = { buf = opts.output or "", sent = {}, fail_send = opts.fail_send or 0, closed = false }
  function s:send(data)
    if self.fail_send > 0 then
      self.fail_send = self.fail_send - 1
      return nil, "closed"
    end
    self.sent[#self.sent + 1] = data
    return #data
  end
  function s:receive(pattern)
    if pattern == "*l" then
      local i = self.buf:find("\n", 1, true)
      if not i then return nil, "closed" end
      local line = self.buf:sub(1, i - 1)
      self.buf = self.buf:sub(i + 1)
      return line
    end
    if #self.buf < pattern then return nil, "closed" end
    local data = self.buf:sub(1, pattern)
    self.buf = self.buf:sub(pattern + 1)
    return data
  end
  function s:settimeout() end
  function s:close() self.closed = true end
  return s
end

-- Fabrique un connect() qui renvoie les faux sockets dans l'ordre, puis nil.
function F.connector(sockets)
  local calls = { n = 0 }
  local function connect()
    calls.n = calls.n + 1
    local s = sockets[calls.n]
    if not s then return nil, "refused" end
    return s
  end
  return connect, calls
end

return F

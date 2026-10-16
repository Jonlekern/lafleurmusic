-- Encodage / décodage du protocole texte de MPD (https://mpd.readthedocs.io/en/latest/protocol.html).
local P = {}

function P.quote(s)
  s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
  return '"' .. s .. '"'
end

-- lines : lignes de la réponse, terminées par "OK" ou "ACK ...".
function P.parse(lines)
  local pairs_ = {}
  for _, line in ipairs(lines) do
    if line == "OK" then
      return { ok = true, pairs = pairs_ }
    end
    local msg = line:match("^ACK %[[^%]]*%] {[^}]*} (.*)$")
    if msg then
      return { ok = false, err = msg, pairs = pairs_ }
    end
    local key, value = line:match("^([^:]+): (.*)$")
    if key then
      pairs_[#pairs_ + 1] = { key, value }
    end
  end
  return { ok = false, err = "incomplete", pairs = pairs_ }
end

function P.records(pairs_, first_key)
  local out, cur = {}, nil
  for _, kv in ipairs(pairs_) do
    local key, value = kv[1], kv[2]
    if key == first_key then
      cur = {}
      out[#out + 1] = cur
    end
    if cur then cur[key] = value end
  end
  return out
end

function P.binary_header(pairs_)
  local h = {}
  for _, kv in ipairs(pairs_) do
    if kv[1] == "size" or kv[1] == "binary" then h[kv[1]] = tonumber(kv[2]) end
  end
  return h
end

return P

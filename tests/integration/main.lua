-- Test d'intégration avec un vrai MPD (sur la console) : love tests/integration
-- Le dossier common/ est copié ici par tools/build.sh.
love.filesystem.setRequirePath("?.lua;?/init.lua;common/?.lua")
local C = require("mpd_client")

function love.load()
  local port = tonumber(os.getenv("LAFLEUR_MPD_PORT") or "6601")
  local c = C.new({ port = port })
  local songs = c:songs()
  local pic = songs[1] and c:picture(songs[1].file)
  local ok = #songs > 0 and pic ~= nil and #pic > 0
  print(string.format("INTEGRATION %s : %d morceaux, pochette %s octets",
    ok and "OK" or "FAIL", #songs, pic and #pic or "nil"))
  love.event.quit(ok and 0 or 1)
end

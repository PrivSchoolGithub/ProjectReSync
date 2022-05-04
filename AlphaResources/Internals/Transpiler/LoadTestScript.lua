local exe = require(script.Executor)

local ok,out = exe:LoadString('game.Players.PlayerAdded:Connect(function(user) local tbl = {} tbl[1] = "hi" print(tbl[1]) local function printHi(k) print(k) end if printHi ~= nil and printHi ~= nil then printHi("Hello!") end end) print([[hi how r u\nugly fat]]) return {P = "hi"}',getfenv(0))
print(out)
local c = out()
print(c.P..'vvv')

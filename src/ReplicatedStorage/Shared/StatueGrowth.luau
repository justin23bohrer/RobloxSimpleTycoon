-- StatueGrowth (shared: server and client)
-- How fat the statue is for a number of cookies eaten, from 0 (thin) to 1
-- (maximum, at Config.StatueMaxCookies).
--
-- StatueService uses it to shape the statue. (The feed pop-up's progress bar
-- does not: it shows the exact cookies eaten out of the max.)
-- It is a pure function: it reads Config and decides nothing.
--
-- Growth follows log(eaten) so small feeds still show: 100 cookies is about
-- 1/3 of the way, 10,000 about 2/3, 1,000,000 is the maximum.

local Config = require(script.Parent.Config)

local StatueGrowth = {}

function StatueGrowth.Fatness(cookies: number): number
	return math.clamp(math.log(1 + math.max(cookies, 0)) / math.log(1 + Config.StatueMaxCookies), 0, 1)
end

return StatueGrowth

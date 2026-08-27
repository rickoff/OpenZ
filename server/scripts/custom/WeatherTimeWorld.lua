--[[
WeatherTimeWorld
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as WeatherTimeWorld.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.WeatherTimeWorld")
---------------------------
]]
 
customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	local count = 0 
	for targetPid, player in pairs(Players) do
		count = count + 1
	end
	if count == 1 then
		WorldInstance.data.time = {
			year = tonumber(os.date("%Y")),
			month = tonumber(os.date("%m")),
			day = tonumber(os.date("%d")),	
			hour = tonumber(os.date("%H")),
			daysPassed = WorldInstance.data.time.daysPassed,
			dayTimeScale = 1,
			nightTimeScale = 1			
		}
		WorldInstance:QuicksaveToDrive()
		WorldInstance:UpdateFrametimeMultiplier()
		WorldInstance:LoadTime(pid, true)	
	end	
end)



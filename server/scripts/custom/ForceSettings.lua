--[[
ForceSettings
tes3mp 0.8.1
---------------------------
DESCRIPTION :
---------------------------
INSTALLATION:
Save the file as ForceSettings.lua inside your server/scripts/custom folder.
Edits to customScripts.lua, add in :
require("custom.ForceSettings")
---------------------------
]]
local cfg = {
	["best attack"] = false
}

local function ForceSettingValue(pid)
    tes3mp.ClearGameSettingValues(pid)
	for settingName, bool in pairs(cfg) do
		tes3mp.SetGameSettingValue(pid, settingName, tostring(bool))
	end
    tes3mp.SendSettings(pid)
end

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
    ForceSettingValue(pid)
end)

customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
    ForceSettingValue(pid)
end)

customEventHooks.registerHandler("OnObjectHit", function(eventStatus, pid, cellDescription, objects, targetPlayers)	
    ForceSettingValue(pid)
end)
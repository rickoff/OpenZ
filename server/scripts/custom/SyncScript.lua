--[[
SyncScript
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as SyncScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.SyncScript")
---------------------------
]]
local PlayersThief = {}

local DoorState = {
	door_lab_02 = true,
	door_lab_03 = true,
	act_hosp_elevatorl = true,
	act_hosp_elevatorr = true,
	act_police_elevatorl = true,
	act_police_elevatorr = true,
	act_slid_door = true,
	door_guard_bar = true,
	act_break_wall_door01 = true,
	act_break_wall_door02 = true,
	act_pc = true,
	act_lab_elevator_01 = true,
	act_lab_elevator_02 = true,
	act_office_elevatorl = true,
	act_office_elevatorr = true
}

customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
	local nameScript = tes3mp.GetObjectListClientScript()
	for _, object in pairs(objects) do
		if object.uniqueIndex and object.refId and object.activatingPid then	
			if nameScript == "ThiefVehicle" then		
				PlayersThief[GetName(object.activatingPid)] = {
					cellDescription = cellDescription,
					uniqueIndex = object.uniqueIndex,
					refId = object.refId
				}
			end
			if DoorState[object.refId] then				
				for _, visitorPid in pairs(LoadedCells[cellDescription].visitors) do
					if object.activatingPid ~= visitorPid then
						logicHandler.ActivateObjectForPlayer(visitorPid, cellDescription, object.uniqueIndex)
					end
				end	
			end
		end		
	end
end)

customEventHooks.registerHandler("OnObjectSpawn", function(eventStatus, pid, cellDescription, objects)
	if tes3mp.GetObjectListClientScript() == "ThiefVehicle" then
		local playerName = GetName(pid)		
		if PlayersThief[playerName] then
			local ThiefData = PlayersThief[playerName]
			for _, visitorPid in pairs(LoadedCells[cellDescription].visitors) do
				if pid ~= visitorPid then
					PlaySound3D(visitorPid, "Car Alarm", ThiefData.cellDescription, ThiefData.uniqueIndex, false)
				end
			end
			PlayersThief[playerName] = nil
		end
	end
end)
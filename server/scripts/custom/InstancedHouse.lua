--[[
InstancedHouse
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as InstancedHouse.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.InstancedHouse")
---------------------------
COMMAND:
/house for open main menu
]]
local cfg = {
	pos = {
		posX = 4330.4169921875,
		posY = 3672.1918945313,
		posZ = 12199.452148438,
		rotX = 0.19873487949371,
		rotZ = 0.025372743606567
	},
	doorRefid = "door_office_00"
}

local trd = {
	NoWarp = "Unable to access your house from here, please leave the area."
}

local function CreateHouse(pid)
	local playerName = GetName(pid)
	local recordStoreCell = RecordStores["cell"]
	local recordTable = {
	  baseId = "Office Apartment 00"
	}	
	local recordId = "Apartment of "..playerName
	recordStoreCell.data.permanentRecords[recordId] = recordTable
	recordStoreCell:Save()
    tes3mp.ClearRecords()
    tes3mp.SetRecordType(5)
    tes3mp.SetRecordName(recordId)
    tes3mp.SetRecordBaseId(recordTable.baseId)
    tes3mp.AddRecord()	
    tes3mp.SendRecordDynamic(pid, true, false)	
	Players[pid].data.customVariables.instancedHouse = {
		cellDescription = tes3mp.GetCell(pid),
		posX = tes3mp.GetPosX(pid),
		posY = tes3mp.GetPosY(pid),
		posZ = tes3mp.GetPosZ(pid),
		rotX = tes3mp.GetRotX(pid),
		rotY = 0,
		rotZ = tes3mp.GetRotZ(pid)
	}
end

local function WarpHouse(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end	
	local cellDescription = tes3mp.GetCell(pid)
	if string.find(cellDescription, "Apartment of ") then 
		tes3mp.MessageBox(pid, -1, trd.NoWarp)
		return
	end
	DragonDoor.OnPlayerWarp(pid)
	Players[pid].data.customVariables.instancedHouse = {
		cellDescription = cellDescription,
		posX = tes3mp.GetPosX(pid),
		posY = tes3mp.GetPosY(pid),
		posZ = tes3mp.GetPosZ(pid),
		rotX = tes3mp.GetRotX(pid),
		rotY = 0,
		rotZ = tes3mp.GetRotZ(pid)
	}
	local playerName = GetName(pid)			
	tes3mp.SetCell(pid, "Apartment of "..playerName)
	tes3mp.SetPos(pid, cfg.pos.posX, cfg.pos.posY, cfg.pos.posZ)
	tes3mp.SetRot(pid, cfg.pos.rotX, cfg.pos.rotZ)	
	tes3mp.SendCell(pid)    
	tes3mp.SendPos(pid)	
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if not Players[pid].data.customVariables.instancedHouse then
		CreateHouse(pid)
	end
end)
	
customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
	if not string.find(cellDescription, "Apartment of ") then return end	
	for _, object in pairs(objects) do
		if object.activatingPid and object.uniqueIndex and object.refId then
			if object.refId == cfg.doorRefid then
				local instancedHouse = Players[object.activatingPid].data.customVariables.instancedHouse
				tes3mp.SetCell(object.activatingPid, instancedHouse.cellDescription)
				tes3mp.SetPos(object.activatingPid, instancedHouse.posX, instancedHouse.posY, instancedHouse.posZ)
				tes3mp.SetRot(object.activatingPid, instancedHouse.rotX, instancedHouse.rotZ)	
				tes3mp.SendCell(object.activatingPid)    
				tes3mp.SendPos(object.activatingPid)			
				return customEventHooks.makeEventStatus(false, false)
			end
		end
	end
end)

customEventHooks.registerValidator("OnObjectSpawn", function(eventStatus, pid, cellDescription, objects)
	if not string.find(cellDescription, "Apartment of ") then return end
	return customEventHooks.makeEventStatus(false, false)
end)

customCommandHooks.registerCommand("house", WarpHouse)
customCommandHooks.registerCommand("hous", WarpHouse)

InstancedHouse = {}

InstancedHouse.WarpHouse = function(pid)
    WarpHouse(pid)
end
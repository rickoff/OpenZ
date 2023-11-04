--[[
OpenZ_CarScript
tes3mp 0.8.1
version 0.1
---------------------------
DESCRIPTION :
car driving script, included animation change, player limitation, dynamic speed
---------------------------
INSTALLATION:
Save the file as OpenZ_CarScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
OpenZ_CarScript = require("custom.OpenZ_CarScript")
---------------------------
FUNCTION:
---------------------------
]]
local PlayersModelTab = {}

local tabCar = {
	police_car_activator = "car_police"
}

local function GetName(pid)
	return string.lower(Players[pid].accountName)	
end

local function StopDrive(pid)
	local PlayerName = GetName(pid)	
	if PlayersModelTab[PlayerName] and PlayersModelTab[PlayerName].model == "base_anim_car.nif" and PlayersModelTab[PlayerName].active then
		PlayersModelTab[PlayerName].active = false
		local PlayerName = GetName(pid)	
		local targetCar = tabCar[PlayersModelTab[PlayerName].car]
		local Model = "base_anim.nif"
		tes3mp.SetModel(pid, Model)
		tes3mp.SendBaseInfo(pid)
		local IndexTarget = inventoryHelper.getItemIndex(Players[pid].data.inventory, targetCar, -1, -1, "")			
		if IndexTarget then		
			Players[pid]:LoadItemChanges({Players[pid].data.inventory[IndexTarget]}, enumerations.inventory.REMOVE)
			Players[pid].data.inventory[IndexTarget] = nil
			tableHelper.cleanNils(Players[pid].data.inventory)					
		end	
		local cellDescription = tes3mp.GetCell(pid)
		local position = {
			posX = tonumber(tes3mp.GetPosX(pid)),
			posY = tonumber(tes3mp.GetPosY(pid)),
			posZ = tonumber(tes3mp.GetPosZ(pid) - 5),
			rotX = 0,
			rotZ = 0,			
			rotY = 0
		}					
		logicHandler.CreateObjectAtLocation(tes3mp.GetCell(pid), position, dataTableBuilder.BuildObjectData(PlayersModelTab[PlayerName].car), "place")
		tes3mp.SetCell(pid, cellDescription)
		tes3mp.SendCell(pid)	
		tes3mp.SetPos(pid, position.posX + 150, position.posY + 150, position.posZ + 5)
		tes3mp.SetRot(pid, position.rotX, position.rotZ)
		tes3mp.SendPos(pid)			
		logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerFighting", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerJumping", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerViewSwitch", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "StopSound, Car_Drive", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "tgm", false)	
		local attributeId = tes3mp.GetAttributeId("Speed")		
		local Value = PlayersModelTab[PlayerName].speed
		tes3mp.SetAttributeBase(pid, attributeId, Value)
		tes3mp.SendAttributes(pid)	
		Players[pid].data.attributes.Speed.base	= Value			
		PlayersModelTab[PlayerName]	= {}	
	end
end

function CheckDrive(pid)
	if Players[pid] then
		local PlayerName = GetName(pid)	
		if PlayersModelTab[PlayerName].active then
			local posZ = tes3mp.GetPosZ(pid)	
			if tes3mp.GetSneakState(pid) or posZ <= -10 then
				return StopDrive(pid)
			end
			local Value = Players[pid].data.attributes.Speed.base + 5
			local posX = tes3mp.GetPosX(pid)
			if PlayersModelTab[PlayerName].posX == posX then
				Value = PlayersModelTab[PlayerName].speed
			end			
			PlayersModelTab[PlayerName].posX = posX
			if Value <= 400 then			
				local attributeId = tes3mp.GetAttributeId("Speed")
				tes3mp.SetAttributeBase(pid, attributeId, Value)
				tes3mp.SendAttributes(pid)	
				Players[pid].data.attributes.Speed.base	= Value	
			end
			local timerSpeedDrive = tes3mp.CreateTimerEx("CheckDrive", time.seconds(0.1), "i", pid)
			tes3mp.StartTimer(timerSpeedDrive)				
		end

	end
end

local OpenZ_CarScript = {}

OpenZ_CarScript.OnPlayerAuthentified = function(eventStatus, pid)
	local PlayerName = GetName(pid)	
	local Model = "base_anim.nif"	
	tes3mp.SetModel(pid, Model)	
	tes3mp.SendBaseInfo(pid)
	PlayersModelTab[PlayerName] = {}
end

OpenZ_CarScript.OnObjectActivate = function(eventStatus, pid, cellDescription, objects, players)

	local ObjectRefid	
	
	for _, object in pairs(objects) do
		ObjectRefid = object.refId
		ObjectIndex = object.uniqueIndex
	end	
	
	if ObjectRefid and ObjectIndex and tabCar[string.lower(ObjectRefid)] and tes3mp.GetDrawState(pid) == 0  then	
		local PlayerName = GetName(pid)	
		local Model = "base_anim_car.nif"
		PlayersModelTab[PlayerName] = {
			car = "police_car_activator",
			model = Model,
			active = true,
			speed = Players[pid].data.attributes.Speed.base,
			posX = tes3mp.GetPosX(pid)
		}				
		tes3mp.SetModel(pid, Model)
		tes3mp.SendBaseInfo(pid)
		tes3mp.UnequipItem(pid, 16)
		tes3mp.UnequipItem(pid, 17)		
		tes3mp.EquipItem(pid, 11, tabCar[string.lower(ObjectRefid)], 1, -1, -1)
		tes3mp.SendEquipment(pid)
		logicHandler.DeleteObject(pid, cellDescription, ObjectIndex, true)
		logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerFighting", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerJumping", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound, Car_Start", false)		
		logicHandler.RunConsoleCommandOnPlayer(pid, "PlayLoopSound3D, Car_Drive", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "tgm", false)
		logicHandler.RunConsoleCommandOnPlayer(pid, "PCForce3rdPerson", false)			
		logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerViewSwitch", false)					
		local timerSpeedDrive = tes3mp.CreateTimerEx("CheckDrive", time.seconds(0.1), "i", pid)	
		tes3mp.StartTimer(timerSpeedDrive)		
	end
end

OpenZ_CarScript.OnPlayerEquipment = function(eventStatus, pid, playerPacket)
	StopDrive(pid)
end

customEventHooks.registerHandler("OnObjectActivate", OpenZ_CarScript.OnObjectActivate)
customEventHooks.registerHandler("OnPlayerAuthentified", OpenZ_CarScript.OnPlayerAuthentified)
customEventHooks.registerHandler("OnPlayerEquipment", OpenZ_CarScript.OnPlayerEquipment)

return OpenZ_CarScript

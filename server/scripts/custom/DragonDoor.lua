--[[
DragonDoor
tes3mp 0.8.1
script version 1.0
---------------------------
DESCRIPTION :
creatures and hostile npc follow players through doors
---------------------------
INSTALLATION:
Edits to customScripts.lua
require("custom.DragonDoor")
]]

ActorsDeath = {}

local cfg = {
	distance = 600,
	height = 50,
	count = 5
}

local forbiddenDoor = {
	door_guard_bar = true,
	lab_startdoor = true
}

local forbiddenCell = {
	["BioCorpTeck Interior"] = true,
	["BioCorpTeck Pipe Way"] = true
}

local forbiddenActor = {
	zomb_mutant_run_01 = true
}

local DragonDoorTab = {}

local function CalculEcart(valueA, valueB)
	local a = math.abs(valueA) 
	local b = math.abs(valueB)
	local ecart = 0	
	if a > b then
		ecart = a - b
	else
		ecart = b - a
	end	
	return ecart
end

local function CleanTab(pid)
	local PlayerName = GetName(pid)	
	if DragonDoorTab[PlayerName] and DragonDoorTab[PlayerName].actors then
		DragonDoorTab[PlayerName].actors = {}
	end
end

local function ActorCellChanges(pid, oldCellDescription, newCellDescription, uniqueIndex, location)	
    local temporaryLoadedCells = {}
	if not LoadedCells[oldCellDescription] then
		logicHandler.LoadCell(oldCellDescription)
		table.insert(temporaryLoadedCells, oldCellDescription)
	end	
	if not LoadedCells[newCellDescription] then
		logicHandler.LoadCell(newCellDescription)
		table.insert(temporaryLoadedCells, newCellDescription)
	end
    local actorCount = 0
	if LoadedCells[oldCellDescription].data.objectData[uniqueIndex] then
		local refId = LoadedCells[oldCellDescription].data.objectData[uniqueIndex].refId
		actorCount = actorCount + 1		
		local packetType
		if tonumber(uniqueIndex:split("-")[1]) > 0 then		
			packetType = "actorList"
		else
			packetType = "actorDelete"	
		end				
		ResetCell.AddResetData(oldCellDescription, uniqueIndex, packetType)
		ResetCell.AddResetData(newCellDescription, uniqueIndex, "actorDelete")
		if tableHelper.containsValue(LoadedCells[oldCellDescription].data.packets.spawn, uniqueIndex) then
			if logicHandler.IsGeneratedRecord(refId) then
				local recordStore = logicHandler.GetRecordStoreByRecordId(refId)
				if recordStore ~= nil then
					LoadedCells[newCellDescription]:AddLinkToRecord(recordStore.storeType, refId, uniqueIndex)
					LoadedCells[oldCellDescription]:RemoveLinkToRecord(recordStore.storeType, refId, uniqueIndex)
				end
				for _, visitorPid in pairs(LoadedCells[newCellDescription].visitors) do
					if pid ~= visitorPid then
						recordStore:LoadGeneratedRecords(visitorPid, recordStore.data.generatedRecords, { refId })
					end
				end
			end
			for _, player in pairs(Players) do
				if pid ~= player.pid and not tableHelper.containsValue(LoadedCells[oldCellDescription].visitors, player.pid) then
					LoadedCells[oldCellDescription]:LoadActorPackets(player.pid, LoadedCells[oldCellDescription].data.objectData, { uniqueIndex })
				end
			end
			LoadedCells[oldCellDescription]:MoveObjectData(uniqueIndex, LoadedCells[newCellDescription])
		elseif tableHelper.containsValue(LoadedCells[oldCellDescription].data.packets.cellChangeFrom, uniqueIndex) then
			local originalCellDescription = LoadedCells[oldCellDescription].data.objectData[uniqueIndex].cellChangeFrom
			if originalCellDescription == newCellDescription then
				LoadedCells[oldCellDescription]:MoveObjectData(uniqueIndex, LoadedCells[newCellDescription])
				tableHelper.removeValue(LoadedCells[newCellDescription].data.packets.cellChangeTo, uniqueIndex)
				tableHelper.removeValue(LoadedCells[newCellDescription].data.packets.cellChangeFrom, uniqueIndex)
				LoadedCells[newCellDescription].data.objectData[uniqueIndex].cellChangeTo = nil
				LoadedCells[newCellDescription].data.objectData[uniqueIndex].cellChangeFrom = nil
			else
				LoadedCells[oldCellDescription]:MoveObjectData(uniqueIndex, LoadedCells[newCellDescription])
				if not LoadedCells[originalCellDescription] then
					logicHandler.LoadCell(originalCellDescription)
					table.insert(temporaryLoadedCells, originalCellDescription)
				end
				local originalCell = LoadedCells[originalCellDescription]
				if originalCell.data.objectData[uniqueIndex] then
					originalCell.data.objectData[uniqueIndex].cellChangeTo = newCellDescription
				end
			end
		elseif LoadedCells[oldCellDescription].data.objectData[uniqueIndex].cellChangeTo ~= newCellDescription then
			LoadedCells[oldCellDescription]:MoveObjectData(uniqueIndex, LoadedCells[newCellDescription])
			table.insert(LoadedCells[oldCellDescription].data.packets.cellChangeTo, uniqueIndex)
			if not LoadedCells[oldCellDescription].data.objectData[uniqueIndex] then
				LoadedCells[oldCellDescription].data.objectData[uniqueIndex] = {}
			end
			LoadedCells[oldCellDescription].data.objectData[uniqueIndex].cellChangeTo = newCellDescription
			table.insert(LoadedCells[newCellDescription].data.packets.cellChangeFrom, uniqueIndex)
			LoadedCells[newCellDescription].data.objectData[uniqueIndex].cellChangeFrom = LoadedCells[oldCellDescription].description
		end
		if LoadedCells[newCellDescription].data.objectData[uniqueIndex] then
			LoadedCells[newCellDescription].data.objectData[uniqueIndex].location = {
				posX = location.posX,
				posY = location.posY,
				posZ = location.posZ,
				rotX = location.rotX,
				rotY = location.rotY,
				rotZ = location.rotZ
			}
		end
	end
    if actorCount > 0 then	
		local splitIndex = uniqueIndex:split("-")
		for targetPid, targetPlayer in pairs(Players) do	
			tes3mp.ClearActorList()
			tes3mp.SetActorListPid(targetPid)
			tes3mp.SetActorListCell(oldCellDescription)	
			tes3mp.SetActorCell(newCellDescription)		
			tes3mp.SetActorRefNum(splitIndex[1])
			tes3mp.SetActorMpNum(splitIndex[2])
			tes3mp.SetActorPosition(location.posX, location.posY, location.posZ)
			tes3mp.SetActorRotation(location.rotX, location.rotY, location.rotZ)		
			tes3mp.AddActor()	
			tes3mp.SendActorCellChange()
			if tableHelper.containsValue(LoadedCells[newCellDescription].visitors, targetPid) then
				PlaySound3D(targetPid, "OpenDoorBase", newCellDescription, uniqueIndex, false)
			end
		end						
		LoadedCells[oldCellDescription]:QuicksaveToDrive()
		LoadedCells[newCellDescription]:QuicksaveToDrive()			
	end	
    for _, cellDescription in ipairs(temporaryLoadedCells) do
        logicHandler.UnloadCell(cellDescription)
    end
end

function StartMove(pid, uniqueIndex)
	if Players[pid] and Players[pid]:IsLoggedIn() then
		local PlayerName = GetName(pid)	
		local cellDescription = tes3mp.GetCell(pid)
		if DragonDoorTab[PlayerName] and DragonDoorTab[PlayerName].actors[uniqueIndex] then
			if ActorsDeath[uniqueIndex] then
				DragonDoorTab[PlayerName].actors[uniqueIndex] = nil
				ActorsDeath[uniqueIndex] = nil
				return
			end
			local actorData = DragonDoorTab[PlayerName].actors[uniqueIndex]
			if actorData.previousCellDescription and actorData.cellDescription and actorData.position then
				if actorData.previousCellDescription ~= cellDescription then
					if not LoadedCells[actorData.previousCellDescription] then
						ActorCellChanges(pid, actorData.previousCellDescription, actorData.cellDescription, uniqueIndex, actorData.position)
					end
				end
			end
			DragonDoorTab[PlayerName].actors[uniqueIndex] = nil
		end
	end
end

customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
	CleanTab(pid)
end)

customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
	if forbiddenCell[cellDescription] then return end
	local count = 0		
	for _, object in pairs(objects) do
		if object.activatingPid and object.refId and string.find(object.refId, "door_") and not forbiddenDoor[object.refId] then	
			local PlayerName = GetName(object.activatingPid)
			if not DragonDoorTab[PlayerName] then			
				DragonDoorTab[PlayerName] = {actors = {}}
			end
			local cell = LoadedCells[cellDescription]				
			for _, uniqueIndex in pairs(cell.data.packets.actorList) do					
				if count == cfg.count then break end
				local actorDeath = false
				local actorStats = GetActorStats(cellDescription, uniqueIndex)
				if actorStats and actorStats.healthCurrent <= 0 then
					actorDeath = true
				end
				if tableHelper.containsValue(cell.data.packets.death, uniqueIndex) then
					actorDeath = true
				end
				if DragonDoorTab[PlayerName].actors[uniqueIndex] then
					actorDeath = true
				end
				if not actorDeath
				and cell.data.objectData[uniqueIndex] 
				and cell.data.objectData[uniqueIndex].refId 
				and cell.data.objectData[uniqueIndex].location then			
					local creatureRefId = string.lower(cell.data.objectData[uniqueIndex].refId)				
					if string.find(creatureRefId, "zomb") or string.find(creatureRefId, "infected_") then
						if not forbiddenActor[creatureRefId] then
							local creaturePos = GetActorPositions(cellDescription, uniqueIndex)
							if creaturePos then
								local playerPosX = tes3mp.GetPosX(object.activatingPid)
								local playerPosY = tes3mp.GetPosY(object.activatingPid)
								local playerPosZ = tes3mp.GetPosZ(object.activatingPid)								
								local creaturePosX = creaturePos.posX
								local creaturePosY = creaturePos.posY
								local creaturePosZ = creaturePos.posZ								
								local distance = math.sqrt((playerPosX - creaturePosX)^2 + (playerPosY - creaturePosY)^2) 						
								local height = CalculEcart(playerPosZ, creaturePosZ)						
								if distance <= cfg.distance and height <= cfg.height then
									DragonDoorTab[PlayerName].actors[uniqueIndex] = {
										distance = distance,
										previousCellDescription = cellDescription
									}	
									count = count + 1
								end	
							end
						end
					end
				end
			end	
		end
	end
end)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	local cellDescription = playerPacket.location.cell
	if cellDescription == previousCellDescription then return end
	if LoadedCells[cellDescription] and LoadedCells[previousCellDescription]
	and LoadedCells[cellDescription].isExterior and LoadedCells[previousCellDescription].isExterior then
		return 
	end	
	local PlayerName = GetName(pid)	
	if not DragonDoorTab[PlayerName] then return end
	if tableHelper.isEmpty(DragonDoorTab[PlayerName].actors) then return end
	local position = { 
		posX = tes3mp.GetPosX(pid),
		posY = tes3mp.GetPosY(pid),
		posZ = tes3mp.GetPosZ(pid),
		rotX = tes3mp.GetRotX(pid),
		rotY = 0,
		rotZ = tes3mp.GetRotZ(pid)
	}
	for uniqueIndex, data in pairs(DragonDoorTab[PlayerName].actors) do
		if data.previousCellDescription == previousCellDescription then
			data.cellDescription = cellDescription
			data.position = position
			local seconds = math.ceil(data.distance / 100)
			local timerMove = tes3mp.CreateTimerEx("StartMove", time.seconds(seconds), "is", pid, uniqueIndex)			
			tes3mp.StartTimer(timerMove)
		end
	end		
end)

customEventHooks.registerHandler("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
	for _, actor in pairs(actors) do
		if actor.refId and actor.uniqueIndex then	
			if not ActorsDeath[actor.uniqueIndex] then
				ActorsDeath[actor.uniqueIndex] = true
			end
		end
	end
end)

DragonDoor = {}

DragonDoor.OnPlayerWarp = function(pid)
	CleanTab(pid)
end
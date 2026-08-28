--[[
ResetCell
OpenZ 0.2.0
script version 0.9.4
------------
INSTALLATION :
Edits to customScripts.lua add in :
require("custom.ResetCell")
------------
]]	

local DataReset = jsonInterface.load("custom/DataReset.json")
local DataCell = jsonInterface.load("custom/DataCell.json")	
local requiredDataFiles = jsonInterface.load("requiredDataFiles.json")
------------
-- CONFIG --
------------
local cfg = {
	debugLog = true,
	cleanInit = true,
	timeCheck = 60,--the time in seconds of the verification timer
	timeInterval = 300,--the time in seconds before a cell resets
	resetLoaded = false,--the cell must be reset when it is loaded or not / true or false
	resetActor = true,--actors must be reset / true or false
	resetPlace = true,--objects placed by players must be reset / true or false
	resetSpawn = true,--objects/actors spawned by client must be reset / true or false
	resetContainer = true,--containers must be reset / true or false
	resetDelete = true,--original objects deleted by players must be reset / true or false
	resetLock = true,--lock level must be reset / true or false "check issue section"
	resetTrap = true,--trap must be reset / true or false "check issue section"
	resetDoor = true,--door state must be reset / true or false
	desynchState = true,--enable/disable state must be sync or desynch with players / true or false
	desynchLock = true,
	contLock = 10,
	carLock = 30,
	doorLock = 100
}

local ForbiddenCell = {--list of cells to exclude from any reset
	cell01 = true,--exemple
	cell02 = true--exemple
}

local CellResetTimer = {--list of specific reset times for specific cells
	cell03 = 999,--exemple
	cell04 = 654--exemple
}
	
local OrderResetPacket = {"actorList", "actorDelete", "container", "objectPlace", "objectSpawn", "objectDelete", "objectLock", "objectTrap", "objectState", "doorState"}

local TimerReset = tes3mp.CreateTimer("StartResetCell", time.seconds(cfg.timeCheck))

local function CellBase(cellDescription)
	cellCible = {}
	cellCible =
	{
		entry = {
			description = cellDescription,
			creationTime = os.time()
		},
		loadState = {
			hasFullActorList = false,
			hasFullContainerData = false
		},		
		visitors = {},
		lastVisit = {},
		objectData = {},
		packets = {},
		recordLinks = {},
		authority = {},
		isRequestingContainers = false,
		containerRequestPid = {},
		isRequestingActorList = false,
		actorListRequestPid = {},
		unusableContainerUniqueIndexes = {},
		isExterior = false
	}
	for _, packetType in pairs(config.cellPacketTypes) do
		if cellCible.packets[packetType] == nil then
			cellCible.packets[packetType] = {}
		end
	end	
	if string.match(cellDescription, patterns.exteriorCell) then
		cellCible.isExterior = true
		local _, _, gridX, gridY = string.find(cellDescription, patterns.exteriorCell)
		cellCible.gridX = tonumber(gridX)
		cellCible.gridY = tonumber(gridY)
	end
	return cellCible
end

local function DeepEqualOrdered(a, b)
    if type(a) ~= type(b) then
        return false
    end

    if type(a) ~= "table" then
        return a == b
    end

    local lengthA = #a
    local lengthB = #b

    if lengthA ~= lengthB then
        return false
    end

    if lengthA > 0 then
        for i = 1, lengthA do
            if not DeepEqualOrdered(a[i], b[i]) then
                return false
            end
        end

        return true
    end

    for key, value in pairs(a) do
        if b[key] == nil then
            return false
        end

        if not DeepEqualOrdered(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function GetAnyPlayerPid()
	for pid, player in pairs(Players) do
		if Players[pid] and Players[pid]:IsLoggedIn() then
			return pid
		end
	end
	return false
end

local function LoadDataReset()
	DataReset = jsonInterface.load("custom/DataReset.json")		
end

local function SaveDataReset()
	jsonInterface.quicksave("custom/DataReset.json", DataReset)	
end

local function LoadDataCell()
	DataCell = jsonInterface.load("custom/DataCell.json")		
end

local function SaveDataCell()
	jsonInterface.quicksave("custom/DataCell.json", DataCell)	
end

local function StarterCleaner()
	if not DeepEqualOrdered(requiredDataFiles, DataReset.requiredDataFiles) then
		for cellDescription, packets in pairs(DataCell) do
			if cellDescription and not string.find(cellDescription, "Apartment of ") then
				cellBase = CellBase(cellDescription) 
				if cellBase then
					jsonInterface.save("cell/"..cellDescription..".json", cellBase)
				end
			end
		end
		DataCell = {}
		DataReset = {
			timeStamp = {},
			cell = {},
			requiredDataFiles = requiredDataFiles
		}	
		SaveDataReset()
		SaveDataCell()
	end
end

local function CleanDataCell(cellDescription)
	local clean = false
	if DataCell[cellDescription] then
		for packetType, packetTable in pairs(DataCell[cellDescription].packets) do
			for index, uniqueIndex in pairs(packetTable) do		
				if tonumber(uniqueIndex:split("-")[2]) > 0 then
					DataCell[cellDescription].packets[packetType][index] = nil
					if DataCell[cellDescription].objectData[uniqueIndex] then
						DataCell[cellDescription].objectData[uniqueIndex] = nil
					end
					clean = true
				end
			end
		end
		if clean then
			tableHelper.cleanNils(DataCell[cellDescription].packets)
			tableHelper.cleanNils(DataCell[cellDescription].objectData)
			SaveDataCell()
		end
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
	if LoadedCells[oldCellDescription].data.objectData[uniqueIndex] then
		local refId = LoadedCells[oldCellDescription].data.objectData[uniqueIndex].refId	
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
	end						
	LoadedCells[oldCellDescription]:QuicksaveToDrive()
	LoadedCells[newCellDescription]:QuicksaveToDrive()			
    for _, cellDescription in ipairs(temporaryLoadedCells) do
        logicHandler.UnloadCell(cellDescription)
    end
end

local function SendResetActors(pid, cellDescription, indexTable)
    if cfg.debugLog then
        tes3mp.LogMessage(enumerations.log.WARN, "[ResetCell] SendResetActors START for " .. cellDescription)
    end

    local tempLoaded = {}

    if not DataCell[cellDescription] then
        SaveInitialData(cellDescription)
    end

    for _, uniqueIndex in ipairs(indexTable) do
	
        if uniqueIndex and DataCell[cellDescription] then
		
            local splitIndex = uniqueIndex:split("-")
            local OriginalObjectData = DataCell[cellDescription].objectData[uniqueIndex]
			
            if OriginalObjectData and OriginalObjectData.refId then
			
				if OriginalObjectData.location and LoadedCells[cellDescription].data.objectData[uniqueIndex] and LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeTo then
					if LoadedCells[LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeTo] then return false end
					ActorCellChanges(pid, LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeTo, cellDescription, uniqueIndex, OriginalObjectData.location)
				elseif OriginalObjectData.location and LoadedCells[cellDescription].data.objectData[uniqueIndex] and LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeFrom then
					if LoadedCells[LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeFrom] then return false end				
					ActorCellChanges(pid, cellDescription, LoadedCells[cellDescription].data.objectData[uniqueIndex].cellChangeFrom, uniqueIndex, OriginalObjectData.location)
				else				
					LoadedCells[cellDescription].data.objectData[uniqueIndex] = tableHelper.deepCopy(OriginalObjectData)
					for packetType, packetTable in pairs(DataCell[cellDescription].packets) do
						if tableHelper.containsValue(packetTable, uniqueIndex) then
							tableHelper.insertValueIfMissing(LoadedCells[cellDescription].data.packets[packetType], uniqueIndex)
						end
					end
				end
				
				tes3mp.ClearActorList()
				tes3mp.SetActorListPid(pid)
				tes3mp.SetActorListCell(cellDescription)
				
				tes3mp.SetActorRefNum(splitIndex[1])
				tes3mp.SetActorMpNum(splitIndex[2])
				tes3mp.SetActorRefId(OriginalObjectData.refId)
				
				if OriginalObjectData.location then 
					tes3mp.SetActorPosition(OriginalObjectData.location.posX, OriginalObjectData.location.posY, OriginalObjectData.location.posZ)
					tes3mp.SetActorRotation(OriginalObjectData.location.rotX, OriginalObjectData.location.rotY, OriginalObjectData.location.rotZ)
				end

                if OriginalObjectData.stats then
                    local s = OriginalObjectData.stats
                    tes3mp.SetActorHealthBase(s.healthBase)
                    tes3mp.SetActorHealthCurrent(s.healthCurrent)
                    tes3mp.SetActorHealthModified(s.healthModified)
                    tes3mp.SetActorMagickaBase(s.magickaBase)
                    tes3mp.SetActorMagickaCurrent(s.magickaCurrent)
                    tes3mp.SetActorMagickaModified(s.magickaModified)
                    tes3mp.SetActorFatigueBase(s.fatigueBase)
                    tes3mp.SetActorFatigueCurrent(s.fatigueCurrent)
                    tes3mp.SetActorFatigueModified(s.fatigueModified)
                end

                if OriginalObjectData.equipment then
                    for slot, item in pairs(OriginalObjectData.equipment) do
                        if item.refId and item.refId ~= "" then
                            tes3mp.EquipActorItem(slot, item.refId, item.count or 1, -1, -1)
                        else
                            tes3mp.UnequipActorItem(slot)
                        end
                    end
                end

				if tableHelper.containsValue(LoadedCells[cellDescription].data.packets.death, uniqueIndex) then
					tableHelper.removeValue(LoadedCells[cellDescription].data.packets.death, uniqueIndex)
				end
				
				if LoadedCells[cellDescription].data.objectData[uniqueIndex] then
					if LoadedCells[cellDescription].data.objectData[uniqueIndex].deathState then
						LoadedCells[cellDescription].data.objectData[uniqueIndex].deathState = nil
					end
					if LoadedCells[cellDescription].data.objectData[uniqueIndex].killer then
						LoadedCells[cellDescription].data.objectData[uniqueIndex].killer = nil
					end
				end
				
				if ActorsDeath[uniqueIndex] then
					ActorsDeath[uniqueIndex] = nil
					tes3mp.SetActorDeathState(0)					
				end
				
                tes3mp.AddActor()	
				
				tes3mp.SendActorPosition()
				tes3mp.SendActorStatsDynamic()
				tes3mp.SendActorEquipment()				
            end
        end
    end

    for _, cell in ipairs(tempLoaded) do
        if LoadedCells[cell] then
            logicHandler.UnloadCell(cell)
        end
    end

    if cfg.debugLog then
        tes3mp.LogMessage(enumerations.log.WARN, "[ResetCell] SendResetActors DONE")
    end
	
	return true
end

local function SendDeleteActors(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendDeleteActors START")
	end	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then 
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end			
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.AddObject()		
			countObject = countObject + 1
		end
	end
	if countObject > 0 then		
        tes3mp.SendObjectDelete(true)
	end		
end

local function SendResetContainers(pid, cellDescription, indexTable)

	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetContainers START")
	end
	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]	
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)				
			local splitIndex = uniqueIndex:split("-")		
			local OriginalObjectData = DataCell[cellDescription].objectData[uniqueIndex]
			if OriginalObjectData then
				LoadedCells[cellDescription].data.objectData[uniqueIndex] = tableHelper.deepCopy(OriginalObjectData)		
				for packetType, packetTable in pairs(DataCell[cellDescription].packets) do		
					if tableHelper.containsValue(packetTable, uniqueIndex) then			
						table.insert(LoadedCells[cellDescription].data.packets[packetType], uniqueIndex)			
					end		
				end	
				if OriginalObjectData.inventory then
					for itemIndex, item in pairs(OriginalObjectData.inventory) do
						if item.enchantmentCharge == nil then
							item.enchantmentCharge = -1
						end
						if item.soul == nil then
							item.soul = ""
						end
						tes3mp.SetContainerItemRefId(item.refId)
						tes3mp.SetContainerItemCount(item.count)
						tes3mp.SetContainerItemCharge(item.charge)
						tes3mp.SetContainerItemEnchantmentCharge(item.enchantmentCharge)
						tes3mp.SetContainerItemSoul(item.soul)
						tes3mp.AddContainerItem()
					end
				end
				if OriginalObjectData.refId then
					tes3mp.SetObjectRefNum(splitIndex[1])
					tes3mp.SetObjectMpNum(splitIndex[2])
					tes3mp.SetObjectRefId(OriginalObjectData.refId)
					tes3mp.SetObjectListAction(enumerations.container.SET)	
					tes3mp.SetObjectListContainerSubAction(enumerations.containerSub.REPLY_TO_REQUEST)	
					tes3mp.AddObject()	
					countObject = countObject + 1
				end
			end
		end
	end	
	if countObject > 0 then
		tes3mp.SendContainer(true) 	
	end
end

local function SendResetObjectsPlace(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsPlace START")
	end	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.AddObject()		
			countObject = countObject + 1
		end
	end
	if countObject > 0 then		
        tes3mp.SendObjectDelete(true)
	end	
end

local function SendResetObjectsSpawn(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsSpawn START")
	end	
	local countObject = 0
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.AddObject()		
			countObject = countObject + 1
		end
	end
	if countObject > 0 then
        tes3mp.SendObjectDelete(true)	
	end	
end

local function SendResetObjectsDelete(pid, cellDescription, indexTable)	
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsDelete START")
	end	
	local consoleCommand = {"Enable", "SetDelete, 0"}	
	tes3mp.ClearObjectList()
	tes3mp.SetObjectListPid(pid)
	tes3mp.SetObjectListCell(cellDescription)	
	local countObject = 0	
	for i = 1, #(indexTable) do
		local uniqueIndex = indexTable[i]	
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			for x = 1, #(consoleCommand) do
				local command = consoleCommand[x]					
				tes3mp.SetObjectListConsoleCommand(command)		
				for otherPid, player in pairs(Players) do
					table.insert(Players[otherPid].consoleCommandsQueued, command)
				end	
				tes3mp.AddObject()
				countObject = countObject + 1			
			end
		end
	end
	if countObject > 0 then
		tes3mp.SendConsoleCommand(true, false)	
	end	
end

local function SendResetObjectsLock(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsLock START")
	end	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local refId = DataCell[cellDescription].objectData[uniqueIndex].refId
			local lockLevel = 0
			if string.find(refId, "car") then
				lockLevel = cfg.carLock
			elseif string.find(refId, "door") then
				lockLevel = cfg.doorLock
			elseif string.find(refId, "cont") then
				lockLevel = cfg.contLock
			end			
			local splitIndex = uniqueIndex:split("-")
			if not LoadedCells[cellDescription].data.objectData[uniqueIndex] then
				LoadedCells[cellDescription].data.objectData[uniqueIndex] = {refId = refId, lockLevel = lockLevel}	
			else
				LoadedCells[cellDescription].data.objectData[uniqueIndex].lockLevel = lockLevel
			end
			table.insert(LoadedCells[cellDescription].data.packets.lock, uniqueIndex)	
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])		
			tes3mp.SetObjectRefId(refId)	
			tes3mp.SetObjectLockLevel(lockLevel)	
			tes3mp.AddObject()		
			countObject = countObject + 1
		end
	end	
	if countObject > 0 then		
		tes3mp.SendObjectLock(true)	
	end
end

local function SendResetObjectsTrap(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsTrap START")
	end	
    local objectCount = 0
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			tes3mp.SetObjectDisarmState(false)
			tes3mp.AddObject()
			objectCount = objectCount + 1
		end
    end
    if objectCount > 0 then
        tes3mp.SendObjectTrap(true)
    end
end

local function SendResetObjectsState(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetObjectsState START")
	end	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do	
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local refId
			if DataCell[cellDescription]
			and DataCell[cellDescription].objectData[uniqueIndex]
			and DataCell[cellDescription].objectData[uniqueIndex].refId then
				refId = DataCell[cellDescription].objectData[uniqueIndex].refId
			elseif LoadedCells[cellDescription]
			and LoadedCells[cellDescription].data.objectData[uniqueIndex]
			and LoadedCells[cellDescription].data.objectData[uniqueIndex].refId then
				refId = LoadedCells[cellDescription].data.objectData[uniqueIndex].refId
			end
			local state = "true"
			if DataCell[cellDescription]
			and DataCell[cellDescription].objectData[uniqueIndex]
			and DataCell[cellDescription].objectData[uniqueIndex].state then
				state = DataCell[cellDescription].objectData[uniqueIndex].state
			end
			if refId and state then
				local splitIndex = uniqueIndex:split("-")
				LoadedCells[cellDescription].data.objectData[uniqueIndex] = {refId = refId, state = state}		
				tableHelper.insertValueIfMissing(LoadedCells[cellDescription].data.packets.state, uniqueIndex)		
				tes3mp.SetObjectRefNum(splitIndex[1])
				tes3mp.SetObjectMpNum(splitIndex[2])		
				tes3mp.SetObjectRefId(refId)	
				tes3mp.SetObjectState(state)	
				tes3mp.AddObject()		
				countObject = countObject + 1
			end
		end
	end	
	if countObject > 0 then		
		tes3mp.SendObjectState(false)	
	end
end

local function SendResetDoorsState(pid, cellDescription, indexTable)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : SendResetDoorsState START")
	end	
	local countObject = 0	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
	for i = 1, #(indexTable) do
		local uniqueIndex = indexTable[i]
		if uniqueIndex then
			for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
				tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
			end		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
			tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
			tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)			
			local refId = DataCell[cellDescription].objectData[uniqueIndex].refId
			local doorState = DataCell[cellDescription].objectData[uniqueIndex].doorState or 2
			local splitIndex = uniqueIndex:split("-")		
			LoadedCells[cellDescription].data.objectData[uniqueIndex] = {refId = refId, doorState = doorState}		
			table.insert(LoadedCells[cellDescription].data.packets.doorState, uniqueIndex)		
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])		
			tes3mp.SetObjectRefId(refId)	
			tes3mp.SetObjectDoorState(doorState)	
			tes3mp.AddObject()		
			countObject = countObject + 1
		end
	end	
	if countObject > 0 then		
		tes3mp.SendDoorState(true)	
	end
end

local function ResetCellData(cellDescription)
	if cfg.debugLog then
		tes3mp.LogAppend(enumerations.log.WARN, "DEBUG RESET CELL : ResetCellData : "..cellDescription)
	end		
	local pid = GetAnyPlayerPid()	
	for x = 1, #(OrderResetPacket) do
		local packetType = OrderResetPacket[x]
		local indexTable = DataReset.cell[cellDescription][packetType]			
		if pid then
			if not tableHelper.isEmpty(indexTable) then	
				if packetType == "actorList" then			
					if SendResetActors(pid, cellDescription, indexTable) == false then return false end
				elseif packetType == "actorDelete" then			
					SendDeleteActors(pid, cellDescription, indexTable)				
				elseif packetType == "container" then
					SendResetContainers(pid, cellDescription, indexTable)		
				elseif packetType == "objectPlace" then
					SendResetObjectsPlace(pid, cellDescription, indexTable)	
				elseif packetType == "objectSpawn" then
					SendResetObjectsSpawn(pid, cellDescription, indexTable)				
				elseif packetType == "objectDelete" then
					SendResetObjectsDelete(pid, cellDescription, indexTable)
				elseif packetType == "objectTrap" then
					SendResetObjectsTrap(pid, cellDescription, indexTable)
				elseif packetType == "objectLock" then
					SendResetObjectsLock(pid, cellDescription, indexTable)
				elseif packetType == "objectState" then
					SendResetObjectsState(pid, cellDescription, indexTable)				
				elseif packetType == "doorState" then
					SendResetDoorsState(pid, cellDescription, indexTable)
				end
			end
		else
			for i = 1, #(indexTable) do
				local uniqueIndex = indexTable[i]
				if uniqueIndex then	
					for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
						tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
					end		
					LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
					tableHelper.cleanNils(LoadedCells[cellDescription].data.packets)
					tableHelper.cleanNils(LoadedCells[cellDescription].data.objectData)
				end
			end
		end
	end	

	LoadedCells[cellDescription].data.loadState = {
		hasFullContainerData = false,
		hasFullActorList = false
	}
	return true
end

local function AddResetData(cellDescription, uniqueIndex, packetType)
	if ForbiddenCell[cellDescription] then return end
	if string.find(cellDescription, "Apartment of ") then return end
	if not DataReset.cell[cellDescription] then
		DataReset.cell[cellDescription] = {
			actorList = {},
			actorDelete = {},
			container = {},
			objectPlace = {},
			objectSpawn = {},			
			objectDelete = {},
			objectLock = {},
			objectTrap = {},
			objectState = {},
			doorState = {}
		}
	end
	if not DataReset.timeStamp[cellDescription] then
		DataReset.timeStamp[cellDescription] = os.time()
	end	
	tableHelper.insertValueIfMissing(DataReset.cell[cellDescription][packetType], uniqueIndex)	
	SaveDataReset()
end

function SaveInitialData(cellDescription)
	if not LoadedCells[cellDescription] then	
		logicHandler.LoadCell(cellDescription)		
	end	
	LoadedCells[cellDescription]:SaveActorPositions()
	LoadedCells[cellDescription]:SaveActorStatsDynamic()
	DataCell[cellDescription] = tableHelper.deepCopy(LoadedCells[cellDescription].data)
	CleanDataCell(cellDescription)	
	SaveDataCell()	
	LoadedCells[cellDescription]:SaveToDrive()	
end	

function StartResetCell()
    local NeedSave = false
    local tempLoadedCell = {}
    for cellDescription, data in pairs(DataReset.cell) do
        local ResetTime = cfg.timeInterval
        if CellResetTimer[cellDescription] then
            ResetTime = CellResetTimer[cellDescription]
        end
        local timeStamp = DataReset.timeStamp[cellDescription]
        if timeStamp then
            local CheckTimeReset = os.time() - timeStamp
            if CheckTimeReset >= ResetTime then
                if cfg.resetLoaded or (not cfg.resetLoaded and not LoadedCells[cellDescription]) then
                    if not LoadedCells[cellDescription] then
                        logicHandler.LoadCell(cellDescription)
                        table.insert(tempLoadedCell, cellDescription)
                    end				
                    if ResetCellData(cellDescription) then
						DataReset.cell[cellDescription] = nil
						DataReset.timeStamp[cellDescription] = nil
						NeedSave = true
					end
                end
            end
        else
            DataReset.cell[cellDescription] = nil
            NeedSave = true
        end
    end

    if NeedSave then
        tableHelper.cleanNils(DataReset.cell)
        tableHelper.cleanNils(DataReset.timeStamp)
        SaveDataReset()
    end

    for i = 1, #tempLoadedCell do
        local cell = tempLoadedCell[i]
        if cell and LoadedCells[cell] then
            logicHandler.UnloadCell(cell)
        end
    end

    tes3mp.RestartTimer(TimerReset, time.seconds(cfg.timeCheck))
end

customEventHooks.registerHandler("OnServerInit", function(eventStatus)
	if not DataCell then
		DataCell = {}
		SaveDataCell()
	end	
	if not DataReset then	
		DataReset = {
			timeStamp = {},
			cell = {},
			requiredDataFiles = requiredDataFiles
		}		
		SaveDataReset()			
	end	
	StarterCleaner()
	tes3mp.StartTimer(TimerReset)	
end)

customEventHooks.registerHandler("OnActorList", function(eventStatus, pid, cellDescription, actors)
	if cfg.resetActor and not DataCell[cellDescription] then
		tes3mp.StartTimer(tes3mp.CreateTimerEx("SaveInitialData", time.seconds(1), "s", cellDescription))	
	end	
end)

customEventHooks.registerValidator("OnActorCellChange", function(eventStatus, pid, cellDescription)
	if cfg.resetActor then
		tes3mp.ReadReceivedActorList()	
		for actorIndex = 0, tes3mp.GetActorListSize() - 1 do
			local uniqueIndex = tes3mp.GetActorRefNum(actorIndex) .. "-" .. tes3mp.GetActorMpNum(actorIndex)
			local newCellDescription = tes3mp.GetActorCell(actorIndex)			
			if uniqueIndex and uniqueIndex ~= "0-0" and LoadedCells[cellDescription]
			and LoadedCells[cellDescription].data.objectData[uniqueIndex]
			and not LoadedCells[cellDescription].data.objectData[uniqueIndex].summon then	
				local packetType
				if tonumber(uniqueIndex:split("-")[1]) > 0 then		
					packetType = "actorList"
				else
					packetType = "actorDelete"	
				end
				AddResetData(cellDescription, uniqueIndex, packetType)					
				local newCellDescription = tes3mp.GetActorCell(actorIndex)			
				if newCellDescription and newCellDescription ~= cellDescription then
					AddResetData(newCellDescription, uniqueIndex, packetType)			
				end	
			end		
		end	
	end
end)

customEventHooks.registerHandler("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
	if cfg.resetActor then
		for _, actor in pairs(actors) do	
			if actor.uniqueIndex and LoadedCells[cellDescription]
			and LoadedCells[cellDescription].data.objectData[actor.uniqueIndex] 
			and not LoadedCells[cellDescription].data.objectData[actor.uniqueIndex].summon then
				local packetType
				if tonumber(actor.uniqueIndex:split("-")[1]) > 0 then		
					packetType = "actorList"
				else
					packetType = "actorDelete"	
				end
				AddResetData(cellDescription, actor.uniqueIndex, packetType)	
			end
		end
	end
end)

customEventHooks.registerHandler("OnContainer", function(eventStatus, pid, cellDescription, objects)
	if cfg.resetContainer then
		local packetType = "container"
		local action = tes3mp.GetObjectListAction()		
		for _, object in pairs(objects) do
			if LoadedCells[cellDescription] and object.uniqueIndex and object.uniqueIndex ~= "0-0" then
				if tableHelper.containsValue(LoadedCells[cellDescription].data.packets.actorList, object.uniqueIndex) then
					if tonumber(object.uniqueIndex:split("-")[1]) > 0 then		
						packetType = "actorList"
					else
						packetType = "actorDelete"	
					end
				end
				AddResetData(cellDescription, object.uniqueIndex, packetType)
			end
		end		
	end
end)

customEventHooks.registerHandler("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
	if cfg.resetPlace then
		for _, object in pairs(objects) do
			if object.uniqueIndex then	
				AddResetData(cellDescription, object.uniqueIndex, "objectPlace")
			end
		end
	end
end)

customEventHooks.registerHandler("OnObjectSpawn", function(eventStatus, pid, cellDescription, objects)
	if cfg.resetSpawn then
		for _, object in pairs(objects) do
			if object.uniqueIndex and not object.summon then	
				AddResetData(cellDescription, object.uniqueIndex, "objectSpawn")
			end
		end
	end
end)

customEventHooks.registerValidator("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)	
	for _, object in pairs(objects) do		
		if object.uniqueIndex and LoadedCells[cellDescription] then
			if tableHelper.containsValue(LoadedCells[cellDescription].data.packets.actorList, object.uniqueIndex) then
				return customEventHooks.makeEventStatus(false, false)
			end
		end
	end	
end)

customEventHooks.registerHandler("OnObjectDelete", function(eventStatus, pid, cellDescription, objects)	
	if cfg.resetDelete then
		for _, object in pairs(objects) do		
			if object.uniqueIndex and tonumber(object.uniqueIndex:split("-")[1]) > 0 then
				AddResetData(cellDescription, object.uniqueIndex, "objectDelete")
			end
		end	
	end
end)

customEventHooks.registerValidator("OnObjectLock", function(eventStatus, pid, cellDescription, objects)
	if cfg.desynchLock then
		local objectCount = 0

		tes3mp.ClearObjectList()
		tes3mp.SetObjectListPid(pid)
		tes3mp.SetObjectListCell(cellDescription)

		for _, object in pairs(objects) do
			if object.uniqueIndex and object.refId and object.lockLevel then
				local splitIndex = object.uniqueIndex:split("-")
				tes3mp.SetObjectRefNum(splitIndex[1])
				tes3mp.SetObjectMpNum(splitIndex[2])
				tes3mp.SetObjectRefId(object.refId)
				tes3mp.SetObjectLockLevel(object.lockLevel)
				tes3mp.AddObject()
				objectCount = objectCount + 1
			end
		end

		if objectCount > 0 then
			tes3mp.SendObjectLock(false)
		end	
		
		return customEventHooks.makeEventStatus(false, false)	
	end
end)

customEventHooks.registerHandler("OnObjectLock", function(eventStatus, pid, cellDescription, objects)
	if cfg.resetLock then
		for _, object in pairs(objects) do
			if object.uniqueIndex and tonumber(object.uniqueIndex:split("-")[1]) > 0 then
				if DataCell[cellDescription] and not DataCell[cellDescription].objectData[object.uniqueIndex] then
					table.insert(DataCell[cellDescription].packets.lock, object.uniqueIndex)
					DataCell[cellDescription].objectData[object.uniqueIndex] = {refId = object.refId, lockLevel = object.lockLevel} 
					SaveDataCell()
				end
				AddResetData(cellDescription, object.uniqueIndex, "objectLock")			
			end
		end
	end
end)

customEventHooks.registerHandler("OnObjectTrap", function(eventStatus, pid, cellDescription, objects)	
	if cfg.resetTrap then	
		for _, object in pairs(objects) do	
			if object.uniqueIndex then
				if DataCell[cellDescription] and not DataCell[cellDescription].objectData[object.uniqueIndex] then
					table.insert(DataCell[cellDescription].packets.trap, object.uniqueIndex)
					DataCell[cellDescription].objectData[object.uniqueIndex] = {refId = object.refId} 
					SaveDataCell()
				end			
				AddResetData(cellDescription, object.uniqueIndex, "objectTrap")	
			end
		end	
	end
end)

customEventHooks.registerHandler("OnDoorState", function(eventStatus, pid, cellDescription, objects)
	if cfg.resetDoor then
		for _, object in pairs(objects) do
			if object.uniqueIndex  and tonumber(object.uniqueIndex:split("-")[1]) > 0 then
				if DataCell[cellDescription] and not DataCell[cellDescription].objectData[object.uniqueIndex] then
					table.insert(DataCell[cellDescription].packets.doorState, object.uniqueIndex)
					DataCell[cellDescription].objectData[object.uniqueIndex] = {refId = object.refId, doorState = 2} 
					SaveDataCell()
				end	
				AddResetData(cellDescription, object.uniqueIndex, "doorState")	
			end
		end
	end
end)

customEventHooks.registerValidator("OnObjectState", function(eventStatus, pid, cellDescription, objects)
	local forEveryone = true
	if cfg.desynchState then
		forEveryone = false
	end
	if string.find(cellDescription, "Apartment of ") then
		return customEventHooks.makeEventStatus(false, false)
	end
	for _, object in pairs(objects) do
		if object.uniqueIndex and tonumber(object.uniqueIndex:split("-")[1]) > 0 then
			tes3mp.ClearObjectList()
			tes3mp.SetObjectListPid(pid)
			tes3mp.SetObjectListCell(cellDescription)
			local splitIndex = object.uniqueIndex:split("-")		
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])		
			tes3mp.SetObjectRefId(object.refId)	
			tes3mp.SetObjectState(object.state)			
			tes3mp.AddObject()
			tes3mp.SendObjectState(forEveryone)
			if forEveryone then
				AddResetData(cellDescription, object.uniqueIndex, "objectState")
			end
		end
	end
	return customEventHooks.makeEventStatus(false, false)
end)

ResetCell = {}

ResetCell.AddResetData = function(cellDescription, uniqueIndex, packetType)
	AddResetData(cellDescription, uniqueIndex, packetType)
end

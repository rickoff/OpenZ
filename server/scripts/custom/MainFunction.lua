function GetName(pid)
	if Players[pid] then
		return string.lower(Players[pid].accountName)
	end
end

function CloseMenu(pid)
	local consoleCommand = "TM"	
	tes3mp.ClearObjectList()		
	tes3mp.SetObjectListPid(pid)		
	tes3mp.SetObjectListCell(Players[pid].data.location.cell)		
	tes3mp.SetObjectListConsoleCommand(consoleCommand)		
	tes3mp.SetPlayerAsObject(pid)		
	tes3mp.AddObject()	
	for x = 1, 2 do	
		table.insert(Players[pid].consoleCommandsQueued, consoleCommand)
		tes3mp.SendConsoleCommand(false)		
	end
end

function PlaySound(pid, sound)
	logicHandler.RunConsoleCommandOnPlayer(pid, "playsound "..'"'..sound..'"', false)
end

function PlayLoopSound3D(pid, sound)
	logicHandler.RunConsoleCommandOnPlayer(pid, "PlayLoopSound3D "..'"'..sound..'"', false)
end

function StopSound(pid, sound)
	logicHandler.RunConsoleCommandOnPlayer(pid, "StopSound "..'"'..sound..'"', false)
end

function PlaySound3D(pid, sound, cellDescription, uniqueIndex, forEveryone)
	logicHandler.RunConsoleCommandOnObject(pid, "playsound3d "..'"'..sound..'"', cellDescription, uniqueIndex, forEveryone)
end

function SendObjectState(pid, cellDescription, uniqueIndex, state, forEveryone)
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    local splitIndex = uniqueIndex:split("-")
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)
    tes3mp.AddObject()	
    tes3mp.SendObjectState(forEveryone)
end

function SendObjectDelete(pid, cellDescription, uniqueIndex, packetType, forEveryone)
	if packetType then		
		ResetCell.AddResetData(cellDescription, uniqueIndex, packetType)			
	end	
	tes3mp.ClearObjectList()		
	tes3mp.SetObjectListPid(pid)		
	tes3mp.SetObjectListCell(cellDescription)	
	if LoadedCells[cellDescription] and LoadedCells[cellDescription].data.objectData[uniqueIndex] then			
		for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
			tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
		end
		LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil				
	end
	local splitIndex = uniqueIndex:split("-")		
	tes3mp.SetObjectRefNum(splitIndex[1])		
	tes3mp.SetObjectMpNum(splitIndex[2])		
	tes3mp.AddObject()			
	tes3mp.SendObjectDelete(forEveryone)	
end

function SendObjectDisable(pid, cellDescription, uniqueIndex, packetType, forEveryone)
	if packetType then		
		ResetCell.AddResetData(cellDescription, uniqueIndex, packetType)			
	end	
	tes3mp.ClearObjectList()
	tes3mp.SetObjectListPid(pid)
	tes3mp.SetObjectListCell(cellDescription)	
	if LoadedCells[cellDescription] and LoadedCells[cellDescription].data.objectData[uniqueIndex] then	
		for packetIndex, packetType in pairs(LoadedCells[cellDescription].data.packets) do
			tableHelper.removeValue(LoadedCells[cellDescription].data.packets[packetIndex], uniqueIndex)
		end
		LoadedCells[cellDescription].data.objectData[uniqueIndex] = nil		
    end
	local splitIndex = uniqueIndex:split("-")		
	tes3mp.SetObjectRefNum(splitIndex[1])		
	tes3mp.SetObjectMpNum(splitIndex[2])
	tes3mp.SetObjectRefId(refId)
	tes3mp.SetObjectState(false)
	tes3mp.AddObject()		
	tes3mp.SendObjectState(forEveryone)	
end

function SendPacketScaleObject(pid, cellDescription, uniqueIndex, scale, forEveryone)
	tes3mp.ClearObjectList()
	tes3mp.SetObjectListPid(pid)
	tes3mp.SetObjectListCell(cellDescription)
	LoadedCells[cellDescription].data.objectData[uniqueIndex].scale = scale
	LoadedCells[cellDescription]:QuicksaveToDrive()    
	local splitIndex = uniqueIndex:split("-")
	tes3mp.SetObjectRefNum(splitIndex[1])
	tes3mp.SetObjectMpNum(splitIndex[2])
	tes3mp.SetObjectScale(scale)
	tes3mp.AddObject()    
	tes3mp.SendObjectScale(forEveryone)
end

function GetIndexItemRefId(pid, refId)
	for key, slot in pairs(Players[pid].data.inventory) do
		if slot.refId and string.lower(slot.refId) == string.lower(refId) then
			return key
		end
	end
	return false
end

function DeleteObjectInventory(pid, refId, count)				
	local key = GetIndexItemRefId(pid, refId)
	if key then
		local total
		if count then
			total = count
		else
			total = Players[pid].data.inventory[key].count or 1 
		end
		local itemref = {refId = refId, count = total, charge = -1, enchantmentCharge = -1, soul = ""}
		if Players[pid].data.inventory[key].count then
			if Players[pid].data.inventory[key].count - total <= 0 then
				Players[pid].data.inventory[key] = nil
			else
				Players[pid].data.inventory[key].count = Players[pid].data.inventory[key].count - total
			end
		else
			Players[pid].data.inventory[key] = nil	
			tableHelper.cleanNils(Players[pid].data.inventory)			
		end
		Players[pid]:LoadItemChanges({itemref}, enumerations.inventory.REMOVE)
	end
end

function AddObjectInventory(pid, refId, count)
	local key = GetIndexItemRefId(pid, refId)
	if not key then
		table.insert(Players[pid].data.inventory, {refId = refId, count = count, charge = -1, enchantmentCharge = -1, soul = ""})
	elseif key then
		Players[pid].data.inventory[key].count = Players[pid].data.inventory[key].count + count
	end	
	local itemref = {refId = refId, count = count, charge = -1, enchantmentCharge = -1, soul = ""}			
	Players[pid]:LoadItemChanges({itemref}, enumerations.inventory.ADD)
end

function SendPacketObject(pid, cellDescription, uniqueIndex, packetType, forEveryone)
	if not LoadedCells[cellDescription] then return end
	local object = LoadedCells[cellDescription].data.objectData[uniqueIndex]	
	if not object then return end	
	tes3mp.ClearObjectList()
	tes3mp.SetObjectListPid(pid)
	tes3mp.SetObjectListCell(cellDescription)	
	local scale = object.scale or 1	
	if object and object.location and object.refId then		
		local splitIndex = uniqueIndex:split("-")
		tes3mp.SetObjectRefNum(splitIndex[1])
		tes3mp.SetObjectMpNum(splitIndex[2])
		tes3mp.SetObjectRefId(object.refId)		
		if packetType == "place" or packetType == "actorList" then		
			tes3mp.SetObjectPosition(object.location.posX, object.location.posY, object.location.posZ)
			tes3mp.SetObjectRotation(object.location.rotX, object.location.rotY, object.location.rotZ)
			tes3mp.SetObjectScale(scale)			
		elseif packetType == "container" and object.inventory then			
			tes3mp.SetObjectPosition(object.location.posX, object.location.posY, object.location.posZ)
			tes3mp.SetObjectRotation(object.location.rotX, object.location.rotY, object.location.rotZ)
			tes3mp.SetObjectScale(scale)					
			for itemIndex, item in pairs(object.inventory) do
				tes3mp.SetContainerItemRefId(item.refId)
				tes3mp.SetContainerItemCount(item.count or 1)
				tes3mp.SetContainerItemCharge(item.charge or -1)
				tes3mp.SetContainerItemEnchantmentCharge(item.enchantmentCharge or -1)
				tes3mp.SetContainerItemSoul(item.soul or "")
				tes3mp.AddContainerItem()
			end				
			tes3mp.SetObjectListAction(enumerations.container.SET)
			tes3mp.SetObjectListContainerSubAction(enumerations.containerSub.REPLY_TO_REQUEST)				
		end	
		tes3mp.AddObject()		
		if packetType == "place" then
			tes3mp.SendObjectPlace(forEveryone)
		elseif packetType == "actorList" then
			tes3mp.SendObjectSpawn(forEveryone)
		elseif packetType == "container" then
			tes3mp.SendContainer(forEveryone) 	
		end		
		tes3mp.SendObjectScale(forEveryone)		
	end	
end

function AddSpell(pid, tabSpell)
	local Change = false	
	tes3mp.ClearSpellbookChanges(pid)	
	tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.ADD)
	for _, spellId in ipairs(tabSpell) do	
		if not tableHelper.containsValue(Players[pid].data.spellbook, spellId) then				
			tes3mp.AddSpell(pid, spellId)			
			table.insert(Players[pid].data.spellbook, spellId)					
			Change = true			
		end		
	end	
	if Change then
		tes3mp.SendSpellbookChanges(pid)		
	end
end

function RemoveSpell(pid, tabSpell)
	local Change = false	
	tes3mp.ClearSpellbookChanges(pid)
	tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.REMOVE)
	for _, spellId in ipairs(tabSpell) do	
		if tableHelper.containsValue(Players[pid].data.spellbook, spellId) then		
			tes3mp.AddSpell(pid, spellId)			
			local foundIndex = tableHelper.getIndexByValue(Players[pid].data.spellbook, spellId)			
			Players[pid].data.spellbook[foundIndex] = nil			
			Change = true			
		else
			AddSpell(pid, tabSpell)
			RemoveSpell(pid, tabSpell)
		end
	end	
	if Change then
		tes3mp.SendSpellbookChanges(pid)	
		tableHelper.cleanNils(Players[pid].data.spellbook)			
	end	
end

function JournalIteration(journal, questName, questIndex)
	for id, data in pairs(journal) do
		if data.quest and data.quest == questName and data.index == questIndex then		
			return true		
		end		
	end
	return false
end

function GetActorPositions(cellDescription, uniqueIndex)
    tes3mp.ReadCellActorList(cellDescription)
    local actorListSize = tes3mp.GetActorListSize()
    if actorListSize == 0 then
        return false
    end
    for objectIndex = 0, actorListSize - 1 do
        local targetIndex = tes3mp.GetActorRefNum(objectIndex) .. "-" .. tes3mp.GetActorMpNum(objectIndex)
        if targetIndex == uniqueIndex then
            local location = {
                posX = tes3mp.GetActorPosX(objectIndex),
                posY = tes3mp.GetActorPosY(objectIndex),
                posZ = tes3mp.GetActorPosZ(objectIndex)
            }
			return location
        end
    end
	return false
end

function GetActorStats(cellDescription, uniqueIndex)
    tes3mp.ReadCellActorList(cellDescription)
    local actorListSize = tes3mp.GetActorListSize()
    if actorListSize == 0 then
        return false
    end
    for objectIndex = 0, actorListSize - 1 do
        local targetIndex = tes3mp.GetActorRefNum(objectIndex) .. "-" .. tes3mp.GetActorMpNum(objectIndex)
        if targetIndex == uniqueIndex then
			local stats = {
				healthBase = tes3mp.GetActorHealthBase(objectIndex),
				healthCurrent = tes3mp.GetActorHealthCurrent(objectIndex),
				healthModified = tes3mp.GetActorHealthModified(objectIndex),
				magickaBase = tes3mp.GetActorMagickaBase(objectIndex),
				magickaCurrent = tes3mp.GetActorMagickaCurrent(objectIndex),
				magickaModified = tes3mp.GetActorMagickaModified(objectIndex),
				fatigueBase = tes3mp.GetActorFatigueBase(objectIndex),
				fatigueCurrent = tes3mp.GetActorFatigueCurrent(objectIndex),
				fatigueModified = tes3mp.GetActorFatigueModified(objectIndex)
			}		
			return stats
        end
    end
	return false
end

function UnequipItem(pid, index)
    tes3mp.UnequipItem(pid, index)			
    Players[pid].previousEquipment = tableHelper.deepCopy(Players[pid].data.equipment)
    tes3mp.SendEquipment(pid)
end
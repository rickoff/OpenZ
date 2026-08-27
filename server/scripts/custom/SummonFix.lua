--[[
SummonFix
tes3mp 0.8.1
script version 1.0
---------------------------
INSTALLATION:
Edits to customScripts.lua
require("custom.SummonFix")
--]]

local cfg = {
	limitSummoned = true,
	summonLimit = 1
}

local function checkForStraySummons(pid, cellDescription)
	if LoadedCells[cellDescription] then
		local indexesToDelete = {}		
		for _,uniqueIndex in pairs(LoadedCells[cellDescription].data.packets.actorList) do
			if LoadedCells[cellDescription].data.objectData[uniqueIndex] then				
				local summon = LoadedCells[cellDescription].data.objectData[uniqueIndex].summon
				if summon then
					if summon.summoner.refId then						
					elseif summon.summoner.playerName then					
						local foundOwner = false						
						for sPid, player in pairs(Players) do
							if Players[sPid] and player:IsLoggedIn() and Players[sPid].summons[uniqueIndex] then
								foundOwner = true
								break
							end	
						end						
						if not foundOwner then
							tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
						end				
					else
						tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
					end					
				elseif LoadedCells[cellDescription].data.objectData[uniqueIndex].refId and string.match(LoadedCells[cellDescription].data.objectData[uniqueIndex].refId, "comp_") then
					tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
				end				
			end
		end		
		if not tableHelper.isEmpty(indexesToDelete) then
			for _,uniqueIndex in pairs(indexesToDelete) do
				logicHandler.DeleteObject(pid, cellDescription, uniqueIndex, true)
				LoadedCells[cellDescription]:DeleteObjectData(uniqueIndex)
			end
		end		
	end
end

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	checkForStraySummons(pid, playerPacket.location.cell)
end)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	function Cell:SaveObjectsSpawned(objects)
		for uniqueIndex, object in pairs(objects) do
			local location = object.location
			local preventSave = false
			if tableHelper.getCount(location) == 6 and tableHelper.usesNumericalValues(location) and
				self:ContainsPosition(location.posX, location.posY) then
				local refId = object.refId
				self:InitializeObjectData(uniqueIndex, refId)
				self.data.objectData[uniqueIndex].location = location
				if object.summon then
					local summonDuration = object.summon.duration
					if summonDuration == 0 then
						summonDuration = 2419200
					end
					if summonDuration > 0 then
						local summon = {}
						summon.duration = summonDuration -- object.summon.duration
						summon.effectId = object.summon.effectId
						summon.spellId = object.summon.spellId
						summon.startTime = object.summon.startTime
						summon.summoner = {}
						local hasPlayerSummoner = object.summon.hasPlayerSummoner
						if hasPlayerSummoner then
							local summonerPid = object.summon.summoner.pid
							summon.summoner.playerName = object.summon.summoner.playerName
							if Players[summonerPid] then
								if cfg.limitSummoned then
									if Players[summonerPid] and Players[summonerPid]:IsLoggedIn() and Players[summonerPid].accountName == summon.summoner.playerName then
										for summonUniqueIndex, summonRefId in pairs(Players[summonerPid].summons) do
											if refId == summonRefId and summonUniqueIndex ~= uniqueIndex then
												local cell = logicHandler.GetCellContainingActor(summonUniqueIndex)
												if cell then
													local cellDescription = cell.description
													logicHandler.DeleteObject(summonerPid, cellDescription, summonUniqueIndex, true)
													cell:DeleteObjectData(summonUniqueIndex)
												end
												Players[summonerPid].summons[summonUniqueIndex] = nil
											end
										end
									end
								end
								if cfg.summonLimit > 0 then
									local activeSummonCount = 0
									for x,y in pairs(Players[summonerPid].summons) do
										activeSummonCount = activeSummonCount + 1
									end									
									if Players[summonerPid].summons ~= nil and activeSummonCount >= cfg.summonLimit then
										local uniqueIndexesToClear = {}
										local uniqueSummonIndexes = {}										
										for summonUniqueIndex, summonRefId in pairs(Players[summonerPid].summons) do
											table.insert(uniqueSummonIndexes, {uniqueIndex = summonUniqueIndex, refId = summonRefId})
										end									
										table.sort(uniqueSummonIndexes, function(a,b) return a.uniqueIndex<b.uniqueIndex end)
										if #uniqueSummonIndexes >= cfg.summonLimit then											
											local overlimitCount = (#uniqueSummonIndexes - cfg.summonLimit) + 1											
											for n=1,overlimitCount do
												local t = uniqueSummonIndexes[n]
												if t and t.uniqueIndex then
													local cell = logicHandler.GetCellContainingActor(t.uniqueIndex)
													if cell then
														local cellDescription = cell.description
														logicHandler.DeleteObject(summonerPid, cellDescription, t.uniqueIndex, true)
														cell:DeleteObjectData(t.uniqueIndex)
													end
													Players[summonerPid].summons[t.uniqueIndex] = nil
												end
											end
											
										end										
									end
								end							
								if not preventSave then
									Players[summonerPid].summons[uniqueIndex] = refId
								end
							else
								preventSave = true
							end
						else
							summon.summoner.refId = object.summon.summoner.refId
							summon.summoner.uniqueIndex = object.summon.summoner.uniqueIndex
						end						
						if not preventSave then
							self.data.objectData[uniqueIndex].summon = summon
						end
					end
				end
				if not preventSave then
					table.insert(self.data.packets.spawn, uniqueIndex)
					table.insert(self.data.packets.actorList, uniqueIndex)
					if logicHandler.IsGeneratedRecord(refId) then
						local recordStore = logicHandler.GetRecordStoreByRecordId(refId)
						if recordStore then
							self:AddLinkToRecord(recordStore.storeType, refId, uniqueIndex)
						end
					end
				end
			end
		end
	end
	function Cell:LoadObjectsSpawned(pid, objectData, uniqueIndexArray, forEveryone)
		local objectCount = 0
		tes3mp.ClearObjectList()
		tes3mp.SetObjectListPid(pid)
		tes3mp.SetObjectListCell(self.description)
		for arrayIndex, uniqueIndex in pairs(uniqueIndexArray) do
			if objectData[uniqueIndex] then
				local location = objectData[uniqueIndex].location
				if type(location) == "table" and tableHelper.getCount(location) == 6 and
					tableHelper.usesNumericalValues(location) and
					self:ContainsPosition(location.posX, location.posY) then
					local shouldSkip = false
					local summon = objectData[uniqueIndex].summon
					if summon then
						local currentTime = os.time()
						local summonDuration = summon.duration
						if summonDuration == 0 then
							summonDuration = 2419200
						end
						local finishTime = summon.startTime + summonDuration
						if currentTime >= finishTime then
							self:DeleteObjectData(uniqueIndex)
							shouldSkip = true
						elseif summon.summoner.playerName then
							if not logicHandler.IsPlayerNameLoggedIn(summon.summoner.playerName) then
								self:DeleteObjectData(uniqueIndex)
								shouldSkip = true
							end
						elseif summon.summoner.uniqueIndex == nil then
							shouldSkip = true
						end
					end
					if not shouldSkip then
						packetBuilder.AddObjectSpawn(uniqueIndex, objectData[uniqueIndex])
						objectCount = objectCount + 1
					end
				else
					objectData[uniqueIndex] = nil
					tableHelper.removeValue(uniqueIndexArray, uniqueIndex)
				end
			end
		end
		if objectCount > 0 then
			tes3mp.SendObjectSpawn(forEveryone)
		end
	end
end)
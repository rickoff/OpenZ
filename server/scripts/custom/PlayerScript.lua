PlayersDeath = {}

local forbidenItemDrop = {
	badge_police_01 = true,
	badge_smith = true,
	key_bct_pipway = true,
	key_hosp_exit = true,
	key_hosp_room_00 = true,
	key_hosp_room_13 = true,
	key_hosp_room_a0 = true,
	key_hosp_room_a1 = true,
	key_hosp_room_a2 = true,
	key_hosp_room_a3 = true,
	key_motel_room_01 = true,
	key_soldier_01 = true,
	key_soldier_02 = true,
	letter_mq_car = true,
	misc_military_medal_01 = true,
	misc_military_medal_02 = true,
	misc_military_medal_03 = true,
	call_dog = true,
	call_drone = true,
	mainmenu = true,
	book_survival_01 = true,
	book_tablet_01 = true,
	book_tablet_02 = true,
	book_usb_katya = true,
	book_usb_password = true,
	key_office_01 = true,
	key_office_02 = true,
	key_office_03 = true,
	key_office_04 = true,
	key_office_05 = true,
	key_office_06 = true,
	key_office_07 = true,
	key_club = true,
	key_camp_01 = true,
	key_car_01 = true
}

local cfg = {
	DeathTimer = 5,
	Pourcent = 20
}

local trd = {
	DeathWait = color.Red .. "You are unconscious.\n\n" .. color.Orange .. "You can wait for someone to help you.\n\n" .. color.White .. "If you are unconscious clicking will make you reappear at the last checkpoint otherwise it closes the window.",
	DeathChoice = "Respawn / Close",
	HelpPlayer = "Do you want to help this person ?",
	NeedItem = "You need a complete care kit including a red, blue, green inalator, a bandage and antibiotics.",
	AddRespawn = "Checkpoint location.",
	Essential = "Essential item collected.",
	RessuCheck = "You have been revived, at the last checkpoint.\n",
	Welcome = (
		color.Red.."Welcome to Open-Z"
		..color.White.."\n\nServer "..color.White.."for the community.\n"
		..color.Orange.."\nQuick keys: \n"
		..color.Yellow .. " F1" .. color.White .. " to configure key shortcuts.\n"
		..color.Yellow .. " F2" .. color.White .. " to modify the chat window mode.\n"
		..color.Yellow .. " F3" .. color.White .. " to show the frames per second.\n"
		..color.Yellow .. " F11" .. color.White .. " to hide the interface.\n"
		..color.Yellow .. " F12" .. color.White .. " to take a screenshot.\n"
		..color.Yellow .. " Y" .. color.White .. " to type in the chat window.\n"
		..color.Yellow .. " 9" .. color.White .. " to open the server menu.\n\n"
	)	
}

local gui = {
	RessurectWaitGUI = 01122024,
	RessurectGUI = 02122024
}

local function Resurrect(pid)
	local respawnPos = Players[pid].data.customVariables.respawnPos
	tes3mp.SetCell(pid, respawnPos.cellDescription)
	tes3mp.SendCell(pid)
	tes3mp.SetPos(pid, respawnPos.posX, respawnPos.posY, respawnPos.posZ)
	tes3mp.SetRot(pid, respawnPos.rotX, respawnPos.rotZ)
	tes3mp.SendPos(pid)
	tes3mp.Resurrect(pid, 0)
    if config.bountyResetOnDeath then
        tes3mp.SetBounty(pid, 0)
        tes3mp.SendBounty(pid)
        Players[pid]:SaveBounty()
    end
	RemoveSpell(pid, {"disease_infection_low", "disease_infection_med", "disease_infection_high", "bleeding_damage_low", "bleeding_damage_med", "bleeding_damage_high"})
	PlayersDeath[GetName(pid)] = false	
	logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerControls", false)		
    tes3mp.SendMessage(pid, trd.RessuCheck, false)
	WorldRanked.SaveSurviveTime(pid)
end

local function ResurrectPlayer(pid)
	local targetPid = Players[pid].data.targetPid
	if Players[targetPid] and Players[targetPid]:IsLoggedIn() and PlayersDeath[GetName(targetPid)] then 
		if GetIndexItemRefId(pid, "med_inhaler_a") and GetIndexItemRefId(pid, "med_inhaler_f") and GetIndexItemRefId(pid, "med_inhaler_h") 
		and GetIndexItemRefId(pid, "med_pills_disease") and GetIndexItemRefId(pid, "med_bandage") then
			DeleteObjectInventory(pid, "med_inhaler_a", 1)
			DeleteObjectInventory(pid, "med_inhaler_f", 1)
			DeleteObjectInventory(pid, "med_inhaler_h", 1)
			DeleteObjectInventory(pid, "med_pills_disease", 1)
			DeleteObjectInventory(pid, "med_bandage", 1)				
			tes3mp.Resurrect(targetPid, 0)
			local PlayerHealthBase = tes3mp.GetHealthBase(targetPid)
			local Pourcent = (PlayerHealthBase * cfg.Pourcent) / 100
			tes3mp.SetHealthCurrent(targetPid, Pourcent)
			tes3mp.SendStatsDynamic(targetPid)
			RemoveSpell(targetPid, {"disease_infection_low", "disease_infection_med", "disease_infection_high", "bleeding_low", "bleeding_med", "bleeding_high"})			
			PlayersDeath[GetName(targetPid)] = false
			logicHandler.RunConsoleCommandOnPlayer(targetPid, "EnablePlayerControls", false)			
		else
			tes3mp.MessageBox(pid, -1, trd.NeedItem)		
		end
	end
end

local function CreatePlayerCorpse(cellDescription, location, refId, scale, tempInventory)
	local LoadedCell = LoadedCells[cellDescription]
	if not LoadedCell then return end
	local scale = scale or 1
	local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local uniqueIndex =  0 .. "-" .. mpNum		
	LoadedCell:InitializeObjectData(uniqueIndex, refId)	
	local objectData = LoadedCell.data.objectData[uniqueIndex]	
	if not objectData then return end
	objectData.location = location
	objectData.scale = scale
	objectData.inventory = tempInventory		
	table.insert(LoadedCell.data.packets.actorList, uniqueIndex)		
	table.insert(LoadedCell.data.packets.scale, uniqueIndex)
	table.insert(LoadedCell.data.packets.container, uniqueIndex)	
	WorldInstance:SetCurrentMpNum(mpNum) 
	tes3mp.SetCurrentMpNum(mpNum)	
	return uniqueIndex	
end

local function ProcessDeath(pid)
	if not PlayersDeath[GetName(pid)] then return end
	local cellDescription = tes3mp.GetCell(pid)	
	if not LoadedCells[cellDescription] then return end
	if Players[pid].data.customVariables.respawnPos.cellDescription ~= cellDescription then	
		local position = {posX = tes3mp.GetPosX(pid), posY = tes3mp.GetPosY(pid), posZ = tes3mp.GetPosZ(pid), rotX = 0, rotY = 0, rotZ = 0}	
		local tempInventory = {}	
		local tempEquipment = {}
		for index, data in pairs(Players[pid].data.equipment) do
			if data and data.refId and data.refId ~= "" then
				tempEquipment[string.lower(data.refId)] = true 
			end
		end	
		for index, slot in pairs(Players[pid].data.inventory) do	
			if not forbidenItemDrop[string.lower(slot.refId)] and not tempEquipment[string.lower(slot.refId)] then
				local item = {
					refId = slot.refId,
					count = slot.count,
					charge = slot.charge,
					enchantmentCharge = slot.enchantmentCharge,
					soul = slot.soul
				}
				Players[pid].data.inventory[index] = nil
				table.insert(tempInventory, item)
			end
		end	
		Players[pid]:LoadItemChanges(tempInventory, enumerations.inventory.REMOVE)
		tableHelper.cleanNils(Players[pid].data.inventory)
		local creatureRefid = "zomb_civ_run_01"		
		if Players[pid].data.character.race == "white" then
			if Players[pid].data.character.gender == 0 then		
				creatureRefid = "infected_white_m_01"
			else
				creatureRefid = "infected_white_f_01"			
			end
		elseif Players[pid].data.character.race == "black" then
			if Players[pid].data.character.gender == 0 then		
				creatureRefid = "infected_black_m_01"
			else
				creatureRefid = "infected_black_f_01"			
			end
		end
		local uniqueIndex = CreatePlayerCorpse(cellDescription, position, creatureRefid, 1, tempInventory)	
		SendPacketObject(pid, cellDescription, uniqueIndex, "actorList", true)	
		SendPacketObject(pid, cellDescription, uniqueIndex, "container", true)	
		LoadedCells[cellDescription]:QuicksaveToDrive()	
		ResetCell.AddResetData(cellDescription, uniqueIndex, "actorDelete")	
	end
	Resurrect(pid)
end

local function ShowRessurectWaitGUI(pid)
	tes3mp.CustomMessageBox(pid, gui.RessurectWaitGUI, trd.DeathWait, trd.DeathChoice)
end

local function SaveContainers(cellDescription, pid)

    tes3mp.ReadReceivedObjectList()
    tes3mp.CopyReceivedObjectListToStore()

    local packetOrigin = tes3mp.GetObjectListOrigin()
    local action = tes3mp.GetObjectListAction()
    local subAction = tes3mp.GetObjectListContainerSubAction()
	local essential = false
	local essentialItem = {}
	
    for objectIndex = 0, tes3mp.GetObjectListSize() - 1 do

        local uniqueIndex = tes3mp.GetObjectRefNum(objectIndex) .. "-" .. tes3mp.GetObjectMpNum(objectIndex)
        local refId = tes3mp.GetObjectRefId(objectIndex)

        LoadedCells[cellDescription]:InitializeObjectData(uniqueIndex, refId)

        tableHelper.insertValueIfMissing(LoadedCells[cellDescription].data.packets.container, uniqueIndex)

        local inventory = LoadedCells[cellDescription].data.objectData[uniqueIndex].inventory

        if inventory == nil or action == enumerations.container.SET then
            inventory = {}
        end

        for itemIndex = 0, tes3mp.GetContainerChangesSize(objectIndex) - 1 do

            local itemRefId = tes3mp.GetContainerItemRefId(objectIndex, itemIndex)
            local itemCount = tes3mp.GetContainerItemCount(objectIndex, itemIndex)
            local itemCharge = tes3mp.GetContainerItemCharge(objectIndex, itemIndex)
            local itemEnchantmentCharge = tes3mp.GetContainerItemEnchantmentCharge(objectIndex, itemIndex)
            local itemSoul = tes3mp.GetContainerItemSoul(objectIndex, itemIndex)
            local actionCount = tes3mp.GetContainerItemActionCount(objectIndex, itemIndex)

            if inventoryHelper.containsItem(inventory, itemRefId, itemCharge, itemEnchantmentCharge, itemSoul) then
                local foundIndex = inventoryHelper.getItemIndex(inventory, itemRefId, itemCharge, itemEnchantmentCharge, itemSoul)
                local item = inventory[foundIndex]

				if forbidenItemDrop[string.lower(itemRefId)] then
					tes3mp.MessageBox(pid, -1, trd.Essential)
					item.count = item.count
					table.insert(essentialItem, uniqueIndex)
					essential = true
					
                elseif action == enumerations.container.ADD then
                    item.count = item.count + itemCount

                elseif action == enumerations.container.REMOVE then
                    local newCount = item.count - actionCount

                    if newCount > 0 then
                        item.count = newCount
                    elseif newCount == 0 then
                        inventory[foundIndex] = nil
                    else
                        actionCount = item.count
                        tes3mp.SetContainerItemActionCountByIndex(objectIndex, itemIndex, actionCount)
                        inventory[foundIndex] = nil
                    end

                    if inventory[foundIndex] == nil and logicHandler.IsGeneratedRecord(itemRefId) then
                        local recordStore = logicHandler.GetRecordStoreByRecordId(itemRefId)
                        if recordStore ~= nil then
                            LoadedCells[cellDescription]:RemoveLinkToRecord(recordStore.storeType, itemRefId, uniqueIndex)
                        end
                    end					
                end			
            else
                if action == enumerations.container.REMOVE then
                    tes3mp.SetContainerItemActionCountByIndex(objectIndex, itemIndex, 0)
                else
                    inventoryHelper.addItem(inventory, itemRefId, itemCount, itemCharge, itemEnchantmentCharge, itemSoul)

                    if logicHandler.IsGeneratedRecord(itemRefId) then
                        local recordStore = logicHandler.GetRecordStoreByRecordId(itemRefId)

                        if recordStore ~= nil then
                            LoadedCells[cellDescription]:AddLinkToRecord(recordStore.storeType, itemRefId, uniqueIndex)
                        end
                    end
                end
            end
        end

        tableHelper.cleanNils(inventory)
        LoadedCells[cellDescription].data.objectData[uniqueIndex].inventory = inventory
    end

	if subAction == enumerations.containerSub.REPLY_TO_REQUEST then
        tes3mp.SendContainer(true, true)
    elseif packetOrigin == enumerations.packetOrigin.CLIENT_SCRIPT_LOCAL or
        packetOrigin == enumerations.packetOrigin.CLIENT_SCRIPT_GLOBAL or
        packetOrigin == enumerations.packetOrigin.CLIENT_DIALOGUE then
        tes3mp.SendContainer(true, true)
    else
        tes3mp.SendContainer(true, false)
    end

    LoadedCells[cellDescription]:QuicksaveToDrive()

	if essential then
		local objectCount = 0
		tes3mp.ClearObjectList()
		tes3mp.SetObjectListPid(pid)
		tes3mp.SetObjectListCell(cellDescription)
		for arrayIndex, uniqueIndex in pairs(essentialItem) do
			local splitIndex = uniqueIndex:split("-")
			tes3mp.SetObjectRefNum(splitIndex[1])
			tes3mp.SetObjectMpNum(splitIndex[2])
			if LoadedCells[cellDescription]:ContainsObject(uniqueIndex) and LoadedCells[cellDescription].data.objectData[uniqueIndex].inventory ~= nil then
				tes3mp.SetObjectRefId(LoadedCells[cellDescription].data.objectData[uniqueIndex].refId)
				for itemIndex, item in pairs(LoadedCells[cellDescription].data.objectData[uniqueIndex].inventory) do
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
				tes3mp.AddObject()
				objectCount = objectCount + 1
			end
		end
		if objectCount > 0 then
			tes3mp.SetObjectListAction(0)
			tes3mp.SendContainer(true, false)
		end
	end
	
    -- Were we waiting on a full container data request from this pid?
    if LoadedCells[cellDescription].isRequestingContainerData == true and LoadedCells[cellDescription].containerRequestPid == pid and subAction == enumerations.containerSub.REPLY_TO_REQUEST then
        LoadedCells[cellDescription].isRequestingContainerData = false
        LoadedCells[cellDescription].data.loadState.hasFullContainerData = true
    end
end

function ProcessDeathTimer(pid)
	if Players[pid] and Players[pid]:IsLoggedIn() then
		ProcessDeath(pid)
	end
end

customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
	CloseMenu(pid)
	logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerControls", false)
	PlayersDeath[GetName(pid)] = true
	return customEventHooks.makeEventStatus(false, true)
end)

customEventHooks.registerHandler("OnPlayerDeath", function(eventStatus, pid)	
	if eventStatus.validCustomHandlers then	
		Players[pid].data.spellsActive = {}
		local deathReason = "committed suicide"
		if tes3mp.DoesPlayerHavePlayerKiller(pid) then
			local killerPid = tes3mp.GetPlayerKillerPid(pid)
			if pid ~= killerPid then
				deathReason = "was killed by player " .. logicHandler.GetChatName(killerPid)
			end
		else
			local killerName = tes3mp.GetPlayerKillerName(pid)
			if killerName ~= "" then
				deathReason = "was killed by " .. killerName
			end
		end
		local message = logicHandler.GetChatName(pid) .. " " .. deathReason .. ".\n"
		tes3mp.SendMessage(pid, message, true)
		local playerKiller = logicHandler.GetPlayerByName(deathReason)
		if playerKiller and playerKiller.pid ~= pid then
			local timerDeath = tes3mp.CreateTimerEx("ProcessDeathTimer", time.seconds(cfg.DeathTimer), "i", pid)	
			tes3mp.StartTimer(timerDeath)		
		else
			ShowRessurectWaitGUI(pid)			
		end	 
	end
end)

customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, targetPlayers)
	for _, targetPlayer in pairs(targetPlayers) do			
		if targetPlayer.pid and targetPlayer.activatingPid 
		and Players[targetPlayer.pid] and Players[targetPlayer.pid]:IsLoggedIn() then			
			Players[targetPlayer.activatingPid].data.targetPid = targetPlayer.pid	
			if PlayersDeath[GetName(targetPlayer.pid)] then	
				tes3mp.CustomMessageBox(targetPlayer.activatingPid, gui.RessurectGUI, trd.HelpPlayer, "Yes;No")	
			else
				TeamGroup.InviteMessage(pid, targetPlayer.pid)
			end
		end
	end
	for _, object in pairs(objects) do
		if object.uniqueIndex and object.refId and object.activatingPid then
			if object.uniqueIndex == "2423-0" then return customEventHooks.makeEventStatus(false, false) end
			if string.find(object.refId, "bed") then
				Players[object.activatingPid].data.customVariables.respawnPos = {
					cellDescription = cellDescription,
					posX = tes3mp.GetPosX(object.activatingPid),
					posY = tes3mp.GetPosY(object.activatingPid),	
					posZ = tes3mp.GetPosZ(object.activatingPid),				
					rotX = tes3mp.GetRotX(object.activatingPid),	
					rotY = 0,
					rotZ = tes3mp.GetRotZ(object.activatingPid)
				}	
				tes3mp.MessageBox(object.activatingPid, -1, trd.AddRespawn)	
			end
			if forbidenItemDrop[string.lower(object.refId)] then
				if not GetIndexItemRefId(object.activatingPid, object.refId) then													
					AddObjectInventory(object.activatingPid, object.refId, 1)
					tes3mp.ClearObjectList()		
					tes3mp.SetObjectListPid(object.activatingPid)		
					tes3mp.SetObjectListCell(cellDescription)	
					local splitIndex = object.uniqueIndex:split("-")		
					tes3mp.SetObjectRefNum(splitIndex[1])		
					tes3mp.SetObjectMpNum(splitIndex[2])		
					tes3mp.AddObject()			
					tes3mp.SendObjectDelete(false)					
					tes3mp.MessageBox(object.activatingPid, -1, trd.Essential)
					PlaySound(object.activatingPid, "Item Misc Up")
				end
				return customEventHooks.makeEventStatus(false, false)	
			end
		end
	end	
end)

customEventHooks.registerHandler("OnPlayerEndCharGen", function(eventStatus, pid)
    local consoleCommand = 'PlayBink, "IntroOpenZ.mp4", 1'
    Players[pid].consoleVideosQueued = {}
    table.insert(Players[pid].consoleVideosQueued, consoleCommand)	
    logicHandler.RunConsoleCommandOnPlayer(pid, consoleCommand, false)	
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if not Players[pid].data.customVariables.respawnPos then
		Players[pid].data.customVariables.respawnPos = {
			cellDescription = "Hospital Room 31",		
			posX = 4152,
			posY = 4285,	
			posZ = 12173,				
			rotX = 0.4,	
			rotY = 0,
			rotZ = 1.7
		}	
	end
	if Players[pid].isNewlyRegistered == false then	
		tes3mp.CustomMessageBox(pid, -1, trd.Welcome, "ok")
	end		
end)

customEventHooks.registerValidator("OnPlayerInventory", function(eventStatus, pid, playerPacket)	
	local action = tes3mp.GetInventoryChangesAction(pid)	
	local PlayerName = GetName(pid)	
	if action == enumerations.inventory.REMOVE then
		for _, item in pairs(playerPacket.inventory) do		
			if item.refId and forbidenItemDrop[string.lower(item.refId)] then
				Players[pid]:LoadItemChanges({item}, enumerations.inventory.ADD)
				return customEventHooks.makeEventStatus(false, false)
			end	
		end
	elseif action == enumerations.inventory.ADD then
		for _, item in pairs(playerPacket.inventory) do
			if item.refId and forbidenItemDrop[string.lower(item.refId)] and GetIndexItemRefId(pid, item.refId) then		
				Players[pid]:LoadItemChanges({item}, enumerations.inventory.REMOVE)
				return customEventHooks.makeEventStatus(false, false)
			end	
		end			
	end
end)

customEventHooks.registerValidator("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
	for _, object in pairs(objects) do
		if object.refId and forbidenItemDrop[string.lower(object.refId)] then	
			return customEventHooks.makeEventStatus(false, false)		
		end
	end
end)

customEventHooks.registerHandler("OnObjectHit", function(eventStatus, pid, cellDescription, objects, targetPlayers)
	local LoadedCell = LoadedCells[cellDescription]
	if LoadedCell then
		for uniqueIndex, object in pairs(objects) do
			if object.hittingPid and object.hit.success then
				if tableHelper.containsValue(LoadedCell.data.packets.actorList, uniqueIndex) then		
					local playerName = GetName(object.hittingPid)
					if LoadedCell.data.objectData[uniqueIndex] and LoadedCell.data.objectData[uniqueIndex].summon then
						local summonerName = LoadedCell.data.objectData[uniqueIndex].summon.summoner.playerName
						local summonerPid = LoadedCell.data.objectData[uniqueIndex].summon.summoner.pid					
						if tableHelper.containsValue(Players[object.hittingPid].data.alliedPlayers, summonerName) then 					
							logicHandler.SetAIForActor(LoadedCell, uniqueIndex, enumerations.ai.FOLLOW, summonerPid)
						end
					end
				end
			end		
		end
		for targetPid, targetPlayer in pairs(targetPlayers) do
			local targetPlayerName = GetName(targetPid)	
			if targetPlayerName and targetPlayer.hittingUniqueIndex and targetPlayer.hit.success then
				if LoadedCell.data.objectData[targetPlayer.hittingUniqueIndex] and LoadedCell.data.objectData[targetPlayer.hittingUniqueIndex].summon then
					local objectData = LoadedCell.data.objectData[targetPlayer.hittingUniqueIndex]
					local summonerName = objectData.summon.summoner.playerName
					local summonerPid = objectData.summon.summoner.pid
					if tableHelper.containsValue(Players[targetPid].data.alliedPlayers, summonerName) then 
						logicHandler.SetAIForActor(LoadedCell, targetPlayer.hittingUniqueIndex, enumerations.ai.FOLLOW, summonerPid)
					end
				end
			end
		end	
	end
end)

customEventHooks.registerValidator("OnContainer", function(eventStatus, pid, cellDescription, objects)
	tes3mp.ReadReceivedObjectList()	
	tes3mp.CopyReceivedObjectListToStore()	
	local action = tes3mp.GetObjectListAction()		
	for containerIndex = 0, tes3mp.GetObjectListSize() - 1 do
		for itemIndex = 0, tes3mp.GetContainerChangesSize(containerIndex) - 1 do				
			local objectRefid = tes3mp.GetContainerItemRefId(containerIndex, itemIndex)					
			if objectRefid and forbidenItemDrop[string.lower(objectRefid)] then	
				SaveContainers(cellDescription, pid)
				return customEventHooks.makeEventStatus(false, false)
			end					
		end				
	end
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)	
	if idGui == gui.RessurectWaitGUI then
		if tonumber(data) == 0 then
			ProcessDeath(pid)		
		end
	elseif idGui == gui.RessurectGUI then
		if tonumber(data) == 0 then
			ResurrectPlayer(pid)
		end	
	end
end)

PlayerScript = {}

PlayerScript.ShowRessurectWaitGUI = function(pid)
	ShowRessurectWaitGUI(pid)
end
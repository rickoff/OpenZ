--[[
FixFollowAI
tes3mp 0.8.1
---------------------------
INSTALLATION :
Save the file as FixFollowAI.lua inside your server/scripts/custom folder
Edits to customScripts.lua add in : require("custom.FixFollowAI")
---------------------------
]]		
customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	local cellDescription = playerPacket.location.cell
	local playerName = tes3mp.GetName(pid)
	if LoadedCells[cellDescription] and LoadedCells[cellDescription].data.packets.ai then
		for _, uniqueIndex in pairs(LoadedCells[cellDescription].data.packets.ai) do
			local npc = LoadedCells[cellDescription].data.objectData[uniqueIndex]
			if npc.ai.action and npc.ai.action == 4 and npc.ai.targetPlayer 
			and string.lower(npc.ai.targetPlayer) == string.lower(playerName) then
				SendObjectState(pid, cellDescription, uniqueIndex, false, true)
				SendObjectState(pid, cellDescription, uniqueIndex, true, true)			
			end		
		end
	end
end)

customEventHooks.registerHandler("OnActorCellChange", function(eventStatus, pid, cellDescription)	
	tes3mp.ReadReceivedActorList()
	for actorIndex = 0, tes3mp.GetActorListSize() - 1 do
		local uniqueIndex = tes3mp.GetActorRefNum(actorIndex) .. "-" .. tes3mp.GetActorMpNum(actorIndex)
		local newCellDescription = tes3mp.GetActorCell(actorIndex)		
		if uniqueIndex and uniqueIndex ~= "0-0" and cellDescription ~= newCellDescription then
			local useTemporaryLoad = false				
			if not LoadedCells[newCellDescription] then
				logicHandler.LoadCell(newCellDescription)
				useTemporaryLoad = true
			end				
			if not LoadedCells[newCellDescription].isExterior then
				LoadedCells[newCellDescription]:SetAuthority(pid)
				logicHandler.SetAIForActor(LoadedCells[newCellDescription], uniqueIndex, enumerations.ai.FOLLOW, pid)				
			end		
			if useTemporaryLoad == true then
				logicHandler.UnloadCell(newCellDescription)
			end		
		end
	end
end)
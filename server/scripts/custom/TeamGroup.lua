--[[
TeamGroup
tes3mp 0.8.1
---------------------------
DESCRIPTION :
Create a group, invite players, teleport to members, group message, sync journal, add/remove allied
---------------------------
INSTALLATION:
Save the file as TeamGroup.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.TeamGroup")
---------------------------
COMMAND:
/group for open main menu
]]
local playerGroup = {}

local trd = {
	MainGui = color.Red.."MENU GROUP\n\n"
	..color.Orange.."List: "
	..color.White.." to display your group members.\n\n"
	..color.Orange.."Exit/Delete:"
	..color.White.." to leave or delete a group.\n\n"
	..color.Orange.."Invitation:"
	..color.White.." to invite a player to your group.\n\n"
	..color.Orange.."Reply :"
	..color.White.." to accept an invitation to join a group.\n\n"		
	..color.Orange.."Expulsion:"
	..color.White.." to kick a player from your group.\n\n"
	..color.Orange.."Message:"
	..color.White.." to send a message to your group members.\n\n",
	MainGuiBox = "List;Exit/Delete;Invitation;Reply;Expulsion;Message;Return;Close",
	CreateGroupCreate = "You have just created a group!\n",
	InputMsg = "Enter a message for the group",
	Group = "Group: ",
	Return = "* Return *\n",
	SelectExit = "Select a player to expel them from your group.",
	ExpulseMembers = "You have just expelled a member of the group!\n",
	ExpulseYou = "You have just been kicked out of the group!\n",
	DeleteGroup = "You have just deleted your group!\n",
	ExitGroup = "You have just left the group!\n",
	InvitePlayer = "Select a player to send an invitation ",
	SelectWarp = "List of players in your group",
	JoinGroup = " just joined the group ",
	JoinGroupYou = "You have just joined the group of ",
	Xp = " xp.",
	Bonus = "Group bonus: ",
	Gain = "You won: ",
	Invitation1 = "Would you like to ask ",
	Invitation2 = " to join the group ?",
	Invitation3 = "You have received an invitation to join the group of ",		
	Choice = "Yes;No",
	Reponse = "Do you want to join the group "
}

local gui = {
	MainGUI = 20001989,
	listGUI = 20001990,
	listPlayerGUI = 20001991,
	listPlayerExitGUI = 20001992,
	MessageInput = 20001993,
	MessageInvitation = 2000194,
	MessageReponse = 20001995
}

local playerList = {
	options = {},
	invite = {},
	cancel = {}
}

local function GetGroupName(pid)
	local name = "Nothing"	
	local playerName = GetName(pid)		
	if playerGroup[playerName] then			
		name = playerName
	else	
		for groupName, members in pairs(playerGroup) do		
			if members[playerName] then			
				name = groupName				
				break				
			end			
		end		
	end	
	return name
end

local function GetGroupData(pid)
	local group = {}	
	local playerName = GetName(pid)		
	if playerGroup[playerName] then		
		group = playerGroup[playerName]
	else	
		for groupName, members in pairs(playerGroup) do	
			if members[playerName] then		
				group = playerGroup[groupName]			
				break			
			end		
		end	
	end	
	return group
end

local function GetListMemberGroup(pid)
	local options = {}
	local playerName = GetName(pid)	
	local playerGroup = GetGroupData(pid)
	for memberName, name in pairs(playerGroup) do
		if memberName ~= playerName then		
			table.insert(options, memberName)  		
		end	
	end	
	return options
end

local function GetListPlayer(pid) 
	local options = {}  
	local playerName = GetName(pid)
	for targetPid, player in pairs(Players) do
		if Players[targetPid] and Players[targetPid]:IsLoggedIn() then
			local targetName = GetName(targetPid)
			if targetName ~= playerName then
				table.insert(options, targetName)
			end		
		end
	end
	return options
end

local function AddAlliedInGroup(pid)
	local GroupList = GetListMemberGroup(pid)
	for _, playerName in ipairs(GroupList) do
		if not tableHelper.containsValue(Players[pid].data.alliedPlayers, playerName) then						
			table.insert(Players[pid].data.alliedPlayers, playerName)						
		end		
		if logicHandler.GetPlayerByName(playerName) then	
			local targetPid = logicHandler.GetPlayerByName(playerName).pid			
			if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then
				local targetGroup = GetListMemberGroup(targetPid)
				for _, targetName in ipairs(targetGroup) do					
					if not tableHelper.containsValue(Players[targetPid].data.alliedPlayers, targetName) then						
						table.insert(Players[targetPid].data.alliedPlayers, targetName)						
					end					
				end				
				Players[targetPid]:LoadAllies()					
			end			
		end		
	end
	Players[pid]:LoadAllies()		
end

local function RemoveAlliedInGroup(pid)
	local targetName = GetName(pid)	
	local GroupList = GetListMemberGroup(pid)	
	for _, playerName in ipairs(GroupList) do
		if logicHandler.GetPlayerByName(playerName) then	
			local targetPid = logicHandler.GetPlayerByName(playerName).pid		
			if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then			
				if tableHelper.containsValue(Players[targetPid].data.alliedPlayers, targetName) then					
					tableHelper.removeValue(Players[targetPid].data.alliedPlayers, targetName)				
					tableHelper.cleanNils(Players[targetPid].data.alliedPlayers)				
					Players[targetPid]:LoadAllies()
				end		
			end
		end
	end
end

local function RemoveAlliedGroupDeleted(pid)
	local GroupList = GetListMemberGroup(pid)
	for _, playerName in ipairs(GroupList) do
		local targetPlayer = logicHandler.GetPlayerByName(playerName)
		if targetPlayer and targetPlayer.pid then	
			local targetPid = targetPlayer.pid		
			if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then		
				for _, targetName in ipairs(GroupList) do				
					if tableHelper.containsValue(Players[targetPid].data.alliedPlayers, targetName) then					
						tableHelper.removeValue(Players[targetPid].data.alliedPlayers, targetName)
						tableHelper.cleanNils(Players[targetPid].data.alliedPlayers)					
					end				
				end			
				Players[targetPid]:LoadAllies()				
			end
		end
	end
end

local function CreateGroup(pid)
	local playerName = GetName(pid)	
	playerGroup[playerName] = {}
	playerGroup[playerName][playerName] = true
	tes3mp.SendMessage(pid, trd.CreateGroupCreate, false)
end

local function ExitGroup(pid)
	local playerName = GetName(pid)	
	if playerGroup[playerName] then	
		RemoveAlliedGroupDeleted(pid)		
		playerGroup[playerName] = nil		
		tes3mp.SendMessage(pid, trd.DeleteGroup, false) 		
	else
		for groupName, name in pairs(playerGroup) do		
			if playerGroup[groupName][playerName] then				
				RemoveAlliedInGroup(pid)				
				playerGroup[groupName][playerName] = nil				
				tes3mp.SendMessage(pid, trd.ExitGroup, false)			
				break				
			end				
		end			
	end
end

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	local message = trd.MainGui.."\nGroup leader : "..GetGroupName(pid).."\n"
	tes3mp.CustomMessageBox(pid, gui.MainGUI, message, trd.MainGuiBox)	
end

local function InputMessage(pid)
	tes3mp.InputDialog(pid, gui.MessageInput, trd.InputMsg, "")
end

local function OnChoiceMessage(pid, loc)	
	local playerName = GetName(pid)
	local playerGroup = GetGroupData(pid)
	for memberName, bool in pairs(playerGroup) do
		if memberName and logicHandler.GetPlayerByName(memberName) then			
			local targetPid = logicHandler.GetPlayerByName(memberName).pid			
			if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then			
				tes3mp.SendMessage(targetPid, "["..playerName.."] : "..color.Green..trd.Group..color.Pink..loc..color.Default.."\n",false)				
			end		
		end	
	end	
end

local function CheckPlayerExit(pid)	
	local playerName = GetName(pid)	
	local options = GetListMemberGroup(pid)	
	local listItem = trd.Return	
	for _, name in ipairs(options) do	
		listItem = listItem..name.."\n"
	end			
	playerList.cancel[playerName] = options	
	tes3mp.ListBox(pid, gui.listPlayerExitGUI, color.CornflowerBlue..trd.SelectExit..color.Default, listItem)	
end

local function ShowChoiceExit(pid, loc)
	local playerName = GetName(pid)
	local choice = playerList.cancel[playerName][loc]
	local targetPid		
	if choice and choice ~= "" and logicHandler.GetPlayerByName(choice) then
		targetPid = logicHandler.GetPlayerByName(choice).pid
	end
	if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then
		Players[pid].data.targetPid = targetPid
		Players[targetPid].data.targetPid = pid
		if playerGroup[playerName] then
			local targetName = GetName(targetPid)
			if playerGroup[playerName][targetName] then
				RemoveAlliedInGroup(targetPid)
				playerGroup[playerName][targetName] = nil
				tes3mp.SendMessage(pid, trd.ExpulseMembers, false)
				tes3mp.SendMessage(targetPid, trd[Traduction.GetLangage(targetPid)].ExpulseYou, false)
			end
		end
	end	
end

local function CheckPlayer(pid)	
	local playerName = GetName(pid)	
	local options = GetListPlayer(pid)	
	local listItem = trd.Return		
	for _, name in ipairs(options) do
		listItem = listItem..name.."\n"
	end	
	playerList.invite[playerName] = options	
	tes3mp.ListBox(pid, gui.listPlayerGUI, color.CornflowerBlue..trd.InvitePlayer..color.Default, listItem)	
end

local function ShowChoiceInvite(pid, loc)
	local playerName = GetName(pid)	
	local choice = playerList.invite[playerName][loc]	
	local targetPid			
	if choice ~= nil and choice ~= "" and logicHandler.GetPlayerByName(choice) then	
		targetPid = logicHandler.GetPlayerByName(choice).pid		
	end	
	if targetPid then	
		TeamGroup.InviteMessage(pid, targetPid)		
	end	
end

local function ReponseMessage(pid, targetPid)
	if Players[pid] and Players[pid]:IsLoggedIn() 
	and Players[targetPid] and Players[targetPid]:IsLoggedIn() then		
		local targetName = GetName(targetPid)		
		local message = trd.Reponse..targetName.." ?"
		tes3mp.CustomMessageBox(pid, gui.MessageReponse, message, trd.Choice)	
	end
end

local function CheckGroup(pid)	
	local playerName = GetName(pid)	
	local options = GetListMemberGroup(pid)	
	local listItem = trd.Return	
	for _, name in ipairs(options) do
		if logicHandler.GetPlayerByName(name) then
			local targetPid = logicHandler.GetPlayerByName(name).pid
			listItem = listItem..name.." : "..Players[targetPid].data.location.cell.."\n"
		end
	end		
	playerList.options[playerName] = options	
	tes3mp.ListBox(pid, gui.listGUI, color.CornflowerBlue..trd.SelectWarp..color.Default, listItem)
end

local function RegisterGroup(pid, invitePid)	
	if Players[pid] and Players[pid]:IsLoggedIn()
	and Players[invitePid] and Players[invitePid]:IsLoggedIn() then	
		local playerName = GetName(pid)		
		local targetName = GetName(invitePid)		
		ExitGroup(invitePid)
		if not playerGroup[playerName] then		
			CreateGroup(pid)	
		end
		playerGroup[playerName][targetName] = true		
		tes3mp.SendMessage(pid, targetName..trd.JoinGroup..playerName.."\n", false)		
		tes3mp.SendMessage(invitePid, trd.JoinGroupYou..playerName.."\n", false)		
		AddAlliedInGroup(pid)	
	end			
end

local function ShowChoiceList(pid, loc)	
	local choice = playerList.options[GetName(pid)][loc]	
	local targetPid	
	if choice and choice ~= "" and logicHandler.GetPlayerByName(choice) then	
		targetPid = logicHandler.GetPlayerByName(choice).pid		
	end	
	if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then		
		local targetCell = tes3mp.GetCell(targetPid)		
		if targetCell then		
			logicHandler.TeleportToPlayer(pid, pid, targetPid)			
		end		
	end
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.MainGUI then 	
		if tonumber(data) == 0 then 		
			CheckGroup(pid)			
		elseif tonumber(data) == 1 then 		
			ExitGroup(pid)			
			ShowMainGUI(pid)			
		elseif tonumber(data) == 2 then 		
			CheckPlayer(pid)
		elseif tonumber(data) == 3 then 
			local targetPid = Players[pid].data.targetPid
			ReponseMessage(pid, targetPid)
		elseif tonumber(data) == 4 then 		
			CheckPlayerExit(pid)			
		elseif tonumber(data) == 5 then		
			InputMessage(pid)				
		elseif tonumber(data) == 6 then				
			MainMenu.ShowServerGUI(pid)			
		end		
	elseif idGui == gui.listGUI then -- Liste				
		ShowMainGUI(pid)					
	elseif idGui == gui.listPlayerGUI then -- Liste	
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then    		
			ShowMainGUI(pid)			
		else   		
			ShowChoiceInvite(pid, tonumber(data)) 			
		end 
	elseif idGui == gui.listPlayerExitGUI then -- Liste	
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then   		
			ShowMainGUI(pid)			
		else   		
			ShowChoiceExit(pid, tonumber(data)) 			
		end 			
	elseif idGui == gui.MessageInput then -- Liste	
		if data and tonumber(data) and tonumber(data) <= 0 or tonumber(data) == 18446744073709551615 then    		
			ShowMainGUI(pid)			
		elseif data and tostring(data) then   		
			OnChoiceMessage(pid, tostring(data)) 			
			ShowMainGUI(pid)			
		else
			ShowMainGUI(pid)
		end
	elseif idGui == gui.MessageInvitation then 	
		if tonumber(data) == 0 then 
			local targetPid = Players[pid].data.targetPid
			tes3mp.SendMessage(targetPid, trd.Invitation3..GetName(pid).."\n", false)			
		end		
	elseif idGui == gui.MessageReponse then 	
		if tonumber(data) == 0 then 
			local targetPid = Players[pid].data.targetPid			
			RegisterGroup(targetPid, pid)			
		end
	end
end)

customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
	ExitGroup(pid)
	Players[pid].data.alliedPlayers = {}
end)

customCommandHooks.registerCommand("group", ShowMainGUI)
customCommandHooks.registerCommand("grou", ShowMainGUI)

TeamGroup = {}

TeamGroup.Bonus = function(pid)	
	local Count = 0	
	local CellPlayer = tes3mp.GetCell(pid)
	local playerName = GetName(pid)	
	local playerGroup = GetGroupData(pid)
	for memberName, bool in pairs(playerGroup) do
		if memberName and logicHandler.GetPlayerByName(memberName) then		
			local targetPid = logicHandler.GetPlayerByName(memberName).pid			
			if targetPid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then			
				local CellTarget = tes3mp.GetCell(targetPid)				
				if CellTarget and CellPlayer and CellPlayer == CellTarget then					
					Count = Count + 1					
				end				
			end			
		end		
	end		
	return Count	
end

TeamGroup.SendSoul = function(pid, totalGain, bonusGroup, creatureName)
	local CellPlayer = tes3mp.GetCell(pid)
	local playerName = GetName(pid)
	local playerGroup = GetGroupData(pid)	
	for memberName, bool in pairs(playerGroup) do		
		if memberName and logicHandler.GetPlayerByName(memberName) then		
			local targetPid = logicHandler.GetPlayerByName(memberName).pid			
			if targetPid and targetPid ~= pid and Players[targetPid] and Players[targetPid]:IsLoggedIn() then			
				local CellTarget = tes3mp.GetCell(targetPid)				
				if CellTarget and CellPlayer and CellPlayer == CellTarget then				
					local soulLoc = Players[targetPid].data.customVariables.playerLevel.soul					
					local levelSoul = Players[targetPid].data.customVariables.playerLevel.levelSoul						
					local capSoul = Players[targetPid].data.customVariables.playerLevel.capSoul				
					Players[targetPid].data.customVariables.playerLevel.soul = Players[targetPid].data.customVariables.playerLevel.soul + totalGain					
					local Message = (
						trd.Gain..totalGain..trd.Xp..
						"\n-- "..creatureName.." --\n"..
						trd.Bonus..bonusGroup.."\n"..
						"Total : "..Players[targetPid].data.customVariables.playerLevel.soul.." / "..Players[targetPid].data.customVariables.playerLevel.capSoul
					)				
					tes3mp.MessageBox(targetPid, -1, Message)					
					PlayerLevelScript.GetlevelSoul(targetPid)				
				end			
			end		
		end	
	end	
end

TeamGroup.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end
 
TeamGroup.InviteMessage = function(pid, targetPid)
	if Players[pid] and Players[pid]:IsLoggedIn() and Players[targetPid] and Players[targetPid]:IsLoggedIn() then
		Players[pid].data.targetPid = targetPid		
		Players[targetPid].data.targetPid = pid		
		local targetName = GetName(targetPid)		
		local message = trd.Invitation1..targetName..trd.Invitation2
		tes3mp.CustomMessageBox(pid, gui.MessageInvitation, message, trd.Choice)			
	end	
end
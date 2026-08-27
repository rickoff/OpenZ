--[[
MainMenu
tes3mp 0.8.1
------------
INSTALLATION :
Save MainMenu.lua to server/scripts/custom folder
Edits to customScripts.lua add in : require("custom.MainMenu")
]]

local cfg = {
	OnServerInit = false
}

local gui = {
	ServerGUI = 10022024,
	PlayerGUI = 11022024,
	ListGUI = 12022024
}

local trd = {	
	ServerTitle = "MAIN MENU\n\n",
	ServerDate = "Date\n",	
	ServerTime = "Time\n",
	ServerPlayer = "Player",
	ServerGroup = "Group",
	ServerQuit = "Close",
	ServerList = "List",
	ServerAnim = "Emote",
	ServerHelp = "Command",
	ServerRank = "Ranking",
	PlayerTitle = "PLAYER MENU\n\n",
	PlayerLevel = "Level : ",
	PlayerExperience = "Experience : ",
	PlayerExperienceRequired = " >= ",
	PlayerSkillPoints = "Skill Points : ",
	PlayerAttributes = "Attributes",
	PlayerSkills = "Skills",
	PlayerSuicide = "Suicide",
	PlayerHouse = "House",
	PlayerCraft = "Craft",
	PlayerEdit = "Edit",
	PlayerDelete = "Delete",
	PlayerReset = "Reset",
	PlayerReturn = "Return",
	PlayerClose = "Close"
}

local customItem = {
	mainmenu = {
		name = "Main menu",
		key = 9,
		icon = "misc\\tablet.dds"
	}
}

local function ShowServerGUI(pid)
    if PlayersDeath[GetName(pid)] then
        PlayerScript.ShowRessurectWaitGUI(pid)
        return
    end  
    local title = (
        color.Red..trd.ServerTitle..
		color.Orange..trd.ServerDate..
        color.White..os.date("%m-%d-%Y").."\n"..
		color.Orange..trd.ServerTime..
		color.White..os.date("%H:%M:%S").."\n"		
    )  
    local buttons = table.concat({
		trd.ServerList,
		trd.ServerRank,
        trd.ServerPlayer,
        trd.ServerGroup,
		trd.ServerAnim,	
		trd.ServerHelp,
        trd.ServerQuit
    }, ";")   
    tes3mp.CustomMessageBox(pid, gui.ServerGUI, title, buttons)
end

local function ShowPlayerGUI(pid)
    local customVariables = Players[pid].data.customVariables
	local clientVariables = Players[pid].data.clientVariables
    local title = (
        color.Red .. trd.PlayerTitle ..
        color.Orange .. trd.PlayerLevel .. color.White .. customVariables.playerLevel.levelSoul .. "\n" ..
        color.Orange .. trd.PlayerExperience .. color.White .. customVariables.playerLevel.soul ..
        color.Red .. trd.PlayerExperienceRequired .. color.White .. customVariables.playerLevel.capSoul .. "\n" ..
        color.Orange .. trd.PlayerSkillPoints .. color.White .. customVariables.playerLevel.pointSoul .. "\n"		
    )   
    local buttons = table.concat({
        trd.PlayerAttributes,
        trd.PlayerSkills,
		trd.PlayerHouse,
		trd.PlayerCraft,
		trd.PlayerEdit,
		trd.PlayerReset,
		trd.PlayerDelete,
        trd.PlayerReturn,
		trd.PlayerClose
    }, ";")
    tes3mp.CustomMessageBox(pid, gui.PlayerGUI, title, buttons)    
end

local function ShowPlayerList(pid)
    local playerCount = logicHandler.GetConnectedPlayerCount()
    local label = playerCount .. " connected player"
    if playerCount ~= 1 then
        label = label .. "s"
    end
    local lastPid = tes3mp.GetLastPlayerId()
    local list = ""
    local divider = ""
    for playerIndex = 0, lastPid do
        if playerIndex == lastPid then
            divider = ""
        else
            divider = "\n"
        end
        if Players[playerIndex] ~= nil and Players[playerIndex]:IsLoggedIn() then
            list = list .. tostring(Players[playerIndex].name) .. " (pid: " .. tostring(Players[playerIndex].pid) ..
                ", ping: " .. tostring(tes3mp.GetAvgPing(Players[playerIndex].pid)) .. ")" .. divider
        end
    end	
    tes3mp.ListBox(pid, gui.ListGUI, label, list)
end

customEventHooks.registerHandler("OnServerInit", function(eventStatus)
	if cfg.OnServerInit then
		local recordStoreBook = RecordStores["book"]
		for refId, data in pairs(customItem) do
			recordTable = {
			  name = data.name,
			  icon = data.icon,
			  model = "misc\\tablet.nif",		  
			  value = 0,
			  weight = 0
			}
			recordStoreBook.data.permanentRecords[refId] = recordTable
		end
		recordStoreBook:Save()
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)	
	for refId, data in pairs(customItem) do	
		if not tableHelper.containsValue(Players[pid].data.inventory, refId, true) then	
			AddObjectInventory(pid, refId, 1)		
		end		
	end
	Players[pid].data.quickKeys[9] = {
		keyType = 0,
		itemId = "mainmenu"
	}
	Players[pid]:LoadQuickKeys()
	if not Players[pid].data.clientVariables then
		Players[pid].data.clientVariables = {
			globals = {
				hunger = {
					variableType = 0,
					intValue = 0
				},
				tired = {
					variableType = 0,
					intValue = 0
				},
				thirsty = {
					variableType = 0,
					intValue = 0
				}				
			}
		}
	end	
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.ServerGUI then 
		if tonumber(data) == 0 then
			ShowPlayerList(pid)	
		elseif tonumber(data) == 1 then
			WorldRanked.ShowMainGui(pid)			
		elseif tonumber(data) == 2 then
			ShowPlayerGUI(pid)
		elseif tonumber(data) == 3 then
			TeamGroup.ShowMainGUI(pid)
		elseif tonumber(data) == 4 then
			AnimationMenu.ShowMainGUI(pid)
		elseif tonumber(data) == 5 then
			HelpCommand.ShowMainGUI(pid)
		end		
	elseif idGui == gui.PlayerGUI then
		if tonumber(data) == 0 then
			PlayerLevelScript.MenuComp(pid)
		elseif tonumber(data) == 1 then
			PlayerLevelScript.MenuSkill(pid)
		elseif tonumber(data) == 2 then
			InstancedHouse.WarpHouse(pid)
		elseif tonumber(data) == 3 then			
			CraftScript.ShowMainGUI(pid)
		elseif tonumber(data) == 4 then		
			PlayerEditScript.ShowMainGUI(pid)		
		elseif tonumber(data) == 5 then
			ResetQuest.ShowMainGUI(pid)		
		elseif tonumber(data) == 6 then
			DeletePlayer.ShowMainGUI(pid)			
		elseif tonumber(data) == 7 then
			ShowServerGUI(pid)
		end
	elseif idGui == gui.ListGUI then
		ShowServerGUI(pid)
	end
end)

customEventHooks.registerValidator("OnPlayerItemUse", function(eventStatus, pid, refId)
	if refId == "mainmenu" then	
		ShowServerGUI(pid)
		return customEventHooks.makeEventStatus(false,false)
	end
end)

customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
	if not string.find(cellDescription, "Apartment of ") then return end	
	for _, object in pairs(objects) do
		if object.activatingPid and object.uniqueIndex and object.refId then
			if object.refId == "act_office_pc_01" then		
				ShowServerGUI(pid)			
				return customEventHooks.makeEventStatus(false, false)
			end
		end
	end
end)

customCommandHooks.registerCommand("menu", ShowServerGUI)

MainMenu = {}

MainMenu.ShowServerGUI = function(pid)
	ShowServerGUI(pid)
end

MainMenu.ShowPlayerGUI = function(pid)
	ShowPlayerGUI(pid)
end
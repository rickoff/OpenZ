--[[
CraftScript
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as CraftScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.CraftScript")
---------------------------
]]

local gui = {
	mainMenu = 22012025,
	clothMenu = 23012025
}

local trd = {
	title = "QUICK CRAFT",
	option = "Bandage;Return;Close"
}

local playerInventoryOptions = {}

local function GetListInventoryCloth(pid)
	local options = {}	
	for _, item in pairs(Players[pid].data.inventory) do		
		if item.refId and item.refId ~= "" then	
			if string.find(string.lower(item.refId), "cloth_") and not tableHelper.containsValue(Players[pid].data.equipment, item.refId, true) then				
				table.insert(options, item)				
			end
		end
	end
 	table.sort(options, function(a,b) return a.refId<b.refId end)	
	return options	
end

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end	
	tes3mp.CustomMessageBox(pid, gui.mainMenu, color.Red..trd.title, trd.option)
end

local function ShowInventoryCloth(pid)
	local playerName = GetName(pid)	
	local options = GetListInventoryCloth(pid)	
	local list = "* Return *\n"	
	for i = 1, #options do		
		list = list..options[i].refId	
		if not(i == #options) then		
			list = list.."\n"			
		end		
	end
	playerInventoryOptions[playerName] = options	
	tes3mp.ListBox(pid, gui.clothMenu, color.CornflowerBlue.."Select an item : "..color.Default, list)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.mainMenu then
		if tonumber(data) == 0 then
			ShowInventoryCloth(pid)	
		elseif tonumber(data) == 1 then
			MainMenu.ShowPlayerGUI(pid)	
		end
	elseif idGui == gui.clothMenu then	
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then
			ShowMainGUI(pid)		
		else	
			if playerInventoryOptions[GetName(pid)] and playerInventoryOptions[GetName(pid)][tonumber(data)] then
				DeleteObjectInventory(pid, playerInventoryOptions[GetName(pid)][tonumber(data)].refId, 1)
				local randCount = math.random(1, 2)
				AddObjectInventory(pid, "med_bandage", randCount)
				tes3mp.MessageBox(pid, -1, "Bandage Crafted : "..randCount)
				PlaySound(pid, "Item Misc Up")
			end
			ShowInventoryCloth(pid)			
		end
	end
end)

customCommandHooks.registerCommand("craf", ShowMainGUI)
customCommandHooks.registerCommand("craft", ShowMainGUI)

CraftScript = {}

CraftScript.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end
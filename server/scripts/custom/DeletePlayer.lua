--[[
DeletePlayer
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as DeletePlayer.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.DeletePlayer")
---------------------------
]]

local cfg = {
	MainGUI = 45328901
}

local trd = {
	DeleteInfo = (
		color.Red.."CHARACTER DELETION\n\n"
		..color.White.."Deleting your character will remove:\n\n" 
		..color.Green.."- Your character file will be permanently deleted\n"
		..color.Green.."- Your instanced house file will be permanently deleted\n\n"		
		..color.White.."Are you sure you want to delete your character ?\n"    
	),
	DeleteChoice = "Yes;No"
}

local function Delete(pid)
	local playerName = GetName(pid)
	local recordStoreCell = RecordStores["cell"]
	local recordId = "Apartment of "..playerName
	recordStoreCell.data.permanentRecords[recordId] = nil
	tableHelper.cleanNils(recordStoreCell.data.permanentRecords)
	recordStoreCell:Save()
	tes3mp.Kick(pid)
	Players[pid] = nil
	local playerFile = (tes3mp.GetDataPath().."/player/"..playerName..".json")
	local houseFile = (tes3mp.GetDataPath().."/cell/".."Apartment of "..playerName..".json")	
	os.remove(playerFile)
	os.remove(houseFile)		
end

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	tes3mp.CustomMessageBox(pid, cfg.MainGUI, trd.DeleteInfo, trd.DeleteChoice)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == cfg.MainGUI then
		if tonumber(data) == 0 then
			Delete(pid)		
		else
			MainMenu.ShowPlayerGUI(pid)	
		end
	end
end)

customCommandHooks.registerCommand("delete", ShowMainGUI)
customCommandHooks.registerCommand("dele", ShowMainGUI)

DeletePlayer = {}

DeletePlayer.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end
--[[
ResetQuest
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as ResetQuest.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.ResetQuest")
---------------------------
]]
local cfg = {
	MainGUI = 12082022
}

local questItem = {
	badge_police_01 = true,
	badge_smith = true,
	key_bct_pipway = true,
	key_hosp_exit = true,
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
	key_club = true
}

local function Quest(pid, guild)
	local list = {}	
	for index, slot in pairs(Players[pid].data.journal) do	
		local quest = slot["quest"]
		local questsub = string.sub(quest, 1, 2)
		local lowerSub = string.lower(questsub)						
		if guild == "all" and lowerSub ~= nil and quest ~= "mq_intro" then
			Players[pid].data.journal[index] = nil
		end
	end		
	for refId, bool in pairs(questItem) do
		DeleteObjectInventory(pid, refId, 1)
	end	
	tableHelper.cleanNils(Players[pid].data.journal)
	Players[pid]:LoadJournal()	
	Players[pid].data.customVariables.respawnPos = {
		cellDescription = "Hospital Room 31",		
		posX = 4152,
		posY = 4285,	
		posZ = 12173,				
		rotX = 0.4,	
		rotY = 0,
		rotZ = 1.7
	}
	Players[pid].data.location = {
		cell = "Hospital Room 31",		
		posX = 4152,
		posY = 4285,	
		posZ = 12173,				
		rotX = 0.4,	
		rotY = 0,
		rotZ = 1.7,
		regionName = ""		
	}
	Players[pid]:SaveToDrive()	
	tes3mp.Kick(pid)
	Players[pid] = nil
end

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	local message = (
		color.Red .. "RESET MENU\n"..
		color.White.."Resetting the journal will log you out of the server, please log back in."
	)	
	local choice = "Journal;Return"	
	tes3mp.CustomMessageBox(pid, cfg.MainGUI, message, choice)
end

ResetQuest = {}

ResetQuest.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)	
	if idGui == cfg.MainGUI then
		if tonumber(data) == 0 then
			Quest(pid, "all")
		elseif tonumber(data) == 1 then
			MainMenu.ShowPlayerGUI(pid)	
		end
	end
end)

customCommandHooks.registerCommand("reset", ShowMainGui)
customCommandHooks.registerCommand("rese", ShowMainGui)
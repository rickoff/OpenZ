--[[
TutorialScript
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as TutorialScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua add in : require("custom.TutorialScript")
---------------------------
]]
local trd = {
	"Red inhaler automatically added to your shortcut 1. Press the 1 key to use a red spray and quickly recover health. Note: To change a shortcut, right-click the inventory and click the number in the shortcut bar to assign it a new item or ability.",
	"Green inhaler automatically added to your shortcut 2. Press the 2 key to use a green spray and quickly recover from fatigue. Note: To change a shortcut, right-click in your inventory and click the number in the hotbar to assign it a new item or ability.",
	"Blue inhaler automatically added to your hotkey 3. Press the 3 key to use a green spray and quickly recover ability points. Note: To change a shortcut, right-click in your inventory and click the number in the hotbar to assign it a new item or ability.",
	"Antibiotic automatically added to your shortcut 4. Press the 4 key to use a box of antibiotics and quickly cure an infection. Note: To change a shortcut, right-click in your inventory and click the number in the shortcut bar to assign it a new item or ability.",
	"Bandage automatically added to your hotkey 5. Press the 5 key to use a bandage and quickly heal from bleeding. Note: To change a hotkey, right-click in your inventory and click the number in the hotbar to assign it a new item or ability.",
	"The kitchen knife has been automatically added to your shortcut number 6, to equip the knife press the 6 key, to take out the weapons press the F key and to attack use the left mouse button.",
	"The pistol has been automatically added to your shortcut number 7, to equip the pistol press the 7 key, to take out the weapons press the F key and to attack use the left mouse button.",
	"To open the journal, press the J key.",
	"The flashlight has been equipped automatically, to modify an equipment open your inventory using the right click of your mouse and drag the objects onto your character.",
	"Sleeping allows you to recover from fatigue and save your last waypoint.",
	"Use ZQSD to move, E to activate, Space to jump."
}

local function TutorialMessage(pid, number)
	local choice = "Ok"
	local gui = 27102025
	tes3mp.CustomMessageBox(pid, gui, color.Red.."TUTO\n\n"..color.White..trd[number], choice)
end

local item = {
	med_inhaler_h = {
		Message = 1,
		KeysSlot = 1
	},
	med_inhaler_f = {
		Message = 2,
		KeysSlot = 2
	},	
	med_inhaler_a = {
		Message = 3,
		KeysSlot = 3
	},
	med_pills_disease = {
		Message = 4,
		KeysSlot = 4
	},	
	med_bandage = {
		Message = 5,
		KeysSlot = 5
	},
	weap_shortblade_knifekitchen_01 = {
		Message = 6,
		KeysSlot = 6,
		Equip = 16			
	},
	weap_gun_m92fs_01 = {
		Message = 7,
		KeysSlot = 7,
		Equip = 16		
	},	
	book_tablet_01 = {
		Message = 8,
		KeysSlot = false
	},	
	ligh_flashlight_01 = {
		Message = 9,
		KeysSlot = false,
		Equip = 17
	},
	act_hosp_bed_room = {
		Message = 10,
		KeysSlot = false
	}	
}

customEventHooks.registerHandler("OnPlayerInventory", function(eventStatus, pid, playerPacket)
	local cellDescription = tes3mp.GetCell(pid)
	if string.find(string.lower(cellDescription), "hospital room 00") then
		if playerPacket.action == enumerations.inventory.ADD then
			for _, object in pairs(playerPacket.inventory) do
				if item[object.refId] then
					if item[object.refId].KeysSlot then
						Players[pid].data.quickKeys[tonumber(item[object.refId].KeysSlot)] = {
							keyType = 0,
							itemId = object.refId
						}
						Players[pid]:LoadQuickKeys()
					end	
					if item[object.refId].Equip then	
						tes3mp.EquipItem(pid, item[object.refId].Equip, object.refId, object.count, -1, -1)
						tes3mp.SendEquipment(pid)		
					end
				end
			end
		end
	end
end)

customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects)
	if string.find(string.lower(cellDescription), "hospital room 00") then
		for _, object in pairs(objects) do		
			if object.activatingPid and object.refId then
				if item[object.refId] then
					TutorialMessage(object.activatingPid, tonumber(item[object.refId].Message))					
				end
			end
		end
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid].isNewlyRegistered == true then	
		TutorialMessage(pid, 11)
	end		
end)
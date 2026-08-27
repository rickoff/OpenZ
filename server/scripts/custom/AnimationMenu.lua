--[[
AnimationMenu
Made by Kyoufu, edited by Vidi_Aquam, based on JRPAnim by malic, rewritten by Rickoff
tes3mp 0.8.1
---------------------------
DESCRIPTION :
AnimationMenu script
/anim to open the animation menu
---------------------------
INSTALLATION:
Save the file as AnimationMenu.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.AnimationMenu")

REQUIREMENT:
Download and save files va_sitting.nif, xva_sitting.nif, and xva_sitting.kf inside morrowind/data/meshs
https://www.nexusmods.com/morrowind/mods/48782?tab=files 
---------------------------
]]
local PlayerAnimationList = {}

local cfg = {
	OnServerPostInit = false
}

local gui = {
	animMenu = 42110
}

local trd = {
	title = "EMOTE MENU",
	option = [[Pray;Lying Down (on back);Lying Down (right side);Lying Down (left side);Sitting (legs to the side);Sitting (legs crossed);Sitting (legs forward);Sitting (on a chair);Dance;Raise Arms;Boo;Applaud;Guard Pose 01;Guard Pose 02;Guard Pose 03;Cancel (animation);Return;Close]]	
}

local Mount = {
	mounthorse = "horse",
	mountcar = "car",
	mountairplane = "plane"
}

local function CheckRace(pid)
	local mountRace
	local finalRace
	if Players[pid].data.clientVariables.globals then
		if Players[pid].data.clientVariables.globals.mountairplane
		and Players[pid].data.clientVariables.globals.mountairplane.intValue == 1 then
			mountRace = "mountairplane"
		elseif Players[pid].data.clientVariables.globals.mountcar
		and Players[pid].data.clientVariables.globals.mountcar.intValue == 1 then
			mountRace = "mountcar"		
		elseif Players[pid].data.clientVariables.globals.mounthorse
		and Players[pid].data.clientVariables.globals.mounthorse.intValue == 1 then	
			mountRace = "mounthorse"	
		end
		if mountRace then
			if Players[pid].data.character.race ~= Mount[mountRace] then
				finalRace = Mount[mountRace]
			end
		else
			if Players[pid].data.customVariables.baseRace 
			and Players[pid].data.customVariables.baseRace ~= Players[pid].data.character.race then
				finalRace = Players[pid].data.customVariables.baseRace
			end
		end
		if finalRace then
			tes3mp.SetRace(pid, finalRace)
			tes3mp.SendBaseInfo(pid)
		end
	end
end	

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end	
	UnequipItem(pid, enumerations.equipment.CARRIED_RIGHT)
	local message = color.Red.. trd.title	
	local optionList = trd.option
	tes3mp.CustomMessageBox(pid, gui.animMenu, message, optionList)
end

local function SendAnimation(pid, model, animation, data, flag, forEveryone)
	if pid and Players[pid] and Players[pid]:IsLoggedIn() then	
		if model and animation and data and flag and forEveryone then
			tes3mp.SetModel(pid, model)
			tes3mp.SendBaseInfo(pid)		
			tes3mp.PlayAnimation(pid, animation, data, flag, forEveryone)	
		end
	end
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	if cfg.OnServerPostInit then
		local recordStore = RecordStores["spell"]
		recordStore.data.permanentRecords["sittingAnim_paralyze"] = {
			name = "Animation",
			subtype = 1,
			cost = 0,
			flags = 0,
			effects = {{
				id = 45,
				attribute = -1,
				skill = -1,
				rangeType = 0,
				duration = -1,
				area = 0,
				magnitudeMin = 1,
				magnitudeMax = 1
			}}
		}
		recordStore:Save()
	end
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.animMenu then	
		local PlayerName = GetName(pid)		
		local PlayerRace = Players[pid].data.character.race		
		local PlayerGender = Players[pid].data.character.gender		
		local cellDescription = tes3mp.GetCell(pid)		
		local Model = "base_anim.nif"		
		if PlayerGender == 0 then		
			Model = "base_anim_female.nif"				
		end	
		local Animation = "idle"		
		if tonumber(data) >= 0 and tonumber(data) < 9 then		
			AddSpell(pid, {"sittingAnim_paralyze"})			
			Model = "sitting.nif"
			logicHandler.RunConsoleCommandOnPlayer(pid, "PCForce3rdPerson", false)
			logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerViewSwitch", false)			
		elseif tonumber(data) >= 9 and tonumber(data) < 12 then		
			AddSpell(pid, {"sittingAnim_paralyze"})			
			Model = "spectator.nif"
			logicHandler.RunConsoleCommandOnPlayer(pid, "PCForce3rdPerson", false)
			logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerViewSwitch", false)			
		elseif tonumber(data) >= 12 and tonumber(data) < 15 then		
			AddSpell(pid, {"sittingAnim_paralyze"})			
			Model = "guard.nif"
			logicHandler.RunConsoleCommandOnPlayer(pid, "PCForce3rdPerson", false)
			logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerViewSwitch", false)			
		end	
		if tonumber(data) == 0 then
			Animation = "idle2"			
		elseif tonumber(data) == 1 then
			Animation = "idle9"			
		elseif tonumber(data) == 2 then
			Animation = "idle7"			
		elseif tonumber(data) == 3 then
			Animation = "idle8"								
		elseif tonumber(data) == 4 then
			Animation = "idle3"					
		elseif tonumber(data) == 5 then
			Animation = "idle4"	
		elseif tonumber(data) == 6 then
			Animation = "idle5"					
		elseif tonumber(data) == 7 then
			Animation = "idle6"			
		elseif tonumber(data) == 8 then			
			Model = "dancing.nif"
			Animation = "idle2"	
		elseif tonumber(data) == 9 then	
			Animation = "idle2"
		elseif tonumber(data) == 10 then	
			Animation = "idle3"
		elseif tonumber(data) == 11 then
			Animation = "idle4"	
		elseif tonumber(data) == 12 then	
			Animation = "idle2"
		elseif tonumber(data) == 13 then	
			Animation = "idle3"
		elseif tonumber(data) == 14 then
			Animation = "idle4"					
		elseif tonumber(data) == 15 then
			RemoveSpell(pid, {"sittingAnim_paralyze"})				
			logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerViewSwitch", false)		
		elseif tonumber(data) == 16 then
			MainMenu.ShowServerGUI(pid)
		elseif tonumber(data) == 17 then
		
		end
		if tonumber(data) >= 0 and tonumber(data) < 16 then	
			SendAnimation(pid, Model, Animation, 0, 1, true)
			ShowMainGUI(pid)
			if tonumber(data) < 15 then
				PlayerAnimationList[PlayerName] = {
					animation = Animation,
					model = Model,
					cellDescription = cellDescription
				}
			else
				PlayerAnimationList[PlayerName] = nil
			end
		end		
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	local PlayerName = GetName(pid)
	local PlayerRace = Players[pid].data.character.race	
	local PlayerGender = Players[pid].data.character.gender	
	local Model = "base_anim.nif"	
	if PlayerGender == 0 then	
		Model = "base_anim_female.nif"			
	end	
	SendAnimation(pid, Model, "idle", 0, 1, false)
	RemoveSpell(pid, {"sittingAnim_paralyze"})	
	CheckRace(pid)
end)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	local PlayerName = GetName(pid)	
	for targetName, data in pairs(PlayerAnimationList) do	
		if targetName ~= PlayerName and playerPacket.location.cell == data.cellDescription and logicHandler.GetPlayerByName(targetName) then		
			local targetPid = logicHandler.GetPlayerByName(targetName).pid			
			SendAnimation(targetPid, data.model, data.animation, 0, 1, true)		
		end		
	end
end)

customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
	local PlayerName = GetName(pid)	
	if PlayerAnimationList[PlayerName] then	
		PlayerAnimationList[PlayerName] = nil		
	end
end)

customEventHooks.registerValidator("OnObjectHit", function(eventStatus, pid, cellDescription, objects, targetPlayers)
	for targetPid, targetPlayer in pairs(targetPlayers) do
		local targetPlayerName = GetName(targetPid)	
		if PlayerAnimationList[targetPlayerName] then
			local Model = "base_anim.nif"		
			if Players[targetPid].data.character.gender == 0 then		
				Model = "base_anim_female.nif"				
			end		
			local Animation = "idle"
			SendAnimation(targetPid, Model, Animation, 0, 1, false)		
			RemoveSpell(targetPid, {"sittingAnim_paralyze"})				
			logicHandler.RunConsoleCommandOnPlayer(targetPid, "EnablePlayerViewSwitch", false)	
			PlayerAnimationList[targetPlayerName] = nil		
		end
	end	
end)

customEventHooks.registerValidator("OnPlayerItemUse", function(eventStatus, pid, refId)
	if refId == "dop_cigarette_01" then	
		if tes3mp.GetDrawState(pid) ~= 1 then
			tes3mp.MessageBox(pid, -1, "Need weapon drawn.")		
			return customEventHooks.makeEventStatus(false,false)
		end	
		if Players[pid].data.equipment[enumerations.equipment.CARRIED_LEFT] and Players[pid].data.equipment[enumerations.equipment.CARRIED_LEFT].refId
		and Players[pid].data.equipment[enumerations.equipment.CARRIED_LEFT].refId == "ligh_zippo_01" then
			SendAnimation(pid, "smoking.nif", "idle2", 2, 1, true)	
		else
			tes3mp.MessageBox(pid, -1, "Need a lighter equipped.")
			return customEventHooks.makeEventStatus(false,false)
		end
	end	
end)

customEventHooks.registerValidator("OnClientScriptGlobal", function(eventStatus, pid, variables)
	for id, variable in pairs(variables) do
		if id and Mount[id] then
			if not Players[pid].data.customVariables.baseRace then
				Players[pid].data.customVariables.baseRace = Players[pid].data.character.race
			end
			if variable.intValue == 1 then
				tes3mp.SetRace(pid, Mount[id])
			else
				tes3mp.SetRace(pid, Players[pid].data.customVariables.baseRace)			
			end
			tes3mp.SendBaseInfo(pid)
			Players[pid].data.character.race = Mount[id]
		end
	end
	
end)

customCommandHooks.registerCommand("emote", ShowMainGUI)
customCommandHooks.registerCommand("emot", ShowMainGUI)

AnimationMenu = {}

AnimationMenu.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end
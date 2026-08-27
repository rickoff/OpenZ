--[[
PlayerLevelScript
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as PlayerLevelScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.PlayerLevelScript")
---------------------------
FUNCTION:
/level in your chat for open menu
---------------------------
]]
local PlayerOptionPoint = {}

local cfg = {
	levelMax = 10,
	LevelHealth = 5,
	talentProgress = 10,
	RewardPoints = 10,
	capSoul = 2500,
	CreaSoul = 100,
	SkillSoul = 25
}

local gui = {
	CompInputGUI = 555555,
	CompAddGUI = 555556,
	CompRemoveGUI = 555557,
	SkillAddOneGUI = 555558,
	SkillAddTwoGUI = 555559,
	SkillRemoveOneGUI = 555560,
	SkillRemoveTwoGUI = 555561
}

local trd = {
	Gain = "You have gained : ",
	Feli = "You have leveled up, congratulations.",
	NotPts = "You do not have enough skill points to decrease",
	NoPt = "You do not have enough skill points, current : ",
	Req = " required : ",
	WereWolf = "The skill menu is prohibited in werewolf form",
	Xp = " xp.",
	Bonus = "Group bonus : ",
	CapSkill = "Your talent fortification has exceeded the maximum allowed value : ",
	CapAttribute = "Your attribute fortification has exceeded the maximum allowed value : ",
	NoNegative = "It is not possible to enter a negative value : -",
	NegativeComp = "Cannot remove your points below 0",
	NumberInput = "Enter the number of points",
	AddPoint = "add points",
	RemovePoint = "remove points"
}

local function AddCustom(pid)
	Players[pid].data.customVariables.playerLevel = {}
	Players[pid].data.customVariables.playerLevel.pointSoul = 0
	Players[pid].data.customVariables.playerLevel.soul = 0
	Players[pid].data.customVariables.playerLevel.capSoul = cfg.capSoul
	Players[pid].data.customVariables.playerLevel.levelSoul = 1	
	for attribute, slot in pairs(Players[pid].data.attributes) do
		Players[pid].data.customVariables.playerLevel[attribute] = 0
	end	
	for skill, slot in pairs(Players[pid].data.skills) do
		Players[pid].data.customVariables.playerLevel[skill] = 0
	end	
end

local function GetlevelSoul(pid)
	local GainHealth = cfg.LevelHealth	
	local GainPoint = cfg.RewardPoints	
	local CapSoul = cfg.capSoul	
	if Players[pid].data.stats.level == cfg.levelMax then	
		Players[pid].data.customVariables.playerLevel.soul = 0	
		return		
	elseif Players[pid].data.stats.level >= 50 then
		GainHealth = GainHealth / 2
		GainPoint = GainPoint / 2
		CapSoul = CapSoul * 2
	end
	local soulLoc = Players[pid].data.customVariables.playerLevel.soul
	local capSoul = Players[pid].data.customVariables.playerLevel.capSoul
	local levelSoul = Players[pid].data.customVariables.playerLevel.levelSoul	
	local pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul		
	if soulLoc >= capSoul and Players[pid].data.stats.level < cfg.levelMax then	
		Players[pid].data.stats.level = Players[pid].data.stats.level + 1		
		local HealthBase = Players[pid].data.stats.healthBase		
		tes3mp.SetHealthBase(pid, (HealthBase + GainHealth))		
		Players[pid]:LoadLevel()		
		Players[pid]:SaveStatsDynamic(packetReader.GetPlayerPacketTables(pid, "PlayerStatsDynamic"))		
		tes3mp.SendStatsDynamic(pid)			
		Players[pid].data.customVariables.playerLevel.levelSoul = levelSoul + 1		
		Players[pid].data.customVariables.playerLevel.soul = 0		
		Players[pid].data.customVariables.playerLevel.capSoul = math.floor(((levelSoul + 1) * 2) * CapSoul)		
		Players[pid].data.customVariables.playerLevel.pointSoul = pointSoul + GainPoint		
		tes3mp.MessageBox(pid, -1, trd.Feli)		
	end	
end

local function GiveXpForPlayer(pid, uniqueIndex, Type, journalIndex, cellDescription)
	local Count = 0
	local creatureSoul = cfg.CreaSoul
	if Type == "Actor" then
		if LoadedCells[cellDescription] 
		and LoadedCells[cellDescription].data.objectData[uniqueIndex]
		and LoadedCells[cellDescription].data.objectData[uniqueIndex].stats
		and LoadedCells[cellDescription].data.objectData[uniqueIndex].stats.healthBase then
			creatureSoul = LoadedCells[cellDescription].data.objectData[uniqueIndex].stats.healthBase
		else
			local actorStats = GetActorStats(cellDescription, uniqueIndex)
			if actorStats then
				creatureSoul = actorStats.healthBase
			end
		end
		if creatureSoul == 0 then creatureSoul = cfg.CreaSoul end
	elseif Type == "Journal" then
		creatureSoul = journalIndex * 10		
	end	
	if TeamGroup and Type ~= "Journal" then
		Count = TeamGroup.Bonus(pid)
	end	
	local bonusGroup = ( creatureSoul * (Count / 10) )	
	local totalGain = creatureSoul + bonusGroup
	if TeamGroup and Count > 1 and Type ~= "Journal" then
		TeamGroup.SendSoul(pid, totalGain, bonusGroup, Type)
	end	
	Players[pid].data.customVariables.playerLevel.soul = Players[pid].data.customVariables.playerLevel.soul + totalGain	
	if Count > 1 then	
		local Message = (trd.Gain..totalGain..trd.Xp.."\n"..trd.Bonus..bonusGroup.."\nTotal : "..
			Players[pid].data.customVariables.playerLevel.soul.." / "..Players[pid].data.customVariables.playerLevel.capSoul
		)	
		tes3mp.MessageBox(pid, -1, Message)		
	else	
		local Message = (trd.Gain..totalGain..trd.Xp.."\nTotal : "..
			Players[pid].data.customVariables.playerLevel.soul.." / "..Players[pid].data.customVariables.playerLevel.capSoul
		)							
		tes3mp.MessageBox(pid, -1, Message)					
	end				
	GetlevelSoul(pid)	
end

local function InputDialog(pid, comp, state)
	local nameP = GetName(pid)
	PlayerOptionPoint[nameP] = {comp = comp, state = state}
	if state == "Add" then
		return tes3mp.InputDialog(pid, gui.CompInputGUI, trd.NumberInput, trd.AddPoint)
	elseif state == "Remove" then
		return tes3mp.InputDialog(pid, gui.CompInputGUI, trd.NumberInput, trd.RemovePoint)
	end	
end

local function OnPlayerCompetence(pid, Comp, State, Count)	
	local PointCount = Players[pid].data.customVariables.playerLevel.pointSoul	
	local Count = Count or 0
	Count = math.ceil(Count)
	local Type = "Nothing"	
	if Comp then		
		if Players[pid].data.skills[Comp] then
			Type = "skill"
		elseif Players[pid].data.attributes[Comp] then
			Type = "attribute"
		end	
		if Count < 0 then
			tes3mp.MessageBox(pid, -1, trd.NoNegative..PointCount)
			return
		end
		if PointCount >= Count and State == "Add" then			
			if Type == "skill" then			
				local skillId = tes3mp.GetSkillId(Comp)
				local skillBase = Players[pid].data.skills[Comp].base
				local valueC = skillBase + Count
				local maxSkillValue = config.maxSkillValue
				if Comp == "Acrobatics" then
					maxSkillValue = config.maxAcrobaticsValue
				end
				if valueC <= maxSkillValue then
					tes3mp.SetSkillBase(pid, skillId, valueC)
					Players[pid].data.customVariables.playerLevel.pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul - Count	
					Players[pid].data.customVariables.playerLevel[Comp] = Players[pid].data.customVariables.playerLevel[Comp] + Count
				else
					tes3mp.MessageBox(pid, -1, trd.CapSkill..maxSkillValue)
				end
			else
				local attrId = tes3mp.GetAttributeId(Comp)
				local attrBase = Players[pid].data.attributes[Comp].base
				local valueS = attrBase + Count	
				if valueS <= config.maxAttributeValue then					
					tes3mp.SetAttributeBase(pid, attrId, valueS)
					Players[pid].data.customVariables.playerLevel.pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul - Count
					Players[pid].data.customVariables.playerLevel[Comp] = Players[pid].data.customVariables.playerLevel[Comp] + Count		
				else
					tes3mp.MessageBox(pid, -1, trd.CapAttribute..config.maxAttributeValue)
				end
			end
		elseif PointCount < Count and State == "Add" then
			tes3mp.MessageBox(pid, -1, trd.NoPt..PointCount)
		end			
		if Players[pid].data.customVariables.playerLevel[Comp] >= Count and State == "Remove" then			
			if Type == "skill" then				
				local skillId = tes3mp.GetSkillId(Comp)
				local skillBase = Players[pid].data.skills[Comp].base
				local valueC = skillBase - Count
				if valueC >= 0 then
					tes3mp.SetSkillBase(pid, skillId, valueC)
					Players[pid].data.customVariables.playerLevel.pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul + Count	
					Players[pid].data.customVariables.playerLevel[Comp] = Players[pid].data.customVariables.playerLevel[Comp] - Count
				else
					tes3mp.MessageBox(pid, -1, trd.NegativeComp)			
				end
			else
				local attrId = tes3mp.GetAttributeId(Comp)
				local attrBase = Players[pid].data.attributes[Comp].base
				local valueS = attrBase - Count	
				if valueS >= 0 then
					tes3mp.SetAttributeBase(pid, attrId, valueS)
					Players[pid].data.customVariables.playerLevel.pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul + Count
					Players[pid].data.customVariables.playerLevel[Comp] = Players[pid].data.customVariables.playerLevel[Comp] - Count
				else
					tes3mp.MessageBox(pid, -1, trd.NegativeComp)				
				end					
			end			
		elseif Players[pid].data.customVariables.playerLevel[Comp] < Count and State == "Remove" then
			tes3mp.MessageBox(pid, -1, trd.NotPts)
		end
		if Type == "attribute" then
			local playerPacket = packetReader.GetPlayerPacketTables(pid, "PlayerAttribute")
			Players[pid]:SaveAttributes(playerPacket)	
			tes3mp.SendAttributes(pid)	
		elseif Type == "skill" then
			local playerPacket = packetReader.GetPlayerPacketTables(pid, "PlayerSkill")
			Players[pid]:SaveSkills(playerPacket)			
			tes3mp.SendSkills(pid)
		end
	end
end	

local function MenuCompAdd(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel
		local Message = (
			color.Red.."ADD ATTRIBUTE\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select an attribute from the list\n\n"..
			color.Orange.."add attribute :"..color.Green.." + 1"..color.White.." point.\n\n"..
			color.Orange .. "Cost : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Strength : "..customVariables.Strength..
			";Endurance : "..customVariables.Endurance..
			";Speed : "..customVariables.Speed..
			";Agility : "..customVariables.Agility..
			";Intelligence : "..customVariables.Intelligence..
			";Willpower : "..customVariables.Willpower..
			";Luck : "..customVariables.Luck..
			";Personality : "..customVariables.Personality..
			";Remove"..
			";Return"
		)
		tes3mp.CustomMessageBox(pid, gui.CompAddGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end

local function MenuCompRemove(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel	
		local Message = (
			color.Red.."REMOVE ATTRIBUTE\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select an attribute from the list\n\n"..
			color.Orange.."remove attribute :"..color.Green.." - 1"..color.White.." point.\n\n"..
			color.Orange .. "Gain : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Strength : "..customVariables.Strength..
			";Endurance : "..customVariables.Endurance..
			";Speed : "..customVariables.Speed..
			";Agility : "..customVariables.Agility..
			";Intelligence : "..customVariables.Intelligence..
			";Willpower : "..customVariables.Willpower..
			";Luck : "..customVariables.Luck..
			";Personality : "..customVariables.Personality..
			";Add"..
			";Return"
		)		
		tes3mp.CustomMessageBox(pid, gui.CompRemoveGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end
	
local function MenuSkillOneAdd(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel	
		local Message = (
			color.Red.."ADD SKILL page 1\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select a skill from the list\n\n"..
			color.Orange.."add skill :"..color.Green.." + 1"..color.White.." point.\n\n"..
			color.Orange .. "Cost : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Hand-to-Hand : "..customVariables.Handtohand..
			";Short Blade : "..customVariables.Shortblade..
			";Long Blade : "..customVariables.Longblade..
			";Axe : "..customVariables.Axe..
			";Blunt Weapon : "..customVariables.Bluntweapon..
			";Spear : "..customVariables.Spear..
			";Security : "..customVariables.Security..
			";Athletics : "..customVariables.Athletics..
			";Marksman : "..customVariables.Marksman..
			";Acrobatics : "..customVariables.Acrobatics..	
			";Sneak : "..customVariables.Sneak..	
			";Mercantile : "..customVariables.Mercantile..
			";Unarmored : "..customVariables.Unarmored..			
			";Remove"..
			";Page 2"..
			";Return"
		)
		tes3mp.CustomMessageBox(pid, gui.SkillAddOneGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end

local function MenuSkillTwoAdd(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel	
		local Message = (
			color.Red.."ADD SKILL page 2\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select a skill from the list\n\n"..
			color.Orange.."add skill :"..color.Green.." + 1"..color.White.." point.\n\n"..
			color.Orange .. "Cost : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Light Armor : "..customVariables.Lightarmor..
			";Medium Armor : "..customVariables.Mediumarmor..
			";Heavy Armor : "..customVariables.Heavyarmor..
			";Block : "..customVariables.Block..
			";Armorer : "..customVariables.Armorer..
			";Speechcraft : "..customVariables.Speechcraft..
			";Enchant : "..customVariables.Enchant..
			";Destruction : "..customVariables.Destruction..
			";Conjuration : "..customVariables.Conjuration..
			";Illusion : "..customVariables.Illusion..	
			";Alteration : "..customVariables.Alteration..	
			";Mysticism : "..customVariables.Mysticism..
			";Restoration : "..customVariables.Restoration..
			";Alchemy : "..customVariables.Alchemy..			
			";Remove"..
			";Page 1"..
			";Return"
		)
		tes3mp.CustomMessageBox(pid, gui.SkillAddTwoGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end

local function MenuSkillOneRemove(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel	
		local Message = (
			color.Red.."REMOVE SKILL page 1\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select a skill from the list\n\n"..
			color.Orange.."remove skill :"..color.Green.." - 1"..color.White.." point.\n\n"..
			color.Orange .. "Gain : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Hand-to-Hand : "..customVariables.Handtohand..
			";Short Blade : "..customVariables.Shortblade..
			";Long Blade : "..customVariables.Longblade..
			";Axe : "..customVariables.Axe..
			";Blunt Weapon : "..customVariables.Bluntweapon..
			";Spear : "..customVariables.Spear..
			";Security : "..customVariables.Security..
			";Athletics : "..customVariables.Athletics..
			";Marksman : "..customVariables.Marksman..
			";Acrobatics : "..customVariables.Acrobatics..	
			";Sneak : "..customVariables.Sneak..	
			";Mercantile : "..customVariables.Mercantile..
			";Unarmored : "..customVariables.Unarmored..			
			";Add"..
			";Page 2"..
			";Return"
		)
		tes3mp.CustomMessageBox(pid, gui.SkillRemoveOneGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end

local function MenuSkillTwoRemove(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	if not tes3mp.IsWerewolf(pid) then
		local customVariables = Players[pid].data.customVariables.playerLevel	
		local Message = (
			color.Red.."REMOVE SKILL page 2\n\n"..
			color.Orange.."skill points : "..color.White..customVariables.pointSoul.."\n\n"..
			color.White.."Select a skill from the list\n\n"..
			color.Orange.."remove skill :"..color.Green.." - 1"..color.White.." point.\n\n"..
			color.Orange .. "Gain : "..color.White .. "1 skill point."
		)
		local Buttons = (
			"Light Armor : "..customVariables.Lightarmor..
			";Medium Armor : "..customVariables.Mediumarmor..
			";Heavy Armor : "..customVariables.Heavyarmor..
			";Block : "..customVariables.Block..
			";Armorer : "..customVariables.Armorer..
			";Speechcraft : "..customVariables.Speechcraft..
			";Enchant : "..customVariables.Enchant..
			";Destruction : "..customVariables.Destruction..
			";Conjuration : "..customVariables.Conjuration..
			";Illusion : "..customVariables.Illusion..	
			";Alteration : "..customVariables.Alteration..	
			";Mysticism : "..customVariables.Mysticism..
			";Restoration : "..customVariables.Restoration..
			";Alchemy : "..customVariables.Alchemy..			
			";Add"..
			";Page 1"..
			";Return"
		)
		tes3mp.CustomMessageBox(pid, gui.SkillRemoveTwoGUI, Message, Buttons)
	else
		tes3mp.MessageBox(pid, -1, trd.WereWolf)
	end
end
	
local function GetlevelSoul(pid)
	local GainHealth = cfg.LevelHealth	
	local GainPoint = cfg.RewardPoints	
	local CapSoul = cfg.capSoul	
	if Players[pid].data.stats.level == cfg.levelMax then	
		Players[pid].data.customVariables.playerLevel.soul = 0	
		return		
	elseif Players[pid].data.stats.level >= 50 then
		GainHealth = GainHealth / 2
		GainPoint = GainPoint / 2
		CapSoul = CapSoul * 2
	end
	local soulLoc = Players[pid].data.customVariables.playerLevel.soul
	local capSoul = Players[pid].data.customVariables.playerLevel.capSoul
	local levelSoul = Players[pid].data.customVariables.playerLevel.levelSoul	
	local pointSoul = Players[pid].data.customVariables.playerLevel.pointSoul		
	if soulLoc >= capSoul and Players[pid].data.stats.level < cfg.levelMax then	
		Players[pid].data.stats.level = Players[pid].data.stats.level + 1		
		local HealthBase = Players[pid].data.stats.healthBase		
		tes3mp.SetHealthBase(pid, (HealthBase + GainHealth))		
		Players[pid]:LoadLevel()		
		Players[pid]:SaveStatsDynamic(packetReader.GetPlayerPacketTables(pid, "PlayerStatsDynamic"))		
		tes3mp.SendStatsDynamic(pid)			
		Players[pid].data.customVariables.playerLevel.levelSoul = levelSoul + 1		
		Players[pid].data.customVariables.playerLevel.soul = 0		
		Players[pid].data.customVariables.playerLevel.capSoul = math.floor(((levelSoul + 1) * 2) * CapSoul)		
		Players[pid].data.customVariables.playerLevel.pointSoul = pointSoul + GainPoint		
		tes3mp.MessageBox(pid, -1, trd.Feli)		
	end	
end

local function PlayerLevel(pid)
	if Players[pid].data.customVariables.playerLevel then	
		Players[pid].data.customVariables.playerLevel.soul = Players[pid].data.customVariables.playerLevel.soul + cfg.SkillSoul			
		local Message = (trd.Gain..cfg.SkillSoul..trd.Xp.."\nTotal : "..
			Players[pid].data.customVariables.playerLevel.soul.." / "..Players[pid].data.customVariables.playerLevel.capSoul
		)					
		tes3mp.MessageBox(pid, -1, Message)			
		Players[pid].data.stats.levelProgress = 0		
		Players[pid]:LoadLevel()		
		GetlevelSoul(pid)		
	end	
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.CompInputGUI then
		local nameP = GetName(pid)		
		OnPlayerCompetence(pid, PlayerOptionPoint[nameP].comp, PlayerOptionPoint[nameP].state, tonumber(data))		
		if Players[pid].data.skills[PlayerOptionPoint[nameP].comp] and PlayerOptionPoint[nameP].state == "Add" then
			MenuSkillOneAdd(pid)
		elseif Players[pid].data.skills[PlayerOptionPoint[nameP].comp] and PlayerOptionPoint[nameP].state == "Remove" then
			MenuSkillOneRemove(pid)				
		elseif Players[pid].data.attributes[PlayerOptionPoint[nameP].comp] and PlayerOptionPoint[nameP].state == "Add" then
			MenuCompAdd(pid)	
		elseif Players[pid].data.attributes[PlayerOptionPoint[nameP].comp] and PlayerOptionPoint[nameP].state == "Remove" then
			MenuCompRemove(pid)					
		end				
	elseif idGui == gui.CompAddGUI then
		if tonumber(data) == 0 then --Strength
			InputDialog(pid, "Strength", "Add")
		elseif tonumber(data) == 1 then --Endurance
			InputDialog(pid, "Endurance", "Add")
		elseif tonumber(data) == 2 then --Speed
			InputDialog(pid, "Speed", "Add")
		elseif tonumber(data) == 3 then --Agility
			InputDialog(pid, "Agility", "Add")
		elseif tonumber(data) == 4 then --Intelligence
			InputDialog(pid, "Intelligence", "Add")
		elseif tonumber(data) == 5 then --Willpower
			InputDialog(pid, "Willpower", "Add")
		elseif tonumber(data) == 6 then --Luck
			InputDialog(pid, "Luck", "Add")
		elseif tonumber(data) == 7 then --Personality
			InputDialog(pid, "Personality", "Add")
		elseif tonumber(data) == 8 then --Remove
			MenuCompRemove(pid)
		elseif tonumber(data) == 9 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end		
	elseif idGui == gui.CompRemoveGUI then
		if tonumber(data) == 0 then --Strength
			InputDialog(pid, "Strength", "Remove")
		elseif tonumber(data) == 1 then --Endurance
			InputDialog(pid, "Endurance", "Remove")
		elseif tonumber(data) == 2 then --Speed
			InputDialog(pid, "Speed", "Remove")
		elseif tonumber(data) == 3 then --Agility
			InputDialog(pid, "Agility", "Remove")
		elseif tonumber(data) == 4 then --Intelligence
			InputDialog(pid, "Intelligence", "Remove")
		elseif tonumber(data) == 5 then --Willpower
			InputDialog(pid, "Willpower", "Remove")
		elseif tonumber(data) == 6 then --Luck
			InputDialog(pid, "Luck", "Remove")
		elseif tonumber(data) == 7 then --Personality
			InputDialog(pid, "Personality", "Remove")
		elseif tonumber(data) == 8 then --Add
			MenuCompAdd(pid)
		elseif tonumber(data) == 9 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end			
	elseif idGui == gui.SkillAddOneGUI then
		if tonumber(data) == 0 then --Handtohand
			InputDialog(pid, "Handtohand", "Add")
		elseif tonumber(data) == 1 then --Shortblade
			InputDialog(pid, "Shortblade", "Add")
		elseif tonumber(data) == 2 then --Longblade
			InputDialog(pid, "Longblade", "Add")
		elseif tonumber(data) == 3 then --Axe
			InputDialog(pid, "Axe", "Add")
		elseif tonumber(data) == 4 then --Bluntweapon
			InputDialog(pid, "Bluntweapon", "Add")
		elseif tonumber(data) == 5 then --Spear
			InputDialog(pid, "Spear", "Add")
		elseif tonumber(data) == 6 then --Security
			InputDialog(pid, "Security", "Add")
		elseif tonumber(data) == 7 then --Athletics
			InputDialog(pid, "Athletics", "Add")
		elseif tonumber(data) == 8 then --Marksman
			InputDialog(pid, "Marksman", "Add")	
		elseif tonumber(data) == 9 then --Acrobatics
			InputDialog(pid, "Acrobatics", "Add")
		elseif tonumber(data) == 10 then --Sneak
			InputDialog(pid, "Sneak", "Add")
		elseif tonumber(data) == 11 then --Mercantile
			InputDialog(pid, "Mercantile", "Add")
		elseif tonumber(data) == 12 then --Unarmored
			InputDialog(pid, "Unarmored", "Add")			
		elseif tonumber(data) == 13 then --Remove1
			MenuSkillOneRemove(pid)
		elseif tonumber(data) == 14 then --Page2Add
			MenuSkillTwoAdd(pid)
		elseif tonumber(data) == 15 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end	
	elseif idGui == gui.SkillAddTwoGUI then
		if tonumber(data) == 0 then --Lightarmor
			InputDialog(pid, "Lightarmor", "Add")
		elseif tonumber(data) == 1 then --Mediumarmor
			InputDialog(pid, "Mediumarmor", "Add")
		elseif tonumber(data) == 2 then --Heavyarmor
			InputDialog(pid, "Heavyarmor", "Add")
		elseif tonumber(data) == 3 then --Block
			InputDialog(pid, "Block", "Add")
		elseif tonumber(data) == 4 then --Armorer
			InputDialog(pid, "Armorer", "Add")
		elseif tonumber(data) == 5 then --Speechcraft
			InputDialog(pid, "Speechcraft", "Add")
		elseif tonumber(data) == 6 then --Enchant
			InputDialog(pid, "Enchant", "Add")
		elseif tonumber(data) == 7 then --Destruction
			InputDialog(pid, "Destruction", "Add")
		elseif tonumber(data) == 8 then --Conjuration
			InputDialog(pid, "Conjuration", "Add")	
		elseif tonumber(data) == 9 then --Illusion
			InputDialog(pid, "Illusion", "Add")
		elseif tonumber(data) == 10 then --Alteration
			InputDialog(pid, "Alteration", "Add")
		elseif tonumber(data) == 11 then --Mysticism
			InputDialog(pid, "Mysticism", "Add")
		elseif tonumber(data) == 12 then --Restoration
			InputDialog(pid, "Restoration", "Add")
		elseif tonumber(data) == 13 then --Alchemy
			InputDialog(pid, "Alchemy", "Add")				
		elseif tonumber(data) == 14 then --Remove2
			MenuSkillTwoRemove(pid)
		elseif tonumber(data) == 15 then --Page1Add
			MenuSkillOneAdd(pid)
		elseif tonumber(data) == 16 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end			
	elseif idGui == gui.SkillRemoveOneGUI then
		if tonumber(data) == 0 then --Handtohand
			InputDialog(pid, "Handtohand", "Remove")
		elseif tonumber(data) == 1 then --Shortblade
			InputDialog(pid, "Shortblade", "Remove")
		elseif tonumber(data) == 2 then --Longblade
			InputDialog(pid, "Longblade", "Remove")
		elseif tonumber(data) == 3 then --Axe
			InputDialog(pid, "Axe", "Remove")
		elseif tonumber(data) == 4 then --Bluntweapon
			InputDialog(pid, "Bluntweapon", "Remove")
		elseif tonumber(data) == 5 then --Spear
			InputDialog(pid, "Spear", "Remove")
		elseif tonumber(data) == 6 then --Security
			InputDialog(pid, "Security", "Remove")
		elseif tonumber(data) == 7 then --Athletics
			InputDialog(pid, "Athletics", "Remove")
		elseif tonumber(data) == 8 then --Marksman
			InputDialog(pid, "Marksman", "Remove")	
		elseif tonumber(data) == 9 then --Acrobatics
			InputDialog(pid, "Acrobatics", "Remove")
		elseif tonumber(data) == 10 then --Sneak
			InputDialog(pid, "Sneak", "Remove")
		elseif tonumber(data) == 11 then --Mercantile
			InputDialog(pid, "Mercantile", "Remove")
		elseif tonumber(data) == 12 then --Unarmored
			InputDialog(pid, "Unarmored", "Remove")			
		elseif tonumber(data) == 13 then --Add1
			MenuSkillOneAdd(pid)
		elseif tonumber(data) == 14 then --Page2Remove
			MenuSkillTwoRemove(pid)
		elseif tonumber(data) == 15 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end	
	elseif idGui == gui.SkillRemoveTwoGUI then
		if tonumber(data) == 0 then --Lightarmor
			InputDialog(pid, "Lightarmor", "Remove")
		elseif tonumber(data) == 1 then --Mediumarmor
			InputDialog(pid, "Mediumarmor", "Remove")
		elseif tonumber(data) == 2 then --Heavyarmor
			InputDialog(pid, "Heavyarmor", "Remove")
		elseif tonumber(data) == 3 then --Block
			InputDialog(pid, "Block", "Remove")
		elseif tonumber(data) == 4 then --Armorer
			InputDialog(pid, "Armorer", "Remove")
		elseif tonumber(data) == 5 then --Speechcraft
			InputDialog(pid, "Speechcraft", "Remove")
		elseif tonumber(data) == 6 then --Enchant
			InputDialog(pid, "Enchant", "Remove")
		elseif tonumber(data) == 7 then --Destruction
			InputDialog(pid, "Destruction", "Remove")
		elseif tonumber(data) == 8 then --Conjuration
			InputDialog(pid, "Conjuration", "Remove")	
		elseif tonumber(data) == 9 then --Illusion
			InputDialog(pid, "Illusion", "Remove")
		elseif tonumber(data) == 10 then --Alteration
			InputDialog(pid, "Alteration", "Remove")
		elseif tonumber(data) == 11 then --Mysticism
			InputDialog(pid, "Mysticism", "Remove")
		elseif tonumber(data) == 12 then --Restoration
			InputDialog(pid, "Restoration", "Remove")
		elseif tonumber(data) == 13 then --Alchemy
			InputDialog(pid, "Alchemy", "Remove")				
		elseif tonumber(data) == 14 then --Add2
			MenuSkillTwoAdd(pid)
		elseif tonumber(data) == 15 then --Page1Remove
			MenuSkillOneRemove(pid)
		elseif tonumber(data) == 16 then --Return
			MainMenu.ShowPlayerGUI(pid)
		end	
	end
end)

customEventHooks.registerValidator("OnPlayerLevel", function(eventStatus, pid)	
	PlayerLevel(pid)
	return customEventHooks.makeEventStatus(false,false)		
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if not Players[pid].data.customVariables.playerLevel then
		AddCustom(pid)			
	end		
end)

customEventHooks.registerValidator("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
	for _, actor in pairs(actors) do
		if actor.refId and actor.uniqueIndex then	
			if LoadedCells[cellDescription].data.objectData[actor.uniqueIndex]
			and LoadedCells[cellDescription].data.objectData[actor.uniqueIndex].deathState then
				return
			end
			if LoadedCells[cellDescription].data.objectData[actor.uniqueIndex]
			and LoadedCells[cellDescription].data.objectData[actor.uniqueIndex].summon then
				return
			end 			
			if actor.killer.pid then		
				GiveXpForPlayer(actor.killer.pid, actor.uniqueIndex, "Actor", nil, cellDescription)				
			elseif actor.killer.uniqueIndex then			
				if LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex]
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].summon 
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].summon.summoner 
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].summon.summoner.playerName then
					local targetName = LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].summon.summoner.playerName					
					local targetPlayer = logicHandler.GetPlayerByName(targetName)						
					if targetPlayer and targetPlayer.pid and Players[targetPlayer.pid] then
						GiveXpForPlayer(targetPlayer.pid, actor.uniqueIndex, "Actor",  nil, cellDescription)
					end
				elseif LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex]
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].ai
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].ai.action
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].ai.action == enumerations.ai.FOLLOW					
				and LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].ai.targetPlayer then
					local targetName = LoadedCells[cellDescription].data.objectData[actor.killer.uniqueIndex].ai.targetPlayer
					local targetPlayer = logicHandler.GetPlayerByName(targetName)
					if targetPlayer and targetPlayer.pid and Players[targetPlayer.pid] then
						GiveXpForPlayer(targetPlayer.pid, actor.uniqueIndex, "Actor", nil, cellDescription)
					end
				end				
			end
		end
	end
end)

customEventHooks.registerHandler("OnPlayerJournal", function(eventStatus, pid, playerPacket)	
	for _, data in pairs(playerPacket.journal) do	
		GiveXpForPlayer(pid, nil, "Journal", data.index, nil)		
	end
end)

customCommandHooks.registerCommand("attribute", MenuCompAdd)
customCommandHooks.registerCommand("attr", MenuCompAdd)
customCommandHooks.registerCommand("skill", MenuSkillOneAdd)
customCommandHooks.registerCommand("skil", MenuSkillOneAdd)

PlayerLevelScript = {}

PlayerLevelScript.InputDialog = function(pid, comp, state)
	InputDialog(pid, comp, state)	
end

PlayerLevelScript.OnPlayerCompetence = function(pid, Comp, State, Count)	
	OnPlayerCompetence(pid, Comp, State, Count)
end	

PlayerLevelScript.MenuComp = function(pid)
	MenuCompAdd(pid)
end

PlayerLevelScript.MenuSkill = function(pid)
	MenuSkillOneAdd(pid)
end

PlayerLevelScript.GetlevelSoul = function(pid)
	GetlevelSoul(pid)
end

PlayerLevelScript.PlayerLevel = function(pid)
	PlayerLevel(pid)
end
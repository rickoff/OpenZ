--[[
PlayerEditScript
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as PlayerEditScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua add in :
require("custom.PlayerEditScript")
---------------------------
]]
local PlayerCustomData = {}

local cfg = {
	Gender = true,
	Race = true,
	Head = true,
	Hair = true,
	Sign = true,
	Size = false,
	ScaleMax = 1.1,
	ScaleMin = 0.9
}

local trd = {
    Select = "Select:\n",
    Title = "EDIT CHARACTER\n\n",
    Gender = "Gender: ",
    Race = "Color: ",
    Head = "Head: ",
    Hair = "Hair: ",
    Birth = "Sign: ",
    Scale = "Size: ",
    Return = "Return\n",
    Man = "Man",
    Woman = "Woman"
}

local gui = {
	MainGUIEdit = 325491,
	SelectGUIEdit = 325492
}

local DataHead = {
	white = {
		"white_m_head_01",
		"white_m_head_02",
		"white_m_head_03",
		"white_m_head_04",
		"white_m_head_05",
		"white_m_head_06",
		"white_m_head_07",
		"white_m_head_08",
		"white_f_head_01",
		"white_f_head_02",
		"white_f_head_03",
		"white_f_head_04",
		"white_f_head_05",
		"white_f_head_06"
	},
	black = {
		"black_m_head_01",
		"black_m_head_02",
		"black_m_head_03",
		"black_m_head_04",
		"black_m_head_05",
		"black_m_head_06",
		"black_f_head_01",
		"black_f_head_02",
		"black_f_head_03",
		"black_f_head_04",
		"black_f_head_05",
		"black_f_head_06"
	}
}

local DataHair = {
	"white_m_hair_00",
	"white_m_hair_01",
	"white_m_hair_02",
	"white_m_hair_03",
	"white_m_hair_04",
	"white_m_hair_05",
	"white_f_hair_01",
	"white_f_hair_02",
	"white_f_hair_03",
	"white_f_hair_04",
	"white_f_hair_05",
	"black_m_hair_00",
	"black_m_hair_01",
	"black_m_hair_02",
	"black_m_hair_03",
	"black_m_hair_04",
	"black_m_hair_05",
	"black_m_hair_06",	
	"black_f_hair_01",
	"black_f_hair_02",
	"black_f_hair_03",
	"black_f_hair_04",
	"black_f_hair_05"		
}

local DataBsgn = {
	birthsign_aquarius = {
		name = "Aquarius",
		spells = {"birth_aquarius"},
		effects = "Agility +10"
	},
	birthsign_aries = {
		name = "Aries",
		spells = {"birth_aries"},
		effects = "Endurance +10"		
	},
	birthsign_cancer = {
		name = "Cancer",
		spells = {"birth_cancer"},
		effects = "Intelligence +10"		
	},
	birthsign_capricorn = {
		name = "Capricorn",
		spells = {"birth_capricorn"},
		effects = "Luck +10"		
	},
	birthsign_gemini = {
		name = "Gemini",
		spells = {"birth_gemini"},
		effects = "Personality +10"		
	},
	birthsign_libra = {
		name = "Libra",
		spells = {"birth_libra"},
		effects = "Speed +10"		
	},
	birthsign_lion = {
		name = "Lion",
		spells = {"birth_lion"},
		effects = "Strength +10"		
	},
	birthsign_pisces = {
		name = "Pisces",
		spells = {"birth_pisces"},
		effects = "Willpower +10"		
	},
	birthsign_sagittarius = {
		name = "Sagittarius",
		spells = {"birth_sagittarius"},
		effects = "Night eye +20"		
	},
	birthsign_scorpio = {
		name = "Scorpio",
		spells = {"birth_scorpio"},
		effects = "Resist Infection 25%"		
	},
	birthsign_taurus = {
		name = "Taurus",
		spells = {"birth_taurus"},
		effects = "Weight Bag +20"		
	},		
	birthsign_virgo = {
		name = "Virgo",
		spells = {"birth_virgo"},
		effects = "Mercantile +25"		
	}
}

local function OptionEdit()
	local option = "Confirm"
	if cfg.Size then
		option = "Size+;Size-;" .. option
	end
	if cfg.Sign then
		option = "Sign;" .. option	
	end
	if cfg.Hair then
		option = "Hair;" .. option
	end
	if cfg.Head then
		option = "Head;" .. option
	end
	if cfg.Race then
		option = "Color;" .. option
	end	
	if cfg.Gender then
		option = "Gender;" .. option
	end
	return option
end

local function GuiEditNumber()
	local optionString = OptionEdit()
	local list = {}
	for option in string.gmatch(optionString, "([^;]+)") do
		table.insert(list, option)
	end
	return list
end

local function NeedEdit()
	local need = "You must choose a "
	if cfg.Size then
		need = need.."Size, "
	end
	if cfg.Sign then
		need = need.."Sign, "
	end		
	if cfg.Hair then
		need = need.."Hair, "
	end
	if cfg.Head then
		need = need.."Head, "
	end
	if cfg.Race then
		need = need.."Color, "
	end	
	if cfg.Gender then
		need = need.."Gender, "
	end
	need = need.."before confirming."
	return need
end

local function ShowMainGuiEdit(pid)	
	local gender = ""
	local race = ""
	local hair = ""
	local head = ""
	local sign = ""
	local size = ""	
	local PlayerName = string.lower(Players[pid].accountName)
	if not PlayerCustomData[PlayerName] then 	
		PlayerCustomData[PlayerName] = {}
		PlayerCustomData[PlayerName] = {
			gender = Players[pid].data.character.gender,
			race = Players[pid].data.character.race,
			head = Players[pid].data.character.head,
			hair = Players[pid].data.character.hair,
			birthsign = Players[pid].data.character.birthsign,
			size = Players[pid].data.shapeshift.scale or 1
		}	
	end
	if PlayerCustomData[PlayerName].gender == 0 then
		gender = trd.Woman.."\n\n"
	else
		gender = trd.Man.."\n\n"
	end		
	if PlayerCustomData[PlayerName].race then
		race = PlayerCustomData[PlayerName].race.."\n\n"
	end			
	if PlayerCustomData[PlayerName].head then
		head = PlayerCustomData[PlayerName].head.."\n\n"
	end		
	if PlayerCustomData[PlayerName].hair then
		hair = PlayerCustomData[PlayerName].hair.."\n\n"
	end		
	if PlayerCustomData[PlayerName].birthsign then
		sign = DataBsgn[PlayerCustomData[PlayerName].birthsign].name.."\n\n"
	end
	if PlayerCustomData[PlayerName].size then
		size = PlayerCustomData[PlayerName].size .."\n\n"
	end		
	local message = (
		color.Red .. trd.Title
		..color.Orange .. trd.Gender
		..color.White .. gender	
		..color.Orange .. trd.Race
		..color.White .. race
		..color.Orange .. trd.Head
		..color.White .. head
		..color.Orange .. trd.Hair
		..color.White .. hair
		..color.Orange .. trd.Birth
		..color.White .. sign
		..color.Orange .. trd.Scale
		..color.White .. size			
	)		
	tes3mp.CustomMessageBox(pid, gui.MainGUIEdit, message, OptionEdit())
end

local function ShowChangeGUIEdit(pid, cat)
	local options = {}	
	local PlayerName = string.lower(Players[pid].accountName)
	local list = ""	
	local title = trd.Select	
	if cat == "GENDER" then
		if PlayerCustomData[PlayerName].gender == 0 then
			title = title..trd.Woman
		else
			title = title..trd.Man
		end	
		table.insert(options, trd.Man)
		table.insert(options, trd.Woman)	
	elseif cat == "RACE" then
		title = title..PlayerCustomData[PlayerName].race
		options = {"White", "Black"}
	elseif cat == "HEAD" then
		title = title..PlayerCustomData[PlayerName].head	
		for _, refHead in ipairs(DataHead[string.lower(PlayerCustomData[PlayerName].race)]) do
			if PlayerCustomData[PlayerName].gender == 0 then
				if string.find(refHead, "_f") then
					table.insert(options, refHead)
				end
			else
				if string.find(refHead, "_m") then
					table.insert(options, refHead)
				end			
			end
		end		
	elseif cat == "HAIR" then
		list = trd.Return	
		title = title..PlayerCustomData[PlayerName].hair		
		for _, refHair in ipairs(DataHair) do
			table.insert(options, refHair)
		end
	elseif cat == "SIGN" then
		list = trd.Return	
		title = title..DataBsgn[PlayerCustomData[PlayerName].birthsign].name	
		for id, slot in pairs(DataBsgn) do
			table.insert(options, slot.name.. " | Effects : "..slot.effects)
		end		
	end			
	for i = 1, #options do
		list = list..options[i].."\n"	
	end		
	PlayerCustomData[PlayerName].cat = cat	
	tes3mp.ListBox(pid, gui.SelectGUIEdit, color.CornflowerBlue..title..color.Default, list)
end

local function ValidateSettingsEdit(pid)
	local PlayerName = string.lower(Players[pid].accountName)	
	if PlayerCustomData[PlayerName] then	
		if PlayerCustomData[PlayerName].head and PlayerCustomData[PlayerName].hair
		and PlayerCustomData[PlayerName].gender and PlayerCustomData[PlayerName].race
		and PlayerCustomData[PlayerName].birthsign then
			Players[pid].data.character.gender = PlayerCustomData[PlayerName].gender
			Players[pid].data.character.race = PlayerCustomData[PlayerName].race	
			Players[pid].data.character.hair = PlayerCustomData[PlayerName].hair
			Players[pid].data.character.head = PlayerCustomData[PlayerName].head	
			Players[pid].data.character.birthsign = PlayerCustomData[PlayerName].birthsign				
			tes3mp.SetIsMale(pid, PlayerCustomData[PlayerName].gender)			
			tes3mp.SetRace(pid, PlayerCustomData[PlayerName].race)		
			tes3mp.SetHair(pid, PlayerCustomData[PlayerName].hair)
			tes3mp.SetHead(pid, PlayerCustomData[PlayerName].head)	
			tes3mp.SetBirthsign(pid, PlayerCustomData[PlayerName].birthsign)				
			tes3mp.SetResetStats(pid, false)
			tes3mp.SendBaseInfo(pid)
			logicHandler.RunConsoleCommandOnPlayer(pid, "ToggleVanityMode", false)	
		else
			local message = (color.Red..NeedEdit())	
			tes3mp.MessageBox(pid, -1, message)		
			ShowMainGuiEdit(pid)
		end
	else
		local message = (color.Red..NeedEdit())	
		tes3mp.MessageBox(pid, -1, message)		
		ShowMainGuiEdit(pid)
	end		
end

local function SendSettings(pid)
	local PlayerName = string.lower(Players[pid].accountName)	
	if PlayerCustomData[PlayerName].gender then
		Players[pid].data.character.gender = PlayerCustomData[PlayerName].gender	
		tes3mp.SetIsMale(pid, PlayerCustomData[PlayerName].gender)		
	end	
	if PlayerCustomData[PlayerName].race then
		Players[pid].data.character.race = PlayerCustomData[PlayerName].race	
		tes3mp.SetRace(pid, PlayerCustomData[PlayerName].race)
	end	
	if PlayerCustomData[PlayerName].hair then
		Players[pid].data.character.hair = PlayerCustomData[PlayerName].hair
		tes3mp.SetHair(pid, PlayerCustomData[PlayerName].hair)
	end	
	if PlayerCustomData[PlayerName].head then
		Players[pid].data.character.head = PlayerCustomData[PlayerName].head
		tes3mp.SetHead(pid, PlayerCustomData[PlayerName].head)
	end	
	if PlayerCustomData[PlayerName].birthsign then
		local tabAddSpell = {}
		local tabRemoveSpell = {}	
		for x, spellId in pairs(DataBsgn[Players[pid].data.character.birthsign].spells) do
			table.insert(tabRemoveSpell, spellId)
		end
		Players[pid].data.character.birthsign = PlayerCustomData[PlayerName].birthsign
		for x, spellId in pairs(DataBsgn[PlayerCustomData[PlayerName].birthsign].spells) do
			table.insert(tabAddSpell, spellId)
		end		
		tes3mp.SetBirthsign(pid, PlayerCustomData[PlayerName].birthsign)
		RemoveSpell(pid, tabRemoveSpell)
		AddSpell(pid, tabAddSpell)
	end	
	local PlayerRace = Players[pid].data.character.race	
	local PlayerGender = Players[pid].data.character.gender	
	local Model = "base_anim.nif"	
	if PlayerGender == 0 then	
		Model = "base_anim_female.nif"			
	end	
	tes3mp.SetModel(pid, Model)	
	tes3mp.SetResetStats(pid, false)
	tes3mp.SendBaseInfo(pid)
end

local function OnPlayerEdit(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end
	logicHandler.RunConsoleCommandOnPlayer(pid, "ToggleVanityMode", false)
	ShowMainGuiEdit(pid)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.MainGUIEdit then
		local PlayerName = string.lower(Players[pid].accountName)	
		local list = GuiEditNumber()
		local action = list[tonumber(data) + 1]	
		if action == "Gender" then
			ShowChangeGUIEdit(pid, "GENDER")
		elseif action == "Color" then
			ShowChangeGUIEdit(pid, "RACE")
		elseif action == "Head" then
			ShowChangeGUIEdit(pid, "HEAD")
		elseif action == "Hair" then
			ShowChangeGUIEdit(pid, "HAIR")
		elseif action == "Sign" then
			ShowChangeGUIEdit(pid, "SIGN")	
		elseif action == "Size+" then
			local scale = Players[pid].data.shapeshift.scale or 1			
			if scale < cfg.ScaleMax then
				Players[pid].data.shapeshift.scale = scale + 0.01
				tes3mp.SetScale(pid, Players[pid].data.shapeshift.scale)
				tes3mp.SendShapeshift(pid)
				PlayerCustomData[PlayerName].size = Players[pid].data.shapeshift.scale
			end
			ShowMainGuiEdit(pid)			
		elseif action == "Size-" then
			local scale = Players[pid].data.shapeshift.scale or 1					
			if scale > cfg.ScaleMin then
				Players[pid].data.shapeshift.scale = scale - 0.01
				tes3mp.SetScale(pid, Players[pid].data.shapeshift.scale)
				tes3mp.SendShapeshift(pid)
				PlayerCustomData[PlayerName].size = Players[pid].data.shapeshift.scale				
			end	
			ShowMainGuiEdit(pid)				
		elseif action == "Confirm" then
			ValidateSettingsEdit(pid)			
		end	
	elseif idGui == gui.SelectGUIEdit then	
		local PlayerName = string.lower(Players[pid].accountName)			
		if data == nil or tonumber(data) == 18446744073709551615 then	
			ShowMainGuiEdit(pid)
		else		
			if PlayerCustomData[PlayerName].cat == "GENDER" then
				if tonumber(data) == 0 then
					PlayerCustomData[PlayerName].gender = 1
				elseif tonumber(data) == 1 then	
					PlayerCustomData[PlayerName].gender = 0	
				end
				SendSettings(pid)
				ShowChangeGUIEdit(pid, "RACE")					
			elseif PlayerCustomData[PlayerName].cat == "RACE" then
				local options = {"White", "Black"}	
				PlayerCustomData[PlayerName].race = options[tonumber(data)+1]
				SendSettings(pid)				
				ShowChangeGUIEdit(pid, "HEAD")							
			elseif PlayerCustomData[PlayerName].cat == "HEAD" then
				local options = {}				
				for _, refHead in ipairs(DataHead[string.lower(PlayerCustomData[PlayerName].race)]) do
					if PlayerCustomData[PlayerName].gender == 0 then
						if string.find(refHead, "_f") then
							table.insert(options, refHead)
						end
					else
						if string.find(refHead, "_m") then
							table.insert(options, refHead)
						end			
					end
				end				
				PlayerCustomData[PlayerName].head = options[tonumber(data)+1]
				SendSettings(pid)
				ShowMainGuiEdit(pid)				
			elseif PlayerCustomData[PlayerName].cat == "HAIR" then
				if tonumber(data) == 0 then				
				else
					local options = {}
					for _, refHair in ipairs(DataHair) do
						table.insert(options, refHair)
					end	
					PlayerCustomData[PlayerName].hair = options[tonumber(data)]
					SendSettings(pid)	
				end
				ShowMainGuiEdit(pid)				
			elseif PlayerCustomData[PlayerName].cat == "SIGN" then
				if tonumber(data) == 0 then				
				else			
					local options = {}
					for id, slot in pairs(DataBsgn) do
						table.insert(options, id)
					end				
					PlayerCustomData[PlayerName].birthsign = options[tonumber(data)]
					SendSettings(pid)
				end
				ShowMainGuiEdit(pid)		
			end
		end
	end
end)

PlayerEditScript = {
	ShowMainGUI = function(pid)
		OnPlayerEdit(pid)
	end
}

customCommandHooks.registerCommand("edit", OnPlayerEdit)

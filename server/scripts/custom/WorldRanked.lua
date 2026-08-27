--[[
WorldRanked
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as WorldRanked.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.WorldRanked")
---------------------------
]]
local WorldRankingData = jsonInterface.load("custom/WorldRankingData.json")

local playerOptions = {}

local trd = {
	Menu = color.Red.."RANKING MENU",
	Choice = "Main;Survival;Pvp;Pve;Death;Return;Close"
}

local gui = {
	RankingGui = 51111,
	CheckRankingGUI = 51112
}

local function ConvertSeconds(seconds)
    local days = math.floor(seconds / (24 * 3600))
    seconds = seconds % (24 * 3600)
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02dd:%02dh:%02dm:%02ds", days, hours, minutes, secs)
end

local function LoadWorldData()
	WorldRankingData = jsonInterface.load("custom/WorldRankingData.json")
end

local function SaveWorldData()
	jsonInterface.quicksave("custom/WorldRankingData.json", WorldRankingData)
end

local function round(num, dec)
	local mult = 10^(dec or 0)
	return math.floor(num * mult + 0.5) / mult
end
	
local function getListRanking(pid, cat)
	local options = {}	
	if cat == "main" then
		for name, slot in pairs(WorldRankingData) do			
			local TotalScore = round((((slot.kill + slot.hunter) - slot.death) + 1) * ((os.time() - slot.survive)/3600), 4)
			local listOption = {
				name = name,
				score = TotalScore				
			}
			table.insert(options, listOption)
		end 
	elseif cat == "survive" then
		for name, slot in pairs(WorldRankingData) do
			local TotalScore = round(((os.time() - slot.survive)/3600), 4)
			local listOption = {
				name = name,
				score = TotalScore				
			}			
			table.insert(options, listOption)
		end 
	elseif cat == "death" then
		for name, slot in pairs(WorldRankingData) do
			local TotalScore = slot.death
			local listOption = {
				name = name,
				score = TotalScore				
			}			
			table.insert(options, listOption)
		end 			
	else
		for name, item in pairs(WorldRankingData) do	
			local listOption = {
				name = name,
				score = item[cat]			
			}		
			table.insert(options, listOption)
		end 
	end
	table.sort(options, function(a,b) return a.score > b.score end)
	return options
end

local function AddPts(pid, data, pts)
	local PlayerName = GetName(pid)
	WorldRankingData[PlayerName][data] = WorldRankingData[PlayerName][data] + pts
	SaveWorldData()	
end

local function CheckRanking(pid, cat)	
	local options = getListRanking(pid, cat)
	local list = "Return\n"
	local listCat = ""	
	if cat == "main" then
		listCat = "Main" 
	elseif cat == "survive" then
		listCat = "Survive" 
	elseif cat == "kill" then
		listCat = "Pvp" 
	elseif cat == "hunter" then
		listCat = "Pve" 
	elseif cat == "death" then
		listCat = "Death" 
	end		
	for i = 1, #options do
		list = list .. "Name: "..options[i].name.." Score: "..options[i].score			
		if not(i == #options) then
			list = list .. "\n"
		end			
	end			
	playerOptions[GetName(pid)] = {opt = options}		
	tes3mp.ListBox(pid, gui.CheckRankingGUI, color.CornflowerBlue .. "RANKING\n\n"..color.Yellow.. listCat .."\n\n", list)
end

local function SaveSurviveTime(pid)
	local PlayerName = GetName(pid)
	if WorldRankingData[PlayerName] then	
		WorldRankingData[PlayerName].survive = os.time()				
		SaveWorldData()
	end
end

local function ShowMainGui(pid)
	local PlayerName = GetName(pid)
	local message = (
		trd.Menu..
		color.Orange.."\n\nEnemies killed : "..color.White..WorldRankingData[PlayerName].hunter..
		color.Orange.."\n\nPlayers killed : "..color.White..WorldRankingData[PlayerName].kill..
		color.Orange.."\n\nDeath count : "..color.White..WorldRankingData[PlayerName].death..		
		color.Orange.."\n\nSurvive time\n"..color.White..ConvertSeconds(os.time() - WorldRankingData[PlayerName].survive)
		
	)
	tes3mp.CustomMessageBox(pid, gui.RankingGui, message, trd.Choice)
end

customEventHooks.registerHandler("OnServerInit", function(eventStatus)
	if not WorldRankingData then
		WorldRankingData = {}
		SaveWorldData()
	end	
end)

customEventHooks.registerHandler("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
	if eventStatus.validCustomHandlers then
		for index, actor in pairs(actors) do
			if actor.killer.pid and actor.refId then
				AddPts(actor.killer.pid, "hunter", 1)
			end
		end
	end
end)

customEventHooks.registerHandler("OnPlayerDeath", function(eventStatus, pid)
	AddPts(pid, "death", 1)
	local deathReason = tes3mp.GetDeathReason(pid)
	local playerKiller = logicHandler.GetPlayerByName(deathReason)
	if playerKiller then
		local KillerPid = playerKiller.pid
		if Players[KillerPid] and Players[KillerPid]:IsLoggedIn() then
			if KillerPid ~= pid then
				AddPts(KillerPid, "kill", 1)			
			end
		end
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	local PlayerName = GetName(pid)	
	if not WorldRankingData[PlayerName] then
		WorldRankingData[PlayerName] = {
			kill = 0,
			hunter = 0,
			death = 0,
			survive = os.time()
		}						
		SaveWorldData()			
	end
end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if idGui == gui.RankingGui then		
		if tonumber(data) == 0 then
			CheckRanking(pid, "main")
		elseif tonumber(data) == 1 then
			CheckRanking(pid, "survive")
		elseif tonumber(data) == 2 then
			CheckRanking(pid, "kill")		
		elseif tonumber(data) == 3 then
			CheckRanking(pid, "hunter")	
		elseif tonumber(data) == 4 then
			CheckRanking(pid, "death")				
		elseif tonumber(data) == 5 then
			MainMenu.ShowServerGUI(pid)
		end
	elseif idGui == gui.CheckRankingGUI then	
		ShowMainGui(pid)		
	end
end)

customCommandHooks.registerCommand("rank", ShowMainGui)

WorldRanked = {}

WorldRanked.LoadWorldData = function()
	LoadWorldData()
end

WorldRanked.SaveSurviveTime = function(pid)
	SaveSurviveTime(pid)
end

WorldRanked.ShowMainGui = function(pid)
	ShowMainGui(pid)	
end
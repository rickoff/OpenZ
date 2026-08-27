--[[
HelpCommand
tes3mp 0.8.1
---------------------------
INSTALLATION:
Save the file as HelpCommand.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
require("custom.HelpCommand")
---------------------------
]]

local cfg = {
	MainGUI = 230923
}

local trd = {
	message = (color.Red.."CHAT COMMANDS\n\n".. 
		color.Orange.."/menu : "..color.White.." open the main menu.\n"..	
		color.Orange.."/hous : "..color.White.." open the global house menu.\n".. 
		color.Orange.."/edit : "..color.White.." open the character editing menu.\n"..	
		color.Orange.."/attr : "..color.White.." open the attributes menu.\n".. 
		color.Orange.."/skil : "..color.White.." open the skills menu.\n"..		
		color.Orange.."/rese : "..color.White.." open the reset menu.\n"..
		color.Orange.."/dele : "..color.White.." open the delete menu.\n".. 		
		color.Orange.."/grou : "..color.White.." open the group menu.\n".. 
		color.Orange.."/emot : "..color.White.." open the animation menu.\n"..
		color.Orange.."/craf : "..color.White.." open the quick craft menu.\n"..		
		color.Orange.."/help : "..color.White.." open the quick command list.\n"	
	),
	choice = "Return;Close"
}

local function ShowMainGUI(pid)
	if PlayersDeath[GetName(pid)] then
		PlayerScript.ShowRessurectWaitGUI(pid)
		return
	end	
	tes3mp.CustomMessageBox(pid, cfg.MainGUI, trd.message, trd.choice)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)  
    if idGui == cfg.MainGUI then
        if tonumber(data) == 0 then
			MainMenu.ShowServerGUI(pid)
        end
	end
end)

customCommandHooks.registerCommand("help", ShowMainGUI)

HelpCommand = {}

HelpCommand.ShowMainGUI = function(pid)
	ShowMainGUI(pid)
end
---lua chat beautify---
local LuaChat = {}
local blue   = Color(132, 182, 232)
local orange = Color(188, 161, 98)
local red    = Color(140, 101, 211)

LuaChat.Cmds = {
	["l"]       	= {text = "Server",          color = blue   },
	["lm"]      	= {text = "Self",            color = red    },
	["ls"]      	= {text = "Shared",          color = orange },
	["lb"]      	= {text = "Both",            color = orange },
	["lc"]      	= {text = "Clients",         color = red },
	["print"]   	= {text = "Server Print",    color = blue   },
	["table"]   	= {text = "Server Table",    color = blue   },
	["keys"]    	= {text = "Server Keys",     color = blue   },
	["printm"]  	= {text = "Self Print",      color = red    },
	["printb"]  	= {text = "Both Print",      color = orange },
	["printc"]  	= {text = "Clients Print",   color = red    },
	["cmd"]     	= {text = "Console",         color = red    },
	["rcon"]    	= {text = "Server Console",  color = blue   },
	["settod"]  	= {text = "Tod",             color = blue   },
	["sudo"]    	= {text = "Sudo",            color = blue   },
	["map"]			= {text = "Map",             color = blue   },
	["restart"]		= {text = "Server Restart",  color = blue   },
	["reboot"]		= {text = "Server Reboot",   color = blue   },
	["resetmap"]	= {text = "Server Cleanup",  color = blue   },
}

LuaChat.OnClientCmds = { --add commands ran on specific client here
	["lsc"]    = "",
	["cexec"]  = "Command",
	["ban"]    = "Ban",
	["kick"]   = "Kick",
	["rank"]   = "Rank",
	["give"]   = "Give",
}

LuaChat.IsCommand = function(str)
	local s = string.lower(str)
	local s,replaced = string.gsub(s,"^[!|%.|/]","")
	if string.match(s,"^[%a+|%d+]") then
		return replaced >= 1 and true or false
	else
		return false
	end
end

local function get(str)
	if not str then return "" end

	if player.FindByName then
		if IsValid(player.FindByName(str)) then
			return player.FindByName(str)
		else
			return str
		end
	else
		return str
	end
end

local function chatText(team_color, ply, line, cmd, target_name, slot_b)
	local arrow = " ⮞⮞ "
	cmd = istable(cmd) and cmd or {text = cmd}

	chat.AddText(Color(158, 158, 153), team_color, ply, Color(175, 175, 155), arrow, cmd.color or red, target_name or "", cmd.text, Color(200, 200, 200), ": "..(slot_b and slot_b.." " or "")..line)
	-- Alternative: Color(158, 158, 153)
end

LuaChat.DoLuaCommand = function(ply,str)
	if LuaChat.IsCommand(str) and IsValid(ply) and aowl then
		local str,_ = string.gsub(str,"^[!|%.|/]","")
		local args = string.Explode(" ",str)
		local cmd = string.lower(args[1])

		local team_color = team.GetColor(ply:Team())
		local line = ""

		if LuaChat.Cmds[cmd] then

			line = table.concat(args," ",2)
			chatText(team_color, ply, line, LuaChat.Cmds[cmd])

			return true

		elseif LuaChat.OnClientCmds[cmd] then

			local a = string.Explode(",",args[2])

			cmd = not istable(LuaChat.OnClientCmds[cmd]) and (LuaChat.OnClientCmds[cmd] ~= "" and " "..LuaChat.OnClientCmds[cmd] or "") or LuaChat.OnClientCmds[cmd]
			line = table.concat(args," ",3)
			chatText(team_color, ply, line, cmd, get(a[1]), a[2])
			return true
		end
	end


end

hook.Add("OnPlayerChat","LuaChatCommands",LuaChat.DoLuaCommand)

local env = requirex("goluwa").env

local autocomplete_font = env.fonts.CreateFont({
	font = "Roboto Black",
	size = 18,
	weight = 600,
	blur_size = 3,
	background_color = Color(25,50,100,255),
	blur_overdraw = 3,
})

local chatsounds_enabled = CreateClientConVar("chatsounds_enabled", "1", true, false, "Disable chatsounds")

do
	local found_autocomplete
	local random_mode = false

	local function query(str, scroll)
		found_autocomplete = env.autocomplete.Query("chatsounds", str, scroll)
	end

	hook.Add("StartChat", "chatsounds_autocomplete_init", function()
		if not chatsounds_enabled:GetBool() then return end

		hook.Add("OnChatTab", "chatsounds_autocomplete", function(str, peek)
			if peek then return end

			if str == "random" or random_mode then
				random_mode = true
				query("", 0)
				return found_autocomplete[1]
			end

			query(str, (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or input.IsKeyDown(KEY_LCONTROL)) and -1 or 1)

			if found_autocomplete[1] then
				return found_autocomplete[1]
			end
		end)

		hook.Add("ChatTextChanged", "chatsounds_autocomplete", function(str)
			if str == "" or string.find(str, "\n", 1, true) then
				random_mode = true
				return
			end

			random_mode = false
			query(str, 0)
		end)

		hook.Add("PostRenderVGUI", "chatsounds_autocomplete", function()
			if random_mode then return end
			if found_autocomplete and #found_autocomplete > 0 then
				local x, y = chat.GetChatBoxPos()
				local w, h = chat.GetChatBoxSize()
				env.gfx.SetFont(autocomplete_font)
				env.autocomplete.DrawFound("chatsounds", x, y + h, found_autocomplete)
			end
		end)
	end)

	hook.Add("FinishChat", "chatsounds_autocomplete", function()
		if not chatsounds_enabled:GetBool() then return end

		hook.Remove("PostRenderVGUI", "chatsounds_autocomplete")
		hook.Remove("ChatTextChanged", "chatsounds_autocomplete")
		hook.Remove("OnChatTab", "chatsounds_autocomplete")
	end)
end

local init = false

local function player_say(ply, str)
	if not chatsounds_enabled:GetBool() then return end

	str = str:lower()
	if not init then
		env.chatsounds.Initialize()

		hook.Run("ChatsoundsInitialized")

		init = true
	end

	local info = {
		ply = ply,
		line = str,
	}

	if hook.Run("PreChatSound", info) == false then return end -- attempt to preserve old structure for compatibility reasons
	if str:Trim():find("^<.*>$") then return end
	if aowl and aowl.Prefix and str:find("^" .. aowl.Prefix) then return end

	if not IsValid(ply) then return end
	if ply:IsDormant() then return end
	if LocalPlayer():EyePos():Distance(ply:EyePos()) > 2500 then return end

	if str == "sh" or (str:find("sh%s") and not str:find("%Ssh")) or (str:find("%ssh") and not str:find("sh%S")) then
		env.audio.Panic()
	end

	env.audio.player_object = ply
	info.script = env.chatsounds.Say(str, math.Round(CurTime()))

	hook.Run("PostChatSound", info)
end

hook.Add("OnPlayerChat", "chatsounds", player_say)

concommand.Add("saysound", function(ply, _,_, str)
	if util.NetworkStringToID("newchatsounds") > 0 then	-- If the server has added the NetworkString
		net.Start("newchatsounds")
			net.WriteString(str:sub(1, 64000-32-32000))	-- Cut to 32KB
		net.SendToServer()
	else
		player_say(ply, str)
	end
end)

net.Receive("newchatsounds", function()
	local ply = net.ReadEntity()
	if not ply:IsValid() then return end

	local str = net.ReadString()
	player_say(ply, str)
end)

if not chatsounds_enabled:GetBool() then
	hook.Remove("OnPlayerChat", "chatsounds")
end

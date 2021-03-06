
if CLIENT then return end

mingeban.CreateCommand("rcon", function(caller, line)
	game.ConsoleCommand(line .. "\n")
end)

local cexec = mingeban.CreateCommand("cexec", function(caller, line, plys, cmd)
	if #plys < 2 then
		plys[1]:ConCommand("mingeban cmd " .. cmd)
	else
		for _, ply in next, plys do
			ply:ConCommand("mingeban cmd " .. cmd)
		end
	end
end)
cexec:AddArgument(ARGTYPE_PLAYERS)
cexec:AddArgument(ARGTYPE_STRING)
	:SetName("command")

-- kick

local kick = mingeban.CreateCommand("kick", function(caller, line, ply, reason)
	local reason = reason or "byebye!!"
	mingeban.utils.print(mingeban.colors.Red,
		tostring(ply) .. "(" .. ply:SteamID() .. ")" ..
		" has been kicked" ..
		" by " .. (IsValid(caller) and tostring(caller) or "CONSOLE") ..
		" for reason: '" .. reason ..
		"'."
	)
	ply:Kick(reason)
end)
kick:AddArgument(ARGTYPE_PLAYER)
kick:AddArgument(ARGTYPE_STRING)
	:SetName("reason")
	:SetOptional(true)

-- rank

local rank = mingeban.CreateCommand("rank", function(caller, line, ply, rank)
	local rank = mingeban.GetRank(rank)
	if not rank then return false, "Rank doesn't exist" end
	-- if not caller:CheckUserGroupLevel(ply:GetUserGroup()) then return false, "Can't target players with a higher or similar rank than yours" end
	if type(caller):lower() == "player" then
		if not caller:CheckUserGroupLevel(rank.name) then return false, "Can't rank players to a higher or similar rank than yours" end
	end

	ply:SetUserGroup(rank.name)
	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " ranked " .. tostring(ply) .. " to '" .. rank.name .. "'.")
end)
rank:AddArgument(ARGTYPE_PLAYER)
rank:AddArgument(ARGTYPE_STRING)
	:SetName("rank")
rank:SetArgRankCheck(true)

-- map / restart

local restart = mingeban.CreateCommand("restart", function(caller, line, time)
	local txt = "Restart"
	mingeban.Countdown(time or 20, function()
		timer.Simple(1, function()
			-- hook.Run("ShutDown") -- isn't this unnecessary?
			game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
		end)
	end, txt)
	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " started countdown \"" .. txt .. "\"")
end)
restart:AddArgument(ARGTYPE_NUMBER)
	:SetName("time")
	:SetOptional(true)

local map = mingeban.CreateCommand("map", function(caller, line, map, time)
	map = map:gsub(".bsp", "")
	if not file.Exists("maps/" .. map .. ".bsp", "GAME") then return false, "Map doesn't exist" end

	local txt = "Changing map to \"" .. map .. "\""
	mingeban.Countdown(time or 20, function()
		timer.Simple(1, function()
			-- hook.Run("ShutDown") -- isn't this unnecessary?
			game.ConsoleCommand("changelevel " .. map .. "\n")
		end)
	end, txt)
	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " started countdown \"" .. txt .. "\"")
end)
map:AddArgument(ARGTYPE_STRING)
	:SetName("map")
map:AddArgument(ARGTYPE_NUMBER)
	:SetName("time")
	:SetOptional(true)

local resetmap = mingeban.CreateCommand({"resetmap", "cleanmap", "cleanupmap"}, function(caller, line, time)
	local txt = "Cleanup"
	mingeban.Countdown(time or 20, function()
		timer.Simple(1, function()
			game.ConsoleCommand("gmod_admin_cleanup\n")
		end)
	end, txt)
	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " started countdown \"" .. txt .. "\"")
end)
resetmap:AddArgument(ARGTYPE_NUMBER)
	:SetName("time")
	:SetOptional(true)

local clean = mingeban.CreateCommand({"clean", "cleanup"}, function(caller, line, plys)
	if prostasia and line:Trim():lower() == "#disconnected" then
		for sid in next, prostasia.Disconnected do
			prostasia.Disconnected[sid] = 0
		end
		mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " cleaned up stuff from disconnected players.")
		return
	end

	local plys = mingeban.utils.findPlayer(plys)
	if #plys < 1 then
		return false, "Couldn't find any players."
	end

	local plyName
	if #plys < 2 then
		plys[1]:ConCommand("gmod_cleanup")
		plyName = tostring(plys[1])
	else
		plyName = {}
		for _, ply in next, plys do
			ply:ConCommand("gmod_cleanup")
			plyName[#plyName + 1] = tostring(ply)
		end
	end
	local str = istable(plyName) and "{" .. table.concat(plyName, ", ") .. "}" or plyName
	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " cleaned up stuff from \"" .. str .. "\"")
end)
clean:AddArgument(ARGTYPE_STRING)

local PLAYER = FindMetaTable("Player")

hook.Add("Initialize", "mingeban_restrictions", function()
	if PLAYER.CheckLimit then
		PLAYER._CheckLimit = PLAYER._CheckLimit or PLAYER.CheckLimit
		function PLAYER:CheckLimit(str)
			if self.Unrestricted then return true end
			return self:_CheckLimit(str)
		end
	end
end)
if istable(GAMEMODE) then
	hook.GetTable().Initialize["mingeban_restrictions"]()
end

local restrictions = mingeban.CreateCommand("restrictions", function(caller, line, b)
	caller.Unrestricted = not b
	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " turned restrictions " .. (b and "on" or "off") .. " for themselves")
end)
restrictions:AddArgument(ARGTYPE_BOOLEAN)
restrictions:SetAllowConsole(false)

local defaultWeapons = {
	["weapon_357"] = true,
	["weapon_ar2"] = true,
	["weapon_bugbait"] = true,
	["weapon_crossbow"] = true,
	["weapon_crowbar"] = true,
	["weapon_frag"] = true,
	["weapon_physcannon"] = true,
	["weapon_pistol"] = true,
	["weapon_rpg"] = true,
	["weapon_shotgun"] = true,
	["weapon_slam"] = true,
	["weapon_smg1"] = true,
	["weapon_stunstick"] = true
}
local give = mingeban.CreateCommand("give", function(caller, line, plys, wep)
	if not weapons.Get(wep) and not defaultWeapons[wep] then
		wep = "weapon_" .. wep
	end
	if not weapons.Get(wep) and not defaultWeapons[wep] then
		return false, "Invalid weapon"
	end

	--[[ if #plys < 2 then
		local ply = plys[1]
		ply:Give(wep)
		ply:SelectWeapon(wep)
	else ]]
	for _, ply in next, plys do
		ply:Give(wep)
		ply:SelectWeapon(wep)
	end
	-- end
end)
give:AddArgument(ARGTYPE_PLAYERS)
give:AddArgument(ARGTYPE_STRING)
	:SetName("weapon_class")

local fire = mingeban.CreateCommand("fire", function(caller, line)
	local ent = caller:GetEyeTrace().Entity
	if IsValid(ent) then
		ent:Fire(line)
	end
end)
fire:SetAllowConsole(false)

-- freeze / unfreeze
-- maybe should add a print?
local freeze = mingeban.CreateCommand("freeze", function(caller, line, ply)
	ply:Freeze(true)
end)
freeze:AddArgument(ARGTYPE_PLAYER)


local unfreeze = mingeban.CreateCommand("unfreeze", function(caller, line, ply)
	ply:Freeze(false)
end)
unfreeze:AddArgument(ARGTYPE_PLAYER)

-- ban / unban

local function calcTime(time)
	local timeNum = 0
	local timeInput = false
	for amt, unit in time:gmatch("(%d+)(%a)") do
		if unit == "M" then
			timeNum = timeNum + (86400 * 30) * amt
		elseif unit == "d" then
			timeNum = timeNum + 86400 * amt
		elseif unit == "h" then
			timeNum = timeNum + 3600 * amt
		elseif unit == "m" then
			timeNum = timeNum + 60 * amt
		elseif unit == "s" then
			timeNum = timeNum + amt
		end
		timeInput = true
	end

	return timeInput, timeNum
end

local ban = mingeban.CreateCommand("ban", function(caller, line, ply, time, reason)
	local foundPlayer = false
	if not mingeban.utils.validSteamID(ply) then
		local results = mingeban.utils.findPlayer(ply)
		if results[1] then
			ply = results[1]
			foundPlayer = true
		end
	end
	if not foundPlayer then
		ply = ply:upper():Trim()
	end

	local ok, timeNum = calcTime(time)
	if not ok then
		return false, "Incorrect time"
	end

	local reason = reason or "byebye!!"
	mingeban.utils.print(mingeban.colors.Red,
		tostring(ply) .. (foundPlayer and " (" .. ply:SteamID() .. ")" or "") ..
		" has been banned " ..
		(timeNum == 0 and "permanently" or "for " .. string.NiceTime(timeNum)) ..
		" by " .. (IsValid(caller) and tostring(caller) or "CONSOLE") ..
		" for reason: '" .. reason ..
		"'."
	)
	mingeban.Ban(ply, timeNum, reason)
	if foundPlayer then
		ply:Kick(reason)
	end
end)
ban:AddArgument(ARGTYPE_STRING)
	:SetName("player/steamid")
ban:AddArgument(ARGTYPE_STRING)
	:SetName("time")
ban:AddArgument(ARGTYPE_STRING)
	:SetName("reason")
	:SetOptional(true)

local unban = mingeban.CreateCommand("unban", function(caller, line, ply)
	ply = ply:upper():Trim()
	if not mingeban.utils.validSteamID(ply) then return false, "Invalid SteamID" end

	mingeban.utils.print(mingeban.colors.Cyan, (IsValid(caller) and tostring(caller) or "CONSOLE") .. " unbanned " .. tostring(ply) .. ".")
	mingeban.Unban(ply)
end)
unban:AddArgument(ARGTYPE_STRING)
	:SetName("steamid")

if banni then
	local bbaann = mingeban.CreateCommand("banni", function(caller, line, ply, time, reason)
		local foundPlayer = false
		if not mingeban.utils.validSteamID(ply) then
			local results = mingeban.utils.findPlayer(ply)
			if results[1] then
				ply = results[1]
				foundPlayer = true
			end
		end
		if not foundPlayer then
			ply = ply:upper():Trim()
		end

		local ok, timeNum = calcTime(time)
		if not ok then
			return false, "Incorrect time"
		end

		local reason = reason or "No reason specified"

		mingeban.utils.print(mingeban.colors.Red,
			tostring(ply) .. (foundPlayer and " (" .. ply:SteamID() .. ")" or "") ..
			" has been banni'd " ..
			(timeNum == 0 and "permanently" or "for " .. string.NiceTime(timeNum)) ..
			" by " .. (IsValid(caller) and tostring(caller) or "CONSOLE") ..
			" for reason: '" .. reason ..
			"'."
		)
		banni.ban(IsValid(caller) and caller:SteamID() or "CONSOLE", type(ply) == "string" and ply or ply:SteamID(), timeNum, reason)
	end)
	bbaann:AddArgument(ARGTYPE_STRING)
		:SetName("player/steamid")
	bbaann:AddArgument(ARGTYPE_STRING)
		:SetName("time")
	bbaann:AddArgument(ARGTYPE_STRING)
		:SetName("reason")
		:SetOptional(true)

	local unbbaann = mingeban.CreateCommand("unbanni", function(caller, line, ply, reason)
		local foundPlayer = false
		if not mingeban.utils.validSteamID(ply) then
			local results = mingeban.utils.findPlayer(ply)
			if results[1] then
				ply = results[1]
				foundPlayer = true
			end
		end
		if not foundPlayer then
			ply = ply:upper():Trim()
		end

		local reason = reason or "No reason specified"
		mingeban.utils.print(mingeban.colors.Cyan,
			tostring(caller) ..
			" unbanni'd " ..
			tostring(ply) .. (foundPlayer and " (" .. ply:SteamID() .. ")" or "") ..
			" with reason: '" .. reason ..
			"'."
		)
		banni.unban(IsValid(caller) and caller:SteamID() or "CONSOLE", type(ply) == "string" and ply or ply:SteamID(), reason)
	end)
	unbbaann:AddArgument(ARGTYPE_STRING)
		:SetName("player/steamid")
	unbbaann:AddArgument(ARGTYPE_STRING)
		:SetName("reason")
		:SetOptional(true)
end

local ok = pcall(require, "cvarsx")
if ok then
	local cheats = mingeban.CreateCommand("cheats", function(caller, line, b)
		caller:SetConVarValue("sv_cheats", b and "1" or "0")
		caller:SendLua([[surface.PlaySound("common/warning.wav")]]) -- lazy
		caller:Notify("sv_cheats turned " .. (b and "on" or "off") .. ".", NOTIFY_HINT, 5)
	end)
	cheats:AddArgument(ARGTYPE_BOOLEAN)
	cheats:SetAllowConsole(false)
end

--[[ server stays dead with _restart rip

mingeban.CreateCommand("reboot",function(caller)
	if not caller:IsAdmin() then return end
	game.ConsoleCommand("_restart\n")
end)

]]

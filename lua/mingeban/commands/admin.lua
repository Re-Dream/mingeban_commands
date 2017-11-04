
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
		" by " .. tostring(caller) ..
		" for reason: '" .. reason ..
		"'."
	)
	ply:Kick(reason)
end)
kick:AddArgument(ARGTYPE_PLAYER)
kick:AddArgument(ARGTYPE_STRING)
	:SetName("reason")
	:SetOptional(true)

-- ban / unban

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

	local timeNum = 0
	local timeInput = false
	for months in time:gmatch("(%d+)M") do
		timeNum = timeNum + (86400 * 30) * months
		timeInput = true
	end
	for days in time:gmatch("(%d+)d") do
		timeNum = timeNum + 86400 * days
		timeInput = true
	end
	for hours in time:gmatch("(%d+)h") do
		timeNum = timeNum + 3600 * hours
		timeInput = true
	end
	for minutes in time:gmatch("(%d+)m") do
		timeNum = timeNum + 60 * minutes
		timeInput = true
	end
	for seconds in time:gmatch("(%d+)s") do
		timeNum = timeNum + seconds
		timeInput = true
	end
	if not timeInput then
		return false, "Incorrect time"
	end

	local reason = reason or "byebye!!"
	mingeban.utils.print(mingeban.colors.Red,
		tostring(ply) .. (foundPlayer and "(" .. ply:SteamID() .. ")" or "") ..
		" has been banned " ..
		(timeNum == 0 and "permanently" or "for " .. string.NiceTime(timeNum)) ..
		" by " .. tostring(caller) ..
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

	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " unbanned " .. tostring(ply) .. ".")
	mingeban.Unban(ply)
end)
unban:AddArgument(ARGTYPE_STRING)
	:SetName("steamid")

-- rank

local rank = mingeban.CreateCommand("rank", function(caller, line, ply, rank)
	local ok, err = pcall(function()
		ply:SetUserGroup(rank)
	end)
	if ok then
		mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " ranked " .. tostring(ply) .. " to '" .. rank .. "'.")
	else
		ErrorNoHalt(err)
	end
	return ok, err
end)
rank:AddArgument(ARGTYPE_PLAYER)
rank:AddArgument(ARGTYPE_STRING)
	:SetName("rank")

-- map / restart

local restart = mingeban.CreateCommand("restart", function(caller, line, time)
	local txt = "Restart"
	mingeban.Countdown(time or 20, function()
		timer.Simple(1, function()
			game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
		end)
	end, txt)
	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " started countdown \"" .. txt .. "\"")
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
			game.ConsoleCommand("changelevel " .. map .. "\n")
		end)
	end, txt)
	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " started countdown \"" .. txt .. "\"")
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
	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " started countdown \"" .. txt .. "\"")
end)
resetmap:AddArgument(ARGTYPE_NUMBER)
	:SetName("time")
	:SetOptional(true)

local clean = mingeban.CreateCommand({"clean", "cleanup"}, function(caller, line, plys)
	if #plys < 2 then
		plys[1]:ConCommand("gmod_cleanup")
	else
		for _, ply in next, plys do
			ply:ConCommand("gmod_cleanup")
		end
	end
	mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " cleaned up stuff from \"" .. table.ToString(plys) .. "\"")
end)
clean:AddArgument(ARGTYPE_PLAYERS)

local PLAYER = FindMetaTable("Player")

hook.Add("Initialize", "mingeban-restrictions", function()
	if PLAYER.CheckLimit then
		PLAYER._CheckLimit = PLAYER._CheckLimit or PLAYER.CheckLimit
		function PLAYER:CheckLimit(str)
			if self.Unrestricted then return true end
			return self:_CheckLimit(str)
		end
	end
end)
if istable(GAMEMODE) then
	hook.GetTable().Initialize["mingeban-restrictions"]()
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
	if not weapons.Get(wep) then
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

if banni then
	local function calcTime(time)
		local timeNum = 0
		local timeInput = false
		for months in time:gmatch("(%d+)M") do
			timeNum = timeNum + (86400 * 30) * months
			timeInput = true
		end
		for days in time:gmatch("(%d+)d") do
			timeNum = timeNum + 86400 * days
			timeInput = true
		end
		for hours in time:gmatch("(%d+)h") do
			timeNum = timeNum + 3600 * hours
			timeInput = true
		end
		for minutes in time:gmatch("(%d+)m") do
			timeNum = timeNum + 60 * minutes
			timeInput = true
		end
		for seconds in time:gmatch("(%d+)s") do
			timeNum = timeNum + seconds
			timeInput = true
		end

		return timeInput,timeNum
	end

	local bbaann = mingeban.CreateCommand("banni", function(caller,line,stid,time,reason)
		local success,tm = calcTime(time)

		if not success then
			return false,"Incorrect time!"
		end

		local ply = mingeban.utils.findPlayer(stid)[1]

		local steamid = IsValid(caller) and caller:SteamID() or "Server"
		banni.ban(steamid,(IsValid(ply) and ply:SteamID() or stid),tm,reason)
	end)
	bbaann:AddArgument(ARGTYPE_STRING)
	bbaann:AddArgument(ARGTYPE_STRING)
	bbaann:AddArgument(ARGTYPE_STRING)

	local unbbaann = mingeban.CreateCommand("unbanni", function(caller,line,stid,reason)
		local steamid = IsValid(caller) and caller:SteamID() or "Server"
		
		local ply = mingeban.utils.findPlayer(stid)[1]
		
		banni.unban(steamid,(IsValid(ply) and ply:SteamID() or stid),reason)
	end)
	unbbaann:AddArgument(ARGTYPE_STRING)
	unbbaann:AddArgument(ARGTYPE_STRING)

	mingeban.GetRank("admin"):AddPermission("command.banni")
	mingeban.GetRank("admin"):AddPermission("command.unbanni")	
end

--[[ server stays dead with _restart rip

mingeban.CreateCommand("reboot",function(caller)
	if not caller:IsAdmin() then return end
	game.ConsoleCommand("_restart\n")
end)

]]

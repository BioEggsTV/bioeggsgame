-- ServerScriptService/ServerMain/MiscModule

--[[
	Script By: BioEggsHD
	Handles miscellaneous player data
]]--

--// VARIABLES //--

local SESSION_START: {[number]: number} = {} -- [user_id]: os.time() at session start

--// MODULE //--

local MiscModule = {}

--- Private

-- Allocate misc data reference for a player
local function _Allocate(user_id: number, player_data: {[string]: any})
	local misc = player_data._misc

	if misc.FirstTimeJoined == nil then
		misc.FirstTimeJoined = os.time()
	end

	misc.TimesJoined += 1
	SESSION_START[user_id] = os.time()
end

-- Remove misc allocation
local function _Wipe(user_id: number)
	SESSION_START[user_id] = nil
end

--- Public

-- Initialize misc data for a player
function MiscModule.CreateMisc(user_id: number, player_data: {[string]: any})
	if not player_data._misc then
		warn(string.format("MiscModule/ERROR: no _misc key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data)
end

-- Add elapsed time to playtime
function MiscModule.UpdatePlaytime(user_id: number, player_data: {[string]: any})
	local session_start = SESSION_START[user_id]
	if not session_start then
		warn(string.format("MiscModule/ERROR: no session start recorded for user: %i", user_id))
		return
	end

	if not player_data or not player_data._misc then
		warn(string.format("MiscModule/ERROR: no _misc data found for user: %i", user_id))
		return
	end

	local elapsed = os.time() - session_start
	player_data._misc.Playtime += elapsed

	SESSION_START[user_id] = os.time()
end

-- Remove misc allocation for a player
function MiscModule.RemoveMisc(user_id: number)
	_Wipe(user_id)
end

-- Get a misc stat for a player
function MiscModule.GetStat(user_id: number, player_data: {[string]: any}, stat_name: string): any --> stat value
	if not player_data or not player_data._misc then
		warn(string.format("MiscModule/ERROR: no _misc data found for user: %i", user_id))
		return nil
	end

	local value = player_data._misc[stat_name]
	if value == nil then
		warn(string.format("MiscModule/ERROR: no such stat \"%s\" for user: %i", stat_name, user_id))
	end

	return value
end

return MiscModule

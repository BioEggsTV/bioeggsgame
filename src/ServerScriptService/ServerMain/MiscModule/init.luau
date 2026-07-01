-- ServerScriptService/ServerMain/MiscModule

--[[
	Script By: BioEggsHD
	Handles miscellaneous player data
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local SESSION_START: {[number]: number} = {} -- [user_id]: os.time() at session start
local PLAYTIME_UPDATE_THREADS: {[number]: thread} = {} -- [user_id]: playtime update thread

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
	local playtime_thread: thread? = PLAYTIME_UPDATE_THREADS[user_id]
	if playtime_thread then
		task.cancel(playtime_thread)
	end
	PLAYTIME_UPDATE_THREADS[user_id] = nil
end

-- Add elapsed time to playtime
local function _UpdatePlaytime(user_id: number, player_data: {[string]: any})
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

--- Public

-- Initialize misc data for a player
function MiscModule.OnPlayerAdded(player: Player, player_data: {[string]: any})
	local user_id: number = player.UserId
	if not player_data._misc then
		warn(string.format("MiscModule/ERROR: no _misc key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data)

	-- Update playtime every 60 seconds
	PLAYTIME_UPDATE_THREADS[user_id] = task.spawn(function()
		local player: Player = game:GetService("Players"):GetPlayerByUserId(user_id)
		while player and player.Parent do
			task.wait(60)
			if player and player.Parent then
				_UpdatePlaytime(user_id, player_data)
			end
		end
	end)
end

-- Remove misc allocation for a player
function MiscModule.OnPlayerRemoving(user_id: number, player_data: {[string]: any})
	_UpdatePlaytime(user_id, player_data)
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

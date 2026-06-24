-- ServerScriptService/ServerMain/LeaderstatsModule

--[[
	Script By: BioEggsHD
	Handles player leaderstats
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

-- Holds references to players _leaderstats directory inside PLAYER_DATA
local LEADERSTATS: {[number]: {[string]: any}} = {} -- [user_id]: _leaderstats reference

--// MODULE //--

local LeaderstatsModule = {}

--- Private

-- Update or create player leaderstats folder based on the leaderstats directory
local function _UpdatePlayerLeaderstats(user_id: number)
	local player: Player? = Players:GetPlayerByUserId(user_id)
	if not player then return end
	if not LEADERSTATS[user_id] then return end

	local leaderstats_folder = player:FindFirstChild("leaderstats")
	if not leaderstats_folder then
		leaderstats_folder = Instance.new("Folder")
		leaderstats_folder.Name = "leaderstats"
		leaderstats_folder.Parent = player
	end

	for stat_name, value in LEADERSTATS[user_id] do
		local value_instance = leaderstats_folder:FindFirstChild(stat_name)
		if value_instance then
			value_instance.Value = value
		else
			if typeof(value) == "number" then
				value_instance = Instance.new("NumberValue")
			elseif typeof(value) == "string" then
				value_instance = Instance.new("StringValue")
			elseif typeof(value) == "boolean" then
				value_instance = Instance.new("BoolValue")
			end
			if value_instance then
				value_instance.Name   = stat_name
				value_instance.Value  = value
				value_instance.Parent = leaderstats_folder
			end
		end
	end
end

-- Allocate leaderstats reference for a player
local function _Allocate(user_id: number, leaderstats: {[string]: any})
	if LEADERSTATS[user_id] ~= nil then
		local player = Players:GetPlayerByUserId(user_id)
		local user_name = player and player.Name or "Unknown"
		warn(string.format("LeaderstatsModule/WARNING: updating already existing leaderstat allocation for player: %s, %i", user_name, user_id))
	end
	LEADERSTATS[user_id] = leaderstats
end

-- Remove players leaderstats allocation
local function _Wipe(user_id: number)
	LEADERSTATS[user_id] = nil
end

-- Increment a players stat inside of its leaderstats directory
local function _IncrementNumber(user_id: number, stat_name: string, value: number)
	if not LEADERSTATS[user_id] then return end
	local current_value = LEADERSTATS[user_id][stat_name]
	if current_value and typeof(current_value) == "number" then
		LEADERSTATS[user_id][stat_name] += value
		_UpdatePlayerLeaderstats(user_id)
	end
end

-- Update a players stat inside of its leaderstats directory
local function _UpdateStat(user_id: number, stat_name: string, new_value: any)
	if not LEADERSTATS[user_id] then return end
	local current_value = LEADERSTATS[user_id][stat_name]
	if current_value ~= nil and typeof(current_value) == typeof(new_value) then
		LEADERSTATS[user_id][stat_name] = new_value
		_UpdatePlayerLeaderstats(user_id)
	end
end

--- Public

-- Create player leaderstats directory using player_data (from ServerMain)
function LeaderstatsModule.CreateLeaderstats(user_id: number, player_data: {[string]: any})
	if not player_data._leaderstats then
        warn(string.format("LeaderstatsModule/ERROR: no _leaderstats key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data._leaderstats)
	_UpdatePlayerLeaderstats(user_id)
end

-- Remove the players leaderstats directory
function LeaderstatsModule.RemoveLeaderstats(user_id: number)
	_Wipe(user_id)
end

LeaderstatsModule.IncrementNumber = _IncrementNumber

LeaderstatsModule.UpdateStat = _UpdateStat

return LeaderstatsModule

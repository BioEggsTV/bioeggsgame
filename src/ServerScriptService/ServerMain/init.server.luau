-- ServerScriptService/ServerMain

--[[
	Script By: BioEggsHD
	Coordinates all child modules and handles player events
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local BansModule = require(script.BansModule)
local DataModule = require(script.DataModule)

local _is_shutting_down: boolean = false
local _auto_save_thread: thread

type PlayerCallback: (player: Player | number, player_data: {[string]: any}) -> ()
local OnPlayerAddedFunctions: {PlayerCallback} = {}
local OnPlayerRemovingFunctions: {PlayerCallback} = {}
local OnServerStartFunctions: {() -> ()} = {}

--// Functions //--PlayerRemovingHooks

--- Utility

-- Add all module player adding / removing functions to the tables
local function _DiscoverModules()
	for _, child in script:GetDescendants() do
		if child:IsA("ModuleScript") and child ~= DataModule and child ~= BansModule then
			local success, module = pcall(require, child)
			if success and typeof(module) == "table" then
				if typeof(module.OnPlayerAdded) == "function" then
					table.insert(OnPlayerAddedFunctions, module.OnPlayerAdded)
				end
				
				if typeof(module.OnPlayerRemoving) == "function" then
					table.insert(OnPlayerRemovingFunctions, module.OnPlayerRemoving)
				end

				if typeof(module.OnServerStart) == "function" then
					table.insert(OnServerStartFunctions, module.OnServerStart)
				end
			end
		end
	end
end

-- Cleanup player
local function _CleanupPlayer(user_id: number)
	local player_data = DataModule.GetCachedData(user_id)
	for _, callback: PlayerCallback in OnPlayerRemovingFunctions do
		pcall(callback, user_id, player_data)
	end

	if player_data then
		DataModule.SaveData(user_id, true)
	end
end

--- Callback

function OnPlayerAdded(player: Player)
	local user_name: string, user_id: number = player.Name, player.UserId
	print(string.format("ServerMain/Player added: %s, %i", user_name, user_id))

	-- Check if player is banned
	task.spawn(BansModule.OnPlayerAdded, player)
	
	-- Load all player data
	local player_data = DataModule.GetData(user_id) -- Reference inside DataModule
	if not player_data then return end

	task.spawn(function()
		for _, callback: PlayerCallback in OnPlayerAddedFunctions do
			local success, errormessage = pcall(callback, player, player_data)
			if not success then
				warn(string.format("ServerMain/ERROR: Error during initialization for user %i: %s", user_id, tostring(errormessage)))
			end
		end

		-- Check if player left during initialization
		if not Players:GetPlayerByUserId(user_id) then
			_CleanupPlayer(user_id)
		end
	end)
end

function OnPlayerRemoving(player: Player)
	if _is_shutting_down then return end -- Skip if BindToClose already handled cleanup
	_CleanupPlayer(player.UserId)
end

--// MAIN //--

_DiscoverModules()

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, callback: () -> () in OnServerStartFunctions do
	pcall(callback)
end

_auto_save_thread = DataModule.StartAutoSave()

game:BindToClose(function()
	_is_shutting_down = true

	local players = Players:GetPlayers()
	local remaining = #players
	if remaining == 0 then return end
	task.cancel(_auto_save_thread)

	local running_thread = coroutine.running()

	for _, player: Player in players do
		task.spawn(function()
			pcall(_CleanupPlayer, player.UserId)
			remaining -= 1
			if remaining == 0 then
				task.spawn(running_thread)
			end
		end)
	end

	coroutine.yield()
end)
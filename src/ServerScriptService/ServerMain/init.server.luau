-- ServerScriptService/ServerMain

--[[
	Script By: BioEggsHD
	Coordinates all descendant modules and handles player events
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

-- Modules
local AdminModule = require(script:FindFirstChild("AdminModule"))
local BansModule = require(script:FindFirstChild("BansModule"))
local DataModule = require(script:FindFirstChild("DataModule"))
local InventoryModule = require(script:FindFirstChild("InventoryModule"))
local LeaderstatsModule = require(script:FindFirstChild("LeaderstatsModule"))
local MiscModule = require(script:FindFirstChild("MiscModule"))

local _is_shutting_down: boolean = false

--// Functions //--

--- Utility

-- Formats a seconds value into a one decimal hour string
local function _FormatSecondsToHour(seconds: number)
	return tostring(math.floor(seconds / 3600 * 10) / 10) .. "h"
end

-- Cleanup player
local function _CleanupPlayer(user_id: number)
	local player_data = DataModule.GetData(user_id)
	if not player_data then
		-- Data was never loaded
		MiscModule.RemoveMisc(user_id)
		LeaderstatsModule.RemoveLeaderstats(user_id)
		InventoryModule.RemoveInventory(user_id)
		return
	end

	-- Finalize misc stats before saving
	MiscModule.UpdatePlaytime(user_id, player_data)
	MiscModule.OnPlayerRemoving(user_id)

	-- Save all player data, releasing the session lock
	DataModule.SaveData(user_id, true)

	-- Clean up all module directories
	MiscModule.RemoveMisc(user_id)
	LeaderstatsModule.RemoveLeaderstats(user_id)
	InventoryModule.RemoveInventory(user_id)
end

--- Callback

function OnPlayerAdded(player: Player)
	local user_name: string, user_id: number = player.Name, player.UserId
	print(string.format("ServerMain/Player added: %s, %i", user_name, user_id))

	-- Add admin ui if the player is an admin
	local is_admin = AdminModule.AddAdminUI(user_id)

	-- Check if the player is banned (bypassed by admins)
	if not is_admin then
		local ban_data = BansModule.GetData(user_id)
		if ban_data == nil then
			warn(string.format("ServerMain/ERROR: Failed getting ban data for user: %s, %i", user_name, user_id))
			return
		end
		if ban_data and ban_data ~= "NO_DATA" then
			if ban_data.is_banned == true then
				print(string.format("ServerMain/Kicking banned player: %s, %i", user_name, user_id))
				player:Kick(string.format(
					"You were banned from this game.\nRemaining time: %s\nReason: %s",
					_FormatSecondsToHour(ban_data.banned_until - os.time()),
					ban_data.reason
				))
				return
			else
				if ban_data.banned_until ~= 0 and ban_data.banned_until <= os.time() then
					BansModule.UnbanPlayer(user_id)
				end
			end
		end
	end

	-- Load all player data
	local player_data = DataModule.GetData(user_id)
	if not player_data then return end

	-- Initialize all modules
	MiscModule.CreateMisc(user_id, player_data)
	LeaderstatsModule.CreateLeaderstats(user_id, player_data)
	InventoryModule.CreateInventory(user_id, player_data)

	-- Update playtime every 60 seconds
	task.spawn(function()
		while player.Parent do
			task.wait(60)
			if player.Parent then
				MiscModule.UpdatePlaytime(user_id, player_data)
				DataModule.SaveData(user_id, false)
			end
		end
	end)
end

function OnPlayerRemoving(player: Player)
	-- Skip if BindToClose already handled this player
	if _is_shutting_down then return end

	local user_id = player.UserId
	_CleanupPlayer(user_id)
end

--// EVENTS //--

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

game:BindToClose(function()
	-- Avoid that PlayerRemoving events fire
	_is_shutting_down = true

	local cleanup_threads = {}
	for _, player in Players:GetPlayers() do
		local thread = task.spawn(_CleanupPlayer, player.UserId)
		table.insert(cleanup_threads, thread)
	end
end)

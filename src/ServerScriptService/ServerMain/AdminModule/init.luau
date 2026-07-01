-- ServerScriptService/ServerMain/AdminModule

--[[
	Script By: BioEggsHD
	Admin utility for players
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local GAME_GROUP: number = 14664496

local AdminUI = script.AdminUI

--// MODULE //--

local AdminModule = {}

--- Private

-- Check if a player is an admin using their user id
local function _IsPlayerAdmin(player: Player): boolean
    local success, result = pcall(function()
        local role = player:GetRoleInGroupAsync(GAME_GROUP)
        return role == "Owner" or role == "Admin"
    end)
    return success and result
end

-- Add the admin ui to the players interface if they are admin
local function _AddAdminUI(player: Player)
	if not _IsPlayerAdmin(player) then return end
	
	local user_id: number = player.UserId

	local player_gui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	if player_gui then
		local new_admin_ui = AdminUI:Clone()
		new_admin_ui.Parent = player_gui
	else
        warn(string.format("ERROR: AdminModule/failed to find PlayerGui for player: %s", player.Name))
	end

	return
end

--- Public

function AdminModule.OnPlayerAdded(player: Player)
	_AddAdminUI(player)
end

return AdminModule

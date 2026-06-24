-- ServerScriptService/ServerMain/AdminModule

--[[
	Script By: BioEggsHD
	Admin utility for players
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local ADMIN_WHITELIST: {[number]: boolean} = {
	[1210462714] = true, -- Aqwertz333 (BioEggsHD),
	[5767632793] = true, -- RichtiginderRitze (Winevobro)
}

local AdminUI = script:WaitForChild("AdminUI")

--// MODULE //--

local AdminModule = {}

--- Private

-- Check if a player is an admin using their user id
local function IsPlayerAdmin(user_id: number): boolean
	return (ADMIN_WHITELIST[user_id] == true)
end

--- Public

-- Add the admin ui to the players interface, if they are admin
function AdminModule.AddAdminUI(user_id: number): boolean
	local player: Player = Players:GetPlayerByUserId(user_id)
	if player then
		if not IsPlayerAdmin(user_id) then return false end

		local player_gui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
		if player_gui then
			local new_admin_ui = AdminUI:Clone()
			new_admin_ui.Parent = player_gui
		else
            warn(string.format("ERROR: AdminModule/failed to find PlayerGui for player: %s", player.Name))
		end

		return true
	end

    warn(string.format("ERROR: AdminModule/failed to find Player instance for user id: %i", user_id))
	return false
end

return AdminModule

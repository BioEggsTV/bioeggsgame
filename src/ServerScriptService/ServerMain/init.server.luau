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

--// Functions //--

--- Utility

-- Formats a seconds value into a one decimal hour string
local function _FormatSecondsToHour(seconds: number)
    return tostring(math.floor(seconds / 360) / 10) .. "h"
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
                player:Kick(string.format("You were banned from this game.\nRemaining time: %s\nReason: %s", _FormatSecondsToHour(ban_data.banned_until - os.time()), ban_data.reason))
                return
            else
                if ban_data.banned_until <= os.time() then
                    BansModule.UnbanPlayer(user_id)
                end
            end
        end
    end

    -- Get saved data
    local leaderstats_data = DataModule.GetData(user_id, "_leaderstats")
    if not leaderstats_data then return end
    local inventory_data = DataModule.GetData(user_id, "_inventory")
    if not inventory_data then return end

    -- Create leaderstats
    LeaderstatsModule.CreateLeaderstats(user_id, leaderstats_data)
end

function OnPlayerRemoving(player: Player)
    
end

--// EVENTS //--

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
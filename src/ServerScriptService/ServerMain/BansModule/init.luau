-- ServerScriptService/ServerMain/BansModule

--[[
    Script By: BioEggsHD
    Handles banning of players
]]--

--// SERVICES //--

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

--// VARIABLES //--

local BansDataStore = DataStoreService:GetDataStore("BansDataStore")

--// MODULE //--

local BansModule = {}

--- Private

-- Formats a seconds value into a one decimal hour string
local function _FormatSecondsToHour(seconds: number): string --> the formatted string
	return tostring(math.floor(seconds / 3600 * 10) / 10) .. "h"
end

-- Get players saved ban data (if it exists)
local function _GetData(user_id: number): any --> user ban data
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            local data = BansDataStore:GetAsync(tostring(user_id))
            if data == nil then
                return "NO_DATA"
            else
                return data
            end
        end)
        if success then
            return result
        end
        warn(string.format("BansModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end
    warn(string.format("BansModule/ERROR: Kicking player after fail to retrieve data after 3 attempts: %i", user_id))
    local player = Players:GetPlayerByUserId(user_id)
    if player then
        player:Kick("Roblox data stores are down. Please try rejoining later.")
    end
    return nil
end

-- Ban a player
local function _BanPlayer(user_id: number, duration_hours: number, reason: string, banned_by: string): boolean --> whether ban succeeded
    local new_data = {
        is_banned = true,
        banned_at = os.time(),
        banned_until = (duration_hours == 0) and 0 or (os.time() + duration_hours * 3600),
        banned_by = banned_by,
        reason = reason
    }
    
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            BansDataStore:UpdateAsync(tostring(user_id), function(old_data)
                return new_data
            end)
        end)
        if success then
            return true
        end
        warn(string.format("BansModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end
    warn(string.format("BansModule/ERROR: Failed to ban player after 3 attempts: %i", user_id))
    return false
end

-- Unban a player
local function _UnbanPlayer(user_id: number): boolean --> whether unban succeeded
    local new_data = {
        is_banned = false,
        banned_at = 0,
        banned_until = 0,
        banned_by = "",
        reason = ""
    }
    
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            BansDataStore:UpdateAsync(tostring(user_id), function(old_data)
                return new_data
            end)
        end)
        if success then
            return true
        end
        warn(string.format("BansModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end
    warn(string.format("BansModule/ERROR: Failed to ban player after 3 attempts: %i", user_id))
    return false
end

--- Public

BansModule.GetData = _GetData

BansModule.BanPlayer = _BanPlayer

BansModule.UnbanPlayer = _UnbanPlayer

function BansModule.OnPlayerAdded(player: Player)
    local user_id: number, user_name: string = player.UserId, player.Name
    local ban_data = _GetData(user_id)
	if ban_data == nil then
		warn(string.format("ServerMain/ERROR: Failed getting ban data for user: %s, %i", user_name, user_id))
		return
	end
    if ban_data.banned_until ~= 0 and ban_data.banned_until <= os.time() then
		_UnbanPlayer(user_id)
	else
	    if ban_data and ban_data ~= "NO_DATA" then
		    if ban_data.is_banned == true then
			    print(string.format("ServerMain/Kicking banned player: %s, %i", user_name, user_id))
			    player:Kick(string.format(
			    	"You were banned from this game.\nRemaining time: %s\nReason: %s",
			    	_FormatSecondsToHour(ban_data.banned_until - os.time()),
			    	ban_data.reason
			    ))
		    end
	    end
    end
end

return BansModule

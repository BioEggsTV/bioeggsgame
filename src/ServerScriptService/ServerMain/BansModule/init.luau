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

-- Get players saved ban data (if it exists)
local function _GetData(user_id: number): any
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
    warn("BansModule/ERROR: Kicking player after fail to retrieve data after 3 attempts: " .. user_id)
    local player = Players:GetPlayerByUserId(user_id)
    if player then
        player:Kick("Roblox data stores are down. Please try rejoining later.")
    end
    return nil
end

-- Ban a player
local function _BanPlayer(user_id: number, duration_hours: number, reason: string, banned_by: string): boolean
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
    warn("BansModule/ERROR: Failed to update data after 3 attempts for user: " .. user_id)
    return false
end

-- Unban a player
local function _UnbanPlayer(user_id: number): boolean
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
    warn("BansModule/ERROR: Failed to update data after 3 attempts for user: " .. user_id)
    return false
end

--- Public

BansModule.GetData = _GetData

BansModule.BanPlayer = _BanPlayer

BansModule.UnbanPlayer = _UnbanPlayer

return BansModule

--[[

ban_data: {
    is_banned: boolean,
    banned_at: number,
    banned_until: number,
    banned_by: string,
    reason: string
}

]]--
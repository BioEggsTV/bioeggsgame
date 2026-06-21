-- ServerScriptService/ServerMain/DataModule

--[[

Script By: BioEggsHD
Handles loading / saving of player data

]]--

--// SERVICES //--

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

--// VARIABLES //--

local StatsDataStore = DataStoreService:GetDataStore("StatsDataStore")

local DEFAULT_DATA = {
    _leaderstats = function() return {
        Kills = 0,
        Wins = 0
    } end,
    _misc = function() return {
        FirstTimeJoined = os.time(),
        TimesJoined = 1,
        Playtime = 0
    } end,
    _inventory = function() return {
        CoinsPotion = {
            Count = 0
        },
        GemsPotion = {
            Count = 0
        }
    } end
}

--// MODULE //--

local DataModule = {}

--- Private

-- Attempt to retrieve saved data for a player
local function _GetData(user_id: number, suffix: string): any
    local data_generator: () -> {[string]: any}? = DEFAULT_DATA[suffix]
    if not data_generator then
        warn(string.format("DataModule/ERROR: Invalid data suffix requested: '%s'", tostring(suffix)))
        return nil
    end

    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            local data = StatsDataStore:GetAsync(tostring(user_id) .. suffix)
            local default_table = data_generator()
            if data == nil then
                return default_table
            else
                for stat_name: string, default_value: any in default_table do
                    if data[stat_name] == nil then 
                        data[stat_name] = default_value
                    end
                end 
                return data
            end
        end)
        if success then
            return result
        end
        warn(string.format("DataModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end
    warn("DataModule/ERROR: Kicking player after fail to retrieve data after 3 attempts: " .. tostring(user_id))
    local player = Players:GetPlayerByUserId(user_id)
    if player then
        player:Kick("Roblox data stores are down. Please try rejoining later.")
    end
    return nil
end

-- Attempt to update / save data for a player
local function _SaveData(user_id: number, new_data: {[string]: any}, suffix: string): boolean
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            StatsDataStore:UpdateAsync(tostring(user_id) .. suffix, function(old_data)
                return new_data
            end)
        end)
        if success then 
            return true 
        end
        warn(string.format("DataModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then 
            task.wait(2 ^ attempt)
        end 
    end
    warn("DataModule/ERROR: Failed to save data after 3 attempts for user: " .. tostring(user_id))
    return false
end

--- Public

DataModule.GetData = _GetData 

DataModule.SaveData = _SaveData 

return DataModule
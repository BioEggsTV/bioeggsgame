-- ServerScriptService/ServerMain/DataModule

--[[

Script By: BioEggsHD
Handles loading and saving of player data

]]--

--// SERVICES //--

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

--// VARIABLES //--

local MainDataStore = DataStoreService:GetDataStore("MainDataStore_v1")
local CURRENT_DATA_VERSION = 1

local PLAYER_DATA: {[number]: {[string]: any}} = {} -- [user_id]: full data table

--// MODULE //--

local DataModule = {}

--- Private

-- Deep copy a table
local function _DeepCopy(t: {[any]: any}): {[any]: any}
    local copy = {}
    for k, v in t do
        if type(v) == "table" then
            copy[k] = _DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function _GenerateDefaultData(): {[string]: any}
    return {
        Version = CURRENT_DATA_VERSION,
        SessionId = nil,
        _leaderstats = {
            Kills = 0,
            Wins = 0
        },

        _misc = {
            FirstTimeJoined = nil,
            TimesJoined = 0,
            Playtime = 0
        },

        _inventory = {
            CoinsPotion = {
                Count = 0
            },
            GemsPotion = {
                Count = 0
            }
        }
    }
end

-- Fill in any missing keys from template
local function _Reconcile(data: {[string]: any}, template: {[string]: any}): {[string]: any}
    for key, value in template do
        if data[key] == nil then
            if type(value) == "table" then
                data[key] = _DeepCopy(value)
            else
                data[key] = value
            end
        elseif type(data[key]) == "table" and type(value) == "table" then
            _Reconcile(data[key], value)
        end
    end
    return data
end

-- Migrate data across versions
local function _MigrateData(data: {[string]: any}): {[string]: any}
    if not data.Version then
        data.Version = 1
    end
    --[[ Future migrations:
        if data.Version == 1 then
            data._misc.NewStat = 0
            data.Version = 2
        end
    ]]--
    return data
end

--- Public

-- Return all player data, held by reference in PLAYER_DATA
function DataModule.GetData(user_id: number): {[string]: any}?
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            return MainDataStore:UpdateAsync(tostring(user_id), function(old_data)
                local data = old_data

                if data == nil then
                    data = _GenerateDefaultData()
                else
                    if data.SessionId and data.SessionId ~= game.JobId and game.JobId ~= "" then
                        error("DataModule/ERROR: session is currently locked by another server")
                    end
                end

                data = _Reconcile(data, _GenerateDefaultData())
                data = _MigrateData(data)
                data.SessionId = game.JobId

                return data
            end)
        end)

        if success and result then
            PLAYER_DATA[user_id] = result
            return result
        end

        warn(string.format("DataModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end

    warn(string.format("DataModule/ERROR: kicking player after fail to retrieve data after 3 attempts: %i", user_id))
    local player = Players:GetPlayerByUserId(user_id)
    if player then
        player:Kick("Roblox data stores are down or session is locked. Please try rejoining later.")
    end
    return nil
end

-- Save all player data
function DataModule.SaveData(user_id: number, release_session: boolean?): boolean
    local current_data = PLAYER_DATA[user_id]
    if not current_data then
        warn(string.format("DataModule/ERROR: no data in directory to save for user: %i", user_id))
        return false
    end

    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            MainDataStore:UpdateAsync(tostring(user_id), function(old_data)
                if old_data and old_data.SessionId and old_data.SessionId ~= game.JobId and game.JobId ~= "" then
                    error("DataModule/ERROR: session lock mismatch; cannot overwrite data from another server")
                end

                current_data.SessionId = if release_session then nil else game.JobId
                current_data.Version = CURRENT_DATA_VERSION

                return current_data
            end)
        end)

        if success then
            if release_session then
                PLAYER_DATA[user_id] = nil
            end
            return true
        end

        warn(string.format("DataModule/ERROR: DataStore failed (Attempt %d/3): %s", attempt, tostring(result)))
        if attempt < 3 then
            task.wait(2 ^ attempt)
        end
    end

    warn(string.format("DataModule/ERROR: failed to save data after 3 attempts for user: %i", user_id))
    return false
end

return DataModule

-- ServerScriptService/ServerMain/SettingsModule

--[[
    Script By: BioEggsHD
    Handles player settings / preferences
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

-- To validate data sent by client
local SETTINGS_TYPES = {
    RecieveRequests = "boolean"
}

-- Holds references to players _settings directory inside PLAYER_DATA
local SETTINGS: {[number]: {[string]: any}} = {} -- [user_id]: _settings reference

--// MODULE //--

local SettingsModule = {}

--- Private

local function _Allocate(user_id: number, settings: {[string]: any})
    if SETTINGS[user_id] then
		local player: Player? = Players:GetPlayerByUserId(user_id)
		local user_name = player and player.Name or "Unknown"
		warn(string.format("SettingsModule/WARNING: updating already existing data allocation for player: %s, %i", user_name, user_id))
	end
	SETTINGS[user_id] = settings
end

local function _Wipe(user_id: number)
    SETTINGS[user_id] = nil
end

local function _ModifySetting(user_id: number, setting_name: string, value: any)
    local directory: {[string]: any}? = SETTINGS[user_id]
    if not directory then
        warn(string.format("SettingsModule/ERROR: no player settings directory: %i", user_id))
        return
    end
    local intended_type: string? = SETTINGS_TYPES[setting_name]
    if not (directory[setting_name] and intended_type) then
        warn(string.format("SettingsModule/ERROR: no such setting \"%s\" to modify for: %i", setting_name, user_id))
        return
    end
    if typeof(value) ~= intended_type then
        warn(string.format("SettingsModule/ERROR: unintended type for setting \"%s\": expected %s, got %s: %i", setting_name, intended_type, typeof(value), user_id))
        return
    end
    directory[setting_name] = value
end

local function _GetSetting(user_id: number, setting_name: string): any --> user setting value
    local directory: {[string]: any}? = SETTINGS[user_id]
    if not directory then
        warn(string.format("SettingsModule/ERROR: no player settings directory: %i", user_id))
        return
    end
    if not (directory[setting_name] and SETTINGS_TYPES[setting_name]) then
        warn(string.format("SettingsModule/ERROR: no such setting \"%s\": %i", setting_name, user_id))
        return
    end
    return directory[setting_name]
end

--- Public

function SettingsModule.OnPlayerAdded(player: Player, player_data: {[string]: any})
    local user_id: number = player.UserId
    if not player_data or not player_data._settings then
        warn(string.format("SettingsModule/ERROR: no _settings key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data._settings)
end

function SettingsModule.OnPlayerRemoving(user_id: number)
    _Wipe(user_id)
end

SettingsModule.ModifySetting = _ModifySetting

SettingsModule.GetSetting = _GetSetting

return SettingsModule
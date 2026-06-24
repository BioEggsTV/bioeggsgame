-- ServerScriptService/ServerMain/InventoryModule

--[[

Script By: BioEggsHD
Handles player inventories

]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local ServerMain = script.Parent::Script
local DataModule = require(ServerMain:FindFirstChild("DataModule"))

type item_type = {[string]: any} -- [property_name]: value
type inventory_type = {[string]: item_type} -- [item_name]: item_data
local INVENTORIES: {[number]: {[string]: any}} = {} -- [user_id]: inventory

--// MODULE //--

local InventoryModule = {}

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

-- Attempt to retrieve saved inventory data
local function _GetInventoryData(user_id: number): {[string]: any}?
    local player_data = DataModule.GetData(user_id)
    if player_data and player_data._inventory then
        return player_data._inventory
    end
    return nil
end

-- Attempt to save inventory data
local function _SaveInventoryData(user_id: number, release_session: boolean?): boolean
    local player_data = INVENTORIES[user_id]
    if not player_data then 
        warn("InventoryModule/ERROR: data does not exist for player: " .. tostring(user_id))
        return false
    end
    
    local success = DataModule.SaveData(user_id, player_data, release_session)
    if not success then 
        warn("InventoryModule/ERROR: failed to save data for player: " .. tostring(user_id))
    end
    return success
end

-- Allocate inventory for a player
local function _Allocate(user_id: number, player_data: {[string]: any})
    if INVENTORIES[user_id] then 
        local player: Player? = Players:GetPlayerByUserId(user_id)
        local user_name = player and player.Name or "Unknown"
        warn(string.format("InventoryModule/WARNING: updating already existing data allocation for player: %s, %i", user_name, user_id))
    end
    INVENTORIES[user_id] = player_data
end

-- Remove players inventory allocation
local function _Wipe(user_id: number)
    if INVENTORIES[user_id] then 
        INVENTORIES[user_id] = nil
    end
end

-- Add an item pool to a players inventory
local function _AddItems(user_id: number, items: inventory_type)
    local player_data = INVENTORIES[user_id]
    if not player_data or not player_data._inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end

    local player_inventory = player_data._inventory
    for item_name: string, item_data: item_type in items do 
        local current_item = player_inventory[item_name]
        if current_item then
            current_item.Count += (item_data.Count or 0)
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while adding items to %i; skipping item", item_name, user_id))
        end
    end
end

-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: inventory_type)
    local player_data = INVENTORIES[user_id]
    if not player_data or not player_data._inventory then 
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end

    local player_inventory = player_data._inventory
    for item_name: string, item_data: item_type in items do 
        local current_item = player_inventory[item_name]
        if current_item then
            current_item.Count = math.max(0, current_item.Count - (item_data.Count or 0))
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while removing items from %i; skipping item", item_name, user_id))
        end
    end
end

-- Get a players inventory
local function _GetInventory(user_id: number): inventory_type?
    local player_data = INVENTORIES[user_id]
    if player_data and player_data._inventory then
        return _DeepCopy(player_data._inventory)
    else
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end
end

-- Get item count in a players inventory
local function _GetItemCount(user_id: number, item_name: string): number?
    local player_data = INVENTORIES[user_id]
    if not player_data or not player_data._inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end
    
    local inventory = player_data._inventory
    if not inventory[item_name] then
        warn(string.format("InventoryModule/ERROR: no such item \"%s\" while getting item count of %i", item_name, user_id))
        return nil
    end
    
    return inventory[item_name].Count or 0
end

--- Public

-- Create a players inventory in the directory
function InventoryModule.CreateInventory(user_id)
    local player_data = _GetInventoryData(user_id)
    if player_data then
        _Allocate(user_id, player_data)
    end
    -- adding further logic like ui here later
end

-- Remove a players inventory in the directory
function InventoryModule.RemoveInventory(user_id)
    _SaveInventoryData(user_id, true)
    _Wipe(user_id)
end

InventoryModule.AddItems = _AddItems

InventoryModule.RemoveItems = _RemoveItems

InventoryModule.GetInventory = _GetInventory

InventoryModule.GetItemCount = _GetItemCount

return InventoryModule
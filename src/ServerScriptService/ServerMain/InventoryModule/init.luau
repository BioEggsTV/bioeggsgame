-- ServerScriptService/ServerMain/DataModule

--[[

Script By: BioEggsHD
Handles loading / saving of player data

]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local ServerMain = script.Parent::Script
local DataModule = require(ServerMain:FindFirstChild("DataModule"))

type item_type = {[string]: any} -- [property_name]: value
type inventory_type = {[string]: item_type} -- [item_name]: item_data
local INVENTORIES: {[number]: inventory_type} = {} -- [user_id]: inventory

--// MODULE //--

local InventoryModule = {}

--- Private

-- Attempt to retrieve saved inventory data
local function _GetInventoryData(user_id: number): inventory_type?
    local inventory_data = DataModule.GetData(user_id, "_inventory")
    if inventory_data then
        return inventory_data
    else
        warn("InventoryModule/ERROR: kicking player after fail getting inventory data: " .. tostring(user_id))
        local player = Players:GetPlayerByUserId(user_id)
        if player then
            player:Kick("Roblox data stores are down. Please try rejoining later.")
        end
        return nil
    end
end

-- Attempt to save inventory data
local function _SaveInventoryData(user_id: number): boolean
    local live_inventory = INVENTORIES[user_id]
    if not live_inventory then 
        warn("InventoryModule/ERROR: inventory does not exist for player: " .. tostring(user_id))
        return false
    end
    
    local inventory_copy: inventory_type = table.clone(live_inventory)
    local success = DataModule.SaveData(user_id, inventory_copy, "_inventory")
    if not success then 
        warn("InventoryModule/ERROR: failed to save inventory for player: " .. tostring(user_id))
    end
    return success
end

-- Allocate inventory for a player
local function _Allocate(user_id: number, inventory: inventory_type)
    if INVENTORIES[user_id] then 
        local player: Player? = Players:GetPlayerByUserId(user_id)
        local user_name = player and player.Name or "Unknown"
        warn(string.format("InventoryModule/WARNING: updating already existing inventory allocation for player: %s, %i", user_name, user_id))
    end
    INVENTORIES[user_id] = inventory
end

-- Remove players inventory allocation
local function _Wipe(user_id: number)
    if INVENTORIES[user_id] then 
        INVENTORIES[user_id] = nil
    end
end

-- Add an item pool to a players inventory
local function _AddItems(user_id: number, items: inventory_type)
    local old_player_inventory = INVENTORIES[user_id]
    if not old_player_inventory then 
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end
    local new_player_inventory = table.clone(old_player_inventory)
    for item_name: string, item_data: item_type in items do 
        if new_player_inventory[item_name] then
            new_player_inventory[item_name].Count += items[item_name].Count
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while adding items to %i; skipping item", item_name, user_id))
            continue
        end
    end
    if old_player_inventory then
        old_player_inventory = new_player_inventory
    else
        warn("InventoryModule/ERROR: player inventory directory not found after item addition: " .. tostring(user_id))
    end
end

-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: inventory_type)
    local old_player_inventory = INVENTORIES[user_id]
    if not old_player_inventory then 
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end
    local new_player_inventory = table.clone(old_player_inventory)
    for item_name: string, item_data: item_type in items do 
        if new_player_inventory[item_name] then
            new_player_inventory[item_name].Count = math.max(0, new_player_inventory[item_name].Count - items[item_name].Count)
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while removing items from %i; skipping item", item_name, user_id))
            continue
        end
    end
    if old_player_inventory then
        old_player_inventory = new_player_inventory
    else
        warn("InventoryModule/ERROR: player inventory directory not found after item removal: " .. tostring(user_id))
    end
end

-- Get a players inventory
local function _GetInventory(user_id: number): inventory_type?
    local inventory: inventory_type? = INVENTORIES[user_id]
    return inventory and inventory or (function()
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end)()
end

-- Get item count in a players inventory
local function _GetItemCount(user_id: number, item_name: string): number?
    local inventory: inventory_type? = INVENTORIES[user_id]
    return inventory and (inventory[item_name] and inventory[item_name].Count or (function()
        warn("InventoryModule/ERROR: no such item \"%s\" while getting item count of " .. tostring(user_id))
        return nil
    end)()) or (function()
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end)()
end

--- Public

-- Create a players inventory in the directory
function InventoryModule.CreateInventory(user_id)
    local inventory: inventory_type? = _GetInventoryData(user_id)
    if inventory then
        _Allocate(user_id, inventory)
    end
    -- adding further logic like ui here later
end

-- Remove a players inventory in the directory
function InventoryModule.RemoveInventory(user_id)
    _SaveInventoryData(user_id)
    _Wipe(user_id)
end

InventoryModule.AddItems = _AddItems

InventoryModule.RemoveItems = _RemoveItems

return InventoryModule
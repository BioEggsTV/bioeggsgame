-- ServerScriptService/ServerMain/InventoryModule

--[[

Script By: BioEggsHD
Handles player inventories

]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local ServerMain = script.Parent :: Script
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

    local inventory_copy: inventory_type = {}
    for item_name: string, item_data: item_type in live_inventory do
        inventory_copy[item_name] = table.clone(item_data)
    end

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
    local player_inventory = INVENTORIES[user_id]
    if not player_inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end
    for item_name: string, item_data: item_type in items do
        if player_inventory[item_name] then
            player_inventory[item_name].Count += item_data.Count
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while adding items to %i; skipping item", item_name, user_id))
            continue
        end
    end
end

-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: inventory_type)
    local player_inventory = INVENTORIES[user_id]
    if not player_inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return
    end
    for item_name: string, item_data: item_type in items do
        if player_inventory[item_name] then
            player_inventory[item_name].Count = math.max(0, player_inventory[item_name].Count - item_data.Count)
        else
            warn(string.format("InventoryModule/ERROR: no such item \"%s\" while removing items from %i; skipping item", item_name, user_id))
            continue
        end
    end
end

-- Get a players inventory
local function _GetInventory(user_id: number): inventory_type?
    local inventory: inventory_type? = INVENTORIES[user_id]
    if not inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end
    return inventory
end

-- Get item count in a players inventory
local function _GetItemCount(user_id: number, item_name: string): number?
    local inventory: inventory_type? = INVENTORIES[user_id]
    if not inventory then
        warn("InventoryModule/ERROR: no player inventory directory: " .. tostring(user_id))
        return nil
    end
    local item: item_type? = inventory[item_name]
    if not item then
        warn(string.format("InventoryModule/ERROR: no such item \"%s\" while getting item count of %i", item_name, user_id))
        return nil
    end
    return item.Count
end

--- Public

-- Create a players inventory in the directory
function InventoryModule.CreateInventory(user_id: number)
    local inventory: inventory_type? = _GetInventoryData(user_id)
    if inventory then
        _Allocate(user_id, inventory)
    end
    -- adding further logic like ui here later
end

-- Remove a players inventory in the directory
function InventoryModule.RemoveInventory(user_id: number)
    _SaveInventoryData(user_id)
    _Wipe(user_id)
end

InventoryModule.AddItems = _AddItems

InventoryModule.RemoveItems = _RemoveItems

InventoryModule.GetInventory = _GetInventory

InventoryModule.GetItemCount = _GetItemCount

return InventoryModule

-- ServerScriptService/ServerMain/InventoryModule

--[[
	Script By: BioEggsHD
	Handles player inventories
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

type item_type = {
    Name: string,
    Category: "Boosts" | "Pets",
    Type: "Stackable" | "Unique",
    Data: {[string]: any}
}
type inventory_type = {[string]: item_type} -- [item_name]: item_data

-- Holds references to players _inventory directory inside PLAYER_DATA
local INVENTORIES: {[number]: inventory_type} = {} -- [user_id]: _inventory reference

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

-- Allocate a reference to the players inventory directory
local function _Allocate(user_id: number, inventory: inventory_type)
	if INVENTORIES[user_id] then
		local player: Player? = Players:GetPlayerByUserId(user_id)
		local user_name = player and player.Name or "Unknown"
		warn(string.format("InventoryModule/WARNING: updating already existing data allocation for player: %s, %i", user_name, user_id))
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
	local inventory: inventory_type = INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return
	end

	for item_name: string, item_data: item_type in items do
		local current_item: item_type = inventory[item_name]
		if current_item then
			current_item.Data.Count += (item_data.Data.Count or 0)
		else
			warn(string.format("InventoryModule/ERROR: no such item \"%s\" while adding items to %i; skipping item", item_name, user_id))
		end
	end
end

-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: inventory_type)
	local inventory: inventory_type = INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return
	end

	for item_name: string, item_data: item_type in items do
		local current_item: item_type = inventory[item_name]
		if current_item then
			current_item.Data.Count = math.max(0, current_item.Data.Count - (item_data.Data.Count or 0))
		else
			warn(string.format("InventoryModule/ERROR: no such item \"%s\" while removing items from %i; skipping item", item_name, user_id))
		end
	end
end

-- Get a player inventory copy or reference
local function _GetInventory(user_id: number, by_reference: boolean): inventory_type?
	local inventory = INVENTORIES[user_id]
	if inventory then
		return by_reference and inventory or _DeepCopy(inventory)
	else
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
end

-- Get item count in a players inventory
local function _GetItemCount(user_id: number, item_name: string): number?
	local inventory: inventory_type = INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end

	if not inventory[item_name] then
		warn(string.format("InventoryModule/ERROR: no such item \"%s\" while getting item count of %i", item_name, user_id))
		return nil
	end

	return inventory[item_name].Data.Count or 0
end

--- Public

-- Create player inventory directory using player_data (from ServerMain)
function InventoryModule.CreateInventory(user_id: number, player_data: {[string]: any})
	if not player_data or not player_data._inventory then
        warn(string.format("InventoryModule/ERROR: no _inventory key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data._inventory)
	-- adding further logic like ui here later
end

-- Remove a players inventory in the directory
function InventoryModule.RemoveInventory(user_id: number)
	_Wipe(user_id)
end

InventoryModule.AddItems = _AddItems

InventoryModule.RemoveItems = _RemoveItems

InventoryModule.GetInventory = _GetInventory

InventoryModule.GetItemCount = _GetItemCount

return InventoryModule

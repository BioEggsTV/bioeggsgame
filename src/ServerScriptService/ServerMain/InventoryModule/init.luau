-- ServerScriptService/ServerMain/InventoryModule

--[[
	Script By: BioEggsHD
	Handles player inventories
]]--

--// SERVICES //--

local Players = game:GetService("Players")

--// VARIABLES //--

local ItemsModule = require(script:FindFirstChild("ItemsModule"))

type item_type = {
    Name: string,
    Category: "Boosts" | "Pets",
    Type: "Stackable" | "Unique",
    Data: {[string]: any}
}
type inventory_type = {[string]: {[any]: item_type}} -- ["Stackable" | "Unique"]: [item_name | index]: item_data

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

	for item_name: string, item_data: item_type in items.Stackable do
		if not ItemsModule.ItemDatabase[item_name] then
			warn(string.format("InventoryModule/ERROR: no such stackable item \"%s\" while adding items to %i; skipping item", item_name, user_id))
			continue
		end
		
		if not inventory[item_name] then
			inventory.Stackable[item_name] = item_data or ItemsModule.ItemDatabase[item_name]
		else
			inventory.Stackable[item_name].Data.Count += item_data.Data.Count or 0
		end
	end

	for index: number, item_data: item_type in items.Unique do
		if not ItemsModule.ItemDatabase[item_data.Name] then
            warn(string.format("InventoryModule/ERROR: no such unique item \"%s\" while adding items to %i; skipping item", item_data.Name, user_id))
			continue
		end

		table.insert(inventory.Unique, item_data)
	end
end
	
-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: inventory_type)
    local inventory = INVENTORIES[user_id]
    if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
        return
    end

    if items.Stackable then
        for item_name: string, item_data: item_type in items.Stackable do
            local current_item = inventory.Stackable[item_name]
            if current_item then
                local remove_amount = item_data.Data.Count or 0
                local new_count = math.max(0, current_item.Data.Count - remove_amount)
                
                if new_count == 0 then
                    inventory.Stackable[item_name] = nil
                else
                    current_item.Data.Count = new_count
                end
            else
                warn(string.format("InventoryModule/ERROR: no such stackable item \"%s\" to remove from %i", item_name, user_id))
            end
        end
    end

    if items.Unique then
        for index: number, item_data: item_type in items.Unique do
            local removed = false
            
            for i = #inventory.Unique, 1, -1 do
                local current_unique = inventory.Unique[i]
                
                if current_unique.Name == item_data.Name then
                    table.remove(inventory.Unique, i)
                    removed = true
                    break
                end
            end
            
            if not removed then
                warn(string.format("InventoryModule/ERROR: unique item \"%s\" not found to remove from %i", item_data.Name, user_id))
            end
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

-- Get item count (stackable) in a players inventory
local function _GetItemCount(user_id: number, item_name: string): number?
	local inventory: inventory_type = INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end

	if not inventory.Stackable[item_name] then
		warn(string.format("InventoryModule/ERROR: no item \"%s\" in player inventory while getting item count in %i", item_name, user_id))
		return nil
	end

	return inventory.Stackable[item_name].Data.Count or 0
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

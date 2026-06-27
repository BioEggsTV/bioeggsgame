-- ServerScriptService/ServerMain/InventoryModule

--[[
	Script By: BioEggsHD
	Handles player inventories
]]--

--// SERVICES //--

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //--

local SharedUtils = ServerScriptService.SharedUtils
local TableUtil = require(SharedUtils:FindFirstChild("TableUtil"))
local ItemsModule = require(script:FindFirstChild("ItemsModule"))

-- Holds references to players _inventory directory inside PLAYER_DATA
local INVENTORIES: {[number]: ItemsModule.inventory_type} = {} -- [user_id]: _inventory reference

local LOCKED: {[number]: boolean?} = {} -- [user_id]: inventory locked or not

--// MODULE //--

local InventoryModule = {}

--- Private

-- Allocate a reference to the players inventory directory
local function _Allocate(user_id: number, inventory: ItemsModule.inventory_type)
	if INVENTORIES[user_id] then
		local player: Player? = Players:GetPlayerByUserId(user_id)
		local user_name = player and player.Name or "Unknown"
		warn(string.format("InventoryModule/WARNING: updating already existing data allocation for player: %s, %i", user_name, user_id))
	end
	INVENTORIES[user_id] = inventory
end

-- Remove players inventory allocation
local function _Wipe(user_id: number)
	INVENTORIES[user_id] = nil
	LOCKED[user_id] = nil
end

-- Add an item pool to a players inventory
local function _AddItems(user_id: number, items: ItemsModule.inventory_type, custom_inventory: ItemsModule.inventory_type?)
	if LOCKED[user_id] then return end
	local inventory = custom_inventory or INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return
	end

	for item_name: string, item_data: ItemsModule.item_type in items.Stackable do
		if not ItemsModule.ItemDatabase[item_name] then
			warn(string.format("InventoryModule/ERROR: no such stackable item \"%s\" while adding items to %i; skipping item", item_name, user_id))
			continue
		end
		
		if not inventory.Stackable[item_name] then
			inventory.Stackable[item_name] = TableUtil.DeepCopy(item_data) or TableUtil.DeepCopy(ItemsModule.ItemDatabase[item_name])
		else
			inventory.Stackable[item_name].Data.Count += item_data.Data.Count or 0
		end
	end

	for index: number, item_data: ItemsModule.item_type in items.Unique do
		if not ItemsModule.ItemDatabase[item_data.Name] then
            warn(string.format("InventoryModule/ERROR: no such unique item \"%s\" while adding items to %i; skipping item", item_data.Name, user_id))
			continue
		end

		table.insert(inventory.Unique, TableUtil.DeepCopy(item_data))
	end
end
	
-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: ItemsModule.inventory_type, custom_inventory: ItemsModule.inventory_type?)
	if LOCKED[user_id] then return end
    local inventory = custom_inventory or INVENTORIES[user_id]
    if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
        return
    end

    if items.Stackable then
        for item_name: string, item_data: ItemsModule.item_type in items.Stackable do
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
                warn(string.format("InventoryModule/ERROR: no such stackable item \"%s\" to remove from: %i", item_name, user_id))
            end
        end
    end

    if items.Unique then
        for index: number, item_data: ItemsModule.item_type in items.Unique do
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
                warn(string.format("InventoryModule/ERROR: unique item \"%s\" not found to remove from: %i", item_data.Name, user_id))
            end
        end
    end
end

-- Get a player inventory copy or reference
local function _GetInventory(user_id: number, by_reference: boolean): ItemsModule.inventory_type?
	local inventory = INVENTORIES[user_id]
	if inventory then
		return by_reference and inventory or TableUtil.DeepCopy(inventory)
	else
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
end

-- Get item count (stackable) in a players inventory
local function _GetItemCount(user_id: number, item_name: string, custom_inventory: ItemsModule.inventory_type?): number?
	local inventory: ItemsModule.inventory_type = custom_inventory or INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
	local item_data: ItemsModule.item_type? = ItemsModule.ItemDatabase[item_name]
	if not item_data then
		warn(string.format("InventoryModule/ERROR: no such item \"%s\" while getting item count in: %i", item_name, user_id))
		return nil
	end
	local type: string = ItemsModule.ItemDatabase[item_name].Type
	if type == "Stackable" then
		if not inventory.Stackable[item_name] then
			warn(string.format("InventoryModule/ERROR: no item \"%s\" in player inventory while getting item count in: %i", item_name, user_id))
			return nil
		end
		return inventory.Stackable[item_name].Data.Count or 0
	else
		local count = 0
		for i, item: ItemsModule.item_type in inventory.Unique do
			if item.Name == item_name then
				count += 1
			end
		end
		return count
	end
end

-- Update locked flag for inventory
local function _LockInventory(user_id: number, locked: boolean)
	LOCKED[user_id] = locked and true or nil
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

InventoryModule.LockInventory = _LockInventory

return InventoryModule

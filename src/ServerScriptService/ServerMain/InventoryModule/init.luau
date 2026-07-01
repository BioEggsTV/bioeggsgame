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
local TableUtil = require(SharedUtils.TableUtil)
local ItemUtil = require(script:FindFirstChild("ItemUtil"))

-- Holds references to players _inventory directory inside PLAYER_DATA
local INVENTORIES: {[number]: ItemUtil.InventoryType} = {} -- [user_id]: _inventory reference

local LOCKED: {[number]: boolean?} = {} -- [user_id]: inventory locked or not

--// MODULE //--

local InventoryModule = {}

--- Private

-- Allocate a reference to the players inventory directory
local function _Allocate(user_id: number, inventory: ItemUtil.InventoryType)
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
local function _AddItems(user_id: number, items: ItemUtil.InventoryType, custom_inventory: ItemUtil.InventoryType?, ignore_lock: boolean?)
	if LOCKED[user_id] and not ignore_lock then return end
	local inventory = custom_inventory or INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return
	end

	for item_name: string, item_data: ItemUtil.ItemType in items.Stackable do
		if not ItemUtil.ItemDatabase[item_name] then
			warn(string.format("InventoryModule/ERROR: no such stackable item \"%s\" while adding items to %i; skipping item", item_name, user_id))
			continue
		end
		
		if not inventory.Stackable[item_name] then
    		local template = TableUtil.DeepCopy(ItemUtil.ItemDatabase[item_name])
    		inventory.Stackable[item_name] = TableUtil.Reconcile(TableUtil.DeepCopy(item_data), template)
		else
			inventory.Stackable[item_name].Data.Count += item_data.Data.Count or 0
		end
	end

	for guid: string, item_data: ItemUtil.ItemType in items.Unique do
		if not ItemUtil.ItemDatabase[item_data.Name] then
            warn(string.format("InventoryModule/ERROR: no such unique item \"%s\" while adding items to %i; skipping item", item_data.Name, user_id))
			continue
		end

		inventory.Unique[guid] = TableUtil.DeepCopy(item_data)
	end
end
	
-- Remove items from a players inventory
local function _RemoveItems(user_id: number, items: ItemUtil.InventoryType, custom_inventory: ItemUtil.InventoryType?, ignore_lock: boolean?)
	if LOCKED[user_id] and not ignore_lock then return end
    local inventory = custom_inventory or INVENTORIES[user_id]
    if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
        return
    end

    if items.Stackable then
        for item_name: string, item_data: ItemUtil.ItemType in items.Stackable do
            local current_item = inventory.Stackable[item_name]
            if current_item then
                local remove_amount = math.max(0, item_data.Data.Count or 0)
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
        for guid: string, item_data: ItemUtil.ItemType in items.Unique do
			inventory.Unique[guid] = nil
        end
    end
end

-- Get a player inventory copy or reference
local function _GetInventory(user_id: number, by_reference: boolean): ItemUtil.InventoryType? --> players inventory
	local inventory = INVENTORIES[user_id]
	if inventory then
		return by_reference and inventory or TableUtil.DeepCopy(inventory)
	else
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
end

-- Get item count in a players inventory
local function _GetItemCount(user_id: number, item_name: string, custom_inventory: ItemUtil.InventoryType?): number? --> item count
	local inventory: ItemUtil.InventoryType = custom_inventory or INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
	local item_data: ItemUtil.ItemType? = ItemUtil.ItemDatabase[item_name]
	if not item_data then
		warn(string.format("InventoryModule/ERROR: no such item \"%s\" while getting item count in: %i", item_name, user_id))
		return nil
	end
	local item_type: string = ItemUtil.ItemDatabase[item_name].Type
	if item_type == "Stackable" then
		if not inventory.Stackable[item_name] then
			warn(string.format("InventoryModule/ERROR: no item \"%s\" in player inventory while getting item count in: %i", item_name, user_id))
			return 0
		end
		return inventory.Stackable[item_name].Data.Count or 0
	else
		local count = 0
		for _, item: ItemUtil.ItemType in inventory.Unique do
			if item.Name == item_name then
				count += 1
			end
		end
		return count
	end
end

-- Check if players owns an item with given guid
local function _HasUniqueItem(user_id: number, guid: string, custom_inventory: ItemUtil.InventoryType?): boolean --> whether player owns the item
	local inventory: ItemUtil.InventoryType = custom_inventory or INVENTORIES[user_id]
	if not inventory then
        warn(string.format("InventoryModule/ERROR: no player inventory directory: %i", user_id))
		return nil
	end
	return inventory.Unique[guid] ~= nil
end

-- Update locked flag for inventory
local function _LockInventory(user_id: number, locked: boolean)
	LOCKED[user_id] = locked and true or nil
end

--- Public

-- Create player inventory directory using player_data (from ServerMain)
function InventoryModule.OnPlayerAdded(player: Player, player_data: {[string]: any})
	local user_id: number = player.UserId
	if not player_data or not player_data._inventory then
        warn(string.format("InventoryModule/ERROR: no _inventory key in player data for user: %i", user_id))
		return
	end
	_Allocate(user_id, player_data._inventory)
end

-- Remove a players inventory in the directory
function InventoryModule.OnPlayerRemoving(user_id: number)
	_Wipe(user_id)
end

InventoryModule.AddItems = _AddItems

InventoryModule.RemoveItems = _RemoveItems

InventoryModule.GetInventory = _GetInventory

InventoryModule.GetItemCount = _GetItemCount

InventoryModule.HasUniqueItem = _HasUniqueItem

InventoryModule.LockInventory = _LockInventory

return InventoryModule

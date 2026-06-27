-- ServerScriptService/ServerMain/InventoryModule/ItemsModule

--[[

Script By: BioEggsHD
Database of all item templates

]]--

local ItemsModule = {}

export type item_type = {
    Name: string,
    Category: "Boosts" | "Pets",
    Type: "Stackable" | "Unique",
    Data: {[string]: any}
}
export type inventory_type = {[string]: {[any]: item_type}} -- ["Stackable" | "Unique"]: [item_name | index]: item_data

-- Stackable items use id as index;
-- Unique items use own Name as index
ItemsModule.ItemDatabase = {
    experience_potion_1 = {
        Name = "Small Experience Potion",
        Category = "Boosts",
        Type = "Stackable",
        Data = {
            Count = 0,
            Modifier = 1
        }
    },

    Dog = {
        Name = "Dog",
        Category = "Pets",
        Type = "Unique",
        Data = {
            Experience = 0,
            -- _uid = "" <- implement unique items actually being unique
        }
    }
}

return ItemsModule

-- ServerScriptService/ServerMain/InventoryModule/ItemUtil

--[[
    Script By: BioEggsHD
    Database of all item templates
]]--

local ItemsModule = {}

export type ItemType = {
    Name: string,
    Category: "Boosts" | "Pets",
    Type: "Stackable" | "Unique",
    Data: {[string]: any}
}
export type InventoryType = {
    Stackable: {[string]: ItemType},
    Unique: {[string]: ItemType}
}

-- Stackable items use id as index;
-- Unique items use name as index;
-- Inside an actual inventory table unique items use GUIDs as indices
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
            -- _uid = "" <-- implement unique items actually being unique
        }
    }
}

return ItemsModule

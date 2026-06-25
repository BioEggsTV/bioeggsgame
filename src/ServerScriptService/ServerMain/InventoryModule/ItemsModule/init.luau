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

    dog = {
        Name = "Dog",
        Category = "Pets",
        Type = "Unique",
        Data = {
            Experience = 0
        }
    }
}

return ItemsModule

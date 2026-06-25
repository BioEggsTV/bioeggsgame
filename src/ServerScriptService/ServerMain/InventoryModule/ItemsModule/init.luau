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

return ItemsModule
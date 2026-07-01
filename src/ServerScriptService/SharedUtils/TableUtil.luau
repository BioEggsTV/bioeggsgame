-- ServerScriptService/SharedUtils/TableUtil

--[[
    Script By: BioEggsHD
    Utils for table manipulation
]]--

--// MODULE //--

local TableUtil = {}

--- Public

function TableUtil.DeepCopy(t: {[any]: any}): {[any]: any} --> deep copied table
    local copy = {}
    for k, v in t do
        if type(v) == "table" then
            copy[k] = TableUtil.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function TableUtil.Reconcile(data: {[string]: any}, template: {[string]: any}): {[string]: any} --> reconciled table
    for key, value in template do
        if data[key] == nil then
            if type(value) == "table" then
                data[key] = TableUtil.DeepCopy(value)
            else
                data[key] = value
            end
        elseif type(data[key]) == "table" and type(value) == "table" then
            TableUtil.Reconcile(data[key], value)
        end
    end
    return data
end

function TableUtil.Overwrite(target: {[any]: any}, source: {[any]: any})
    table.clear(target)
    for k, v in source do
        if type(v) == "table" then
            target[k] = TableUtil.DeepCopy(v)
        else
            target[k] = v
        end
    end
end

function TableUtil.RemoveFirst(t: {[any]: any}, a: any): boolean --> whether element was removed
    local index = table.find(t, a)
    if index then
        table.remove(t, index)
        return true
    end
    return false
end

return TableUtil
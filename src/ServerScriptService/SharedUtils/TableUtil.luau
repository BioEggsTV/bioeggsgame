-- ServerScriptService/SharedUtils/TableUtil

--[[
    Script By: BioEggsHD
    Utils for table manipulation
]]--

--// MODULE //--

local TableUtil = {}

--- Public

function TableUtil.DeepCopy(t: {[any]: any}): {[any]: any}
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

function TableUtil.Reconcile(data: {[string]: any}, template: {[string]: any}): {[string]: any}
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

return TableUtil
-- ServerScriptService/ServerMain/MessagingModule

--[[
	Script By: BioEggsHD
	Operations for broadcasting messages / data across servers
]]--

--// SERVICES //--

local MessagingService = game:GetService("MessagingService")

--// VARIABLES //--

type CallbackType: (any) -> (any)
local CALLBACKS: {[string]: CallbackType} = {}

--// MODULE //--

local MessagingModule = {}

--- Private

local function _Publish(topic: string, payload: any)
    MessagingService:PublishAsync(topic, payload)
end

local function _BindCallback(topic: string, callback: (any) -> (any))
    local connection: RBXScriptConnection = MessagingService:SubscribeAsync(topic, callback)
    if CALLBACKS[topic] then
        CALLBACKS[topic]:Disconnect()
    end
    CALLBACKS[topic] = connection
end

local function _RemoveCallback(topic: string)
    if CALLBACKS[topic] then
        CALLBACKS[topic]:Disconnect()
        CALLBACKS[topic] = nil
    end
end

--- Public

function MessagingModule.SendToServer(job_id: string, topic: string, data: any)
    local payload = {
        Mode = "TargetServer",
        Target = job_id,
        Data = data
    }
    _Publish(topic, payload)
end

function MessagingModule.SendGlobal(topic: string, data: any)
    local payload = {
        Mode = "Global",
        Data = data
    }
    _Publish(topic, payload)
end

function MessagingModule.StartListening(topic: string, callback: CallbackType)
    _BindCallback(topic, function(payload: any)
        local data = payload.Data
        if data.Mode == "TargetServer" then
            if data.Target and data.Target ~= game.JobId then return end
        end
        callback(data.Data)
    end)
end

function MessagingModule.StopListening(topic: string)
    _RemoveCallback(topic)
end

return MessagingModule
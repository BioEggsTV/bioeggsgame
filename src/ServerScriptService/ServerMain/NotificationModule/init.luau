-- ServerScriptService/ServerMain/NotificationModule

--[[
	Script By: BioEggsHD
	Handles backend of sending notifications to clients
]]--

--// SERVICES //--

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //--

local ServerMain: Script = ServerScriptService.ServerMain
local NetworkBridge = require(ServerMain.NetworkBridge)

--// MODULE //--

local NotificationModule = {}

--- Private

local function _NotifyClients(user_ids: {number}, message: string)
    local payload = {
        Message = message
    }
    NetworkBridge.AttemptReplication(user_ids, payload, "NotificationModule", "Notification")
end

local function _NotifyAll(message: string)
    local payload = {
        Message = message
    }
    NetworkBridge.Broadcast(payload, "NotificationModule", "Notification")
end

--- Public

NotificationModule.NotifyClients = _NotifyClients

NotificationModule.NotifyAll = _NotifyAll

return NotificationModule
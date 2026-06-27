-- ServerScriptService/ServerMain/TradeRequestUtil

--[[
    Script By: BioEggsHD
    Handles player item trading
]]--

--// SERVICES //--

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //--

local SharedUtils = ServerScriptService.SharedUtils
local TableUtil = require(SharedUtils.TableUtil)
local TradingModule = require(script.Parent)

local REQUESTS: {[number]: {number}} = {}

--// MODULE //--

local TradeRequestUtil = {}

--- Private

local function _SendTradeRequest(player: number, request_to: number): string --> trade request result
    if table.find(REQUESTS[player], request_to) then
        return "AlreadySent"
    end
    table.insert(REQUESTS[player], request_to)
    -- fire request sent remote

    task.delay(60, function()
        local expired = TableUtil.RemoveFirst(REQUESTS[player], request_to)
        if expired then
            table.remove(REQUESTS[player], index)
            if Players:GetPlayerByUserId(player) then
                -- fire request expired remote
            end
            if Players:GetPlayerByUserId(request_to) then
                -- fire request expired remote
            end
        end
    end)

    return "Sent"
end

local function _InteractRequest(player: number, request_from: number, accept: boolean): string --> request interaction result
    if not REQUESTS[request_from] or not table.find(REQUESTS[request_from], player) then
        return "NoRequest"
    end
    TableUtil.RemoveFirst(REQUESTS[request_from], player)

    if not Players:GetPlayerByUserId(player) then
        if Players:GetPlayerByUserId(request_from) then
            -- fire target left remote
            return "TargetLeft"
        end
    end
    if not Players:GetPlayerByUserId(request_from) then
        if Players:GetPlayerByUserId(player) then
            -- fire player left remote
            return "PlayerLeft"
        end
    end

    if accept == true then
        TradingModule.CreateTradeSession(request_from, player)
        -- fire request accepted remote
        return "RequestAccepted"
    else
        -- fire request denied remote
        return "RequestDenied"
    end
end

--- Public

return TradeRequestUtil

--[[
    To implement:
    - toggle recieving trade requests setting
    - client replication
]]--
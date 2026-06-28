-- ServerScriptService/ServerMain/TradeRequestUtil

--[[
    Script By: BioEggsHD
    Handles player item trading
]]--

--// SERVICES //--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //--

local SharedUtils = ServerScriptService.SharedUtils
local TableUtil = require(SharedUtils.TableUtil)
local TradingModule = require(script.Parent)

local Remotes: Folder = ReplicatedStorage.Remotes
local TradeRequestRemote: RemoteEvent = Remotes.TradeRequest
local PlayerSettingsFunction: RemoteFunction = Remotes.PlayerSettings

local REQUESTS: {[number]: {number}} = {}

--// MODULE //--

local TradeRequestUtil = {}

--- Private

local function _PlayerInGame(player: number): boolean, Player? --> whether player is in game, player instance
    local plr: Player? = Players:GetPlayerByUserId(player)
    if plr then
        return true, plr
    else
        return false, nil
    end
end

local function _AttemptSendPayload(player: number, result: string, extra: {[string]: any}?)
    local payload = {
        Action = "TradeRequest",
        Result = result
    }
    if extra then
        for k: string, v: any in extra do
            payload[k] = v
        end
    end
    local is_in_game: boolean, plr: Player? = _PlayerInGame(player)
    if is_in_game then
        TradeRequestRemote:FireClient(plr, payload)
    end
end

local function _SendTradeRequest(player: number, request_to: number): string --> trade request result: AlreadySent, RequestSent, RequestsDisabled, RequestExpired, TargetLeft
    if table.find(REQUESTS[player], request_to) then
        return "AlreadySent"
    end
    if not _PlayerInGame(request_to) then
        return "TargetLeft"
    end
    
    local recieve_requests: boolean = PlayerSettings:InvokeClient(request_to, "RecieveRequests")
    if recieve_requests == false then
        return "RequestsDisabled"
    end

    task.delay(60, function()
        local expired = TableUtil.RemoveFirst(REQUESTS[player], request_to)
        if expired then
            table.remove(REQUESTS[player], index)
            _AttemptSendPayload(player, "RequestExpired", {
                Mode = "To",
                Player = request_to
            })
            _AttemptSendPayload(request_to, "RequestExpired", {
                Mode = "From",
                Player = player
            })
        end
    end)

    table.insert(REQUESTS[player], request_to)
    return "RequestSent"
end

local function _InteractRequest(player: number, request_from: number, accept: boolean): string --> request interaction result: TargetLeft, PlayerLeft, RequestAccepted, RequestDenied, NoRequest
    if not REQUESTS[request_from] or not table.find(REQUESTS[request_from], player) then
        return "NoRequest"
    end
    TableUtil.RemoveFirst(REQUESTS[request_from], player)

    if not _PlayerInGame(player) then
        if _PlayerInGame(requst_from) then
            return "TargetLeft"
        end
    end
    if not _PlayerInGame(request_from) then
        if _PlayerInGame(player) then
            return "PlayerLeft"
        end
    end

    if accept == true then
        return "RequestAccepted"
    else
        return "RequestDenied"
    end
end

--- Public

function TradeRequestUtil.SendTradeRequest(player: number, request_to: number)
    local result = _SendTradeRequest(player, request_to)
    _AttemptSendPayload(player, result)
end

function TradeRequestUtil.InteractRequest(player: number, request_from: number, accept: boolean)
    local result = _InteractRequest(player, request_from, accept)
    if result == "RequestAccepted" then
        -- create trade session (tbd)
    else
        _AttemptSendPayload(request_from, result)
    end
end

return TradeRequestUtil

--[[
    To implement:
    - toggle recieving trade requests setting (DONE)
    - client replication -> (BACKEND DONE)
]]--
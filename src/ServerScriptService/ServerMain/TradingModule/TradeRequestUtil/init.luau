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

local ServerMain = ServerScriptService.ServerMain
local SharedUtils = ServerScriptService.SharedUtils
local NetworkBridge = require(ServerMain.NetworkBridge)
local SettingsModule = require(ServerMain.SettingsModule)
local TradingModule = require(script.Parent)
local TableUtil = require(SharedUtils.TableUtil)

local Remotes: Folder = ReplicatedStorage.Remotes
local TradeRequestRemote: RemoteEvent = Remotes.TradeRequest

local REQUESTS: {[number]: {number}} = {}

--// MODULE //--

local TradeRequestUtil = {}

--- Private

local function _Allocate(user_id: number)
    REQUESTS[user_id] = {}
end

local function _Wipe(user_id: number)
    REQUESTS[user_id] = nil
end

local function _PlayerInGame(user_id: number): boolean, Player? --> whether player is in game, player instance
    local plr: Player? = Players:GetPlayerByUserId(user_id)
    if plr then
        return true, plr
    else
        return false, nil
    end
end

local function _SendTradeRequest(user_id: number, request_to: number): string --> trade request result: AlreadySent, RequestSent, RequestsDisabled, RequestExpired, TargetLeft
    if table.find(REQUESTS[user_id], request_to) then
        return "AlreadySent"
    end
    if not _PlayerInGame(request_to) then
        return "TargetLeft"
    end
    
    local recieve_requests: boolean = SettingsModule.GetSetting(request_to, "RecieveRequests")
    if recieve_requests == false then
        return "RequestsDisabled"
    end

    task.delay(60, function()
        local expired
        if REQUESTS[user_id] then
            expired = TableUtil.RemoveFirst(REQUESTS[user_id], request_to)
        end
        if expired then
            NetworkBridge.AttemptReplication({user_id, request_to}, "TradeRequestUtil", "TradeRequestCreation", {
                From = user_id,
                To = request_to,
                Result = "RequestExpired"
            })
        end
    end)

    table.insert(REQUESTS[user_id], request_to)
    return "RequestSent"
end

local function _InteractRequest(user_id: number, request_from: number, accept: boolean): string --> request interaction result: TargetLeft, PlayerLeft, RequestAccepted, RequestDenied, NoRequest
    if not REQUESTS[request_from] or not table.find(REQUESTS[request_from], user_id) then
        return "NoRequest"
    end
    TableUtil.RemoveFirst(REQUESTS[request_from], user_id)

    if not _PlayerInGame(user_id) then
        if _PlayerInGame(request_from) then
            return "TargetLeft"
        end
    end
    if not _PlayerInGame(request_from) then
        if _PlayerInGame(user_id) then
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

function TradeRequestUtil.OnPlayerAdded(player: Player)
    _Allocate(player.UserId)
end

function TradeRequestUtil.OnPlayerRemoving(user_id: number)
    _Wipe(user_id)
end

function TradeRequestUtil.SendTradeRequest(user_id: number, request_to: number)
    local result = _SendTradeRequest(user_id, request_to)
    local targets: {number} = if result == "RequestSent" then {user_id, request_to} else {user_id}
    NetworkBridge.AttemptReplication(targets, "TradeRequestUtil", "TradeRequestCreation", {
        From = user_id,
        To = request_to,
        Result = result
    })
end

function TradeRequestUtil.InteractRequest(user_id: number, request_from: number, accept: boolean)
    local result = _InteractRequest(user_id, request_from, accept)
    local player_table = {user_id, request_from}

    if result == "RequestAccepted" then
        local trade_id = TradingModule.CreateTradeSession(request_from, user_id)
    end
    NetworkBridge.AttemptReplication(player_table, "TradeRequestUtil", "TradeRequestInteraction", {
        From = request_from,
        To = user_id,
        Result = result
    })
end

return TradeRequestUtil

--[[
    To implement:
    - toggle recieving trade requests setting (DONE)
    - client replication -> (DONE)
]]--
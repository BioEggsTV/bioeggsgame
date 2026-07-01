-- ServerScriptService/ServerMain/TradingModule

--[[
    Script By: BioEggsHD
    Handles player item trading
]]--

--// SERVICES //--

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //

local ServerMain = script.Parent
local SharedUtils = ServerScriptService.SharedUtils
local DataModule = require(ServerMain.DataModule)
local ItemUtil = require(ServerMain.InventoryModule.ItemUtil)
local InventoryModule = require(ServerMain.InventoryModule)
local LeaderstatsModule = require(ServerMain.LeaderstatsModule)

type TradeSession = {
    TradeId: string,
    Active: boolean,
    Processing: boolean,
    
    Player1: {
        UserId: number,
        Gems: number,
        Ready: boolean,
        Offer: ItemUtil.InventoryType,
    },
    Player2: {
        UserId: number,
        Gems: number,
        Ready: boolean,
        Offer: ItemUtil.InventoryType,
    }
}

local ACTIVE_TRADES: {[string]: TradeSession} = {}
local PLAYER_TO_TRADE: {[number]: string} = {}

--// MODULE //--

local TradingModule = {}

--- Private

local function _UnreadyBoth(session: TradeSession)
    session.Player1.Ready = false
    session.Player2.Ready = false
end

local function _CheckPlayerPresency(player1: number, player2: number): boolean --> whether both players are in server
    if not (Players:GetPlayerByUserId(player1) and Players:GetPlayerByUserId(player2)) then
        return false
    else
        return true
    end
end

--- Public

function TradingModule.CreateTradeSession(player1: number, player2: number): string --> new trade id
    if PLAYER_TO_TRADE[player1] or PLAYER_TO_TRADE[player2] then return "" end
    local trade_id = HttpService:GenerateGUID(false)
    
    local session: TradeSession = {
        TradeId = trade_id,
        Active = true,
        Processing = false,
        
        Player1 = {
            UserId = player1,
            Gems = 0,
            Ready = false,
            Offer = {
                Stackable = {}, Unique = {} 
            },
        },
        Player2 = {
            UserId = player2,
            Gems = 0,
            Ready = false,
            Offer = {
                Stackable = {}, Unique = {}
            },
        }
    }
    
    ACTIVE_TRADES[trade_id] = session
    PLAYER_TO_TRADE[player1] = trade_id
    PLAYER_TO_TRADE[player2] = trade_id
    InventoryModule.LockInventory(player1, true)
    InventoryModule.LockInventory(player2, true)
    
    return trade_id
end

function TradingModule.CancelTradeSession(trade_id: string)
    local session: TradeSession = ACTIVE_TRADES[trade_id]
    if not session or session.Processing then return end

    local player1_uid = session.Player1.UserId
    local player2_uid = session.Player2.UserId
    
    session.Active = false
    PLAYER_TO_TRADE[player1_uid] = nil
    PLAYER_TO_TRADE[player2_uid] = nil
    InventoryModule.LockInventory(player1_uid, false)
    InventoryModule.LockInventory(player2_uid, false)
    ACTIVE_TRADES[trade_id] = nil
end

function TradingModule.OfferChanged(user_id: number)
    local trade_id: string = PLAYER_TO_TRADE[user_id]
    if not trade_id then return end
    local session: TradeSession = ACTIVE_TRADES[trade_id]
    
    if session and not session.Processing then
        _UnreadyBoth(session)
    end
end

function TradingModule.Process(trade_id: string)
    local session: TradeSession = ACTIVE_TRADES[trade_id]
    if not session or not session.Active or session.Processing then return end
    
    local player1_uid: number = session.Player1.UserId
    local player2_uid: number = session.Player2.UserId

    if _CheckPlayerPresency(player1_uid, player2_uid) == false then
        warn("TradingModule/ERROR: at least one player left during processing, cancelling")
        TradingModule.CancelTradeSession(trade_id)
        return
    end

    session.Processing = true
    
    local player1_inventory_copy: ItemUtil.InventoryType = InventoryModule.GetInventory(player1_uid, false)
    local player2_inventory_copy: ItemUtil.InventoryType = InventoryModule.GetInventory(player2_uid, false)
    local player1_gems: number = LeaderstatsModule.GetStat(player1_uid, "Gems")
    local player2_gems: number = LeaderstatsModule.GetStat(player2_uid, "Gems")

    local function _VerifyStackable(user_id: number, item_name: string, offer: ItemUtil.InventoryType): boolean --> whether player owns items
        if InventoryModule.GetItemCount(user_id, item_name) < (offer.Stackable[item_name].Data.Count or 0) then
            warn(string.format("TradingModule/ERROR: cancelling trade because player doesnt own stackable items in offer: %i", user_id))
            TradingModule.CancelTradeSession(trade_id)
            return false
        else
            return true
        end
    end
    local function _VerifyUnique(user_id: number, guid: string): boolean --> whether player owns unique item
        if not InventoryModule.HasUniqueItem(user_id, guid) then
            warn(string.format("TradingModule/ERROR: cancelling trade because player doesnt own unique item in offer: %i (%s)", user_id, guid))
            TradingModule.CancelTradeSession(trade_id)
            return false
        else
            return true
        end
    end

    if session.Player1.Gems > player1_gems or session.Player2.Gems > player2_gems then
        warn(string.format("TradingModule/ERROR: more gems in trade than actually owned. Player 1: %i, %i, Player 2: %i, %i", player1_gems, session.Player1.Gems, player2_gems, session.Player2.Gems))
        TradingModule.CancelTradeSession(trade_id)
        return
    end

    for item_name: string, _ in session.Player1.Offer.Stackable do
        if _VerifyStackable(player1_uid, item_name, session.Player1.Offer) == false then return end
    end
    for guid: string, _ in session.Player1.Offer.Unique do
        if _VerifyUnique(player1_uid, guid) == false then return end
    end
    for item_name: string, _ in session.Player2.Offer.Stackable do
        if _VerifyStackable(player2_uid, item_name, session.Player2.Offer) == false then return end
    end
    for guid: string, _ in session.Player2.Offer.Unique do
        if _VerifyUnique(player2_uid, guid) == false then return end
    end

    local success, errormessage = pcall(function()
        InventoryModule.RemoveItems(player1_uid, session.Player1.Offer, nil, true)
        InventoryModule.RemoveItems(player2_uid, session.Player2.Offer, nil, true)
        InventoryModule.AddItems(player1_uid, session.Player2.Offer, nil, true)
        InventoryModule.AddItems(player2_uid, session.Player1.Offer, nil, true)
        LeaderstatsModule.IncrementNumber(player1_uid, "Gems", session.Player2.Gems - session.Player1.Gems)
        LeaderstatsModule.IncrementNumber(player2_uid, "Gems", session.Player1.Gems - session.Player2.Gems)
    end)
    if not success then
        warn(string.format("TradingModule/ERROR: item or gems exchange failed, recovering %i and %i: %s", player1_uid, player2_uid, errormessage))
        DataModule.UpdateInventory(player1_uid, player1_inventory_copy)
        DataModule.UpdateInventory(player2_uid, player2_inventory_copy)
        LeaderstatsModule.UpdateStat(player1_uid, "Gems", player1_gems)
        LeaderstatsModule.UpdateStat(player2_uid, "Gems", player2_gems)
    end
    
    TradingModule.CancelTradeSession(trade_id)
end

return TradingModule

--[[

to be implemented in future:
- verification against real inventories (DONE)
- recovery (DONE)
- state checks (do players still exist, etc) (DONE)
- trade requests (DONE)
- only allow 1 active trade per player (DONE)
- locking inventories during trades (DONE)
- rate limiter
- audit log
- unique items being unique (DONE)

- client replication -> to be done for every single module, this is a massive future task

]]--

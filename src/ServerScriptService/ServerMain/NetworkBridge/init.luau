-- ServerScriptService/ServerMain/NetworkBridge

--[[
  Script By: BioEggsHD
  Handles replication between server and client
]]--

--// SERVICES //--

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// VARIABLES //--

type DefaultDictionary: {[string]: any}
type ClientRoute: (user_id: number, payload: any) -> ()

local MODULE_NAMES: {[string]: boolean} = {}
local CLIENT_ROUTES: {[string]: ClientRoute} = {}
local CLIENT_RATE_LIMITS: {[number]: {last_request: number, warnings: number}} = {}

local Replication: Folder = ReplicatedStorage.Replication
local ClientRemote: RemoteEvent = Replication.ClientRemote
local ServerRemote: RemoteEvent = Replication.ServerRemote

--// MODULE //--

local NetworkBridge = {}

--- Private

local function _LoadModules()
    for _, descendant: Instance in ServerScriptService:GetDescendants() do
        if descendant:IsA("ModuleScript") and descendant ~= script then
            MODULE_NAMES[descendant.Name] = true
        end
    end
end

local function _PlayerInGame(user_id: number): boolean, Player? --> whether player is in game, player instance
    local player: Player? = Players:GetPlayerByUserId(user_id)
    if player then
        return true, player
    else
        return false, nil
    end
end

local function _IsRateLimited(user_id: number): boolean --> whether player is rate limited
    local now = os.clock()

    if not CLIENT_RATE_LIMITS[user_id] then
		CLIENT_RATE_LIMITS[user_id] = {last_request = now, warnings = 0}
		return false
	end

    local cache = CLIENT_RATE_LIMITS[user_id]

	if (now - cache.last_request) < 0.05 then
		cache.warnings += 1
		if cache.warnings >= 5 then
            local is_in_game: boolean, player: Player = _PlayerInGame(user_id)
			if is_in_game then
                player:Kick("Packet limit exceeded.")
            end
		end
		return true
	else
        cache.warnings = math.max(0, cache.warnings - math.floor((now - cache.last_request) / 2)) -- decay warnings
    end
end

local function _OnClientSignal(player: Player, route_key: any, payload: any)
    if typeof(route_key) ~= "string" then return end
    if typeof(payload) ~= "table" then return end

    local user_id: number = player.UserId

    if _IsRateLimited(user_id) then return end
    local cache = CLIENT_RATE_LIMITS[user_id]
    cache.last_request = os.clock()

    local callback: ClientRoute? = CLIENT_ROUTES[route_key]
	if not callback then
		warn(string.format("NetworkBridge/ERROR: unregistered route request dropped from %s: %s", player.Name, route_key))
		return 
	end

    local success, errormessage = pcall(callback, user_id, payload)
    if not success then
        warn(string.format("NetworkBridge/ERROR: error executing route %s for %s: %s", route_key, player.Name, tostring(errormessage)))
    end
end

local function _RegisterClientRoute(route_key: string, callback: (user_id: number, payload: DefaultDictionary) -> ())
    if CLIENT_ROUTES[route_key] then
		warn(string.format("NetworkBridge/ERROR: route key '%s' is already registered", route_key))
        return
	end
	CLIENT_ROUTES[route_key] = callback
end

local function _AttemptReplication(user_ids: {number}, module_name: string, action: string, data: DefaultDictionary)
    if not MODULE_NAMES[module_name] then return end

    for _, user_id: number in user_ids do
        local is_in_game: boolean, player: Player? = _PlayerInGame(user_id)
        if not is_in_game then continue end

        local payload = {
            Module = module_name,
            Action = action,
            Data = data
        }
        ClientRemote:FireClient(player, payload)
    end
end

local function _Broadcast(module_name: string, action: string, data: DefaultDictionary)
    if not MODULE_NAMES[module_name] then return end

    local payload = {
        Module = module_name,
        Action = action,
        Data = data
    }
    ClientRemote:FireAllClients(payload)
end

--- Public

NetworkBridge.RegisterClientRoute = _RegisterClientRoute

NetworkBridge.AttemptReplication = _AttemptReplication

NetworkBridge.Broadcast = _Broadcast

function NetworkBridge.OnPlayerRemoving(user_id: number)
    CLIENT_RATE_LIMITS[user_id] = nil
end

function NetworkBridge.OnServerStart()
    _LoadModules()
    ServerRemote.OnServerEvent:Connect(_OnClientSignal)
end

return NetworkBridge
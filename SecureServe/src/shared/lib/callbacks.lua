local IS_SERVER = IsDuplicityVersion()
local table_unpack = table.unpack
local debug = debug
local debug_getinfo = debug.getinfo
local msgpack = msgpack
local msgpack_pack = msgpack.pack
local msgpack_unpack = msgpack.unpack
local msgpack_pack_args = msgpack.pack_args

-- Deferred states
local PENDING = 0
local RESOLVING = 1
local REJECTING = 2
local RESOLVED = 3
local REJECTED = 4

---@class CallbacksModule
local Callbacks = {
    callbackRegistry = {},
    currentCallbackId = 0
}

---@description Initialize the callbacks module
---@param isServer boolean Whether the current environment is server or client
function Callbacks.initialize(isServer)
    if isServer then
        RegisterNetEvent("SecureServe:callback:serverRequest", function(eventName, callbackId, ...)
            local src = source
            
            if Callbacks.callbackRegistry[eventName] then
                local result = Callbacks.callbackRegistry[eventName](src, ...)
                TriggerClientEvent("SecureServe:callback:clientResponse", src, callbackId, result)
            end
        end)
    else
        RegisterNetEvent("SecureServe:callback:clientResponse", function(callbackId, ...)
            if Callbacks.callbackRegistry[callbackId] then
                Callbacks.callbackRegistry[callbackId](...)
                Callbacks.callbackRegistry[callbackId] = nil
            end
        end)
    end
    
    print("^5[INITIALIZED] ^3Callbacks System^7")
end

---@description Register a server callback that can be triggered from clients
---@param name string The name of the callback
---@param cb function The callback function to execute
function Callbacks.registerServerCallback(name, cb)
    Callbacks.callbackRegistry[name] = cb
end

---@description Trigger a server callback from the client
---@param name string The name of the server callback to trigger
---@param cb function The callback function to execute with the result
---@param ... any Additional parameters to pass to the server callback
function Callbacks.triggerServerCallback(name, cb, ...)
    Callbacks.currentCallbackId = Callbacks.currentCallbackId + 1
    Callbacks.callbackRegistry[Callbacks.currentCallbackId] = cb
    TriggerServerEvent("SecureServe:callback:serverRequest", name, Callbacks.currentCallbackId, ...)
end

---@param obj any The object to check
---@param typeof string The expected type
---@param opt_typeof string|nil Optional expected type
---@param errMessage string|nil Optional error message
local function ensure(obj, typeof, opt_typeof, errMessage)
    local objtype = type(obj)
    local di = debug_getinfo(2)
    local errMessage = errMessage or (opt_typeof == nil and (di.name .. ' expected %s, but got %s') or (di.name .. ' expected %s or %s, but got %s'))
    if typeof ~= 'function' then
        if objtype ~= typeof and objtype ~= opt_typeof then
            error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
        end
    else
        if objtype == 'table' and not rawget(obj, '__cfx_functionReference') then
            error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
        end
    end
end

if IS_SERVER then
    ---@param args {eventName: string, eventCallback: function} Register a server callback
    ---@return any eventData The event data reference
    function Callbacks.register_server_callback(args)
        ensure(args, 'table'); ensure(args.eventName, 'string'); ensure(args.eventCallback, 'function')

        local eventCallback = args.eventCallback
        local eventName = args.eventName
        local eventData = RegisterNetEvent('smp__server_callback:'..eventName, function(packed, src, cb)
            local source = tonumber(source)
            if not source then
                cb(msgpack_pack_args(eventCallback(src, table_unpack(msgpack_unpack(packed)))))
            else
                TriggerClientEvent(('smp__client_callback_response:%s:%s'):format(eventName, source), source, msgpack_pack_args(eventCallback(source, table_unpack(msgpack_unpack(packed)))))
            end
        end)
        return eventData
    end

    ---@param eventData any The event data reference
    function Callbacks.unregister_server_callback(eventData)
        RemoveEventHandler(eventData)
    end

    ---@param args {source: string|number, eventName: string, args: table|nil, timeout: number|nil, timedout: function|nil, callback: function|nil} Trigger a client callback
    ---@return any result The callback result (if synchronous)
    function Callbacks.trigger_client_callback(args)
        ensure(args, 'table'); ensure(args.source, 'string', 'number'); ensure(args.eventName, 'string'); ensure(args.args, 'table', 'nil'); ensure(args.timeout, 'number', 'nil'); ensure(args.timedout, 'function', 'nil'); ensure(args.callback, 'function', 'nil')

        if tonumber(args.source) >= 0 then
            local ticket = tostring(args.source) .. 'x' .. tostring(GetGameTimer())
            local prom = promise.new()
            local eventCallback = args.callback
            local eventData = RegisterNetEvent(('smp__callback_retval:%s:%s:%s'):format(args.source, args.eventName, ticket), function(packed)
                if eventCallback and prom.state == PENDING then eventCallback(table_unpack(msgpack_unpack(packed))) end
                prom:resolve(table_unpack(msgpack_unpack(packed)))
            end)

            TriggerClientEvent(('smp__client_callback:%s'):format(args.eventName), args.source, msgpack_pack(args.args or {}), ticket)

            if args.timeout ~= nil and args.timedout then
                local timedout = args.timedout
                SetTimeout(args.timeout * 1000, function()
                    if
                        prom.state == PENDING or
                        prom.state == REJECTED or
                        prom.state == REJECTING
                    then
                        timedout(prom.state)
                        if prom.state == PENDING then prom:reject() end
                        RemoveEventHandler(eventData)
                    end
                end)
            end

            if not eventCallback then
                local result = Citizen.Await(prom)
                RemoveEventHandler(eventData)
                return result
            end
        else
            error('source should be equal to or higher than 0')
        end
    end

    ---@param args {source: string|number, eventName: string, args: table|nil, timeout: number|nil, timedout: function|nil, callback: function|nil} Simulate a client callback from server
    ---@return any result The callback result (if synchronous)
    function Callbacks.trigger_server_callback_from_server(args)
        ensure(args, 'table'); ensure(args.source, 'string', 'number'); ensure(args.eventName, 'string'); ensure(args.args, 'table', 'nil'); ensure(args.timeout, 'number', 'nil'); ensure(args.timedout, 'function', 'nil'); ensure(args.callback, 'function', 'nil')

        local prom = promise.new()
        local eventCallback = args.callback
        local eventName = args.eventName
        TriggerEvent('smp__server_callback:'..eventName, msgpack_pack(args.args or {}), args.source,
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback(table_unpack(msgpack_unpack(packed))) end
            prom:resolve(table_unpack(msgpack_unpack(packed)))
        end)

        if args.timeout ~= nil and args.timedout then
            local timedout = args.timedout
            SetTimeout(args.timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                end
            end)
        end

        if not eventCallback then
            return Citizen.Await(prom)
        end
    end
else
    local SERVER_ID = GetPlayerServerId(PlayerId())

    ---@param args {eventName: string, eventCallback: function} Register a client callback
    ---@return any eventData The event data reference
    function Callbacks.register_client_callback(args)
        ensure(args, 'table'); ensure(args.eventName, 'string'); ensure(args.eventCallback, 'function')
        
        local eventCallback = args.eventCallback
        local eventName = args.eventName
        local eventData = RegisterNetEvent('smp__client_callback:'..eventName, function(packed, ticket)
            if type(ticket) == 'function' then
                ticket(msgpack_pack_args(eventCallback(table_unpack(msgpack_unpack(packed)))))
            else
                TriggerServerEvent(('smp__callback_retval:%s:%s:%s'):format(SERVER_ID, eventName, ticket), msgpack_pack_args(eventCallback(table_unpack(msgpack_unpack(packed)))))
            end
        end)
        return eventData
    end

    ---@param eventData any The event data reference
    function Callbacks.unregister_client_callback(eventData)
        RemoveEventHandler(eventData)
    end

    ---@param args {eventName: string, args: table|nil, timeout: number|nil, timedout: function|nil, callback: function|nil} Trigger a server callback
    ---@return any result The callback result (if synchronous)
    function Callbacks.trigger_server_callback(args)
        ensure(args, 'table'); ensure(args.args, 'table', 'nil'); ensure(args.eventName, 'string'); ensure(args.timeout, 'number', 'nil'); ensure(args.timedout, 'function', 'nil'); ensure(args.callback, 'function', 'nil')
        
        local prom = promise.new()
        local eventCallback = args.callback
        local eventData = RegisterNetEvent(('smp__client_callback_response:%s:%s'):format(args.eventName, SERVER_ID),
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback(table_unpack(msgpack_unpack(packed))) end
            prom:resolve(table_unpack(msgpack_unpack(packed)))
        end)

        TriggerServerEvent('smp__server_callback:'..args.eventName, msgpack_pack(args.args))

        if args.timeout ~= nil and args.timedout then
            local timedout = args.timedout
            SetTimeout(args.timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                    RemoveEventHandler(eventData)
                end
            end)
        end

        if not eventCallback then
            local result = Citizen.Await(prom)
            RemoveEventHandler(eventData)
            return result
        end
    end

    ---@param args {eventName: string, args: table|nil, timeout: number|nil, timedout: function|nil, callback: function|nil} Simulate a server callback from client
    ---@return any result The callback result (if synchronous)
    function Callbacks.trigger_client_callback_from_client(args)
        ensure(args, 'table'); ensure(args.eventName, 'string'); ensure(args.args, 'table', 'nil'); ensure(args.timeout, 'number', 'nil'); ensure(args.timedout, 'function', 'nil'); ensure(args.callback, 'function', 'nil')

        local prom = promise.new()
        local eventCallback = args.callback
        local eventName = args.eventName
        TriggerEvent('smp__client_callback:'..eventName, msgpack_pack(args.args or {}),
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback(table_unpack(msgpack_unpack(packed))) end
            prom:resolve(table_unpack(msgpack_unpack(packed)))
        end)

        -- timeout response
        if args.timeout ~= nil and args.timedout then
            local timedout = args.timedout
            SetTimeout(args.timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                end
            end)
        end

        if not eventCallback then
            return Citizen.Await(prom)
        end
    end
end

if IS_SERVER then
    Callbacks.RegisterServerCallback = Callbacks.register_server_callback
    Callbacks.UnregisterServerCallback = Callbacks.unregister_server_callback
    Callbacks.TriggerClientCallback = Callbacks.trigger_client_callback
    Callbacks.TriggerServerCallback = Callbacks.trigger_server_callback_from_server
else
    Callbacks.RegisterClientCallback = Callbacks.register_client_callback
    Callbacks.UnregisterClientCallback = Callbacks.unregister_client_callback
    Callbacks.TriggerServerCallback = Callbacks.trigger_server_callback
    Callbacks.TriggerClientCallback = Callbacks.trigger_client_callback_from_client
end

_G.RegisterServerCallback = Callbacks.register_server_callback
_G.UnregisterServerCallback = Callbacks.unregister_server_callback
_G.TriggerClientCallback = Callbacks.trigger_client_callback
_G.TriggerServerCallback = IS_SERVER and Callbacks.trigger_server_callback_from_server or Callbacks.trigger_server_callback
_G.RegisterClientCallback = Callbacks.register_client_callback
_G.UnregisterClientCallback = Callbacks.unregister_client_callback

return Callbacks 
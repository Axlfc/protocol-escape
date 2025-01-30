-- app/utils/networkManager.lua
local socket = require 'socket'
local json = require 'cjson'
local networkManager = {}


-- Configuration
local CONFIG = {
    SERVER_PORT = 12345,
    CLIENT_TIMEOUT = 5,
    MAX_MESSAGE_SIZE = 1024 * 10,
    MESSAGE_RATE_LIMIT = 100,
    MAX_CLIENTS = 2,  -- This refers to "pairs" of connections
    ALLOW_DYNAMIC_SLOTS = true,
    SLOT_CLEANUP_INTERVAL = 60  -- Cleanup interval in seconds
}

-- Enhanced state management with slot tracking
networkManager.server = nil
networkManager.client = nil
networkManager.isServer = false
networkManager.connections = {}
networkManager.callbacks = {}
networkManager.messageCounters = {}
networkManager.lastCleanup = os.time()
networkManager.slots = {}
networkManager.clientSlots = {}
networkManager.maxSlotId = 0
networkManager.pairedConnections = {}  -- Track connection pairs by IP


function networkManager.initializeSlotSystem()
    networkManager.clientSlots = {}
    networkManager.maxSlotId = 0
    networkManager.pairedConnections = {}
    networkManager.ghostTimeout = 5  -- Seconds to wait before considering a client as ghost
end


function networkManager.handlePairedConnection(clientIp, clientPort)
    -- Use the existing lastPortPerIP variable (fix the typo)
    local isSequentialPort = false
    if networkManager.lastPortPerIP[clientIp] then
        local lastPort = networkManager.lastPortPerIP[clientIp]
        isSequentialPort = (clientPort == lastPort + 1)
    end

    if not networkManager.pairedConnections[clientIp] then
        networkManager.pairedConnections[clientIp] = {
            ports = {},
            slotId = nil
        }
    end

    local pair = networkManager.pairedConnections[clientIp]
    table.insert(pair.ports, clientPort)

    return isSequentialPort, pair
end


-- Logging function with improved timestamps and context
local function enhancedLog(level, message, context)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local contextStr = context and " " .. json.encode(context) or ""
    local formattedMessage = string.format("[NetworkManager][%s][%s]%s %s",
        timestamp,
        level:upper(),
        contextStr,
        message
    )
    print(formattedMessage)

    -- Optional: Log to file for persistent records
    local logFile = io.open("network_log.txt", "a")
    if logFile then
        logFile:write(formattedMessage .. "\n")
        logFile:close()
    end
end


-- Enhanced logging
local function log(level, message, context)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local contextStr = ""
    if context then
        contextStr = " [" .. json.encode(context) .. "]"
    end
    print(string.format("[NetworkManager][%s][%s]%s %s", timestamp, level, contextStr, message))
end

-- Message validation
local function validateMessage(message)
    if not message then return false, "Message is nil" end
    if #message > CONFIG.MAX_MESSAGE_SIZE then
        return false, "Message exceeds size limit"
    end
    -- Basic injection prevention
    if message:match("^%s*$") or message:match("[^%w%s%p]") then
        return false, "Message contains invalid characters"
    end
    return true
end

-- Rate limiting
local function checkRateLimit(connectionId)
    local now = os.time()
    networkManager.messageCounters[connectionId] = networkManager.messageCounters[connectionId] or {
        count = 0,
        lastReset = now
    }

    local counter = networkManager.messageCounters[connectionId]
    if now - counter.lastReset >= 1 then
        counter.count = 0
        counter.lastReset = now
    end

    counter.count = counter.count + 1
    return counter.count <= CONFIG.MESSAGE_RATE_LIMIT
end


function networkManager.sendMessage(message)
    if not networkManager.client then
        log("ERROR", "sendMessage called but client is not connected")
        return false, "Client not connected"
    end

    local valid, err = validateMessage(message)
    if not valid then
        log("ERROR", "Invalid message", {error = err})
        return false, err
    end

    local success, sendErr = pcall(function()
        networkManager.client:send(message .. "\n")
    end)

    if not success then
        log("ERROR", "Failed to send message to server", {error = sendErr})
        return false, sendErr
    end

    log("DEBUG", "Message sent to server", {message = message})
    return true
end


function networkManager.startServer()
    local success, err = pcall(function()
        networkManager.isServer = true
        networkManager.server = assert(socket.bind('*', CONFIG.SERVER_PORT))
        networkManager.server:settimeout(0)

        -- Log detailed server startup information
        enhancedLog("INFO", "Server Mode Activated", {
            port = CONFIG.SERVER_PORT,
            max_clients = CONFIG.MAX_CLIENTS,
            timestamp = os.date("%Y-%m-%d %H:%M:%S")
        })

        -- Setup client connection tracking
        networkManager.connections = {}
        networkManager.clientCounter = 0
    end)

    if not success then
        enhancedLog("ERROR", "Server Initialization Failed", {error = err})
        return false, err
    end
    return true
end


function networkManager.acceptNewConnections()
    if not networkManager.isServer then return end

    -- Initialize slot system if needed
    if not networkManager.clientSlots then
        networkManager.initializeSlotSystem()
    end

    -- Ensure network tracking tables exist
    networkManager.processedConnections = networkManager.processedConnections or {}
    networkManager.lastPortPerIP = networkManager.lastPortPerIP or {}

    while true do
        local client = networkManager.server:accept()
        if not client or not lastAcceptedClient then break end

        local clientIp, clientPort = client:getpeername()
        local uniqueId = string.format("%s:%d", clientIp, clientPort)

        -- Handle paired connection logic
        local isSequentialPort, connectionPair = networkManager.handlePairedConnection(clientIp, clientPort)

        if networkManager.processedConnections[clientPort] == clientPort then
            print(string.format("[DEBUG] Duplicate connection from %s:%d. Closing client.", clientIp, clientPort))
            client:close()
        elseif #networkManager.connections >= CONFIG.MAX_CLIENTS * 2 then
            -- Account for connection pairs (multiply MAX_CLIENTS by 2)
            print(string.format("[NetworkManager] Rejecting connection from %s:%d (Server full)", clientIp, clientPort))
            pcall(function()
                client:send("SERVER_FULL\n")
                client:close()
            end)

            local statusChannel = lovr.thread.getChannel('networkStatus')
            statusChannel:push("SERVER_FULL")
            break
        else
            -- Only assign new slot for the first connection of a pair
            local slotId
            if not isSequentialPort then
                networkManager.maxSlotId = networkManager.maxSlotId + 1
                slotId = networkManager.maxSlotId
                connectionPair.slotId = slotId

                networkManager.clientSlots[slotId] = {
                    lastActivity = os.time(),
                    clientId = string.format("Client_%d_%s", slotId, os.date("%Y%m%d%H%M%S")),
                    clientIp = clientIp,
                    ports = connectionPair.ports
                }
            else
                slotId = connectionPair.slotId
            end

            -- Store the connection
            table.insert(networkManager.connections, {
                socket = client,
                ip = clientIp,
                port = clientPort,
                id = networkManager.clientSlots[slotId].clientId,
                slotId = slotId,
                uniqueId = uniqueId,
                connected_at = os.time(),
                is_sequential = isSequentialPort
            })

            -- Update last port for this IP
            networkManager.lastPortPerIP[clientIp] = clientPort

            -- Mark this port as processed
            networkManager.processedConnections[clientPort] = clientPort

            enhancedLog("INFO", "Client connection processed", {
                slotId = slotId,
                clientId = networkManager.clientSlots[slotId].clientId,
                ip = clientIp,
                port = clientPort,
                isSequential = isSequentialPort
            })

            lastAcceptedClient = false
        end
    end
    lastAcceptedClient = true
end


function networkManager.handleDisconnectionUICleanup(sceneManager)
    if sceneManager then
        -- Clear any overlay scenes first
        if type(sceneManager.clearOverlayScene) == "function" then
            sceneManager.clearOverlayScene()
        end

        -- Safe scene transition
        if type(sceneManager.switchScene) == "function" then
            sceneManager.switchScene('mainMenu')

            -- Only log if we have access to getCurrentScene
            if type(sceneManager.getCurrentScene) == "function" then
                local currentScene = sceneManager.getCurrentScene()
                if currentScene then
                    enhancedLog("INFO", "UI cleaned up after disconnection", {
                        previousScene = currentScene.name
                    })
                else
                    enhancedLog("INFO", "UI cleaned up after disconnection")
                end
            else
                enhancedLog("INFO", "UI cleaned up after disconnection")
            end
        else
            enhancedLog("WARN", "Could not switch scene - sceneManager.switchScene not available")
        end
    else
        enhancedLog("WARN", "Scene cleanup skipped - no sceneManager available")
    end
end


function networkManager.checkConnections()
    print("[NetworkManager] Active connections:")
    for _, conn in ipairs(networkManager.connections) do
        print(string.format(" - Client ID: %s, IP: %s, Port: %d", conn.id, conn.ip, conn.port))
    end
end


function networkManager.getConnectionStatus()
    return {
        is_server = networkManager.isServer,
        port = CONFIG.SERVER_PORT,
        total_connections = networkManager.clientCounter,
        max_clients = CONFIG.MAX_CLIENTS,
        connections = #networkManager.connections
    }
end


function networkManager.setupConnectionMonitorThread()
    local threadCode = [[
        local socket = require 'socket'
        local thread = require 'lovr.thread'

        local statusChannel = thread.getChannel('networkStatus')
        local paramsChannel = thread.getChannel('connectionParams')

        local host = paramsChannel:pop()
        local port = paramsChannel:pop()

        local function monitorConnection(host, port)
            local client = socket.tcp()
            client:settimeout(1)

            local success, connectErr = pcall(function()
                client:connect(host, port)
            end)

            if not success then
                statusChannel:push("DISCONNECTED")
                return
            end

            while true do
                local _, receiveErr = client:receive()
                if receiveErr == "closed" then
                    statusChannel:push("DISCONNECTED")
                    break
                end
                -- Use socket.sleep instead of lovr.thread.sleep
                socket.sleep(1)
            end
        end

        monitorConnection(host, port)
    ]]

    -- Create channels
    networkManager.statusChannel = lovr.thread.getChannel('networkStatus')
    networkManager.paramsChannel = lovr.thread.getChannel('connectionParams')

    -- Create and start monitoring thread
    networkManager.connectionThread = lovr.thread.newThread(threadCode)
    networkManager.connectionThread:start()
end


function networkManager.connectToServer(host)
    if not host then
        print("[NetworkManager] Invalid host")
        return false, "Invalid host"
    end

    -- Ensure previous connection thread is stopped
    if networkManager.connectionThread and networkManager.connectionThread:isRunning() then
        networkManager.connectionThread:stop()
    end

    networkManager.isServer = false
    networkManager.client = socket.tcp()
    networkManager.client:settimeout(CONFIG.CLIENT_TIMEOUT)

    local success, err = networkManager.client:connect(host, CONFIG.SERVER_PORT)
    if success then
        -- Wait briefly for server full response
        local response, err = networkManager.client:receive("*l")
        if response == "SERVER_FULL" then
            networkManager.client:close()
            networkManager.client = nil

            -- Push status to channel
            local statusChannel = lovr.thread.getChannel('networkStatus')
            statusChannel:push("SERVER_FULL")

            return false, "Server is full"
        end

        local statusChannel = lovr.thread.getChannel('networkStatus')
        local paramsChannel = lovr.thread.getChannel('connectionParams')

        -- Clear any existing channel data
        while statusChannel:pop() do end
        while paramsChannel:pop() do end

        paramsChannel:push(host)
        paramsChannel:push(CONFIG.SERVER_PORT)

        networkManager.setupConnectionMonitorThread()
        return true
    else
        print("[NetworkManager] Connection failed:", err)
        networkManager.client = nil
        return false, err
    end
end


function networkManager.broadcast(message)
    if not networkManager.isServer then
        return false, "Client cannot broadcast"
    end

    -- Add scene transition broadcast
    if message == "SCENE_TRANSITION" then
        for _, conn in ipairs(networkManager.connections) do
            conn:send("SERVER_SCENE_CHANGE\n")
        end
    end
end


function networkManager.cleanupClientConnections(clientIp)
    local currentTime = os.time()

    -- Clean up connection tracking
    networkManager.lastPortPerIP[clientIp] = nil

    -- Clean up the paired connection entry
    if networkManager.pairedConnections[clientIp] then
        local slotId = networkManager.pairedConnections[clientIp].slotId
        if slotId then
            networkManager.clientSlots[slotId] = nil
            enhancedLog("INFO", "Freed slot for paired connection", {
                slotId = slotId,
                clientIp = clientIp
            })
        end
        networkManager.pairedConnections[clientIp] = nil
    end

    -- Remove all connections for this IP and clean up processed ports
    for i = #networkManager.connections, 1, -1 do
        local conn = networkManager.connections[i]
        if conn.ip == clientIp then
            networkManager.processedConnections[conn.port] = nil
            table.remove(networkManager.connections, i)
        end
    end

    -- Perform ghost client cleanup
    for slotId, slot in pairs(networkManager.clientSlots) do
        if currentTime - slot.lastActivity > networkManager.ghostTimeout then
            networkManager.clientSlots[slotId] = nil
            if slot.clientIp then
                networkManager.pairedConnections[slot.clientIp] = nil
            end
            enhancedLog("WARN", "Removed ghost client", {
                slotId = slotId,
                inactiveFor = currentTime - slot.lastActivity
            })
        end
    end

    -- Recount active client pairs
    local activeSlots = 0
    for _ in pairs(networkManager.clientSlots) do
        activeSlots = activeSlots + 1
    end

    if activeSlots == 0 then
        networkManager.maxSlotId = 0  -- Reset if no active clients
    end
end


function networkManager.pollConnections()
    for i = #networkManager.connections, 1, -1 do
        local conn = networkManager.connections[i]
        local _, err = conn.socket:receive()

        -- Check if the client disconnected
        if err == "closed" then
            enhancedLog("WARN", "Client Disconnected", {
                clientId = conn.id,
                ip = conn.ip,
                port = conn.port,
                connected_duration = os.time() - conn.connected_at
            })

            -- Close the socket
            pcall(function()
                conn.socket:close()
            end)

            -- Clean up connection tracking for this client
            networkManager.cleanupClientConnections(conn.ip)

            -- Remove the connection
            table.remove(networkManager.connections, i)

            -- Optional: Dynamically adjust max clients if enabled
            if CONFIG.ALLOW_DYNAMIC_SLOTS then
                CONFIG.MAX_CLIENTS = math.max(2, math.ceil(#networkManager.connections / 2))
                enhancedLog("INFO", "Dynamic Client Slot Adjustment", {
                    new_max_clients = CONFIG.MAX_CLIENTS
                })
            end
        end
    end
end


function networkManager.pollMessages()
    if not networkManager.client then return end

    local line, err = networkManager.client:receive()
    if err == "closed" or line == "SERVER_QUIT" then
        print("[NetworkManager] Connection lost or server quit")
        networkManager.resetClient() -- Ensure the client is reset
        networkManager.handleServerDisconnect()
    elseif err then
        print("[NetworkManager] Error while receiving message:", err)
        networkManager.resetClient() -- Handle other errors
    end
end


function networkManager.stop()
    local success, err = pcall(function()
        if networkManager.isServer then
            -- Broadcast server shutdown to clients
            for _, conn in ipairs(networkManager.connections) do
                pcall(function()
                    conn.socket:send("SERVER_QUIT\n")
                    conn.socket:close()
                end)
            end
            networkManager.server:close()
        elseif networkManager.client then
            networkManager.client:send("CLIENT_QUIT\n")
            networkManager.client:close()
        end

        networkManager.server = nil
        networkManager.client = nil
        networkManager.connections = {}
    end)

    if not success then
        print("[NetworkManager] Shutdown error: " .. tostring(err))
    end
    return success
end


function networkManager.handleServerShutdown()
    if not networkManager.isServer and networkManager.client then
        print("[NetworkManager] Forcing client back to main menu")
        networkManager.client:close()
        networkManager.client = nil

        if _G.sceneManager then
            _G.sceneManager.returnToMainMenu("Server Initiated Shutdown")
        end
    end
end


function networkManager.resetClient()
    if networkManager.client then
        -- Try to close the client socket safely
        local success, err = pcall(function()
            networkManager.client:close()
        end)

        if not success then
            print(string.format("[NetworkManager] Error closing client socket: %s", err))
        end

        -- Set the client to nil to prevent further usage
        networkManager.client = nil

        -- Log the reset operation
        print("[NetworkManager] Client connection has been reset.")
    end
end


function networkManager.initConnectionLogging()
    networkManager.lastConnectionLogTime = os.time()
end


function networkManager.checkPeriodicConnectionLog()
    if networkManager.isServer then
        local status = networkManager.getConnectionStatus()
        enhancedLog("STATUS", "Server Connection Overview", status)
    end
end


function networkManager.handleServerDisconnect(sceneManager)
    enhancedLog("INFO", "Handling server disconnect")

    -- Clean up client connection
    if networkManager.client then
        pcall(function()
            networkManager.client:close()
        end)
        networkManager.client = nil
    end

    -- Safely handle UI cleanup
    pcall(function()
        networkManager.handleDisconnectionUICleanup(sceneManager)
    end)
end


function networkManager.verifySceneManager(sceneManager)
    if not sceneManager then
        return false, "sceneManager is nil"
    end

    local required_functions = {
        "clearOverlayScene",
        "switchScene",
        "getCurrentScene"
    }

    local missing_functions = {}
    for _, func_name in ipairs(required_functions) do
        if type(sceneManager[func_name]) ~= "function" then
            table.insert(missing_functions, func_name)
        end
    end

    if #missing_functions > 0 then
        return false, "Missing required functions: " .. table.concat(missing_functions, ", ")
    end

    return true
end


function networkManager.shutdownServer()
    print("[NetworkManager] Shutting down server...")

    -- Notify all clients
    for _, conn in ipairs(networkManager.connections) do
        pcall(function()
            conn.socket:send("SERVER_SHUTDOWN\n")
        end)
    end

    -- Close all sockets
    for _, conn in ipairs(networkManager.connections) do
        conn.socket:close()
    end
    networkManager.server:close()
    networkManager.connections = {}

    print("[NetworkManager] Server shut down successfully.")
end


function networkManager.periodicConnectionLog()
    if networkManager.isServer then
        local status = networkManager.getConnectionStatus()
        enhancedLog("STATUS", "Server Connection Overview", status)
    end
end


function networkManager.setDisconnectCallback(callback)
    networkManager.onDisconnectCallback = callback
end


function networkManager.notifyServerOfDisconnect()
    if not isServer then
        -- Send a disconnection notification to the server
        pcall(function()
            networkManager.client:send("CLIENT_DISCONNECT\n")
            networkManager.client:close()
            networkManager.client = nil
        end)
    end
end


return networkManager
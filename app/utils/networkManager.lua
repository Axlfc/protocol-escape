-- app/utils/networkManager.lua
local socket = require 'socket'
local json = require 'cjson'
local networkManager = {}
local lastAcceptedClient = true


-- Configuration
local CONFIG = {
    SERVER_PORT = 12345,
    CLIENT_TIMEOUT = 5,
    MAX_MESSAGE_SIZE = 1024 * 10,  -- 10KB limit
    MESSAGE_RATE_LIMIT = 100,      -- messages per second
    MAX_CLIENTS = 2
}

-- State management
networkManager.server = nil
networkManager.client = nil
networkManager.isServer = false
networkManager.connections = {}
networkManager.callbacks = {}
networkManager.messageCounters = {}  -- For rate limiting
networkManager.lastCleanup = os.time()


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

    -- Ensure `processedConnections` is initialized
    networkManager.processedConnections = networkManager.processedConnections or {}

    -- Accept pending connections in a loop to handle all at once
    while true do
        -- Always attempt to accept a client connection
        local client = networkManager.server:accept()
        if not client or not lastAcceptedClient then break end

        local clientIp, clientPort = client:getpeername()
        local uniqueId = string.format("%s:%d", clientIp, clientPort)

        -- Check if the connection is already processed
        if #networkManager.connections >= CONFIG.MAX_CLIENTS then
            print(string.format("[NetworkManager] Rejecting connection from %s:%d (Server full)", clientIp, clientPort))
            pcall(function()
                client:send("SERVER_FULL\n")
                client:close()
            end)
            enhancedLog("WARN", "Client rejected due to server being full", {
                ip = clientIp,
                port = clientPort
            })
        elseif networkManager.processedConnections[clientPort] == clientPort then
            print(string.format("[DEBUG] Duplicate connection from %s:%d. Closing client.", clientIp, clientPort))
            client:close()
        else
            -- Register the connection
            networkManager.clientCounter = networkManager.clientCounter + 1
            local clientId = string.format("Client_%d_%s", networkManager.clientCounter, os.date("%Y%m%d%H%M%S"))

            -- Log the new connection
            enhancedLog("INFO", "New Client Connected", {
                clientId = clientId,
                ip = clientIp,
                port = clientPort,
                uniqueId = uniqueId,
                total_connections = #networkManager.connections + 1
            })

            -- Store the connection
            table.insert(networkManager.connections, {
                socket = client,
                ip = clientIp,
                port = clientPort,
                id = clientId,
                uniqueId = uniqueId,
                connected_at = os.time()
            })

            -- Mark this IP as processed
            networkManager.processedConnections[clientIp] = true
            lastAcceptedClient = false
        end
    end
    lastAcceptedClient = true
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


function networkManager.pollConnections()
    for i = #networkManager.connections, 1, -1 do
        local conn = networkManager.connections[i]
        local _, err = conn.socket:receive()

        -- Check if the client disconnected
        if err == "closed" then
            print(string.format("[DEBUG] Client %s:%d disconnected.", conn.ip, conn.port))
            table.remove(networkManager.connections, i)

            -- Allow reconnection by removing processed flag
            if conn.uniqueId then
                networkManager.processedConnections[conn.uniqueId] = nil
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
    print("[NetworkManager] Server has disconnected. Returning to main menu.")

    -- Notify clients
    if networkManager.isServer then
        for _, conn in ipairs(networkManager.connections) do
            pcall(function()
                conn.socket:send("SERVER_SHUTDOWN\n")
            end)
        end
    end

    -- Reset client connection
    if networkManager.client then
        networkManager.client:close()
        networkManager.client = nil
    end

    -- Notify sceneManager
    if sceneManager then
        sceneManager.switchScene('mainMenu')
    end
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
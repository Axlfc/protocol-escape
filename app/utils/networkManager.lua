-- app/utils/networkManager.lua
local socket = require 'socket'
local json = require 'cjson'
local networkManager = {}

-- Configuration
local CONFIG = {
    SERVER_PORT = 12345,
    CLIENT_TIMEOUT = 5,
    MAX_MESSAGE_SIZE = 1024 * 10,  -- 10KB limit
    MESSAGE_RATE_LIMIT = 100,      -- messages per second
    MAX_CLIENTS = 100
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

    local client = networkManager.server:accept()
    if client then
        -- Increment and track client connection
        networkManager.clientCounter = networkManager.clientCounter + 1

        -- Create a unique client identifier
        local clientId = string.format("Client_%d_%s",
            networkManager.clientCounter,
            os.date("%Y%m%d%H%M%S")
        )

        -- Log detailed client connection
        enhancedLog("CONNECTION", "New Client Connected", {
            client_id = clientId,
            total_connections = networkManager.clientCounter,
            connection_time = os.date("%Y-%m-%d %H:%M:%S")
        })

        -- Store client connection details
        table.insert(networkManager.connections, {
            socket = client,
            id = clientId,
            connected_at = os.time()
        })

        return client, clientId
    end
end


function networkManager.getConnectionStatus()
    if not networkManager.isServer then
        return {
            is_server = false,
            message = "Not running in server mode"
        }
    end

    return {
        is_server = true,
        port = CONFIG.SERVER_PORT,
        total_connections = networkManager.clientCounter or 0,
        max_clients = CONFIG.MAX_CLIENTS,
        connections = #(networkManager.connections or {})
    }
end


function networkManager.connectToServer(host)
    if not host then
        log("ERROR", "Invalid host provided")
        return false, "Invalid host"
    end

    networkManager.isServer = false
    networkManager.client = socket.tcp()
    networkManager.client:settimeout(CONFIG.CLIENT_TIMEOUT)

    local success, err = networkManager.client:connect(host, CONFIG.SERVER_PORT)
    if success then
        log("INFO", "Client Connection Established")
        print(string.format("[NetworkManager] Connected to Server: %s", host))
        print(string.format("[NetworkManager] Server Port: %d", CONFIG.SERVER_PORT))
        return true
    else
        log("ERROR", "Connection Failed", {host = host, error = err})
        print(string.format("[NetworkManager] Client Connection to %s Failed", host))
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


function networkManager.pollMessages()
    if networkManager.client then
        local line, err = networkManager.client:receive()
        if line == "SERVER_QUIT" then
            networkManager.handleServerDisconnect()
        elseif err == "closed" then
            networkManager.handleServerDisconnect()
        end
    end
end


function networkManager.stop()
    local success, err = pcall(function()
        if networkManager.isServer then
            for _, conn in ipairs(networkManager.connections) do
                conn:close()
            end
            networkManager.server:close()
            log("INFO", "Server stopped")
        elseif networkManager.client then
            networkManager.client:close()
            log("INFO", "Disconnected from server")
        end

        networkManager.server = nil
        networkManager.client = nil
        networkManager.connections = {}
        networkManager.messageCounters = {}
    end)

    if not success then
        log("ERROR", "Error during shutdown", {error = err})
        return false, err
    end
    return true
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


function networkManager.initConnectionLogging()
    networkManager.lastConnectionLogTime = os.time()
end


function networkManager.checkPeriodicConnectionLog()
    if not networkManager.isServer then return end

    local currentTime = os.time()
    if (networkManager.lastConnectionLogTime or 0) + (CONFIG.CONNECTION_LOG_INTERVAL or 0) <= currentTime then
        local status = networkManager.getConnectionStatus()
        local totalConnections = status.total_connections or 0
        enhancedLog("STATUS", "Server Connection Overview", {
            port = status.port,
            max_clients = status.max_clients,
            total_connections = totalConnections,
            is_server = status.is_server,
            connections = status.connections
        })

        -- Update the last log time
        networkManager.lastConnectionLogTime = currentTime
    end
end


function networkManager.handleServerDisconnect()
    if not networkManager.isServer and _G.sceneManager then
        _G.sceneManager.switchScene('mainMenu')
    end
end


function networkManager.shutdownServer()
    if networkManager.isServer then
        print("[NetworkManager] Shutting down server.")
        networkManager.connectionStatus = false

        -- Trigger disconnect callback if set
        if networkManager.onDisconnectCallback then
            networkManager.onDisconnectCallback()
        end
    end
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


return networkManager
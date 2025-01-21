-- app/utils/logger.lua
local logger = {}
logger.logs = {}

-- Helper function to get the current timestamp
local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Function to log a warning message
function logger.warn(message)
    local logEntry = {
        type = "warning",
        message = message,
        timestamp = getTimestamp()
    }
    print(string.format("[%s] [WARNING] %s", logEntry.timestamp, logEntry.message))
    table.insert(logger.logs, logEntry)
end

-- Function to log an info message
function logger.info(message)
    local logEntry = {
        type = "info",
        message = message,
        timestamp = getTimestamp()
    }
    print(string.format("[%s] [INFO] %s", logEntry.timestamp, logEntry.message))
    table.insert(logger.logs, logEntry)
end

-- Function to retrieve all logs
function logger.getLogs()
    return logger.logs
end

return logger
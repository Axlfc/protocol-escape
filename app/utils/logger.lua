-- app/utils/logger.lua
local logger = {}

logger.logs = {}

function logger.warn(message)
    print("[WARNING] " .. message)
    table.insert(logger.logs, { type = "warning", message = message })
end

function logger.info(message)
    print("[INFO] " .. message)
    table.insert(logger.logs, { type = "info", message = message })
end

function logger.getLogs()
    return logger.logs
end

return logger

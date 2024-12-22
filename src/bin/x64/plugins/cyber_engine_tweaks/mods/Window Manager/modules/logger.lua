---@class logger
---@method info(message: string)
---@method error(message: string)
---@method warn(message: string)

local logger = {}
logger.__index = logger

function logger:info(message)
    print(message)
    spdlog.info(tostring(message))
end

function logger:error(message)
    print(message)
    spdlog.error(tostring(message))
end

function logger:warn(message)
    print(message)
    spdlog.error(tostring(message))
end

return logger

local Logger = {}

Logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4
}

local COLORS = {
    DEBUG = "\27[36m",   -- Cyan
    INFO = "\27[32m",    -- Green
    WARNING = "\27[33m", -- Yellow
    ERROR = "\27[31m",   -- Red
    RESET = "\27[0m"
}

local function checkDebugMode()
    if arg then
        for i, v in ipairs(arg) do
            if v == "--debug" then
                return true
            end
        end
    end
    return false
end

-- Checks the debug mode at startup
Logger.currentLevel = checkDebugMode() and Logger.LEVELS.DEBUG or Logger.LEVELS.INFO

local function getTimestamp()
    return os.date("%H:%M:%S")
end

local function formatMessage(level, message, source)
    local timestamp = getTimestamp()
    local sourceStr = source and (" [" .. source .. "]") or ""
    local coloredLevel = COLORS[level] .. level .. COLORS.RESET
    return string.format("[%s] %s%s: %s", timestamp, coloredLevel, sourceStr, tostring(message))
end

local function log(level, levelName, message, source)
    if level >= Logger.currentLevel then
        local formatted = formatMessage(levelName, message, source)
        print(formatted)
        io.stdout:flush()
    end
end

function Logger.debug(message, source)
    log(Logger.LEVELS.DEBUG, "DEBUG", message, source)
end

function Logger.info(message, source)
    log(Logger.LEVELS.INFO, "INFO", message, source)
end

function Logger.warning(message, source)
    log(Logger.LEVELS.WARNING, "WARNING", message, source)
end

function Logger.error(message, source)
    log(Logger.LEVELS.ERROR, "ERROR", message, source)
end

function Logger.setLevel(level)
    Logger.currentLevel = level
end

function Logger.disable()
    Logger.currentLevel = math.huge
end

function Logger.enable()
    Logger.currentLevel = Logger.LEVELS.DEBUG
end

return Logger

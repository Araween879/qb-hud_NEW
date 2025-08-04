-- ================================================================
-- QBCore HUD - Time & Weather System Module
-- Version: 3.0.0
-- Description: Time display and weather integration system
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Time System Module
Time = Time or {}
Time.Initialized = false
Time.Visible = true
Time.LastUpdate = 0
Time.UpdateInterval = Config.Modules.time.updateInterval or 1000

-- Time Status Data
Time.Status = {
    -- Current time
    hours = 0,
    minutes = 0,
    seconds = 0,
    
    -- Formatted displays
    time12h = "12:00 AM",            -- 12-hour format
    time24h = "00:00",               -- 24-hour format
    timeDisplay = "00:00",           -- Current display format
    
    -- Date information
    day = 0,                         -- Day of week (0-6)
    dayName = "Monday",              -- Day name
    month = 0,                       -- Month (0-11)
    monthName = "January",           -- Month name
    dayOfMonth = 1,                  -- Day of month (1-31)
    year = 2024,                     -- Year
    dateDisplay = "Monday, January 1st", -- Formatted date
    
    -- Weather information (if available)
    weather = {
        current = "CLEAR",           -- Current weather
        temperature = 20,            -- Temperature in Celsius
        windSpeed = 0,               -- Wind speed
        windDirection = 0,           -- Wind direction
        humidity = 50,               -- Humidity percentage
        available = false            -- Weather system available
    },
    
    -- Configuration
    format24h = true,                -- Use 24-hour format
    showSeconds = false,             -- Show seconds
    showDate = true,                 -- Show date
    showWeather = false,             -- Show weather info
    showTemperature = false          -- Show temperature
}

-- Weather System Integration
Time.Weather = {
    resource = nil,                  -- Weather resource name
    available = false,               -- Weather system available
    lastWeatherUpdate = 0           -- Last weather update time
}

-- Performance tracking
Time.Performance = {
    updateCount = 0,
    averageUpdateTime = 0,
    skippedUpdates = 0
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Time module
---@return boolean success
function Time.Init()
    if Time.Initialized then
        HUD.Debug("Time module already initialized", "TIME", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Time module...", "TIME", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.time.enabled then
        HUD.Debug("Time module disabled in config", "TIME", "INFO")
        return false
    end
    
    -- Load configuration
    Time.LoadConfiguration()
    
    -- Initialize weather system
    Time.InitializeWeatherSystem()
    
    -- Register events
    Time.RegisterEvents()
    
    -- Register NUI callbacks
    Time.RegisterNUICallbacks()
    
    -- Start update thread
    Time.StartUpdateThread()
    
    Time.Initialized = true
    HUD.Debug("Time module initialized successfully", "TIME", "INFO")
    
    -- Send initial update
    Time.ForceUpdate()
    
    return true
end

---Load Time module configuration
function Time.LoadConfiguration()
    local config = Config.Modules.time or {}
    
    Time.Status.format24h = config.format24h or true
    Time.Status.showDate = config.showDate or true
    Time.Status.showWeather = config.showWeather or false
    Time.Status.showTemperature = config.showTemperature or false
    Time.Status.showSeconds = config.showSeconds or false
    
    Time.UpdateInterval = config.updateInterval or 1000
    
    HUD.Debug("Time configuration loaded", "TIME", "INFO")
end

---Initialize weather system integration
function Time.InitializeWeatherSystem()
    -- Check for weather resources
    local weatherResources = {'weathersync', 'qb-weathersync', 'vSync'}
    
    for _, resource in ipairs(weatherResources) do
        if GetResourceState(resource) == 'started' then
            Time.Weather.resource = resource
            Time.Weather.available = true
            Time.Status.weather.available = true
            HUD.Debug(string.format("Weather resource detected: %s", resource), "TIME", "INFO")
            
            -- Enable weather display if resource is available
            if Time.Status.showWeather then
                Time.StartWeatherUpdateThread()
            end
            break
        end
    end
    
    if not Time.Weather.available then
        HUD.Debug("No weather resource detected - weather display disabled", "TIME", "WARN")
        Time.Status.showWeather = false
        Time.Status.weather.available = false
    end
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register Time module events
function Time.RegisterEvents()
    -- Player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Time.ForceUpdate()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Time.SetVisible(false)
    end)
    
    -- Time control events
    RegisterNetEvent('hud:client:toggleTime', function(visible)
        Time.SetVisible(visible)
    end)
    
    RegisterNetEvent('hud:client:setTimeFormat', function(format24h)
        Time.SetFormat(format24h)
    end)
    
    -- Weather events (if weather system is available)
    if Time.Weather.available then
        RegisterNetEvent('weathersync:client:SyncWeather', function(weather, blackout, timeOffset)
            Time.UpdateWeatherFromSync(weather)
        end)
        
        -- Alternative weather events for different resources
        RegisterNetEvent('qb-weathersync:client:SyncWeather', function(weather)
            Time.UpdateWeatherFromSync(weather)
        end)
    end
    
    HUD.Debug("Time events registered", "TIME", "INFO")
end

---Register NUI callbacks
function Time.RegisterNUICallbacks()
    RegisterNUICallback('timeClick', function(data, cb)
        Time.OnTimeClick()
        cb('ok')
    end)
    
    RegisterNUICallback('toggleTimeFormat', function(data, cb)
        Time.ToggleFormat()
        cb('ok')
    end)
    
    RegisterNUICallback('getTimeDetails', function(data, cb)
        cb(Time.GetDetailedStatus())
    end)
    
    HUD.Debug("Time NUI callbacks registered", "TIME", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM
-- ================================================================

---Start the time update thread
function Time.StartUpdateThread()
    CreateThread(function()
        while Time.Initialized do
            local currentTime = GetGameTimer()
            
            if currentTime - Time.LastUpdate >= Time.UpdateInterval then
                local startTime = GetGameTimer()
                
                Time.UpdateTimeStatus()
                Time.SendToNUI()
                
                Time.LastUpdate = currentTime
                Time.Performance.updateCount = Time.Performance.updateCount + 1
                
                -- Performance tracking
                local updateTime = GetGameTimer() - startTime
                Time.Performance.averageUpdateTime = 
                    (Time.Performance.averageUpdateTime + updateTime) / 2
            else
                Time.Performance.skippedUpdates = Time.Performance.skippedUpdates + 1
            end
            
            Wait(100) -- Check every 100ms but only update based on interval
        end
    end)
    
    HUD.Debug("Time update thread started", "TIME", "INFO")
end

---Start weather update thread (if weather system available)
function Time.StartWeatherUpdateThread()
    if not Time.Weather.available then return end
    
    CreateThread(function()
        while Time.Initialized and Time.Status.showWeather do
            Time.UpdateWeatherStatus()
            Wait(30000) -- Update weather every 30 seconds
        end
    end)
    
    HUD.Debug("Weather update thread started", "TIME", "INFO")
end

---Update time status
function Time.UpdateTimeStatus()
    -- Get current game time
    Time.Status.hours = GetClockHours()
    Time.Status.minutes = GetClockMinutes()
    Time.Status.seconds = GetClockSeconds()
    
    -- Format time displays
    Time.FormatTimeDisplays()
    
    -- Update date information
    Time.UpdateDateStatus()
end

---Format time displays
function Time.FormatTimeDisplays()
    local hours = Time.Status.hours
    local minutes = Time.Status.minutes
    local seconds = Time.Status.seconds
    
    -- 24-hour format
    if Time.Status.showSeconds then
        Time.Status.time24h = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
        Time.Status.time24h = string.format("%02d:%02d", hours, minutes)
    end
    
    -- 12-hour format
    local displayHour = hours
    local ampm = "AM"
    
    if hours == 0 then
        displayHour = 12
    elseif hours > 12 then
        displayHour = hours - 12
        ampm = "PM"
    elseif hours == 12 then
        ampm = "PM"
    end
    
    if Time.Status.showSeconds then
        Time.Status.time12h = string.format("%d:%02d:%02d %s", displayHour, minutes, seconds, ampm)
    else
        Time.Status.time12h = string.format("%d:%02d %s", displayHour, minutes, ampm)
    end
    
    -- Set current display format
    Time.Status.timeDisplay = Time.Status.format24h and Time.Status.time24h or Time.Status.time12h
end

---Update date status
function Time.UpdateDateStatus()
    -- Get date components
    Time.Status.day = GetClockDayOfWeek()
    Time.Status.month = GetClockMonth()
    Time.Status.dayOfMonth = GetClockDayOfMonth()
    
    -- Day names
    local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    Time.Status.dayName = dayNames[Time.Status.day + 1]
    
    -- Month names
    local monthNames = {"January", "February", "March", "April", "May", "June", 
                       "July", "August", "September", "October", "November", "December"}
    Time.Status.monthName = monthNames[Time.Status.month + 1]
    
    -- Add ordinal suffix to day
    local suffix = "th"
    local day = Time.Status.dayOfMonth
    if day % 10 == 1 and day ~= 11 then suffix = "st"
    elseif day % 10 == 2 and day ~= 12 then suffix = "nd"
    elseif day % 10 == 3 and day ~= 13 then suffix = "rd"
    end
    
    -- Format date display
    Time.Status.dateDisplay = string.format("%s, %s %d%s", 
                                           Time.Status.dayName, 
                                           Time.Status.monthName, 
                                           Time.Status.dayOfMonth, 
                                           suffix)
end

---Update weather status
function Time.UpdateWeatherStatus()
    if not Time.Weather.available then return end
    
    -- Get current weather
    Time.Status.weather.current = GetPrevWeatherTypeHashName() or "CLEAR"
    
    -- Get wind information
    Time.Status.weather.windSpeed = GetWindSpeed()
    Time.Status.weather.windDirection = GetWindDirection()
    
    -- Temperature (simulated based on weather and time)
    Time.Status.weather.temperature = Time.CalculateTemperature()
    
    -- Humidity (simulated)
    Time.Status.weather.humidity = Time.CalculateHumidity()
    
    Time.Weather.lastWeatherUpdate = GetGameTimer()
end

---Calculate temperature based on weather and time
---@return number temperature
function Time.CalculateTemperature()
    local baseTemp = 20 -- Base temperature in Celsius
    local weather = Time.Status.weather.current
    local hour = Time.Status.hours
    
    -- Weather modifiers
    local weatherMods = {
        CLEAR = 0,
        EXTRASUNNY = 5,
        CLOUDS = -2,
        OVERCAST = -5,
        RAIN = -8,
        THUNDER = -10,
        CLEARING = -3,
        NEUTRAL = 0,
        SNOW = -15,
        BLIZZARD = -20,
        SNOWLIGHT = -10,
        XMAS = -5,
        HALLOWEEN = -3
    }
    
    -- Time of day modifier
    local timemod = 0
    if hour >= 6 and hour < 12 then
        timemod = math.sin((hour - 6) * math.pi / 6) * 5 -- Morning warming
    elseif hour >= 12 and hour < 18 then
        timemod = 5 - math.sin((hour - 12) * math.pi / 6) * 3 -- Afternoon cooling
    elseif hour >= 18 and hour < 24 then
        timemod = 2 - math.sin((hour - 18) * math.pi / 6) * 7 -- Evening cooling
    else
        timemod = -5 - math.sin(hour * math.pi / 6) * 3 -- Night cooling
    end
    
    local weatherMod = weatherMods[weather] or 0
    return math.floor(baseTemp + weatherMod + timemod)
end

---Calculate humidity based on weather
---@return number humidity
function Time.CalculateHumidity()
    local weather = Time.Status.weather.current
    
    local humidityValues = {
        CLEAR = 30,
        EXTRASUNNY = 25,
        CLOUDS = 50,
        OVERCAST = 65,
        RAIN = 90,
        THUNDER = 95,
        CLEARING = 40,
        NEUTRAL = 45,
        SNOW = 70,
        BLIZZARD = 80,
        SNOWLIGHT = 60,
        XMAS = 55,
        HALLOWEEN = 60
    }
    
    return humidityValues[weather] or 50
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send time data to NUI
function Time.SendToNUI()
    if not Time.Visible then return end
    
    local timeData = {
        -- Time information
        time = Time.Status.timeDisplay,
        time24h = Time.Status.time24h,
        time12h = Time.Status.time12h,
        hours = Time.Status.hours,
        minutes = Time.Status.minutes,
        seconds = Time.Status.seconds,
        
        -- Date information
        date = Time.Status.dateDisplay,
        dayName = Time.Status.dayName,
        monthName = Time.Status.monthName,
        dayOfMonth = Time.Status.dayOfMonth,
        
        -- Weather information (if available)
        weather = Time.Status.weather,
        
        -- Configuration
        format24h = Time.Status.format24h,
        showDate = Time.Status.showDate,
        showWeather = Time.Status.showWeather,
        showTemperature = Time.Status.showTemperature,
        showSeconds = Time.Status.showSeconds
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'updateTime',
        data = timeData
    })
    
    -- Also send to UIManager if available
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('time', timeData)
    end
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle weather update from sync
---@param weather string Weather type
function Time.UpdateWeatherFromSync(weather)
    if weather and type(weather) == "string" then
        Time.Status.weather.current = weather
        HUD.Debug(string.format("Weather updated from sync: %s", weather), "TIME", "INFO")
        Time.SendToNUI()
    end
end

---Handle time click event
function Time.OnTimeClick()
    if Config.GPSHUD.interaction.clickableIcons then
        -- Toggle time format
        Time.ToggleFormat()
        
        -- Show detailed time information
        local message = string.format("Time: %s | Date: %s", 
                                     Time.Status.timeDisplay, 
                                     Time.Status.dateDisplay)
        
        if Time.Status.showWeather and Time.Weather.available then
            message = message .. string.format(" | Weather: %s", Time.Status.weather.current)
            
            if Time.Status.showTemperature then
                message = message .. string.format(" (%d°C)", Time.Status.weather.temperature)
            end
        end
        
        QBCore.Functions.Notify(message, 'primary')
        
        HUD.Debug("Time clicked - format toggled and info shown", "TIME", "INFO")
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set time module visibility
---@param visible boolean Visibility state
function Time.SetVisible(visible)
    Time.Visible = visible
    
    HUD.Debug(string.format("Time visibility set to: %s", visible and "visible" or "hidden"), "TIME", "INFO")
    
    if visible then
        Time.SendToNUI()
    else
        SendNUIMessage({
            action = 'toggleModule',
            module = 'time',
            visible = false
        })
    end
end

---Get time module visibility
---@return boolean visible
function Time.IsVisible()
    return Time.Visible
end

---Set time format
---@param format24h boolean Use 24-hour format
function Time.SetFormat(format24h)
    if type(format24h) == "boolean" then
        Time.Status.format24h = format24h
        Time.FormatTimeDisplays()
        Time.SendToNUI()
        
        HUD.Debug(string.format("Time format set to: %s", format24h and "24h" or "12h"), "TIME", "INFO")
    end
end

---Toggle time format between 12h and 24h
function Time.ToggleFormat()
    Time.SetFormat(not Time.Status.format24h)
end

---Get current time status
---@return table status
function Time.GetStatus()
    return Time.Status
end

---Get detailed time status
---@return table detailedStatus
function Time.GetDetailedStatus()
    return {
        status = Time.Status,
        weather = Time.Weather,
        performance = Time.Performance,
        config = Config.Modules.time
    }
end

---Force update time display
function Time.ForceUpdate()
    Time.UpdateTimeStatus()
    if Time.Weather.available and Time.Status.showWeather then
        Time.UpdateWeatherStatus()
    end
    Time.SendToNUI()
    
    HUD.Debug("Time force update triggered", "TIME", "INFO")
end

---Set theme for time module
---@param theme string Theme name
function Time.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("Time theme set to: %s", theme), "TIME", "INFO")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get time in specific format
---@param format string Format type ('12h', '24h', 'timestamp')
---@return string formattedTime
function Time.GetFormattedTime(format)
    format = format or 'current'
    
    if format == '12h' then
        return Time.Status.time12h
    elseif format == '24h' then
        return Time.Status.time24h
    elseif format == 'timestamp' then
        return string.format("%02d%02d%02d", Time.Status.hours, Time.Status.minutes, Time.Status.seconds)
    else
        return Time.Status.timeDisplay
    end
end

---Get weather display string
---@return string weatherDisplay
function Time.GetWeatherDisplay()
    if not Time.Weather.available or not Time.Status.showWeather then
        return ""
    end
    
    local weather = Time.Status.weather.current
    local display = weather:gsub("_", " "):lower():gsub("^%l", string.upper)
    
    if Time.Status.showTemperature then
        display = display .. string.format(" (%d°C)", Time.Status.weather.temperature)
    end
    
    return display
end

---Check if it's day time
---@return boolean isDaytime
function Time.IsDaytime()
    local hour = Time.Status.hours
    return hour >= 6 and hour < 20
end

---Check if it's night time
---@return boolean isNighttime
function Time.IsNighttime()
    return not Time.IsDaytime()
end

---Get performance statistics
---@return table performance
function Time.GetPerformanceStats()
    return {
        initialized = Time.Initialized,
        visible = Time.Visible,
        updateInterval = Time.UpdateInterval,
        updateCount = Time.Performance.updateCount,
        averageUpdateTime = Time.Performance.averageUpdateTime,
        skippedUpdates = Time.Performance.skippedUpdates,
        lastUpdate = Time.LastUpdate,
        weatherAvailable = Time.Weather.available,
        weatherResource = Time.Weather.resource
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function Time.Cleanup()
    Time.Initialized = false
    Time.Visible = false
    
    HUD.Debug("Time module cleaned up", "TIME", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Time.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make Time module available globally
_G.Time = Time

HUD.Debug("Time module loaded", "TIME", "INFO")
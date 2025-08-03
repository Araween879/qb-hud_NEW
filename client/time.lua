-- ================================================================
-- QBCore HUD - Time System Module
-- Version: 3.0.0
-- Description: Manages time, date, and weather display
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local Time = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current time values
local currentHour = 0
local currentMinute = 0
local currentDay = 1
local currentMonth = 1
local currentYear = 2024
local currentWeather = "CLEAR"

-- Time format settings
local format24h = true

-- Month names for display
local monthNames = {
    [1] = "January", [2] = "February", [3] = "March", [4] = "April",
    [5] = "May", [6] = "June", [7] = "July", [8] = "August",
    [9] = "September", [10] = "October", [11] = "November", [12] = "December"
}

-- Weather display mapping
local weatherIcons = {
    ["CLEAR"] = "fas fa-sun",
    ["EXTRASUNNY"] = "fas fa-sun",
    ["CLOUDS"] = "fas fa-cloud",
    ["OVERCAST"] = "fas fa-cloud",
    ["RAIN"] = "fas fa-cloud-rain",
    ["THUNDER"] = "fas fa-bolt",
    ["CLEARING"] = "fas fa-cloud-sun",
    ["NEUTRAL"] = "fas fa-cloud",
    ["SNOW"] = "fas fa-snowflake",
    ["BLIZZARD"] = "fas fa-snowflake",
    ["SNOWLIGHT"] = "fas fa-snowflake",
    ["FOGGY"] = "fas fa-smog"
}

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Time module
function Time.Init()
    if isInitialized then
        HUD.Debug("^3Time module already initialized^7", "TIME")
        return true
    end
    
    HUD.Debug("^2Initializing Time module^7", "TIME")
    
    -- Get initial settings from config
    format24h = Config.Modules.time.format24h or true
    
    -- Register events
    Time.RegisterEvents()
    
    -- Start update thread
    Time.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.time.enabled
    
    -- Get initial time
    Time.UpdateTime()
    
    isInitialized = true
    HUD.Debug("^2Time module initialized successfully^7", "TIME")
    
    return true
end

---Register all time-related events
function Time.RegisterEvents()
    -- Weather sync events (if weather resource is available)
    RegisterNetEvent('qb-weathersync:client:SyncWeather', function(newweather, blackout)
        currentWeather = newweather or "CLEAR"
        Time.SendUpdate()
        HUD.Debug(string.format("^2Weather updated: %s^7", currentWeather), "TIME")
    end)
    
    -- Time sync events
    RegisterNetEvent('qb-weathersync:client:SyncTime', function(hour, minute)
        if hour and minute then
            currentHour = hour
            currentMinute = minute
            Time.SendUpdate()
        end
    end)
    
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'time' then
            Time.SetVisible(visible)
        end
    end)
    
    -- Time format change event
    RegisterNetEvent('hud:client:setTimeFormat', function(use24h)
        format24h = use24h
        Time.SendUpdate()
        HUD.Debug(string.format("^2Time format changed to: %s^7", use24h and "24h" or "12h"), "TIME")
    end)
    
    HUD.Debug("^2Time events registered^7", "TIME")
end

---Start the time update thread
function Time.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Time update thread already running^7", "TIME")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible then
                Time.UpdateTime()
            end
            Wait(Config.Modules.time.updateInterval or 1000)
        end
    end)
    
    HUD.Debug("^2Time update thread started^7", "TIME")
end

---Update time and date values
function Time.UpdateTime()
    -- Get game time
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local day = GetClockDayOfMonth()
    local month = GetClockMonth()
    
    -- Check for changes (optimization)
    if hour ~= currentHour or minute ~= currentMinute or day ~= currentDay or month ~= currentMonth then
        currentHour = hour
        currentMinute = minute
        currentDay = day
        currentMonth = month
        
        Time.SendUpdate()
    end
end

---Send current time data to NUI
function Time.SendUpdate()
    if not isVisible then return end
    
    local timeData = {
        time = {
            hour = currentHour,
            minute = currentMinute,
            formatted = Time.GetFormattedTime(),
            format24h = format24h
        },
        date = {
            day = currentDay,
            month = currentMonth,
            monthName = monthNames[currentMonth] or "Unknown",
            year = currentYear,
            formatted = Time.GetFormattedDate()
        },
        weather = {
            current = currentWeather,
            icon = weatherIcons[currentWeather] or "fas fa-sun",
            enabled = Config.Modules.time.showWeather
        },
        config = {
            showDate = Config.Modules.time.showDate,
            showWeather = Config.Modules.time.showWeather
        }
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('time', timeData)
    end
end

-- ================================================================
-- TIME FORMATTING FUNCTIONS
-- ================================================================

---Get formatted time string
---@return string
function Time.GetFormattedTime()
    if format24h then
        return string.format("%02d:%02d", currentHour, currentMinute)
    else
        local hour12 = currentHour
        local ampm = "AM"
        
        if currentHour == 0 then
            hour12 = 12
        elseif currentHour >= 12 then
            ampm = "PM"
            if currentHour > 12 then
                hour12 = currentHour - 12
            end
        end
        
        return string.format("%d:%02d %s", hour12, currentMinute, ampm)
    end
end

---Get formatted date string
---@return string
function Time.GetFormattedDate()
    return string.format("%d. %s %d", currentDay, monthNames[currentMonth] or "Unknown", currentYear)
end

---Get short date string
---@return string
function Time.GetShortDate()
    return string.format("%02d/%02d/%d", currentDay, currentMonth, currentYear)
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the time module
---@param visible boolean
function Time.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Time visibility set to: %s^7", visible and "visible" or "hidden"), "TIME")
    
    if visible then
        Time.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('time', { visible = false })
        end
    end
end

---Get current time module visibility
---@return boolean
function Time.IsVisible()
    return isVisible
end

---Get current time data
---@return table
function Time.GetTimeData()
    return {
        hour = currentHour,
        minute = currentMinute,
        day = currentDay,
        month = currentMonth,
        year = currentYear,
        weather = currentWeather,
        formatted = Time.GetFormattedTime(),
        formattedDate = Time.GetFormattedDate()
    }
end

---Force update time display
function Time.ForceUpdate()
    Time.UpdateTime()
    Time.SendUpdate()
    HUD.Debug("^2Time force update triggered^7", "TIME")
end

---Set time format
---@param use24h boolean Use 24-hour format
function Time.SetTimeFormat(use24h)
    format24h = use24h
    Time.SendUpdate()
    HUD.Debug(string.format("^2Time format set to: %s^7", use24h and "24h" or "12h"), "TIME")
end

---Set weather manually (for testing or external integration)
---@param weather string Weather type
function Time.SetWeather(weather)
    if type(weather) ~= "string" then return false end
    
    currentWeather = weather:upper()
    Time.SendUpdate()
    HUD.Debug(string.format("^2Weather manually set to: %s^7", currentWeather), "TIME")
    return true
end

---Get current weather
---@return string
function Time.GetWeather()
    return currentWeather
end

---Get weather icon for current weather
---@return string
function Time.GetWeatherIcon()
    return weatherIcons[currentWeather] or "fas fa-sun"
end

-- ================================================================
-- SERVER TIME INTEGRATION
-- ================================================================

-- Try to get server time from QBCore if available
CreateThread(function()
    Wait(5000) -- Wait for other resources to load
    
    if isInitialized then
        -- Check if QBCore has server time functions
        if QBCore.Functions.GetCurrentTime then
            local serverTime = QBCore.Functions.GetCurrentTime()
            if serverTime then
                currentHour = serverTime.hour or currentHour
                currentMinute = serverTime.min or currentMinute
                Time.SendUpdate()
                HUD.Debug("^2Server time synchronized^7", "TIME")
            end
        end
    end
end)

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('time', Time)
end

-- Export Time functions for external use
_G.Time = Time

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Time module shutting down^7", "TIME")
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)
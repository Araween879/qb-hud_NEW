-- ================================================================
-- QBCore HUD - Status System Module (COMPATIBILITY MODULE)
-- Version: 3.0.0
-- Description: Legacy status indicators (voice, radio, armed, etc.)
--              NOTE: This module is DISABLED by default as GPS-HUD handles these
--              It exists for backward compatibility and can be enabled if needed
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Status System Module
Status = Status or {}
Status.Initialized = false
Status.Visible = false -- Disabled by default - GPS-HUD handles this
Status.LastUpdate = 0
Status.UpdateInterval = Config.Modules.status.updateInterval or 200

-- Status Data Cache
Status.Data = {
    -- Voice System (handled by GPS-HUD)
    voice = {
        level = 2,                  -- Voice level 1-4
        talking = false,            -- Currently talking
        radioActive = false,        -- Radio active
        radioChannel = 0,           -- Radio channel
        radioTalking = false        -- Talking on radio
    },
    
    -- Player Status Indicators
    indicators = {
        armed = false,              -- Player has weapon equipped
        parachute = false,          -- Player has parachute
        diving = false,             -- Player is diving/underwater
        harness = false,            -- Racing harness equipped
        dev_mode = false,           -- Developer mode active
        cruise = false              -- Cruise control active
    },
    
    -- System Status
    system = {
        fps = 60,                   -- Current FPS
        ping = 0,                   -- Network ping
        players = 0,                -- Online players
        serverTime = "00:00"        -- Server time
    }
}

-- Performance tracking
Status.Performance = {
    updateCount = 0,
    averageUpdateTime = 0,
    skippedUpdates = 0
}

-- Integration status
Status.Integration = {
    voiceResource = nil,
    radioResource = nil,
    voiceAvailable = false,
    radioAvailable = false
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Status module
---@return boolean success
function Status.Init()
    if Status.Initialized then
        HUD.Debug("Status module already initialized", "STATUS", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Status module...", "STATUS", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.status.enabled then
        HUD.Debug("Status module disabled in config (GPS-HUD handles status)", "STATUS", "INFO")
        return false
    end
    
    -- Load configuration
    Status.LoadConfiguration()
    
    -- Initialize voice integration
    Status.InitializeVoiceIntegration()
    
    -- Register events
    Status.RegisterEvents()
    
    -- Register NUI callbacks
    Status.RegisterNUICallbacks()
    
    -- Start update thread
    Status.StartUpdateThread()
    
    Status.Initialized = true
    Status.Visible = true
    
    HUD.Debug("Status module initialized successfully", "STATUS", "INFO")
    
    return true
end

---Load Status module configuration
function Status.LoadConfiguration()
    local config = Config.Modules.status or {}
    
    Status.UpdateInterval = config.updateInterval or 200
    
    -- Load component settings
    Status.Components = {
        voice = config.components.voice or false,      -- Disabled - GPS-HUD handles this
        radio = config.components.radio or false,      -- Disabled - GPS-HUD handles this
        armed = config.components.armed or true,
        parachute = config.components.parachute or true,
        harness = config.components.harness or true,
        cruise = config.components.cruise or true,
        dev_mode = config.components.dev_mode or true
    }
    
    HUD.Debug("Status configuration loaded", "STATUS", "INFO")
end

---Initialize voice system integration
function Status.InitializeVoiceIntegration()
    -- Check for voice systems (but GPS-HUD handles this primarily)
    if GetResourceState('pma-voice') == 'started' then
        Status.Integration.voiceResource = 'pma-voice'
        Status.Integration.voiceAvailable = true
        HUD.Debug("pma-voice detected (handled by GPS-HUD)", "STATUS", "INFO")
    end
    
    -- Check for radio systems
    local radioResources = {'pma-voice', 'rp-radio', 'qb-radio'}
    for _, resource in ipairs(radioResources) do
        if GetResourceState(resource) == 'started' then
            Status.Integration.radioResource = resource
            Status.Integration.radioAvailable = true
            HUD.Debug(string.format("Radio resource detected: %s (handled by GPS-HUD)", resource), "STATUS", "INFO")
            break
        end
    end
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register Status module events
function Status.RegisterEvents()
    -- Player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Status.RefreshStatus()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Status.SetVisible(false)
    end)
    
    -- Status control events
    RegisterNetEvent('hud:client:toggleStatus', function(visible)
        Status.SetVisible(visible)
    end)
    
    -- Legacy compatibility events
    RegisterNetEvent('hud:client:UpdateStress', function(stress)
        Status.OnStressUpdate(stress)
    end)
    
    -- Weapon events
    RegisterNetEvent('weapons:client:SetCurrentWeapon', function(data)
        Status.OnWeaponChange(data)
    end)
    
    -- Parachute events
    RegisterNetEvent('hud:client:parachuteEquipped', function(equipped)
        Status.Data.indicators.parachute = equipped
    end)
    
    -- Harness events
    RegisterNetEvent('seatbelt:client:ToggleHarness', function()
        Status.ToggleHarness()
    end)
    
    -- Cruise control events
    RegisterNetEvent('seatbelt:client:ToggleCruise', function()
        Status.ToggleCruise()
    end)
    
    -- Developer mode events
    RegisterNetEvent('hud:client:ToggleDevMode', function()
        Status.ToggleDevMode()
    end)
    
    HUD.Debug("Status events registered", "STATUS", "INFO")
end

---Register NUI callbacks
function Status.RegisterNUICallbacks()
    RegisterNUICallback('statusClick', function(data, cb)
        Status.OnStatusClick(data.type)
        cb('ok')
    end)
    
    RegisterNUICallback('toggleDevMode', function(data, cb)
        Status.ToggleDevMode()
        cb('ok')
    end)
    
    RegisterNUICallback('getStatusDetails', function(data, cb)
        cb(Status.GetDetailedStatus())
    end)
    
    HUD.Debug("Status NUI callbacks registered", "STATUS", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM
-- ================================================================

---Start the status update thread
function Status.StartUpdateThread()
    CreateThread(function()
        while Status.Initialized do
            local currentTime = GetGameTimer()
            
            if currentTime - Status.LastUpdate >= Status.UpdateInterval then
                local startTime = GetGameTimer()
                
                Status.UpdateStatus()
                Status.SendToNUI()
                
                Status.LastUpdate = currentTime
                Status.Performance.updateCount = Status.Performance.updateCount + 1
                
                -- Performance tracking
                local updateTime = GetGameTimer() - startTime
                Status.Performance.averageUpdateTime = 
                    (Status.Performance.averageUpdateTime + updateTime) / 2
            else
                Status.Performance.skippedUpdates = Status.Performance.skippedUpdates + 1
            end
            
            Wait(100) -- Check every 100ms
        end
    end)
    
    HUD.Debug("Status update thread started", "STATUS", "INFO")
end

---Update all status indicators
function Status.UpdateStatus()
    local ped = PlayerPedId()
    
    -- Update weapon status
    if Status.Components.armed then
        Status.Data.indicators.armed = IsPedArmed(ped, 7) -- 7 = any weapon
    end
    
    -- Update parachute status
    if Status.Components.parachute then
        Status.Data.indicators.parachute = GetPedParachuteState(ped) ~= -1
    end
    
    -- Update diving status
    Status.Data.indicators.diving = IsPedSwimmingUnderWater(ped)
    
    -- Update system information
    Status.UpdateSystemInfo()
    
    -- Voice and radio are handled by GPS-HUD, but we can mirror the data
    if GPSHUD and GPSHUD.Status then
        Status.Data.voice = GPSHUD.Status.voice
    end
end

---Update system information
function Status.UpdateSystemInfo()
    -- FPS
    Status.Data.system.fps = math.floor(1 / GetFrameTime())
    
    -- Ping (if available)
    Status.Data.system.ping = GetPlayerPing(PlayerId())
    
    -- Player count
    Status.Data.system.players = #GetActivePlayers()
    
    -- Server time
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    Status.Data.system.serverTime = string.format("%02d:%02d", hours, minutes)
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle stress update (legacy compatibility)
---@param stress number Stress level
function Status.OnStressUpdate(stress)
    -- Forward to GPS-HUD if available
    if GPSHUD and GPSHUD.UpdateStress then
        GPSHUD.UpdateStress(stress)
    end
    
    HUD.Debug(string.format("Stress update forwarded to GPS-HUD: %d", stress), "STATUS", "INFO")
end

---Handle weapon change
---@param weaponData table Weapon data
function Status.OnWeaponChange(weaponData)
    if weaponData then
        Status.Data.indicators.armed = weaponData.name ~= nil and weaponData.name ~= 'weapon_unarmed'
        Status.SendToNUI()
    end
end

---Toggle harness status
function Status.ToggleHarness()
    Status.Data.indicators.harness = not Status.Data.indicators.harness
    
    local message = Status.Data.indicators.harness and "Racing Harness On" or "Racing Harness Off"
    QBCore.Functions.Notify(message, 'primary')
    
    HUD.Debug("Harness toggled: " .. tostring(Status.Data.indicators.harness), "STATUS", "INFO")
    Status.SendToNUI()
end

---Toggle cruise control
function Status.ToggleCruise()
    Status.Data.indicators.cruise = not Status.Data.indicators.cruise
    
    local message = Status.Data.indicators.cruise and "Cruise Control On" or "Cruise Control Off"
    QBCore.Functions.Notify(message, 'primary')
    
    HUD.Debug("Cruise control toggled: " .. tostring(Status.Data.indicators.cruise), "STATUS", "INFO")
    Status.SendToNUI()
end

---Toggle developer mode
function Status.ToggleDevMode()
    Status.Data.indicators.dev_mode = not Status.Data.indicators.dev_mode
    
    -- Apply dev mode effects
    if Status.Data.indicators.dev_mode then
        -- Make player invincible
        SetPlayerInvincible(PlayerId(), true)
        SetEntityInvincible(PlayerPedId(), true)
        
        -- Infinite stamina
        RestorePlayerStamina(PlayerId(), 1.0)
        
        QBCore.Functions.Notify("Developer Mode: ON", 'success')
    else
        -- Remove dev mode effects
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(PlayerPedId(), false)
        
        QBCore.Functions.Notify("Developer Mode: OFF", 'error')
    end
    
    HUD.Debug("Developer mode toggled: " .. tostring(Status.Data.indicators.dev_mode), "STATUS", "INFO")
    Status.SendToNUI()
end

---Handle status indicator click
---@param statusType string Type of status clicked
function Status.OnStatusClick(statusType)
    if not Config.GPSHUD.interaction.clickableIcons then return end
    
    local message = Status.GetStatusMessage(statusType)
    if message then
        QBCore.Functions.Notify(message, 'primary')
    end
    
    HUD.Debug(string.format("Status indicator clicked: %s", statusType), "STATUS", "INFO")
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send status data to NUI
function Status.SendToNUI()
    if not Status.Visible then return end
    
    local statusData = {
        -- Voice data (mirrored from GPS-HUD)
        voice = Status.Data.voice,
        
        -- Status indicators
        indicators = Status.Data.indicators,
        
        -- System information
        system = Status.Data.system,
        
        -- Component visibility
        components = Status.Components,
        
        -- Integration status
        integration = Status.Integration
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'updateStatus',
        data = statusData
    })
    
    -- Also send to UIManager if available
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('status', statusData)
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set status module visibility
---@param visible boolean Visibility state
function Status.SetVisible(visible)
    Status.Visible = visible
    
    HUD.Debug(string.format("Status visibility set to: %s", visible and "visible" or "hidden"), "STATUS", "INFO")
    
    if visible then
        Status.SendToNUI()
    else
        SendNUIMessage({
            action = 'toggleModule',
            module = 'status',
            visible = false
        })
    end
end

---Get status module visibility
---@return boolean visible
function Status.IsVisible()
    return Status.Visible
end

---Get current status data
---@return table status
function Status.GetStatus()
    return Status.Data
end

---Get detailed status information
---@return table detailedStatus
function Status.GetDetailedStatus()
    return {
        data = Status.Data,
        components = Status.Components,
        integration = Status.Integration,
        performance = Status.Performance,
        config = Config.Modules.status
    }
end

---Force update status display
function Status.ForceUpdate()
    Status.UpdateStatus()
    Status.SendToNUI()
    
    HUD.Debug("Status force update triggered", "STATUS", "INFO")
end

---Set theme for status module
---@param theme string Theme name
function Status.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("Status theme set to: %s", theme), "STATUS", "INFO")
end

---Refresh all status data
function Status.RefreshStatus()
    Status.UpdateStatus()
    Status.SendToNUI()
    
    HUD.Debug("Status data refreshed", "STATUS", "INFO")
end

-- ================================================================
-- COMPATIBILITY FUNCTIONS (Legacy Support)
-- ================================================================

---Set specific status value (for external use)
---@param statusType string Status type
---@param value any Status value
---@return boolean success
function Status.SetStatus(statusType, value)
    if statusType == 'dev_mode' and type(value) == "boolean" then
        Status.Data.indicators.dev_mode = value
        Status.SendToNUI()
        return true
    elseif statusType == 'cruise' and type(value) == "boolean" then
        Status.Data.indicators.cruise = value
        Status.SendToNUI()
        return true
    elseif statusType == 'harness' and type(value) == "boolean" then
        Status.Data.indicators.harness = value
        Status.SendToNUI()
        return true
    elseif statusType == 'armed' and type(value) == "boolean" then
        Status.Data.indicators.armed = value
        Status.SendToNUI()
        return true
    elseif statusType == 'parachute' and type(value) == "boolean" then
        Status.Data.indicators.parachute = value
        Status.SendToNUI()
        return true
    end
    
    HUD.Debug(string.format("Invalid status type or value: %s, %s", statusType, tostring(value)), "STATUS", "WARN")
    return false
end

---Get specific status value
---@param statusType string Status type
---@return any value
function Status.GetStatusValue(statusType)
    if statusType == 'dev_mode' then
        return Status.Data.indicators.dev_mode
    elseif statusType == 'cruise' then
        return Status.Data.indicators.cruise
    elseif statusType == 'harness' then
        return Status.Data.indicators.harness
    elseif statusType == 'armed' then
        return Status.Data.indicators.armed
    elseif statusType == 'parachute' then
        return Status.Data.indicators.parachute
    elseif statusType == 'diving' then
        return Status.Data.indicators.diving
    elseif statusType == 'voice' then
        return Status.Data.voice
    end
    
    return nil
end

---Check if player is armed
---@return boolean armed
function Status.IsArmed()
    return Status.Data.indicators.armed
end

---Check if developer mode is active
---@return boolean devMode
function Status.IsDevMode()
    return Status.Data.indicators.dev_mode
end

---Check if cruise control is active
---@return boolean cruise
function Status.IsCruiseActive()
    return Status.Data.indicators.cruise
end

---Check if harness is equipped
---@return boolean harness
function Status.IsHarnessEquipped()
    return Status.Data.indicators.harness
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get status message for display
---@param statusType string Status type
---@return string message
function Status.GetStatusMessage(statusType)
    local messages = {
        armed = Status.Data.indicators.armed and "Armed" or "Unarmed",
        parachute = Status.Data.indicators.parachute and "Parachute: Equipped" or "No Parachute",
        harness = Status.Data.indicators.harness and "Racing Harness: On" or "Racing Harness: Off",
        cruise = Status.Data.indicators.cruise and "Cruise Control: Active" or "Cruise Control: Off",
        dev_mode = Status.Data.indicators.dev_mode and "Developer Mode: ON" or "Developer Mode: OFF",
        diving = Status.Data.indicators.diving and "Diving" or "Not Diving",
        fps = string.format("FPS: %d", Status.Data.system.fps),
        ping = string.format("Ping: %dms", Status.Data.system.ping),
        players = string.format("Players: %d", Status.Data.system.players),
        time = string.format("Server Time: %s", Status.Data.system.serverTime)
    }
    
    return messages[statusType]
end

---Get current FPS
---@return number fps
function Status.GetFPS()
    return Status.Data.system.fps
end

---Get current ping
---@return number ping
function Status.GetPing()
    return Status.Data.system.ping
end

---Get player count
---@return number players
function Status.GetPlayerCount()
    return Status.Data.system.players
end

---Get performance statistics
---@return table performance
function Status.GetPerformanceStats()
    return {
        initialized = Status.Initialized,
        visible = Status.Visible,
        updateInterval = Status.UpdateInterval,
        updateCount = Status.Performance.updateCount,
        averageUpdateTime = Status.Performance.averageUpdateTime,
        skippedUpdates = Status.Performance.skippedUpdates,
        lastUpdate = Status.LastUpdate,
        voiceAvailable = Status.Integration.voiceAvailable,
        radioAvailable = Status.Integration.radioAvailable,
        voiceResource = Status.Integration.voiceResource,
        radioResource = Status.Integration.radioResource
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function Status.Cleanup()
    -- Disable developer mode if active
    if Status.Data.indicators.dev_mode then
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(PlayerPedId(), false)
    end
    
    Status.Initialized = false
    Status.Visible = false
    
    HUD.Debug("Status module cleaned up", "STATUS", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Status.Cleanup()
    end
end)

-- ================================================================
-- COMPATIBILITY EXPORTS (for external resources)
-- ================================================================

---Export for external resources to check if status module is available
---@return boolean available
function Status.IsAvailable()
    return Status.Initialized
end

---Export for external resources to set status indicators
---@param statusType string Status type
---@param value any Status value
exports('SetStatusIndicator', function(statusType, value)
    return Status.SetStatus(statusType, value)
end)

---Export for external resources to get status indicators
---@param statusType string Status type
---@return any value
exports('GetStatusIndicator', function(statusType)
    return Status.GetStatusValue(statusType)
end)

---Export for external resources to toggle developer mode
exports('ToggleDevMode', function()
    Status.ToggleDevMode()
end)

---Export for external resources to check dev mode
---@return boolean devMode
exports('IsDevMode', function()
    return Status.IsDevMode()
end)

-- ================================================================
-- LEGACY COMPATIBILITY NOTICE
-- ================================================================

--[[
    🚨 IMPORTANT NOTICE:
    
    This Status module is provided for BACKWARD COMPATIBILITY only.
    
    By default, this module is DISABLED in config.lua because the new
    GPS-HUD system handles voice, radio, and most status indicators.
    
    The GPS-HUD provides a more integrated and performance-optimized
    approach to displaying player status information.
    
    You should only enable this module if:
    1. You need specific legacy status indicators not covered by GPS-HUD
    2. You have external resources that specifically depend on this module
    3. You want to run both systems simultaneously (not recommended)
    
    For new installations, use GPS-HUD exclusively.
    
    Components handled by GPS-HUD:
    - Voice level and talking state
    - Radio channel and radio talking
    - All biometric status (health, armor, hunger, thirst, stress, stamina)
    - Money display
    - Time and location information
    
    Components unique to Status module:
    - Armed status indicator
    - Parachute status indicator  
    - Racing harness status
    - Developer mode toggle
    - System information (FPS, ping, player count)
]]

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make Status module available globally
_G.Status = Status

HUD.Debug("Status module loaded (COMPATIBILITY MODE - GPS-HUD recommended)", "STATUS", "INFO")
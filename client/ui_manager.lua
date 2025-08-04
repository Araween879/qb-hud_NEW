-- ================================================================
-- QBCore HUD - UI Manager Module (COMPLETE)
-- Version: 3.0.0
-- Description: Central UI management and coordination system
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- UI Manager System
UIManager = UIManager or {}
UIManager.Initialized = false
UIManager.CinematicMode = false
UIManager.CurrentTheme = 'neon-magenta'
UIManager.HudVisible = true
UIManager.ModuleVisibility = {}
UIManager.Settings = {}

-- Performance tracking
UIManager.Performance = {
    nuiMessageCount = 0,
    lastNUIUpdate = 0,
    batchedUpdates = {},
    batchTimer = nil
}

-- State management
UIManager.State = {
    isInVehicle = false,
    isDead = false,
    isUnconscious = false,
    isPaused = false,
    cinematicMode = false,
    scaling = 1.0,
    opacity = 0.9
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the UI Manager module
---@return boolean success  
function UIManager.Init()
    if UIManager.Initialized then
        HUD.Debug("UI Manager already initialized", "UI_MANAGER", "WARN")
        return true
    end
    
    HUD.Debug("Initializing UI Manager...", "UI_MANAGER", "INFO")
    
    -- Load configuration
    UIManager.LoadConfiguration()
    
    -- Set initial theme
    UIManager.CurrentTheme = Config.Theme.current or 'neon-magenta'
    
    -- Initialize module visibility states
    for moduleName, moduleConfig in pairs(Config.Modules) do
        UIManager.ModuleVisibility[moduleName] = moduleConfig.enabled or false
    end
    
    -- Register events
    UIManager.RegisterEvents()
    
    -- Initialize NUI
    UIManager.InitializeNUI()
    
    -- Setup update batching
    UIManager.SetupBatching()
    
    -- Set cinematic mode from config
    UIManager.CinematicMode = Config.Modules.ui_manager.cinematicMode or false
    if UIManager.CinematicMode then
        UIManager.SetCinematicMode(true)
    end
    
    UIManager.Initialized = true
    HUD.Debug("UI Manager initialized successfully", "UI_MANAGER", "INFO")
    
    return true
end

---Load UI Manager configuration
function UIManager.LoadConfiguration()
    local config = Config.Modules.ui_manager or {}
    
    UIManager.Settings = {
        cinematicMode = config.cinematicMode or false,
        scaling = config.scaling or 1.0,
        opacity = config.opacity or 0.9,
        enableGlowEffects = config.enableGlowEffects or true,
        enableAnimations = config.enableAnimations or true,
        theme = config.theme or Config.Theme.current,
        batchUpdates = Config.Advanced.optimization.batchUpdates or true,
        throttleUpdates = Config.Advanced.optimization.throttleUpdates or true
    }
    
    HUD.Debug("UI Manager configuration loaded", "UI_MANAGER", "INFO")
end

---Initialize NUI communication
function UIManager.InitializeNUI()
    -- Send initial theme configuration to NUI
    UIManager.SendNUIMessage({
        action = 'setTheme',
        theme = UIManager.CurrentTheme,
        colors = Config.Theme.colors[UIManager.CurrentTheme],
        fonts = Config.Theme.fonts,
        animations = Config.Theme.animations,
        layout = Config.Theme.layout
    })
    
    -- Send initial module visibility states
    UIManager.SendNUIMessage({
        action = 'setModuleVisibility',
        visibility = UIManager.ModuleVisibility
    })
    
    -- Send initial UI settings
    UIManager.SendNUIMessage({
        action = 'updateUISettings',
        settings = {
            scaling = UIManager.Settings.scaling,
            opacity = UIManager.Settings.opacity,
            animations = UIManager.Settings.enableAnimations,
            glowEffects = UIManager.Settings.enableGlowEffects,
            cinematicMode = UIManager.Settings.cinematicMode
        }
    })
    
    HUD.Debug("NUI initialized with theme: " .. UIManager.CurrentTheme, "UI_MANAGER", "INFO")
end

---Register UI Manager events
function UIManager.RegisterEvents()
    -- Theme change event
    RegisterNetEvent('hud:client:setTheme', function(theme)
        UIManager.SetTheme(theme)
    end)
    
    -- Module visibility toggle event
    RegisterNetEvent('hud:client:toggleModule', function(moduleName, visible)
        UIManager.ToggleModule(moduleName, visible)
    end)
    
    -- HUD visibility toggle event
    RegisterNetEvent('hud:client:setHudVisibility', function(visible)
        UIManager.SetHudVisibility(visible)
    end)
    
    -- Cinematic mode event
    RegisterNetEvent('hud:client:setCinematicMode', function(enabled)
        UIManager.SetCinematicMode(enabled)
    end)
    
    -- UI scaling event
    RegisterNetEvent('hud:client:setUIScale', function(scale)
        UIManager.SetUIScale(scale)
    end)
    
    -- UI opacity event
    RegisterNetEvent('hud:client:setUIOpacity', function(opacity)
        UIManager.SetUIOpacity(opacity)
    end)
    
    -- Player state events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        UIManager.OnPlayerLoaded()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        UIManager.OnPlayerUnloaded()
    end)
    
    -- Game state events
    AddEventHandler('gameEventTriggered', function(name, args)
        UIManager.OnGameEvent(name, args)
    end)
    
    HUD.Debug("UI Manager events registered", "UI_MANAGER", "INFO")
end

---Setup update batching system
function UIManager.SetupBatching()
    if not UIManager.Settings.batchUpdates then return end
    
    UIManager.Performance.batchTimer = SetInterval(function()
        UIManager.ProcessBatchedUpdates()
    end, 100) -- Process batched updates every 100ms
    
    HUD.Debug("Update batching system initialized", "UI_MANAGER", "INFO")
end

-- ================================================================
-- THEME MANAGEMENT
-- ================================================================

---Set the current UI theme
---@param theme string Theme name
---@return boolean success
function UIManager.SetTheme(theme)
    if not Config.Theme.colors[theme] then
        HUD.Debug(string.format("Theme '%s' not found, keeping current theme", theme), "UI_MANAGER", "WARN")
        return false
    end
    
    UIManager.CurrentTheme = theme
    
    -- Update NUI with new theme
    UIManager.SendNUIMessage({
        action = 'setTheme',
        theme = theme,
        colors = Config.Theme.colors[theme],
        fonts = Config.Theme.fonts,
        animations = Config.Theme.animations,
        layout = Config.Theme.layout
    })
    
    HUD.Debug(string.format("Theme changed to: %s", theme), "UI_MANAGER", "INFO")
    
    -- Trigger theme change event for other modules
    TriggerEvent('hud:client:themeChanged', theme)
    
    -- Save theme preference
    UIManager.SaveSetting('theme', theme)
    
    return true
end

---Get the current theme
---@return string theme
function UIManager.GetTheme()
    return UIManager.CurrentTheme
end

---Get available themes
---@return table themes
function UIManager.GetAvailableThemes()
    return Config.Theme.available or {'neon-magenta', 'neon-cyan', 'synthwave', 'classic'}
end

-- ================================================================
-- MODULE MANAGEMENT
-- ================================================================

---Toggle module visibility
---@param moduleName string Module name
---@param visible boolean Visibility state
function UIManager.ToggleModule(moduleName, visible)
    if type(visible) ~= "boolean" then
        visible = not UIManager.ModuleVisibility[moduleName]
    end
    
    UIManager.ModuleVisibility[moduleName] = visible
    
    -- Send to NUI
    UIManager.SendNUIMessage({
        action = 'toggleModule',
        module = moduleName,
        visible = visible
    })
    
    -- Notify module if it has a SetVisible function
    if _G[moduleName:upper()] and _G[moduleName:upper()].SetVisible then
        _G[moduleName:upper()].SetVisible(visible)
    end
    
    HUD.Debug(string.format("Module %s visibility: %s", moduleName, visible and "visible" or "hidden"), "UI_MANAGER", "INFO")
    
    -- Trigger module visibility event
    TriggerEvent('hud:client:moduleVisibilityChanged', moduleName, visible)
    
    -- Save setting
    UIManager.SaveSetting('moduleVisibility.' .. moduleName, visible)
end

---Get module visibility
---@param moduleName string Module name
---@return boolean visible
function UIManager.GetModuleVisibility(moduleName)
    return UIManager.ModuleVisibility[moduleName] or false
end

---Update module data
---@param moduleName string Module name
---@param data table Module data
function UIManager.UpdateModule(moduleName, data)
    if not UIManager.ModuleVisibility[moduleName] then
        return -- Don't update hidden modules
    end
    
    -- Batch the update if batching is enabled
    if UIManager.Settings.batchUpdates then
        UIManager.BatchUpdate('updateModule', {
            module = moduleName,
            data = data
        })
    else
        UIManager.SendNUIMessage({
            action = 'updateModule',
            module = moduleName,
            data = data
        })
    end
end

-- ================================================================
-- HUD VISIBILITY MANAGEMENT
-- ================================================================

---Set HUD visibility
---@param visible boolean Visibility state
function UIManager.SetHudVisibility(visible)
    UIManager.HudVisible = visible
    
    -- Update all modules
    for moduleName, _ in pairs(UIManager.ModuleVisibility) do
        UIManager.ToggleModule(moduleName, visible)
    end
    
    -- Send master visibility command to NUI
    UIManager.SendNUIMessage({
        action = 'setHudVisibility',
        visible = visible
    })
    
    HUD.Debug(string.format("HUD visibility set to: %s", visible and "visible" or "hidden"), "UI_MANAGER", "INFO")
    
    -- Trigger HUD visibility event
    TriggerEvent('hud:client:hudVisibilityChanged', visible)
end

---Get HUD visibility
---@return boolean visible
function UIManager.IsHudVisible()
    return UIManager.HudVisible
end

-- ================================================================
-- CINEMATIC MODE
-- ================================================================

---Set cinematic mode
---@param enabled boolean Cinematic mode state
function UIManager.SetCinematicMode(enabled)
    UIManager.CinematicMode = enabled
    UIManager.State.cinematicMode = enabled
    
    -- Send to NUI
    UIManager.SendNUIMessage({
        action = 'setCinematicMode',
        enabled = enabled
    })
    
    -- Hide/show HUD based on cinematic mode
    if enabled then
        UIManager.SetHudVisibility(false)
    else
        UIManager.SetHudVisibility(true)
    end
    
    HUD.Debug(string.format("Cinematic mode: %s", enabled and "enabled" or "disabled"), "UI_MANAGER", "INFO")
    
    -- Trigger cinematic mode event
    TriggerEvent('hud:client:cinematicModeChanged', enabled)
    
    -- Save setting
    UIManager.SaveSetting('cinematicMode', enabled)
end

---Get cinematic mode state
---@return boolean enabled
function UIManager.GetCinematicMode()
    return UIManager.CinematicMode
end

-- ================================================================
-- UI SETTINGS
-- ================================================================

---Set UI scale
---@param scale number Scale factor (0.5-2.0)
function UIManager.SetUIScale(scale)
    if type(scale) ~= "number" then return end
    
    scale = math.max(0.5, math.min(2.0, scale)) -- Clamp between 0.5 and 2.0
    UIManager.Settings.scaling = scale
    UIManager.State.scaling = scale
    
    UIManager.SendNUIMessage({
        action = 'setUIScale',
        scale = scale
    })
    
    HUD.Debug(string.format("UI scale set to: %.2f", scale), "UI_MANAGER", "INFO")
    UIManager.SaveSetting('scaling', scale)
end

---Set UI opacity
---@param opacity number Opacity (0.0-1.0)
function UIManager.SetUIOpacity(opacity)
    if type(opacity) ~= "number" then return end
    
    opacity = math.max(0.0, math.min(1.0, opacity)) -- Clamp between 0.0 and 1.0
    UIManager.Settings.opacity = opacity
    UIManager.State.opacity = opacity
    
    UIManager.SendNUIMessage({
        action = 'setUIOpacity',
        opacity = opacity
    })
    
    HUD.Debug(string.format("UI opacity set to: %.2f", opacity), "UI_MANAGER", "INFO")
    UIManager.SaveSetting('opacity', opacity)
end

---Toggle animations
---@param enabled boolean Animation state
function UIManager.SetAnimations(enabled)
    UIManager.Settings.enableAnimations = enabled
    
    UIManager.SendNUIMessage({
        action = 'setAnimations',
        enabled = enabled
    })
    
    HUD.Debug(string.format("Animations: %s", enabled and "enabled" or "disabled"), "UI_MANAGER", "INFO")
    UIManager.SaveSetting('animations', enabled)
end

---Toggle glow effects
---@param enabled boolean Glow effects state
function UIManager.SetGlowEffects(enabled)
    UIManager.Settings.enableGlowEffects = enabled
    
    UIManager.SendNUIMessage({
        action = 'setGlowEffects',
        enabled = enabled
    })
    
    HUD.Debug(string.format("Glow effects: %s", enabled and "enabled" or "disabled"), "UI_MANAGER", "INFO")
    UIManager.SaveSetting('glowEffects', enabled)
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send message to NUI with throttling
---@param message table NUI message
function UIManager.SendNUIMessage(message)
    if not message or type(message) ~= "table" then return end
    
    -- Throttle updates if enabled
    if UIManager.Settings.throttleUpdates then
        local currentTime = GetGameTimer()
        if currentTime - UIManager.Performance.lastNUIUpdate < 16 then -- ~60 FPS
            return
        end
        UIManager.Performance.lastNUIUpdate = currentTime
    end
    
    SendNUIMessage(message)
    UIManager.Performance.nuiMessageCount = UIManager.Performance.nuiMessageCount + 1
end

---Batch update for performance
---@param action string Action type
---@param data table Action data
function UIManager.BatchUpdate(action, data)
    if not UIManager.Performance.batchedUpdates[action] then
        UIManager.Performance.batchedUpdates[action] = {}
    end
    
    table.insert(UIManager.Performance.batchedUpdates[action], data)
end

---Process all batched updates
function UIManager.ProcessBatchedUpdates()
    for action, updates in pairs(UIManager.Performance.batchedUpdates) do
        if #updates > 0 then
            UIManager.SendNUIMessage({
                action = 'batchUpdate',
                updateType = action,
                updates = updates
            })
            
            UIManager.Performance.batchedUpdates[action] = {}
        end
    end
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle player loaded event
function UIManager.OnPlayerLoaded()
    HUD.Debug("Player loaded - refreshing UI", "UI_MANAGER", "INFO")
    
    -- Refresh UI state
    UIManager.SetHudVisibility(true)
    UIManager.InitializeNUI()
    
    -- Load saved settings
    UIManager.LoadSettings()
end

---Handle player unloaded event
function UIManager.OnPlayerUnloaded()
    HUD.Debug("Player unloaded - hiding UI", "UI_MANAGER", "INFO")
    UIManager.SetHudVisibility(false)
end

---Handle game events
---@param eventName string Event name
---@param args table Event arguments
function UIManager.OnGameEvent(eventName, args)
    if eventName == 'CEventNetworkPlayerEnteredVehicle' then
        UIManager.State.isInVehicle = true
        TriggerEvent('hud:client:playerEnteredVehicle')
    elseif eventName == 'CEventNetworkPlayerLeftVehicle' then
        UIManager.State.isInVehicle = false
        TriggerEvent('hud:client:playerLeftVehicle')
    end
end

-- ================================================================
-- SETTINGS PERSISTENCE
-- ================================================================

---Save a setting
---@param key string Setting key
---@param value any Setting value
function UIManager.SaveSetting(key, value)
    UIManager.SendNUIMessage({
        action = 'saveSetting',
        key = key,
        value = value
    })
end

---Load all settings
function UIManager.LoadSettings()
    UIManager.SendNUIMessage({
        action = 'loadSettings'
    })
end

-- ================================================================
-- PUBLIC API
-- ================================================================

---Get current UI state
---@return table state
function UIManager.GetState()
    return {
        initialized = UIManager.Initialized,
        hudVisible = UIManager.HudVisible,
        cinematicMode = UIManager.CinematicMode,
        theme = UIManager.CurrentTheme,
        scaling = UIManager.Settings.scaling,
        opacity = UIManager.Settings.opacity,
        animations = UIManager.Settings.enableAnimations,
        glowEffects = UIManager.Settings.enableGlowEffects,
        moduleVisibility = UIManager.ModuleVisibility
    }
end

---Get performance statistics
---@return table performance
function UIManager.GetPerformanceStats()
    return {
        nuiMessageCount = UIManager.Performance.nuiMessageCount,
        lastNUIUpdate = UIManager.Performance.lastNUIUpdate,
        batchedUpdatesCount = table.length(UIManager.Performance.batchedUpdates),
        initialized = UIManager.Initialized
    }
end

---Force refresh all UI elements
function UIManager.ForceRefresh()
    UIManager.InitializeNUI()
    
    -- Refresh all visible modules
    for moduleName, visible in pairs(UIManager.ModuleVisibility) do
        if visible and _G[moduleName:upper()] and _G[moduleName:upper()].ForceUpdate then
            _G[moduleName:upper()].ForceUpdate()
        end
    end
    
    HUD.Debug("UI Manager force refresh completed", "UI_MANAGER", "INFO")
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function UIManager.Cleanup()
    if UIManager.Performance.batchTimer then
        ClearInterval(UIManager.Performance.batchTimer)
    end
    
    UIManager.Initialized = false
    HUD.Debug("UI Manager cleaned up", "UI_MANAGER", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        UIManager.Cleanup()
    end
end)

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Check if a table is empty
---@param t table Table to check
---@return boolean empty
function table.length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make UIManager available globally
_G.UIManager = UIManager

HUD.Debug("UI Manager module loaded", "UI_MANAGER", "INFO")
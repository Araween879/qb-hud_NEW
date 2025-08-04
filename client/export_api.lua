-- ================================================================
-- QBCore HUD - Export API System (COMPLETE)
-- Version: 3.0.0
-- Description: Complete export API for external resource integration
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Export API System
ExportAPI = ExportAPI or {}
ExportAPI.Initialized = false
ExportAPI.EnableLogging = Config.Debug or false
ExportAPI.CustomModules = {}
ExportAPI.Callbacks = {}

-- API Statistics
ExportAPI.Stats = {
    totalCalls = 0,
    moduleUpdates = 0,
    themeChanges = 0,
    visibilityToggles = 0,
    customModules = 0,
    errors = 0
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Export API system
---@return boolean success
function ExportAPI.Init()
    if ExportAPI.Initialized then
        HUD.Debug("Export API already initialized", "EXPORT_API", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Export API system...", "EXPORT_API", "INFO")
    
    -- Load configuration
    ExportAPI.LoadConfiguration()
    
    -- Register all exports
    ExportAPI.RegisterAllExports()
    
    -- Setup event handlers
    ExportAPI.RegisterEvents()
    
    ExportAPI.Initialized = true
    HUD.Debug("Export API system initialized successfully", "EXPORT_API", "INFO")
    
    return true
end

---Load Export API configuration
function ExportAPI.LoadConfiguration()
    local config = Config.Modules.export_api or {}
    
    ExportAPI.EnableLogging = config.enableLogging or Config.Debug or false
    
    -- Load component settings
    ExportAPI.Components = {
        visibility = config.components and config.components.visibility or true,
        themes = config.components and config.components.themes or true,
        modules = config.components and config.components.modules or true,
        callbacks = config.components and config.components.callbacks or true,
        events = config.components and config.components.events or true
    }
    
    HUD.Debug("Export API configuration loaded", "EXPORT_API", "INFO")
end

---Register event handlers
function ExportAPI.RegisterEvents()
    -- Module initialization events
    RegisterNetEvent('hud:client:initialized', function()
        ExportAPI.OnHUDInitialized()
    end)
    
    HUD.Debug("Export API events registered", "EXPORT_API", "INFO")
end

---Handle HUD initialization
function ExportAPI.OnHUDInitialized()
    HUD.Debug("HUD initialized - Export API ready", "EXPORT_API", "INFO")
    
    -- Trigger event for external resources
    TriggerEvent('hud:api:ready')
end

-- ================================================================
-- CORE EXPORT FUNCTIONS
-- ================================================================

---Set HUD visibility
---@param visible boolean Visibility state
---@return boolean success
exports('SetHudVisibility', function(visible)
    ExportAPI.LogCall('SetHudVisibility', { visible = visible })
    
    if type(visible) ~= "boolean" then
        ExportAPI.LogError('SetHudVisibility', 'Invalid parameter type - expected boolean')
        return false
    end
    
    if UIManager and UIManager.SetHudVisibility then
        UIManager.SetHudVisibility(visible)
        ExportAPI.Stats.visibilityToggles = ExportAPI.Stats.visibilityToggles + 1
        return true
    else
        ExportAPI.LogError('SetHudVisibility', 'UIManager not available')
        return false
    end
end)

---Get HUD visibility
---@return boolean visible
exports('GetHudVisibility', function()
    ExportAPI.LogCall('GetHudVisibility')
    
    if UIManager and UIManager.IsHudVisible then
        return UIManager.IsHudVisible()
    else
        ExportAPI.LogError('GetHudVisibility', 'UIManager not available')
        return false
    end
end)

---Set HUD theme
---@param theme string Theme name
---@return boolean success
exports('SetTheme', function(theme)
    ExportAPI.LogCall('SetTheme', { theme = theme })
    
    if type(theme) ~= "string" then
        ExportAPI.LogError('SetTheme', 'Invalid parameter type - expected string')
        return false
    end
    
    if not ExportAPI.Components.themes then
        ExportAPI.LogError('SetTheme', 'Theme component disabled')
        return false
    end
    
    if UIManager and UIManager.SetTheme then
        local success = UIManager.SetTheme(theme)
        if success then
            ExportAPI.Stats.themeChanges = ExportAPI.Stats.themeChanges + 1
        end
        return success
    else
        ExportAPI.LogError('SetTheme', 'UIManager not available')
        return false
    end
end)

---Get current theme
---@return string theme
exports('GetTheme', function()
    ExportAPI.LogCall('GetTheme')
    
    if UIManager and UIManager.GetTheme then
        return UIManager.GetTheme()
    else
        ExportAPI.LogError('GetTheme', 'UIManager not available')
        return 'neon-magenta'
    end
end)

---Get available themes
---@return table themes
exports('GetAvailableThemes', function()
    ExportAPI.LogCall('GetAvailableThemes')
    
    if UIManager and UIManager.GetAvailableThemes then
        return UIManager.GetAvailableThemes()
    else
        return Config.Theme.available or {'neon-magenta', 'neon-cyan', 'synthwave', 'classic'}
    end
end)

-- ================================================================
-- MODULE MANAGEMENT EXPORTS
-- ================================================================

---Toggle module visibility
---@param moduleName string Module name
---@param visible boolean Visibility state
---@return boolean success
exports('ToggleModule', function(moduleName, visible)
    ExportAPI.LogCall('ToggleModule', { module = moduleName, visible = visible })
    
    if type(moduleName) ~= "string" then
        ExportAPI.LogError('ToggleModule', 'Invalid moduleName type - expected string')
        return false
    end
    
    if visible ~= nil and type(visible) ~= "boolean" then
        ExportAPI.LogError('ToggleModule', 'Invalid visible type - expected boolean or nil')
        return false
    end
    
    if not ExportAPI.Components.modules then
        ExportAPI.LogError('ToggleModule', 'Module component disabled')
        return false
    end
    
    if UIManager and UIManager.ToggleModule then
        UIManager.ToggleModule(moduleName, visible)
        ExportAPI.Stats.visibilityToggles = ExportAPI.Stats.visibilityToggles + 1
        return true
    else
        ExportAPI.LogError('ToggleModule', 'UIManager not available')
        return false
    end
end)

---Get module visibility
---@param moduleName string Module name
---@return boolean visible
exports('GetModuleVisibility', function(moduleName)
    ExportAPI.LogCall('GetModuleVisibility', { module = moduleName })
    
    if type(moduleName) ~= "string" then
        ExportAPI.LogError('GetModuleVisibility', 'Invalid moduleName type - expected string')
        return false
    end
    
    if UIManager and UIManager.GetModuleVisibility then
        return UIManager.GetModuleVisibility(moduleName)
    else
        ExportAPI.LogError('GetModuleVisibility', 'UIManager not available')
        return false
    end
end)

---Update module status
---@param moduleName string Module name
---@param data table Status data
---@return boolean success
exports('UpdateStatus', function(moduleName, data)
    ExportAPI.LogCall('UpdateStatus', { module = moduleName, dataType = type(data) })
    
    if type(moduleName) ~= "string" then
        ExportAPI.LogError('UpdateStatus', 'Invalid moduleName type - expected string')
        return false
    end
    
    if type(data) ~= "table" then
        ExportAPI.LogError('UpdateStatus', 'Invalid data type - expected table')
        return false
    end
    
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule(moduleName, data)
        ExportAPI.Stats.moduleUpdates = ExportAPI.Stats.moduleUpdates + 1
        return true
    else
        ExportAPI.LogError('UpdateStatus', 'UIManager not available')
        return false
    end
end)

-- ================================================================
-- ADVANCED EXPORTS
-- ================================================================

---Set UI scale
---@param scale number Scale factor (0.5-2.0)
---@return boolean success
exports('SetUIScale', function(scale)
    ExportAPI.LogCall('SetUIScale', { scale = scale })
    
    if type(scale) ~= "number" then
        ExportAPI.LogError('SetUIScale', 'Invalid scale type - expected number')
        return false
    end
    
    if scale < 0.5 or scale > 2.0 then
        ExportAPI.LogError('SetUIScale', 'Scale out of range - expected 0.5-2.0')
        return false
    end
    
    if UIManager and UIManager.SetUIScale then
        UIManager.SetUIScale(scale)
        return true
    else
        ExportAPI.LogError('SetUIScale', 'UIManager not available')
        return false
    end
end)

---Set UI opacity
---@param opacity number Opacity (0.0-1.0)
---@return boolean success
exports('SetUIOpacity', function(opacity)
    ExportAPI.LogCall('SetUIOpacity', { opacity = opacity })
    
    if type(opacity) ~= "number" then
        ExportAPI.LogError('SetUIOpacity', 'Invalid opacity type - expected number')
        return false
    end
    
    if opacity < 0.0 or opacity > 1.0 then
        ExportAPI.LogError('SetUIOpacity', 'Opacity out of range - expected 0.0-1.0')
        return false
    end
    
    if UIManager and UIManager.SetUIOpacity then
        UIManager.SetUIOpacity(opacity)
        return true
    else
        ExportAPI.LogError('SetUIOpacity', 'UIManager not available')
        return false
    end
end)

---Set cinematic mode
---@param enabled boolean Cinematic mode state
---@return boolean success
exports('SetCinematicMode', function(enabled)
    ExportAPI.LogCall('SetCinematicMode', { enabled = enabled })
    
    if type(enabled) ~= "boolean" then
        ExportAPI.LogError('SetCinematicMode', 'Invalid enabled type - expected boolean')
        return false
    end
    
    if UIManager and UIManager.SetCinematicMode then
        UIManager.SetCinematicMode(enabled)
        return true
    else
        ExportAPI.LogError('SetCinematicMode', 'UIManager not available')
        return false
    end
end)

---Get cinematic mode state
---@return boolean enabled
exports('GetCinematicMode', function()
    ExportAPI.LogCall('GetCinematicMode')
    
    if UIManager and UIManager.GetCinematicMode then
        return UIManager.GetCinematicMode()
    else
        ExportAPI.LogError('GetCinematicMode', 'UIManager not available')
        return false
    end
end)

-- ================================================================
-- HEALTH SYSTEM EXPORTS
-- ================================================================

---Get health status
---@return table status
exports('GetHealthStatus', function()
    ExportAPI.LogCall('GetHealthStatus')
    
    if Health and Health.GetStatus then
        return Health.GetStatus()
    else
        ExportAPI.LogError('GetHealthStatus', 'Health module not available')
        return {}
    end
end)

---Update health values
---@param healthData table Health data
---@return boolean success
exports('UpdateHealth', function(healthData)
    ExportAPI.LogCall('UpdateHealth', { dataType = type(healthData) })
    
    if type(healthData) ~= "table" then
        ExportAPI.LogError('UpdateHealth', 'Invalid healthData type - expected table')
        return false
    end
    
    -- Validate health data
    local validFields = {'health', 'armor', 'hunger', 'thirst', 'stress', 'stamina', 'oxygen'}
    local validData = {}
    
    for _, field in ipairs(validFields) do
        if healthData[field] and type(healthData[field]) == "number" then
            validData[field] = math.max(0, math.min(100, healthData[field]))
        end
    end
    
    if next(validData) == nil then
        ExportAPI.LogError('UpdateHealth', 'No valid health fields provided')
        return false
    end
    
    return exports['qb-hud']:UpdateStatus('health', validData)
end)

-- ================================================================
-- VEHICLE SYSTEM EXPORTS
-- ================================================================

---Show vehicle HUD
---@param vehicleData table Vehicle data
---@return boolean success
exports('ShowVehicleHUD', function(vehicleData)
    ExportAPI.LogCall('ShowVehicleHUD', { dataType = type(vehicleData) })
    
    if type(vehicleData) ~= "table" then
        vehicleData = {}
    end
    
    return exports['qb-hud']:UpdateStatus('vehicle', vehicleData)
end)

---Hide vehicle HUD
---@return boolean success
exports('HideVehicleHUD', function()
    ExportAPI.LogCall('HideVehicleHUD')
    return exports['qb-hud']:ToggleModule('vehicle', false)
end)

-- ================================================================
-- NOTIFICATION SYSTEM EXPORTS
-- ================================================================

---Show custom message
---@param id string Message ID
---@param text string Message text
---@param duration number Duration in milliseconds
---@param type string Message type ('info', 'success', 'warning', 'error')
---@return boolean success
exports('ShowCustomMessage', function(id, text, duration, type)
    ExportAPI.LogCall('ShowCustomMessage', { id = id, text = text, duration = duration, type = type })
    
    if type(id) ~= "string" or type(text) ~= "string" then
        ExportAPI.LogError('ShowCustomMessage', 'Invalid id or text type - expected string')
        return false
    end
    
    duration = duration or 3000
    type = type or 'info'
    
    if UIManager and UIManager.SendNUIMessage then
        UIManager.SendNUIMessage({
            action = 'showCustomMessage',
            id = id,
            text = text,
            duration = duration,
            type = type
        })
        return true
    else
        ExportAPI.LogError('ShowCustomMessage', 'UIManager not available')
        return false
    end
end)

---Hide custom message
---@param id string Message ID
---@return boolean success
exports('HideCustomMessage', function(id)
    ExportAPI.LogCall('HideCustomMessage', { id = id })
    
    if type(id) ~= "string" then
        ExportAPI.LogError('HideCustomMessage', 'Invalid id type - expected string')
        return false
    end
    
    if UIManager and UIManager.SendNUIMessage then
        UIManager.SendNUIMessage({
            action = 'hideCustomMessage',
            id = id
        })
        return true
    else
        ExportAPI.LogError('HideCustomMessage', 'UIManager not available')
        return false
    end
end)

-- ================================================================
-- CUSTOM MODULE REGISTRATION
-- ================================================================

---Register a custom module (for external resources)
---@param name string Module name
---@param config table Module configuration
---@return boolean success
exports('RegisterCustomModule', function(name, config)
    ExportAPI.LogCall('RegisterCustomModule', { name = name, configType = type(config) })
    
    if type(name) ~= "string" or type(config) ~= "table" then
        ExportAPI.LogError('RegisterCustomModule', 'Invalid parameters - expected string, table')
        return false
    end
    
    -- Basic validation
    if not config.enabled or not config.position then
        ExportAPI.LogError('RegisterCustomModule', 'Missing required config fields (enabled, position)')
        return false
    end
    
    -- Add to custom modules registry
    ExportAPI.CustomModules[name] = {
        config = config,
        registered = GetGameTimer(),
        resource = GetInvokingResource()
    }
    
    -- Add to global module configuration
    Config.Modules[name] = config
    
    -- Initialize module if UI is ready
    if UIManager and UIManager.ModuleVisibility then
        UIManager.ModuleVisibility[name] = config.enabled
        UIManager.ToggleModule(name, config.enabled)
    end
    
    ExportAPI.Stats.customModules = ExportAPI.Stats.customModules + 1
    HUD.Debug(string.format("Custom module '%s' registered by %s", name, GetInvokingResource() or "unknown"), "EXPORT_API", "INFO")
    
    return true
end)

---Unregister a custom module
---@param name string Module name
---@return boolean success
exports('UnregisterCustomModule', function(name)
    ExportAPI.LogCall('UnregisterCustomModule', { name = name })
    
    if type(name) ~= "string" then
        ExportAPI.LogError('UnregisterCustomModule', 'Invalid name type - expected string')
        return false
    end
    
    if ExportAPI.CustomModules[name] then
        -- Hide module first
        if UIManager and UIManager.ToggleModule then
            UIManager.ToggleModule(name, false)
        end
        
        -- Remove from registries
        ExportAPI.CustomModules[name] = nil
        Config.Modules[name] = nil
        
        ExportAPI.Stats.customModules = math.max(0, ExportAPI.Stats.customModules - 1)
        HUD.Debug(string.format("Custom module '%s' unregistered", name), "EXPORT_API", "INFO")
        
        return true
    else
        ExportAPI.LogError('UnregisterCustomModule', string.format("Module '%s' not found", name))
        return false
    end
end)

-- ================================================================
-- UTILITY EXPORTS
-- ================================================================

---Get full HUD status
---@return table status
exports('GetStatus', function()
    ExportAPI.LogCall('GetStatus')
    
    local status = {
        initialized = ExportAPI.Initialized,
        modules = {},
        theme = exports['qb-hud']:GetTheme(),
        visible = exports['qb-hud']:GetHudVisibility(),
        cinematicMode = exports['qb-hud']:GetCinematicMode(),
        customModules = table.keys(ExportAPI.CustomModules),
        stats = ExportAPI.Stats
    }
    
    -- Get individual module statuses
    if UIManager and UIManager.ModuleVisibility then
        for moduleName, visible in pairs(UIManager.ModuleVisibility) do
            status.modules[moduleName] = visible
        end
    end
    
    return status
end)

---Force update all modules
---@return boolean success
exports('ForceUpdate', function()
    ExportAPI.LogCall('ForceUpdate')
    
    local updated = 0
    
    -- Update core modules
    local coreModules = {'Health', 'Status', 'Time', 'Location', 'Vehicle', 'GPSHUD'}
    
    for _, moduleName in ipairs(coreModules) do
        local moduleTable = _G[moduleName]
        if moduleTable and moduleTable.ForceUpdate then
            moduleTable.ForceUpdate()
            updated = updated + 1
        end
    end
    
    -- Update UI Manager
    if UIManager and UIManager.ForceRefresh then
        UIManager.ForceRefresh()
    end
    
    HUD.Debug(string.format("Force update completed - %d modules updated", updated), "EXPORT_API", "INFO")
    
    return updated > 0
end)

---Get performance statistics
---@return table performance
exports('GetPerformanceStats', function()
    ExportAPI.LogCall('GetPerformanceStats')
    
    local stats = {
        exportAPI = ExportAPI.Stats,
        modules = {}
    }
    
    -- Get module performance stats
    local modules = {'Health', 'Status', 'Time', 'Location', 'Vehicle', 'UIManager', 'GPSHUD'}
    
    for _, moduleName in ipairs(modules) do
        local moduleTable = _G[moduleName]
        if moduleTable and moduleTable.GetPerformanceStats then
            stats.modules[moduleName] = moduleTable.GetPerformanceStats()
        end
    end
    
    return stats
end)

-- ================================================================
-- CALLBACK SYSTEM
-- ================================================================

---Register a callback function
---@param name string Callback name
---@param func function Callback function
---@return boolean success
exports('RegisterCallback', function(name, func)
    ExportAPI.LogCall('RegisterCallback', { name = name, funcType = type(func) })
    
    if type(name) ~= "string" or type(func) ~= "function" then
        ExportAPI.LogError('RegisterCallback', 'Invalid parameters - expected string, function')
        return false
    end
    
    if not ExportAPI.Components.callbacks then
        ExportAPI.LogError('RegisterCallback', 'Callback component disabled')
        return false
    end
    
    ExportAPI.Callbacks[name] = {
        func = func,
        resource = GetInvokingResource(),
        registered = GetGameTimer()
    }
    
    HUD.Debug(string.format("Callback '%s' registered by %s", name, GetInvokingResource() or "unknown"), "EXPORT_API", "INFO")
    
    return true
end)

---Trigger a callback
---@param name string Callback name
---@param ... any Callback arguments
---@return any result
exports('TriggerCallback', function(name, ...)
    ExportAPI.LogCall('TriggerCallback', { name = name })
    
    if type(name) ~= "string" then
        ExportAPI.LogError('TriggerCallback', 'Invalid name type - expected string')
        return nil
    end
    
    local callback = ExportAPI.Callbacks[name]
    if callback and callback.func then
        local success, result = pcall(callback.func, ...)
        if success then
            return result
        else
            ExportAPI.LogError('TriggerCallback', string.format("Callback '%s' error: %s", name, result))
            return nil
        end
    else
        ExportAPI.LogError('TriggerCallback', string.format("Callback '%s' not found", name))
        return nil
    end
end)

-- ================================================================
-- LOGGING & DEBUGGING
-- ================================================================

---Log an export call
---@param exportName string Export function name
---@param params table Parameters passed
function ExportAPI.LogCall(exportName, params)
    ExportAPI.Stats.totalCalls = ExportAPI.Stats.totalCalls + 1
    
    if ExportAPI.EnableLogging then
        local paramStr = params and json.encode(params) or "none"
        HUD.Debug(string.format("Export call: %s(%s) by %s", exportName, paramStr, GetInvokingResource() or "unknown"), "EXPORT_API", "INFO")
    end
end

---Log an export error
---@param exportName string Export function name
---@param error string Error message
function ExportAPI.LogError(exportName, error)
    ExportAPI.Stats.errors = ExportAPI.Stats.errors + 1
    
    HUD.Debug(string.format("Export error in %s: %s (called by %s)", exportName, error, GetInvokingResource() or "unknown"), "EXPORT_API", "ERROR")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get table keys
---@param t table Table
---@return table keys
function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

---Register all exports at once
function ExportAPI.RegisterAllExports()
    HUD.Debug("All exports registered successfully", "EXPORT_API", "INFO")
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function ExportAPI.Cleanup()
    ExportAPI.Initialized = false
    ExportAPI.CustomModules = {}
    ExportAPI.Callbacks = {}
    
    HUD.Debug("Export API cleaned up", "EXPORT_API", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ExportAPI.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make ExportAPI available globally
_G.ExportAPI = ExportAPI

HUD.Debug("Export API module loaded", "EXPORT_API", "INFO")
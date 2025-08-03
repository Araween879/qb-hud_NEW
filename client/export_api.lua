-- ================================================================
-- QBCore HUD - Export API Module
-- Version: 3.0.0
-- Description: External resource integration and backwards compatibility
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local ExportAPI = {}
local isInitialized = false

-- ================================================================
-- INITIALIZATION
-- ================================================================

---Initialize the Export API module
function ExportAPI.Init()
    if isInitialized then
        HUD.Debug("^3Export API already initialized^7", "EXPORT_API")
        return true
    end
    
    HUD.Debug("^2Initializing Export API^7", "EXPORT_API")
    
    -- Register callbacks for external resources
    ExportAPI.RegisterCallbacks()
    
    isInitialized = true
    HUD.Debug("^2Export API initialized successfully^7", "EXPORT_API")
    
    return true
end

---Register QBCore callbacks for external access
function ExportAPI.RegisterCallbacks()
    -- Get current HUD status
    QBCore.Functions.CreateCallback('hud:getStatus', function(cb)
        local status = {}
        
        -- Collect status from all modules
        if Health and Health.GetStatus then
            status.health = Health.GetStatus()
        end
        
        if Status and Status.GetStatus then
            status.status = Status.GetStatus()
        end
        
        if Time and Time.GetTimeData then
            status.time = Time.GetTimeData()
        end
        
        if UIManager and UIManager.GetStatus then
            status.ui = UIManager.GetStatus()
        end
        
        cb(status)
    end)
    
    -- Get module specific status
    QBCore.Functions.CreateCallback('hud:getModuleStatus', function(cb, moduleName)
        local moduleStatus = nil
        
        if moduleName == 'health' and Health and Health.GetStatus then
            moduleStatus = Health.GetStatus()
        elseif moduleName == 'status' and Status and Status.GetStatus then
            moduleStatus = Status.GetStatus()
        elseif moduleName == 'time' and Time and Time.GetTimeData then
            moduleStatus = Time.GetTimeData()
        elseif moduleName == 'ui' and UIManager and UIManager.GetStatus then
            moduleStatus = UIManager.GetStatus()
        end
        
        cb(moduleStatus)
    end)
    
    HUD.Debug("^2Export callbacks registered^7", "EXPORT_API")
end

-- ================================================================
-- HUD VISIBILITY EXPORTS
-- ================================================================

---Set overall HUD visibility
---@param visible boolean
exports('SetHudVisibility', function(visible)
    if type(visible) ~= "boolean" then
        HUD.Debug("^1SetHudVisibility: Invalid parameter type^7", "EXPORT_API")
        return false
    end
    
    if UIManager and UIManager.SetHudVisibility then
        UIManager.SetHudVisibility(visible)
        HUD.Debug(string.format("^2HUD visibility set to: %s^7", visible and "visible" or "hidden"), "EXPORT_API")
        return true
    end
    
    HUD.Debug("^1SetHudVisibility: UIManager not available^7", "EXPORT_API")
    return false
end)

---Get current HUD visibility state
exports('GetHudVisibility', function()
    if UIManager and UIManager.IsHudVisible then
        return UIManager.IsHudVisible()
    end
    return true -- Default to visible if UIManager not available
end)

---Toggle HUD visibility
exports('ToggleHud', function()
    if UIManager and UIManager.IsHudVisible and UIManager.SetHudVisibility then
        local currentState = UIManager.IsHudVisible()
        UIManager.SetHudVisibility(not currentState)
        return not currentState
    end
    return false
end)

-- ================================================================
-- MODULE CONTROL EXPORTS
-- ================================================================

---Toggle specific module visibility
---@param moduleName string
---@param visible boolean
exports('ToggleModule', function(moduleName, visible)
    if type(moduleName) ~= "string" then
        HUD.Debug("^1ToggleModule: Invalid module name^7", "EXPORT_API")
        return false
    end
    
    if visible ~= nil and type(visible) ~= "boolean" then
        HUD.Debug("^1ToggleModule: Invalid visible parameter^7", "EXPORT_API")
        return false
    end
    
    if UIManager and UIManager.ToggleModule then
        UIManager.ToggleModule(moduleName, visible)
        HUD.Debug(string.format("^2Module '%s' toggled^7", moduleName), "EXPORT_API")
        return true
    end
    
    HUD.Debug("^1ToggleModule: UIManager not available^7", "EXPORT_API")
    return false
end)

---Get module visibility state
---@param moduleName string
exports('GetModuleVisibility', function(moduleName)
    if UIManager and UIManager.GetModuleVisibility then
        return UIManager.GetModuleVisibility(moduleName)
    end
    return false
end)

---Show specific module
---@param moduleName string
exports('ShowModule', function(moduleName)
    return exports['qb-hud']:ToggleModule(moduleName, true)
end)

---Hide specific module
---@param moduleName string
exports('HideModule', function(moduleName)
    return exports['qb-hud']:ToggleModule(moduleName, false)
end)

-- ================================================================
-- THEME CONTROL EXPORTS
-- ================================================================

---Set HUD theme
---@param themeName string
exports('SetTheme', function(themeName)
    if type(themeName) ~= "string" then
        HUD.Debug("^1SetTheme: Invalid theme name^7", "EXPORT_API")
        return false
    end
    
    if UIManager and UIManager.SetTheme then
        return UIManager.SetTheme(themeName)
    end
    
    HUD.Debug("^1SetTheme: UIManager not available^7", "EXPORT_API")
    return false
end)

---Get current theme
exports('GetTheme', function()
    if UIManager and UIManager.GetCurrentTheme then
        return UIManager.GetCurrentTheme()
    end
    return Config.Theme.current or 'neon-magenta'
end)

---Get available themes
exports('GetAvailableThemes', function()
    if UIManager and UIManager.GetAvailableThemes then
        return UIManager.GetAvailableThemes()
    end
    return Config.Theme.available or {'neon-magenta', 'neon-cyan', 'classic'}
end)

-- ================================================================
-- STATUS UPDATE EXPORTS
-- ================================================================

---Update health status
---@param data table
exports('UpdateHealth', function(data)
    if type(data) ~= "table" then
        HUD.Debug("^1UpdateHealth: Invalid data parameter^7", "EXPORT_API")
        return false
    end
    
    if Health and Health.Update then
        Health.Update(data)
        return true
    end
    
    return false
end)

---Update status indicators
---@param data table
exports('UpdateStatus', function(data)
    if type(data) ~= "table" then
        HUD.Debug("^1UpdateStatus: Invalid data parameter^7", "EXPORT_API")
        return false
    end
    
    if Status and Status.Update then
        Status.Update(data)
        return true
    end
    
    return false
end)

---Update time display
---@param data table
exports('UpdateTime', function(data)
    if type(data) ~= "table" then
        HUD.Debug("^1UpdateTime: Invalid data parameter^7", "EXPORT_API")
        return false
    end
    
    if Time and Time.Update then
        Time.Update(data)
        return true
    end
    
    return false
end)

-- ================================================================
-- CONVENIENCE EXPORTS (Common Use Cases)
-- ================================================================

---Set player health value
---@param health number (0-100)
exports('SetHealth', function(health)
    local healthValue = tonumber(health)
    if not healthValue then return false end
    
    return exports['qb-hud']:UpdateHealth({health = healthValue})
end)

---Set player armor value
---@param armor number (0-100)
exports('SetArmor', function(armor)
    local armorValue = tonumber(armor)
    if not armorValue then return false end
    
    return exports['qb-hud']:UpdateHealth({armor = armorValue})
end)

---Set player hunger value
---@param hunger number (0-100)
exports('SetHunger', function(hunger)
    local hungerValue = tonumber(hunger)
    if not hungerValue then return false end
    
    return exports['qb-hud']:UpdateHealth({hunger = hungerValue})
end)

---Set player thirst value
---@param thirst number (0-100)
exports('SetThirst', function(thirst)
    local thirstValue = tonumber(thirst)
    if not thirstValue then return false end
    
    return exports['qb-hud']:UpdateHealth({thirst = thirstValue})
end)

---Set player stress value
---@param stress number (0-100)
exports('SetStress', function(stress)
    local stressValue = tonumber(stress)
    if not stressValue then return false end
    
    return exports['qb-hud']:UpdateHealth({stress = stressValue})
end)

---Set voice level
---@param level number (1-4)
exports('SetVoiceLevel', function(level)
    local voiceLevel = tonumber(level)
    if not voiceLevel then return false end
    
    return exports['qb-hud']:UpdateStatus({voice = {level = voiceLevel}})
end)

---Set talking status
---@param talking boolean
exports('SetTalking', function(talking)
    if type(talking) ~= "boolean" then return false end
    
    return exports['qb-hud']:UpdateStatus({voice = {talking = talking}})
end)

---Set radio active status
---@param active boolean
exports('SetRadioActive', function(active)
    if type(active) ~= "boolean" then return false end
    
    return exports['qb-hud']:UpdateStatus({voice = {radioActive = active}})
end)

---Set armed status
---@param armed boolean
exports('SetArmed', function(armed)
    if type(armed) ~= "boolean" then return false end
    
    return exports['qb-hud']:UpdateStatus({armed = armed})
end)

-- ================================================================
-- CINEMATIC MODE EXPORTS
-- ================================================================

---Set cinematic mode
---@param enabled boolean
exports('SetCinematicMode', function(enabled)
    if type(enabled) ~= "boolean" then
        HUD.Debug("^1SetCinematicMode: Invalid parameter type^7", "EXPORT_API")
        return false
    end
    
    if UIManager and UIManager.SetCinematicMode then
        UIManager.SetCinematicMode(enabled)
        return true
    end
    
    return false
end)

---Get cinematic mode state
exports('GetCinematicMode', function()
    if UIManager and UIManager.IsCinematicMode then
        return UIManager.IsCinematicMode()
    end
    return false
end)

---Toggle cinematic mode
exports('ToggleCinematicMode', function()
    if UIManager and UIManager.IsCinematicMode and UIManager.SetCinematicMode then
        local currentState = UIManager.IsCinematicMode()
        UIManager.SetCinematicMode(not currentState)
        return not currentState
    end
    return false
end)

-- ================================================================
-- BACKWARDS COMPATIBILITY (Legacy Export Names)
-- ================================================================

-- Legacy QBCore exports for backwards compatibility
exports('ToggleAirHud', function()
    -- Legacy function - now just toggles entire HUD
    return exports['qb-hud']:ToggleHud()
end)

exports('UpdateNeeds', function(hunger, thirst)
    local data = {}
    if hunger then data.hunger = hunger end
    if thirst then data.thirst = thirst end
    return exports['qb-hud']:UpdateHealth(data)
end)

exports('UpdateStress', function(stress)
    return exports['qb-hud']:SetStress(stress)
end)

exports('ShowAccounts', function()
    -- Legacy function - trigger money display
    TriggerEvent('hud:client:ShowAccounts')
end)

exports('OnMoneyChange', function(type, amount, newAmount)
    -- Legacy function - trigger money change
    TriggerEvent('hud:client:OnMoneyChange', type, amount, newAmount)
end)

-- ================================================================
-- CUSTOM MODULE REGISTRATION
-- ================================================================

---Register a custom module (for external resources)
---@param name string Module name
---@param config table Module configuration
exports('RegisterCustomModule', function(name, config)
    if type(name) ~= "string" or type(config) ~= "table" then
        HUD.Debug("^1RegisterCustomModule: Invalid parameters^7", "EXPORT_API")
        return false
    end
    
    -- Basic validation
    if not config.enabled or not config.position then
        HUD.Debug("^1RegisterCustomModule: Missing required config fields^7", "EXPORT_API")
        return false
    end
    
    -- Add to module configuration
    Config.Modules[name] = config
    
    HUD.Debug(string.format("^2Custom module '%s' registered^7", name), "EXPORT_API")
    return true
end)

---Unregister a custom module
---@param name string Module name
exports('UnregisterCustomModule', function(name)
    if type(name) ~= "string" then return false end
    
    if Config.Modules[name] then
        Config.Modules[name] = nil
        HUD.Debug(string.format("^2Custom module '%s' unregistered^7", name), "EXPORT_API")
        return true
    end
    
    return false
end)

-- ================================================================
-- UTILITY EXPORTS
-- ================================================================

---Get full HUD status
exports('GetStatus', function()
    local status = {
        initialized = isInitialized,
        modules = {},
        theme = exports['qb-hud']:GetTheme(),
        visible = exports['qb-hud']:GetHudVisibility(),
        cinematicMode = exports['qb-hud']:GetCinematicMode()
    }
    
    -- Get individual module statuses
    for moduleName, _ in pairs(Config.Modules) do
        status.modules[moduleName] = exports['qb-hud']:GetModuleVisibility(moduleName)
    end
    
    return status
end)

---Force update all modules
exports('ForceUpdate', function()
    local updated = 0
    
    if Health and Health.ForceUpdate then
        Health.ForceUpdate()
        updated = updated + 1
    end
    
    if Status and Status.ForceUpdate then
        Status.ForceUpdate()
        updated = updated + 1
    end
    
    if Time and Time.ForceUpdate then
        Time.ForceUpdate()
        updated = updated + 1
    end
    
    HUD.Debug(string.format("^2Force updated %d modules^7", updated), "EXPORT_API")
    return updated > 0
end)

---Reset HUD to default settings
exports('Reset', function()
    local reset = 0
    
    -- Reset all modules
    for moduleName, _ in pairs(Config.Modules) do
        if exports['qb-hud']:ToggleModule(moduleName, true) then
            reset = reset + 1
        end
    end
    
    -- Reset theme
    exports['qb-hud']:SetTheme(Config.Theme.current)
    
    -- Reset visibility
    exports['qb-hud']:SetHudVisibility(true)
    exports['qb-hud']:SetCinematicMode(false)
    
    HUD.Debug(string.format("^2Reset %d modules to default^7", reset), "EXPORT_API")
    return true
end)

-- ================================================================
-- DEBUG EXPORTS
-- ================================================================

if Config.Debug then
    ---Get debug information
    exports('GetDebugInfo', function()
        return {
            initialized = isInitialized,
            modulesLoaded = HUD.LoadedModules or {},
            config = Config,
            performance = {
                lastUpdate = os.time(),
                moduleCount = 0
            }
        }
    end)
    
    ---Test all export functions
    exports('TestExports', function()
        HUD.Debug("^3Testing all export functions...^7", "EXPORT_API")
        
        -- Test basic functions
        local visibility = exports['qb-hud']:GetHudVisibility()
        local theme = exports['qb-hud']:GetTheme()
        local status = exports['qb-hud']:GetStatus()
        
        HUD.Debug(string.format("^2Visibility: %s, Theme: %s, Modules: %d^7", 
                  tostring(visibility), theme, #status.modules), "EXPORT_API")
        
        return true
    end)
end

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('export_api', ExportAPI)
end

-- Export ExportAPI for internal use
_G.ExportAPI = ExportAPI

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Export API shutting down^7", "EXPORT_API")
        isInitialized = false
    end
end)
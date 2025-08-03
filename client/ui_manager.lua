-- ================================================================
-- QBCore HUD - UI Manager Module
-- Version: 3.0.0
-- Description: Central UI management and coordination system
-- ================================================================

local UIManager = {}
local isInitialized = false
local cinematicMode = false
local currentTheme = 'neon-magenta'
local hudVisible = true
local moduleVisibility = {}

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the UI Manager module
function UIManager.Init()
    if isInitialized then
        HUD.Debug("^3UI Manager already initialized^7", "UI_MANAGER")
        return true
    end
    
    HUD.Debug("^2Initializing UI Manager^7", "UI_MANAGER")
    
    -- Set initial theme
    currentTheme = Config.Theme.current or 'neon-magenta'
    
    -- Initialize module visibility states
    for moduleName, moduleConfig in pairs(Config.Modules) do
        moduleVisibility[moduleName] = moduleConfig.enabled or false
    end
    
    -- Register events
    UIManager.RegisterEvents()
    
    -- Initialize NUI
    UIManager.InitializeNUI()
    
    -- Set cinematic mode from config
    cinematicMode = Config.Modules.ui_manager.cinematicMode or false
    if cinematicMode then
        UIManager.SetCinematicMode(true)
    end
    
    isInitialized = true
    HUD.Debug("^2UI Manager initialized successfully^7", "UI_MANAGER")
    
    return true
end

---Initialize NUI communication
function UIManager.InitializeNUI()
    -- Send initial theme configuration to NUI
    SendNUIMessage({
        action = 'setTheme',
        theme = currentTheme,
        colors = Config.Theme.colors[currentTheme],
        fonts = Config.Theme.fonts,
        animations = Config.Theme.animations,
        layout = Config.Theme.layout
    })
    
    -- Send initial module visibility states
    SendNUIMessage({
        action = 'setModuleVisibility',
        visibility = moduleVisibility
    })
    
    HUD.Debug("^2NUI initialized with theme: " .. currentTheme .. "^7", "UI_MANAGER")
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
    
    HUD.Debug("^2UI Manager events registered^7", "UI_MANAGER")
end

-- ================================================================
-- THEME MANAGEMENT
-- ================================================================

---Set the current UI theme
---@param theme string Theme name
function UIManager.SetTheme(theme)
    if not Config.Theme.colors[theme] then
        HUD.Debug(string.format("^1Theme '%s' not found, keeping current theme^7", theme), "UI_MANAGER")
        return false
    end
    
    currentTheme = theme
    
    -- Update NUI with new theme
    SendNUIMessage({
        action = 'setTheme',
        theme = theme,
        colors = Config.Theme.colors[theme],
        fonts = Config.Theme.fonts,
        animations = Config.Theme.animations,
        layout = Config.Theme.layout
    })
    
    HUD.Debug(string.format("^2Theme changed to: %s^7", theme), "UI_MANAGER")
    
    -- Trigger theme change event for other modules
    TriggerEvent('hud:client:themeChanged', theme)
    
    return true
end

---Get the current theme
---@return string
function UIManager.GetCurrentTheme()
    return currentTheme
end

---Get available themes
---@return table
function UIManager.GetAvailableThemes()
    return Config.Theme.available
end

-- ================================================================
-- MODULE VISIBILITY MANAGEMENT
-- ================================================================

---Toggle visibility of a specific module
---@param moduleName string Module name
---@param visible boolean Visibility state (optional, toggles if nil)
function UIManager.ToggleModule(moduleName, visible)
    if not Config.Modules[moduleName] then
        HUD.Debug(string.format("^1Module '%s' not found in config^7", moduleName), "UI_MANAGER")
        return false
    end
    
    -- If visible is nil, toggle current state
    if visible == nil then
        visible = not moduleVisibility[moduleName]
    end
    
    moduleVisibility[moduleName] = visible
    
    -- Send to NUI
    SendNUIMessage({
        action = 'toggleModule',
        module = moduleName,
        visible = visible
    })
    
    HUD.Debug(string.format("^2Module '%s' visibility: %s^7", moduleName, visible and "shown" or "hidden"), "UI_MANAGER")
    
    -- Trigger module visibility event
    TriggerEvent('hud:client:moduleVisibilityChanged', moduleName, visible)
    
    return true
end

---Set visibility for all modules
---@param visible boolean
function UIManager.SetHudVisibility(visible)
    hudVisible = visible
    
    -- Send to NUI
    SendNUIMessage({
        action = 'setHudVisibility',
        visible = visible
    })
    
    HUD.Debug(string.format("^2HUD visibility: %s^7", visible and "shown" or "hidden"), "UI_MANAGER")
    
    -- Trigger HUD visibility event
    TriggerEvent('hud:client:hudVisibilityChanged', visible)
end

---Get current HUD visibility state
---@return boolean
function UIManager.IsHudVisible()
    return hudVisible
end

---Get module visibility state
---@param moduleName string Module name (optional, returns all if nil)
---@return boolean|table
function UIManager.GetModuleVisibility(moduleName)
    if moduleName then
        return moduleVisibility[moduleName] or false
    else
        return moduleVisibility
    end
end

-- ================================================================
-- CINEMATIC MODE
-- ================================================================

---Set cinematic mode (black bars)
---@param enabled boolean
function UIManager.SetCinematicMode(enabled)
    cinematicMode = enabled
    
    -- Send to NUI for black bars animation
    SendNUIMessage({
        action = 'setCinematicMode',
        enabled = enabled
    })
    
    -- Hide/show radar based on cinematic mode
    DisplayRadar(not enabled)
    
    HUD.Debug(string.format("^2Cinematic mode: %s^7", enabled and "enabled" or "disabled"), "UI_MANAGER")
    
    -- Trigger cinematic mode event
    TriggerEvent('hud:client:cinematicModeChanged', enabled)
end

---Get current cinematic mode state
---@return boolean
function UIManager.IsCinematicMode()
    return cinematicMode
end

-- ================================================================
-- SCALING & LAYOUT
-- ================================================================

---Set UI scaling factor
---@param scale number Scaling factor (0.5 - 2.0)
function UIManager.SetScale(scale)
    if scale < 0.5 or scale > 2.0 then
        HUD.Debug("^1Invalid scale factor, must be between 0.5 and 2.0^7", "UI_MANAGER")
        return false
    end
    
    SendNUIMessage({
        action = 'setScale',
        scale = scale
    })
    
    HUD.Debug(string.format("^2UI scale set to: %.1f^7", scale), "UI_MANAGER")
    return true
end

---Set UI opacity
---@param opacity number Opacity value (0.1 - 1.0)
function UIManager.SetOpacity(opacity)
    if opacity < 0.1 or opacity > 1.0 then
        HUD.Debug("^1Invalid opacity value, must be between 0.1 and 1.0^7", "UI_MANAGER")
        return false
    end
    
    SendNUIMessage({
        action = 'setOpacity',
        opacity = opacity
    })
    
    HUD.Debug(string.format("^2UI opacity set to: %.1f^7", opacity), "UI_MANAGER")
    return true
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Send data update to a specific module
---@param moduleName string Module name
---@param data table Data to send
function UIManager.UpdateModule(moduleName, data)
    if not moduleVisibility[moduleName] then
        return -- Module is hidden, no need to update
    end
    
    SendNUIMessage({
        action = 'updateModule',
        module = moduleName,
        data = data
    })
end

---Get UI Manager status information
---@return table
function UIManager.GetStatus()
    return {
        initialized = isInitialized,
        theme = currentTheme,
        hudVisible = hudVisible,
        cinematicMode = cinematicMode,
        moduleVisibility = moduleVisibility
    }
end

-- ================================================================
-- EXPORT FUNCTIONS
-- ================================================================

-- Export UIManager functions for other modules
_G.UIManager = UIManager

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('ui_manager', UIManager)
end

-- ================================================================
-- CLEANUP
-- ================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3UI Manager shutting down^7", "UI_MANAGER")
        
        -- Reset NUI
        SendNUIMessage({
            action = 'shutdown'
        })
        
        isInitialized = false
    end
end)
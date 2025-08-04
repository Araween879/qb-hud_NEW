-- =======================================
-- 📄 FILE: client/hud_settings.lua
-- 📌 STEP: STEP 1 - SETTINGS-SYSTEM IMPLEMENTIERUNG
-- Diese Datei behandelt das komplette Settings-Management für das modulare HUD-System
-- VERSION: 1.0.0
-- =======================================

-- ================================================================
-- QBCore HUD - Settings System Module  
-- Version: 3.0.0
-- Description: Komplettes Settings-Management für modulares HUD-System
--              🎨 Theme-Wechsel | 🔧 Module-Toggles | 📏 UI-Scaling | 👁️ Opacity | 💾 Speichern/Laden
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Settings System
HUDSETTINGS = HUDSETTINGS or {}
HUDSETTINGS.Enabled = true
HUDSETTINGS.Initialized = false
HUDSETTINGS.MenuOpen = false

-- Settings Cache
HUDSETTINGS.Config = {
    -- Theme Settings
    theme = Config.Theme.current or 'neon-magenta',
    
    -- UI Settings
    scaling = Config.UI.scaling or 1.0,
    opacity = Config.UI.opacity or 0.9,
    animations = Config.UI.animations ~= false,
    glowEffects = Config.UI.glow_effects ~= false,
    
    -- Module Settings (aus Config.Modules übernommen)
    modules = {},
    
    -- Advanced Settings
    cinematicMode = false,
    performanceMode = false,
    debugMode = Config.Debug or false,
    
    -- Position Settings
    positions = {},
    
    -- Last Update
    lastUpdated = 0
}

-- Available Themes (aus Config)
HUDSETTINGS.AvailableThemes = Config.Theme.available or {
    'neon-magenta',
    'neon-cyan', 
    'synthwave',
    'matrix',
    'classic'
}

-- Theme Descriptions
HUDSETTINGS.ThemeDescriptions = {
    ['neon-magenta'] = 'Futuristic magenta/purple with cyan accents - Default theme',
    ['neon-cyan'] = 'Bright cyan primary with magenta highlights - Cool variant',
    ['synthwave'] = 'Retro 80s pink and purple aesthetic - Nostalgic vibes',
    ['matrix'] = 'Classic green matrix code style - Hacker aesthetic',
    ['classic'] = 'Traditional blue HUD design - Conservative look'
}

-- Performance Tracking
HUDSETTINGS.Performance = {
    lastSave = 0,
    lastLoad = 0,
    saveCount = 0,
    loadCount = 0
}

-- ================================================================
-- INITIALIZATION
-- ================================================================

function HUDSETTINGS.Init()
    if not Config.Modules.menu_ui or not Config.Modules.menu_ui.enabled then
        if HUD and HUD.Debug then
            HUD.Debug("Settings system disabled in config", "SETTINGS", "WARN")
        end
        return false
    end
    
    if HUD and HUD.Debug then
        HUD.Debug("Initializing HUD Settings system...", "SETTINGS", "INFO")
    end
    
    -- Load module configurations from Config
    HUDSETTINGS.LoadModuleDefaults()
    
    -- Load saved settings
    HUDSETTINGS.LoadSettings()
    
    -- Setup NUI callbacks
    HUDSETTINGS.SetupNUICallbacks()
    
    -- Register events
    HUDSETTINGS.RegisterEvents()
    
    -- Apply initial settings
    HUDSETTINGS.ApplyAllSettings()
    
    HUDSETTINGS.Initialized = true
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings system initialized successfully", "SETTINGS", "SUCCESS")
    end
    
    return true
end

function HUDSETTINGS.LoadModuleDefaults()
    -- Initialize module settings from Config
    for moduleName, moduleConfig in pairs(Config.Modules) do
        if type(moduleConfig) == "table" then
            HUDSETTINGS.Config.modules[moduleName] = {
                enabled = moduleConfig.enabled ~= false,
                position = moduleConfig.position or 'bottom-left',
                priority = moduleConfig.priority or 999,
                essential = moduleConfig.essential or false,
                components = moduleConfig.components or {}
            }
            
            -- Set default position if not set
            if moduleConfig.position then
                HUDSETTINGS.Config.positions[moduleName] = moduleConfig.position
            end
        end
    end
    
    if HUD and HUD.Debug then
        local moduleCount = 0
        for _ in pairs(HUDSETTINGS.Config.modules) do moduleCount = moduleCount + 1 end
        HUD.Debug(string.format("Loaded %d module configurations", moduleCount), "SETTINGS", "INFO")
    end
end

-- ================================================================
-- MENU MANAGEMENT
-- ================================================================

function HUDSETTINGS.OpenMenu()
    if not HUDSETTINGS.Initialized then
        if HUD and HUD.Debug then
            HUD.Debug("Settings system not initialized", "SETTINGS", "ERROR")
        end
        return false
    end
    
    if HUDSETTINGS.MenuOpen then
        if HUD and HUD.Debug then
            HUD.Debug("Settings menu already open", "SETTINGS", "WARN")
        end
        return false
    end
    
    -- Get current settings for menu
    local menuData = HUDSETTINGS.GetMenuData()
    
    -- Send to NUI
    SendNUIMessage({
        action = 'openSettings',
        data = menuData
    })
    
    -- Set focus
    SetNuiFocus(true, true)
    HUDSETTINGS.MenuOpen = true
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings menu opened", "SETTINGS", "INFO")
    end
    
    return true
end

function HUDSETTINGS.CloseMenu()
    if not HUDSETTINGS.MenuOpen then return false end
    
    -- Send close to NUI
    SendNUIMessage({
        action = 'closeSettings'
    })
    
    -- Remove focus
    SetNuiFocus(false, false)
    HUDSETTINGS.MenuOpen = false
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings menu closed", "SETTINGS", "INFO")
    end
    
    return true
end

function HUDSETTINGS.GetMenuData()
    return {
        -- Current settings
        current = {
            theme = HUDSETTINGS.Config.theme,
            scaling = HUDSETTINGS.Config.scaling,
            opacity = HUDSETTINGS.Config.opacity,
            animations = HUDSETTINGS.Config.animations,
            glowEffects = HUDSETTINGS.Config.glowEffects,
            cinematicMode = HUDSETTINGS.Config.cinematicMode,
            performanceMode = HUDSETTINGS.Config.performanceMode,
            debugMode = HUDSETTINGS.Config.debugMode
        },
        
        -- Available options
        themes = HUDSETTINGS.AvailableThemes,
        themeDescriptions = HUDSETTINGS.ThemeDescriptions,
        
        -- Module settings
        modules = HUDSETTINGS.Config.modules,
        
        -- Position settings
        positions = HUDSETTINGS.Config.positions,
        
        -- Performance data
        performance = HUDSETTINGS.Performance,
        
        -- Metadata
        lastUpdated = HUDSETTINGS.Config.lastUpdated,
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '3.0.0'
    }
end

-- ================================================================
-- THEME MANAGEMENT
-- ================================================================

function HUDSETTINGS.SetTheme(themeName)
    if type(themeName) ~= "string" then
        if HUD and HUD.Debug then
            HUD.Debug("Invalid theme name provided", "SETTINGS", "ERROR")
        end
        return false
    end
    
    -- Validate theme exists
    local validTheme = false
    for _, availableTheme in ipairs(HUDSETTINGS.AvailableThemes) do
        if availableTheme == themeName then
            validTheme = true
            break
        end
    end
    
    if not validTheme then
        if HUD and HUD.Debug then
            HUD.Debug(string.format("Theme '%s' not available", themeName), "SETTINGS", "ERROR")
        end
        return false
    end
    
    -- Update local config
    HUDSETTINGS.Config.theme = themeName
    
    -- Apply theme to UI
    HUDSETTINGS.ApplyTheme(themeName)
    
    -- Notify other modules via UIManager
    if UIManager and UIManager.SetTheme then
        UIManager.SetTheme(themeName)
    end
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Theme changed to '%s'", themeName), "SETTINGS", "SUCCESS")
    end
    
    return true
end

function HUDSETTINGS.ApplyTheme(themeName)
    if not themeName then themeName = HUDSETTINGS.Config.theme end
    
    -- Send theme to NUI
    SendNUIMessage({
        action = 'setTheme',
        data = {
            theme = themeName,
            description = HUDSETTINGS.ThemeDescriptions[themeName] or 'Custom theme'
        }
    })
    
    -- Update global theme variable if exists
    if Config.Theme then
        Config.Theme.current = themeName
    end
end

function HUDSETTINGS.GetCurrentTheme()
    return HUDSETTINGS.Config.theme
end

function HUDSETTINGS.GetAvailableThemes()
    return HUDSETTINGS.AvailableThemes, HUDSETTINGS.ThemeDescriptions
end

-- ================================================================
-- MODULE MANAGEMENT
-- ================================================================

function HUDSETTINGS.ToggleModule(moduleName, enabled)
    if type(moduleName) ~= "string" then
        if HUD and HUD.Debug then
            HUD.Debug("Invalid module name provided", "SETTINGS", "ERROR")
        end
        return false
    end
    
    if not HUDSETTINGS.Config.modules[moduleName] then
        if HUD and HUD.Debug then
            HUD.Debug(string.format("Module '%s' not found", moduleName), "SETTINGS", "ERROR")
        end
        return false
    end
    
    -- Check if module is essential (cannot be disabled)
    if HUDSETTINGS.Config.modules[moduleName].essential and not enabled then
        if HUD and HUD.Debug then
            HUD.Debug(string.format("Module '%s' is essential and cannot be disabled", moduleName), "SETTINGS", "WARN")
        end
        return false
    end
    
    -- Update module state
    HUDSETTINGS.Config.modules[moduleName].enabled = enabled
    
    -- Apply module visibility via UIManager
    if UIManager and UIManager.ToggleModule then
        UIManager.ToggleModule(moduleName, enabled)
    end
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Module '%s' %s", moduleName, enabled and "enabled" or "disabled"), "SETTINGS", "INFO")
    end
    
    return true
end

function HUDSETTINGS.SetModulePosition(moduleName, position)
    if type(moduleName) ~= "string" or type(position) ~= "string" then
        return false
    end
    
    if not HUDSETTINGS.Config.modules[moduleName] then
        return false
    end
    
    -- Valid positions
    local validPositions = {
        'top-left', 'top-center', 'top-right',
        'center-left', 'center-center', 'center-right',
        'bottom-left', 'bottom-center', 'bottom-right'
    }
    
    local validPosition = false
    for _, pos in ipairs(validPositions) do
        if pos == position then
            validPosition = true
            break
        end
    end
    
    if not validPosition then
        return false
    end
    
    -- Update position
    HUDSETTINGS.Config.modules[moduleName].position = position
    HUDSETTINGS.Config.positions[moduleName] = position
    
    -- Apply position change
    if UIManager and UIManager.SetModulePosition then
        UIManager.SetModulePosition(moduleName, position)
    end
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

function HUDSETTINGS.GetModuleStatus(moduleName)
    if not moduleName then
        return HUDSETTINGS.Config.modules
    end
    
    return HUDSETTINGS.Config.modules[moduleName]
end

-- ================================================================
-- UI SETTINGS MANAGEMENT
-- ================================================================

function HUDSETTINGS.SetScaling(scale)
    local scaleValue = tonumber(scale)
    if not scaleValue then return false end
    
    -- Clamp scale between 0.5 and 2.0
    scaleValue = math.max(0.5, math.min(2.0, scaleValue))
    
    HUDSETTINGS.Config.scaling = scaleValue
    
    -- Apply scaling via UIManager
    if UIManager and UIManager.SetScale then
        UIManager.SetScale(scaleValue)
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'setScaling',
        data = { scaling = scaleValue }
    })
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

function HUDSETTINGS.SetOpacity(opacity)
    local opacityValue = tonumber(opacity)
    if not opacityValue then return false end
    
    -- Clamp opacity between 0.1 and 1.0
    opacityValue = math.max(0.1, math.min(1.0, opacityValue))
    
    HUDSETTINGS.Config.opacity = opacityValue
    
    -- Apply opacity via UIManager
    if UIManager and UIManager.SetOpacity then
        UIManager.SetOpacity(opacityValue)
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'setOpacity',
        data = { opacity = opacityValue }
    })
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

function HUDSETTINGS.ToggleAnimations(enabled)
    if type(enabled) ~= "boolean" then return false end
    
    HUDSETTINGS.Config.animations = enabled
    
    -- Apply animation setting
    SendNUIMessage({
        action = 'setAnimations',
        data = { animations = enabled }
    })
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

function HUDSETTINGS.ToggleGlowEffects(enabled)
    if type(enabled) ~= "boolean" then return false end
    
    HUDSETTINGS.Config.glowEffects = enabled
    
    -- Apply glow effects setting
    SendNUIMessage({
        action = 'setGlowEffects',
        data = { glowEffects = enabled }
    })
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

-- ================================================================
-- ADVANCED SETTINGS
-- ================================================================

function HUDSETTINGS.ToggleCinematicMode(enabled)
    if type(enabled) ~= "boolean" then enabled = not HUDSETTINGS.Config.cinematicMode end
    
    HUDSETTINGS.Config.cinematicMode = enabled
    
    -- Apply cinematic mode via UIManager
    if UIManager and UIManager.SetCinematicMode then
        UIManager.SetCinematicMode(enabled)
    end
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Cinematic mode %s", enabled and "enabled" or "disabled"), "SETTINGS", "INFO")
    end
    
    return true
end

function HUDSETTINGS.TogglePerformanceMode(enabled)
    if type(enabled) ~= "boolean" then enabled = not HUDSETTINGS.Config.performanceMode end
    
    HUDSETTINGS.Config.performanceMode = enabled
    
    -- Apply performance mode
    SendNUIMessage({
        action = 'setPerformanceMode',
        data = { performanceMode = enabled }
    })
    
    -- Adjust update intervals if performance mode
    if enabled then
        -- Reduce update frequency for performance
        if GPSHUD then GPSHUD.UpdateInterval = 500 end
        if Health then Health.UpdateInterval = 1000 end
        if Status then Status.UpdateInterval = 500 end
    else
        -- Restore normal update frequency
        if GPSHUD then GPSHUD.UpdateInterval = Config.GPSHUD.updateInterval or 200 end
        if Health then Health.UpdateInterval = Config.Modules.health.updateInterval or 500 end
        if Status then Status.UpdateInterval = Config.Modules.status.updateInterval or 200 end
    end
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    return true
end

function HUDSETTINGS.ToggleDebugMode(enabled)
    if type(enabled) ~= "boolean" then enabled = not HUDSETTINGS.Config.debugMode end
    
    HUDSETTINGS.Config.debugMode = enabled
    
    -- Update global debug setting
    if Config then
        Config.Debug = enabled
    end
    
    -- Apply debug mode
    SendNUIMessage({
        action = 'setDebugMode',
        data = { debugMode = enabled }
    })
    
    -- Save settings
    HUDSETTINGS.SaveSettings()
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Debug mode %s", enabled and "enabled" or "disabled"), "SETTINGS", "INFO")
    end
    
    return true
end

-- ================================================================
-- SETTINGS PERSISTENCE
-- ================================================================

function HUDSETTINGS.SaveSettings()
    if not HUDSETTINGS.Initialized then return false end
    
    -- Prepare settings data for saving
    local settingsData = {
        theme = HUDSETTINGS.Config.theme,
        scaling = HUDSETTINGS.Config.scaling,
        opacity = HUDSETTINGS.Config.opacity,
        animations = HUDSETTINGS.Config.animations,
        glowEffects = HUDSETTINGS.Config.glowEffects,
        modules = HUDSETTINGS.Config.modules,
        positions = HUDSETTINGS.Config.positions,
        cinematicMode = HUDSETTINGS.Config.cinematicMode,
        performanceMode = HUDSETTINGS.Config.performanceMode,
        debugMode = HUDSETTINGS.Config.debugMode,
        lastUpdated = GetGameTimer(),
        version = '3.0.0'
    }
    
    -- Save to server via callback
    QBCore.Functions.TriggerCallback('hud:server:saveSettings', function(result)
        if result and result.success then
            HUDSETTINGS.Config.lastUpdated = GetGameTimer()
            HUDSETTINGS.Performance.lastSave = GetGameTimer()
            HUDSETTINGS.Performance.saveCount = HUDSETTINGS.Performance.saveCount + 1
            
            if HUD and HUD.Debug then
                HUD.Debug("Settings saved successfully", "SETTINGS", "SUCCESS")
            end
        else
            if HUD and HUD.Debug then
                HUD.Debug("Failed to save settings: " .. (result and result.error or "Unknown error"), "SETTINGS", "ERROR")
            end
        end
    end, settingsData)
    
    return true
end

function HUDSETTINGS.LoadSettings()
    -- Load settings from server via callback
    QBCore.Functions.TriggerCallback('hud:server:getSettings', function(savedSettings)
        if savedSettings and type(savedSettings) == "table" then
            -- Merge saved settings with defaults
            if savedSettings.theme then HUDSETTINGS.Config.theme = savedSettings.theme end
            if savedSettings.scaling then HUDSETTINGS.Config.scaling = savedSettings.scaling end
            if savedSettings.opacity then HUDSETTINGS.Config.opacity = savedSettings.opacity end
            if savedSettings.animations ~= nil then HUDSETTINGS.Config.animations = savedSettings.animations end
            if savedSettings.glowEffects ~= nil then HUDSETTINGS.Config.glowEffects = savedSettings.glowEffects end
            if savedSettings.cinematicMode ~= nil then HUDSETTINGS.Config.cinematicMode = savedSettings.cinematicMode end
            if savedSettings.performanceMode ~= nil then HUDSETTINGS.Config.performanceMode = savedSettings.performanceMode end
            if savedSettings.debugMode ~= nil then HUDSETTINGS.Config.debugMode = savedSettings.debugMode end
            
            -- Merge module settings
            if savedSettings.modules and type(savedSettings.modules) == "table" then
                for moduleName, moduleSettings in pairs(savedSettings.modules) do
                    if HUDSETTINGS.Config.modules[moduleName] and type(moduleSettings) == "table" then
                        for key, value in pairs(moduleSettings) do
                            HUDSETTINGS.Config.modules[moduleName][key] = value
                        end
                    end
                end
            end
            
            -- Merge position settings
            if savedSettings.positions and type(savedSettings.positions) == "table" then
                for moduleName, position in pairs(savedSettings.positions) do
                    HUDSETTINGS.Config.positions[moduleName] = position
                end
            end
            
            HUDSETTINGS.Performance.lastLoad = GetGameTimer()
            HUDSETTINGS.Performance.loadCount = HUDSETTINGS.Performance.loadCount + 1
            
            if HUD and HUD.Debug then
                HUD.Debug("Settings loaded successfully", "SETTINGS", "SUCCESS")
            end
        else
            if HUD and HUD.Debug then
                HUD.Debug("No saved settings found, using defaults", "SETTINGS", "INFO")
            end
        end
    end)
end

function HUDSETTINGS.ResetSettings()
    -- Reset to default values
    HUDSETTINGS.Config.theme = Config.Theme.current or 'neon-magenta'
    HUDSETTINGS.Config.scaling = Config.UI.scaling or 1.0
    HUDSETTINGS.Config.opacity = Config.UI.opacity or 0.9
    HUDSETTINGS.Config.animations = Config.UI.animations ~= false
    HUDSETTINGS.Config.glowEffects = Config.UI.glow_effects ~= false
    HUDSETTINGS.Config.cinematicMode = false
    HUDSETTINGS.Config.performanceMode = false
    HUDSETTINGS.Config.debugMode = Config.Debug or false
    
    -- Reset module settings to defaults
    HUDSETTINGS.LoadModuleDefaults()
    
    -- Apply all settings
    HUDSETTINGS.ApplyAllSettings()
    
    -- Save reset settings
    HUDSETTINGS.SaveSettings()
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings reset to defaults", "SETTINGS", "INFO")
    end
    
    return true
end

-- ================================================================
-- SETTINGS APPLICATION
-- ================================================================

function HUDSETTINGS.ApplyAllSettings()
    -- Apply theme
    HUDSETTINGS.ApplyTheme(HUDSETTINGS.Config.theme)
    
    -- Apply UI settings
    if UIManager then
        if UIManager.SetScale then UIManager.SetScale(HUDSETTINGS.Config.scaling) end
        if UIManager.SetOpacity then UIManager.SetOpacity(HUDSETTINGS.Config.opacity) end
        if UIManager.SetCinematicMode then UIManager.SetCinematicMode(HUDSETTINGS.Config.cinematicMode) end
    end
    
    -- Apply module settings
    for moduleName, moduleConfig in pairs(HUDSETTINGS.Config.modules) do
        if UIManager and UIManager.ToggleModule then
            UIManager.ToggleModule(moduleName, moduleConfig.enabled)
        end
        if moduleConfig.position and UIManager and UIManager.SetModulePosition then
            UIManager.SetModulePosition(moduleName, moduleConfig.position)
        end
    end
    
    -- Apply advanced settings
    SendNUIMessage({
        action = 'applyAllSettings',
        data = {
            theme = HUDSETTINGS.Config.theme,
            scaling = HUDSETTINGS.Config.scaling,
            opacity = HUDSETTINGS.Config.opacity,
            animations = HUDSETTINGS.Config.animations,
            glowEffects = HUDSETTINGS.Config.glowEffects,
            performanceMode = HUDSETTINGS.Config.performanceMode,
            debugMode = HUDSETTINGS.Config.debugMode
        }
    })
    
    if HUD and HUD.Debug then
        HUD.Debug("All settings applied", "SETTINGS", "SUCCESS")
    end
end

-- ================================================================
-- EVENT HANDLING
-- ================================================================

function HUDSETTINGS.RegisterEvents()
    -- Register QBCore events for settings
    RegisterNetEvent('hud:client:openSettings', function()
        HUDSETTINGS.OpenMenu()
    end)
    
    RegisterNetEvent('hud:client:closeSettings', function()
        HUDSETTINGS.CloseMenu()
    end)
    
    RegisterNetEvent('hud:client:resetSettings', function()
        HUDSETTINGS.ResetSettings()
    end)
    
    RegisterNetEvent('hud:client:updateSettings', function(settings)
        if settings and type(settings) == "table" then
            -- Apply updated settings
            for key, value in pairs(settings) do
                if HUDSETTINGS.Config[key] ~= nil then
                    HUDSETTINGS.Config[key] = value
                end
            end
            HUDSETTINGS.ApplyAllSettings()
        end
    end)
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings events registered", "SETTINGS", "INFO")
    end
end

function HUDSETTINGS.SetupNUICallbacks()
    -- Settings menu callbacks
    RegisterNUICallback('closeSettings', function(data, cb)
        HUDSETTINGS.CloseMenu()
        cb('ok')
    end)
    
    RegisterNUICallback('applyTheme', function(data, cb)
        if data.theme then
            HUDSETTINGS.SetTheme(data.theme)
        end
        cb('ok')
    end)
    
    RegisterNUICallback('updateSetting', function(data, cb)
        if not data.setting or not data.value then
            cb('error')
            return
        end
        
        local success = false
        local setting = data.setting
        local value = data.value
        
        if setting == 'scaling' then
            success = HUDSETTINGS.SetScaling(value)
        elseif setting == 'opacity' then
            success = HUDSETTINGS.SetOpacity(value)
        elseif setting == 'animations' then
            success = HUDSETTINGS.ToggleAnimations(value)
        elseif setting == 'glowEffects' then
            success = HUDSETTINGS.ToggleGlowEffects(value)
        elseif setting == 'cinematicMode' then
            success = HUDSETTINGS.ToggleCinematicMode(value)
        elseif setting == 'performanceMode' then
            success = HUDSETTINGS.TogglePerformanceMode(value)
        elseif setting == 'debugMode' then
            success = HUDSETTINGS.ToggleDebugMode(value)
        end
        
        cb(success and 'ok' or 'error')
    end)
    
    RegisterNUICallback('toggleModule', function(data, cb)
        if not data.module or data.enabled == nil then
            cb('error')
            return
        end
        
        local success = HUDSETTINGS.ToggleModule(data.module, data.enabled)
        cb(success and 'ok' or 'error')
    end)
    
    RegisterNUICallback('setModulePosition', function(data, cb)
        if not data.module or not data.position then
            cb('error')
            return
        end
        
        local success = HUDSETTINGS.SetModulePosition(data.module, data.position)
        cb(success and 'ok' or 'error')
    end)
    
    RegisterNUICallback('saveSettings', function(data, cb)
        HUDSETTINGS.SaveSettings()
        cb('ok')
    end)
    
    RegisterNUICallback('resetSettings', function(data, cb)
        HUDSETTINGS.ResetSettings()
        cb('ok')
    end)
    
    RegisterNUICallback('getSettingsData', function(data, cb)
        cb(HUDSETTINGS.GetMenuData())
    end)
    
    if HUD and HUD.Debug then
        HUD.Debug("Settings NUI callbacks registered", "SETTINGS", "INFO")
    end
end

-- ================================================================
-- EXPORT FUNCTIONS
-- ================================================================

-- Get current settings
function HUDSETTINGS.GetStatus()
    return {
        initialized = HUDSETTINGS.Initialized,
        menuOpen = HUDSETTINGS.MenuOpen,
        config = HUDSETTINGS.Config,
        performance = HUDSETTINGS.Performance,
        themes = HUDSETTINGS.AvailableThemes
    }
end

-- Force update all settings
function HUDSETTINGS.ForceUpdate()
    if not HUDSETTINGS.Initialized then return false end
    
    HUDSETTINGS.ApplyAllSettings()
    return true
end

-- Debug information
function HUDSETTINGS.Debug()
    if HUD and HUD.Debug then
        HUD.Debug("=== SETTINGS DEBUG INFO ===", "SETTINGS", "INFO")
        HUD.Debug(string.format("Initialized: %s", HUDSETTINGS.Initialized), "SETTINGS", "INFO")
        HUD.Debug(string.format("Menu Open: %s", HUDSETTINGS.MenuOpen), "SETTINGS", "INFO")
        HUD.Debug(string.format("Current Theme: %s", HUDSETTINGS.Config.theme), "SETTINGS", "INFO")
        HUD.Debug(string.format("Scaling: %.2f", HUDSETTINGS.Config.scaling), "SETTINGS", "INFO")
        HUD.Debug(string.format("Opacity: %.2f", HUDSETTINGS.Config.opacity), "SETTINGS", "INFO")
        HUD.Debug(string.format("Animations: %s", HUDSETTINGS.Config.animations), "SETTINGS", "INFO")
        HUD.Debug(string.format("Glow Effects: %s", HUDSETTINGS.Config.glowEffects), "SETTINGS", "INFO")
        HUD.Debug(string.format("Performance Mode: %s", HUDSETTINGS.Config.performanceMode), "SETTINGS", "INFO")
        HUD.Debug(string.format("Debug Mode: %s", HUDSETTINGS.Config.debugMode), "SETTINGS", "INFO")
        
        local moduleCount = 0
        for moduleName, moduleConfig in pairs(HUDSETTINGS.Config.modules) do
            if moduleConfig.enabled then moduleCount = moduleCount + 1 end
        end
        HUD.Debug(string.format("Active Modules: %d", moduleCount), "SETTINGS", "INFO")
        
        HUD.Debug(string.format("Save Count: %d", HUDSETTINGS.Performance.saveCount), "SETTINGS", "INFO")
        HUD.Debug(string.format("Load Count: %d", HUDSETTINGS.Performance.loadCount), "SETTINGS", "INFO")
        HUD.Debug("=== END SETTINGS DEBUG ===", "SETTINGS", "INFO")
    end
end

-- ================================================================
-- INITIALIZATION ON LOAD
-- ================================================================

-- Register with HUD system
if HUD then
    HUD.RegisterModule('hud_settings', HUDSETTINGS)
    
    if HUD.Debug then
        HUD.Debug("Settings module registered with HUD system", "SETTINGS", "SUCCESS")
    end
end
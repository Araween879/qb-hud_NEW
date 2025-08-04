-- ================================================================
-- QBCore HUD - Menu UI System Module
-- Version: 3.0.0
-- Description: Advanced settings menu with live preview and persistence
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Menu UI System Module
MenuUI = MenuUI or {}
MenuUI.Initialized = false
MenuUI.MenuOpen = false
MenuUI.OpenKey = Config.Modules.menu_ui.openKey or 'I'

-- Menu State Management
MenuUI.State = {
    currentTab = 'general',         -- Current menu tab
    hasUnsavedChanges = false,      -- Unsaved changes flag
    lastSaveTime = 0,              -- Last save timestamp
    previewMode = false,           -- Live preview mode
    settingsBackup = {},           -- Settings backup for cancel
    menuPosition = { x = 50, y = 50 }, -- Menu position percentage
    menuSize = { width = 600, height = 700 } -- Menu size in pixels
}

-- Settings Data
MenuUI.Settings = {
    -- Theme settings
    theme = {
        current = 'neon-magenta',
        available = {'neon-magenta', 'neon-cyan', 'synthwave', 'classic'},
        preview = false
    },
    
    -- UI settings
    ui = {
        scaling = 1.0,
        opacity = 0.9,
        animations = true,
        glowEffects = true,
        cinematicMode = false,
        lowEndMode = false
    },
    
    -- Module settings
    modules = {
        gps_hud = { enabled = true, position = 'bottom-left' },
        time = { enabled = true, position = 'top-right' },
        location = { enabled = true, position = 'top-center' },
        vehicle = { enabled = true, position = 'bottom-right' },
        health = { enabled = false, position = 'bottom-left' },
        status = { enabled = false, position = 'bottom-center' }
    },
    
    -- Display settings
    display = {
        showWhenFull = false,
        showPercentages = false,
        compactMode = false,
        showCoordinates = false,
        showPostal = false,
        format24h = true
    },
    
    -- Performance settings
    performance = {
        updateInterval = 200,
        enableCaching = true,
        batchUpdates = true,
        enableProfiling = false
    },
    
    -- Audio settings
    audio = {
        enabled = true,
        volume = 0.3,
        soundEffects = true,
        voiceSound = true,
        lowHealthSound = true,
        stressSound = true
    },
    
    -- Keybind settings
    keybinds = {
        openMenu = 'I',
        toggleHUD = 'F2',
        toggleCinematic = 'F1',
        cycleVoice = 'F3',
        toggleMap = 'M'
    }
}

-- Menu Tabs Configuration
MenuUI.Tabs = {
    {
        id = 'general',
        name = 'General',
        icon = 'fas fa-home',
        order = 1
    },
    {
        id = 'theme',
        name = 'Themes',
        icon = 'fas fa-palette',
        order = 2
    },
    {
        id = 'modules',
        name = 'Modules',
        icon = 'fas fa-puzzle-piece',
        order = 3
    },
    {
        id = 'display',
        name = 'Display',
        icon = 'fas fa-desktop',
        order = 4
    },
    {
        id = 'performance',
        name = 'Performance',
        icon = 'fas fa-tachometer-alt',
        order = 5
    },
    {
        id = 'audio',
        name = 'Audio',
        icon = 'fas fa-volume-up',
        order = 6
    },
    {
        id = 'keybinds',
        name = 'Keybinds',
        icon = 'fas fa-keyboard',
        order = 7
    },
    {
        id = 'about',
        name = 'About',
        icon = 'fas fa-info-circle',
        order = 8
    }
}

-- Performance tracking
MenuUI.Performance = {
    openCount = 0,
    saveCount = 0,
    averageLoadTime = 0,
    totalMenuTime = 0
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Menu UI module
---@return boolean success
function MenuUI.Init()
    if MenuUI.Initialized then
        HUD.Debug("Menu UI already initialized", "MENU_UI", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Menu UI system...", "MENU_UI", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.menu_ui.enabled then
        HUD.Debug("Menu UI disabled in config", "MENU_UI", "INFO")
        return false
    end
    
    -- Load configuration
    MenuUI.LoadConfiguration()
    
    -- Load saved settings
    MenuUI.LoadSettings()
    
    -- Register events
    MenuUI.RegisterEvents()
    
    -- Register NUI callbacks
    MenuUI.RegisterNUICallbacks()
    
    -- Register keybinds
    MenuUI.RegisterKeybinds()
    
    -- Initialize menu data
    MenuUI.InitializeMenuData()
    
    MenuUI.Initialized = true
    HUD.Debug("Menu UI system initialized successfully", "MENU_UI", "INFO")
    
    return true
end

---Load Menu UI configuration
function MenuUI.LoadConfiguration()
    local config = Config.Modules.menu_ui or {}
    
    MenuUI.OpenKey = config.openKey or 'I'
    
    -- Load current settings from other modules
    if UIManager and UIManager.GetState then
        local uiState = UIManager.GetState()
        MenuUI.Settings.theme.current = uiState.theme
        MenuUI.Settings.ui.scaling = uiState.scaling
        MenuUI.Settings.ui.opacity = uiState.opacity
        MenuUI.Settings.ui.animations = uiState.animations
        MenuUI.Settings.ui.glowEffects = uiState.glowEffects
        MenuUI.Settings.ui.cinematicMode = uiState.cinematicMode
        MenuUI.Settings.modules = uiState.moduleVisibility
    end
    
    HUD.Debug("Menu UI configuration loaded", "MENU_UI", "INFO")
end

---Initialize menu data
function MenuUI.InitializeMenuData()
    -- Load available themes
    MenuUI.Settings.theme.available = Config.Theme.available or MenuUI.Settings.theme.available
    
    -- Load module information
    for moduleName, moduleConfig in pairs(Config.Modules) do
        if not MenuUI.Settings.modules[moduleName] then
            MenuUI.Settings.modules[moduleName] = {
                enabled = moduleConfig.enabled or false,
                position = moduleConfig.position or 'bottom-left'
            }
        end
    end
    
    HUD.Debug("Menu data initialized", "MENU_UI", "INFO")
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register Menu UI events
function MenuUI.RegisterEvents()
    -- Player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        MenuUI.LoadSettings()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        MenuUI.SaveSettings()
        MenuUI.CloseMenu()
    end)
    
    -- Menu control events
    RegisterNetEvent('hud:client:openMenu', function()
        MenuUI.OpenMenu()
    end)
    
    RegisterNetEvent('hud:client:closeMenu', function()
        MenuUI.CloseMenu()
    end)
    
    -- Settings events
    RegisterNetEvent('hud:client:resetSettings', function()
        MenuUI.ResetSettings()
    end)
    
    HUD.Debug("Menu UI events registered", "MENU_UI", "INFO")
end

---Register NUI callbacks
function MenuUI.RegisterNUICallbacks()
    -- Menu control callbacks
    RegisterNUICallback('openMenu', function(data, cb)
        MenuUI.OnMenuOpen()
        cb('ok')
    end)
    
    RegisterNUICallback('closeMenu', function(data, cb)
        MenuUI.OnMenuClose()
        cb('ok')
    end)
    
    -- Tab navigation
    RegisterNUICallback('changeTab', function(data, cb)
        MenuUI.ChangeTab(data.tab)
        cb('ok')
    end)
    
    -- Settings callbacks
    RegisterNUICallback('updateSetting', function(data, cb)
        MenuUI.UpdateSetting(data.category, data.key, data.value)
        cb('ok')
    end)
    
    RegisterNUICallback('previewSetting', function(data, cb)
        MenuUI.PreviewSetting(data.category, data.key, data.value)
        cb('ok')
    end)
    
    RegisterNUICallback('resetSettings', function(data, cb)
        MenuUI.ResetSettings()
        cb('ok')
    end)
    
    RegisterNUICallback('saveSettings', function(data, cb)
        MenuUI.SaveSettings()
        cb('ok')
    end)
    
    RegisterNUICallback('loadSettings', function(data, cb)
        MenuUI.SendMenuData()
        cb('ok')
    end)
    
    RegisterNUICallback('exportSettings', function(data, cb)
        MenuUI.ExportSettings()
        cb('ok')
    end)
    
    RegisterNUICallback('importSettings', function(data, cb)
        MenuUI.ImportSettings(data.settings)
        cb('ok')
    end)
    
    -- Module management
    RegisterNUICallback('toggleModule', function(data, cb)
        MenuUI.ToggleModule(data.module, data.enabled)
        cb('ok')
    end)
    
    RegisterNUICallback('resetModule', function(data, cb)
        MenuUI.ResetModule(data.module)
        cb('ok')
    end)
    
    -- Performance callbacks
    RegisterNUICallback('getPerformanceStats', function(data, cb)
        cb(MenuUI.GetPerformanceStats())
    end)
    
    HUD.Debug("Menu UI NUI callbacks registered", "MENU_UI", "INFO")
end

---Register keybinds
function MenuUI.RegisterKeybinds()
    -- Menu toggle keybind
    RegisterKeyMapping('openHudMenu', 'Open HUD Menu', 'keyboard', MenuUI.OpenKey)
    
    -- Register command
    RegisterCommand('openHudMenu', function()
        MenuUI.ToggleMenu()
    end, false)
    
    -- Alternative commands
    RegisterCommand('hud', function(source, args)
        if args[1] then
            MenuUI.HandleCommand(args)
        else
            MenuUI.ToggleMenu()
        end
    end, false)
    
    RegisterCommand('hudmenu', function()
        MenuUI.OpenMenu()
    end, false)
    
    HUD.Debug("Menu UI keybinds registered", "MENU_UI", "INFO")
end

-- ================================================================
-- MENU MANAGEMENT
-- ================================================================

---Open the menu
function MenuUI.OpenMenu()
    if MenuUI.MenuOpen then return end
    
    local startTime = GetGameTimer()
    
    MenuUI.MenuOpen = true
    MenuUI.State.hasUnsavedChanges = false
    MenuUI.State.previewMode = false
    
    -- Backup current settings
    MenuUI.BackupSettings()
    
    -- Send menu data to NUI
    MenuUI.SendMenuData()
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    -- Show menu
    SendNUIMessage({
        action = 'showMenu',
        visible = true
    })
    
    -- Performance tracking
    local loadTime = GetGameTimer() - startTime
    MenuUI.Performance.openCount = MenuUI.Performance.openCount + 1
    MenuUI.Performance.averageLoadTime = (MenuUI.Performance.averageLoadTime + loadTime) / 2
    
    HUD.Debug(string.format("Menu opened in %dms", loadTime), "MENU_UI", "INFO")
    
    -- Play sound if enabled
    if Config.Modules.menu_ui.enableSounds and GetResourceState('interact-sound') == 'started' then
        exports['interact-sound']:PlaySound("menu_open")
    end
end

---Close the menu
function MenuUI.CloseMenu()
    if not MenuUI.MenuOpen then return end
    
    MenuUI.MenuOpen = false
    
    -- Check for unsaved changes
    if MenuUI.State.hasUnsavedChanges then
        MenuUI.PromptSaveChanges()
    end
    
    -- Remove NUI focus
    SetNuiFocus(false, false)
    
    -- Hide menu
    SendNUIMessage({
        action = 'hideMenu',
        visible = false
    })
    
    -- Clear preview mode
    if MenuUI.State.previewMode then
        MenuUI.RestoreSettings()
        MenuUI.State.previewMode = false
    end
    
    HUD.Debug("Menu closed", "MENU_UI", "INFO")
    
    -- Play sound if enabled
    if Config.Modules.menu_ui.enableSounds and GetResourceState('interact-sound') == 'started' then
        exports['interact-sound']:PlaySound("menu_close")
    end
end

---Toggle the menu
function MenuUI.ToggleMenu()
    if MenuUI.MenuOpen then
        MenuUI.CloseMenu()
    else
        MenuUI.OpenMenu()
    end
end

---Change active tab
---@param tabId string Tab identifier
function MenuUI.ChangeTab(tabId)
    if MenuUI.State.currentTab == tabId then return end
    
    MenuUI.State.currentTab = tabId
    
    -- Send tab change to NUI
    SendNUIMessage({
        action = 'changeTab',
        tab = tabId
    })
    
    HUD.Debug(string.format("Tab changed to: %s", tabId), "MENU_UI", "INFO")
end

---Send menu data to NUI
function MenuUI.SendMenuData()
    local menuData = {
        -- Current state
        currentTab = MenuUI.State.currentTab,
        hasUnsavedChanges = MenuUI.State.hasUnsavedChanges,
        previewMode = MenuUI.State.previewMode,
        
        -- Settings
        settings = MenuUI.Settings,
        
        -- Tabs
        tabs = MenuUI.Tabs,
        
        -- System information
        system = {
            version = HUD.Version or '3.0.0',
            framework = 'QBCore',
            modules = MenuUI.GetModuleStatus(),
            performance = MenuUI.GetPerformanceStats()
        },
        
        -- Localization
        locale = Config.Locale or 'en'
    }
    
    SendNUIMessage({
        action = 'updateMenuData',
        data = menuData
    })
end

-- ================================================================
-- SETTINGS MANAGEMENT
-- ================================================================

---Update a setting
---@param category string Setting category
---@param key string Setting key
---@param value any Setting value
function MenuUI.UpdateSetting(category, key, value)
    if not MenuUI.Settings[category] then return end
    
    local oldValue = MenuUI.Settings[category][key]
    MenuUI.Settings[category][key] = value
    MenuUI.State.hasUnsavedChanges = true
    
    -- Apply setting immediately
    MenuUI.ApplySetting(category, key, value)
    
    HUD.Debug(string.format("Setting updated: %s.%s = %s (was: %s)", 
              category, key, tostring(value), tostring(oldValue)), "MENU_UI", "INFO")
end

---Preview a setting (temporary application)
---@param category string Setting category
---@param key string Setting key  
---@param value any Setting value
function MenuUI.PreviewSetting(category, key, value)
    if not MenuUI.State.previewMode then
        MenuUI.BackupSettings()
        MenuUI.State.previewMode = true
    end
    
    -- Apply preview
    MenuUI.ApplySetting(category, key, value)
    
    HUD.Debug(string.format("Setting previewed: %s.%s = %s", 
              category, key, tostring(value)), "MENU_UI", "INFO")
end

---Apply a setting to the system
---@param category string Setting category
---@param key string Setting key
---@param value any Setting value
function MenuUI.ApplySetting(category, key, value)
    -- Theme settings
    if category == 'theme' and key == 'current' then
        if UIManager and UIManager.SetTheme then
            UIManager.SetTheme(value)
        end
    
    -- UI settings
    elseif category == 'ui' then
        if key == 'scaling' and UIManager and UIManager.SetUIScale then
            UIManager.SetUIScale(value)
        elseif key == 'opacity' and UIManager and UIManager.SetUIOpacity then
            UIManager.SetUIOpacity(value)
        elseif key == 'animations' and UIManager and UIManager.SetAnimations then
            UIManager.SetAnimations(value)
        elseif key == 'glowEffects' and UIManager and UIManager.SetGlowEffects then
            UIManager.SetGlowEffects(value)
        elseif key == 'cinematicMode' and UIManager and UIManager.SetCinematicMode then
            UIManager.SetCinematicMode(value)
        end
    
    -- Display settings
    elseif category == 'display' then
        if key == 'format24h' and Time and Time.SetFormat then
            Time.SetFormat(value)
        elseif key == 'showCoordinates' and Location and Location.UpdateSettings then
            Location.UpdateSettings({ showCoordinates = value })
        elseif key == 'showPostal' and Location and Location.UpdateSettings then
            Location.UpdateSettings({ showPostal = value })
        end
    
    -- Audio settings
    elseif category == 'audio' then
        -- Apply audio settings to relevant systems
        if Config.GPSHUD and Config.GPSHUD.audio then
            Config.GPSHUD.audio.enabled = MenuUI.Settings.audio.enabled
            Config.GPSHUD.audio.volume = MenuUI.Settings.audio.volume
            Config.GPSHUD.audio.soundEffects = MenuUI.Settings.audio.soundEffects
        end
    
    -- Performance settings
    elseif category == 'performance' then
        -- Apply performance settings
        if key == 'updateInterval' then
            -- Update intervals for various modules
            if Health then Health.UpdateInterval = value end
            if Location then Location.UpdateInterval = value * 7.5 end -- 1500ms default
            if Vehicle then Vehicle.UpdateInterval = value end
        end
    end
end

---Save all settings
function MenuUI.SaveSettings()
    -- Save to server
    QBCore.Functions.TriggerCallback('hud:server:saveSettings', function(result)
        if result.success then
            MenuUI.State.hasUnsavedChanges = false
            MenuUI.State.lastSaveTime = GetGameTimer()
            MenuUI.Performance.saveCount = MenuUI.Performance.saveCount + 1
            
            QBCore.Functions.Notify('Settings saved successfully', 'success')
            HUD.Debug("Settings saved to server", "MENU_UI", "INFO")
        else
            QBCore.Functions.Notify('Failed to save settings: ' .. (result.error or 'Unknown error'), 'error')
            HUD.Debug("Failed to save settings: " .. (result.error or 'Unknown error'), "MENU_UI", "ERROR")
        end
    end, MenuUI.Settings)
    
    -- Also save to NUI localStorage
    SendNUIMessage({
        action = 'saveToLocalStorage',
        settings = MenuUI.Settings
    })
end

---Load settings from server
function MenuUI.LoadSettings()
    QBCore.Functions.TriggerCallback('hud:server:loadSettings', function(result)
        if result.success and result.settings then
            MenuUI.Settings = result.settings
            
            -- Apply all loaded settings
            MenuUI.ApplyAllSettings()
            
            HUD.Debug("Settings loaded from server", "MENU_UI", "INFO")
        else
            HUD.Debug("Using default settings", "MENU_UI", "INFO")
        end
    end)
end

---Apply all settings to the system
function MenuUI.ApplyAllSettings()
    -- Apply theme
    if MenuUI.Settings.theme.current and UIManager and UIManager.SetTheme then
        UIManager.SetTheme(MenuUI.Settings.theme.current)
    end
    
    -- Apply UI settings
    local ui = MenuUI.Settings.ui
    if UIManager then
        if UIManager.SetUIScale then UIManager.SetUIScale(ui.scaling) end
        if UIManager.SetUIOpacity then UIManager.SetUIOpacity(ui.opacity) end
        if UIManager.SetAnimations then UIManager.SetAnimations(ui.animations) end
        if UIManager.SetGlowEffects then UIManager.SetGlowEffects(ui.glowEffects) end
        if UIManager.SetCinematicMode then UIManager.SetCinematicMode(ui.cinematicMode) end
    end
    
    -- Apply module settings
    for moduleName, moduleSettings in pairs(MenuUI.Settings.modules) do
        if UIManager and UIManager.ToggleModule then
            UIManager.ToggleModule(moduleName, moduleSettings.enabled)
        end
    end
    
    -- Apply display settings
    local display = MenuUI.Settings.display
    if Time and Time.SetFormat then
        Time.SetFormat(display.format24h)
    end
    
    if Location and Location.UpdateSettings then
        Location.UpdateSettings({
            showCoordinates = display.showCoordinates,
            showPostal = display.showPostal
        })
    end
end

---Reset settings to defaults
function MenuUI.ResetSettings()
    -- Confirm reset
    MenuUI.ShowConfirmDialog('Reset all settings to default?', function(confirmed)
        if confirmed then
            -- Reset to default settings
            MenuUI.Settings = MenuUI.GetDefaultSettings()
            
            -- Apply default settings
            MenuUI.ApplyAllSettings()
            
            -- Save defaults
            MenuUI.SaveSettings()
            
            -- Update menu
            MenuUI.SendMenuData()
            
            QBCore.Functions.Notify('Settings reset to default', 'success')
            HUD.Debug("Settings reset to defaults", "MENU_UI", "INFO")
        end
    end)
end

---Get default settings
---@return table defaultSettings
function MenuUI.GetDefaultSettings()
    return {
        theme = {
            current = 'neon-magenta',
            available = {'neon-magenta', 'neon-cyan', 'synthwave', 'classic'}
        },
        ui = {
            scaling = 1.0,
            opacity = 0.9,
            animations = true,
            glowEffects = true,
            cinematicMode = false,
            lowEndMode = false
        },
        modules = {
            gps_hud = { enabled = true, position = 'bottom-left' },
            time = { enabled = true, position = 'top-right' },
            location = { enabled = true, position = 'top-center' },
            vehicle = { enabled = true, position = 'bottom-right' },
            health = { enabled = false, position = 'bottom-left' },
            status = { enabled = false, position = 'bottom-center' }
        },
        display = {
            showWhenFull = false,
            showPercentages = false,
            compactMode = false,
            showCoordinates = false,
            showPostal = false,
            format24h = true
        },
        performance = {
            updateInterval = 200,
            enableCaching = true,
            batchUpdates = true,
            enableProfiling = false
        },
        audio = {
            enabled = true,
            volume = 0.3,
            soundEffects = true,
            voiceSound = true,
            lowHealthSound = true,
            stressSound = true
        },
        keybinds = {
            openMenu = 'I',
            toggleHUD = 'F2',
            toggleCinematic = 'F1',
            cycleVoice = 'F3',
            toggleMap = 'M'
        }
    }
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Backup current settings
function MenuUI.BackupSettings()
    MenuUI.State.settingsBackup = json.decode(json.encode(MenuUI.Settings))
end

---Restore settings from backup
function MenuUI.RestoreSettings()
    if MenuUI.State.settingsBackup then
        MenuUI.Settings = MenuUI.State.settingsBackup
        MenuUI.ApplyAllSettings()
    end
end

---Get module status information
---@return table moduleStatus
function MenuUI.GetModuleStatus()
    local status = {}
    
    local modules = {'Health', 'Status', 'Time', 'Location', 'Vehicle', 'UIManager', 'GPSHUD', 'ExportAPI'}
    
    for _, moduleName in ipairs(modules) do
        local module = _G[moduleName]
        status[moduleName] = {
            loaded = module ~= nil,
            initialized = module and module.Initialized or false,
            visible = module and module.IsVisible and module.IsVisible() or false
        }
    end
    
    return status
end

---Get performance statistics
---@return table performance
function MenuUI.GetPerformanceStats()
    local stats = {
        menu = MenuUI.Performance,
        modules = {}
    }
    
    -- Get stats from all modules
    local modules = {'Health', 'Status', 'Time', 'Location', 'Vehicle', 'UIManager', 'GPSHUD', 'ExportAPI'}
    
    for _, moduleName in ipairs(modules) do
        local module = _G[moduleName]
        if module and module.GetPerformanceStats then
            stats.modules[moduleName] = module.GetPerformanceStats()
        end
    end
    
    return stats
end

---Handle command input
---@param args table Command arguments
function MenuUI.HandleCommand(args)
    local action = args[1]:lower()
    
    if action == 'open' then
        MenuUI.OpenMenu()
    elseif action == 'close' then
        MenuUI.CloseMenu()
    elseif action == 'toggle' then
        MenuUI.ToggleMenu()
    elseif action == 'reset' then
        MenuUI.ResetSettings()
    elseif action == 'save' then
        MenuUI.SaveSettings()
    elseif action == 'theme' and args[2] then
        MenuUI.UpdateSetting('theme', 'current', args[2])
        MenuUI.SaveSettings()
    else
        QBCore.Functions.Notify('Available commands: open, close, toggle, reset, save, theme <name>', 'primary')
    end
end

---Toggle module
---@param moduleName string Module name
---@param enabled boolean Module enabled state
function MenuUI.ToggleModule(moduleName, enabled)
    MenuUI.UpdateSetting('modules', moduleName, { enabled = enabled })
    
    if UIManager and UIManager.ToggleModule then
        UIManager.ToggleModule(moduleName, enabled)
    end
end

---Reset module to defaults
---@param moduleName string Module name
function MenuUI.ResetModule(moduleName)
    local defaultModules = MenuUI.GetDefaultSettings().modules
    if defaultModules[moduleName] then
        MenuUI.Settings.modules[moduleName] = defaultModules[moduleName]
        MenuUI.State.hasUnsavedChanges = true
        MenuUI.SendMenuData()
    end
end

---Export settings to clipboard
function MenuUI.ExportSettings()
    local settingsJson = json.encode(MenuUI.Settings)
    
    SendNUIMessage({
        action = 'copyToClipboard',
        text = settingsJson
    })
    
    QBCore.Functions.Notify('Settings exported to clipboard', 'success')
    HUD.Debug("Settings exported", "MENU_UI", "INFO")
end

---Import settings from JSON
---@param settingsJson string Settings JSON string
function MenuUI.ImportSettings(settingsJson)
    local success, importedSettings = pcall(json.decode, settingsJson)
    
    if success and type(importedSettings) == "table" then
        MenuUI.Settings = importedSettings
        MenuUI.ApplyAllSettings()
        MenuUI.SendMenuData()
        MenuUI.State.hasUnsavedChanges = true
        
        QBCore.Functions.Notify('Settings imported successfully', 'success')
        HUD.Debug("Settings imported", "MENU_UI", "INFO")
    else
        QBCore.Functions.Notify('Invalid settings format', 'error')
        HUD.Debug("Failed to import settings - invalid format", "MENU_UI", "ERROR")
    end
end

---Show confirmation dialog
---@param message string Dialog message
---@param callback function Callback function
function MenuUI.ShowConfirmDialog(message, callback)
    SendNUIMessage({
        action = 'showConfirmDialog',
        message = message,
        callback = 'confirmCallback'
    })
    
    -- Store callback for NUI response
    MenuUI.pendingCallback = callback
end

---Prompt to save changes
function MenuUI.PromptSaveChanges()
    MenuUI.ShowConfirmDialog('You have unsaved changes. Save before closing?', function(confirmed)
        if confirmed then
            MenuUI.SaveSettings()
        else
            MenuUI.RestoreSettings()
        end
    end)
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle menu open event from NUI
function MenuUI.OnMenuOpen()
    MenuUI.Performance.totalMenuTime = GetGameTimer()
    HUD.Debug("Menu opened via NUI", "MENU_UI", "INFO")
end

---Handle menu close event from NUI
function MenuUI.OnMenuClose()
    local sessionTime = GetGameTimer() - MenuUI.Performance.totalMenuTime
    MenuUI.Performance.totalMenuTime = MenuUI.Performance.totalMenuTime + sessionTime
    
    MenuUI.CloseMenu()
    HUD.Debug(string.format("Menu closed via NUI (session: %dms)", sessionTime), "MENU_UI", "INFO")
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function MenuUI.Cleanup()
    if MenuUI.MenuOpen then
        SetNuiFocus(false, false)
        MenuUI.MenuOpen = false
    end
    
    MenuUI.Initialized = false
    
    HUD.Debug("Menu UI cleaned up", "MENU_UI", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        MenuUI.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make MenuUI module available globally
_G.MenuUI = MenuUI

HUD.Debug("Menu UI module loaded", "MENU_UI", "INFO")
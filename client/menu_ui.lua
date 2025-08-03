-- ================================================================
-- QBCore HUD - Menu UI System
-- Version: 3.0.0
-- Description: Settings menu, /hud command, and user preferences
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local MenuUI = {}
local isInitialized = false
local menuOpen = false
local currentSettings = {}

-- ================================================================
-- INITIALIZATION
-- ================================================================

---Initialize the Menu UI module
function MenuUI.Init()
    if isInitialized then
        HUD.Debug("^3Menu UI already initialized^7", "MENU_UI")
        return true
    end
    
    HUD.Debug("^2Initializing Menu UI^7", "MENU_UI")
    
    -- Register events
    MenuUI.RegisterEvents()
    
    -- Register commands
    MenuUI.RegisterCommands()
    
    -- Load saved settings
    MenuUI.LoadSettings()
    
    isInitialized = true
    HUD.Debug("^2Menu UI initialized successfully^7", "MENU_UI")
    
    return true
end

---Register menu-related events
function MenuUI.RegisterEvents()
    -- Menu open event from server
    RegisterNetEvent('hud:client:OpenMenu', function()
        MenuUI.OpenMenu()
    end)
    
    -- Settings save event
    RegisterNetEvent('hud:client:SaveSettings', function()
        MenuUI.SaveSettings()
    end)
    
    -- Settings reset event
    RegisterNetEvent('hud:client:ResetSettings', function()
        MenuUI.ResetSettings()
    end)
    
    -- NUI Callbacks for menu interaction
    RegisterNUICallback('closeMenu', function(data, cb)
        MenuUI.CloseMenu()
        cb('ok')
    end)
    
    RegisterNUICallback('updateSetting', function(data, cb)
        MenuUI.UpdateSetting(data.setting, data.value)
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
    
    HUD.Debug("^2Menu UI events registered^7", "MENU_UI")
end

---Register commands
function MenuUI.RegisterCommands()
    -- Main HUD command
    RegisterCommand('hud', function(source, args, rawCommand)
        if args[1] then
            local action = args[1]:lower()
            
            if action == 'toggle' then
                -- Toggle HUD visibility
                if UIManager and UIManager.IsHudVisible and UIManager.SetHudVisibility then
                    local currentState = UIManager.IsHudVisible()
                    UIManager.SetHudVisibility(not currentState)
                    QBCore.Functions.Notify(string.format('HUD %s', currentState and 'hidden' or 'shown'), 'primary')
                end
            elseif action == 'reset' then
                -- Reset HUD settings
                MenuUI.ResetSettings()
            elseif action == 'save' then
                -- Save current settings
                MenuUI.SaveSettings()
            elseif action == 'theme' then
                -- Change theme
                local theme = args[2]
                if theme and UIManager and UIManager.SetTheme then
                    if UIManager.SetTheme(theme) then
                        QBCore.Functions.Notify(string.format('Theme changed to: %s', theme), 'success')
                    else
                        QBCore.Functions.Notify('Invalid theme name', 'error')
                    end
                else
                    QBCore.Functions.Notify('Usage: /hud theme <theme_name>', 'error')
                end
            elseif action == 'module' then
                -- Toggle specific module
                local moduleName = args[2]
                local visible = args[3]
                
                if moduleName then
                    local isVisible = visible == 'true' or visible == '1' or visible == 'on'
                    if visible == 'false' or visible == '0' or visible == 'off' then
                        isVisible = false
                    elseif visible == nil then
                        -- Toggle if no state specified
                        if UIManager and UIManager.GetModuleVisibility then
                            isVisible = not UIManager.GetModuleVisibility(moduleName)
                        end
                    end
                    
                    if UIManager and UIManager.ToggleModule then
                        UIManager.ToggleModule(moduleName, isVisible)
                        QBCore.Functions.Notify(string.format('Module %s: %s', moduleName, isVisible and 'shown' or 'hidden'), 'primary')
                    end
                else
                    QBCore.Functions.Notify('Usage: /hud module <module_name> [true/false]', 'error')
                end
            elseif action == 'help' then
                -- Show help
                MenuUI.ShowHelp()
            else
                QBCore.Functions.Notify('Unknown command. Use /hud help for available commands', 'error')
            end
        else
            -- Open settings menu
            MenuUI.OpenMenu()
        end
    end, false)
    
    -- Quick toggle commands
    RegisterCommand('togglehud', function()
        if UIManager and UIManager.IsHudVisible and UIManager.SetHudVisibility then
            local currentState = UIManager.IsHudVisible()
            UIManager.SetHudVisibility(not currentState)
        end
    end, false)
    
    -- Cinematic mode toggle
    RegisterCommand('cinematic', function()
        if UIManager and UIManager.IsCinematicMode and UIManager.SetCinematicMode then
            local currentState = UIManager.IsCinematicMode()
            UIManager.SetCinematicMode(not currentState)
            QBCore.Functions.Notify(string.format('Cinematic mode %s', currentState and 'disabled' or 'enabled'), 'primary')
        end
    end, false)
    
    HUD.Debug("^2Menu UI commands registered^7", "MENU_UI")
end

-- ================================================================
-- MENU MANAGEMENT
-- ================================================================

---Open the HUD settings menu
function MenuUI.OpenMenu()
    if menuOpen then
        HUD.Debug("^3Menu already open^7", "MENU_UI")
        return
    end
    
    -- Get current settings from server
    QBCore.Functions.TriggerCallback('hud:server:getMenu', function(menuData)
        if not menuData then
            QBCore.Functions.Notify('Failed to load menu data', 'error')
            return
        end
        
        -- Prepare menu data for NUI
        local nui_data = MenuUI.PrepareMenuData(menuData)
        
        -- Show NUI menu
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'showSettings',
            data = nui_data
        })
        
        menuOpen = true
        HUD.Debug("^2HUD menu opened^7", "MENU_UI")
    end)
end

---Close the HUD settings menu
function MenuUI.CloseMenu()
    if not menuOpen then return end
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'hideSettings'
    })
    
    menuOpen = false
    HUD.Debug("^2HUD menu closed^7", "MENU_UI")
end

---Prepare menu data for NUI
---@param menuData table
---@return table
function MenuUI.PrepareMenuData(menuData)
    local data = {
        modules = {},
        themes = menuData.themes or {},
        currentTheme = menuData.currentTheme or 'neon-magenta',
        settings = {
            hudVisible = true,
            cinematicMode = false,
            scaling = 1.0,
            opacity = 0.9
        }
    }
    
    -- Get current UI settings
    if UIManager then
        if UIManager.IsHudVisible then
            data.settings.hudVisible = UIManager.IsHudVisible()
        end
        if UIManager.IsCinematicMode then
            data.settings.cinematicMode = UIManager.IsCinematicMode()
        end
        if UIManager.GetCurrentTheme then
            data.currentTheme = UIManager.GetCurrentTheme()
        end
    end
    
    -- Prepare module data
    for moduleName, moduleConfig in pairs(menuData.modules or {}) do
        local moduleVisible = true
        if UIManager and UIManager.GetModuleVisibility then
            moduleVisible = UIManager.GetModuleVisibility(moduleName)
        end
        
        data.modules[moduleName] = {
            name = moduleName,
            enabled = moduleConfig.enabled or false,
            visible = moduleVisible,
            position = moduleConfig.position or 'bottom-left',
            components = moduleConfig.components or {}
        }
    end
    
    return data
end

-- ================================================================
-- SETTINGS MANAGEMENT
-- ================================================================

---Update a specific setting
---@param setting string
---@param value any
function MenuUI.UpdateSetting(setting, value)
    if not setting then return end
    
    HUD.Debug(string.format("^2Updating setting: %s = %s^7", setting, tostring(value)), "MENU_UI")
    
    -- Handle different setting types
    if setting == 'theme' then
        if UIManager and UIManager.SetTheme then
            UIManager.SetTheme(value)
        end
    elseif setting == 'hudVisible' then
        if UIManager and UIManager.SetHudVisibility then
            UIManager.SetHudVisibility(value)
        end
    elseif setting == 'cinematicMode' then
        if UIManager and UIManager.SetCinematicMode then
            UIManager.SetCinematicMode(value)
        end
    elseif setting:startswith('module_') then
        -- Module visibility setting
        local moduleName = setting:gsub('module_', '')
        if UIManager and UIManager.ToggleModule then
            UIManager.ToggleModule(moduleName, value)
        end
    elseif setting == 'scaling' then
        if UIManager and UIManager.SetScale then
            UIManager.SetScale(value)
        end
    elseif setting == 'opacity' then
        if UIManager and UIManager.SetOpacity then
            UIManager.SetOpacity(value)
        end
    end
    
    -- Store in current settings
    currentSettings[setting] = value
end

---Load settings from storage
function MenuUI.LoadSettings()
    -- Settings are automatically loaded by individual modules
    -- This function exists for future database integration
    currentSettings = {}
    HUD.Debug("^2Settings loaded^7", "MENU_UI")
end

---Save current settings
function MenuUI.SaveSettings()
    -- Save settings via callback
    QBCore.Functions.TriggerCallback('hud:server:saveSettings', function(success)
        if success then
            QBCore.Functions.Notify('Settings saved successfully', 'success')
            HUD.Debug("^2Settings saved successfully^7", "MENU_UI")
        else
            QBCore.Functions.Notify('Failed to save settings', 'error')
            HUD.Debug("^1Failed to save settings^7", "MENU_UI")
        end
    end, currentSettings)
end

---Reset settings to default
function MenuUI.ResetSettings()
    HUD.Debug("^3Resetting HUD settings to default^7", "MENU_UI")
    
    -- Reset theme
    if UIManager and UIManager.SetTheme then
        UIManager.SetTheme(Config.Theme.current)
    end
    
    -- Reset visibility
    if UIManager and UIManager.SetHudVisibility then
        UIManager.SetHudVisibility(true)
    end
    
    -- Reset cinematic mode
    if UIManager and UIManager.SetCinematicMode then
        UIManager.SetCinematicMode(false)
    end
    
    -- Reset all modules to enabled state
    for moduleName, moduleConfig in pairs(Config.Modules) do
        if UIManager and UIManager.ToggleModule then
            UIManager.ToggleModule(moduleName, moduleConfig.enabled)
        end
    end
    
    -- Clear current settings
    currentSettings = {}
    
    QBCore.Functions.Notify('HUD settings reset to default', 'success')
    
    -- Update NUI if menu is open
    if menuOpen then
        MenuUI.CloseMenu()
        Wait(100)
        MenuUI.OpenMenu()
    end
end

-- ================================================================
-- HELP SYSTEM
-- ================================================================

---Show help information
function MenuUI.ShowHelp()
    local helpText = {
        "^3=== HUD Commands Help ===^7",
        "^2/hud^7 - Open settings menu",
        "^2/hud toggle^7 - Toggle HUD visibility",
        "^2/hud reset^7 - Reset to default settings",
        "^2/hud save^7 - Save current settings",
        "^2/hud theme <name>^7 - Change theme",
        "^2/hud module <name> [on/off]^7 - Toggle module",
        "^2/togglehud^7 - Quick HUD toggle",
        "^2/cinematic^7 - Toggle cinematic mode",
        "",
        "^3Available Themes:^7"
    }
    
    -- Add available themes
    if UIManager and UIManager.GetAvailableThemes then
        local themes = UIManager.GetAvailableThemes()
        for _, theme in ipairs(themes) do
            table.insert(helpText, string.format("  ^2%s^7", theme))
        end
    else
        for _, theme in ipairs(Config.Theme.available) do
            table.insert(helpText, string.format("  ^2%s^7", theme))
        end
    end
    
    table.insert(helpText, "")
    table.insert(helpText, "^3Available Modules:^7")
    
    -- Add available modules
    for moduleName, moduleConfig in pairs(Config.Modules) do
        local status = moduleConfig.enabled and "^2enabled^7" or "^1disabled^7"
        table.insert(helpText, string.format("  ^2%s^7 (%s)", moduleName, status))
    end
    
    -- Print help to console
    for _, line in ipairs(helpText) do
        print(line)
    end
    
    QBCore.Functions.Notify('Check console for help information', 'primary')
end

-- ================================================================
-- KEYBIND INTEGRATION
-- ================================================================

---Register keybinds for HUD functions
function MenuUI.RegisterKeybinds()
    -- Register keybind for opening menu
    if Config.Modules.menu_ui.openKey then
        RegisterKeyMapping('openhudmenu', 'Open HUD Menu', 'keyboard', Config.Modules.menu_ui.openKey)
        RegisterCommand('openhudmenu', function()
            MenuUI.OpenMenu()
        end, false)
    end
    
    -- Register keybind for toggling HUD
    RegisterKeyMapping('togglehudvisibility', 'Toggle HUD Visibility', 'keyboard', 'F1')
    RegisterCommand('togglehudvisibility', function()
        if UIManager and UIManager.IsHudVisible and UIManager.SetHudVisibility then
            local currentState = UIManager.IsHudVisible()
            UIManager.SetHudVisibility(not currentState)
        end
    end, false)
    
    HUD.Debug("^2Menu UI keybinds registered^7", "MENU_UI")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get current menu state
---@return boolean
function MenuUI.IsMenuOpen()
    return menuOpen
end

---Get current settings
---@return table
function MenuUI.GetCurrentSettings()
    return currentSettings
end

---Check if player has permission for advanced settings
---@return boolean
function MenuUI.HasAdvancedPermissions()
    -- Basic permission check - can be extended
    return true
end

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('menu_ui', MenuUI)
end

-- Export MenuUI functions for external use
_G.MenuUI = MenuUI

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Menu UI shutting down^7", "MENU_UI")
        
        -- Close menu if open
        if menuOpen then
            MenuUI.CloseMenu()
        end
        
        isInitialized = false
    end
end)

-- Auto-register keybinds when player is loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Wait for other systems to load
    MenuUI.RegisterKeybinds()
end)

-- Handle ESC key to close menu
CreateThread(function()
    while true do
        if menuOpen then
            DisableControlAction(0, 199, true) -- Disable pause menu
            DisableControlAction(0, 200, true) -- Disable pause menu alternate
            
            if IsDisabledControlJustPressed(0, 200) then -- ESC key
                MenuUI.CloseMenu()
            end
        end
        Wait(0)
    end
end)
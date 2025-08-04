-- ================================================================
-- QBCore HUD - Master Module Loader & Coordinator
-- Version: 3.0.0
-- Description: Central initialization system for all HUD modules
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Global HUD System
HUD = HUD or {}
HUD.Version = "3.0.0"
HUD.Modules = {}
HUD.Initialized = false
HUD.StartTime = GetGameTimer()

-- Debug System
HUD.Debug = function(message, module, level)
    if not Config.Debug then return end
    
    local prefix = "^2[HUD]^7"
    local moduleStr = module and string.format("^3[%s]^7", module) or ""
    local levelColor = "^7" -- Default white
    
    if level == "ERROR" then levelColor = "^1"
    elseif level == "WARN" then levelColor = "^3"
    elseif level == "INFO" then levelColor = "^5"
    end
    
    print(string.format("%s %s %s%s^7", prefix, moduleStr, levelColor, message))
end

-- Performance Monitoring
HUD.Performance = {
    moduleLoadTimes = {},
    totalLoadTime = 0,
    memoryUsage = 0
}

-- ================================================================
-- CORE INITIALIZATION SYSTEM
-- ================================================================

---Initialize the complete HUD system
function HUD.Initialize()
    if HUD.Initialized then
        HUD.Debug("HUD already initialized", "CORE", "WARN")
        return false
    end
    
    HUD.Debug("Starting HUD System v" .. HUD.Version, "CORE", "INFO")
    
    -- Phase 1: Core Dependencies Check
    if not HUD.CheckDependencies() then
        HUD.Debug("Dependency check failed!", "CORE", "ERROR")
        return false
    end
    
    -- Phase 2: Load Configuration
    if not HUD.LoadConfiguration() then
        HUD.Debug("Configuration loading failed!", "CORE", "ERROR")
        return false
    end
    
    -- Phase 3: Initialize Modules
    if not HUD.InitializeModules() then
        HUD.Debug("Module initialization failed!", "CORE", "ERROR")
        return false
    end
    
    -- Phase 4: Setup Global Events
    HUD.RegisterGlobalEvents()
    
    -- Phase 5: Final Setup
    HUD.Initialized = true
    HUD.Performance.totalLoadTime = GetGameTimer() - HUD.StartTime
    
    HUD.Debug(string.format("HUD System initialized successfully in %dms", HUD.Performance.totalLoadTime), "CORE", "INFO")
    
    -- Send initialization complete event
    TriggerEvent('hud:client:initialized')
    
    return true
end

-- ================================================================
-- DEPENDENCY MANAGEMENT
-- ================================================================

---Check all required dependencies
---@return boolean
function HUD.CheckDependencies()
    local dependencies = {
        { name = 'qb-core', required = true },
        { name = 'pma-voice', required = true },
        { name = 'LegacyFuel', required = false },
        { name = 'interact-sound', required = false },
        { name = 'qb-menu', required = false },
        { name = 'weathersync', required = false }
    }
    
    local missing = {}
    local optional = {}
    
    for _, dep in ipairs(dependencies) do
        local state = GetResourceState(dep.name)
        
        if state ~= 'started' then
            if dep.required then
                table.insert(missing, dep.name)
                HUD.Debug(string.format("Missing required dependency: %s", dep.name), "CORE", "ERROR")
            else
                table.insert(optional, dep.name)
                HUD.Debug(string.format("Optional dependency not available: %s", dep.name), "CORE", "WARN")
            end
        else
            HUD.Debug(string.format("Dependency OK: %s", dep.name), "CORE", "INFO")
        end
    end
    
    if #missing > 0 then
        HUD.Debug("Critical dependencies missing: " .. table.concat(missing, ", "), "CORE", "ERROR")
        return false
    end
    
    if #optional > 0 then
        HUD.Debug("Optional dependencies missing: " .. table.concat(optional, ", "), "CORE", "WARN")
    end
    
    return true
end

-- ================================================================
-- CONFIGURATION LOADING
-- ================================================================

---Load and validate configuration
---@return boolean
function HUD.LoadConfiguration()
    HUD.Debug("Loading configuration...", "CORE", "INFO")
    
    -- Validate Config exists
    if not Config then
        HUD.Debug("Config table not found!", "CORE", "ERROR")
        return false
    end
    
    -- Validate essential config sections
    local requiredSections = { 'Modules', 'GPSHUD', 'Theme' }
    for _, section in ipairs(requiredSections) do
        if not Config[section] then
            HUD.Debug(string.format("Missing config section: %s", section), "CORE", "ERROR")
            return false
        end
    end
    
    -- Set debug mode
    if Config.Debug then
        HUD.Debug("Debug mode enabled", "CORE", "INFO")
    end
    
    -- Validate theme configuration
    if not Config.Theme.current or not Config.Theme.colors then
        HUD.Debug("Invalid theme configuration", "CORE", "WARN")
        -- Set defaults
        Config.Theme.current = 'neon-magenta'
        Config.Theme.colors = {
            ['neon-magenta'] = {
                primary = '#B026FF',
                secondary = '#0ff',
                accent = '#FFD700'
            }
        }
    end
    
    HUD.Debug("Configuration loaded successfully", "CORE", "INFO")
    return true
end

-- ================================================================
-- MODULE INITIALIZATION
-- ================================================================

---Initialize all enabled modules in correct order
---@return boolean
function HUD.InitializeModules()
    HUD.Debug("Initializing modules...", "CORE", "INFO")
    
    -- Module loading order (priority-based)
    local loadOrder = {
        { name = 'ui_manager', priority = 1 },
        { name = 'export_api', priority = 2 },
        { name = 'gps_hud', priority = 3 },
        { name = 'health', priority = 4 },
        { name = 'status', priority = 5 },
        { name = 'time', priority = 6 },
        { name = 'location', priority = 7 },
        { name = 'vehicle', priority = 8 },
        { name = 'menu_ui', priority = 9 }
    }
    
    -- Sort by priority
    table.sort(loadOrder, function(a, b) return a.priority < b.priority end)
    
    local loadedCount = 0
    local failedModules = {}
    
    for _, module in ipairs(loadOrder) do
        local moduleName = module.name
        local moduleConfig = Config.Modules[moduleName]
        
        if moduleConfig and moduleConfig.enabled then
            local startTime = GetGameTimer()
            
            HUD.Debug(string.format("Loading module: %s", moduleName), "CORE", "INFO")
            
            -- Attempt to initialize module
            local success = HUD.InitializeModule(moduleName, moduleConfig)
            
            local loadTime = GetGameTimer() - startTime
            HUD.Performance.moduleLoadTimes[moduleName] = loadTime
            
            if success then
                loadedCount = loadedCount + 1
                HUD.Debug(string.format("Module %s loaded in %dms", moduleName, loadTime), "CORE", "INFO")
            else
                table.insert(failedModules, moduleName)
                HUD.Debug(string.format("Module %s failed to load", moduleName), "CORE", "ERROR")
            end
        else
            HUD.Debug(string.format("Module %s disabled in config", moduleName), "CORE", "INFO")
        end
    end
    
    -- Report results
    HUD.Debug(string.format("Modules loaded: %d/%d", loadedCount, #loadOrder), "CORE", "INFO")
    
    if #failedModules > 0 then
        HUD.Debug("Failed modules: " .. table.concat(failedModules, ", "), "CORE", "WARN")
    end
    
    return loadedCount > 0 -- At least one module must load
end

---Initialize a specific module
---@param moduleName string
---@param config table
---@return boolean
function HUD.InitializeModule(moduleName, config)
    -- Check if module's init function exists
    local moduleTable = _G[moduleName:upper()] or _G[moduleName:gsub("^%l", string.upper)]
    
    if not moduleTable then
        -- Try alternative naming conventions
        local alternatives = {
            moduleName:upper(),
            moduleName:gsub("_", ""):upper(),
            moduleName:gsub("_(.)", function(c) return c:upper() end)
        }
        
        for _, altName in ipairs(alternatives) do
            moduleTable = _G[altName]
            if moduleTable then break end
        end
    end
    
    if moduleTable and moduleTable.Init then
        local success, error = pcall(moduleTable.Init)
        if success then
            HUD.Modules[moduleName] = {
                instance = moduleTable,
                config = config,
                initialized = true,
                lastUpdate = 0
            }
            return true
        else
            HUD.Debug(string.format("Module %s init error: %s", moduleName, error), "CORE", "ERROR")
            return false
        end
    end
    
    HUD.Debug(string.format("Module %s has no Init function", moduleName), "CORE", "WARN")
    return false
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register global HUD events
function HUD.RegisterGlobalEvents()
    HUD.Debug("Registering global events...", "CORE", "INFO")
    
    -- Player loaded event
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        HUD.Debug("Player loaded - refreshing HUD", "CORE", "INFO")
        HUD.RefreshAllModules()
    end)
    
    -- Player unloaded event
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        HUD.Debug("Player unloaded - hiding HUD", "CORE", "INFO")
        HUD.SetVisibility(false)
    end)
    
    -- HUD refresh event
    RegisterNetEvent('hud:client:refresh', function()
        HUD.RefreshAllModules()
    end)
    
    -- Module control events
    RegisterNetEvent('hud:client:toggleModule', function(moduleName, visible)
        HUD.SetModuleVisibility(moduleName, visible)
    end)
    
    -- Theme change event
    RegisterNetEvent('hud:client:setTheme', function(theme)
        HUD.SetTheme(theme)
    end)
    
    HUD.Debug("Global events registered", "CORE", "INFO")
end

-- ================================================================
-- MODULE MANAGEMENT
-- ================================================================

---Refresh all active modules
function HUD.RefreshAllModules()
    for moduleName, moduleData in pairs(HUD.Modules) do
        if moduleData.instance and moduleData.instance.ForceUpdate then
            moduleData.instance.ForceUpdate()
        end
    end
end

---Set visibility for a specific module
---@param moduleName string
---@param visible boolean
function HUD.SetModuleVisibility(moduleName, visible)
    local moduleData = HUD.Modules[moduleName]
    if moduleData and moduleData.instance and moduleData.instance.SetVisible then
        moduleData.instance.SetVisible(visible)
        HUD.Debug(string.format("Module %s visibility: %s", moduleName, visible and "visible" or "hidden"), "CORE", "INFO")
    end
end

---Set HUD visibility
---@param visible boolean
function HUD.SetVisibility(visible)
    for moduleName, _ in pairs(HUD.Modules) do
        HUD.SetModuleVisibility(moduleName, visible)
    end
end

---Set HUD theme
---@param theme string
function HUD.SetTheme(theme)
    for moduleName, moduleData in pairs(HUD.Modules) do
        if moduleData.instance and moduleData.instance.SetTheme then
            moduleData.instance.SetTheme(theme)
        end
    end
    
    -- Update NUI
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
end

-- ================================================================
-- PERFORMANCE MONITORING
-- ================================================================

---Get performance statistics
---@return table
function HUD.GetPerformanceData()
    return {
        totalLoadTime = HUD.Performance.totalLoadTime,
        moduleLoadTimes = HUD.Performance.moduleLoadTimes,
        modulesLoaded = table.length(HUD.Modules),
        memoryUsage = collectgarbage("count") -- KB
    }
end

-- ================================================================
-- STARTUP SEQUENCE
-- ================================================================

-- Initialize on next tick (after all scripts loaded)
CreateThread(function()
    Wait(1000) -- Wait for all dependencies to load
    
    HUD.Debug("Starting HUD initialization sequence...", "CORE", "INFO")
    
    local success = HUD.Initialize()
    if not success then
        HUD.Debug("HUD initialization failed!", "CORE", "ERROR")
    end
end)
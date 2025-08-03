-- ================================================================
-- QBCore HUD - Enhanced Modular System Initializer
-- Version: 3.0.0
-- Description: Master module loader and system coordinator with GPS HUD focus
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Global HUD System
HUD = HUD or {}
HUD.Modules = {}
HUD.LoadedModules = {}
HUD.Debug = Config.Debug or false
HUD.Version = "3.0.0"

-- System Status
HUD.Status = {
    initialized = false,
    playerLoaded = false,
    totalModules = 0,
    loadedModules = 0,
    failedModules = 0
}

-- ================================================================
-- DEBUG SYSTEM
-- ================================================================

---Enhanced debug system with module-specific logging
---@param message string Debug message to print
---@param module string Module name (optional)
---@param level string Debug level: 'INFO', 'WARN', 'ERROR' (optional)
function HUD.Debug(message, module, level)
    if not Config.Debug then return end
    
    local prefix = module and string.format("[HUD:%s]", string.upper(module)) or "[HUD:CORE]"
    local timestamp = os.date("%H:%M:%S")
    local levelColor = "^7" -- Default white
    
    -- Color coding based on level
    if level == "ERROR" then
        levelColor = "^1" -- Red
    elseif level == "WARN" then
        levelColor = "^3" -- Yellow
    elseif level == "INFO" then
        levelColor = "^2" -- Green
    end
    
    print(string.format("^6%s %s%s^7 %s", timestamp, levelColor, prefix, message))
end

-- ================================================================
-- MODULE MANAGEMENT SYSTEM
-- ================================================================

---Register a new module in the HUD system
---@param name string Module name
---@param moduleTable table Module functions and data
---@return boolean success
function HUD.RegisterModule(name, moduleTable)
    if not name or type(moduleTable) ~= "table" then
        HUD.Debug(string.format("Failed to register module: Invalid parameters (name: %s, type: %s)", 
                 tostring(name), type(moduleTable)), "CORE", "ERROR")
        return false
    end
    
    HUD.Modules[name] = moduleTable
    HUD.Status.totalModules = HUD.Status.totalModules + 1
    
    HUD.Debug(string.format("Module '%s' registered successfully", name), "CORE", "INFO")
    return true
end

---Initialize a specific module with error handling
---@param name string Module name to initialize
---@return boolean success
function HUD.InitModule(name)
    local module = HUD.Modules[name]
    if not module then
        HUD.Debug(string.format("Module '%s' not found", name), "CORE", "ERROR")
        HUD.Status.failedModules = HUD.Status.failedModules + 1
        return false
    end
    
    -- Check if module is enabled in config
    local moduleConfig = Config.Modules[name]
    if moduleConfig and moduleConfig.enabled == false then
        HUD.Debug(string.format("Module '%s' disabled in config", name), "CORE", "WARN")
        return false
    end
    
    -- Check if module has Init function
    if not module.Init or type(module.Init) ~= "function" then
        HUD.Debug(string.format("Module '%s' has no Init function", name), "CORE", "ERROR")
        HUD.Status.failedModules = HUD.Status.failedModules + 1
        return false
    end
    
    -- Initialize module with error handling
    local success, error = pcall(module.Init)
    if success then
        HUD.LoadedModules[name] = {
            loaded = true,
            loadTime = GetGameTimer(),
            config = moduleConfig
        }
        HUD.Status.loadedModules = HUD.Status.loadedModules + 1
        HUD.Debug(string.format("Module '%s' initialized successfully", name), string.upper(name), "INFO")
        return true
    else
        HUD.Debug(string.format("Module '%s' initialization failed: %s", name, tostring(error)), "CORE", "ERROR")
        HUD.Status.failedModules = HUD.Status.failedModules + 1
        return false
    end
end

---Check if a module is loaded and running
---@param name string Module name
---@return boolean loaded
function HUD.IsModuleLoaded(name)
    return HUD.LoadedModules[name] and HUD.LoadedModules[name].loaded == true
end

---Get comprehensive module status information
---@param name string Module name (optional, returns all if nil)
---@return table status
function HUD.GetModuleStatus(name)
    if name then
        local moduleInfo = HUD.LoadedModules[name]
        local moduleConfig = Config.Modules[name]
        
        return {
            registered = HUD.Modules[name] ~= nil,
            loaded = moduleInfo and moduleInfo.loaded or false,
            loadTime = moduleInfo and moduleInfo.loadTime or 0,
            enabled = moduleConfig and moduleConfig.enabled or false,
            priority = moduleConfig and moduleConfig.priority or 999,
            essential = moduleConfig and moduleConfig.essential or false
        }
    else
        local status = {}
        for moduleName, _ in pairs(HUD.Modules) do
            status[moduleName] = HUD.GetModuleStatus(moduleName)
        end
        return status
    end
end

-- ================================================================
-- SYSTEM INITIALIZATION
-- ================================================================

---Initialize the entire HUD system
function HUD.Initialize()
    HUD.Debug("Starting Enhanced HUD System initialization...", "CORE", "INFO")
    HUD.Debug(string.format("Version: %s | Debug: %s", HUD.Version, Config.Debug and "ON" or "OFF"), "CORE", "INFO")
    
    -- Initialize modules in priority order
    local initOrder = HUD.GetInitializationOrder()
    
    HUD.Debug(string.format("Initialization order: %s", table.concat(initOrder, " → ")), "CORE", "INFO")
    
    for i, moduleName in ipairs(initOrder) do
        HUD.Debug(string.format("Initializing module %d/%d: %s", i, #initOrder, moduleName), "CORE", "INFO")
        
        local success = HUD.InitModule(moduleName)
        if success then
            -- Small delay between modules to prevent conflicts
            Citizen.Wait(50)
        else
            -- Check if module is essential
            local moduleConfig = Config.Modules[moduleName]
            if moduleConfig and moduleConfig.essential then
                HUD.Debug(string.format("CRITICAL: Essential module '%s' failed to load!", moduleName), "CORE", "ERROR")
            end
        end
    end
    
    HUD.Status.initialized = true
    
    -- Print initialization summary
    HUD.PrintInitializationSummary()
end

---Get module initialization order based on priority
---@return table initOrder
function HUD.GetInitializationOrder()
    local modules = {}
    
    -- Collect all modules with their priorities
    for moduleName, _ in pairs(HUD.Modules) do
        local moduleConfig = Config.Modules[moduleName]
        local priority = moduleConfig and moduleConfig.priority or 999
        local enabled = moduleConfig and moduleConfig.enabled ~= false or true
        
        if enabled then
            table.insert(modules, {
                name = moduleName,
                priority = priority
            })
        end
    end
    
    -- Sort by priority (lower number = higher priority)
    table.sort(modules, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Extract just the names
    local initOrder = {}
    for _, module in ipairs(modules) do
        table.insert(initOrder, module.name)
    end
    
    return initOrder
end

---Print initialization summary
function HUD.PrintInitializationSummary()
    HUD.Debug("=== HUD INITIALIZATION SUMMARY ===", "CORE", "INFO")
    HUD.Debug(string.format("Total Modules: %d", HUD.Status.totalModules), "CORE", "INFO")
    HUD.Debug(string.format("Loaded Successfully: ^2%d^7", HUD.Status.loadedModules), "CORE", "INFO")
    HUD.Debug(string.format("Failed to Load: ^1%d^7", HUD.Status.failedModules), "CORE", "INFO")
    
    -- List loaded modules
    if HUD.Status.loadedModules > 0 then
        HUD.Debug("Loaded Modules:", "CORE", "INFO")
        for moduleName, moduleInfo in pairs(HUD.LoadedModules) do
            if moduleInfo.loaded then
                local loadTime = moduleInfo.loadTime
                HUD.Debug(string.format("  ✅ %s (loaded at %dms)", moduleName, loadTime), "CORE", "INFO")
            end
        end
    end
    
    -- List failed modules
    if HUD.Status.failedModules > 0 then
        HUD.Debug("Failed Modules:", "CORE", "WARN")
        for moduleName, _ in pairs(HUD.Modules) do
            if not HUD.IsModuleLoaded(moduleName) then
                local moduleConfig = Config.Modules[moduleName]
                local enabled = moduleConfig and moduleConfig.enabled ~= false
                if enabled then
                    HUD.Debug(string.format("  ❌ %s", moduleName), "CORE", "WARN")
                end
            end
        end
    end
    
    HUD.Debug("=================================", "CORE", "INFO")
    
    -- Check GPS HUD status specifically
    if HUD.IsModuleLoaded('gps_hud') then
        HUD.Debug("🗺️ GPS HUD System: ^2ACTIVE^7 (Main Interface)", "CORE", "INFO")
    else
        HUD.Debug("🗺️ GPS HUD System: ^1FAILED^7 (Fallback to legacy modules)", "CORE", "ERROR")
    end
end

-- ================================================================
-- SYSTEM EVENTS
-- ================================================================

-- Player loaded event
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    HUD.Debug("Player loaded - Starting delayed HUD initialization", "CORE", "INFO")
    HUD.Status.playerLoaded = true
    
    -- Wait for all resources to be fully loaded
    Citizen.Wait(2000)
    
    -- Initialize HUD system
    HUD.Initialize()
    
    -- Additional delay for GPS HUD
    Citizen.Wait(1000)
    
    -- Show GPS HUD if enabled
    if HUD.IsModuleLoaded('gps_hud') and Config.GPSHUD.enabled then
        local gpsModule = HUD.Modules['gps_hud']
        if gpsModule and gpsModule.Show then
            gpsModule.Show()
            HUD.Debug("GPS HUD activated for player", "GPS", "INFO")
        end
    end
    
    HUD.Debug("HUD system fully activated for player", "CORE", "INFO")
end)

-- Player unload event
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    HUD.Debug("Player unloaded - Cleaning up HUD system", "CORE", "INFO")
    HUD.Status.playerLoaded = false
    
    -- Hide GPS HUD
    if HUD.IsModuleLoaded('gps_hud') then
        local gpsModule = HUD.Modules['gps_hud']
        if gpsModule and gpsModule.Hide then
            gpsModule.Hide()
        end
    end
end)

-- Resource start event (for restart scenarios)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    HUD.Debug("Resource started - Checking player status", "CORE", "INFO")
    
    -- Wait a bit for other resources
    Citizen.Wait(1000)
    
    -- Check if player is already logged in
    if LocalPlayer.state.isLoggedIn then
        HUD.Debug("Player already logged in - Initializing immediately", "CORE", "INFO")
        HUD.Status.playerLoaded = true
        
        CreateThread(function()
            Citizen.Wait(2000)
            HUD.Initialize()
            
            -- Show GPS HUD
            Citizen.Wait(1000)
            if HUD.IsModuleLoaded('gps_hud') and Config.GPSHUD.enabled then
                local gpsModule = HUD.Modules['gps_hud']
                if gpsModule and gpsModule.Show then
                    gpsModule.Show()
                end
            end
        end)
    end
end)

-- Resource stop event
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    HUD.Debug("Resource stopping - Cleanup initiated", "CORE", "INFO")
    
    -- Cleanup all modules
    for moduleName, module in pairs(HUD.Modules) do
        if module.Cleanup and type(module.Cleanup) == "function" then
            pcall(module.Cleanup)
        end
    end
end)

-- ================================================================
-- PERFORMANCE MONITORING
-- ================================================================

if Config.Debug then
    -- Performance monitoring thread (only in debug mode)
    CreateThread(function()
        while true do
            Citizen.Wait(30000) -- Check every 30 seconds
            
            if HUD.Status.initialized then
                local memoryUsage = collectgarbage("count") / 1024 -- Convert to MB
                HUD.Debug(string.format("Performance Check: %d modules loaded, %.2f MB memory", 
                         HUD.Status.loadedModules, memoryUsage), "PERF", "INFO")
                
                -- Check for high memory usage
                if memoryUsage > 50 then
                    HUD.Debug(string.format("HIGH MEMORY USAGE: %.2f MB (Consider performance mode)", memoryUsage), "PERF", "WARN")
                end
            end
        end
    end)
end

-- ================================================================
-- COMMANDS (Debug Only)
-- ================================================================

if Config.Debug then
    -- Debug command to check system status
    RegisterCommand('hudstatus', function()
        print("^3=== HUD SYSTEM STATUS ===^7")
        print(string.format("^7Version: ^2%s^7", HUD.Version))
        print(string.format("^7Initialized: ^%s%s^7", HUD.Status.initialized and "2" or "1", HUD.Status.initialized and "YES" or "NO"))
        print(string.format("^7Player Loaded: ^%s%s^7", HUD.Status.playerLoaded and "2" or "1", HUD.Status.playerLoaded and "YES" or "NO"))
        print(string.format("^7Total Modules: ^6%d^7", HUD.Status.totalModules))
        print(string.format("^7Loaded Modules: ^2%d^7", HUD.Status.loadedModules))
        print(string.format("^7Failed Modules: ^1%d^7", HUD.Status.failedModules))
        
        -- GPS HUD specific status
        local gpsStatus = HUD.IsModuleLoaded('gps_hud')
        print(string.format("^7GPS HUD: ^%s%s^7", gpsStatus and "2" or "1", gpsStatus and "ACTIVE" or "INACTIVE"))
        
        print("^3========================^7")
        
        -- Detailed module status
        local status = HUD.GetModuleStatus()
        for moduleName, moduleStatus in pairs(status) do
            local statusText = string.format(
                "^7%s: ^%s%s ^7(Priority: ^6%d^7, Essential: ^%s%s^7)",
                moduleName,
                moduleStatus.loaded and "2" or "1",
                moduleStatus.loaded and "LOADED" or "NOT LOADED",
                moduleStatus.priority,
                moduleStatus.essential and "2" or "1",
                moduleStatus.essential and "YES" or "NO"
            )
            print(statusText)
        end
    end, false)
    
    -- Debug command to restart a specific module
    RegisterCommand('hudrestart', function(source, args)
        if not args[1] then
            print("^1Usage: /hudrestart <module_name>^7")
            print("^3Available modules:^7")
            for moduleName, _ in pairs(HUD.Modules) do
                print(string.format("^7- %s", moduleName))
            end
            return
        end
        
        local moduleName = args[1]:lower()
        if HUD.Modules[moduleName] then
            HUD.Debug(string.format("Restarting module '%s'", moduleName), "CMD", "INFO")
            
            -- Cleanup if possible
            local module = HUD.Modules[moduleName]
            if module.Cleanup and type(module.Cleanup) == "function" then
                pcall(module.Cleanup)
            end
            
            -- Remove from loaded modules
            HUD.LoadedModules[moduleName] = nil
            HUD.Status.loadedModules = HUD.Status.loadedModules - 1
            
            -- Re-initialize
            local success = HUD.InitModule(moduleName)
            if success then
                print(string.format("^2Module '%s' restarted successfully^7", moduleName))
            else
                print(string.format("^1Module '%s' failed to restart^7", moduleName))
            end
        else
            print(string.format("^1Module '%s' not found^7", moduleName))
        end
    end, false)
    
    -- Debug command to toggle GPS HUD
    RegisterCommand('gpshud', function(source, args)
        if not HUD.IsModuleLoaded('gps_hud') then
            print("^1GPS HUD module not loaded^7")
            return
        end
        
        local gpsModule = HUD.Modules['gps_hud']
        local action = args[1] and args[1]:lower() or 'toggle'
        
        if action == 'show' and gpsModule.Show then
            gpsModule.Show()
            print("^2GPS HUD shown^7")
        elseif action == 'hide' and gpsModule.Hide then
            gpsModule.Hide()
            print("^3GPS HUD hidden^7")
        elseif action == 'toggle' and gpsModule.Toggle then
            gpsModule.Toggle()
            print("^6GPS HUD toggled^7")
        else
            print("^3Usage: /gpshud [show|hide|toggle]^7")
        end
    end, false)
end

-- ================================================================
-- INITIALIZATION COMPLETE
-- ================================================================

HUD.Debug(string.format("Enhanced HUD Core System loaded (v%s)", HUD.Version), "CORE", "INFO")
HUD.Debug("Waiting for player login to initialize modules...", "CORE", "INFO")

-- Set global flag that init.lua has loaded
_G.HUD_CORE_LOADED = true
_G.HUD_VERSION = HUD.Version
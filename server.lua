-- ================================================================
-- QBCore HUD - Server Module
-- Version: 3.0.0
-- Description: Server-side functionality for HUD system
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ================================================================
-- DATABASE SETUP (FIXED SQL IMPLEMENTATION)
-- ================================================================

-- HUD Settings Table Name
local HUD_SETTINGS_TABLE = 'qb_hud_settings'

---Create HUD settings table if not exists
local function CreateHudSettingsTable()
    if not MySQL then
        print("^1[HUD-SERVER] MySQL wrapper not available^7")
        return false
    end
    
    -- ✅ FIXED: Complete SQL query string
    local query = string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL UNIQUE,
            settings JSON NOT NULL,
            theme VARCHAR(50) DEFAULT 'neon-magenta',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], HUD_SETTINGS_TABLE)
    
    -- ✅ SAFE: Type check before execution
    if type(query) == "string" and query ~= "" then
        MySQL.query(query, {}, function(result)
            if result then
                print("^2[HUD-SERVER] Settings table ready^7")
            else
                print("^1[HUD-SERVER] Failed to create settings table^7")
            end
        end)
        return true
    else
        print("^1[HUD-SERVER] Invalid query - table creation failed^7")
        return false
    end
end

-- ================================================================
-- INITIALIZATION
-- ================================================================

CreateThread(function()
    Wait(2000) -- Wait for MySQL to be ready
    
    -- ✅ SAFE: Check MySQL availability
    if GetResourceState('oxmysql') == 'started' then
        MySQL = exports.oxmysql
        CreateHudSettingsTable()
    else
        print("^3[HUD-SERVER] MySQL not available - settings will not persist^7")
    end
    
    print("^2[HUD-SERVER] Server module initialized^7")
end)

-- ================================================================
-- PLAYER DATA MANAGEMENT
-- ================================================================

---Get complete menu data for player
QBCore.Functions.CreateCallback('hud:server:getMenuData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, error = "Player not found"})
        return
    end
    
    -- ✅ SAFE: Validate player data before processing
    if not Player.PlayerData or type(Player.PlayerData) ~= "table" then
        cb({success = false, error = "Invalid player data"})
        return
    end
    
    local menuData = {
        success = true,
        player = {
            name = Player.PlayerData.name or "Unknown",
            citizenid = Player.PlayerData.citizenid or "",
            job = {
                name = Player.PlayerData.job and Player.PlayerData.job.name or "unemployed",
                label = Player.PlayerData.job and Player.PlayerData.job.label or "Unemployed",
                grade = Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.name or "0"
            },
            money = Player.PlayerData.money or {},
            metadata = {
                hunger = Player.PlayerData.metadata and Player.PlayerData.metadata['hunger'] or 100,
                thirst = Player.PlayerData.metadata and Player.PlayerData.metadata['thirst'] or 100,
                stress = Player.PlayerData.metadata and Player.PlayerData.metadata['stress'] or 0
            }
        },
        modules = {}
    }
    
    -- Add module configurations
    if Config and Config.Modules then
        for moduleName, moduleConfig in pairs(Config.Modules) do
            menuData.modules[moduleName] = {
                enabled = moduleConfig.enabled or false,
                position = moduleConfig.position or 'bottom-left',
                components = moduleConfig.components or {},
                priority = moduleConfig.priority or 999,
                essential = moduleConfig.essential or false
            }
        end
    end
    
    -- Add GPS HUD specific data
    if Config.GPSHUD then
        menuData.gpsHUD = {
            enabled = Config.GPSHUD.enabled,
            components = Config.GPSHUD.components,
            animations = Config.GPSHUD.animations,
            interaction = Config.GPSHUD.interaction
        }
    end
    
    -- Add theme data
    if Config.Theme then
        menuData.theme = {
            current = Config.Theme.current or 'neon-magenta',
            available = Config.Theme.available or {'neon-magenta', 'neon-cyan', 'classic'},
            colors = Config.Theme.colors or {}
        }
    end
    
    cb(menuData)
end)

-- ================================================================
-- SETTINGS MANAGEMENT
-- ================================================================

---Save player HUD settings
QBCore.Functions.CreateCallback('hud:server:saveSettings', function(source, cb, settings)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, error = "Player not found"})
        return
    end
    
    -- ✅ SAFE: Validate settings data
    if not settings or type(settings) ~= 'table' then
        cb({success = false, error = "Invalid settings data"})
        return
    end
    
    -- ✅ SAFE: Check MySQL availability
    if not MySQL then
        cb({success = false, error = "Database not available"})
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Validate and sanitize settings
    local validatedSettings = {}
    
    -- Validate theme
    if settings.theme and type(settings.theme) == "string" then
        local validThemes = Config.Theme and Config.Theme.available or {'neon-magenta', 'neon-cyan', 'classic'}
        local validTheme = false
        for _, theme in ipairs(validThemes) do
            if theme == settings.theme then
                validTheme = true
                break
            end
        end
        if validTheme then
            validatedSettings.theme = settings.theme
        end
    end
    
    -- Validate modules
    if settings.modules and type(settings.modules) == "table" then
        validatedSettings.modules = {}
        for moduleName, moduleSettings in pairs(settings.modules) do
            if type(moduleSettings) == "table" then
                validatedSettings.modules[moduleName] = {
                    enabled = type(moduleSettings.enabled) == "boolean" and moduleSettings.enabled or true,
                    position = type(moduleSettings.position) == "string" and moduleSettings.position or 'bottom-left',
                    opacity = type(moduleSettings.opacity) == "number" and moduleSettings.opacity or 0.9,
                    scale = type(moduleSettings.scale) == "number" and moduleSettings.scale or 1.0
                }
            end
        end
    end
    
    -- Validate UI settings
    if settings.ui and type(settings.ui) == "table" then
        validatedSettings.ui = {
            scaling = type(settings.ui.scaling) == "number" and settings.ui.scaling or 1.0,
            opacity = type(settings.ui.opacity) == "number" and settings.ui.opacity or 0.9,
            animations = type(settings.ui.animations) == "boolean" and settings.ui.animations or true,
            glowEffects = type(settings.ui.glowEffects) == "boolean" and settings.ui.glowEffects or true
        }
    end
    
    -- Save to database
    local query = string.format([[
        INSERT INTO %s (citizenid, settings, theme) 
        VALUES (?, ?, ?) 
        ON DUPLICATE KEY UPDATE 
            settings = VALUES(settings), 
            theme = VALUES(theme),
            updated_at = CURRENT_TIMESTAMP
    ]], HUD_SETTINGS_TABLE)
    
    local params = {
        citizenid,
        json.encode(validatedSettings),
        validatedSettings.theme or 'neon-magenta'
    }
    
    MySQL.query(query, params, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
            cb({success = true, message = "Settings saved successfully"})
            print(string.format("^2[HUD-SERVER] Settings saved for %s^7", citizenid))
        else
            cb({success = false, error = "Failed to save settings"})
            print(string.format("^1[HUD-SERVER] Failed to save settings for %s^7", citizenid))
        end
    end)
end)

---Load player HUD settings
QBCore.Functions.CreateCallback('hud:server:loadSettings', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, error = "Player not found"})
        return
    end
    
    -- ✅ SAFE: Check MySQL availability
    if not MySQL then
        cb({success = false, error = "Database not available"})
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    local query = string.format([[
        SELECT settings, theme, updated_at 
        FROM %s 
        WHERE citizenid = ? 
        LIMIT 1
    ]], HUD_SETTINGS_TABLE)
    
    MySQL.query(query, {citizenid}, function(result)
        if result and result[1] then
            local data = result[1]
            local settings = {}
            
            -- ✅ SAFE: Parse JSON settings
            if data.settings then
                local success, parsedSettings = pcall(json.decode, data.settings)
                if success and type(parsedSettings) == "table" then
                    settings = parsedSettings
                end
            end
            
            cb({
                success = true,
                settings = settings,
                theme = data.theme or 'neon-magenta',
                lastUpdated = data.updated_at
            })
        else
            -- Return default settings
            cb({
                success = true,
                settings = {
                    modules = {},
                    ui = {
                        scaling = 1.0,
                        opacity = 0.9,
                        animations = true,
                        glowEffects = true
                    }
                },
                theme = 'neon-magenta',
                lastUpdated = nil
            })
        end
    end)
end)

-- ================================================================
-- STRESS MANAGEMENT SYSTEM
-- ================================================================

---Gain stress for player
RegisterNetEvent('hud:server:GainStress', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- ✅ SAFE: Validate amount parameter
    if type(amount) ~= "number" or amount <= 0 then
        print(string.format("^3[HUD-SERVER] Invalid stress amount: %s^7", tostring(amount)))
        return
    end
    
    local currentStress = Player.PlayerData.metadata and Player.PlayerData.metadata['stress'] or 0
    local newStress = math.min(currentStress + amount, 100) -- Cap at 100
    
    Player.Functions.SetMetaData('stress', newStress)
    
    -- Trigger client update
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    
    print(string.format("^2[HUD-SERVER] Player %s gained %d stress (now: %d)^7", 
          Player.PlayerData.citizenid, amount, newStress))
end)

---Relieve stress for player
RegisterNetEvent('hud:server:RelieveStress', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- ✅ SAFE: Validate amount parameter
    if type(amount) ~= "number" or amount <= 0 then
        print(string.format("^3[HUD-SERVER] Invalid stress relief amount: %s^7", tostring(amount)))
        return
    end
    
    local currentStress = Player.PlayerData.metadata and Player.PlayerData.metadata['stress'] or 0
    local newStress = math.max(currentStress - amount, 0) -- Floor at 0
    
    Player.Functions.SetMetaData('stress', newStress)
    
    -- Trigger client update
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    
    print(string.format("^2[HUD-SERVER] Player %s relieved %d stress (now: %d)^7", 
          Player.PlayerData.citizenid, amount, newStress))
end)

-- ================================================================
-- MONEY MANAGEMENT COMMANDS
-- ================================================================

---Cash command
QBCore.Commands.Add('cash', 'Check your cash amount', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local cash = Player.PlayerData.money and Player.PlayerData.money['cash'] or 0
    TriggerClientEvent('QBCore:Notify', source, string.format('Cash: $%s', comma_value(cash)), 'primary')
end)

---Bank command
QBCore.Commands.Add('bank', 'Check your bank balance', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local bank = Player.PlayerData.money and Player.PlayerData.money['bank'] or 0
    TriggerClientEvent('QBCore:Notify', source, string.format('Bank: $%s', comma_value(bank)), 'primary')
end)

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Format number with commas
---@param amount number
---@return string
function comma_value(amount)
    if not amount or type(amount) ~= "number" then return "0" end
    
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

---Validate table structure
---@param data table
---@param schema table
---@return boolean
function ValidateTableStructure(data, schema)
    if type(data) ~= "table" or type(schema) ~= "table" then
        return false
    end
    
    for key, expectedType in pairs(schema) do
        if type(data[key]) ~= expectedType then
            return false
        end
    end
    
    return true
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

-- Player connecting event
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    print(string.format("^2[HUD-SERVER] Player %s connected^7", src))
end)

-- Player disconnecting event
AddEventHandler('playerDropped', function(reason)
    local src = source
    print(string.format("^3[HUD-SERVER] Player %s disconnected: %s^7", src, reason))
end)

-- Resource stopping cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^3[HUD-SERVER] Shutting down...^7")
    end
end)

print("^2[HUD-SERVER] Server module loaded successfully^7")
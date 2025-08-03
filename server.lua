-- ================================================================
-- QBCore HUD - Enhanced Server Module
-- Version: 3.0.0
-- Description: Server-side events, commands, callbacks and stress system
--              Optimized for GPS HUD integration
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Server Status
local ServerStatus = {
    version = "3.0.0",
    playersLoaded = {},
    totalStressEvents = 0,
    totalMoneyTransactions = 0
}

-- ================================================================
-- ENHANCED STRESS SYSTEM
-- ================================================================

---Gain stress for a player with enhanced logging
---@param source number Player source
---@param amount number Stress amount to gain (0-100)
---@param reason string Reason for stress gain (optional)
---@param category string Stress category: 'combat', 'vehicle', 'environment', 'social' (optional)
local function GainStress(source, amount, reason, category)
    if not source or not amount then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player job is whitelisted (no stress)
    if Config.WhitelistedJobs[Player.PlayerData.job.name] then return end
    
    -- Check if stress system is disabled
    if Config.DisableStress then return end
    
    local currentStress = Player.PlayerData.metadata['stress'] or 0
    local newStress = math.min(100, currentStress + amount)
    
    -- Update player metadata
    Player.Functions.SetMetaData('stress', newStress)
    
    -- Trigger client update (GPS HUD will receive this)
    TriggerClientEvent('hud:client:UpdateStress', source, newStress)
    
    -- Enhanced logging
    ServerStatus.totalStressEvents = ServerStatus.totalStressEvents + 1
    
    if Config.Debug then
        print(string.format("^3[HUD:SERVER]^7 Player %s gained %d stress (%s | %s). New stress: %d", 
              Player.PlayerData.name, amount, reason or "unknown", category or "general", newStress))
    end
    
    -- Trigger stress effects at high levels
    if newStress >= 85 and currentStress < 85 then
        TriggerClientEvent('hud:client:StressEffects', source, 'high')
    elseif newStress >= 60 and currentStress < 60 then
        TriggerClientEvent('hud:client:StressEffects', source, 'medium')
    end
end

---Relieve stress for a player with enhanced logging
---@param source number Player source
---@param amount number Stress amount to relieve (0-100)
---@param reason string Reason for stress relief (optional)
---@param category string Relief category: 'rest', 'activity', 'medication', 'social' (optional)
local function RelieveStress(source, amount, reason, category)
    if not source or not amount then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local currentStress = Player.PlayerData.metadata['stress'] or 0
    local newStress = math.max(0, currentStress - amount)
    
    -- Update player metadata
    Player.Functions.SetMetaData('stress', newStress)
    
    -- Trigger client update (GPS HUD will receive this)
    TriggerClientEvent('hud:client:UpdateStress', source, newStress)
    
    -- Enhanced logging
    if Config.Debug then
        print(string.format("^2[HUD:SERVER]^7 Player %s relieved %d stress (%s | %s). New stress: %d", 
              Player.PlayerData.name, amount, reason or "unknown", category or "general", newStress))
    end
end

-- ================================================================
-- EVENTS
-- ================================================================

-- Enhanced Stress Events
RegisterNetEvent('hud:server:GainStress', function(amount, reason, category)
    local src = source
    if not src then return end
    
    GainStress(src, amount, reason, category)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount, reason, category)
    local src = source
    if not src then return end
    
    RelieveStress(src, amount, reason, category)
end)

-- Player loaded event - send initial GPS HUD data
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local src = source
    if not Player then return end
    
    -- Track loaded players
    ServerStatus.playersLoaded[src] = {
        name = Player.PlayerData.name,
        loadTime = os.time(),
        citizenid = Player.PlayerData.citizenid
    }
    
    -- Wait for client to be ready
    Wait(2000)
    
    -- Send initial biometric data to GPS HUD
    local hunger = Player.PlayerData.metadata['hunger'] or 100
    local thirst = Player.PlayerData.metadata['thirst'] or 100
    local stress = Player.PlayerData.metadata['stress'] or 0
    
    TriggerClientEvent('hud:client:UpdateNeeds', src, hunger, thirst)
    TriggerClientEvent('hud:client:UpdateStress', src, stress)
    
    -- Send welcome message with GPS HUD info
    if Config.Debug then
        TriggerClientEvent('QBCore:Notify', src, 'GPS HUD System Active', 'success')
    end
    
    if Config.Debug then
        print(string.format("^2[HUD:SERVER]^7 GPS HUD data sent to %s (ID: %s)", Player.PlayerData.name, Player.PlayerData.citizenid))
    end
end)

-- Player unload event
RegisterNetEvent('QBCore:Server:PlayerUnload', function(source)
    if ServerStatus.playersLoaded[source] then
        if Config.Debug then
            print(string.format("^3[HUD:SERVER]^7 Player %s unloaded", ServerStatus.playersLoaded[source].name))
        end
        ServerStatus.playersLoaded[source] = nil
    end
end)

-- Enhanced Money change event
RegisterNetEvent('hud:server:OnMoneyChange', function(moneyType, amount, action, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local currentAmount = 0
    if moneyType == 'cash' then
        currentAmount = Player.PlayerData.money['cash'] or 0
    elseif moneyType == 'bank' then
        currentAmount = Player.PlayerData.money['bank'] or 0
    end
    
    -- Track transaction
    ServerStatus.totalMoneyTransactions = ServerStatus.totalMoneyTransactions + 1
    
    -- Trigger client money display update (GPS HUD can show this)
    TriggerClientEvent('hud:client:OnMoneyChange', src, {
        type = moneyType,
        amount = amount,
        newAmount = currentAmount,
        action = action,
        reason = reason
    })
    
    if Config.Debug then
        print(string.format("^6[HUD:SERVER]^7 Money change: %s %s %d (new: %d) - %s", 
              Player.PlayerData.name, moneyType, amount, currentAmount, reason or action or "unknown"))
    end
end)

-- ================================================================
-- ENHANCED COMMANDS
-- ================================================================

-- Cash command with GPS HUD integration
QBCore.Commands.Add('cash', 'Check your cash amount', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local cashAmount = Player.PlayerData.money['cash'] or 0
    TriggerClientEvent('QBCore:Notify', source, 'Cash: $' .. QBCore.Shared.CommaValue(cashAmount), 'primary')
    
    -- Show in GPS HUD as well
    TriggerClientEvent('hud:client:ShowMoney', source, {
        cash = cashAmount,
        duration = 5000
    })
end)

-- Bank command with GPS HUD integration
QBCore.Commands.Add('bank', 'Check your bank amount', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local bankAmount = Player.PlayerData.money['bank'] or 0
    TriggerClientEvent('QBCore:Notify', source, 'Bank: $' .. QBCore.Shared.CommaValue(bankAmount), 'primary')
    
    -- Show in GPS HUD as well
    TriggerClientEvent('hud:client:ShowMoney', source, {
        bank = bankAmount,
        duration = 5000
    })
end)

-- Enhanced admin stress command
QBCore.Commands.Add('setstress', 'Set player stress level (Admin Only)', {
    {name = 'id', help = 'Player ID'},
    {name = 'stress', help = 'Stress level (0-100)'},
    {name = 'reason', help = 'Reason (optional)'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local stressLevel = tonumber(args[2])
    local reason = args[3] or "Admin Command"
    
    if not targetId or not stressLevel then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid arguments. Usage: /setstress [id] [stress] [reason]', 'error')
        return
    end
    
    if stressLevel < 0 or stressLevel > 100 then
        TriggerClientEvent('QBCore:Notify', source, 'Stress level must be between 0 and 100', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local oldStress = TargetPlayer.PlayerData.metadata['stress'] or 0
    TargetPlayer.Functions.SetMetaData('stress', stressLevel)
    TriggerClientEvent('hud:client:UpdateStress', targetId, stressLevel)
    
    -- Admin feedback
    TriggerClientEvent('QBCore:Notify', source, 
        string.format('Set %s stress: %d → %d (%s)', TargetPlayer.PlayerData.name, oldStress, stressLevel, reason), 'success')
        
    -- Player feedback
    TriggerClientEvent('QBCore:Notify', targetId, 
        string.format('Your stress level was set to %d%% by an admin', stressLevel), 'primary')
        
    if Config.Debug then
        print(string.format("^6[HUD:SERVER]^7 Admin %s set %s stress: %d → %d (%s)", 
              GetPlayerName(source), TargetPlayer.PlayerData.name, oldStress, stressLevel, reason))
    end
end, 'admin')

-- Enhanced test stress command
QBCore.Commands.Add('teststress', 'Test stress gain/relief (Admin Only)', {
    {name = 'amount', help = 'Stress amount (+/- value)'},
    {name = 'reason', help = 'Test reason (optional)'}
}, true, function(source, args)
    local amount = tonumber(args[1])
    local reason = args[2] or "Admin Test"
    
    if not amount then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid amount. Usage: /teststress [amount] [reason]', 'error')
        return
    end
    
    if amount > 0 then
        GainStress(source, amount, reason, 'test')
        TriggerClientEvent('QBCore:Notify', source, string.format('Test: Gained %d stress (%s)', amount, reason), 'primary')
    else
        RelieveStress(source, math.abs(amount), reason, 'test')
        TriggerClientEvent('QBCore:Notify', source, string.format('Test: Relieved %d stress (%s)', math.abs(amount), reason), 'primary')
    end
end, 'admin')

-- GPS HUD debug command (Admin Only)
QBCore.Commands.Add('gpshudinfo', 'Get GPS HUD system information (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerCount = 0
    for _ in pairs(ServerStatus.playersLoaded) do
        playerCount = playerCount + 1
    end
    
    local info = {
        "^3=== GPS HUD SERVER INFO ===^7",
        string.format("^7Version: ^2%s^7", ServerStatus.version),
        string.format("^7Players with GPS HUD: ^6%d^7", playerCount),
        string.format("^7Total Stress Events: ^6%d^7", ServerStatus.totalStressEvents),
        string.format("^7Total Money Transactions: ^6%d^7", ServerStatus.totalMoneyTransactions),
        string.format("^7Stress System: %s^7", Config.DisableStress and "^1DISABLED" or "^2ENABLED"),
        "^3==========================^7"
    }
    
    for _, line in ipairs(info) do
        TriggerClientEvent('chatMessage', source, "", {}, line)
    end
end, 'admin')

-- ================================================================
-- ENHANCED CALLBACKS
-- ================================================================

-- Get enhanced menu data for client
QBCore.Functions.CreateCallback('hud:server:getMenu', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local menuData = {
        version = ServerStatus.version,
        modules = {},
        themes = Config.Theme.available or {'neon-magenta', 'neon-cyan', 'synthwave', 'matrix', 'classic'},
        currentTheme = Config.Theme.current or 'neon-magenta',
        playerData = {
            name = Player.PlayerData.name,
            citizenid = Player.PlayerData.citizenid,
            job = {
                name = Player.PlayerData.job.name,
                label = Player.PlayerData.job.label,
                grade = Player.PlayerData.job.grade.name
            },
            money = Player.PlayerData.money,
            metadata = {
                hunger = Player.PlayerData.metadata['hunger'] or 100,
                thirst = Player.PlayerData.metadata['thirst'] or 100,
                stress = Player.PlayerData.metadata['stress'] or 0
            }
        }
    }
    
    -- Add module configurations
    for moduleName, moduleConfig in pairs(Config.Modules) do
        menuData.modules[moduleName] = {
            enabled = moduleConfig.enabled or false,
            position = moduleConfig.position or 'bottom-left',
            components = moduleConfig.components or {},
            priority = moduleConfig.priority or 999,
            essential = moduleConfig.essential or false
        }
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
    
    cb(menuData)
end)

-- Enhanced save player settings
QBCore.Functions.CreateCallback('hud:server:saveSettings', function(source, cb, settings)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({success = false, error = "Player not found"})
        return
    end
    
    if not settings or type(settings) ~= 'table' then
        cb({success = false, error = "Invalid settings data"})
        return
    end
    
    -- Validate settings structure
    local validatedSettings = {}
    
    -- Validate theme
    if settings.theme and Config.Theme.available then
        local validTheme = false
        for _, theme in ipairs(Config.Theme.available) do
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
    if settings.modules and type(settings.modules) == 'table' then
        validatedSettings.modules = {}
        for moduleName, moduleSettings in pairs(settings.modules) do
            if Config.Modules[moduleName] then
                validatedSettings.modules[moduleName] = moduleSettings
            end
        end
    end
    
    -- Validate GPS HUD settings
    if settings.gpsHUD and type(settings.gpsHUD) == 'table' then
        validatedSettings.gpsHUD = {}
        for key, value in pairs(settings.gpsHUD) do
            if type(value) == 'boolean' or type(value) == 'string' or type(value) == 'number' then
                validatedSettings.gpsHUD[key] = value
            end
        end
    end
    
    -- Save to player metadata
    local currentSettings = Player.PlayerData.metadata['hud_settings'] or {}
    
    -- Merge validated settings with existing
    for key, value in pairs(validatedSettings) do
        currentSettings[key] = value
    end
    
    currentSettings.lastUpdated = os.time()
    Player.Functions.SetMetaData('hud_settings', currentSettings)
    
    cb({
        success = true,
        settings = currentSettings,
        message = "GPS HUD settings saved successfully"
    })
    
    if Config.Debug then
        print(string.format("^2[HUD:SERVER]^7 GPS HUD settings saved for %s", Player.PlayerData.name))
    end
end)

-- Get enhanced player settings
QBCore.Functions.CreateCallback('hud:server:getSettings', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local settings = Player.PlayerData.metadata['hud_settings'] or {}
    
    -- Add default GPS HUD settings if not present
    if not settings.gpsHUD then
        settings.gpsHUD = {
            theme = Config.Theme.current or 'neon-magenta',
            position = 'bottom-left',
            components = Config.GPSHUD.components or {},
            animations = Config.GPSHUD.animations or {}
        }
    end
    
    cb(settings)
end)

-- Get comprehensive player stress data
QBCore.Functions.CreateCallback('hud:server:getStressData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({stress = 0, disabled = true})
        return
    end
    
    local stress = Player.PlayerData.metadata['stress'] or 0
    local jobWhitelisted = Config.WhitelistedJobs[Player.PlayerData.job.name] or false
    
    cb({
        stress = stress,
        disabled = Config.DisableStress,
        jobWhitelisted = jobWhitelisted,
        effectLevel = stress >= 85 and 'high' or stress >= 60 and 'medium' or stress >= 25 and 'low' or 'none'
    })
end)

-- ================================================================
-- AUTOMATIC STRESS SYSTEM (Enhanced)
-- ================================================================

-- Vehicle speed stress system
CreateThread(function()
    if Config.DisableStress then return end
    
    while true do
        Wait(10000) -- Check every 10 seconds
        
        for _, playerId in pairs(GetPlayers()) do
            local src = tonumber(playerId)
            local Player = QBCore.Functions.GetPlayer(src)
            
            if Player and not Config.WhitelistedJobs[Player.PlayerData.job.name] then
                -- Check if player is in vehicle and speeding
                local ped = GetPlayerPed(src)
                if ped and DoesEntityExist(ped) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    
                    if vehicle and vehicle ~= 0 then
                        local speed = GetEntitySpeed(vehicle) * (Config.UseMPH and 2.23694 or 3.6)
                        local vehicleClass = GetVehicleClass(vehicle)
                        local vehicleHash = GetEntityModel(vehicle)
                        
                        -- Check if vehicle/class is whitelisted
                        local isWhitelisted = Config.WhitelistedVehicles[vehicleHash] or not Config.VehClassStress[tostring(vehicleClass)]
                        
                        if not isWhitelisted and speed >= Config.MinimumSpeed then
                            local stressAmount = math.random(1, 3)
                            
                            -- Check if seatbelt is off (more stress)
                            if speed >= Config.MinimumSpeedUnbuckled then
                                -- Check seatbelt status (implement seatbelt detection)
                                stressAmount = stressAmount * 1.5
                            end
                            
                            -- Higher stress for extreme speeds
                            if speed >= 150 then
                                stressAmount = stressAmount * 2
                            end
                            
                            if math.random() < Config.StressChance then
                                GainStress(src, math.ceil(stressAmount), string.format("High Speed Driving (%.0f %s)", speed, Config.UseMPH and "MPH" or "KPH"), 'vehicle')
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Combat stress system (Enhanced)
AddEventHandler('entityDamage', function(entity, attacker, weapon, damage)
    if not entity or not IsEntityAPed(entity) then return end
    if Config.DisableStress then return end
    
    local victimPlayerId = NetworkGetPlayerIndexFromPed(entity)
    if victimPlayerId == -1 then return end
    
    local victimSource = GetPlayerServerId(victimPlayerId)
    if not victimSource then return end
    
    local Player = QBCore.Functions.GetPlayer(victimSource)
    if not Player or Config.WhitelistedJobs[Player.PlayerData.job.name] then return end
    
    -- Check if damage is from weapon
    if weapon and weapon ~= 0 and not Config.WhitelistedWeaponStress[weapon] then
        local stressAmount = math.random(2, 5)
        
        -- More stress for headshots or high damage
        if damage >= 50 then
            stressAmount = stressAmount * 1.5
        end
        
        if math.random() < (Config.StressChance * 1.5) then -- Higher chance for combat stress
            local weaponName = QBCore.Shared.Weapons[weapon] and QBCore.Shared.Weapons[weapon].label or "Unknown Weapon"
            GainStress(victimSource, math.ceil(stressAmount), string.format("Combat Damage (%s)", weaponName), 'combat')
        end
    end
end)

-- ================================================================
-- EXPORTS
-- ================================================================

-- Enhanced stress functions for other resources
exports('GainStress', GainStress)
exports('RelieveStress', RelieveStress)

-- Get player stress level with additional info
exports('GetStress', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    return Player.PlayerData.metadata['stress'] or 0
end)

-- Set player stress level with validation
exports('SetStress', function(source, amount, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    amount = math.max(0, math.min(100, amount))
    local oldStress = Player.PlayerData.metadata['stress'] or 0
    
    Player.Functions.SetMetaData('stress', amount)
    TriggerClientEvent('hud:client:UpdateStress', source, amount)
    
    if Config.Debug then
        print(string.format("^6[HUD:SERVER]^7 External stress set: %s %d → %d (%s)", 
              Player.PlayerData.name, oldStress, amount, reason or "External Script"))
    end
    
    return true
end)

-- Get server statistics
exports('GetHUDStats', function()
    return {
        version = ServerStatus.version,
        playersLoaded = ServerStatus.playersLoaded,
        totalStressEvents = ServerStatus.totalStressEvents,
        totalMoneyTransactions = ServerStatus.totalMoneyTransactions,
        stressEnabled = not Config.DisableStress
    }
end)

-- ================================================================
-- INITIALIZATION
-- ================================================================

CreateThread(function()
    if Config.Debug then
        print("^2[HUD:SERVER]^7 Enhanced QBCore HUD Server Module loaded successfully")
        print(string.format("^2[HUD:SERVER]^7 Version: ^6%s^7", ServerStatus.version))
        print("^2[HUD:SERVER]^7 Stress System: " .. (Config.DisableStress and "^1DISABLED^7" or "^2ENABLED^7"))
        print("^2[HUD:SERVER]^7 GPS HUD Integration: " .. (Config.GPSHUD.enabled and "^2ACTIVE^7" or "^1INACTIVE^7"))
        print("^2[HUD:SERVER]^7 Available Commands: ^3/cash, /bank, /setstress, /teststress, /gpshudinfo^7")
    end
end)
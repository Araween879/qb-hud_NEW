-- ================================================================
-- QBCore HUD - Health System Module
-- Version: 3.0.0
-- Description: Complete health monitoring system for all vital stats
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Health System Module
Health = Health or {}
Health.Initialized = false
Health.Visible = true
Health.LastUpdate = 0
Health.UpdateInterval = Config.Modules.health.updateInterval or 500

-- Status Data Cache
Health.Status = {
    health = 100,              -- ❤️ Health (0-100%)
    armor = 0,                 -- 🛡️ Armor (0-100%)
    hunger = 100,              -- 🍔 Hunger (0-100%)
    thirst = 100,              -- 💧 Thirst (0-100%)
    stress = 0,                -- 🧠 Stress (0-100%)
    stamina = 100,             -- 🏃 Stamina (0-100%)
    oxygen = 100,              -- 🫁 Oxygen (0-100%)
    
    -- Status flags
    isDead = false,
    isUnconscious = false,
    isBleeding = false,
    isInVehicle = false,
    
    -- Warnings (true when values are critically low)
    warnings = {
        health = false,
        armor = false,
        hunger = false,
        thirst = false,
        stress = false,
        stamina = false,
        oxygen = false
    }
}

-- Performance tracking
Health.Performance = {
    lastFullUpdate = 0,
    updateCount = 0,
    averageUpdateTime = 0
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Health module
---@return boolean success
function Health.Init()
    if Health.Initialized then
        HUD.Debug("Health module already initialized", "HEALTH", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Health module...", "HEALTH", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.health.enabled then
        HUD.Debug("Health module disabled in config", "HEALTH", "INFO")
        return false
    end
    
    -- Register events
    Health.RegisterEvents()
    
    -- Start update thread
    Health.StartUpdateThread()
    
    -- Register NUI callbacks
    Health.RegisterNUICallbacks()
    
    Health.Initialized = true
    HUD.Debug("Health module initialized successfully", "HEALTH", "INFO")
    
    return true
end

---Register all health-related events
function Health.RegisterEvents()
    -- QBCore player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Health.RefreshStatus()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Health.SetVisible(false)
    end)
    
    -- Health update events
    RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
        Health.UpdateNeeds(hunger, thirst)
    end)
    
    RegisterNetEvent('hud:client:UpdateStress', function(stress)
        Health.UpdateStress(stress)
    end)
    
    RegisterNetEvent('hospital:client:Revive', function()
        Health.OnPlayerRevive()
    end)
    
    RegisterNetEvent('hospital:client:SetLaststand', function()
        Health.OnPlayerDown()
    end)
    
    -- HUD control events
    RegisterNetEvent('hud:client:toggleHealth', function(visible)
        Health.SetVisible(visible)
    end)
    
    HUD.Debug("Health events registered", "HEALTH", "INFO")
end

---Register NUI callbacks for health module
function Health.RegisterNUICallbacks()
    RegisterNUICallback('healthClick', function(data, cb)
        Health.OnHealthClick(data.type)
        cb('ok')
    end)
    
    RegisterNUICallback('getHealthDetails', function(data, cb)
        cb(Health.GetDetailedStatus())
    end)
    
    HUD.Debug("Health NUI callbacks registered", "HEALTH", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM
-- ================================================================

---Start the health update thread
function Health.StartUpdateThread()
    CreateThread(function()
        while Health.Initialized do
            local currentTime = GetGameTimer()
            
            -- Only update if enough time has passed
            if currentTime - Health.LastUpdate >= Health.UpdateInterval then
                local startTime = GetGameTimer()
                
                Health.UpdateStatus()
                Health.SendToNUI()
                
                Health.LastUpdate = currentTime
                Health.Performance.updateCount = Health.Performance.updateCount + 1
                
                -- Track performance
                local updateTime = GetGameTimer() - startTime
                Health.Performance.averageUpdateTime = 
                    (Health.Performance.averageUpdateTime + updateTime) / 2
            end
            
            Wait(50) -- Small delay to prevent excessive CPU usage
        end
    end)
    
    HUD.Debug("Health update thread started", "HEALTH", "INFO")
end

---Update all health status values
function Health.UpdateStatus()
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- ✅ SAFE: Check if player data exists
    if not PlayerData or not PlayerData.metadata then
        return
    end
    
    -- Update basic health values
    Health.Status.health = GetEntityHealth(ped) - 100 -- Convert from 100-200 to 0-100
    Health.Status.armor = GetPedArmour(ped)
    
    -- Update needs from player metadata
    Health.Status.hunger = PlayerData.metadata.hunger or 100
    Health.Status.thirst = PlayerData.metadata.thirst or 100
    Health.Status.stress = PlayerData.metadata.stress or 0
    
    -- Update stamina (only when not in vehicle)
    if not IsPedInAnyVehicle(ped, false) then
        Health.Status.stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    else
        Health.Status.stamina = 100
    end
    
    -- Update oxygen (only when underwater)
    if IsPedSwimmingUnderWater(ped) then
        Health.Status.oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    else
        Health.Status.oxygen = 100
    end
    
    -- Update status flags
    Health.Status.isDead = IsEntityDead(ped)
    Health.Status.isUnconscious = PlayerData.metadata.ishandcuffed or false
    Health.Status.isBleeding = PlayerData.metadata.bleed or 0 > 0
    Health.Status.isInVehicle = IsPedInAnyVehicle(ped, false)
    
    -- Update warnings
    Health.UpdateWarnings()
    
    -- Additional checks for special states
    Health.CheckSpecialStates()
end

---Update warning states for low values
function Health.UpdateWarnings()
    local config = Config.GPSHUD.visual
    
    Health.Status.warnings.health = Health.Status.health <= (config.lowHealthWarning or 25)
    Health.Status.warnings.armor = Health.Status.armor <= (config.lowArmorWarning or 25)
    Health.Status.warnings.hunger = Health.Status.hunger <= (config.lowHungerWarning or 25)
    Health.Status.warnings.thirst = Health.Status.thirst <= (config.lowThirstWarning or 25)
    Health.Status.warnings.stress = Health.Status.stress >= (config.highStressWarning or 75)
    Health.Status.warnings.stamina = Health.Status.stamina <= 25
    Health.Status.warnings.oxygen = Health.Status.oxygen <= 25
end

---Check for special states that affect health display
function Health.CheckSpecialStates()
    local ped = PlayerPedId()
    
    -- Check if player is in water
    if IsEntityInWater(ped) then
        Health.Status.inWater = true
    else
        Health.Status.inWater = false
    end
    
    -- Check if player is falling
    if IsPedFalling(ped) then
        Health.Status.falling = true
    else
        Health.Status.falling = false
    end
    
    -- Check if player is in combat
    if GetPlayerTargetEntity(PlayerId()) ~= 0 or IsPedInCombat(ped, 0) then
        Health.Status.inCombat = true
    else
        Health.Status.inCombat = false
    end
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send health data to NUI
function Health.SendToNUI()
    if not Health.Visible then return end
    
    -- Prepare data for NUI
    local healthData = {
        health = math.max(0, math.min(100, Health.Status.health)),
        armor = math.max(0, math.min(100, Health.Status.armor)),
        hunger = math.max(0, math.min(100, Health.Status.hunger)),
        thirst = math.max(0, math.min(100, Health.Status.thirst)),
        stress = math.max(0, math.min(100, Health.Status.stress)),
        stamina = math.max(0, math.min(100, Health.Status.stamina)),
        oxygen = math.max(0, math.min(100, Health.Status.oxygen)),
        
        -- Status flags
        isDead = Health.Status.isDead,
        isUnconscious = Health.Status.isUnconscious,
        isBleeding = Health.Status.isBleeding,
        inWater = Health.Status.inWater,
        inCombat = Health.Status.inCombat,
        
        -- Warnings
        warnings = Health.Status.warnings,
        
        -- Visual settings
        showWhenFull = Config.GPSHUD.visual.showWhenFull,
        showPercentage = Config.GPSHUD.visual.showPercentage,
        compactMode = Config.GPSHUD.visual.compactMode
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'updateStatus',
        module = 'health',
        data = healthData
    })
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle needs update from server
---@param hunger number Hunger value (0-100)
---@param thirst number Thirst value (0-100)
function Health.UpdateNeeds(hunger, thirst)
    if type(hunger) == "number" then
        Health.Status.hunger = math.max(0, math.min(100, hunger))
    end
    
    if type(thirst) == "number" then
        Health.Status.thirst = math.max(0, math.min(100, thirst))
    end
    
    HUD.Debug(string.format("Needs updated - Hunger: %d, Thirst: %d", 
              Health.Status.hunger, Health.Status.thirst), "HEALTH", "INFO")
    
    -- Force immediate NUI update
    Health.SendToNUI()
end

---Handle stress update from server
---@param stress number Stress value (0-100)
function Health.UpdateStress(stress)
    if type(stress) == "number" then
        Health.Status.stress = math.max(0, math.min(100, stress))
        
        HUD.Debug(string.format("Stress updated: %d", Health.Status.stress), "HEALTH", "INFO")
        
        -- Play stress sound if enabled and stress is high
        if Config.GPSHUD.audio.enabled and Config.GPSHUD.audio.stressSound then
            if Health.Status.stress >= (Config.GPSHUD.visual.highStressWarning or 75) then
                Health.PlayStressSound()
            end
        end
        
        -- Force immediate NUI update
        Health.SendToNUI()
    end
end

---Handle player revive event
function Health.OnPlayerRevive()
    Health.Status.isDead = false
    Health.Status.isUnconscious = false
    Health.Status.health = 100
    
    HUD.Debug("Player revived - health status reset", "HEALTH", "INFO")
    
    -- Force status refresh
    Health.RefreshStatus()
end

---Handle player down/laststand event
function Health.OnPlayerDown()
    Health.Status.isUnconscious = true
    
    HUD.Debug("Player down - unconscious state activated", "HEALTH", "INFO")
    
    -- Force immediate NUI update
    Health.SendToNUI()
end

---Handle health icon click
---@param healthType string Type of health clicked ('health', 'armor', etc.)
function Health.OnHealthClick(healthType)
    if not Config.GPSHUD.interaction.clickableIcons then return end
    
    HUD.Debug(string.format("Health icon clicked: %s", healthType), "HEALTH", "INFO")
    
    -- Show detailed status if enabled
    if Config.GPSHUD.interaction.statusDetails then
        Health.ShowDetailedStatus(healthType)
    end
    
    -- Trigger custom event for other resources
    TriggerEvent('hud:client:healthIconClicked', healthType, Health.Status)
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the health module
---@param visible boolean
function Health.SetVisible(visible)
    Health.Visible = visible
    
    HUD.Debug(string.format("Health visibility set to: %s", visible and "visible" or "hidden"), "HEALTH", "INFO")
    
    if visible then
        Health.SendToNUI()
    else
        SendNUIMessage({
            action = 'toggleModule',
            module = 'health',
            visible = false
        })
    end
end

---Get current health module visibility
---@return boolean
function Health.IsVisible()
    return Health.Visible
end

---Get current health status
---@return table
function Health.GetStatus()
    return Health.Status
end

---Get detailed health status for NUI display
---@return table
function Health.GetDetailedStatus()
    return {
        status = Health.Status,
        performance = Health.Performance,
        config = {
            updateInterval = Health.UpdateInterval,
            showWhenFull = Config.GPSHUD.visual.showWhenFull,
            warnings = Config.GPSHUD.visual
        }
    }
end

---Force update health display
function Health.ForceUpdate()
    Health.UpdateStatus()
    Health.SendToNUI()
    HUD.Debug("Health force update triggered", "HEALTH", "INFO")
end

---Refresh all health status from server
function Health.RefreshStatus()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if PlayerData and PlayerData.metadata then
        Health.Status.hunger = PlayerData.metadata.hunger or 100
        Health.Status.thirst = PlayerData.metadata.thirst or 100
        Health.Status.stress = PlayerData.metadata.stress or 0
        
        HUD.Debug("Health status refreshed from server", "HEALTH", "INFO")
        Health.SendToNUI()
    end
end

---Set theme for health module
---@param theme string Theme name
function Health.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("Health theme set to: %s", theme), "HEALTH", "INFO")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Show detailed status information
---@param statusType string Type of status to show details for
function Health.ShowDetailedStatus(statusType)
    local statusData = Health.Status
    local message = ""
    
    if statusType == "health" then
        message = string.format("Health: %d%% %s", 
                  statusData.health, 
                  statusData.warnings.health and "(LOW!)" or "")
    elseif statusType == "armor" then
        message = string.format("Armor: %d%% %s", 
                  statusData.armor, 
                  statusData.warnings.armor and "(LOW!)" or "")
    elseif statusType == "hunger" then
        message = string.format("Hunger: %d%% %s", 
                  statusData.hunger, 
                  statusData.warnings.hunger and "(LOW!)" or "")
    elseif statusType == "thirst" then
        message = string.format("Thirst: %d%% %s", 
                  statusData.thirst, 
                  statusData.warnings.thirst and "(LOW!)" or "")
    elseif statusType == "stress" then
        message = string.format("Stress: %d%% %s", 
                  statusData.stress, 
                  statusData.warnings.stress and "(HIGH!)" or "")
    elseif statusType == "stamina" then
        message = string.format("Stamina: %d%% %s", 
                  statusData.stamina, 
                  statusData.warnings.stamina and "(LOW!)" or "")
    end
    
    if message ~= "" then
        QBCore.Functions.Notify(message, statusData.warnings[statusType] and 'error' or 'primary')
    end
end

---Play stress warning sound
function Health.PlayStressSound()
    if GetResourceState('interact-sound') == 'started' then
        exports['interact-sound']:PlaySound("stress_warning")
    end
end

---Play low health warning sound
function Health.PlayHealthWarningSound()
    if GetResourceState('interact-sound') == 'started' then
        exports['interact-sound']:PlaySound("health_warning")
    end
end

---Get performance statistics
---@return table
function Health.GetPerformanceStats()
    return {
        initialized = Health.Initialized,
        visible = Health.Visible,
        updateInterval = Health.UpdateInterval,
        updateCount = Health.Performance.updateCount,
        averageUpdateTime = Health.Performance.averageUpdateTime,
        lastUpdate = Health.LastUpdate
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function called when resource stops
function Health.Cleanup()
    Health.Initialized = false
    Health.Visible = false
    
    HUD.Debug("Health module cleaned up", "HEALTH", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Health.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make Health module available globally
_G.Health = Health

HUD.Debug("Health module loaded", "HEALTH", "INFO")
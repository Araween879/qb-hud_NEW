-- ================================================================
-- QBCore HUD - Health System Module
-- Version: 3.0.0
-- Description: Manages health, armor, hunger, thirst, stress, oxygen
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

local Health = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current status values
local currentHealth = 100
local currentArmor = 0
local currentHunger = 100
local currentThirst = 100
local currentStress = 0
local currentOxygen = 100
local playerDead = false

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Health module
function Health.Init()
    if isInitialized then
        HUD.Debug("^3Health module already initialized^7", "HEALTH")
        return true
    end
    
    HUD.Debug("^2Initializing Health module^7", "HEALTH")
    
    -- Register events
    Health.RegisterEvents()
    
    -- Start update thread
    Health.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.health.enabled
    
    isInitialized = true
    HUD.Debug("^2Health module initialized successfully^7", "HEALTH")
    
    return true
end

---Register all health-related events
function Health.RegisterEvents()
    -- QBCore player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
        HUD.Debug("^2Player data loaded in Health module^7", "HEALTH")
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        PlayerData = {}
    end)
    
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        PlayerData = val
    end)
    
    -- Health-specific events
    RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
        if newHunger then currentHunger = newHunger end
        if newThirst then currentThirst = newThirst end
        Health.SendUpdate()
        HUD.Debug(string.format("^2Needs updated - Hunger: %d, Thirst: %d^7", currentHunger, currentThirst), "HEALTH")
    end)
    
    RegisterNetEvent('hud:client:UpdateStress', function(newStress)
        currentStress = newStress or 0
        Health.SendUpdate()
        HUD.Debug(string.format("^2Stress updated: %d^7", currentStress), "HEALTH")
    end)
    
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'health' then
            Health.SetVisible(visible)
        end
    end)
    
    HUD.Debug("^2Health events registered^7", "HEALTH")
end

---Start the health update thread
function Health.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Health update thread already running^7", "HEALTH")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible then
                Health.UpdateStatus()
            end
            Wait(Config.Modules.health.updateInterval or 500)
        end
    end)
    
    HUD.Debug("^2Health update thread started^7", "HEALTH")
end

---Update all health-related status values
function Health.UpdateStatus()
    local player = PlayerPedId()
    if not player or player == 0 then return end
    
    -- Get current values
    local newHealth = GetEntityHealth(player) - 100 -- Normalize to 0-100
    local newArmor = GetPedArmour(player)
    local newPlayerDead = IsEntityDead(player) or 
                         (PlayerData.metadata and PlayerData.metadata['inlaststand']) or 
                         (PlayerData.metadata and PlayerData.metadata['isdead']) or false
    
    -- Get hunger/thirst from PlayerData if available
    if PlayerData.metadata then
        if PlayerData.metadata['hunger'] then currentHunger = PlayerData.metadata['hunger'] end
        if PlayerData.metadata['thirst'] then currentThirst = PlayerData.metadata['thirst'] end
        if PlayerData.metadata['stress'] then currentStress = PlayerData.metadata['stress'] end
    end
    
    -- Calculate oxygen based on situation
    local newOxygen = currentOxygen
    if IsEntityInWater(player) then
        newOxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    else
        newOxygen = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    end
    
    -- Check if any values changed significantly (optimization)
    local healthChanged = math.abs(newHealth - currentHealth) > 1
    local armorChanged = math.abs(newArmor - currentArmor) > 1
    local oxygenChanged = math.abs(newOxygen - currentOxygen) > 2
    local deadStateChanged = newPlayerDead ~= playerDead
    
    if healthChanged or armorChanged or oxygenChanged or deadStateChanged then
        currentHealth = newHealth
        currentArmor = newArmor
        currentOxygen = newOxygen
        playerDead = newPlayerDead
        
        Health.SendUpdate()
    end
end

---Send current health data to NUI
function Health.SendUpdate()
    if not isVisible then return end
    
    local healthData = {
        health = math.max(0, math.min(100, currentHealth)),
        armor = math.max(0, math.min(100, currentArmor)),
        hunger = math.max(0, math.min(100, currentHunger)),
        thirst = math.max(0, math.min(100, currentThirst)),
        stress = math.max(0, math.min(100, currentStress)),
        oxygen = math.max(0, math.min(100, currentOxygen)),
        isDead = playerDead,
        showWhenFull = Config.Modules.health.showWhenFull,
        components = Config.Modules.health.components
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('health', healthData)
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the health module
---@param visible boolean
function Health.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Health visibility set to: %s^7", visible and "visible" or "hidden"), "HEALTH")
    
    if visible then
        Health.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('health', { visible = false })
        end
    end
end

---Get current health module visibility
---@return boolean
function Health.IsVisible()
    return isVisible
end

---Get current health status data
---@return table
function Health.GetStatus()
    return {
        health = currentHealth,
        armor = currentArmor,
        hunger = currentHunger,
        thirst = currentThirst,
        stress = currentStress,
        oxygen = currentOxygen,
        isDead = playerDead
    }
end

---Force update health display
function Health.ForceUpdate()
    Health.UpdateStatus()
    Health.SendUpdate()
    HUD.Debug("^2Health force update triggered^7", "HEALTH")
end

---Set specific health values (for external use)
---@param healthType string Type: 'health', 'armor', 'hunger', 'thirst', 'stress', 'oxygen'
---@param value number Value to set (0-100)
function Health.SetValue(healthType, value)
    if type(value) ~= "number" then
        HUD.Debug(string.format("^1Invalid value type for %s: expected number^7", healthType), "HEALTH")
        return false
    end
    
    value = math.max(0, math.min(100, value))
    
    if healthType == 'health' then
        currentHealth = value
    elseif healthType == 'armor' then
        currentArmor = value
    elseif healthType == 'hunger' then
        currentHunger = value
    elseif healthType == 'thirst' then
        currentThirst = value
    elseif healthType == 'stress' then
        currentStress = value
    elseif healthType == 'oxygen' then
        currentOxygen = value
    else
        HUD.Debug(string.format("^1Unknown health type: %s^7", healthType), "HEALTH")
        return false
    end
    
    Health.SendUpdate()
    HUD.Debug(string.format("^2%s set to: %d^7", healthType, value), "HEALTH")
    return true
end

-- ================================================================
-- STRESS SYSTEM INTEGRATION
-- ================================================================

-- Stress effects (from original client.lua)
if not Config.DisableStress then
    CreateThread(function()
        while true do
            Wait(10000) -- Check every 10 seconds
            
            if LocalPlayer.state.isLoggedIn and currentStress >= Config.MinimumStress then
                local player = PlayerPedId()
                
                -- Stress effects based on level
                if currentStress >= 100 then
                    -- Extreme stress - ragdoll and screen effects
                    local BlurIntensity = 3000
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                    
                    if not IsPedRagdoll(player) and IsPedOnFoot(player) and not IsPedSwimming(player) then
                        SetPedToRagdollWithFall(player, 3500, 3500, 1, GetEntityForwardVector(player), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                    end
                elseif currentStress >= Config.MinimumStress then
                    -- Light stress effects
                    local BlurIntensity = 1500 + (currentStress - Config.MinimumStress) * 20
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            end
        end
    end)
end

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('health', Health)
end

-- Export Health functions for external use
_G.Health = Health

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Health module shutting down^7", "HEALTH")
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)
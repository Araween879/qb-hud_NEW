-- ================================================================
-- QBCore HUD - HUD Core Client Module (STATUS-BALKEN SYSTEM)
-- Version: 3.0.0
-- Description: Verwaltet alle Status-Balken: 
--              🎤 Mikrofon | ❤️ Leben | 🛡️ Rüstung | 🍔 Hunger | 💧 Durst | 🧠 Stress | 🏃 Ausdauer
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- HUD Core System
HUDCORE = HUDCORE or {}
HUDCORE.Enabled = true
HUDCORE.Visible = false
HUDCORE.LastUpdate = 0
HUDCORE.UpdateInterval = Config.Modules.hud_core and Config.Modules.hud_core.updateInterval or 200

-- Status Cache für alle Balken
HUDCORE.Status = {
    -- 🎤 Voice System (Mikrofon-Anzeige)
    voice = {
        level = 2,              -- Voice level 1-4 (Whisper, Normal, Shout, Scream)
        talking = false,        -- Aktuell am sprechen
        radioActive = false,    -- Radio aktiv
        radioChannel = 0,       -- Radio Kanal (0 = kein Kanal)
        muted = false,          -- Stumm geschaltet
        proximity = 'normal'    -- Voice mode: whisper, normal, shout
    },
    
    -- Biometrics (Alle Lebenswerte)
    health = 100,              -- ❤️ Leben (0-100%)
    armor = 0,                 -- 🛡️ Rüstung (0-100%)
    hunger = 100,              -- 🍔 Hunger (0-100%)
    thirst = 100,              -- 💧 Durst (0-100%)
    stress = 0,                -- 🧠 Stress (0-100%)
    stamina = 100,             -- 🏃 Ausdauer (0-100%)
    oxygen = 100               -- 🫁 Sauerstoff (0-100%)
}

-- Performance Tracking
HUDCORE.Performance = {
    lastVoiceUpdate = 0,
    lastBiometricsUpdate = 0,
    updateCount = 0,
    averageUpdateTime = 0
}

-- ================================================================
-- INITIALIZATION
-- ================================================================

function HUDCORE.Init()
    if not Config.Modules.hud_core or not Config.Modules.hud_core.enabled then
        if HUD and HUD.Debug then
            HUD.Debug("HUD Core disabled in config", "HUDCORE", "WARN")
        end
        return false
    end
    
    if HUD and HUD.Debug then
        HUD.Debug("Initializing HUD Core System (Status-Balken)...", "HUDCORE", "INFO")
    end
    
    -- Setup NUI callbacks
    HUDCORE.RegisterNUICallbacks()
    
    -- Setup game events
    HUDCORE.RegisterEvents()
    
    -- Setup update threads
    HUDCORE.StartUpdateThreads()
    
    -- Show HUD Core
    HUDCORE.SetVisible(true)
    
    if HUD and HUD.Debug then
        HUD.Debug("HUD Core System initialized successfully", "HUDCORE", "INFO")
    end
    
    return true
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

function HUDCORE.RegisterNUICallbacks()
    -- HUD Core visibility toggle
    RegisterNUICallback('hudcore:toggleVisibility', function(data, cb)
        HUDCORE.SetVisible(data.visible)
        cb('ok')
    end)
    
    -- Voice level cycling (when user clicks microphone)
    RegisterNUICallback('hudcore:cycleVoiceLevel', function(data, cb)
        HUDCORE.CycleVoiceLevel()
        cb('ok')
    end)
    
    -- Get current status (for initialization)
    RegisterNUICallback('hudcore:getStatus', function(data, cb)
        cb(HUDCORE.Status)
    end)
end

function HUDCORE.SendNUIMessage(action, data)
    SendNUIMessage({
        module = 'hud_core',
        action = action,
        data = data or {}
    })
end

-- ================================================================
-- STATUS UPDATES
-- ================================================================

function HUDCORE.UpdateStatus(data)
    if not data then return end
    
    local startTime = GetGameTimer()
    local updated = false
    
    -- Update biometrics
    if data.health and data.health ~= HUDCORE.Status.health then
        HUDCORE.Status.health = math.max(0, math.min(100, data.health))
        updated = true
    end
    
    if data.armor and data.armor ~= HUDCORE.Status.armor then
        HUDCORE.Status.armor = math.max(0, math.min(100, data.armor))
        updated = true
    end
    
    if data.hunger and data.hunger ~= HUDCORE.Status.hunger then
        HUDCORE.Status.hunger = math.max(0, math.min(100, data.hunger))
        updated = true
    end
    
    if data.thirst and data.thirst ~= HUDCORE.Status.thirst then
        HUDCORE.Status.thirst = math.max(0, math.min(100, data.thirst))
        updated = true
    end
    
    if data.stress and data.stress ~= HUDCORE.Status.stress then
        HUDCORE.Status.stress = math.max(0, math.min(100, data.stress))
        updated = true
    end
    
    if data.stamina and data.stamina ~= HUDCORE.Status.stamina then
        HUDCORE.Status.stamina = math.max(0, math.min(100, data.stamina))
        updated = true
    end
    
    if data.oxygen and data.oxygen ~= HUDCORE.Status.oxygen then
        HUDCORE.Status.oxygen = math.max(0, math.min(100, data.oxygen))
        updated = true
    end
    
    -- Send to NUI if anything changed
    if updated then
        HUDCORE.SendNUIMessage('updateStatus', HUDCORE.Status)
        HUDCORE.Performance.lastBiometricsUpdate = GetGameTimer()
        
        -- Update performance stats
        local updateTime = GetGameTimer() - startTime
        HUDCORE.Performance.updateCount = HUDCORE.Performance.updateCount + 1
        HUDCORE.Performance.averageUpdateTime = 
            (HUDCORE.Performance.averageUpdateTime * (HUDCORE.Performance.updateCount - 1) + updateTime) / HUDCORE.Performance.updateCount
    end
end

function HUDCORE.UpdateVoice(data)
    if not data then return end
    
    local updated = false
    
    -- Voice level (1-4)
    if data.level and data.level ~= HUDCORE.Status.voice.level then
        HUDCORE.Status.voice.level = math.max(1, math.min(4, data.level))
        updated = true
    end
    
    -- Talking state
    if data.talking ~= nil and data.talking ~= HUDCORE.Status.voice.talking then
        HUDCORE.Status.voice.talking = data.talking
        updated = true
    end
    
    -- Radio state
    if data.radioActive ~= nil and data.radioActive ~= HUDCORE.Status.voice.radioActive then
        HUDCORE.Status.voice.radioActive = data.radioActive
        updated = true
    end
    
    if data.radioChannel and data.radioChannel ~= HUDCORE.Status.voice.radioChannel then
        HUDCORE.Status.voice.radioChannel = data.radioChannel
        updated = true
    end
    
    -- Muted state
    if data.muted ~= nil and data.muted ~= HUDCORE.Status.voice.muted then
        HUDCORE.Status.voice.muted = data.muted
        updated = true
    end
    
    -- Proximity mode
    if data.proximity and data.proximity ~= HUDCORE.Status.voice.proximity then
        HUDCORE.Status.voice.proximity = data.proximity
        updated = true
    end
    
    -- Send to NUI if anything changed
    if updated then
        HUDCORE.SendNUIMessage('updateVoice', HUDCORE.Status.voice)
        HUDCORE.Performance.lastVoiceUpdate = GetGameTimer()
    end
end

-- ================================================================
-- VOICE SYSTEM INTEGRATION
-- ================================================================

function HUDCORE.CycleVoiceLevel()
    -- Cycle through voice levels: 1 -> 2 -> 3 -> 4 -> 1
    local currentLevel = HUDCORE.Status.voice.level
    local newLevel = currentLevel >= 4 and 1 or currentLevel + 1
    
    -- Update local state
    HUDCORE.Status.voice.level = newLevel
    
    -- Send to voice system (if available)
    if GetResourceState('pma-voice') == 'started' then
        -- Trigger voice level change
        TriggerEvent('pma-voice:setTalkingMode', newLevel)
    end
    
    -- Update NUI
    HUDCORE.SendNUIMessage('updateVoice', HUDCORE.Status.voice)
    
    if HUD and HUD.Debug then
        local modes = { 'Whisper', 'Normal', 'Shout', 'Scream' }
        HUD.Debug(string.format("Voice level changed to: %s (%d)", modes[newLevel] or 'Unknown', newLevel), "HUDCORE", "INFO")
    end
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

function HUDCORE.RegisterEvents()
    -- QBCore Player Events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Wait(1000) -- Wait for player data to load
        HUDCORE.ForceUpdate()
    end)
    
    -- HUD Status Update Events
    RegisterNetEvent('hud:client:UpdateNeeds', function(data)
        HUDCORE.UpdateStatus({
            hunger = data.hunger,
            thirst = data.thirst
        })
    end)
    
    RegisterNetEvent('hud:client:UpdateStress', function(stress)
        HUDCORE.UpdateStatus({
            stress = stress
        })
    end)
    
    -- Voice System Events (pma-voice integration)
    RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
        HUDCORE.UpdateVoice({
            level = mode
        })
    end)
    
    RegisterNetEvent('pma-voice:radioActive', function(active)
        HUDCORE.UpdateVoice({
            radioActive = active
        })
    end)
    
    RegisterNetEvent('pma-voice:setRadioChannel', function(channel)
        HUDCORE.UpdateVoice({
            radioChannel = channel
        })
    end)
    
    -- Health System Events
    RegisterNetEvent('hospital:client:SetArmor', function(armor)
        HUDCORE.UpdateStatus({
            armor = armor
        })
    end)
    
    -- Oxygen Events (for underwater)
    RegisterNetEvent('hud:client:UpdateOxygen', function(oxygen)
        HUDCORE.UpdateStatus({
            oxygen = oxygen
        })
    end)
    
    -- Force update event
    RegisterNetEvent('hudcore:client:forceUpdate', function()
        HUDCORE.ForceUpdate()
    end)
end

-- ================================================================
-- UPDATE THREADS
-- ================================================================

function HUDCORE.StartUpdateThreads()
    -- Main status update thread
    CreateThread(function()
        while HUDCORE.Enabled do
            if HUDCORE.Visible then
                HUDCORE.UpdateFromGame()
            end
            Wait(HUDCORE.UpdateInterval)
        end
    end)
    
    -- Voice system update thread (faster updates for voice)
    CreateThread(function()
        while HUDCORE.Enabled do
            if HUDCORE.Visible then
                HUDCORE.UpdateVoiceFromGame()
            end
            Wait(100) -- Voice updates every 100ms for responsiveness
        end
    end)
end

function HUDCORE.UpdateFromGame()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return end
    
    local ped = PlayerPedId()
    
    -- Get current values from game
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local healthPercent = math.floor((currentHealth / maxHealth) * 100)
    
    local armorPercent = GetPedArmour(ped)
    local staminaPercent = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    
    -- Get metadata if available
    local hunger = PlayerData.metadata and PlayerData.metadata.hunger or 100
    local thirst = PlayerData.metadata and PlayerData.metadata.thirst or 100
    local stress = PlayerData.metadata and PlayerData.metadata.stress or 0
    
    -- Update status
    HUDCORE.UpdateStatus({
        health = healthPercent,
        armor = armorPercent,
        hunger = hunger,
        thirst = thirst,
        stress = stress,
        stamina = staminaPercent
    })
end

function HUDCORE.UpdateVoiceFromGame()
    if GetResourceState('pma-voice') ~= 'started' then return end
    
    local playerId = PlayerId()
    
    -- Get voice state from pma-voice
    local voiceLevel = LocalPlayer.state.proximity and LocalPlayer.state.proximity.mode or 2
    local isTalking = NetworkIsPlayerTalking(playerId)
    local radioChannel = LocalPlayer.state.radioChannel or 0
    local radioActive = LocalPlayer.state.radioActive or false
    
    -- Update voice status
    HUDCORE.UpdateVoice({
        level = voiceLevel,
        talking = isTalking,
        radioChannel = radioChannel,
        radioActive = radioActive
    })
end

-- ================================================================
-- VISIBILITY & THEME CONTROL
-- ================================================================

function HUDCORE.SetVisible(visible)
    if HUDCORE.Visible == visible then return end
    
    HUDCORE.Visible = visible
    HUDCORE.SendNUIMessage('setVisible', { visible = visible })
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("HUD Core visibility: %s", visible and "visible" or "hidden"), "HUDCORE", "INFO")
    end
end

function HUDCORE.SetTheme(theme)
    if not theme then return end
    
    HUDCORE.SendNUIMessage('setTheme', { theme = theme })
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("HUD Core theme changed to: %s", theme), "HUDCORE", "INFO")
    end
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

function HUDCORE.ForceUpdate()
    HUDCORE.UpdateFromGame()
    HUDCORE.UpdateVoiceFromGame()
    
    if HUD and HUD.Debug then
        HUD.Debug("HUD Core force update completed", "HUDCORE", "INFO")
    end
end

function HUDCORE.GetStatus()
    return HUDCORE.Status
end

function HUDCORE.GetPerformanceData()
    return {
        updateCount = HUDCORE.Performance.updateCount,
        averageUpdateTime = HUDCORE.Performance.averageUpdateTime,
        lastVoiceUpdate = HUDCORE.Performance.lastVoiceUpdate,
        lastBiometricsUpdate = HUDCORE.Performance.lastBiometricsUpdate
    }
end

-- ================================================================
-- EXPORTS FOR OTHER RESOURCES
-- ================================================================

-- Get current status
exports('GetHUDCoreStatus', function()
    return HUDCORE.GetStatus()
end)

-- Update specific status
exports('UpdateHealth', function(health)
    HUDCORE.UpdateStatus({ health = health })
end)

exports('UpdateArmor', function(armor)
    HUDCORE.UpdateStatus({ armor = armor })
end)

exports('UpdateHunger', function(hunger)
    HUDCORE.UpdateStatus({ hunger = hunger })
end)

exports('UpdateThirst', function(thirst)
    HUDCORE.UpdateStatus({ thirst = thirst })
end)

exports('UpdateStress', function(stress)
    HUDCORE.UpdateStatus({ stress = stress })
end)

exports('UpdateVoiceLevel', function(level)
    HUDCORE.UpdateVoice({ level = level })
end)

-- Visibility control
exports('SetHUDCoreVisible', function(visible)
    HUDCORE.SetVisible(visible)
end)

-- Theme control
exports('SetHUDCoreTheme', function(theme)
    HUDCORE.SetTheme(theme)
end)
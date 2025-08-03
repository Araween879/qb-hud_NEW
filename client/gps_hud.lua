-- ================================================================
-- QBCore HUD - GPS HUD Client Module (HAUPT-INTERFACE)
-- Version: 3.0.0
-- Description: Hauptinterface mit GPS, Navigation und allen Status-Werten
--              🎤 Mikrofon | ❤️ Leben | 🍔 Essen | 💧 Durst | 🧠 Stress | 🏃 Ausdauer
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- GPS HUD System
GPSHUD = GPSHUD or {}
GPSHUD.Enabled = true
GPSHUD.Visible = false
GPSHUD.LastUpdate = 0
GPSHUD.UpdateInterval = Config.GPSHUD.updateInterval or 200

-- Status Cache für alle Werte
GPSHUD.Status = {
    -- 🎤 Voice System (Mikrofon)
    voice = {
        level = 2,              -- Voice level 1-4
        talking = false,        -- Aktuell am sprechen
        radioActive = false,    -- Radio aktiv
        radioChannel = 0,       -- Radio Kanal
        muted = false          -- Stumm geschaltet
    },
    
    -- Biometrics (Alle Lebenswerte für GPS HUD Icons)
    health = 100,              -- ❤️ Leben (0-100%)
    armor = 0,                 -- 🛡️ Rüstung (0-100%)
    hunger = 100,              -- 🍔 Essen (0-100%)
    thirst = 100,              -- 💧 Durst (0-100%)
    stress = 0,                -- 🧠 Stress (0-100%)
    stamina = 100,             -- 🏃 Ausdauer (0-100%)
    
    -- Navigation & Location
    location = {
        name = "Unknown",       -- Zone name
        street = "Unknown Street", -- Straßenname
        direction = 0,          -- Kompass-Richtung
        distance = 0           -- Entfernung zum Waypoint
    },
    
    -- Time Display
    time = {
        hours = 0,
        minutes = 0,
        formatted = "00:00"
    }
}

-- Performance Tracking
GPSHUD.Performance = {
    lastVoiceUpdate = 0,
    lastBiometricsUpdate = 0,
    lastLocationUpdate = 0,
    updateCount = 0
}

-- ================================================================
-- INITIALIZATION
-- ================================================================

function GPSHUD.Init()
    if not Config.GPSHUD or not Config.GPSHUD.enabled then
        if HUD and HUD.Debug then
            HUD.Debug("GPS HUD disabled in config", "GPS", "WARN")
        end
        return false
    end
    
    if HUD and HUD.Debug then
        HUD.Debug("Initializing GPS HUD system (MAIN INTERFACE)...", "GPS", "INFO")
    end
    
    -- Setup NUI callbacks
    GPSHUD.SetupCallbacks()
    
    -- Start update loops
    GPSHUD.StartUpdateLoop()
    
    -- Register events
    GPSHUD.RegisterEvents()
    
    -- Set initial theme
    GPSHUD.SetTheme(Config.Theme.current or 'neon-magenta')
    
    if HUD and HUD.Debug then
        HUD.Debug("GPS HUD initialized successfully", "GPS", "INFO")
    end
    return true
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

function GPSHUD.SetupCallbacks()
    -- Handle GPS HUD interactions
    RegisterNUICallback('statusIconClicked', function(data, cb)
        GPSHUD.HandleStatusIconClick(data.statusType)
        cb('ok')
    end)
    
    RegisterNUICallback('hudSettings', function(data, cb)
        GPSHUD.HandleSettingsAction(data)
        cb('ok')
    end)
end

function GPSHUD.SendNUIMessage(action, data)
    if not GPSHUD.Enabled then return end
    
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

-- ================================================================
-- VISIBILITY CONTROL
-- ================================================================

function GPSHUD.Show()
    if not GPSHUD.Enabled then return end
    
    GPSHUD.Visible = true
    GPSHUD.SendNUIMessage('toggleGpsHud', { show = true })
    
    -- Initial data load
    CreateThread(function()
        Wait(100)
        GPSHUD.ForceUpdate()
    end)
    
    if HUD and HUD.Debug then
        HUD.Debug("GPS HUD shown (Main Interface)", "GPS", "INFO")
    end
end

function GPSHUD.Hide()
    GPSHUD.Visible = false
    GPSHUD.SendNUIMessage('toggleGpsHud', { show = false })
    
    if HUD and HUD.Debug then
        HUD.Debug("GPS HUD hidden", "GPS", "INFO")
    end
end

function GPSHUD.Toggle(visible)
    if visible == nil then
        visible = not GPSHUD.Visible
    end
    
    if visible then
        GPSHUD.Show()
    else
        GPSHUD.Hide()
    end
end

-- ================================================================
-- STATUS DATA COLLECTION
-- ================================================================

function GPSHUD.CollectBiometricData()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return GPSHUD.Status end
    
    local ped = PlayerPedId()
    
    -- Sammle alle Biometric-Daten für die GPS HUD Icons
    local biometrics = {
        -- ❤️ Leben (Health)
        health = math.max(0, math.min(100, math.ceil((GetEntityHealth(ped) - 100) / (GetEntityMaxHealth(ped) - 100) * 100))),
        
        -- 🛡️ Rüstung (Armor)
        armor = math.max(0, math.min(100, GetPedArmour(ped))),
        
        -- 🍔 Essen (Hunger)
        hunger = math.max(0, math.min(100, Player.metadata and Player.metadata['hunger'] or 100)),
        
        -- 💧 Durst (Thirst)
        thirst = math.max(0, math.min(100, Player.metadata and Player.metadata['thirst'] or 100)),
        
        -- 🧠 Stress
        stress = math.max(0, math.min(100, Player.metadata and Player.metadata['stress'] or 0)),
        
        -- 🏃 Ausdauer (Stamina) - Berechnet aus Sprint-Stamina
        stamina = math.max(0, math.min(100, 100 - GetPlayerSprintStaminaRemaining(PlayerId())))
    }
    
    return biometrics
end

function GPSHUD.CollectVoiceData()
    -- 🎤 Voice-System-Daten sammeln
    local voiceData = {
        level = 2, -- Default
        talking = false,
        radioActive = false,
        radioChannel = 0,
        muted = false
    }
    
    -- pma-voice Integration
    if GetResourceState('pma-voice'):find('start') then
        -- Voice Level (Proximity Distance)
        if LocalPlayer.state.proximity then
            if LocalPlayer.state.proximity.distance then
                local distance = LocalPlayer.state.proximity.distance
                -- Convert distance to level 1-4
                if distance <= 3 then voiceData.level = 1      -- Whisper
                elseif distance <= 7 then voiceData.level = 2  -- Normal
                elseif distance <= 15 then voiceData.level = 3 -- Shout
                else voiceData.level = 4 end                   -- Megaphone
            end
        end
        
        -- Talking Status
        voiceData.talking = NetworkIsPlayerTalking(PlayerId())
        
        -- Radio Status
        if LocalPlayer.state.radioChannel then
            voiceData.radioChannel = LocalPlayer.state.radioChannel
            voiceData.radioActive = voiceData.radioChannel > 0
        end
        
        -- Muted Status (if available)
        if LocalPlayer.state.voiceMuted ~= nil then
            voiceData.muted = LocalPlayer.state.voiceMuted
        end
    end
    
    return voiceData
end

function GPSHUD.CollectLocationData()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Street Namen
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    -- Zone Name
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    
    -- Direction/Heading
    local heading = GetEntityHeading(ped)
    
    -- Distance to waypoint (if set)
    local distance = 0
    if IsWaypointActive() then
        local waypoint = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
        if waypoint.x ~= 0 and waypoint.y ~= 0 then
            distance = #(coords - waypoint) / 1000 -- Convert to KM
        end
    end
    
    return {
        name = zoneName ~= "MAPNAME" and zoneName or "Unknown Area",
        street = streetName,
        crossing = crossingName,
        direction = heading,
        distance = math.floor(distance * 10) / 10 -- Round to 1 decimal
    }
end

-- ================================================================
-- STATUS UPDATES
-- ================================================================

function GPSHUD.UpdateAll()
    if not GPSHUD.Visible or not GPSHUD.Enabled then return end
    
    local now = GetGameTimer()
    
    -- Update biometrics (❤️🛡️🍔💧🧠🏃)
    if now - GPSHUD.Performance.lastBiometricsUpdate >= GPSHUD.UpdateInterval then
        local biometrics = GPSHUD.CollectBiometricData()
        GPSHUD.UpdateStatus(biometrics)
        GPSHUD.Performance.lastBiometricsUpdate = now
    end
    
    -- Update voice (🎤) - Higher frequency for responsiveness
    if now - GPSHUD.Performance.lastVoiceUpdate >= 100 then
        local voiceData = GPSHUD.CollectVoiceData()
        GPSHUD.UpdateVoice(voiceData)
        GPSHUD.Performance.lastVoiceUpdate = now
    end
    
    -- Update location - Lower frequency (every 1.5 seconds)
    if now - GPSHUD.Performance.lastLocationUpdate >= 1500 then
        local locationData = GPSHUD.CollectLocationData()
        GPSHUD.UpdateLocation(locationData)
        GPSHUD.Performance.lastLocationUpdate = now
    end
    
    GPSHUD.Performance.updateCount = GPSHUD.Performance.updateCount + 1
end

function GPSHUD.UpdateStatus(statusData)
    if not GPSHUD.Visible or not GPSHUD.Enabled then return end
    
    -- Update internal cache
    for key, value in pairs(statusData) do
        if GPSHUD.Status[key] ~= nil then
            GPSHUD.Status[key] = value
        end
    end
    
    -- Send to NUI
    GPSHUD.SendNUIMessage('updateStatus', statusData)
end

function GPSHUD.UpdateVoice(voiceData)
    if not GPSHUD.Visible or not GPSHUD.Enabled then return end
    
    -- Validate and clamp voice data
    if voiceData.level then
        voiceData.level = math.max(1, math.min(4, voiceData.level))
    end
    
    if voiceData.radioChannel then
        voiceData.radioChannel = math.max(0, voiceData.radioChannel)
    end
    
    -- Update cache
    for key, value in pairs(voiceData) do
        if GPSHUD.Status.voice[key] ~= nil then
            GPSHUD.Status.voice[key] = value
        end
    end
    
    -- Send to NUI
    GPSHUD.SendNUIMessage('updateVoice', voiceData)
end

function GPSHUD.UpdateLocation(locationData)
    if not GPSHUD.Visible or not GPSHUD.Enabled then return end
    
    -- Update cache
    for key, value in pairs(locationData) do
        if GPSHUD.Status.location[key] ~= nil then
            GPSHUD.Status.location[key] = value
        end
    end
    
    -- Send to NUI
    GPSHUD.SendNUIMessage('updateLocation', locationData)
end

function GPSHUD.ForceUpdate()
    -- Force update all components immediately
    local biometrics = GPSHUD.CollectBiometricData()
    local voiceData = GPSHUD.CollectVoiceData()
    local locationData = GPSHUD.CollectLocationData()
    
    GPSHUD.UpdateStatus(biometrics)
    GPSHUD.UpdateVoice(voiceData)
    GPSHUD.UpdateLocation(locationData)
    
    if HUD and HUD.Debug then
        HUD.Debug("GPS HUD force update completed", "GPS", "INFO")
    end
end

-- ================================================================
-- UPDATE LOOP
-- ================================================================

function GPSHUD.StartUpdateLoop()
    CreateThread(function()
        while GPSHUD.Enabled do
            if GPSHUD.Visible then
                GPSHUD.UpdateAll()
            end
            
            Wait(GPSHUD.UpdateInterval)
        end
    end)
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("GPS HUD update loop started (interval: %dms)", GPSHUD.UpdateInterval), "GPS", "INFO")
    end
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

function GPSHUD.RegisterEvents()
    -- Player loaded
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Wait(2000) -- Wait for other systems to load
        if Config.GPSHUD.enabled then
            GPSHUD.Show()
        end
    end)
    
    -- Player logout
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        GPSHUD.Hide()
    end)
    
    -- Voice Events (pma-voice)
    RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
        GPSHUD.Status.voice.level = mode
        GPSHUD.UpdateVoice({ level = mode })
    end)
    
    RegisterNetEvent('pma-voice:radioActive', function(radioTalking)
        GPSHUD.Status.voice.radioActive = radioTalking
        GPSHUD.UpdateVoice({ radioActive = radioTalking })
    end)
    
    -- Health/Needs Updates
    RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
        GPSHUD.UpdateStatus({
            hunger = hunger,
            thirst = thirst
        })
    end)
    
    -- Stress Updates
    RegisterNetEvent('hud:client:UpdateStress', function(stress)
        GPSHUD.UpdateStatus({
            stress = stress
        })
    end)
    
    -- Money updates (for potential future integration)
    RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, newAmount)
        if HUD and HUD.Debug then
            HUD.Debug(string.format("Money change: %s %s (new: %s)", type, amount, newAmount), "GPS", "INFO")
        end
    end)
    
    -- Vehicle events (for potential future integration)
    RegisterNetEvent('QBCore:Client:VehicleInfo', function(info)
        -- Could be used for vehicle-specific GPS HUD features
    end)
end

-- ================================================================
-- USER INTERACTIONS
-- ================================================================

function GPSHUD.HandleStatusIconClick(statusType)
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Status icon clicked: %s", statusType), "GPS", "INFO")
    end
    
    -- Handle different status icon clicks
    if statusType == 'voice' then
        -- 🎤 Cycle through voice levels
        local currentLevel = GPSHUD.Status.voice.level
        local newLevel = currentLevel >= 4 and 1 or currentLevel + 1
        
        -- Trigger voice level change via pma-voice
        if GetResourceState('pma-voice'):find('start') then
            exports['pma-voice']:setVoiceProperty("radioEnabled", true)
            -- Note: Actual voice level change needs to be handled by pma-voice commands
        end
        
        QBCore.Functions.Notify(string.format('Voice Level: %d', newLevel), 'primary')
        
    elseif statusType == 'health' then
        -- ❤️ Health info
        local health = GPSHUD.Status.health
        local status = health > 75 and "Excellent" or health > 50 and "Good" or health > 25 and "Fair" or "Critical"
        QBCore.Functions.Notify(string.format('Health: %d%% (%s)', health, status), health > 50 and 'success' or health > 25 and 'primary' or 'error')
        
    elseif statusType == 'armor' then
        -- 🛡️ Armor info
        local armor = GPSHUD.Status.armor
        if armor > 0 then
            QBCore.Functions.Notify(string.format('Armor: %d%%', armor), 'primary')
        else
            QBCore.Functions.Notify('No armor equipped', 'error')
        end
        
    elseif statusType == 'hunger' then
        -- 🍔 Hunger info
        local hunger = GPSHUD.Status.hunger
        local status = hunger > 75 and "Well Fed" or hunger > 50 and "Satisfied" or hunger > 25 and "Hungry" or "Starving"
        QBCore.Functions.Notify(string.format('Hunger: %d%% (%s)', hunger, status), hunger > 25 and 'success' or 'error')
        
    elseif statusType == 'thirst' then
        -- 💧 Thirst info
        local thirst = GPSHUD.Status.thirst
        local status = thirst > 75 and "Hydrated" or thirst > 50 and "Refreshed" or thirst > 25 and "Thirsty" or "Dehydrated"
        QBCore.Functions.Notify(string.format('Thirst: %d%% (%s)', thirst, status), thirst > 25 and 'success' or 'error')
        
    elseif statusType == 'stress' then
        -- 🧠 Stress info
        local stress = GPSHUD.Status.stress
        local status = stress < 25 and "Relaxed" or stress < 50 and "Mild" or stress < 75 and "Stressed" or "Critical"
        QBCore.Functions.Notify(string.format('Stress: %d%% (%s)', stress, status), stress < 50 and 'success' or stress < 75 and 'primary' or 'error')
        
    elseif statusType == 'stamina' then
        -- 🏃 Stamina info
        local stamina = GPSHUD.Status.stamina
        local status = stamina > 75 and "Energetic" or stamina > 50 and "Active" or stamina > 25 and "Tired" or "Exhausted"
        QBCore.Functions.Notify(string.format('Stamina: %d%% (%s)', stamina, status), stamina > 25 and 'success' or 'error')
    end
end

function GPSHUD.HandleSettingsAction(data)
    if data.action == 'getSettings' then
        -- Return current settings
        GPSHUD.SendNUIMessage('settingsData', {
            theme = Config.Theme.current,
            gpsEnabled = GPSHUD.Enabled,
            components = Config.GPSHUD.components
        })
        
    elseif data.action == 'saveSettings' then
        -- Save settings (implement as needed)
        if HUD and HUD.Debug then
            HUD.Debug("Settings saved", "GPS", "INFO")
        end
        
    elseif data.action == 'resetSettings' then
        -- Reset to defaults
        GPSHUD.SetTheme('neon-magenta')
        if HUD and HUD.Debug then
            HUD.Debug("Settings reset to defaults", "GPS", "INFO")
        end
    end
end

-- ================================================================
-- THEME SYSTEM
-- ================================================================

function GPSHUD.SetTheme(theme)
    if not theme or not Config.Theme.colors[theme] then
        theme = 'neon-magenta'
    end
    
    GPSHUD.SendNUIMessage('updateTheme', { theme = theme })
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("GPS HUD theme changed to: %s", theme), "GPS", "INFO")
    end
end

function GPSHUD.SetPosition(position)
    GPSHUD.SendNUIMessage('updatePosition', { position = position })
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("GPS HUD position changed to: %s", position), "GPS", "INFO")
    end
end

function GPSHUD.SetPerformanceMode(enabled)
    GPSHUD.SendNUIMessage('setPerformanceMode', { enabled = enabled })
    
    if enabled then
        GPSHUD.UpdateInterval = 500 -- Slower updates
    else
        GPSHUD.UpdateInterval = Config.GPSHUD.updateInterval or 200
    end
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("GPS HUD performance mode: %s", enabled and "ENABLED" or "DISABLED"), "GPS", "INFO")
    end
end

-- ================================================================
-- EXPORTS
-- ================================================================

-- Show/Hide GPS HUD
exports('ShowGPSHUD', GPSHUD.Show)
exports('HideGPSHUD', GPSHUD.Hide)
exports('ToggleGPSHUD', GPSHUD.Toggle)

-- Update functions
exports('UpdateGPSStatus', GPSHUD.UpdateStatus)
exports('UpdateGPSVoice', GPSHUD.UpdateVoice)
exports('UpdateGPSLocation', GPSHUD.UpdateLocation)
exports('ForceGPSUpdate', GPSHUD.ForceUpdate)

-- Theme and settings
exports('SetGPSTheme', GPSHUD.SetTheme)
exports('SetGPSPosition', GPSHUD.SetPosition)
exports('SetGPSPerformanceMode', GPSHUD.SetPerformanceMode)

-- Get status
exports('GetGPSHUDStatus', function()
    return GPSHUD.Status
end)

exports('GetGPSHUDPerformance', function()
    return GPSHUD.Performance
end)

-- ================================================================
-- COMMANDS (Debug)
-- ================================================================

if Config.Debug then
    RegisterCommand('gpshudtest', function(source, args)
        if args[1] == 'voice' then
            -- Test voice levels
            for i = 1, 4 do
                GPSHUD.UpdateVoice({ level = i, talking = i == 2 })
                Wait(1000)
            end
            
        elseif args[1] == 'status' then
            -- Test all status values
            GPSHUD.UpdateStatus({
                health = math.random(20, 100),
                armor = math.random(0, 100),
                hunger = math.random(20, 100),
                thirst = math.random(20, 100),
                stress = math.random(0, 80),
                stamina = math.random(20, 100)
            })
            
        elseif args[1] == 'location' then
            -- Test location update
            GPSHUD.UpdateLocation({
                name = "Test Location",
                street = "Test Street",
                direction = math.random(0, 360),
                distance = math.random(0, 50) / 10
            })
            
        else
            print("^3GPS HUD Test Commands:^7")
            print("^7/gpshudtest voice - Test voice indicators")
            print("^7/gpshudtest status - Test status values")
            print("^7/gpshudtest location - Test location display")
        end
    end, false)
end

-- ================================================================
-- INITIALIZATION
-- ================================================================

-- Register with HUD system
if HUD and HUD.RegisterModule then
    HUD.RegisterModule('gps_hud', GPSHUD)
end

if HUD and HUD.Debug then
    HUD.Debug("GPS HUD module loaded (MAIN INTERFACE)", "GPS", "INFO")
end
-- ================================================================
-- QBCore HUD - GPS HUD Client Module (HAUPT-INTERFACE) - COMPLETE
-- Version: 3.0.0
-- Description: Hauptinterface mit GPS, Navigation und allen Status-Werten
--              🎤 Mikrofon | ❤️ Leben | 🍔 Essen | 💧 Durst | 🧠 Stress | 🏃 Ausdauer
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- GPS HUD System (HAUPT-INTERFACE)
GPSHUD = GPSHUD or {}
GPSHUD.Initialized = false
GPSHUD.Enabled = true
GPSHUD.Visible = true
GPSHUD.LastUpdate = 0
GPSHUD.UpdateInterval = Config.GPSHUD.updateInterval or 200

-- Status Cache für alle Werte (ZENTRALER STATUS-SPEICHER)
GPSHUD.Status = {
    -- 🎤 Voice System (Mikrofon) - pma-voice Integration
    voice = {
        level = 2,              -- Voice level 1-4 (Whisper, Normal, Shouting, Screaming)
        talking = false,        -- Aktuell am sprechen
        radioActive = false,    -- Radio aktiv
        radioChannel = 0,       -- Radio Kanal (0 = kein Radio)
        muted = false,          -- Stumm geschaltet
        proximity = 'normal',   -- Proximity level ('whisper', 'normal', 'shouting', 'screaming')
        radioTalking = false    -- Am Radio sprechen
    },
    
    -- Biometrics (Alle Lebenswerte für GPS HUD Icons)
    health = 100,              -- ❤️ Leben (0-100%)
    armor = 0,                 -- 🛡️ Rüstung (0-100%)
    hunger = 100,              -- 🍔 Essen (0-100%)
    thirst = 100,              -- 💧 Durst (0-100%)
    stress = 0,                -- 🧠 Stress (0-100%)
    stamina = 100,             -- 🏃 Ausdauer (0-100%)
    oxygen = 100,              -- 🫁 Sauerstoff (0-100%, nur unter Wasser relevant)
    
    -- Navigation & Location (GPS-System)
    location = {
        name = "Los Santos",     -- Zone name (Vinewood Hills, Downtown, etc.)
        street = "Unknown Street", -- Straßenname
        direction = 0,          -- Kompass-Richtung (0-360°)
        heading = "N",          -- Kompass-Buchstabe (N, NE, E, SE, S, SW, W, NW)
        distance = 0,           -- Entfernung zum Waypoint
        waypoint = false,       -- Hat Waypoint gesetzt
        coords = { x = 0, y = 0, z = 0 } -- Aktuelle Koordinaten
    },
    
    -- Time Display (Zeit-System)
    time = {
        hours = 0,
        minutes = 0,
        formatted = "00:00",    -- Formatierte Zeit-Anzeige
        date = "Monday, January 1st", -- Datum-Anzeige
        is24h = true           -- 24h Format aktiviert
    },
    
    -- Money Display (Geld-Anzeige)
    money = {
        cash = 0,              -- Bargeld
        bank = 0,              -- Bank-Guthaben
        total = 0              -- Gesamt-Vermögen
    },
    
    -- Player Status Flags
    flags = {
        isDead = false,
        isUnconscious = false,
        isBleeding = false,
        isInVehicle = false,
        isSwimming = false,
        isPaused = false,
        isArmed = false,
        hasParachute = false,
        isHandcuffed = false
    }
}

-- Performance Tracking
GPSHUD.Performance = {
    lastVoiceUpdate = 0,
    lastBiometricsUpdate = 0,
    lastLocationUpdate = 0,
    lastTimeUpdate = 0,
    updateCount = 0,
    averageUpdateTime = 0,
    skippedUpdates = 0
}

-- Voice System Integration
GPSHUD.Voice = {
    resource = nil,            -- Voice resource name
    available = false,         -- Voice system available
    lastLevel = 2,            -- Last voice level
    radioResource = nil       -- Radio resource name
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the GPS HUD system (MAIN INTERFACE)
---@return boolean success
function GPSHUD.Init()
    if GPSHUD.Initialized then
        HUD.Debug("GPS HUD already initialized", "GPS_HUD", "WARN")
        return true
    end
    
    if not Config.GPSHUD or not Config.GPSHUD.enabled then
        HUD.Debug("GPS HUD disabled in config", "GPS_HUD", "WARN")
        return false
    end
    
    HUD.Debug("Initializing GPS HUD system (MAIN INTERFACE)...", "GPS_HUD", "INFO")
    
    -- Check and initialize voice system
    GPSHUD.InitializeVoiceSystem()
    
    -- Setup NUI callbacks
    GPSHUD.RegisterNUICallbacks()
    
    -- Register events
    GPSHUD.RegisterEvents()
    
    -- Start update threads
    GPSHUD.StartUpdateThreads()
    
    -- Initialize location system
    GPSHUD.InitializeLocationSystem()
    
    -- Load player data
    GPSHUD.LoadPlayerData()
    
    GPSHUD.Initialized = true
    GPSHUD.Visible = true
    
    HUD.Debug("GPS HUD system initialized successfully", "GPS_HUD", "INFO")
    
    -- Send initial data to NUI
    GPSHUD.SendFullUpdate()
    
    return true
end

---Initialize voice system integration
function GPSHUD.InitializeVoiceSystem()
    -- Check for pma-voice
    if GetResourceState('pma-voice') == 'started' then
        GPSHUD.Voice.resource = 'pma-voice'
        GPSHUD.Voice.available = true
        HUD.Debug("pma-voice detected and integrated", "GPS_HUD", "INFO")
    else
        HUD.Debug("pma-voice not available - voice indicator disabled", "GPS_HUD", "WARN")
    end
    
    -- Check for radio resource
    local radioResources = {'pma-voice', 'rp-radio', 'qb-radio'}
    for _, resource in ipairs(radioResources) do
        if GetResourceState(resource) == 'started' then
            GPSHUD.Voice.radioResource = resource
            HUD.Debug(string.format("Radio resource detected: %s", resource), "GPS_HUD", "INFO")
            break
        end
    end
end

---Initialize location system
function GPSHUD.InitializeLocationSystem()
    -- Enable street name display
    if Config.GPSHUD.components.location then
        CreateThread(function()
            while GPSHUD.Initialized do
                GPSHUD.UpdateLocation()
                Wait(1500) -- Update location every 1.5 seconds
            end
        end)
    end
end

---Load player data on initialization
function GPSHUD.LoadPlayerData()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if PlayerData then
        -- Load money
        if PlayerData.money then
            GPSHUD.Status.money.cash = PlayerData.money.cash or 0
            GPSHUD.Status.money.bank = PlayerData.money.bank or 0
            GPSHUD.Status.money.total = GPSHUD.Status.money.cash + GPSHUD.Status.money.bank
        end
        
        -- Load metadata
        if PlayerData.metadata then
            GPSHUD.Status.hunger = PlayerData.metadata.hunger or 100
            GPSHUD.Status.thirst = PlayerData.metadata.thirst or 100
            GPSHUD.Status.stress = PlayerData.metadata.stress or 0
        end
        
        HUD.Debug("Player data loaded into GPS HUD", "GPS_HUD", "INFO")
    end
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register all GPS HUD events
function GPSHUD.RegisterEvents()
    -- QBCore player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        GPSHUD.LoadPlayerData()
        GPSHUD.SendFullUpdate()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        GPSHUD.SetVisible(false)
    end)
    
    -- Health & needs events
    RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
        GPSHUD.UpdateNeeds(hunger, thirst)
    end)
    
    RegisterNetEvent('hud:client:UpdateStress', function(stress)
        GPSHUD.UpdateStress(stress)
    end)
    
    -- Money events
    RegisterNetEvent('hud:client:UpdateMoney', function(money)
        GPSHUD.UpdateMoney(money)
    end)
    
    RegisterNetEvent('hud:client:OnMoneyChange', function(amount, moneyType, reason)
        GPSHUD.OnMoneyChange(amount, moneyType, reason)
    end)
    
    -- Voice events (pma-voice integration)
    if GPSHUD.Voice.available then
        RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
            GPSHUD.UpdateVoiceLevel(mode)
        end)
        
        RegisterNetEvent('pma-voice:radioActive', function(radioTalking)
            GPSHUD.Status.voice.radioTalking = radioTalking
        end)
    end
    
    -- Player status events
    RegisterNetEvent('hospital:client:Revive', function()
        GPSHUD.OnPlayerRevive()
    end)
    
    RegisterNetEvent('hospital:client:SetLaststand', function()
        GPSHUD.OnPlayerDown()
    end)
    
    -- GPS HUD control events
    RegisterNetEvent('hud:client:toggleGPSHUD', function(visible)
        GPSHUD.SetVisible(visible)
    end)
    
    HUD.Debug("GPS HUD events registered", "GPS_HUD", "INFO")
end

---Register NUI callbacks
function GPSHUD.RegisterNUICallbacks()
    -- Status icon click handlers
    RegisterNUICallback('statusIconClick', function(data, cb)
        GPSHUD.OnStatusIconClick(data.type, data.value)
        cb('ok')
    end)
    
    -- Voice level cycle
    RegisterNUICallback('cycleVoiceLevel', function(data, cb)
        GPSHUD.CycleVoiceLevel()
        cb('ok')
    end)
    
    -- Get detailed status
    RegisterNUICallback('getDetailedStatus', function(data, cb)
        cb(GPSHUD.GetDetailedStatus())
    end)
    
    HUD.Debug("GPS HUD NUI callbacks registered", "GPS_HUD", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM (HAUPT-UPDATE-THREADS)
-- ================================================================

---Start all update threads for GPS HUD
function GPSHUD.StartUpdateThreads()
    -- Main update thread (all biometrics)
    CreateThread(function()
        while GPSHUD.Initialized do
            local currentTime = GetGameTimer()
            
            if currentTime - GPSHUD.LastUpdate >= GPSHUD.UpdateInterval then
                local startTime = GetGameTimer()
                
                -- Update all status values
                GPSHUD.UpdateAllStatus()
                
                -- Send to NUI if changes occurred
                GPSHUD.SendIncrementalUpdate()
                
                -- Performance tracking
                local updateTime = GetGameTimer() - startTime
                GPSHUD.Performance.updateCount = GPSHUD.Performance.updateCount + 1
                GPSHUD.Performance.averageUpdateTime = 
                    (GPSHUD.Performance.averageUpdateTime + updateTime) / 2
                
                GPSHUD.LastUpdate = currentTime
            else
                GPSHUD.Performance.skippedUpdates = GPSHUD.Performance.skippedUpdates + 1
            end
            
            Wait(50) -- Small delay to prevent excessive CPU usage
        end
    end)
    
    -- Voice update thread (faster for responsiveness)
    if GPSHUD.Voice.available then
        CreateThread(function()
            while GPSHUD.Initialized do
                GPSHUD.UpdateVoiceStatus()
                Wait(100) -- Update voice every 100ms for responsiveness
            end
        end)
    end
    
    -- Time update thread
    CreateThread(function()
        while GPSHUD.Initialized do
            GPSHUD.UpdateTime()
            Wait(1000) -- Update time every second
        end
    end)
    
    HUD.Debug("GPS HUD update threads started", "GPS_HUD", "INFO")
end

---Update all status values (ZENTRALE UPDATE-FUNKTION)
function GPSHUD.UpdateAllStatus()
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- ✅ SAFE: Check if player data exists
    if not PlayerData then return end
    
    -- Update basic health values
    local currentHealth = GetEntityHealth(ped)
    GPSHUD.Status.health = currentHealth > 100 and (currentHealth - 100) or 0 -- Convert from 100-200 to 0-100
    GPSHUD.Status.armor = GetPedArmour(ped)
    
    -- Update needs from player metadata
    if PlayerData.metadata then
        GPSHUD.Status.hunger = PlayerData.metadata.hunger or 100
        GPSHUD.Status.thirst = PlayerData.metadata.thirst or 100
        GPSHUD.Status.stress = PlayerData.metadata.stress or 0
    end
    
    -- Update stamina (only when not in vehicle)
    if not IsPedInAnyVehicle(ped, false) then
        GPSHUD.Status.stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    else
        GPSHUD.Status.stamina = 100
    end
    
    -- Update oxygen (only when underwater)
    if IsPedSwimmingUnderWater(ped) then
        GPSHUD.Status.oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
        GPSHUD.Status.flags.isSwimming = true
    else
        GPSHUD.Status.oxygen = 100
        GPSHUD.Status.flags.isSwimming = false
    end
    
    -- Update player flags
    GPSHUD.UpdatePlayerFlags()
    
    -- Update money
    if PlayerData.money then
        GPSHUD.Status.money.cash = PlayerData.money.cash or 0
        GPSHUD.Status.money.bank = PlayerData.money.bank or 0
        GPSHUD.Status.money.total = GPSHUD.Status.money.cash + GPSHUD.Status.money.bank
    end
end

---Update player status flags
function GPSHUD.UpdatePlayerFlags()
    local ped = PlayerPedId()
    
    GPSHUD.Status.flags.isDead = IsEntityDead(ped)
    GPSHUD.Status.flags.isInVehicle = IsPedInAnyVehicle(ped, false)
    GPSHUD.Status.flags.isArmed = IsPedArmed(ped, 7) -- 7 = any weapon
    GPSHUD.Status.flags.hasParachute = GetPedParachuteState(ped) ~= -1
    GPSHUD.Status.flags.isPaused = IsPauseMenuActive()
    
    -- Check if player is unconscious (from metadata)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        GPSHUD.Status.flags.isUnconscious = PlayerData.metadata.ishandcuffed or false
        GPSHUD.Status.flags.isBleeding = (PlayerData.metadata.bleed or 0) > 0
        GPSHUD.Status.flags.isHandcuffed = PlayerData.metadata.ishandcuffed or false
    end
end

---Update voice status (pma-voice integration)
function GPSHUD.UpdateVoiceStatus()
    if not GPSHUD.Voice.available then return end
    
    -- Get voice level from pma-voice
    local voiceLevel = LocalPlayer.state.proximity or {}
    if voiceLevel.distance then
        local distance = voiceLevel.distance
        
        -- Convert distance to level (1-4)
        if distance <= 3.0 then
            GPSHUD.Status.voice.level = 1 -- Whisper
            GPSHUD.Status.voice.proximity = 'whisper'
        elseif distance <= 8.0 then
            GPSHUD.Status.voice.level = 2 -- Normal
            GPSHUD.Status.voice.proximity = 'normal'
        elseif distance <= 15.0 then
            GPSHUD.Status.voice.level = 3 -- Shouting
            GPSHUD.Status.voice.proximity = 'shouting'
        else
            GPSHUD.Status.voice.level = 4 -- Screaming
            GPSHUD.Status.voice.proximity = 'screaming'
        end
    end
    
    -- Get talking state
    GPSHUD.Status.voice.talking = LocalPlayer.state.proximity and LocalPlayer.state.proximity.talking or false
    
    -- Get radio state
    GPSHUD.Status.voice.radioActive = LocalPlayer.state.radioChannel and LocalPlayer.state.radioChannel > 0 or false
    GPSHUD.Status.voice.radioChannel = LocalPlayer.state.radioChannel or 0
    
    GPSHUD.Performance.lastVoiceUpdate = GetGameTimer()
end

---Update location information
function GPSHUD.UpdateLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Update coordinates
    GPSHUD.Status.location.coords = { x = coords.x, y = coords.y, z = coords.z }
    
    -- Get street names
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName1 = GetStreetNameFromHashKey(street1)
    local streetName2 = GetStreetNameFromHashKey(street2)
    
    if streetName2 and streetName2 ~= "" then
        GPSHUD.Status.location.street = streetName1 .. " / " .. streetName2
    else
        GPSHUD.Status.location.street = streetName1
    end
    
    -- Get zone name
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    GPSHUD.Status.location.name = GetLabelText(zone)
    
    -- Get heading/direction
    local heading = GetEntityHeading(ped)
    GPSHUD.Status.location.direction = heading
    GPSHUD.Status.location.heading = GPSHUD.GetCompassDirection(heading)
    
    -- Check for waypoint
    GPSHUD.Status.location.waypoint = IsWaypointActive()
    if GPSHUD.Status.location.waypoint then
        local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
        GPSHUD.Status.location.distance = math.floor(#(coords - waypointCoords))
    else
        GPSHUD.Status.location.distance = 0
    end
    
    GPSHUD.Performance.lastLocationUpdate = GetGameTimer()
end

---Update time display
function GPSHUD.UpdateTime()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    
    GPSHUD.Status.time.hours = hours
    GPSHUD.Status.time.minutes = minutes
    
    -- Format time
    if GPSHUD.Status.time.is24h then
        GPSHUD.Status.time.formatted = string.format("%02d:%02d", hours, minutes)
    else
        local displayHour = hours
        local ampm = "AM"
        
        if hours == 0 then
            displayHour = 12
        elseif hours > 12 then
            displayHour = hours - 12
            ampm = "PM"
        elseif hours == 12 then
            ampm = "PM"
        end
        
        GPSHUD.Status.time.formatted = string.format("%d:%02d %s", displayHour, minutes, ampm)
    end
    
    -- Format date
    local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    local monthNames = {"January", "February", "March", "April", "May", "June", 
                       "July", "August", "September", "October", "November", "December"}
    
    local day = GetClockDayOfWeek()
    local month = GetClockMonth()
    local dayOfMonth = GetClockDayOfMonth()
    
    -- Add ordinal suffix
    local suffix = "th"
    if dayOfMonth % 10 == 1 and dayOfMonth ~= 11 then suffix = "st"
    elseif dayOfMonth % 10 == 2 and dayOfMonth ~= 12 then suffix = "nd"
    elseif dayOfMonth % 10 == 3 and dayOfMonth ~= 13 then suffix = "rd"
    end
    
    GPSHUD.Status.time.date = string.format("%s, %s %d%s", 
                                           dayNames[day + 1], 
                                           monthNames[month + 1], 
                                           dayOfMonth, 
                                           suffix)
    
    GPSHUD.Performance.lastTimeUpdate = GetGameTimer()
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send full update to NUI (all data)
function GPSHUD.SendFullUpdate()
    if not GPSHUD.Visible then return end
    
    SendNUIMessage({
        action = 'updateGPSHUD',
        data = {
            -- Voice system
            voice = GPSHUD.Status.voice,
            
            -- Biometrics
            health = math.max(0, math.min(100, GPSHUD.Status.health)),
            armor = math.max(0, math.min(100, GPSHUD.Status.armor)),
            hunger = math.max(0, math.min(100, GPSHUD.Status.hunger)),
            thirst = math.max(0, math.min(100, GPSHUD.Status.thirst)),
            stress = math.max(0, math.min(100, GPSHUD.Status.stress)),
            stamina = math.max(0, math.min(100, GPSHUD.Status.stamina)),
            oxygen = math.max(0, math.min(100, GPSHUD.Status.oxygen)),
            
            -- Location & Navigation
            location = GPSHUD.Status.location,
            
            -- Time
            time = GPSHUD.Status.time,
            
            -- Money
            money = GPSHUD.Status.money,
            
            -- Flags
            flags = GPSHUD.Status.flags,
            
            -- Configuration
            config = {
                components = Config.GPSHUD.components,
                visual = Config.GPSHUD.visual,
                interaction = Config.GPSHUD.interaction
            }
        }
    })
end

---Send incremental update (only changed values)
function GPSHUD.SendIncrementalUpdate()
    if not GPSHUD.Visible then return end
    
    -- For performance, we'll send full updates at this interval
    -- In a production system, you'd implement change detection
    GPSHUD.SendFullUpdate()
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle needs update from server
---@param hunger number Hunger value
---@param thirst number Thirst value
function GPSHUD.UpdateNeeds(hunger, thirst)
    if type(hunger) == "number" then
        GPSHUD.Status.hunger = math.max(0, math.min(100, hunger))
    end
    
    if type(thirst) == "number" then
        GPSHUD.Status.thirst = math.max(0, math.min(100, thirst))
    end
    
    HUD.Debug(string.format("Needs updated - Hunger: %d, Thirst: %d", 
              GPSHUD.Status.hunger, GPSHUD.Status.thirst), "GPS_HUD", "INFO")
    
    GPSHUD.SendFullUpdate()
end

---Handle stress update from server
---@param stress number Stress value
function GPSHUD.UpdateStress(stress)
    if type(stress) == "number" then
        GPSHUD.Status.stress = math.max(0, math.min(100, stress))
        
        HUD.Debug(string.format("Stress updated: %d", GPSHUD.Status.stress), "GPS_HUD", "INFO")
        GPSHUD.SendFullUpdate()
    end
end

---Handle money update
---@param money table Money data
function GPSHUD.UpdateMoney(money)
    if type(money) == "table" then
        GPSHUD.Status.money.cash = money.cash or GPSHUD.Status.money.cash
        GPSHUD.Status.money.bank = money.bank or GPSHUD.Status.money.bank
        GPSHUD.Status.money.total = GPSHUD.Status.money.cash + GPSHUD.Status.money.bank
        
        GPSHUD.SendFullUpdate()
    end
end

---Handle money change event
---@param amount number Amount changed
---@param moneyType string Type of money ('cash' or 'bank')
---@param reason string Reason for change
function GPSHUD.OnMoneyChange(amount, moneyType, reason)
    if moneyType == 'cash' then
        GPSHUD.Status.money.cash = GPSHUD.Status.money.cash + amount
    elseif moneyType == 'bank' then
        GPSHUD.Status.money.bank = GPSHUD.Status.money.bank + amount
    end
    
    GPSHUD.Status.money.total = GPSHUD.Status.money.cash + GPSHUD.Status.money.bank
    
    -- Show money change notification if configured
    if Config.GPSHUD.visual.showMoneyChanges then
        SendNUIMessage({
            action = 'showMoneyChange',
            amount = amount,
            type = moneyType,
            reason = reason
        })
    end
    
    GPSHUD.SendFullUpdate()
end

---Handle voice level update
---@param mode number Voice mode
function GPSHUD.UpdateVoiceLevel(mode)
    GPSHUD.Status.voice.level = mode or 2
    GPSHUD.Voice.lastLevel = GPSHUD.Status.voice.level
    
    GPSHUD.SendFullUpdate()
end

---Handle player revive
function GPSHUD.OnPlayerRevive()
    GPSHUD.Status.flags.isDead = false
    GPSHUD.Status.flags.isUnconscious = false
    GPSHUD.Status.health = 100
    
    HUD.Debug("Player revived - GPS HUD status reset", "GPS_HUD", "INFO")
    GPSHUD.SendFullUpdate()
end

---Handle player down
function GPSHUD.OnPlayerDown()
    GPSHUD.Status.flags.isUnconscious = true
    
    HUD.Debug("Player down - GPS HUD updated", "GPS_HUD", "INFO")
    GPSHUD.SendFullUpdate()
end

---Handle status icon click
---@param statusType string Type of status clicked
---@param currentValue number Current value
function GPSHUD.OnStatusIconClick(statusType, currentValue)
    if not Config.GPSHUD.interaction.clickableIcons then return end
    
    HUD.Debug(string.format("Status icon clicked: %s (value: %s)", statusType, currentValue), "GPS_HUD", "INFO")
    
    -- Show detailed information
    local message = GPSHUD.GetStatusMessage(statusType, currentValue)
    if message then
        QBCore.Functions.Notify(message, 'primary')
    end
    
    -- Trigger custom event for other resources
    TriggerEvent('hud:client:statusIconClicked', statusType, currentValue, GPSHUD.Status)
end

---Cycle voice level
function GPSHUD.CycleVoiceLevel()
    if not GPSHUD.Voice.available then return end
    
    local currentLevel = GPSHUD.Status.voice.level
    local newLevel = currentLevel + 1
    
    if newLevel > 4 then newLevel = 1 end
    
    -- Trigger voice level change (this depends on your voice system)
    if GPSHUD.Voice.resource == 'pma-voice' then
        exports['pma-voice']:setVoiceProperty('radioEnabled', newLevel > 1)
    end
    
    GPSHUD.Status.voice.level = newLevel
    GPSHUD.SendFullUpdate()
    
    HUD.Debug(string.format("Voice level cycled to: %d", newLevel), "GPS_HUD", "INFO")
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set GPS HUD visibility
---@param visible boolean Visibility state
function GPSHUD.SetVisible(visible)
    GPSHUD.Visible = visible
    
    HUD.Debug(string.format("GPS HUD visibility: %s", visible and "visible" or "hidden"), "GPS_HUD", "INFO")
    
    if visible then
        GPSHUD.SendFullUpdate()
    else
        SendNUIMessage({
            action = 'toggleGPSHUD',
            visible = false
        })
    end
end

---Get GPS HUD visibility
---@return boolean visible
function GPSHUD.IsVisible()
    return GPSHUD.Visible
end

---Get current GPS HUD status
---@return table status
function GPSHUD.GetStatus()
    return GPSHUD.Status
end

---Get detailed status for specific type
---@return table detailedStatus
function GPSHUD.GetDetailedStatus()
    return {
        status = GPSHUD.Status,
        performance = GPSHUD.Performance,
        voice = GPSHUD.Voice,
        config = Config.GPSHUD
    }
end

---Force update GPS HUD
function GPSHUD.ForceUpdate()
    GPSHUD.UpdateAllStatus()
    GPSHUD.UpdateLocation()
    GPSHUD.UpdateTime()
    if GPSHUD.Voice.available then
        GPSHUD.UpdateVoiceStatus()
    end
    GPSHUD.SendFullUpdate()
    
    HUD.Debug("GPS HUD force update completed", "GPS_HUD", "INFO")
end

---Set theme for GPS HUD
---@param theme string Theme name
function GPSHUD.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("GPS HUD theme set to: %s", theme), "GPS_HUD", "INFO")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get compass direction from heading
---@param heading number Heading in degrees
---@return string direction
function GPSHUD.GetCompassDirection(heading)
    local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
    local index = math.floor((heading + 22.5) / 45) % 8
    return directions[index + 1]
end

---Get status message for clicked icon
---@param statusType string Status type
---@param value number Current value
---@return string message
function GPSHUD.GetStatusMessage(statusType, value)
    local messages = {
        health = string.format("Health: %d%% %s", value, value < 25 and "(Critical!)" or ""),
        armor = string.format("Armor: %d%% %s", value, value < 25 and "(Low!)" or ""),
        hunger = string.format("Hunger: %d%% %s", value, value < 25 and "(Hungry!)" or ""),
        thirst = string.format("Thirst: %d%% %s", value, value < 25 and "(Thirsty!)" or ""),
        stress = string.format("Stress: %d%% %s", value, value > 75 and "(High!)" or ""),
        stamina = string.format("Stamina: %d%% %s", value, value < 25 and "(Tired!)" or ""),
        voice = string.format("Voice Level: %d (%s)", GPSHUD.Status.voice.level, GPSHUD.Status.voice.proximity)
    }
    
    return messages[statusType]
end

---Get performance statistics
---@return table performance
function GPSHUD.GetPerformanceStats()
    return {
        initialized = GPSHUD.Initialized,
        visible = GPSHUD.Visible,
        updateInterval = GPSHUD.UpdateInterval,
        updateCount = GPSHUD.Performance.updateCount,
        averageUpdateTime = GPSHUD.Performance.averageUpdateTime,
        skippedUpdates = GPSHUD.Performance.skippedUpdates,
        lastUpdate = GPSHUD.LastUpdate,
        voiceAvailable = GPSHUD.Voice.available,
        voiceResource = GPSHUD.Voice.resource
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function GPSHUD.Cleanup()
    GPSHUD.Initialized = false
    GPSHUD.Visible = false
    
    HUD.Debug("GPS HUD cleaned up", "GPS_HUD", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        GPSHUD.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make GPSHUD available globally
_G.GPSHUD = GPSHUD

HUD.Debug("GPS HUD module loaded (MAIN INTERFACE)", "GPS_HUD", "INFO")
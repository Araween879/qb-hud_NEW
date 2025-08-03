-- ================================================================
-- QBCore HUD - Status System Module
-- Version: 3.0.0
-- Description: Manages voice, radio, armed, parachute, harness, cruise, dev mode
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local Status = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current status values
local voiceLevel = 0
local radioChannel = 0
local isTalking = false
local isRadioActive = false
local isArmed = false
local parachuteState = -1
local hasHarness = false
local harnessHp = 100
local cruiseActive = false
local devMode = false
local vehicleSpeed = 0

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Status module
function Status.Init()
    if isInitialized then
        HUD.Debug("^3Status module already initialized^7", "STATUS")
        return true
    end
    
    HUD.Debug("^2Initializing Status module^7", "STATUS")
    
    -- Register events
    Status.RegisterEvents()
    
    -- Start update thread
    Status.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.status.enabled
    
    isInitialized = true
    HUD.Debug("^2Status module initialized successfully^7", "STATUS")
    
    return true
end

---Register all status-related events
function Status.RegisterEvents()
    -- Voice/Radio events (pma-voice integration)
    AddEventHandler('pma-voice:radioActive', function(radioActive)
        isRadioActive = radioActive
        Status.SendUpdate()
        HUD.Debug(string.format("^2Radio active: %s^7", radioActive and "ON" or "OFF"), "STATUS")
    end)
    
    -- pma-voice talking state
    AddEventHandler('pma-voice:setTalkingMode', function(mode)
        isTalking = mode ~= 1 -- mode 1 = not talking
        Status.SendUpdate()
        HUD.Debug(string.format("^2Talking mode: %d (talking: %s)^7", mode, isTalking and "YES" or "NO"), "STATUS")
    end)
    
    -- pma-voice radio channel updates
    AddEventHandler('pma-voice:radioChannelChanged', function(channel)
        radioChannel = channel or 0
        Status.SendUpdate()
        HUD.Debug(string.format("^2Radio channel changed: %d^7", radioChannel), "STATUS")
    end)
    
    -- Developer mode toggle
    RegisterNetEvent('qb-admin:client:ToggleDevmode', function()
        devMode = not devMode
        Status.SendUpdate()
        HUD.Debug(string.format("^2Dev mode toggled: %s^7", devMode and "ON" or "OFF"), "STATUS")
    end)
    
    -- Vehicle events
    RegisterNetEvent('seatbelt:client:ToggleCruise', function()
        cruiseActive = not cruiseActive
        Status.SendUpdate()
        HUD.Debug(string.format("^2Cruise control: %s^7", cruiseActive and "ON" or "OFF"), "STATUS")
    end)
    
    RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
        if type(harnessHp) == "number" then
            Status.SetValue('harness_hp', harnessHp)
        end
    end)
    
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'status' then
            Status.SetVisible(visible)
        end
    end)
    
    HUD.Debug("^2Status events registered (pma-voice integration)^7", "STATUS")
end

---Start the status update thread
function Status.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Status update thread already running^7", "STATUS")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible then
                Status.UpdateStatus()
            end
            Wait(Config.Modules.status.updateInterval or 200)
        end
    end)
    
    HUD.Debug("^2Status update thread started^7", "STATUS")
end

---Update all status-related values
function Status.UpdateStatus()
    local player = PlayerPedId()
    local playerId = PlayerId()
    if not player or player == 0 then return end
    
    -- Voice system status (pma-voice integration)
    local newVoiceLevel = 0
    if LocalPlayer.state['proximity'] then
        newVoiceLevel = LocalPlayer.state['proximity'].distance or 1
    else
        -- Fallback if pma-voice not available
        newVoiceLevel = 2
    end
    
    -- Radio channel from pma-voice
    local newRadioChannel = 0
    if LocalPlayer.state['radioChannel'] then
        newRadioChannel = LocalPlayer.state['radioChannel']
    end
    
    -- Talking status - combination of NetworkIsPlayerTalking and pma-voice state
    local newTalking = NetworkIsPlayerTalking(playerId) or isTalking
    
    -- Weapon/Armed status
    local weapon = GetSelectedPedWeapon(player)
    local newArmed = false
    if not Config.WhitelistedWeaponArmed[weapon] and weapon ~= `WEAPON_UNARMED` then
        newArmed = true
    end
    
    -- Parachute status
    local newParachuteState = GetPedParachuteState(player)
    
    -- Vehicle status
    local newVehicleSpeed = 0
    if IsPedInAnyVehicle(player, false) then
        local vehicle = GetVehiclePedIsIn(player, false)
        newVehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * (Config.UseMPH and 2.23694 or 3.6))
        
        -- Check for harness
        Status.CheckHarness()
    else
        hasHarness = false
    end
    
    -- Check for significant changes (optimization)
    local voiceChanged = newVoiceLevel ~= voiceLevel
    local radioChanged = newRadioChannel ~= radioChannel or newTalking ~= isTalking
    local armedChanged = newArmed ~= isArmed
    local parachuteChanged = newParachuteState ~= parachuteState
    local speedChanged = math.abs(newVehicleSpeed - vehicleSpeed) > 5
    
    if voiceChanged or radioChanged or armedChanged or parachuteChanged or speedChanged then
        voiceLevel = newVoiceLevel
        radioChannel = newRadioChannel
        isTalking = newTalking
        isArmed = newArmed
        parachuteState = newParachuteState
        vehicleSpeed = newVehicleSpeed
        
        Status.SendUpdate()
    end
end

---Check harness status in vehicle
function Status.CheckHarness()
    local player = PlayerPedId()
    if not IsPedInAnyVehicle(player, false) then 
        hasHarness = false
        return 
    end
    
    -- Check if player has harness item (requires PlayerData)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.items then
        hasHarness = false
        for _, item in pairs(PlayerData.items) do
            if item.name == 'harness' then
                hasHarness = true
                break
            end
        end
    end
end

---Send current status data to NUI
function Status.SendUpdate()
    if not isVisible then return end
    
    local statusData = {
        voice = {
            level = voiceLevel,
            talking = isTalking,
            radioActive = isRadioActive,
            radioChannel = radioChannel
        },
        armed = isArmed,
        parachute = {
            active = parachuteState >= 0,
            state = parachuteState
        },
        harness = {
            active = hasHarness,
            hp = harnessHp
        },
        cruise = cruiseActive,
        devMode = devMode,
        vehicle = {
            speed = vehicleSpeed,
            inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        },
        components = Config.Modules.status.components
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('status', statusData)
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the status module
---@param visible boolean
function Status.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Status visibility set to: %s^7", visible and "visible" or "hidden"), "STATUS")
    
    if visible then
        Status.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('status', { visible = false })
        end
    end
end

---Get current status module visibility
---@return boolean
function Status.IsVisible()
    return isVisible
end

---Get current status data
---@return table
function Status.GetStatus()
    return {
        voiceLevel = voiceLevel,
        radioChannel = radioChannel,
        isTalking = isTalking,
        isRadioActive = isRadioActive,
        isArmed = isArmed,
        parachuteState = parachuteState,
        hasHarness = hasHarness,
        harnessHp = harnessHp,
        cruiseActive = cruiseActive,
        devMode = devMode,
        vehicleSpeed = vehicleSpeed
    }
end

---Force update status display
function Status.ForceUpdate()
    Status.UpdateStatus()
    Status.SendUpdate()
    HUD.Debug("^2Status force update triggered^7", "STATUS")
end

---Set specific status values (for external use)
---@param statusType string Type: 'dev_mode', 'cruise', 'harness_hp', etc.
---@param value any Value to set
function Status.SetValue(statusType, value)
    if statusType == 'dev_mode' then
        devMode = value == true
    elseif statusType == 'cruise' then
        cruiseActive = value == true
    elseif statusType == 'harness_hp' then
        if type(value) == "number" then
            harnessHp = math.max(0, math.min(100, value))
        end
    elseif statusType == 'radio_active' then
        isRadioActive = value == true
    elseif statusType == 'talking' then
        isTalking = value == true
    elseif statusType == 'voice_level' then
        if type(value) == "number" then
            voiceLevel = math.max(1, math.min(4, value))
        end
    else
        HUD.Debug(string.format("^1Unknown status type: %s^7", statusType), "STATUS")
        return false
    end
    
    Status.SendUpdate()
    HUD.Debug(string.format("^2%s set to: %s^7", statusType, tostring(value)), "STATUS")
    return true
end

---Get voice icon based on current state
---@return string
function Status.GetVoiceIcon()
    if radioChannel ~= 0 then
        return "fas fa-headset"
    elseif voiceLevel == 1 then
        return "fas fa-microphone-slash"
    elseif voiceLevel == 2 then
        return "fas fa-microphone"
    elseif voiceLevel == 3 then
        return "fas fa-volume-up"
    elseif voiceLevel == 4 then
        return "fas fa-bullhorn"
    else
        return "fas fa-microphone"
    end
end

---Get voice color based on current state
---@return string
function Status.GetVoiceColor()
    if isRadioActive then
        return "#D64763" -- Red for radio active
    elseif isTalking then
        return "#FFFF3E" -- Yellow for talking
    else
        return "#FFFFFF" -- White for idle
    end
end

-- ================================================================
-- PMA-VOICE SPECIFIC FUNCTIONS
-- ================================================================

---Get pma-voice status information
---@return table
function Status.GetPMAVoiceStatus()
    return {
        available = GetResourceState('pma-voice') == 'started',
        proximity = LocalPlayer.state['proximity'] or { distance = 2 },
        radioChannel = LocalPlayer.state['radioChannel'] or 0,
        talking = isTalking,
        radioActive = isRadioActive
    }
end

---Test pma-voice integration (debug function)
function Status.TestPMAVoiceIntegration()
    if GetResourceState('pma-voice') ~= 'started' then
        HUD.Debug("^1pma-voice is not running!^7", "STATUS")
        return false
    end
    
    local status = Status.GetPMAVoiceStatus()
    HUD.Debug("^3pma-voice Integration Test:^7", "STATUS")
    HUD.Debug(string.format("^2Proximity Distance: %d^7", status.proximity.distance), "STATUS")
    HUD.Debug(string.format("^2Radio Channel: %d^7", status.radioChannel), "STATUS")
    HUD.Debug(string.format("^2Talking: %s^7", status.talking and "YES" or "NO"), "STATUS")
    HUD.Debug(string.format("^2Radio Active: %s^7", status.radioActive and "YES" or "NO"), "STATUS")
    
    return true
end

-- ================================================================
-- VEHICLE-SPECIFIC STATUS UPDATES
-- ================================================================

-- Thread for vehicle-specific status updates
CreateThread(function()
    while true do
        if isInitialized and LocalPlayer.state.isLoggedIn then
            local player = PlayerPedId()
            
            if IsPedInAnyVehicle(player, false) then
                Status.CheckHarness()
                Status.SendUpdate()
            end
        end
        Wait(2000) -- Check every 2 seconds
    end
end)

-- ================================================================
-- PMA-VOICE COMPATIBILITY FALLBACK
-- ================================================================

-- Fallback thread if pma-voice events are not firing
CreateThread(function()
    while true do
        if isInitialized and LocalPlayer.state.isLoggedIn then
            -- Check if pma-voice is available
            if GetResourceState('pma-voice') == 'started' then
                -- Update voice level from LocalPlayer state
                if LocalPlayer.state['proximity'] then
                    local newLevel = LocalPlayer.state['proximity'].distance or 2
                    if newLevel ~= voiceLevel then
                        voiceLevel = newLevel
                        Status.SendUpdate()
                    end
                end
                
                -- Update radio channel from LocalPlayer state
                if LocalPlayer.state['radioChannel'] then
                    local newChannel = LocalPlayer.state['radioChannel']
                    if newChannel ~= radioChannel then
                        radioChannel = newChannel
                        Status.SendUpdate()
                    end
                end
                
                -- Update talking status
                local newTalking = NetworkIsPlayerTalking(PlayerId())
                if newTalking ~= isTalking then
                    isTalking = newTalking
                    Status.SendUpdate()
                end
            else
                -- pma-voice not available - use defaults
                if voiceLevel == 0 then
                    voiceLevel = 2 -- Default to normal voice
                    Status.SendUpdate()
                end
            end
        end
        
        Wait(1000) -- Check every second
    end
end)

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('status', Status)
end

-- Export Status functions for external use
_G.Status = Status

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Status module shutting down^7", "STATUS")
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)

-- Debug command for pma-voice testing
if Config.Debug then
    RegisterCommand('testpmavoice', function()
        Status.TestPMAVoiceIntegration()
    end, false)
end
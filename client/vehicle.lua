-- ================================================================
-- QBCore HUD - Vehicle System Module
-- Version: 3.0.0
-- Description: Speedometer, fuel, engine, seatbelt, cruise, nitro, altitude
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local Vehicle = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current vehicle values
local currentSpeed = 0
local currentFuel = 100
local currentEngine = 1000
local currentNitro = 0
local currentAltitude = 0
local seatbeltOn = false
local cruiseActive = false
local inVehicle = false
local vehicleClass = -1

-- State tracking
local lastVehicle = nil
local lastUpdate = 0

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Vehicle module
function Vehicle.Init()
    if isInitialized then
        HUD.Debug("^3Vehicle module already initialized^7", "VEHICLE")
        return true
    end
    
    HUD.Debug("^2Initializing Vehicle module^7", "VEHICLE")
    
    -- Register events
    Vehicle.RegisterEvents()
    
    -- Start update thread
    Vehicle.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.vehicle.enabled
    
    isInitialized = true
    HUD.Debug("^2Vehicle module initialized successfully^7", "VEHICLE")
    
    return true
end

---Register all vehicle-related events
function Vehicle.RegisterEvents()
    -- Seatbelt events
    RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
        seatbeltOn = not seatbeltOn
        Vehicle.SendUpdate()
        HUD.Debug(string.format("^2Seatbelt: %s^7", seatbeltOn and "ON" or "OFF"), "VEHICLE")
    end)
    
    -- Cruise control events
    RegisterNetEvent('seatbelt:client:ToggleCruise', function()
        cruiseActive = not cruiseActive
        Vehicle.SendUpdate()
        HUD.Debug(string.format("^2Cruise control: %s^7", cruiseActive and "ON" or "OFF"), "VEHICLE")
    end)
    
    -- Nitro events (if available)
    RegisterNetEvent('hud:client:UpdateNitrous', function(nitroLevel)
        if type(nitroLevel) == "number" then
            currentNitro = math.max(0, math.min(100, nitroLevel))
            Vehicle.SendUpdate()
        end
    end)
    
    -- Manual fuel update event
    RegisterNetEvent('hud:client:UpdateFuel', function(fuelLevel)
        if type(fuelLevel) == "number" then
            currentFuel = math.max(0, math.min(100, fuelLevel))
            Vehicle.SendUpdate()
        end
    end)
    
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'vehicle' then
            Vehicle.SetVisible(visible)
        end
    end)
    
    HUD.Debug("^2Vehicle events registered^7", "VEHICLE")
end

---Start the vehicle update thread
function Vehicle.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Vehicle update thread already running^7", "VEHICLE")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible then
                Vehicle.UpdateStatus()
            end
            Wait(Config.Modules.vehicle.updateInterval or 200)
        end
    end)
    
    HUD.Debug("^2Vehicle update thread started^7", "VEHICLE")
end

---Update all vehicle-related status values
function Vehicle.UpdateStatus()
    local player = PlayerPedId()
    if not player or player == 0 then return end
    
    local vehicle = GetVehiclePedIsIn(player, false)
    local newInVehicle = vehicle ~= 0
    
    -- Early exit if not in vehicle and was not in vehicle before
    if not newInVehicle and not inVehicle then
        return
    end
    
    -- Vehicle state changed
    if newInVehicle ~= inVehicle then
        inVehicle = newInVehicle
        lastVehicle = newInVehicle and vehicle or nil
        
        if not newInVehicle then
            -- Just exited vehicle - hide vehicle HUD
            if UIManager and UIManager.UpdateModule then
                UIManager.UpdateModule('vehicle', { visible = false, inVehicle = false })
            end
            return
        end
    end
    
    -- Not in vehicle - skip updates
    if not inVehicle or not vehicle or vehicle == 0 then
        return
    end
    
    -- Get vehicle class for specific handling
    vehicleClass = GetVehicleClass(vehicle)
    
    -- Speed calculation
    local speed = GetEntitySpeed(vehicle)
    local newSpeed = math.ceil(speed * (Config.Modules.vehicle.useMPH and 2.23694 or 3.6))
    
    -- Engine health (0-1000 normalized to 0-100)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local newEngine = math.max(0, math.min(100, (engineHealth / 1000) * 100))
    
    -- Fuel level (try different fuel systems)
    local newFuel = Vehicle.GetFuelLevel(vehicle)
    
    -- Altitude (for aircraft)
    local newAltitude = 0
    if vehicleClass == 15 or vehicleClass == 16 then -- Helicopters or Planes
        local coords = GetEntityCoords(vehicle)
        newAltitude = math.ceil(coords.z)
    end
    
    -- Nitro level (if available)
    local newNitro = Vehicle.GetNitroLevel(vehicle)
    
    -- Check for significant changes (optimization)
    local speedChanged = math.abs(newSpeed - currentSpeed) > 2
    local fuelChanged = math.abs(newFuel - currentFuel) > 1
    local engineChanged = math.abs(newEngine - currentEngine) > 5
    local altitudeChanged = math.abs(newAltitude - currentAltitude) > 5
    local nitroChanged = math.abs(newNitro - currentNitro) > 1
    
    -- Throttle updates (max 5 per second)
    local currentTime = GetGameTimer()
    if currentTime - lastUpdate < 200 and not (speedChanged or fuelChanged or engineChanged or altitudeChanged or nitroChanged) then
        return
    end
    
    if speedChanged or fuelChanged or engineChanged or altitudeChanged or nitroChanged or currentTime - lastUpdate > 1000 then
        currentSpeed = newSpeed
        currentFuel = newFuel
        currentEngine = newEngine
        currentAltitude = newAltitude
        currentNitro = newNitro
        lastUpdate = currentTime
        
        Vehicle.SendUpdate()
    end
end

---Get fuel level from various fuel systems
---@param vehicle number Vehicle entity
---@return number Fuel level (0-100)
function Vehicle.GetFuelLevel(vehicle)
    if not vehicle or vehicle == 0 then return 100 end
    
    -- Try LegacyFuel first
    if GetResourceState('LegacyFuel') == 'started' then
        local fuel = exports['LegacyFuel']:GetFuel(vehicle)
        if fuel then return math.max(0, math.min(100, fuel)) end
    end
    
    -- Try ps-fuel
    if GetResourceState('ps-fuel') == 'started' then
        local fuel = exports['ps-fuel']:GetFuel(vehicle)
        if fuel then return math.max(0, math.min(100, fuel)) end
    end
    
    -- Try okokGasStation
    if GetResourceState('okokGasStation') == 'started' then
        local fuel = exports['okokGasStation']:GetFuel(vehicle)
        if fuel then return math.max(0, math.min(100, fuel)) end
    end
    
    -- Fallback to native (always 100 unless manually set)
    local fuel = GetVehicleFuelLevel(vehicle)
    if fuel > 0 then
        return math.max(0, math.min(100, fuel))
    end
    
    -- Default fallback
    return 100
end

---Get nitro level (if nitro system available)
---@param vehicle number Vehicle entity
---@return number Nitro level (0-100)
function Vehicle.GetNitroLevel(vehicle)
    if not vehicle or vehicle == 0 then return 0 end
    
    -- Try various nitro systems
    if GetResourceState('qb-nitro') == 'started' then
        -- QBCore nitro system
        return 0 -- Implement based on your nitro system
    end
    
    if GetResourceState('nkn_carnitro') == 'started' then
        -- NKN Nitro system
        return 0 -- Implement based on your nitro system
    end
    
    return currentNitro -- Return current cached value
end

---Send current vehicle data to NUI
function Vehicle.SendUpdate()
    if not isVisible or not inVehicle then return end
    
    local vehicleData = {
        inVehicle = inVehicle,
        speed = currentSpeed,
        fuel = currentFuel,
        engine = currentEngine,
        nitro = currentNitro,
        altitude = currentAltitude,
        seatbelt = seatbeltOn,
        cruise = cruiseActive,
        vehicleClass = vehicleClass,
        isAircraft = vehicleClass == 15 or vehicleClass == 16,
        useMPH = Config.Modules.vehicle.useMPH or true,
        components = Config.Modules.vehicle.components or {
            speedometer = true,
            fuel = true,
            engine = true,
            seatbelt = true,
            cruise = true,
            nitro = true,
            altitude = true
        }
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('vehicle', vehicleData)
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the vehicle module
---@param visible boolean
function Vehicle.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Vehicle visibility set to: %s^7", visible and "visible" or "hidden"), "VEHICLE")
    
    if visible and inVehicle then
        Vehicle.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('vehicle', { visible = false })
        end
    end
end

---Get current vehicle module visibility
---@return boolean
function Vehicle.IsVisible()
    return isVisible
end

---Get current vehicle data
---@return table
function Vehicle.GetVehicleData()
    return {
        inVehicle = inVehicle,
        speed = currentSpeed,
        fuel = currentFuel,
        engine = currentEngine,
        nitro = currentNitro,
        altitude = currentAltitude,
        seatbelt = seatbeltOn,
        cruise = cruiseActive,
        vehicleClass = vehicleClass
    }
end

---Force update vehicle display
function Vehicle.ForceUpdate()
    Vehicle.UpdateStatus()
    Vehicle.SendUpdate()
    HUD.Debug("^2Vehicle force update triggered^7", "VEHICLE")
end

---Set specific vehicle values (for external use)
---@param valueType string Type: 'fuel', 'nitro', 'seatbelt', 'cruise'
---@param value any Value to set
function Vehicle.SetValue(valueType, value)
    if valueType == 'fuel' then
        if type(value) == "number" then
            currentFuel = math.max(0, math.min(100, value))
        end
    elseif valueType == 'nitro' then
        if type(value) == "number" then
            currentNitro = math.max(0, math.min(100, value))
        end
    elseif valueType == 'seatbelt' then
        seatbeltOn = value == true
    elseif valueType == 'cruise' then
        cruiseActive = value == true
    else
        HUD.Debug(string.format("^1Unknown vehicle value type: %s^7", valueType), "VEHICLE")
        return false
    end
    
    Vehicle.SendUpdate()
    HUD.Debug(string.format("^2%s set to: %s^7", valueType, tostring(value)), "VEHICLE")
    return true
end

---Get speed in specified unit
---@param useMPH boolean Use MPH instead of KPH (optional)
---@return number Speed value
function Vehicle.GetSpeed(useMPH)
    if useMPH == nil then useMPH = Config.Modules.vehicle.useMPH end
    
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    
    if vehicle and vehicle ~= 0 then
        local speed = GetEntitySpeed(vehicle)
        return math.ceil(speed * (useMPH and 2.23694 or 3.6))
    end
    
    return 0
end

---Check if player is in specific vehicle type
---@param vehicleType string Type: 'car', 'bike', 'aircraft', 'boat'
---@return boolean
function Vehicle.IsInVehicleType(vehicleType)
    if not inVehicle then return false end
    
    if vehicleType == 'car' then
        return vehicleClass >= 0 and vehicleClass <= 12
    elseif vehicleType == 'bike' then
        return vehicleClass == 8 or vehicleClass == 13
    elseif vehicleType == 'aircraft' then
        return vehicleClass == 15 or vehicleClass == 16
    elseif vehicleType == 'boat' then
        return vehicleClass == 14
    end
    
    return false
end

-- ================================================================
-- LOW FUEL WARNING SYSTEM
-- ================================================================

CreateThread(function()
    local lastWarning = 0
    
    while isInitialized do
        if inVehicle and Config.Modules.vehicle.showFuelGauge then
            -- Low fuel warning
            if currentFuel <= 20 and currentFuel > 0 then
                local currentTime = GetGameTimer()
                
                -- Warn every 30 seconds when fuel is low
                if currentTime - lastWarning > 30000 then
                    if currentFuel <= 10 then
                        QBCore.Functions.Notify('Fuel critically low! Find a gas station immediately!', 'error')
                    else
                        QBCore.Functions.Notify('Fuel is running low. Consider refueling soon.', 'primary')
                    end
                    lastWarning = currentTime
                end
            end
        end
        
        Wait(5000) -- Check every 5 seconds
    end
end)

-- ================================================================
-- VEHICLE PERFORMANCE MONITORING
-- ================================================================

CreateThread(function()
    while isInitialized do
        if inVehicle and currentEngine < 50 then
            local player = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(player, false)
            
            if vehicle and vehicle ~= 0 then
                -- Engine damage effects
                if currentEngine < 25 then
                    -- Critical engine damage - random stalling
                    if math.random(1, 100) <= 2 then -- 2% chance per check
                        SetVehicleEngineOn(vehicle, false, true, true)
                        QBCore.Functions.Notify('Engine stalled due to damage!', 'error')
                    end
                end
            end
        end
        
        Wait(5000)
    end
end)

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('vehicle', Vehicle)
end

-- Export Vehicle functions for external use
_G.Vehicle = Vehicle

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Vehicle module shutting down^7", "VEHICLE")
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)
-- ================================================================
-- QBCore HUD - Vehicle HUD System Module
-- Version: 3.0.0
-- Description: Complete vehicle interface with speed, fuel, engine health, etc.
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Vehicle HUD System Module
Vehicle = Vehicle or {}
Vehicle.Initialized = false
Vehicle.Visible = false
Vehicle.LastUpdate = 0
Vehicle.UpdateInterval = Config.Modules.vehicle.updateInterval or 200

-- Vehicle Status Data
Vehicle.Status = {
    -- Basic vehicle info
    inVehicle = false,
    vehicleHandle = 0,              -- Vehicle entity handle
    vehicleModel = "",              -- Vehicle model name
    vehicleClass = 0,               -- Vehicle class
    
    -- Speed & Motion
    speed = {
        current = 0,                -- Current speed
        max = 0,                    -- Max speed for this vehicle
        display = "0",              -- Formatted speed display
        unit = "MPH"                -- Speed unit (MPH/KPH)
    },
    
    -- Engine & Performance
    engine = {
        health = 100,               -- Engine health (0-100%)
        temperature = 90,           -- Engine temperature
        rpm = 0,                    -- RPM (0-1.0)
        running = false,            -- Engine running state
        damage = 0                  -- Engine damage level
    },
    
    -- Fuel System
    fuel = {
        level = 100,                -- Fuel level (0-100%)
        capacity = 65,              -- Tank capacity in liters
        consumption = 0,            -- Fuel consumption rate
        range = 0,                  -- Estimated range in km
        available = false           -- Fuel system available
    },
    
    -- Transmission
    transmission = {
        gear = 0,                   -- Current gear (-1=R, 0=N, 1+=Drive)
        gearDisplay = "P",          -- Gear display (P, R, N, D, 1, 2, etc.)
        automatic = true,           -- Automatic transmission
        clutch = 1.0               -- Clutch state (manual only)
    },
    
    -- Vehicle Systems
    systems = {
        seatbelt = false,           -- Seatbelt status
        cruise = false,             -- Cruise control active
        handbrake = false,          -- Handbrake engaged
        lights = false,             -- Lights on
        highbeams = false,          -- High beams on
        indicators = {              -- Turn indicators
            left = false,
            right = false,
            hazards = false
        }
    },
    
    -- Special Systems
    special = {
        nitro = {                   -- Nitro system
            available = false,
            level = 0,
            active = false
        },
        harness = {                 -- Racing harness
            available = false,
            equipped = false,
            health = 100
        },
        hydraulics = {              -- Hydraulics system
            available = false,
            active = false
        }
    },
    
    -- Vehicle Position
    position = {
        altitude = 0,               -- Altitude in meters
        coordinates = { x = 0, y = 0, z = 0 },
        onGround = true,            -- Vehicle on ground
        submerged = false           -- Vehicle underwater
    },
    
    -- Damage Information
    damage = {
        overall = 0,                -- Overall damage (0-100%)
        engine = 0,                 -- Engine damage
        body = 0,                   -- Body damage
        petrolTank = 0,             -- Fuel tank damage
        wheels = {}                 -- Individual wheel damage
    }
}

-- Vehicle System Integration
Vehicle.Systems = {
    fuel = {
        resource = nil,             -- Fuel resource name
        available = false           -- Fuel system available
    },
    seatbelt = {
        resource = nil,             -- Seatbelt resource name
        available = false           -- Seatbelt system available
    },
    nitro = {
        resource = nil,             -- Nitro resource name
        available = false           -- Nitro system available
    },
    harness = {
        resource = nil,             -- Harness resource name
        available = false           -- Harness system available
    }
}

-- Performance tracking
Vehicle.Performance = {
    updateCount = 0,
    averageUpdateTime = 0,
    skippedUpdates = 0,
    vehicleChanges = 0
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Vehicle module
---@return boolean success
function Vehicle.Init()
    if Vehicle.Initialized then
        HUD.Debug("Vehicle module already initialized", "VEHICLE", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Vehicle module...", "VEHICLE", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.vehicle.enabled then
        HUD.Debug("Vehicle module disabled in config", "VEHICLE", "INFO")
        return false
    end
    
    -- Load configuration
    Vehicle.LoadConfiguration()
    
    -- Initialize vehicle systems
    Vehicle.InitializeSystems()
    
    -- Register events
    Vehicle.RegisterEvents()
    
    -- Register NUI callbacks
    Vehicle.RegisterNUICallbacks()
    
    -- Start update thread
    Vehicle.StartUpdateThread()
    
    Vehicle.Initialized = true
    HUD.Debug("Vehicle module initialized successfully", "VEHICLE", "INFO")
    
    return true
end

---Load Vehicle module configuration
function Vehicle.LoadConfiguration()
    local config = Config.Modules.vehicle or {}
    
    Vehicle.Status.speed.unit = config.useMPH and "MPH" or "KPH"
    Vehicle.UpdateInterval = config.updateInterval or 200
    
    -- Load component settings
    local components = config.components or {}
    Vehicle.Components = {
        speed = components.speed or true,
        fuel = components.fuel or true,
        engine = components.engine or true,
        altitude = components.altitude or true,
        gear = components.gear or false,
        rpm = components.rpm or false,
        nitro = components.nitro or false,
        seatbelt = components.seatbelt or true,
        cruise = components.cruise or true
    }
    
    HUD.Debug("Vehicle configuration loaded", "VEHICLE", "INFO")
end

---Initialize vehicle systems integration
function Vehicle.InitializeSystems()
    -- Check for fuel systems
    local fuelResources = {'LegacyFuel', 'ps-fuel', 'ox_fuel', 'cdn-fuel'}
    for _, resource in ipairs(fuelResources) do
        if GetResourceState(resource) == 'started' then
            Vehicle.Systems.fuel.resource = resource
            Vehicle.Systems.fuel.available = true
            Vehicle.Status.fuel.available = true
            HUD.Debug(string.format("Fuel resource detected: %s", resource), "VEHICLE", "INFO")
            break
        end
    end
    
    -- Check for seatbelt systems
    local seatbeltResources = {'seatbelt', 'qb-smallresources'}
    for _, resource in ipairs(seatbeltResources) do
        if GetResourceState(resource) == 'started' then
            Vehicle.Systems.seatbelt.resource = resource
            Vehicle.Systems.seatbelt.available = true
            HUD.Debug(string.format("Seatbelt resource detected: %s", resource), "VEHICLE", "INFO")
            break
        end
    end
    
    -- Check for nitro systems
    local nitroResources = {'SL-Nitro', 'qb-nitro', 'ps-nitro'}
    for _, resource in ipairs(nitroResources) do
        if GetResourceState(resource) == 'started' then
            Vehicle.Systems.nitro.resource = resource
            Vehicle.Systems.nitro.available = true
            Vehicle.Status.special.nitro.available = true
            HUD.Debug(string.format("Nitro resource detected: %s", resource), "VEHICLE", "INFO")
            break
        end
    end
    
    -- Check for harness systems
    local harnessResources = {'qb-racing', 'ps-racing'}
    for _, resource in ipairs(harnessResources) do
        if GetResourceState(resource) == 'started' then
            Vehicle.Systems.harness.resource = resource
            Vehicle.Systems.harness.available = true
            Vehicle.Status.special.harness.available = true
            HUD.Debug(string.format("Harness resource detected: %s", resource), "VEHICLE", "INFO")
            break
        end
    end
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register Vehicle module events
function Vehicle.RegisterEvents()
    -- Player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Vehicle.CheckVehicleState()
    end)
    
    -- Vehicle events
    RegisterNetEvent('hud:client:toggleVehicleHUD', function(visible)
        Vehicle.SetVisible(visible)
    end)
    
    -- Seatbelt events
    RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
        Vehicle.ToggleSeatbelt()
    end)
    
    RegisterNetEvent('seatbelt:client:ToggleCruise', function()
        Vehicle.ToggleCruise()
    end)
    
    -- Fuel events
    if Vehicle.Systems.fuel.available then
        RegisterNetEvent('fuel:client:UpdateFuel', function(fuel)
            Vehicle.UpdateFuel(fuel)
        end)
    end
    
    -- Nitro events
    if Vehicle.Systems.nitro.available then
        RegisterNetEvent('nitro:client:UpdateNitro', function(nitro)
            Vehicle.UpdateNitro(nitro)
        end)
        
        RegisterNetEvent('nitro:client:ActivateNitro', function()
            Vehicle.Status.special.nitro.active = true
        end)
        
        RegisterNetEvent('nitro:client:DeactivateNitro', function()
            Vehicle.Status.special.nitro.active = false
        end)
    end
    
    -- Harness events
    if Vehicle.Systems.harness.available then
        RegisterNetEvent('harness:client:UpdateHarness', function(data)
            Vehicle.UpdateHarness(data)
        end)
    end
    
    HUD.Debug("Vehicle events registered", "VEHICLE", "INFO")
end

---Register NUI callbacks
function Vehicle.RegisterNUICallbacks()
    RegisterNUICallback('vehicleClick', function(data, cb)
        Vehicle.OnVehicleClick(data.component)
        cb('ok')
    end)
    
    RegisterNUICallback('toggleSeatbelt', function(data, cb)
        Vehicle.ToggleSeatbelt()
        cb('ok')
    end)
    
    RegisterNUICallback('toggleCruise', function(data, cb)
        Vehicle.ToggleCruise()
        cb('ok')
    end)
    
    RegisterNUICallback('getVehicleDetails', function(data, cb)
        cb(Vehicle.GetDetailedStatus())
    end)
    
    HUD.Debug("Vehicle NUI callbacks registered", "VEHICLE", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM
-- ================================================================

---Start the vehicle update thread
function Vehicle.StartUpdateThread()
    CreateThread(function()
        while Vehicle.Initialized do
            local currentTime = GetGameTimer()
            
            -- Check vehicle state first
            Vehicle.CheckVehicleState()
            
            if Vehicle.Status.inVehicle and currentTime - Vehicle.LastUpdate >= Vehicle.UpdateInterval then
                local startTime = GetGameTimer()
                
                Vehicle.UpdateVehicleStatus()
                Vehicle.SendToNUI()
                
                Vehicle.LastUpdate = currentTime
                Vehicle.Performance.updateCount = Vehicle.Performance.updateCount + 1
                
                -- Performance tracking
                local updateTime = GetGameTimer() - startTime
                Vehicle.Performance.averageUpdateTime = 
                    (Vehicle.Performance.averageUpdateTime + updateTime) / 2
            elseif not Vehicle.Status.inVehicle then
                Vehicle.Performance.skippedUpdates = Vehicle.Performance.skippedUpdates + 1
            end
            
            Wait(100) -- Check vehicle state every 100ms
        end
    end)
    
    HUD.Debug("Vehicle update thread started", "VEHICLE", "INFO")
end

---Check if player is in vehicle and update state
function Vehicle.CheckVehicleState()
    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)
    
    if inVehicle ~= Vehicle.Status.inVehicle then
        Vehicle.Status.inVehicle = inVehicle
        
        if inVehicle then
            Vehicle.OnEnterVehicle()
        else
            Vehicle.OnExitVehicle()
        end
    end
    
    if inVehicle then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= Vehicle.Status.vehicleHandle then
            Vehicle.Status.vehicleHandle = vehicle
            Vehicle.OnVehicleChange(vehicle)
        end
    end
end

---Update all vehicle status values
function Vehicle.UpdateVehicleStatus()
    if not Vehicle.Status.inVehicle then return end
    
    local ped = PlayerPedId()
    local vehicle = Vehicle.Status.vehicleHandle
    
    if not DoesEntityExist(vehicle) then return end
    
    -- Update speed
    Vehicle.UpdateSpeed(vehicle)
    
    -- Update engine
    Vehicle.UpdateEngine(vehicle)
    
    -- Update fuel (if available)
    if Vehicle.Systems.fuel.available then
        Vehicle.UpdateFuelStatus(vehicle)
    end
    
    -- Update transmission
    Vehicle.UpdateTransmission(vehicle)
    
    -- Update vehicle systems
    Vehicle.UpdateVehicleSystems(vehicle)
    
    -- Update position
    Vehicle.UpdatePosition(vehicle)
    
    -- Update damage
    Vehicle.UpdateDamage(vehicle)
end

---Update speed information
---@param vehicle number Vehicle handle
function Vehicle.UpdateSpeed(vehicle)
    local speed = GetEntitySpeed(vehicle)
    
    -- Convert to desired unit
    if Vehicle.Status.speed.unit == "MPH" then
        Vehicle.Status.speed.current = speed * 2.236936 -- m/s to mph
    else
        Vehicle.Status.speed.current = speed * 3.6 -- m/s to kph
    end
    
    -- Format display
    Vehicle.Status.speed.display = string.format("%.0f", Vehicle.Status.speed.current)
    
    -- Get max speed for this vehicle
    local maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle))
    if Vehicle.Status.speed.unit == "MPH" then
        Vehicle.Status.speed.max = maxSpeed * 2.236936
    else
        Vehicle.Status.speed.max = maxSpeed * 3.6
    end
end

---Update engine information
---@param vehicle number Vehicle handle
function Vehicle.UpdateEngine(vehicle)
    -- Engine health (0-1000 range converted to 0-100%)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    Vehicle.Status.engine.health = math.max(0, math.min(100, engineHealth / 10))
    
    -- Engine damage
    Vehicle.Status.engine.damage = 100 - Vehicle.Status.engine.health
    
    -- Engine running state
    Vehicle.Status.engine.running = GetIsVehicleEngineRunning(vehicle)
    
    -- RPM
    Vehicle.Status.engine.rpm = GetVehicleCurrentRpm(vehicle)
    
    -- Simulate engine temperature based on health and RPM
    local baseTemp = 90
    local healthMod = (100 - Vehicle.Status.engine.health) * 0.5
    local rpmMod = Vehicle.Status.engine.rpm * 20
    Vehicle.Status.engine.temperature = math.min(120, baseTemp + healthMod + rpmMod)
end

---Update fuel status
---@param vehicle number Vehicle handle
function Vehicle.UpdateFuelStatus(vehicle)
    if not Vehicle.Systems.fuel.available then return end
    
    local fuel = 100 -- Default fuel level
    
    -- Get fuel from appropriate system
    if Vehicle.Systems.fuel.resource == 'LegacyFuel' then
        fuel = exports['LegacyFuel']:GetFuel(vehicle)
    elseif Vehicle.Systems.fuel.resource == 'ps-fuel' then
        fuel = exports['ps-fuel']:GetFuel(vehicle)
    elseif Vehicle.Systems.fuel.resource == 'ox_fuel' then
        fuel = GetVehicleFuelLevel(vehicle) -- Native function
    end
    
    Vehicle.Status.fuel.level = math.max(0, math.min(100, fuel))
    
    -- Calculate estimated range (very rough estimate)
    local avgConsumption = 8 -- L/100km average
    local remainingFuel = (Vehicle.Status.fuel.level / 100) * Vehicle.Status.fuel.capacity
    Vehicle.Status.fuel.range = math.floor((remainingFuel / avgConsumption) * 100)
end

---Update transmission information
---@param vehicle number Vehicle handle
function Vehicle.UpdateTransmission(vehicle)
    Vehicle.Status.transmission.gear = GetVehicleCurrentGear(vehicle)
    
    -- Format gear display
    local gear = Vehicle.Status.transmission.gear
    if gear == 0 then
        Vehicle.Status.transmission.gearDisplay = GetVehicleHandbrake(vehicle) and "P" or "N"
    elseif gear == -1 then
        Vehicle.Status.transmission.gearDisplay = "R"
    else
        Vehicle.Status.transmission.gearDisplay = tostring(gear)
    end
    
    -- Check if automatic (most vehicles in GTA are automatic)
    Vehicle.Status.transmission.automatic = true
end

---Update vehicle systems
---@param vehicle number Vehicle handle
function Vehicle.UpdateVehicleSystems(vehicle)
    -- Handbrake
    Vehicle.Status.systems.handbrake = GetVehicleHandbrake(vehicle)
    
    -- Lights
    local lightState = GetVehicleLightsState(vehicle)
    Vehicle.Status.systems.lights = lightState == 1
    Vehicle.Status.systems.highbeams = IsVehicleHighbeamOn(vehicle)
    
    -- Indicators
    Vehicle.Status.systems.indicators.left = GetVehicleIndicatorLights(vehicle) == 1
    Vehicle.Status.systems.indicators.right = GetVehicleIndicatorLights(vehicle) == 2
    Vehicle.Status.systems.indicators.hazards = GetVehicleIndicatorLights(vehicle) == 3
end

---Update position information
---@param vehicle number Vehicle handle
function Vehicle.UpdatePosition(vehicle)
    local coords = GetEntityCoords(vehicle)
    Vehicle.Status.position.coordinates = { x = coords.x, y = coords.y, z = coords.z }
    Vehicle.Status.position.altitude = math.floor(coords.z)
    Vehicle.Status.position.onGround = IsVehicleOnAllWheels(vehicle)
    Vehicle.Status.position.submerged = IsEntityInWater(vehicle)
end

---Update damage information
---@param vehicle number Vehicle handle
function Vehicle.UpdateDamage(vehicle)
    -- Overall body health
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    Vehicle.Status.damage.body = math.max(0, 100 - (bodyHealth / 10))
    
    -- Engine damage (already calculated in UpdateEngine)
    Vehicle.Status.damage.engine = Vehicle.Status.engine.damage
    
    -- Fuel tank health
    local tankHealth = GetVehiclePetrolTankHealth(vehicle)
    Vehicle.Status.damage.petrolTank = math.max(0, 100 - (tankHealth / 10))
    
    -- Overall damage (average of all systems)
    Vehicle.Status.damage.overall = (Vehicle.Status.damage.body + 
                                   Vehicle.Status.damage.engine + 
                                   Vehicle.Status.damage.petrolTank) / 3
    
    -- Wheel damage
    Vehicle.Status.damage.wheels = {}
    for i = 0, GetVehicleNumberOfWheels(vehicle) - 1 do
        local wheelHealth = GetVehicleWheelHealth(vehicle, i)
        Vehicle.Status.damage.wheels[i + 1] = math.max(0, 100 - wheelHealth)
    end
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle entering vehicle
function Vehicle.OnEnterVehicle()
    Vehicle.Status.inVehicle = true
    Vehicle.SetVisible(true)
    Vehicle.Performance.vehicleChanges = Vehicle.Performance.vehicleChanges + 1
    
    HUD.Debug("Entered vehicle - Vehicle HUD activated", "VEHICLE", "INFO")
    
    -- Trigger event for other systems
    TriggerEvent('hud:client:enteredVehicle')
end

---Handle exiting vehicle
function Vehicle.OnExitVehicle()
    Vehicle.Status.inVehicle = false
    Vehicle.Status.vehicleHandle = 0
    Vehicle.SetVisible(false)
    
    HUD.Debug("Exited vehicle - Vehicle HUD deactivated", "VEHICLE", "INFO")
    
    -- Trigger event for other systems
    TriggerEvent('hud:client:exitedVehicle')
end

---Handle vehicle change
---@param newVehicle number New vehicle handle
function Vehicle.OnVehicleChange(newVehicle)
    Vehicle.Status.vehicleHandle = newVehicle
    
    -- Get vehicle info
    local model = GetEntityModel(newVehicle)
    Vehicle.Status.vehicleModel = GetDisplayNameFromVehicleModel(model)
    Vehicle.Status.vehicleClass = GetVehicleClass(newVehicle)
    
    -- Reset systems for new vehicle
    Vehicle.ResetVehicleData()
    
    HUD.Debug(string.format("Vehicle changed to: %s", Vehicle.Status.vehicleModel), "VEHICLE", "INFO")
    
    -- Trigger event
    TriggerEvent('hud:client:vehicleChanged', newVehicle, Vehicle.Status.vehicleModel)
end

---Reset vehicle data for new vehicle
function Vehicle.ResetVehicleData()
    Vehicle.Status.systems.seatbelt = false
    Vehicle.Status.systems.cruise = false
    Vehicle.Status.special.nitro.level = 0
    Vehicle.Status.special.nitro.active = false
    Vehicle.Status.special.harness.equipped = false
    Vehicle.Status.special.harness.health = 100
end

---Toggle seatbelt
function Vehicle.ToggleSeatbelt()
    if not Vehicle.Status.inVehicle then return end
    
    Vehicle.Status.systems.seatbelt = not Vehicle.Status.systems.seatbelt
    
    local message = Vehicle.Status.systems.seatbelt and "Seatbelt On" or "Seatbelt Off"
    QBCore.Functions.Notify(message, 'primary')
    
    HUD.Debug("Seatbelt toggled: " .. tostring(Vehicle.Status.systems.seatbelt), "VEHICLE", "INFO")
    
    -- Trigger seatbelt event for other systems
    TriggerEvent('seatbelt:client:seatbeltToggled', Vehicle.Status.systems.seatbelt)
    
    Vehicle.SendToNUI()
end

---Toggle cruise control
function Vehicle.ToggleCruise()
    if not Vehicle.Status.inVehicle or Vehicle.Status.speed.current < 20 then return end
    
    Vehicle.Status.systems.cruise = not Vehicle.Status.systems.cruise
    
    local message = Vehicle.Status.systems.cruise and "Cruise Control On" or "Cruise Control Off"
    QBCore.Functions.Notify(message, 'primary')
    
    HUD.Debug("Cruise control toggled: " .. tostring(Vehicle.Status.systems.cruise), "VEHICLE", "INFO")
    
    -- Trigger cruise event for other systems
    TriggerEvent('cruise:client:cruiseToggled', Vehicle.Status.systems.cruise)
    
    Vehicle.SendToNUI()
end

---Update fuel from external system
---@param fuel number Fuel level
function Vehicle.UpdateFuel(fuel)
    if type(fuel) == "number" then
        Vehicle.Status.fuel.level = math.max(0, math.min(100, fuel))
        Vehicle.SendToNUI()
    end
end

---Update nitro from external system
---@param nitro table Nitro data
function Vehicle.UpdateNitro(nitro)
    if type(nitro) == "table" then
        Vehicle.Status.special.nitro.level = nitro.level or 0
        Vehicle.Status.special.nitro.active = nitro.active or false
        Vehicle.SendToNUI()
    end
end

---Update harness from external system
---@param harness table Harness data
function Vehicle.UpdateHarness(harness)
    if type(harness) == "table" then
        Vehicle.Status.special.harness.equipped = harness.equipped or false
        Vehicle.Status.special.harness.health = harness.health or 100
        Vehicle.SendToNUI()
    end
end

---Handle vehicle component click
---@param component string Component clicked
function Vehicle.OnVehicleClick(component)
    if not Config.GPSHUD.interaction.clickableIcons then return end
    
    local message = Vehicle.GetComponentMessage(component)
    if message then
        QBCore.Functions.Notify(message, 'primary')
    end
    
    HUD.Debug(string.format("Vehicle component clicked: %s", component), "VEHICLE", "INFO")
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send vehicle data to NUI
function Vehicle.SendToNUI()
    if not Vehicle.Visible or not Vehicle.Status.inVehicle then return end
    
    local vehicleData = {
        -- Basic info
        inVehicle = Vehicle.Status.inVehicle,
        vehicleModel = Vehicle.Status.vehicleModel,
        vehicleClass = Vehicle.Status.vehicleClass,
        
        -- Speed
        speed = Vehicle.Status.speed,
        
        -- Engine
        engine = Vehicle.Status.engine,
        
        -- Fuel
        fuel = Vehicle.Status.fuel,
        
        -- Transmission
        transmission = Vehicle.Status.transmission,
        
        -- Systems
        systems = Vehicle.Status.systems,
        
        -- Special systems
        special = Vehicle.Status.special,
        
        -- Position
        position = Vehicle.Status.position,
        
        -- Damage
        damage = Vehicle.Status.damage,
        
        -- Component visibility
        components = Vehicle.Components,
        
        -- System availability
        systemsAvailable = {
            fuel = Vehicle.Systems.fuel.available,
            seatbelt = Vehicle.Systems.seatbelt.available,
            nitro = Vehicle.Systems.nitro.available,
            harness = Vehicle.Systems.harness.available
        }
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'updateVehicle',
        data = vehicleData
    })
    
    -- Also send to UIManager if available
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('vehicle', vehicleData)
    end
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set vehicle module visibility
---@param visible boolean Visibility state
function Vehicle.SetVisible(visible)
    -- Only show if in vehicle and showInVehicleOnly is true
    if Config.Modules.vehicle.showInVehicleOnly and not Vehicle.Status.inVehicle then
        visible = false
    end
    
    Vehicle.Visible = visible
    
    HUD.Debug(string.format("Vehicle visibility set to: %s", visible and "visible" or "hidden"), "VEHICLE", "INFO")
    
    if visible then
        Vehicle.SendToNUI()
    else
        SendNUIMessage({
            action = 'toggleModule',
            module = 'vehicle',
            visible = false
        })
    end
end

---Get vehicle module visibility
---@return boolean visible
function Vehicle.IsVisible()
    return Vehicle.Visible
end

---Get current vehicle status
---@return table status
function Vehicle.GetStatus()
    return Vehicle.Status
end

---Get detailed vehicle status
---@return table detailedStatus
function Vehicle.GetDetailedStatus()
    return {
        status = Vehicle.Status,
        systems = Vehicle.Systems,
        components = Vehicle.Components,
        performance = Vehicle.Performance,
        config = Config.Modules.vehicle
    }
end

---Force update vehicle display
function Vehicle.ForceUpdate()
    if Vehicle.Status.inVehicle then
        Vehicle.UpdateVehicleStatus()
        Vehicle.SendToNUI()
    end
    
    HUD.Debug("Vehicle force update triggered", "VEHICLE", "INFO")
end

---Set theme for vehicle module
---@param theme string Theme name
function Vehicle.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("Vehicle theme set to: %s", theme), "VEHICLE", "INFO")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get component message for display
---@param component string Component name
---@return string message
function Vehicle.GetComponentMessage(component)
    local messages = {
        speed = string.format("Speed: %s %s", Vehicle.Status.speed.display, Vehicle.Status.speed.unit),
        fuel = string.format("Fuel: %.1f%% (Range: %dkm)", Vehicle.Status.fuel.level, Vehicle.Status.fuel.range),
        engine = string.format("Engine: %.1f%% (Temp: %.0f°C)", Vehicle.Status.engine.health, Vehicle.Status.engine.temperature),
        gear = string.format("Gear: %s", Vehicle.Status.transmission.gearDisplay),
        seatbelt = Vehicle.Status.systems.seatbelt and "Seatbelt: On" or "Seatbelt: Off",
        cruise = Vehicle.Status.systems.cruise and "Cruise: On" or "Cruise: Off",
        altitude = string.format("Altitude: %dm", Vehicle.Status.position.altitude)
    }
    
    return messages[component]
end

---Get current speed
---@return number speed
function Vehicle.GetCurrentSpeed()
    return Vehicle.Status.speed.current
end

---Get fuel level
---@return number fuel
function Vehicle.GetFuelLevel()
    return Vehicle.Status.fuel.level
end

---Check if seatbelt is on
---@return boolean seatbeltOn
function Vehicle.IsSeatbeltOn()
    return Vehicle.Status.systems.seatbelt
end

---Check if cruise control is active
---@return boolean cruiseActive
function Vehicle.IsCruiseActive()
    return Vehicle.Status.systems.cruise
end

---Get vehicle class name
---@return string className
function Vehicle.GetVehicleClassName()
    local classNames = {
        [0] = "Compacts", [1] = "Sedans", [2] = "SUVs", [3] = "Coupes",
        [4] = "Muscle", [5] = "Sports Classics", [6] = "Sports", [7] = "Super",
        [8] = "Motorcycles", [9] = "Off-road", [10] = "Industrial", [11] = "Utility",
        [12] = "Vans", [13] = "Cycles", [14] = "Boats", [15] = "Helicopters",
        [16] = "Planes", [17] = "Service", [18] = "Emergency", [19] = "Military",
        [20] = "Commercial", [21] = "Trains"
    }
    
    return classNames[Vehicle.Status.vehicleClass] or "Unknown"
end

---Get performance statistics
---@return table performance
function Vehicle.GetPerformanceStats()
    return {
        initialized = Vehicle.Initialized,
        visible = Vehicle.Visible,
        inVehicle = Vehicle.Status.inVehicle,
        updateInterval = Vehicle.UpdateInterval,
        updateCount = Vehicle.Performance.updateCount,
        averageUpdateTime = Vehicle.Performance.averageUpdateTime,
        skippedUpdates = Vehicle.Performance.skippedUpdates,
        vehicleChanges = Vehicle.Performance.vehicleChanges,
        lastUpdate = Vehicle.LastUpdate,
        systemsAvailable = {
            fuel = Vehicle.Systems.fuel.available,
            seatbelt = Vehicle.Systems.seatbelt.available,
            nitro = Vehicle.Systems.nitro.available,
            harness = Vehicle.Systems.harness.available
        }
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function Vehicle.Cleanup()
    Vehicle.Initialized = false
    Vehicle.Visible = false
    Vehicle.Status.inVehicle = false
    Vehicle.Status.vehicleHandle = 0
    
    HUD.Debug("Vehicle module cleaned up", "VEHICLE", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Vehicle.Cleanup()
    end
end)

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make Vehicle module available globally
_G.Vehicle = Vehicle

HUD.Debug("Vehicle module loaded", "VEHICLE", "INFO")
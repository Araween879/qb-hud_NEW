-- ================================================================
-- QBCore HUD - Location & Streets System Module
-- Version: 3.0.0
-- Description: Advanced location tracking with streets, zones, and navigation
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Location System Module
Location = Location or {}
Location.Initialized = false
Location.Visible = true
Location.LastUpdate = 0
Location.UpdateInterval = Config.Modules.location.updateInterval or 1500

-- Location Status Data
Location.Status = {
    -- Current location
    coords = { x = 0, y = 0, z = 0 },
    
    -- Street information
    street = {
        primary = "Unknown Street",     -- Main street name
        secondary = "",                 -- Cross street (if available)
        combined = "Unknown Street",    -- Combined street display
        hash1 = 0,                     -- Primary street hash
        hash2 = 0                      -- Secondary street hash
    },
    
    -- Zone information
    zone = {
        name = "Unknown",              -- Zone name (technical)
        label = "Unknown Area",        -- Zone display name
        hash = 0                       -- Zone hash
    },
    
    -- Direction information
    direction = {
        heading = 0,                   -- Heading in degrees (0-360)
        cardinal = "N",                -- Cardinal direction (N, NE, E, etc.)
        degrees = "0°"                 -- Degrees display
    },
    
    -- Postal code (if available)
    postal = {
        code = "",                     -- Postal code
        available = false              -- Postal system available
    },
    
    -- Waypoint information
    waypoint = {
        active = false,                -- Waypoint is set
        coords = { x = 0, y = 0, z = 0 }, -- Waypoint coordinates
        distance = 0,                  -- Distance to waypoint
        direction = 0,                 -- Direction to waypoint
        eta = 0                        -- Estimated time to arrival
    },
    
    -- Location history
    history = {},                      -- Recent locations
    
    -- Configuration
    showStreets = true,
    showZone = true,
    showDirection = true,
    showPostal = false,
    showCoordinates = false
}

-- Postal System Integration
Location.Postal = {
    resource = nil,                    -- Postal resource name
    available = false,                 -- Postal system available
    lastPostalUpdate = 0              -- Last postal update time
}

-- Performance tracking
Location.Performance = {
    updateCount = 0,
    averageUpdateTime = 0,
    skippedUpdates = 0,
    cacheHits = 0,
    cacheMisses = 0
}

-- Location cache for performance
Location.Cache = {
    streets = {},                      -- Street name cache
    zones = {},                        -- Zone name cache
    lastCacheClean = 0,               -- Last cache cleanup
    maxCacheSize = 100,               -- Maximum cache entries
    cacheTimeout = 300000             -- Cache timeout (5 minutes)
}

-- ================================================================
-- INITIALIZATION SYSTEM
-- ================================================================

---Initialize the Location module
---@return boolean success
function Location.Init()
    if Location.Initialized then
        HUD.Debug("Location module already initialized", "LOCATION", "WARN")
        return true
    end
    
    HUD.Debug("Initializing Location module...", "LOCATION", "INFO")
    
    -- Check if module is enabled
    if not Config.Modules.location.enabled then
        HUD.Debug("Location module disabled in config", "LOCATION", "INFO")
        return false
    end
    
    -- Load configuration
    Location.LoadConfiguration()
    
    -- Initialize postal system
    Location.InitializePostalSystem()
    
    -- Register events
    Location.RegisterEvents()
    
    -- Register NUI callbacks
    Location.RegisterNUICallbacks()
    
    -- Start update thread
    Location.StartUpdateThread()
    
    -- Initialize location cache
    Location.InitializeCache()
    
    Location.Initialized = true
    HUD.Debug("Location module initialized successfully", "LOCATION", "INFO")
    
    -- Send initial update
    Location.ForceUpdate()
    
    return true
end

---Load Location module configuration
function Location.LoadConfiguration()
    local config = Config.Modules.location or {}
    
    Location.Status.showStreets = config.showStreetNames or true
    Location.Status.showZone = config.showZoneName or true
    Location.Status.showDirection = config.showPointer or true
    Location.Status.showPostal = config.showPostal or false
    Location.Status.showCoordinates = config.showCoordinates or false
    
    Location.UpdateInterval = config.updateInterval or 1500
    
    HUD.Debug("Location configuration loaded", "LOCATION", "INFO")
end

---Initialize postal system integration
function Location.InitializePostalSystem()
    -- Check for postal code resources
    local postalResources = {'nearest-postal', 'postals', 'qb-postals'}
    
    for _, resource in ipairs(postalResources) do
        if GetResourceState(resource) == 'started' then
            Location.Postal.resource = resource
            Location.Postal.available = true
            Location.Status.postal.available = true
            Location.Status.showPostal = true
            HUD.Debug(string.format("Postal resource detected: %s", resource), "LOCATION", "INFO")
            break
        end
    end
    
    if not Location.Postal.available then
        HUD.Debug("No postal resource detected - postal codes disabled", "LOCATION", "INFO")
        Location.Status.showPostal = false
        Location.Status.postal.available = false
    end
end

---Initialize location cache
function Location.InitializeCache()
    Location.Cache.streets = {}
    Location.Cache.zones = {}
    Location.Cache.lastCacheClean = GetGameTimer()
    
    -- Start cache cleanup thread
    CreateThread(function()
        while Location.Initialized do
            Location.CleanCache()
            Wait(60000) -- Clean cache every minute
        end
    end)
    
    HUD.Debug("Location cache initialized", "LOCATION", "INFO")
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

---Register Location module events
function Location.RegisterEvents()
    -- Player events
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Location.ForceUpdate()
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Location.SetVisible(false)
    end)
    
    -- Location control events
    RegisterNetEvent('hud:client:toggleLocation', function(visible)
        Location.SetVisible(visible)
    end)
    
    RegisterNetEvent('hud:client:updateLocationSettings', function(settings)
        Location.UpdateSettings(settings)
    end)
    
    -- Waypoint events
    RegisterNetEvent('hud:client:waypointSet', function()
        Location.OnWaypointSet()
    end)
    
    RegisterNetEvent('hud:client:waypointCleared', function()
        Location.OnWaypointCleared()
    end)
    
    HUD.Debug("Location events registered", "LOCATION", "INFO")
end

---Register NUI callbacks
function Location.RegisterNUICallbacks()
    RegisterNUICallback('locationClick', function(data, cb)
        Location.OnLocationClick()
        cb('ok')
    end)
    
    RegisterNUICallback('copyCoordinates', function(data, cb)
        Location.CopyCoordinates()
        cb('ok')
    end)
    
    RegisterNUICallback('getLocationDetails', function(data, cb)
        cb(Location.GetDetailedStatus())
    end)
    
    RegisterNUICallback('toggleLocationDisplay', function(data, cb)
        Location.ToggleDisplayMode()
        cb('ok')
    end)
    
    HUD.Debug("Location NUI callbacks registered", "LOCATION", "INFO")
end

-- ================================================================
-- UPDATE SYSTEM
-- ================================================================

---Start the location update thread
function Location.StartUpdateThread()
    CreateThread(function()
        while Location.Initialized do
            local currentTime = GetGameTimer()
            
            if currentTime - Location.LastUpdate >= Location.UpdateInterval then
                local startTime = GetGameTimer()
                
                Location.UpdateLocationStatus()
                Location.SendToNUI()
                
                Location.LastUpdate = currentTime
                Location.Performance.updateCount = Location.Performance.updateCount + 1
                
                -- Performance tracking
                local updateTime = GetGameTimer() - startTime
                Location.Performance.averageUpdateTime = 
                    (Location.Performance.averageUpdateTime + updateTime) / 2
            else
                Location.Performance.skippedUpdates = Location.Performance.skippedUpdates + 1
            end
            
            Wait(100) -- Check every 100ms but only update based on interval
        end
    end)
    
    HUD.Debug("Location update thread started", "LOCATION", "INFO")
end

---Update location status
function Location.UpdateLocationStatus()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Update coordinates
    Location.Status.coords = { x = coords.x, y = coords.y, z = coords.z }
    
    -- Update street information
    Location.UpdateStreetInfo(coords)
    
    -- Update zone information
    Location.UpdateZoneInfo(coords)
    
    -- Update direction information
    Location.UpdateDirectionInfo()
    
    -- Update postal code (if available)
    if Location.Postal.available then
        Location.UpdatePostalCode(coords)
    end
    
    -- Update waypoint information
    Location.UpdateWaypointInfo(coords)
    
    -- Update location history
    Location.UpdateLocationHistory()
end

---Update street information with caching
---@param coords vector3 Player coordinates
function Location.UpdateStreetInfo(coords)
    local cacheKey = string.format("%.0f_%.0f", coords.x // 50, coords.y // 50) -- 50m grid cache
    
    -- Check cache first
    local cached = Location.Cache.streets[cacheKey]
    if cached and (GetGameTimer() - cached.time) < Location.Cache.cacheTimeout then
        Location.Status.street = cached.data
        Location.Performance.cacheHits = Location.Performance.cacheHits + 1
        return
    end
    
    -- Get street names from game
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    
    local streetData = {
        hash1 = street1,
        hash2 = street2,
        primary = GetStreetNameFromHashKey(street1) or "Unknown Street",
        secondary = street2 ~= 0 and GetStreetNameFromHashKey(street2) or "",
        combined = ""
    }
    
    -- Create combined street name
    if streetData.secondary ~= "" then
        streetData.combined = streetData.primary .. " / " .. streetData.secondary
    else
        streetData.combined = streetData.primary
    end
    
    Location.Status.street = streetData
    
    -- Cache the result
    Location.Cache.streets[cacheKey] = {
        data = streetData,
        time = GetGameTimer()
    }
    Location.Performance.cacheMisses = Location.Performance.cacheMisses + 1
    
    -- Clean cache if too large
    if table.count(Location.Cache.streets) > Location.Cache.maxCacheSize then
        Location.CleanCache()
    end
end

---Update zone information with caching
---@param coords vector3 Player coordinates
function Location.UpdateZoneInfo(coords)
    local cacheKey = string.format("zone_%.0f_%.0f", coords.x // 100, coords.y // 100) -- 100m grid cache
    
    -- Check cache first
    local cached = Location.Cache.zones[cacheKey]
    if cached and (GetGameTimer() - cached.time) < Location.Cache.cacheTimeout then
        Location.Status.zone = cached.data
        Location.Performance.cacheHits = Location.Performance.cacheHits + 1
        return
    end
    
    -- Get zone from game
    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zoneHash)
    
    -- Fallback if label is not found
    if zoneLabel == "NULL" or zoneLabel == "" then
        zoneLabel = zoneHash
    end
    
    local zoneData = {
        name = zoneHash,
        label = zoneLabel,
        hash = GetHashKey(zoneHash)
    }
    
    Location.Status.zone = zoneData
    
    -- Cache the result
    Location.Cache.zones[cacheKey] = {
        data = zoneData,
        time = GetGameTimer()
    }
    Location.Performance.cacheMisses = Location.Performance.cacheMisses + 1
end

---Update direction information
function Location.UpdateDirectionInfo()
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    
    Location.Status.direction.heading = heading
    Location.Status.direction.cardinal = Location.GetCardinalDirection(heading)
    Location.Status.direction.degrees = string.format("%.0f°", heading)
end

---Update postal code information
---@param coords vector3 Player coordinates
function Location.UpdatePostalCode(coords)
    if not Location.Postal.available then return end
    
    local currentTime = GetGameTimer()
    if currentTime - Location.Postal.lastPostalUpdate < 2000 then return end -- Update every 2 seconds
    
    -- Get postal code based on resource
    local postal = ""
    
    if Location.Postal.resource == 'nearest-postal' then
        postal = exports['nearest-postal']:GetNearestPostal(coords.x, coords.y, coords.z)
    elseif Location.Postal.resource == 'postals' then
        postal = exports['postals']:GetClosestPostal(coords)
    elseif Location.Postal.resource == 'qb-postals' then
        postal = exports['qb-postals']:GetPostal(coords)
    end
    
    if postal and type(postal) == "string" then
        Location.Status.postal.code = postal
    elseif postal and type(postal) == "table" and postal.code then
        Location.Status.postal.code = postal.code
    end
    
    Location.Postal.lastPostalUpdate = currentTime
end

---Update waypoint information
---@param coords vector3 Player coordinates
function Location.UpdateWaypointInfo(coords)
    local waypointActive = IsWaypointActive()
    Location.Status.waypoint.active = waypointActive
    
    if waypointActive then
        local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
        Location.Status.waypoint.coords = { x = waypointCoords.x, y = waypointCoords.y, z = waypointCoords.z }
        
        -- Calculate distance
        local distance = #(coords - waypointCoords)
        Location.Status.waypoint.distance = math.floor(distance)
        
        -- Calculate direction to waypoint
        local dx = waypointCoords.x - coords.x
        local dy = waypointCoords.y - coords.y
        local direction = math.deg(math.atan2(dy, dx))
        if direction < 0 then direction = direction + 360 end
        Location.Status.waypoint.direction = direction
        
        -- Estimate ETA (assuming average speed of 50 km/h = 13.89 m/s)
        local avgSpeed = 13.89 -- m/s
        Location.Status.waypoint.eta = math.floor(distance / avgSpeed)
    else
        Location.Status.waypoint.coords = { x = 0, y = 0, z = 0 }
        Location.Status.waypoint.distance = 0
        Location.Status.waypoint.direction = 0
        Location.Status.waypoint.eta = 0
    end
end

---Update location history
function Location.UpdateLocationHistory()
    local current = Location.Status
    local history = Location.Status.history
    
    -- Add current location to history if it's different enough
    local shouldAdd = true
    if #history > 0 then
        local last = history[#history]
        local distance = math.sqrt(
            (current.coords.x - last.coords.x)^2 + 
            (current.coords.y - last.coords.y)^2
        )
        if distance < 100 then -- Less than 100m difference
            shouldAdd = false
        end
    end
    
    if shouldAdd then
        table.insert(history, {
            coords = current.coords,
            street = current.street.combined,
            zone = current.zone.label,
            timestamp = GetGameTimer()
        })
        
        -- Keep only last 10 locations
        if #history > 10 then
            table.remove(history, 1)
        end
    end
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

---Send location data to NUI
function Location.SendToNUI()
    if not Location.Visible then return end
    
    local locationData = {
        -- Street information
        street = Location.Status.street.combined,
        streetPrimary = Location.Status.street.primary,
        streetSecondary = Location.Status.street.secondary,
        
        -- Zone information
        zone = Location.Status.zone.label,
        zoneName = Location.Status.zone.name,
        
        -- Direction information
        heading = Location.Status.direction.heading,
        cardinal = Location.Status.direction.cardinal,
        degrees = Location.Status.direction.degrees,
        
        -- Coordinates
        coords = Location.Status.coords,
        
        -- Postal code
        postal = Location.Status.postal.code,
        
        -- Waypoint information
        waypoint = Location.Status.waypoint,
        
        -- Display settings
        showStreets = Location.Status.showStreets,
        showZone = Location.Status.showZone,
        showDirection = Location.Status.showDirection,
        showPostal = Location.Status.showPostal,
        showCoordinates = Location.Status.showCoordinates,
        
        -- Status
        postalAvailable = Location.Postal.available
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'updateLocation',
        data = locationData
    })
    
    -- Also send to UIManager if available
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('location', locationData)
    end
end

-- ================================================================
-- EVENT HANDLERS
-- ================================================================

---Handle waypoint set event
function Location.OnWaypointSet()
    HUD.Debug("Waypoint set - updating location display", "LOCATION", "INFO")
    Location.UpdateWaypointInfo(GetEntityCoords(PlayerPedId()))
    Location.SendToNUI()
end

---Handle waypoint cleared event
function Location.OnWaypointCleared()
    HUD.Debug("Waypoint cleared - updating location display", "LOCATION", "INFO")
    Location.Status.waypoint.active = false
    Location.SendToNUI()
end

---Handle location click event
function Location.OnLocationClick()
    if Config.GPSHUD.interaction.clickableIcons then
        -- Toggle display mode or show detailed info
        local message = Location.GetLocationMessage()
        QBCore.Functions.Notify(message, 'primary')
        
        HUD.Debug("Location clicked - detailed info shown", "LOCATION", "INFO")
    end
end

---Handle settings update
---@param settings table New settings
function Location.UpdateSettings(settings)
    if type(settings) ~= "table" then return end
    
    if settings.showStreets ~= nil then
        Location.Status.showStreets = settings.showStreets
    end
    
    if settings.showZone ~= nil then
        Location.Status.showZone = settings.showZone
    end
    
    if settings.showDirection ~= nil then
        Location.Status.showDirection = settings.showDirection
    end
    
    if settings.showPostal ~= nil then
        Location.Status.showPostal = settings.showPostal
    end
    
    if settings.showCoordinates ~= nil then
        Location.Status.showCoordinates = settings.showCoordinates
    end
    
    Location.SendToNUI()
    HUD.Debug("Location settings updated", "LOCATION", "INFO")
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set location module visibility
---@param visible boolean Visibility state
function Location.SetVisible(visible)
    Location.Visible = visible
    
    HUD.Debug(string.format("Location visibility set to: %s", visible and "visible" or "hidden"), "LOCATION", "INFO")
    
    if visible then
        Location.SendToNUI()
    else
        SendNUIMessage({
            action = 'toggleModule',
            module = 'location',
            visible = false
        })
    end
end

---Get location module visibility
---@return boolean visible
function Location.IsVisible()
    return Location.Visible
end

---Get current location status
---@return table status
function Location.GetStatus()
    return Location.Status
end

---Get detailed location status
---@return table detailedStatus
function Location.GetDetailedStatus()
    return {
        status = Location.Status,
        postal = Location.Postal,
        performance = Location.Performance,
        cache = {
            streets = table.count(Location.Cache.streets),
            zones = table.count(Location.Cache.zones),
            cacheHits = Location.Performance.cacheHits,
            cacheMisses = Location.Performance.cacheMisses
        },
        config = Config.Modules.location
    }
end

---Force update location display
function Location.ForceUpdate()
    Location.UpdateLocationStatus()
    Location.SendToNUI()
    
    HUD.Debug("Location force update triggered", "LOCATION", "INFO")
end

---Set theme for location module
---@param theme string Theme name
function Location.SetTheme(theme)
    SendNUIMessage({
        action = 'setTheme',
        theme = theme
    })
    
    HUD.Debug(string.format("Location theme set to: %s", theme), "LOCATION", "INFO")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Get cardinal direction from heading
---@param heading number Heading in degrees
---@return string direction
function Location.GetCardinalDirection(heading)
    local directions = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", 
                       "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"}
    local index = math.floor((heading + 11.25) / 22.5) % 16
    return directions[index + 1]
end

---Get location message for display
---@return string message
function Location.GetLocationMessage()
    local parts = {}
    
    if Location.Status.showStreets then
        table.insert(parts, Location.Status.street.combined)
    end
    
    if Location.Status.showZone then
        table.insert(parts, Location.Status.zone.label)
    end
    
    if Location.Status.showDirection then
        table.insert(parts, string.format("%s (%s)", 
                     Location.Status.direction.cardinal, 
                     Location.Status.direction.degrees))
    end
    
    if Location.Status.showPostal and Location.Status.postal.code ~= "" then
        table.insert(parts, "Postal: " .. Location.Status.postal.code)
    end
    
    if Location.Status.showCoordinates then
        table.insert(parts, string.format("Coords: %.1f, %.1f, %.1f", 
                            Location.Status.coords.x, 
                            Location.Status.coords.y, 
                            Location.Status.coords.z))
    end
    
    if Location.Status.waypoint.active then
        table.insert(parts, string.format("Waypoint: %dm (%ds)", 
                            Location.Status.waypoint.distance, 
                            Location.Status.waypoint.eta))
    end
    
    return table.concat(parts, " | ")
end

---Copy coordinates to clipboard
function Location.CopyCoordinates()
    local coords = Location.Status.coords
    local coordString = string.format("vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)
    
    -- Send to NUI for clipboard copying
    SendNUIMessage({
        action = 'copyToClipboard',
        text = coordString
    })
    
    QBCore.Functions.Notify("Coordinates copied to clipboard", 'success')
    HUD.Debug("Coordinates copied: " .. coordString, "LOCATION", "INFO")
end

---Toggle display mode
function Location.ToggleDisplayMode()
    -- Cycle through different display modes
    if Location.Status.showStreets and Location.Status.showZone then
        -- Show only streets
        Location.Status.showStreets = true
        Location.Status.showZone = false
        QBCore.Functions.Notify("Location: Streets only", 'primary')
    elseif Location.Status.showStreets and not Location.Status.showZone then
        -- Show only zone
        Location.Status.showStreets = false
        Location.Status.showZone = true
        QBCore.Functions.Notify("Location: Zone only", 'primary')
    else
        -- Show both
        Location.Status.showStreets = true
        Location.Status.showZone = true
        QBCore.Functions.Notify("Location: Streets + Zone", 'primary')
    end
    
    Location.SendToNUI()
end

---Get current street name
---@return string street
function Location.GetCurrentStreet()
    return Location.Status.street.combined
end

---Get current zone name
---@return string zone
function Location.GetCurrentZone()
    return Location.Status.zone.label
end

---Get distance to waypoint
---@return number distance
function Location.GetWaypointDistance()
    return Location.Status.waypoint.distance
end

---Check if player is in specific zone
---@param zoneName string Zone name to check
---@return boolean inZone
function Location.IsInZone(zoneName)
    return Location.Status.zone.name:upper() == zoneName:upper() or 
           Location.Status.zone.label:upper() == zoneName:upper()
end

---Clean location cache
function Location.CleanCache()
    local currentTime = GetGameTimer()
    local cleaned = 0
    
    -- Clean street cache
    for key, data in pairs(Location.Cache.streets) do
        if currentTime - data.time > Location.Cache.cacheTimeout then
            Location.Cache.streets[key] = nil
            cleaned = cleaned + 1
        end
    end
    
    -- Clean zone cache
    for key, data in pairs(Location.Cache.zones) do
        if currentTime - data.time > Location.Cache.cacheTimeout then
            Location.Cache.zones[key] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        HUD.Debug(string.format("Cleaned %d cache entries", cleaned), "LOCATION", "INFO")
    end
    
    Location.Cache.lastCacheClean = currentTime
end

---Get performance statistics
---@return table performance
function Location.GetPerformanceStats()
    return {
        initialized = Location.Initialized,
        visible = Location.Visible,
        updateInterval = Location.UpdateInterval,
        updateCount = Location.Performance.updateCount,
        averageUpdateTime = Location.Performance.averageUpdateTime,
        skippedUpdates = Location.Performance.skippedUpdates,
        cacheHits = Location.Performance.cacheHits,
        cacheMisses = Location.Performance.cacheMisses,
        cacheSize = table.count(Location.Cache.streets) + table.count(Location.Cache.zones),
        lastUpdate = Location.LastUpdate,
        postalAvailable = Location.Postal.available,
        postalResource = Location.Postal.resource
    }
end

-- ================================================================
-- CLEANUP
-- ================================================================

---Cleanup function
function Location.Cleanup()
    Location.Initialized = false
    Location.Visible = false
    Location.Cache.streets = {}
    Location.Cache.zones = {}
    
    HUD.Debug("Location module cleaned up", "LOCATION", "INFO")
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Location.Cleanup()
    end
end)

-- ================================================================
-- UTILITY FUNCTION
-- ================================================================

---Count table entries
---@param t table Table to count
---@return number count
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ================================================================
-- MODULE EXPORT
-- ================================================================

-- Make Location module available globally
_G.Location = Location

HUD.Debug("Location module loaded", "LOCATION", "INFO")
-- ================================================================
-- QBCore HUD - Location System Module
-- Version: 3.0.0
-- Description: Street names, zone detection, and area display
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local Location = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current location values
local currentStreet1 = ""
local currentStreet2 = ""
local currentZone = ""
local currentArea = ""
local lastUpdate = 0

-- Zone name translations (English to readable names)
local zoneNames = {
    -- Los Santos Areas
    ['AIRP'] = 'Los Santos International Airport',
    ['ALAMO'] = 'Alamo Sea',
    ['ALTA'] = 'Alta',
    ['ARMYB'] = 'Fort Zancudo',
    ['BANHAMC'] = 'Banham Canyon Dr',
    ['BANNING'] = 'Banning',
    ['BEACH'] = 'Vespucci Beach',
    ['BHAMCA'] = 'Banham Canyon',
    ['BRADP'] = 'Braddock Pass',
    ['BRADT'] = 'Braddock Tunnel',
    ['BURTON'] = 'Burton',
    ['CALAFB'] = 'Calafia Bridge',
    ['CANNY'] = 'Raton Canyon',
    ['CCREAK'] = 'Cassidy Creek',
    ['CHAMH'] = 'Chamberlain Hills',
    ['CHIL'] = 'Vinewood Hills',
    ['CHU'] = 'Chumash',
    ['CMSW'] = 'Chiliad Mountain State Wilderness',
    ['CYPRE'] = 'Cypress Flats',
    ['DAVIS'] = 'Davis',
    ['DELBE'] = 'Del Perro Beach',
    ['DELPE'] = 'Del Perro',
    ['DELSOL'] = 'La Puerta',
    ['DESRT'] = 'Grand Senora Desert',
    ['DOWNT'] = 'Downtown',
    ['DTVINE'] = 'Downtown Vinewood',
    ['EAST_V'] = 'East Vinewood',
    ['EBURO'] = 'El Burro Heights',
    ['ELGORL'] = 'El Gordo Lighthouse',
    ['ELYSIAN'] = 'Elysian Island',
    ['GALFISH'] = 'Galilee',
    ['GOLF'] = 'GWC and Golfing Society',
    ['GRAPES'] = 'Grapeseed',
    ['GREATC'] = 'Great Chaparral',
    ['HARMO'] = 'Harmony',
    ['HAWICK'] = 'Hawick',
    ['HORS'] = 'Vinewood Racetrack',
    ['HUMLAB'] = 'Humane Labs and Research',
    ['IGLESIAS'] = 'Iglesias',
    ['ISHEIST'] = 'Island',
    ['KOREAT'] = 'Little Seoul',
    ['LACT'] = 'Land Act Reservoir',
    ['LAGO'] = 'Lago Zancudo',
    ['LDAM'] = 'Land Act Dam',
    ['LEGSQU'] = 'Legion Square',
    ['LMESA'] = 'La Mesa',
    ['LOSPUER'] = 'La Puerta',
    ['MIRR'] = 'Mirror Park',
    ['MORN'] = 'Morningwood',
    ['MOVIE'] = 'Richards Majestic',
    ['MTCHIL'] = 'Mount Chiliad',
    ['MTGORDO'] = 'Mount Gordo',
    ['MTJOSE'] = 'Mount Josiah',
    ['MURRI'] = 'Murrieta Heights',
    ['NCHU'] = 'North Chumash',
    ['NOOSE'] = 'N.O.O.S.E',
    ['OCEANA'] = 'Pacific Ocean',
    ['PALCOV'] = 'Paleto Cove',
    ['PALETO'] = 'Paleto Bay',
    ['PALFOR'] = 'Paleto Forest',
    ['PALHIGH'] = 'Palomino Highlands',
    ['PALMPOW'] = 'Palmer-Taylor Power Station',
    ['PBLUFF'] = 'Pacific Bluffs',
    ['PBOX'] = 'Pillbox Hill',
    ['PROCOB'] = 'Procopio Beach',
    ['RANCHO'] = 'Rancho',
    ['RGLEN'] = 'Richman Glen',
    ['RICHM'] = 'Richman',
    ['ROCKF'] = 'Rockford Hills',
    ['RTRAK'] = 'Redwood Lights Track',
    ['SANAND'] = 'San Andreas',
    ['SANCHIA'] = 'San Chianski Mountain Range',
    ['SANDY'] = 'Sandy Shores',
    ['SKID'] = 'Mission Row',
    ['SLAB'] = 'Stab City',
    ['STAD'] = 'Maze Bank Arena',
    ['STRAW'] = 'Strawberry',
    ['TATAMO'] = 'Tataviam Mountains',
    ['TERMINA'] = 'Terminal',
    ['TEXTI'] = 'Textile City',
    ['TONGVAH'] = 'Tongva Hills',
    ['TONGVAV'] = 'Tongva Valley',
    ['VCANA'] = 'Vespucci Canals',
    ['VESP'] = 'Vespucci',
    ['VINE'] = 'Vinewood',
    ['WINDF'] = 'Ron Alternates Wind Farm',
    ['WVINE'] = 'West Vinewood',
    ['ZANCUDO'] = 'Zancudo River',
    ['ZP_ORT'] = 'Port of Los Santos',
    ['ZQ_UAR'] = 'Davis Quartz'
}

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Location module
function Location.Init()
    if isInitialized then
        HUD.Debug("^3Location module already initialized^7", "LOCATION")
        return true
    end
    
    HUD.Debug("^2Initializing Location module^7", "LOCATION")
    
    -- Register events
    Location.RegisterEvents()
    
    -- Start update thread
    Location.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.location.enabled
    
    isInitialized = true
    HUD.Debug("^2Location module initialized successfully^7", "LOCATION")
    
    return true
end

---Register all location-related events
function Location.RegisterEvents()
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'location' then
            Location.SetVisible(visible)
        end
    end)
    
    -- Manual location update event
    RegisterNetEvent('hud:client:UpdateLocation', function(street1, street2, zone)
        if street1 then currentStreet1 = street1 end
        if street2 then currentStreet2 = street2 end
        if zone then currentZone = zone end
        Location.SendUpdate()
    end)
    
    HUD.Debug("^2Location events registered^7", "LOCATION")
end

---Start the location update thread
function Location.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Location update thread already running^7", "LOCATION")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible then
                Location.UpdateLocation()
            end
            Wait(Config.Modules.location.updateInterval or 1500)
        end
    end)
    
    HUD.Debug("^2Location update thread started^7", "LOCATION")
end

---Update location information
function Location.UpdateLocation()
    local player = PlayerPedId()
    if not player or player == 0 then return end
    
    local coords = GetEntityCoords(player)
    
    -- Get street names
    local street1Hash, street2Hash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local newStreet1 = GetStreetNameFromHashKey(street1Hash) or ""
    local newStreet2 = GetStreetNameFromHashKey(street2Hash) or ""
    
    -- Get zone name
    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
    local newZone = zoneNames[zoneHash] or zoneHash or ""
    
    -- Get area (for special locations like buildings, etc.)
    local newArea = Location.GetSpecialArea(coords)
    
    -- Check for significant changes (optimization)
    local streetChanged = newStreet1 ~= currentStreet1 or newStreet2 ~= currentStreet2
    local zoneChanged = newZone ~= currentZone
    local areaChanged = newArea ~= currentArea
    
    if streetChanged or zoneChanged or areaChanged then
        currentStreet1 = newStreet1
        currentStreet2 = newStreet2
        currentZone = newZone
        currentArea = newArea
        
        Location.SendUpdate()
        
        -- Debug output
        if Config.Debug then
            HUD.Debug(string.format("^2Location updated: %s | %s | %s^7", 
                      Location.GetFormattedStreet(), currentZone, currentArea), "LOCATION")
        end
    end
end

---Get special area name for current coordinates
---@param coords vector3 Player coordinates
---@return string Area name
function Location.GetSpecialArea(coords)
    -- Check for special buildings/areas
    local areas = {
        -- Police Stations
        {coords = vector3(425.1, -979.5, 30.7), radius = 50.0, name = "Mission Row Police Station"},
        {coords = vector3(1854.3, 3678.9, 34.2), radius = 50.0, name = "Sandy Shores Police Station"},
        {coords = vector3(-449.1, 6008.0, 31.7), radius = 50.0, name = "Paleto Bay Police Station"},
        
        -- Hospitals
        {coords = vector3(295.0, -1446.9, 29.9), radius = 50.0, name = "Central Los Santos Medical Center"},
        {coords = vector3(-247.8, 6331.5, 32.4), radius = 50.0, name = "Paleto Bay Medical Center"},
        {coords = vector3(1839.6, 3672.9, 34.3), radius = 50.0, name = "Sandy Shores Medical Center"},
        
        -- Government Buildings
        {coords = vector3(-544.5, -204.5, 38.2), radius = 30.0, name = "City Hall"},
        {coords = vector3(-1368.8, -503.7, 33.2), radius = 30.0, name = "Del Perro Police Station"},
        
        -- Shopping Centers
        {coords = vector3(25.7, -1347.3, 29.5), radius = 40.0, name = "Strawberry 24/7"},
        {coords = vector3(1135.8, -982.3, 46.4), radius = 40.0, name = "Mirror Park 24/7"},
        {coords = vector3(373.5, 325.6, 103.6), radius = 40.0, name = "Clinton Avenue 24/7"},
        
        -- Banks
        {coords = vector3(150.3, -1040.2, 29.4), radius = 30.0, name = "Fleeca Bank"},
        {coords = vector3(-1212.9, -330.8, 37.8), radius = 30.0, name = "Fleeca Bank"},
        {coords = vector3(-2962.7, 482.6, 15.7), radius = 30.0, name = "Fleeca Bank"},
        
        -- Car Dealerships
        {coords = vector3(-56.7, -1096.6, 26.4), radius = 50.0, name = "Premium Deluxe Motorsport"},
        {coords = vector3(-33.9, -1102.3, 26.4), radius = 50.0, name = "Simeon's Dealership"},
        
        -- Garages
        {coords = vector3(215.8, -805.1, 30.8), radius = 30.0, name = "Central Garage"},
        {coords = vector3(596.4, 90.6, 93.1), radius = 30.0, name = "Vinewood Garage"},
        
        -- Gas Stations
        {coords = vector3(49.4, 2778.8, 58.0), radius = 25.0, name = "Route 68 Gas Station"},
        {coords = vector3(263.9, 2606.5, 44.9), radius = 25.0, name = "Route 68 Gas Station"},
        {coords = vector3(1039.9, 2671.1, 39.6), radius = 25.0, name = "Grand Senora Gas Station"},
        
        -- Special Locations
        {coords = vector3(-75.0, -818.6, 326.2), radius = 100.0, name = "Maze Bank Tower"},
        {coords = vector3(240.0, -1379.9, 33.7), radius = 40.0, name = "Maze Bank Arena"},
        {coords = vector3(-1266.8, -3014.1, -49.5), radius = 50.0, name = "Los Santos International Airport"},
    }
    
    -- Check if player is in any special area
    for _, area in pairs(areas) do
        local distance = #(coords - area.coords)
        if distance <= area.radius then
            return area.name
        end
    end
    
    return ""
end

---Send current location data to NUI
function Location.SendUpdate()
    if not isVisible then return end
    
    local locationData = {
        street = {
            primary = currentStreet1,
            secondary = currentStreet2,
            formatted = Location.GetFormattedStreet()
        },
        zone = currentZone,
        area = currentArea,
        display = {
            showStreetNames = Config.Modules.location.showStreetNames,
            showZoneName = Config.Modules.location.showZoneName,
            showPointer = Config.Modules.location.showPointer,
            showDegrees = Config.Modules.location.showDegrees
        },
        heading = Location.GetPlayerHeading()
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('location', locationData)
    end
end

-- ================================================================
-- FORMATTING FUNCTIONS
-- ================================================================

---Get formatted street name string
---@return string Formatted street name
function Location.GetFormattedStreet()
    if currentStreet1 ~= "" and currentStreet2 ~= "" then
        return string.format("%s / %s", currentStreet1, currentStreet2)
    elseif currentStreet1 ~= "" then
        return currentStreet1
    elseif currentStreet2 ~= "" then
        return currentStreet2
    else
        return "Unknown Area"
    end
end

---Get player heading as compass direction
---@return table Heading information
function Location.GetPlayerHeading()
    local player = PlayerPedId()
    if not player or player == 0 then
        return {degrees = 0, direction = "N"}
    end
    
    local heading = GetEntityHeading(player)
    local direction = Location.GetCompassDirection(heading)
    
    return {
        degrees = math.floor(heading),
        direction = direction,
        formatted = string.format("%s (%d°)", direction, math.floor(heading))
    }
end

---Convert heading to compass direction
---@param heading number Heading in degrees
---@return string Compass direction
function Location.GetCompassDirection(heading)
    local directions = {
        {0, 22.5, "N"}, {22.5, 67.5, "NE"}, {67.5, 112.5, "E"}, {112.5, 157.5, "SE"},
        {157.5, 202.5, "S"}, {202.5, 247.5, "SW"}, {247.5, 292.5, "W"}, {292.5, 337.5, "NW"},
        {337.5, 360, "N"}
    }
    
    for _, dir in ipairs(directions) do
        if heading >= dir[1] and heading < dir[2] then
            return dir[3]
        end
    end
    
    return "N"
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the location module
---@param visible boolean
function Location.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Location visibility set to: %s^7", visible and "visible" or "hidden"), "LOCATION")
    
    if visible then
        Location.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('location', { visible = false })
        end
    end
end

---Get current location module visibility
---@return boolean
function Location.IsVisible()
    return isVisible
end

---Get current location data
---@return table
function Location.GetLocationData()
    return {
        street1 = currentStreet1,
        street2 = currentStreet2,
        zone = currentZone,
        area = currentArea,
        formattedStreet = Location.GetFormattedStreet(),
        heading = Location.GetPlayerHeading()
    }
end

---Force update location display
function Location.ForceUpdate()
    Location.UpdateLocation()
    Location.SendUpdate()
    HUD.Debug("^2Location force update triggered^7", "LOCATION")
end

---Get zone name by hash
---@param zoneHash string Zone hash key
---@return string Zone display name
function Location.GetZoneDisplayName(zoneHash)
    return zoneNames[zoneHash] or zoneHash or "Unknown"
end

---Set custom area name (for external use)
---@param areaName string Custom area name
function Location.SetCustomArea(areaName)
    if type(areaName) == "string" then
        currentArea = areaName
        Location.SendUpdate()
        HUD.Debug(string.format("^2Custom area set: %s^7", areaName), "LOCATION")
    end
end

---Clear custom area name
function Location.ClearCustomArea()
    currentArea = ""
    Location.SendUpdate()
    HUD.Debug("^2Custom area cleared^7", "LOCATION")
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

---Check if player is in specific zone
---@param zoneName string Zone name to check
---@return boolean
function Location.IsInZone(zoneName)
    return currentZone:upper() == zoneName:upper()
end

---Check if player is near coordinates
---@param coords vector3 Coordinates to check
---@param radius number Check radius
---@return boolean
function Location.IsNearCoordinates(coords, radius)
    local player = PlayerPedId()
    if not player or player == 0 then return false end
    
    local playerCoords = GetEntityCoords(player)
    local distance = #(playerCoords - coords)
    
    return distance <= radius
end

---Get distance to coordinates
---@param coords vector3 Target coordinates
---@return number Distance in meters
function Location.GetDistanceToCoords(coords)
    local player = PlayerPedId()
    if not player or player == 0 then return 0 end
    
    local playerCoords = GetEntityCoords(player)
    return #(playerCoords - coords)
end

-- ================================================================
-- SPECIAL LOCATION EVENTS
-- ================================================================

-- Thread to check for special location events
CreateThread(function()
    local lastSpecialLocation = ""
    
    while true do
        if isInitialized and LocalPlayer.state.isLoggedIn then
            local player = PlayerPedId()
            if player and player ~= 0 then
                local coords = GetEntityCoords(player)
                local specialLocation = Location.GetSpecialArea(coords)
                
                -- Trigger event when entering/leaving special locations
                if specialLocation ~= lastSpecialLocation then
                    if specialLocation ~= "" then
                        TriggerEvent('hud:client:EnteredSpecialLocation', specialLocation)
                        HUD.Debug(string.format("^2Entered special location: %s^7", specialLocation), "LOCATION")
                    elseif lastSpecialLocation ~= "" then
                        TriggerEvent('hud:client:LeftSpecialLocation', lastSpecialLocation)
                        HUD.Debug(string.format("^3Left special location: %s^7", lastSpecialLocation), "LOCATION")
                    end
                    
                    lastSpecialLocation = specialLocation
                end
            end
        end
        
        Wait(2000) -- Check every 2 seconds for special locations
    end
end)

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('location', Location)
end

-- Export Location functions for external use
_G.Location = Location

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Location module shutting down^7", "LOCATION")
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)
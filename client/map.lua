-- ================================================================
-- QBCore HUD - Map & Compass System Module
-- Version: 3.0.0
-- Description: Compass, minimap shape, altitude, navigation system
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local Map = {}
local isInitialized = false
local updateThread = nil
local isVisible = true

-- Current map values
local currentHeading = 0
local currentAltitude = 0
local mapShape = 'circle'
local showCompass = true
local showMinimap = true
local followCamera = true
local inVehicle = false

-- Direction mapping
local directions = {
    ['N'] = {min = 337.5, max = 360, min2 = 0, max2 = 22.5, label = 'N'},
    ['NE'] = {min = 22.5, max = 67.5, label = 'NE'},
    ['E'] = {min = 67.5, max = 112.5, label = 'E'},
    ['SE'] = {min = 112.5, max = 157.5, label = 'SE'},
    ['S'] = {min = 157.5, max = 202.5, label = 'S'},
    ['SW'] = {min = 202.5, max = 247.5, label = 'SW'},
    ['W'] = {min = 247.5, max = 292.5, label = 'W'},
    ['NW'] = {min = 292.5, max = 337.5, label = 'NW'}
}

-- ================================================================
-- CORE FUNCTIONS
-- ================================================================

---Initialize the Map module
function Map.Init()
    if isInitialized then
        HUD.Debug("^3Map module already initialized^7", "MAP")
        return true
    end
    
    HUD.Debug("^2Initializing Map module^7", "MAP")
    
    -- Get initial settings from config
    mapShape = Config.Modules.map.mapShape or 'circle'
    showCompass = Config.Modules.map.showCompass
    showMinimap = Config.Modules.map.showMinimap
    followCamera = Config.Modules.map.compassFollowCam
    
    -- Register events
    Map.RegisterEvents()
    
    -- Start update thread
    Map.StartUpdateThread()
    
    -- Set initial visibility
    isVisible = Config.Modules.map.enabled
    
    -- Apply initial map settings
    Map.ApplyMapSettings()
    
    isInitialized = true
    HUD.Debug("^2Map module initialized successfully^7", "MAP")
    
    return true
end

---Register all map-related events
function Map.RegisterEvents()
    -- Map shape toggle event
    RegisterNetEvent('hud:client:ToggleMapShape', function()
        Map.ToggleMapShape()
    end)
    
    -- Compass toggle event
    RegisterNetEvent('hud:client:ToggleCompass', function()
        Map.ToggleCompass()
    end)
    
    -- Minimap visibility event
    RegisterNetEvent('hud:client:ToggleMinimap', function()
        Map.ToggleMinimap()
    end)
    
    -- Module visibility events
    RegisterNetEvent('hud:client:moduleVisibilityChanged', function(moduleName, visible)
        if moduleName == 'map' then
            Map.SetVisible(visible)
        end
    end)
    
    -- Settings update events
    RegisterNetEvent('hud:client:setMapShape', function(shape)
        Map.SetMapShape(shape)
    end)
    
    RegisterNetEvent('hud:client:setCompassFollow', function(follow)
        followCamera = follow
        HUD.Debug(string.format("^2Compass follow camera: %s^7", follow and "ON" or "OFF"), "MAP")
    end)
    
    HUD.Debug("^2Map events registered^7", "MAP")
end

---Start the map update thread
function Map.StartUpdateThread()
    if updateThread then
        HUD.Debug("^3Map update thread already running^7", "MAP")
        return
    end
    
    updateThread = CreateThread(function()
        while isInitialized do
            if LocalPlayer.state.isLoggedIn and isVisible and showCompass then
                Map.UpdateCompass()
            end
            Wait(Config.Modules.map.updateInterval or 100)
        end
    end)
    
    HUD.Debug("^2Map update thread started^7", "MAP")
end

---Update compass and related data
function Map.UpdateCompass()
    local player = PlayerPedId()
    if not player or player == 0 then return end
    
    -- Get current heading
    local newHeading
    if followCamera then
        local cam = GetRenderingCam()
        if cam ~= -1 then
            newHeading = GetGameplayCamRot(0).z
        else
            newHeading = GetEntityHeading(player)
        end
    else
        newHeading = GetEntityHeading(player)
    end
    
    -- Normalize heading to 0-360
    if newHeading < 0 then
        newHeading = newHeading + 360
    end
    
    -- Get altitude (for aircraft or elevated positions)
    local coords = GetEntityCoords(player)
    local newAltitude = math.ceil(coords.z)
    
    -- Check if in vehicle
    local vehicle = GetVehiclePedIsIn(player, false)
    local newInVehicle = vehicle ~= 0
    
    -- Check for significant changes (optimization)
    local headingChanged = math.abs(newHeading - currentHeading) > 2
    local altitudeChanged = math.abs(newAltitude - currentAltitude) > 5
    local vehicleStateChanged = newInVehicle ~= inVehicle
    
    if headingChanged or altitudeChanged or vehicleStateChanged then
        currentHeading = newHeading
        currentAltitude = newAltitude
        inVehicle = newInVehicle
        
        Map.SendUpdate()
    end
end

---Apply map settings to game
function Map.ApplyMapSettings()
    -- Set minimap visibility
    DisplayRadar(showMinimap and isVisible)
    
    -- Apply map shape
    Map.SetMapShape(mapShape)
    
    HUD.Debug(string.format("^2Map settings applied - Shape: %s, Radar: %s^7", 
              mapShape, showMinimap and "ON" or "OFF"), "MAP")
end

---Send current map data to NUI
function Map.SendUpdate()
    if not isVisible then return end
    
    local direction = Map.GetDirection(currentHeading)
    local cardinalDirection = Map.GetCardinalDirection(currentHeading)
    
    local mapData = {
        compass = {
            heading = currentHeading,
            headingRounded = math.floor(currentHeading),
            direction = direction,
            cardinal = cardinalDirection,
            show = showCompass
        },
        minimap = {
            shape = mapShape,
            visible = showMinimap,
            followCamera = followCamera
        },
        altitude = currentAltitude,
        inVehicle = inVehicle,
        showInVehicleOnly = Config.Modules.map.showInVehicleOnly or false,
        components = Config.Modules.map.components or {
            compass = true,
            minimap = true,
            altitude = true
        }
    }
    
    -- Send to UI Manager for NUI update
    if UIManager and UIManager.UpdateModule then
        UIManager.UpdateModule('map', mapData)
    end
end

-- ================================================================
-- DIRECTION CALCULATION
-- ================================================================

---Get direction from heading
---@param heading number Heading in degrees (0-360)
---@return string Direction abbreviation
function Map.GetDirection(heading)
    for direction, data in pairs(directions) do
        if direction == 'N' then
            -- Special case for North (crosses 0/360)
            if (heading >= data.min and heading <= data.max) or (heading >= data.min2 and heading <= data.max2) then
                return data.label
            end
        else
            if heading >= data.min and heading < data.max then
                return data.label
            end
        end
    end
    return 'N' -- Fallback
end

---Get cardinal direction (N, S, E, W only)
---@param heading number Heading in degrees (0-360)
---@return string Cardinal direction
function Map.GetCardinalDirection(heading)
    if (heading >= 315 and heading <= 360) or (heading >= 0 and heading < 45) then
        return 'N'
    elseif heading >= 45 and heading < 135 then
        return 'E'
    elseif heading >= 135 and heading < 225 then
        return 'S'
    elseif heading >= 225 and heading < 315 then
        return 'W'
    end
    return 'N'
end

---Get detailed direction description
---@param heading number Heading in degrees (0-360)
---@return string Detailed direction
function Map.GetDetailedDirection(heading)
    local directions = {
        {0, 11.25, "North"},
        {11.25, 33.75, "North-Northeast"},
        {33.75, 56.25, "Northeast"},
        {56.25, 78.75, "East-Northeast"},
        {78.75, 101.25, "East"},
        {101.25, 123.75, "East-Southeast"},
        {123.75, 146.25, "Southeast"},
        {146.25, 168.75, "South-Southeast"},
        {168.75, 191.25, "South"},
        {191.25, 213.75, "South-Southwest"},
        {213.75, 236.25, "Southwest"},
        {236.25, 258.75, "West-Southwest"},
        {258.75, 281.25, "West"},
        {281.25, 303.75, "West-Northwest"},
        {303.75, 326.25, "Northwest"},
        {326.25, 348.75, "North-Northwest"},
        {348.75, 360, "North"}
    }
    
    for _, dir in ipairs(directions) do
        if heading >= dir[1] and heading < dir[2] then
            return dir[3]
        end
    end
    
    return "North"
end

-- ================================================================
-- MAP CONTROL FUNCTIONS
-- ================================================================

---Toggle minimap shape between circle and square
function Map.ToggleMapShape()
    mapShape = mapShape == 'circle' and 'square' or 'circle'
    Map.SetMapShape(mapShape)
    Map.SendUpdate()
    
    QBCore.Functions.Notify(string.format('Minimap shape: %s', mapShape), 'primary')
    HUD.Debug(string.format("^2Map shape toggled to: %s^7", mapShape), "MAP")
end

---Set minimap shape
---@param shape string 'circle' or 'square'
function Map.SetMapShape(shape)
    if shape ~= 'circle' and shape ~= 'square' then
        HUD.Debug(string.format("^1Invalid map shape: %s^7", shape), "MAP")
        return false
    end
    
    mapShape = shape
    
    -- Apply the shape change
    if shape == 'circle' then
        RequestStreamedTextureDict("circlemap", false)
        if not HasStreamedTextureDictLoaded("circlemap") then
            Wait(150)
        end
        SetMinimapClipType(1)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
        SetMinimapComponentPosition('minimap', 'L', 'B', 0.0, -0.047, 0.1638, 0.183)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0, 0.0, 0.128, 0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', 0.012, 0.022, 0.142, 0.150)
        
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetRadarBigmapEnabled(true, false)
        SetMinimapClipType(1)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
    else
        -- Square minimap
        SetMinimapClipType(0)
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, -0.002, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0, 0.0, 0.128, 0.20)
        
        -- Reset blip alpha
        SetBlipAlpha(GetNorthRadarBlip(), 255)
        
        -- Remove circle texture
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "platform:/textures/graphics", "radarmasksm")
    end
    
    HUD.Debug(string.format("^2Map shape set to: %s^7", shape), "MAP")
    return true
end

---Toggle compass visibility
function Map.ToggleCompass()
    showCompass = not showCompass
    Map.SendUpdate()
    
    QBCore.Functions.Notify(string.format('Compass: %s', showCompass and 'shown' or 'hidden'), 'primary')
    HUD.Debug(string.format("^2Compass visibility: %s^7", showCompass and "ON" or "OFF"), "MAP")
end

---Toggle minimap visibility
function Map.ToggleMinimap()
    showMinimap = not showMinimap
    DisplayRadar(showMinimap and isVisible)
    Map.SendUpdate()
    
    QBCore.Functions.Notify(string.format('Minimap: %s', showMinimap and 'shown' or 'hidden'), 'primary')
    HUD.Debug(string.format("^2Minimap visibility: %s^7", showMinimap and "ON" or "OFF"), "MAP")
end

-- ================================================================
-- PUBLIC API FUNCTIONS
-- ================================================================

---Set the visibility of the map module
---@param visible boolean
function Map.SetVisible(visible)
    isVisible = visible
    HUD.Debug(string.format("^2Map visibility set to: %s^7", visible and "visible" or "hidden"), "MAP")
    
    -- Update minimap visibility
    DisplayRadar(showMinimap and visible)
    
    if visible then
        Map.SendUpdate()
    else
        -- Hide the module in NUI
        if UIManager and UIManager.UpdateModule then
            UIManager.UpdateModule('map', { visible = false })
        end
    end
end

---Get current map module visibility
---@return boolean
function Map.IsVisible()
    return isVisible
end

---Get current map data
---@return table
function Map.GetMapData()
    return {
        heading = currentHeading,
        altitude = currentAltitude,
        direction = Map.GetDirection(currentHeading),
        cardinal = Map.GetCardinalDirection(currentHeading),
        mapShape = mapShape,
        showCompass = showCompass,
        showMinimap = showMinimap,
        followCamera = followCamera,
        inVehicle = inVehicle
    }
end

---Force update map display
function Map.ForceUpdate()
    Map.UpdateCompass()
    Map.SendUpdate()
    HUD.Debug("^2Map force update triggered^7", "MAP")
end

---Set compass follow camera mode
---@param follow boolean
function Map.SetCompassFollow(follow)
    followCamera = follow
    HUD.Debug(string.format("^2Compass follow camera: %s^7", follow and "ON" or "OFF"), "MAP")
end

---Get current heading
---@return number
function Map.GetHeading()
    return currentHeading
end

---Get current altitude
---@return number
function Map.GetAltitude()
    return currentAltitude
end

-- ================================================================
-- WAYPOINT SYSTEM (Future Extension Ready)
-- ================================================================

---Set waypoint and get direction
---@param x number X coordinate
---@param y number Y coordinate
---@return table Waypoint data
function Map.SetWaypoint(x, y)
    SetNewWaypoint(x, y)
    
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    local waypointHeading = GetHeadingFromVector_2d(x - playerCoords.x, y - playerCoords.y)
    local distance = #(vector3(x, y, 0) - vector3(playerCoords.x, playerCoords.y, 0))
    
    local waypointData = {
        x = x,
        y = y,
        heading = waypointHeading,
        direction = Map.GetDirection(waypointHeading),
        distance = math.ceil(distance)
    }
    
    HUD.Debug(string.format("^2Waypoint set: %s, Distance: %dm^7", waypointData.direction, waypointData.distance), "MAP")
    
    return waypointData
end

---Clear current waypoint
function Map.ClearWaypoint()
    RemoveBlip(GetFirstBlipInfoId(8)) -- Remove waypoint blip
    HUD.Debug("^2Waypoint cleared^7", "MAP")
end

-- ================================================================
-- MODULE REGISTRATION & CLEANUP
-- ================================================================

-- Register module with HUD system
if HUD then
    HUD.RegisterModule('map', Map)
end

-- Export Map functions for external use
_G.Map = Map

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isInitialized then
        HUD.Debug("^3Map module shutting down^7", "MAP")
        
        -- Reset minimap to default
        DisplayRadar(true)
        Map.SetMapShape('square')
        
        isInitialized = false
        if updateThread then
            updateThread = nil
        end
    end
end)
-- ================================================================
-- QBCore HUD - Navigation Menu Client Module (NAVIGATION-MENÜ)
-- Version: 3.0.0
-- Description: Navigation-Menü Management:
--              📋 Waypoint-Liste | 🏠 Favoriten | 🏢 POI-System | 📊 Route-History
-- ================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Navigation Menu System
NAVMENU = NAVMENU or {}
NAVMENU.Enabled = true
NAVMENU.MenuOpen = false
NAVMENU.MenuKey = 'M' -- Default key for navigation menu

-- Menu Data
NAVMENU.Data = {
    -- Favorite Locations
    favorites = {},
    
    -- Recent Waypoints
    recentWaypoints = {},
    
    -- Points of Interest
    pois = {
        ['businesses'] = {},
        ['government'] = {},
        ['medical'] = {},
        ['automotive'] = {},
        ['entertainment'] = {},
        ['shopping'] = {},
        ['services'] = {}
    },
    
    -- Route History
    routeHistory = {},
    
    -- Current Selection
    selectedCategory = 'favorites',
    selectedItem = nil
}

-- Default POI Data
NAVMENU.DefaultPOIs = {
    ['businesses'] = {
        { name = "Maze Bank", coords = vector3(-75.0, -818.77, 243.38), icon = "fas fa-building" },
        { name = "Diamond Casino", coords = vector3(925.0, 46.0, 81.0), icon = "fas fa-dice" },
        { name = "Vanilla Unicorn", coords = vector3(129.0, -1299.0, 29.0), icon = "fas fa-cocktail" }
    },
    ['government'] = {
        { name = "City Hall", coords = vector3(-544.0, -204.0, 38.0), icon = "fas fa-landmark" },
        { name = "Police Station", coords = vector3(428.0, -982.0, 30.0), icon = "fas fa-shield-alt" },
        { name = "Fire Station", coords = vector3(1193.0, -1464.0, 35.0), icon = "fas fa-fire-extinguisher" }
    },
    ['medical'] = {
        { name = "Central Medical", coords = vector3(295.0, -1448.0, 30.0), icon = "fas fa-hospital" },
        { name = "Sandy Shores Medical", coords = vector3(1839.0, 3672.0, 34.0), icon = "fas fa-ambulance" },
        { name = "Paleto Medical", coords = vector3(-247.0, 6331.0, 32.0), icon = "fas fa-first-aid" }
    },
    ['automotive'] = {
        { name = "PDM Dealership", coords = vector3(-56.0, -1096.0, 26.0), icon = "fas fa-car" },
        { name = "Benny's Workshop", coords = vector3(-212.0, -1324.0, 31.0), icon = "fas fa-wrench" },
        { name = "Los Santos Customs", coords = vector3(-362.0, -132.0, 38.0), icon = "fas fa-tools" }
    },
    ['entertainment'] = {
        { name = "Movie Theater", coords = vector3(300.0, 200.0, 104.0), icon = "fas fa-film" },
        { name = "Golf Club", coords = vector3(-1368.0, 56.0, 54.0), icon = "fas fa-golf-ball" },
        { name = "Beach Pier", coords = vector3(-1850.0, -1232.0, 13.0), icon = "fas fa-umbrella-beach" }
    },
    ['shopping'] = {
        { name = "24/7 Supermarket", coords = vector3(-3047.0, 585.0, 8.0), icon = "fas fa-shopping-cart" },
        { name = "Clothing Store", coords = vector3(72.0, -1399.0, 29.0), icon = "fas fa-tshirt" },
        { name = "Ammunation", coords = vector3(-662.0, -935.0, 21.0), icon = "fas fa-crosshairs" }
    },
    ['services'] = {
        { name = "Bank ATM", coords = vector3(147.0, -1036.0, 29.0), icon = "fas fa-credit-card" },
        { name = "Gas Station", coords = vector3(49.0, 2778.0, 58.0), icon = "fas fa-gas-pump" },
        { name = "Parking Garage", coords = vector3(215.0, -810.0, 31.0), icon = "fas fa-parking" }
    }
}

-- Performance Tracking
NAVMENU.Performance = {
    lastMenuOpen = 0,
    lastPOIUpdate = 0,
    menuInteractions = 0
}

-- ================================================================
-- INITIALIZATION
-- ================================================================

function NAVMENU.Init()
    if HUD and HUD.Debug then
        HUD.Debug("Initializing Navigation Menu System...", "NAVMENU", "INFO")
    end
    
    -- Setup NUI callbacks
    NAVMENU.RegisterNUICallbacks()
    
    -- Setup game events
    NAVMENU.RegisterEvents()
    
    -- Setup keybinds
    NAVMENU.RegisterKeybinds()
    
    -- Load POI data
    NAVMENU.LoadPOIs()
    
    -- Load saved data
    NAVMENU.LoadSavedData()
    
    if HUD and HUD.Debug then
        HUD.Debug("Navigation Menu System initialized successfully", "NAVMENU", "INFO")
    end
    
    return true
end

-- ================================================================
-- NUI COMMUNICATION
-- ================================================================

function NAVMENU.RegisterNUICallbacks()
    -- Open/Close navigation menu
    RegisterNUICallback('navmenu:toggleMenu', function(data, cb)
        NAVMENU.ToggleMenu()
        cb('ok')
    end)
    
    -- Set waypoint from menu
    RegisterNUICallback('navmenu:setWaypoint', function(data, cb)
        if data.coords and data.name then
            NAVMENU.SetWaypointFromMenu(data.coords, data.name)
            cb('ok')
        else
            cb('error')
        end
    end)
    
    -- Add to favorites
    RegisterNUICallback('navmenu:addFavorite', function(data, cb)
        if data.name and data.coords then
            NAVMENU.AddFavorite(data.name, data.coords, data.icon)
            cb('ok')
        else
            cb('error')
        end
    end)
    
    -- Remove from favorites
    RegisterNUICallback('navmenu:removeFavorite', function(data, cb)
        if data.id then
            NAVMENU.RemoveFavorite(data.id)
            cb('ok')
        else
            cb('error')
        end
    end)
    
    -- Change category
    RegisterNUICallback('navmenu:changeCategory', function(data, cb)
        if data.category then
            NAVMENU.SetCategory(data.category)
            cb('ok')
        else
            cb('error')
        end
    end)
    
    -- Get menu data
    RegisterNUICallback('navmenu:getMenuData', function(data, cb)
        cb(NAVMENU.Data)
    end)
    
    -- Search locations
    RegisterNUICallback('navmenu:searchLocations', function(data, cb)
        if data.query then
            local results = NAVMENU.SearchLocations(data.query)
            cb(results)
        else
            cb({})
        end
    end)
    
    -- Save current location as favorite
    RegisterNUICallback('navmenu:saveCurrentLocation', function(data, cb)
        NAVMENU.SaveCurrentLocationAsFavorite(data.name)
        cb('ok')
    end)
end

function NAVMENU.SendNUIMessage(action, data)
    SendNUIMessage({
        module = 'nav_menu',
        action = action,
        data = data or {}
    })
end

-- ================================================================
-- MENU CONTROL
-- ================================================================

function NAVMENU.OpenMenu()
    if NAVMENU.MenuOpen then return end
    
    NAVMENU.MenuOpen = true
    NAVMENU.Performance.lastMenuOpen = GetGameTimer()
    
    -- Update current location data
    NAVMENU.UpdateCurrentLocation()
    
    -- Send menu data to NUI
    NAVMENU.SendNUIMessage('openMenu', NAVMENU.Data)
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    -- Play sound
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    if HUD and HUD.Debug then
        HUD.Debug("Navigation menu opened", "NAVMENU", "INFO")
    end
end

function NAVMENU.CloseMenu()
    if not NAVMENU.MenuOpen then return end
    
    NAVMENU.MenuOpen = false
    
    -- Close NUI
    NAVMENU.SendNUIMessage('closeMenu', {})
    
    -- Remove NUI focus
    SetNuiFocus(false, false)
    
    -- Auto-save data
    NAVMENU.SaveData()
    
    -- Play sound
    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    if HUD and HUD.Debug then
        HUD.Debug("Navigation menu closed", "NAVMENU", "INFO")
    end
end

function NAVMENU.ToggleMenu()
    if NAVMENU.MenuOpen then
        NAVMENU.CloseMenu()
    else
        NAVMENU.OpenMenu()
    end
end

-- ================================================================
-- WAYPOINT MANAGEMENT
-- ================================================================

function NAVMENU.SetWaypointFromMenu(coords, name)
    if not coords then return false end
    
    -- Add to recent waypoints
    NAVMENU.AddRecentWaypoint(name, coords)
    
    -- Set waypoint via GPS Navigation system
    if GPSNAV and GPSNAV.SetWaypoint then
        GPSNAV.SetWaypoint(coords, name)
    else
        -- Fallback: Set waypoint directly
        SetNewWaypoint(coords.x, coords.y)
    end
    
    NAVMENU.Performance.menuInteractions = NAVMENU.Performance.menuInteractions + 1
    
    -- Show notification
    NAVMENU.ShowNotification(string.format("Waypoint set: %s", name))
    
    -- Close menu after setting waypoint
    NAVMENU.CloseMenu()
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Waypoint set from menu: %s", name), "NAVMENU", "INFO")
    end
    
    return true
end

function NAVMENU.AddRecentWaypoint(name, coords)
    local waypoint = {
        id = GetGameTimer(),
        name = name,
        coords = coords,
        timestamp = GetGameTimer(),
        date = os.date("%Y-%m-%d %H:%M")
    }
    
    -- Add to beginning of list
    table.insert(NAVMENU.Data.recentWaypoints, 1, waypoint)
    
    -- Keep only last 10 recent waypoints
    if #NAVMENU.Data.recentWaypoints > 10 then
        table.remove(NAVMENU.Data.recentWaypoints, 11)
    end
    
    -- Update NUI
    NAVMENU.SendNUIMessage('recentWaypointsUpdated', NAVMENU.Data.recentWaypoints)
end

-- ================================================================
-- FAVORITES MANAGEMENT
-- ================================================================

function NAVMENU.AddFavorite(name, coords, icon)
    if not name or not coords then return false end
    
    local favorite = {
        id = GetGameTimer(),
        name = name,
        coords = coords,
        icon = icon or "fas fa-star",
        dateAdded = os.date("%Y-%m-%d %H:%M")
    }
    
    -- Check if already exists
    for i, fav in ipairs(NAVMENU.Data.favorites) do
        if fav.name == name then
            NAVMENU.ShowNotification("Location already in favorites")
            return false
        end
    end
    
    -- Add to favorites
    table.insert(NAVMENU.Data.favorites, favorite)
    
    -- Update NUI
    NAVMENU.SendNUIMessage('favoritesUpdated', NAVMENU.Data.favorites)
    
    -- Show notification
    NAVMENU.ShowNotification(string.format("Added to favorites: %s", name))
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Added favorite: %s", name), "NAVMENU", "INFO")
    end
    
    return true
end

function NAVMENU.RemoveFavorite(id)
    for i, favorite in ipairs(NAVMENU.Data.favorites) do
        if favorite.id == id then
            local name = favorite.name
            table.remove(NAVMENU.Data.favorites, i)
            
            -- Update NUI
            NAVMENU.SendNUIMessage('favoritesUpdated', NAVMENU.Data.favorites)
            
            -- Show notification
            NAVMENU.ShowNotification(string.format("Removed from favorites: %s", name))
            
            if HUD and HUD.Debug then
                HUD.Debug(string.format("Removed favorite: %s", name), "NAVMENU", "INFO")
            end
            
            return true
        end
    end
    
    return false
end

function NAVMENU.SaveCurrentLocationAsFavorite(name)
    if not name or name == "" then
        name = "Custom Location " .. #NAVMENU.Data.favorites + 1
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    NAVMENU.AddFavorite(name, coords, "fas fa-map-marker-alt")
end

-- ================================================================
-- POI SYSTEM
-- ================================================================

function NAVMENU.LoadPOIs()
    -- Load default POIs
    for category, locations in pairs(NAVMENU.DefaultPOIs) do
        NAVMENU.Data.pois[category] = {}
        for _, location in ipairs(locations) do
            table.insert(NAVMENU.Data.pois[category], {
                id = GetGameTimer() + math.random(1000, 9999),
                name = location.name,
                coords = location.coords,
                icon = location.icon,
                category = category,
                isDefault = true
            })
        end
    end
    
    -- Update performance tracker
    NAVMENU.Performance.lastPOIUpdate = GetGameTimer()
    
    if HUD and HUD.Debug then
        local totalPOIs = 0
        for _, category in pairs(NAVMENU.Data.pois) do
            totalPOIs = totalPOIs + #category
        end
        HUD.Debug(string.format("Loaded %d POIs across all categories", totalPOIs), "NAVMENU", "INFO")
    end
end

function NAVMENU.AddCustomPOI(category, name, coords, icon)
    if not NAVMENU.Data.pois[category] then
        NAVMENU.Data.pois[category] = {}
    end
    
    local poi = {
        id = GetGameTimer(),
        name = name,
        coords = coords,
        icon = icon or "fas fa-map-marker",
        category = category,
        isDefault = false,
        dateAdded = os.date("%Y-%m-%d %H:%M")
    }
    
    table.insert(NAVMENU.Data.pois[category], poi)
    
    -- Update NUI
    NAVMENU.SendNUIMessage('poisUpdated', NAVMENU.Data.pois)
    
    return true
end

-- ================================================================
-- SEARCH SYSTEM
-- ================================================================

function NAVMENU.SearchLocations(query)
    if not query or query == "" then return {} end
    
    local results = {}
    query = query:lower()
    
    -- Search favorites
    for _, favorite in ipairs(NAVMENU.Data.favorites) do
        if favorite.name:lower():find(query) then
            table.insert(results, {
                name = favorite.name,
                coords = favorite.coords,
                icon = favorite.icon,
                type = "favorite"
            })
        end
    end
    
    -- Search POIs
    for category, pois in pairs(NAVMENU.Data.pois) do
        for _, poi in ipairs(pois) do
            if poi.name:lower():find(query) then
                table.insert(results, {
                    name = poi.name,
                    coords = poi.coords,
                    icon = poi.icon,
                    type = "poi",
                    category = category
                })
            end
        end
    end
    
    -- Search recent waypoints
    for _, waypoint in ipairs(NAVMENU.Data.recentWaypoints) do
        if waypoint.name:lower():find(query) then
            table.insert(results, {
                name = waypoint.name,
                coords = waypoint.coords,
                icon = "fas fa-history",
                type = "recent"
            })
        end
    end
    
    -- Limit results to 20 for performance
    if #results > 20 then
        for i = #results, 21, -1 do
            table.remove(results, i)
        end
    end
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Search query '%s' returned %d results", query, #results), "NAVMENU", "INFO")
    end
    
    return results
end

-- ================================================================
-- CATEGORY MANAGEMENT
-- ================================================================

function NAVMENU.SetCategory(category)
    if not category then return false end
    
    NAVMENU.Data.selectedCategory = category
    NAVMENU.Data.selectedItem = nil
    
    -- Send category change to NUI
    NAVMENU.SendNUIMessage('categoryChanged', { category = category })
    
    if HUD and HUD.Debug then
        HUD.Debug(string.format("Category changed to: %s", category), "NAVMENU", "INFO")
    end
    
    return true
end

-- ================================================================
-- LOCATION UPDATES
-- ================================================================

function NAVMENU.UpdateCurrentLocation()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Get street and zone names
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
    
    -- Format location name
    local locationName = streetName
    if crossingName and crossingName ~= "" then
        locationName = streetName .. " / " .. crossingName
    end
    
    -- Send current location to NUI
    NAVMENU.SendNUIMessage('currentLocationUpdate', {
        name = locationName,
        zone = zoneName,
        coords = coords
    })
end

-- ================================================================
-- EVENT SYSTEM
-- ================================================================

function NAVMENU.RegisterEvents()
    -- Player loaded
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Wait(2000)
        NAVMENU.LoadSavedData()
    end)
    
    -- Navigation menu events
    RegisterNetEvent('navmenu:client:openMenu', function()
        NAVMENU.OpenMenu()
    end)
    
    RegisterNetEvent('navmenu:client:closeMenu', function()
        NAVMENU.CloseMenu()
    end)
    
    -- Add location events
    RegisterNetEvent('navmenu:client:addFavorite', function(name, coords, icon)
        NAVMENU.AddFavorite(name, coords, icon)
    end)
    
    RegisterNetEvent('navmenu:client:addPOI', function(category, name, coords, icon)
        NAVMENU.AddCustomPOI(category, name, coords, icon)
    end)
end

function NAVMENU.RegisterKeybinds()
    -- Navigation menu keybind
    RegisterKeyMapping('navmenu_open', 'Open Navigation Menu', 'keyboard', NAVMENU.MenuKey)
    
    RegisterCommand('navmenu_open', function()
        NAVMENU.ToggleMenu()
    end, false)
    
    -- Quick waypoint clear
    RegisterKeyMapping('navmenu_clear_waypoint', 'Clear Current Waypoint', 'keyboard', '')
    
    RegisterCommand('navmenu_clear_waypoint', function()
        if GPSNAV and GPSNAV.ClearWaypoint then
            GPSNAV.ClearWaypoint()
        else
            SetWaypointOff()
        end
        NAVMENU.ShowNotification("Waypoint cleared")
    end, false)
end

-- ================================================================
-- DATA PERSISTENCE
-- ================================================================

function NAVMENU.SaveData()
    local saveData = {
        favorites = NAVMENU.Data.favorites,
        recentWaypoints = NAVMENU.Data.recentWaypoints,
        customPOIs = {}
    }
    
    -- Save only custom POIs (not default ones)
    for category, pois in pairs(NAVMENU.Data.pois) do
        saveData.customPOIs[category] = {}
        for _, poi in ipairs(pois) do
            if not poi.isDefault then
                table.insert(saveData.customPOIs[category], poi)
            end
        end
    end
    
    local saveString = json.encode(saveData)
    
    -- Save to NUI localStorage
    NAVMENU.SendNUIMessage('saveData', { data = saveString })
    
    -- Also save to server
    TriggerServerEvent('navmenu:server:saveData', saveString)
    
    if HUD and HUD.Debug then
        HUD.Debug("Navigation menu data saved", "NAVMENU", "INFO")
    end
end

function NAVMENU.LoadSavedData()
    -- Request from NUI localStorage
    NAVMENU.SendNUIMessage('loadData', {})
    
    -- Also request from server
    TriggerServerEvent('navmenu:server:loadData')
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

function NAVMENU.ShowNotification(message)
    if not message then return end
    
    -- Send to NUI
    NAVMENU.SendNUIMessage('showNotification', { message = message })
    
    -- Also use QBCore notification if available
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, 'primary', 3000)
    end
end

function NAVMENU.GetMenuData()
    return NAVMENU.Data
end

function NAVMENU.GetPerformanceData()
    return NAVMENU.Performance
end

-- ================================================================
-- EXPORTS FOR OTHER RESOURCES
-- ================================================================

-- Menu control
exports('OpenNavigationMenu', function()
    NAVMENU.OpenMenu()
end)

exports('CloseNavigationMenu', function()
    NAVMENU.CloseMenu()
end)

exports('ToggleNavigationMenu', function()
    NAVMENU.ToggleMenu()
end)

-- Favorites management
exports('AddNavigationFavorite', function(name, coords, icon)
    return NAVMENU.AddFavorite(name, coords, icon)
end)

exports('RemoveNavigationFavorite', function(id)
    return NAVMENU.RemoveFavorite(id)
end)

exports('GetNavigationFavorites', function()
    return NAVMENU.Data.favorites
end)

-- POI management
exports('AddNavigationPOI', function(category, name, coords, icon)
    return NAVMENU.AddCustomPOI(category, name, coords, icon)
end)

exports('GetNavigationPOIs', function(category)
    if category then
        return NAVMENU.Data.pois[category] or {}
    else
        return NAVMENU.Data.pois
    end
end)

-- Search
exports('SearchNavigationLocations', function(query)
    return NAVMENU.SearchLocations(query)
end)

-- Waypoint from menu
exports('SetWaypointFromNavigationMenu', function(coords, name)
    return NAVMENU.SetWaypointFromMenu(coords, name)
end)

-- Data access
exports('GetNavigationMenuData', function()
    return NAVMENU.GetMenuData()
end)
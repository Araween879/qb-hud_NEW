-- ================================================================
-- QBCore HUD - Enhanced Configuration System
-- Version: 3.0.0
-- Description: Complete modular configuration with GPS HUD focus
-- ================================================================

Config = {}

-- ================================================================
-- CORE SYSTEM SETTINGS
-- ================================================================

-- Debug Mode (enables detailed console output and debug commands)
Config.Debug = false

-- Performance Settings
Config.Performance = {
    updateInterval = 200,           -- Base update interval in ms (200ms for GPS HUD)
    optimizedMode = false,          -- Use optimized update cycles
    maxFPS = 60,                    -- Target FPS for animations
    reducedAnimations = false       -- Disable heavy animations for better performance
}

-- ================================================================
-- GPS HUD SYSTEM (MAIN INTERFACE)
-- ================================================================

Config.GPSHUD = {
    enabled = true,                 -- Master switch for GPS HUD
    position = 'bottom-left',       -- Position on screen
    updateInterval = 200,           -- Update frequency in ms
    
    -- Display Components
    components = {
        navigation = true,          -- GPS Navigation header
        minimap = true,            -- Minimap area
        voice = true,              -- 🎤 Microphone/Voice indicator
        health = true,             -- ❤️ Health indicator
        armor = true,              -- 🛡️ Armor indicator  
        hunger = true,             -- 🍔 Hunger indicator
        thirst = true,             -- 💧 Thirst indicator
        stress = true,             -- 🧠 Stress indicator
        stamina = true,            -- 🏃 Stamina indicator
        time = true                -- Time display (separate module)
    },
    
    -- Animation Settings
    animations = {
        enabled = true,            -- Enable all animations
        glowEffects = true,        -- Glow effects for status indicators
        pulseWarnings = true,      -- Pulse effect for critical status
        scanLines = true,          -- Scanning line animations
        particleEffects = false    -- Particle effects (performance heavy)
    },
    
    -- Interaction Settings
    interaction = {
        clickableIcons = true,     -- Allow clicking on status icons
        hoverEffects = true,       -- Hover effects on elements
        statusDetails = true,      -- Show detailed info on click
        voiceLevelCycle = true     -- Allow cycling voice levels
    }
}

-- ================================================================
-- MODULE CONFIGURATION
-- ================================================================

Config.Modules = {
    -- GPS HUD System (HAUPT-INTERFACE)
    gps_hud = {
        enabled = true,
        priority = 1,              -- Load order priority
        position = 'bottom-left',
        updateInterval = 200,      -- Fast updates for all status
        showNavigation = true,
        showMinimap = true,
        animations = true,
        essential = true,          -- Cannot be disabled by user
        components = {
            voice = true,          -- Mikrofon
            health = true,         -- Leben
            armor = true,          -- Rüstung
            hunger = true,         -- Essen
            thirst = true,         -- Durst
            stress = true,         -- Stress
            stamina = true,        -- Ausdauer
            navigation = true,     -- GPS Navigation
            time = true            -- Zeit oben rechts
        }
    },
    
    -- UI Manager Module
    ui_manager = {
        enabled = true,
        priority = 2,
        cinematicMode = false,
        scaling = 1.0,
        opacity = 0.9,
        enableGlowEffects = true,
        enableAnimations = true
    },
    
    -- Health System Module (DEAKTIVIERT - GPS-HUD übernimmt)
    health = {
        enabled = false,           -- ❌ Deaktiviert
        position = 'bottom-left',
        updateInterval = 500,
        showWhenFull = false,
        animations = true,
        components = {
            health = false,        -- Im GPS-HUD integriert
            armor = false,         -- Im GPS-HUD integriert
            hunger = false,        -- Im GPS-HUD integriert
            thirst = false,        -- Im GPS-HUD integriert
            stress = false,        -- Im GPS-HUD integriert
            oxygen = false         -- Im GPS-HUD integriert
        }
    },
    
    -- Status System Module (DEAKTIVIERT - GPS-HUD übernimmt)
    status = {
        enabled = false,           -- ❌ Deaktiviert
        position = 'bottom-center',
        updateInterval = 200,
        showIcons = true,
        animations = true,
        components = {
            voice = false,         -- Im GPS-HUD integriert
            radio = false,         -- Im GPS-HUD integriert
            armed = false,
            parachute = false,
            harness = false,
            cruise = false,
            dev_mode = false
        }
    },
    
    -- Time & Weather System Module
    time = {
        enabled = true,
        position = 'top-right',
        updateInterval = 1000,     -- Update every second
        format24h = true,          -- 24-hour format vs 12-hour
        showDate = true,
        showWeather = false,       -- Requires weather sync resource
        animations = true
    },
    
    -- Location System Module
    location = {
        enabled = true,
        position = 'top-center',
        updateInterval = 1500,     -- Update street names every 1.5s
        showStreetNames = true,
        showZoneName = true,
        showPointer = true,
        showDegrees = true,
        animations = true
    },
    
    -- Vehicle System Module
    vehicle = {
        enabled = true,
        position = 'bottom-right',
        updateInterval = 200,      -- Fast updates for speed
        showInVehicleOnly = true,  -- Only show when in vehicle
        showSpeedometer = true,
        showFuelGauge = true,
        showEngine = true,
        showNitro = false,
        showSeatbelt = true,
        showAltitude = true,       -- For aircraft
        useMPH = true,            -- false for KPH
        animations = true
    },
    
    -- Menu System Module
    menu_ui = {
        enabled = true,
        openKey = 'I',            -- Default key to open HUD menu
        enableSounds = true,
        saveSettings = true       -- Save settings to localStorage
    },
    
    -- Extensions System
    extensions = {
        enabled = true,
        autoLoad = true           -- Automatically load files from extensions/
    }
}

-- ================================================================
-- DESIGN DNA CONFIGURATION (NEON THEME SYSTEM)
-- ================================================================

Config.Theme = {
    -- Active Theme
    current = 'neon-magenta',
    
    -- Available Themes
    available = {
        'neon-magenta',           -- Default purple/magenta theme
        'neon-cyan',              -- Cyan/blue theme
        'synthwave',              -- Pink/purple synthwave
        'matrix',                 -- Green matrix theme
        'classic'                 -- Classic blue theme
    },
    
    -- Color Definitions for GPS HUD
    colors = {
        -- Neon Magenta Theme (Default)
        ['neon-magenta'] = {
            primary = '#B026FF',        -- Magenta/Violet
            secondary = '#0ff',         -- Cyan
            accent = '#FFD700',         -- Gold
            background = '#1a1a1a',     -- Dark gray
            backgroundDark = '#111',    -- Darker gray
            textPrimary = '#fff',       -- White
            textSecondary = '#e0e0e0',  -- Light gray
            
            -- Status Colors for GPS HUD icons
            health = '#ff4444',         -- Red
            armor = '#00bcd4',          -- Blue
            hunger = '#ffb74d',         -- Orange
            thirst = '#29b6f6',         -- Light Blue
            stress = '#a020f0',         -- Purple
            stamina = '#66bb6a',        -- Green
            
            -- Voice Colors
            voiceIdle = '#ffffff',      -- White
            voiceTalking = '#ffff3e',   -- Yellow
            voiceRadio = '#d64763',     -- Red
            voiceMuted = '#666666'      -- Gray
        },
        
        -- Neon Cyan Theme
        ['neon-cyan'] = {
            primary = '#0ff',           -- Cyan
            secondary = '#B026FF',      -- Magenta
            accent = '#FFD700',         -- Gold
            background = '#0a1a1a',     -- Dark blue-gray
            backgroundDark = '#051111', -- Darker blue-gray
            textPrimary = '#fff',
            textSecondary = '#e0e0e0',
            
            health = '#ff4444',
            armor = '#00bcd4',
            hunger = '#ffb74d',
            thirst = '#29b6f6',
            stress = '#a020f0',
            stamina = '#66bb6a',
            
            voiceIdle = '#ffffff',
            voiceTalking = '#ffff3e',
            voiceRadio = '#d64763',
            voiceMuted = '#666666'
        }
    },
    
    -- Typography Settings
    fonts = {
        primary = 'Orbitron',           -- Main UI font
        secondary = 'Roboto',           -- Secondary font
        monospace = 'Fira Code'         -- For numbers/data
    },
    
    -- Animation Settings
    animations = {
        transitionSpeed = '0.3s',       -- Global transition speed
        easing = 'ease',                -- CSS easing function
        enableGlow = true,              -- Enable glow effects
        enableScanning = true,          -- Enable scanning animations
        hoverScale = 1.05,              -- Scale on hover
        hoverTranslate = '-2px'         -- Translate Y on hover
    }
}

-- ================================================================
-- VOICE SYSTEM CONFIGURATION
-- ================================================================

Config.Voice = {
    enabled = true,                     -- Enable voice integration
    provider = 'pma-voice',            -- Voice system provider
    
    -- Voice Levels (proximity chat)
    levels = {
        [1] = { distance = 3, label = 'Whisper', icon = 'fa-microphone-slash' },
        [2] = { distance = 7, label = 'Normal', icon = 'fa-microphone' },
        [3] = { distance = 15, label = 'Shout', icon = 'fa-volume-up' },
        [4] = { distance = 30, label = 'Megaphone', icon = 'fa-bullhorn' }
    },
    
    -- Radio Settings
    radio = {
        enabled = true,                 -- Enable radio integration
        showChannel = true,             -- Show radio channel number
        maxChannels = 999,              -- Maximum radio channels
        defaultChannel = 0              -- Default channel (0 = off)
    },
    
    -- Visual Effects
    effects = {
        talkingAnimation = true,        -- Animate microphone when talking
        radioGlow = true,               -- Glow effect for radio active
        levelBars = true,               -- Show voice level bars
        channelDisplay = true           -- Show channel number overlay
    }
}

-- ================================================================
-- LEGACY SETTINGS (for backwards compatibility)
-- ================================================================

-- Stress System Settings
Config.StressChance = 0.1              -- Chance to gain stress from events
Config.MinimumStress = 50              -- Minimum stress to trigger effects
Config.MinimumSpeedUnbuckled = 50      -- Speed threshold without seatbelt
Config.MinimumSpeed = 100              -- Base speed threshold for stress
Config.DisableStress = false           -- Disable stress system entirely

-- Display Settings
Config.UseMPH = true                   -- Use MPH instead of KPH
Config.OpenMenu = 'I'                  -- Key to open HUD menu

-- Whitelisted weapons (no armed indicator)
Config.WhitelistedWeaponArmed = {
    -- Miscellaneous
    [`weapon_petrolcan`] = true,
    [`weapon_hazardcan`] = true,
    [`weapon_fireextinguisher`] = true,
    -- Melee weapons
    [`weapon_dagger`] = true,
    [`weapon_bat`] = true,
    [`weapon_bottle`] = true,
    [`weapon_crowbar`] = true,
    [`weapon_flashlight`] = true,
    [`weapon_golfclub`] = true,
    [`weapon_hammer`] = true,
    [`weapon_hatchet`] = true,
    [`weapon_knuckle`] = true,
    [`weapon_knife`] = true,
    [`weapon_machete`] = true,
    [`weapon_switchblade`] = true,
    [`weapon_nightstick`] = true,
    [`weapon_wrench`] = true,
    [`weapon_battleaxe`] = true,
    [`weapon_poolcue`] = true,
    [`weapon_briefcase`] = true,
    [`weapon_briefcase_02`] = true,
    [`weapon_garbagebag`] = true,
    [`weapon_handcuffs`] = true,
    [`weapon_bread`] = true,
    [`weapon_stone_hatchet`] = true,
    -- Throwables
    [`weapon_grenade`] = true,
    [`weapon_bzgas`] = true,
    [`weapon_molotov`] = true,
    [`weapon_stickybomb`] = true,
    [`weapon_proxmine`] = true,
    [`weapon_snowball`] = true,
    [`weapon_pipebomb`] = true,
    [`weapon_ball`] = true,
    [`weapon_smokegrenade`] = true,
    [`weapon_flare`] = true
}

-- Whitelisted weapons (no stress gain)
Config.WhitelistedWeaponStress = {
    [`weapon_petrolcan`] = true,
    [`weapon_hazardcan`] = true,
    [`weapon_fireextinguisher`] = true
}

-- Vehicle class stress settings
Config.VehClassStress = {
    ['0'] = true,         -- Compacts
    ['1'] = true,         -- Sedans
    ['2'] = true,         -- SUVs
    ['3'] = true,         -- Coupes
    ['4'] = true,         -- Muscle
    ['5'] = true,         -- Sports Classics
    ['6'] = true,         -- Sports
    ['7'] = true,         -- Super
    ['8'] = true,         -- Motorcycles
    ['9'] = true,         -- Off Road
    ['10'] = true,        -- Industrial
    ['11'] = true,        -- Utility
    ['12'] = true,        -- Vans
    ['13'] = false,       -- Cycles
    ['14'] = false,       -- Boats
    ['15'] = false,       -- Helicopters
    ['16'] = false,       -- Planes
    ['18'] = false,       -- Emergency
    ['19'] = false,       -- Military
    ['20'] = false,       -- Commercial
    ['21'] = false        -- Trains
}

-- Whitelisted vehicles (no stress from speeding)
Config.WhitelistedVehicles = {
    --[`adder`] = true
}

-- Whitelisted jobs (no stress)
Config.WhitelistedJobs = {
    ['police'] = true,
    ['ambulance'] = true,
    ['mechanic'] = true
}

-- Stress effects configuration
Config.Intensity = {
    ['blur'] = {
        [1] = { min = 50, max = 60, intensity = 1500 },
        [2] = { min = 60, max = 70, intensity = 2000 },
        [3] = { min = 70, max = 80, intensity = 2500 },
        [4] = { min = 80, max = 90, intensity = 2700 },
        [5] = { min = 90, max = 100, intensity = 3000 }
    }
}

Config.EffectInterval = {
    [1] = { min = 50, max = 60, timeout = math.random(50000, 60000) },
    [2] = { min = 60, max = 70, timeout = math.random(40000, 50000) },
    [3] = { min = 70, max = 80, timeout = math.random(30000, 40000) },
    [4] = { min = 80, max = 90, timeout = math.random(20000, 30000) },
    [5] = { min = 90, max = 100, timeout = math.random(15000, 20000) }
}

-- ================================================================
-- VALIDATION & INITIALIZATION
-- ================================================================

-- Validate configuration on resource start
CreateThread(function()
    if Config.Debug then
        print("^3[HUD:CONFIG]^7 Validating enhanced configuration...")
        
        -- Check GPS HUD configuration
        if not Config.GPSHUD.enabled then
            print("^1[HUD:CONFIG] WARNING: GPS HUD is disabled! This is the main interface.^7")
        end
        
        -- Check theme configuration
        local currentTheme = Config.Theme.current
        if not Config.Theme.colors[currentTheme] then
            print(string.format("^1[HUD:CONFIG] ERROR: Theme '%s' not found, falling back to 'neon-magenta'^7", currentTheme))
            Config.Theme.current = 'neon-magenta'
        end
        
        -- Validate voice configuration
        if Config.Voice.enabled and not GetResourceState('pma-voice'):find('start') then
            print("^3[HUD:CONFIG] WARNING: pma-voice not found, voice features may not work^7")
        end
        
        print("^2[HUD:CONFIG]^7 Configuration validation completed successfully")
        print(string.format("^2[HUD:CONFIG]^7 GPS HUD Status: %s", Config.GPSHUD.enabled and "^2ENABLED^7" or "^1DISABLED^7"))
        print(string.format("^2[HUD:CONFIG]^7 Active Theme: ^5%s^7", Config.Theme.current))
        print(string.format("^2[HUD:CONFIG]^7 Voice Integration: %s", Config.Voice.enabled and "^2ENABLED^7" or "^1DISABLED^7"))
    end
end)
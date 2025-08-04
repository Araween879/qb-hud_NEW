-- ================================================================
-- QBCore HUD - Complete Configuration
-- Version: 3.0.0
-- Description: Comprehensive configuration for modular HUD system
-- ================================================================

Config = {}

-- ================================================================
-- CORE SETTINGS
-- ================================================================

Config.Debug = false                    -- Enable debug output
Config.Framework = 'QBCore'            -- Framework type
Config.Version = '3.0.0'               -- HUD version

-- Performance Settings
Config.Performance = {
    optimizeUpdates = true,             -- Optimize update frequencies
    maxFPS = 60,                       -- Target FPS
    lowEndMode = false,                -- Reduce effects for low-end PCs
    enableProfiling = false            -- Performance profiling
}

-- ================================================================
-- THEME SYSTEM (DESIGN-DNA IMPLEMENTATION)
-- ================================================================

Config.Theme = {
    current = 'neon-magenta',          -- Default theme
    available = {                      -- Available themes
        'neon-magenta',
        'neon-cyan',
        'synthwave',
        'classic'
    },
    
    -- Color definitions for each theme
    colors = {
        ['neon-magenta'] = {
            primary = '#B026FF',       -- Magenta/Violett
            secondary = '#0ff',        -- Cyan
            accent = '#FFD700',        -- Gold
            background = '#1a1a1a',    -- Dark background
            backgroundDark = '#111',   -- Darker background
            textPrimary = '#fff',      -- White text
            textSecondary = '#e0e0e0', -- Light gray text
            success = '#00ff88',       -- Green
            warning = '#ffb74d',       -- Orange
            error = '#ff4444',         -- Red
            health = '#ff4444',        -- Health red
            armor = '#00bcd4',         -- Armor cyan
            hunger = '#ffb74d',        -- Hunger orange
            thirst = '#29b6f6',        -- Thirst blue
            stress = '#a020f0',        -- Stress purple
            stamina = '#66bb6a'        -- Stamina green
        },
        
        ['neon-cyan'] = {
            primary = '#0ff',          -- Cyan
            secondary = '#B026FF',     -- Magenta
            accent = '#FFD700',        -- Gold
            background = '#0a1a1a',    -- Dark teal background
            backgroundDark = '#051111', -- Darker teal
            textPrimary = '#fff',
            textSecondary = '#e0f0f0',
            success = '#00ff88',
            warning = '#ffb74d',
            error = '#ff4444',
            health = '#ff4444',
            armor = '#00bcd4',
            hunger = '#ffb74d',
            thirst = '#29b6f6',
            stress = '#a020f0',
            stamina = '#66bb6a'
        },
        
        ['synthwave'] = {
            primary = '#ff0080',       -- Hot pink
            secondary = '#00ffff',     -- Electric cyan
            accent = '#ffff00',        -- Electric yellow
            background = '#1a0a1a',    -- Dark purple background
            backgroundDark = '#110511', -- Darker purple
            textPrimary = '#fff',
            textSecondary = '#f0e0f0',
            success = '#00ff88',
            warning = '#ff8000',
            error = '#ff0040',
            health = '#ff0040',
            armor = '#00ffff',
            hunger = '#ff8000',
            thirst = '#0080ff',
            stress = '#8000ff',
            stamina = '#80ff00'
        },
        
        ['classic'] = {
            primary = '#007acc',       -- Professional blue
            secondary = '#666',        -- Gray
            accent = '#ffa500',        -- Orange
            background = '#2d2d2d',    -- Dark gray
            backgroundDark = '#1e1e1e', -- Darker gray
            textPrimary = '#fff',
            textSecondary = '#ccc',
            success = '#28a745',
            warning = '#ffc107',
            error = '#dc3545',
            health = '#dc3545',
            armor = '#007acc',
            hunger = '#ffc107',
            thirst = '#17a2b8',
            stress = '#6f42c1',
            stamina = '#28a745'
        }
    },
    
    -- Font configuration
    fonts = {
        primary = "'Orbitron', sans-serif",    -- Main font
        secondary = "'Roboto', sans-serif",     -- Secondary font
        monospace = "'Courier New', monospace"  -- Monospace font
    },
    
    -- Animation settings
    animations = {
        enabled = true,
        duration = 300,                -- Default transition duration (ms)
        easing = 'ease',              -- CSS easing function
        glowEffects = true,           -- Enable glow effects
        scanAnimation = true,         -- Enable scanning animations
        scanDuration = 6000,          -- Scan animation duration (ms)
        hoverScale = 1.05,            -- Hover scale factor
        hoverTranslate = -2           -- Hover translate distance (px)
    },
    
    -- Layout settings
    layout = {
        borderRadius = 12,            -- Border radius (px)
        padding = 8,                  -- Default padding (px)
        margin = 12,                  -- Default margin (px)
        shadowBlur = 20,              -- Shadow blur (px)
        shadowSpread = 0,             -- Shadow spread (px)
        shadowOpacity = 0.4           -- Shadow opacity
    }
}

-- ================================================================
-- GPS HUD SYSTEM (HAUPT-INTERFACE)
-- ================================================================

Config.GPSHUD = {
    enabled = true,                   -- Enable GPS HUD system
    position = 'bottom-left',         -- Position on screen
    updateInterval = 200,             -- Update frequency (ms)
    showNavigation = true,            -- Show GPS navigation
    showMinimap = true,              -- Show minimap
    animations = true,               -- Enable animations
    
    -- Components configuration
    components = {
        voice = true,                 -- 🎤 Mikrofon indicator
        health = true,                -- ❤️ Health bar
        armor = true,                 -- 🛡️ Armor bar
        hunger = true,                -- 🍔 Hunger bar
        thirst = true,                -- 💧 Thirst bar
        stress = true,                -- 🧠 Stress bar
        stamina = true,               -- 🏃 Stamina bar
        navigation = true,            -- 🗺️ GPS Navigation
        time = true,                  -- 🕐 Time display
        money = true,                 -- 💰 Money display
        location = true               -- 📍 Location display
    },
    
    -- Visual settings
    visual = {
        showWhenFull = false,         -- Hide bars when at 100%
        lowHealthWarning = 25,        -- Health warning threshold
        lowArmorWarning = 25,         -- Armor warning threshold
        lowHungerWarning = 25,        -- Hunger warning threshold
        lowThirstWarning = 25,        -- Thirst warning threshold
        highStressWarning = 75,       -- Stress warning threshold
        blinkOnLow = true,            -- Blink when values are low
        showPercentage = false,       -- Show percentage values
        compactMode = false           -- Compact display mode
    },
    
    -- Audio settings
    audio = {
        enabled = true,               -- Enable audio feedback
        lowHealthSound = true,        -- Low health warning sound
        stressSound = true,           -- Stress warning sound
        voiceSound = true,            -- Voice activity sound
        volume = 0.3                  -- Audio volume (0-1)
    },
    
    -- Advanced settings
    advanced = {
        smoothTransitions = true,     -- Smooth value transitions
        predictiveUpdates = false,    -- Predictive value updates
        adaptiveRefresh = true,       -- Adaptive refresh rates
        batteryOptimization = false,  -- Battery optimization mode
        accessibilityMode = false,    -- Accessibility enhancements
        colorblindSupport = false     -- Colorblind-friendly colors
    },
    
    -- Interaction settings
    interaction = {
        clickableIcons = true,        -- Allow clicking on status icons
        hoverEffects = true,          -- Hover effects on elements
        statusDetails = true,         -- Show detailed info on click
        voiceLevelCycle = true,       -- Allow cycling voice levels
        quickSettings = true,         -- Quick settings access
        contextMenu = false           -- Right-click context menu
    }
}

-- ================================================================
-- MODULE CONFIGURATION
-- ================================================================

Config.Modules = {
    -- GPS HUD System (HAUPT-INTERFACE)
    gps_hud = {
        enabled = true,
        priority = 1,                 -- Load order priority
        position = 'bottom-left',
        updateInterval = 200,         -- Fast updates for all status
        showNavigation = true,
        showMinimap = true,
        animations = true,
        essential = true,             -- Cannot be disabled by user
        components = Config.GPSHUD.components
    },
    
    -- UI Manager Module
    ui_manager = {
        enabled = true,
        priority = 2,
        cinematicMode = false,
        scaling = 1.0,
        opacity = 0.9,
        enableGlowEffects = true,
        enableAnimations = true,
        theme = Config.Theme.current
    },
    
    -- Health System Module (DEAKTIVIERT - GPS-HUD übernimmt)
    health = {
        enabled = false,              -- ❌ Deaktiviert
        position = 'bottom-left',
        updateInterval = 500,
        showWhenFull = false,
        animations = true,
        components = {
            health = false,           -- Im GPS-HUD integriert
            armor = false,            -- Im GPS-HUD integriert
            hunger = false,           -- Im GPS-HUD integriert
            thirst = false,           -- Im GPS-HUD integriert
            stress = false,           -- Im GPS-HUD integriert
            stamina = false,          -- Im GPS-HUD integriert
            oxygen = false            -- Im GPS-HUD integriert
        }
    },
    
    -- Status System Module (DEAKTIVIERT - GPS-HUD übernimmt)
    status = {
        enabled = false,              -- ❌ Deaktiviert
        position = 'bottom-center',
        updateInterval = 200,
        showIcons = true,
        animations = true,
        components = {
            voice = false,            -- Im GPS-HUD integriert
            radio = false,            -- Im GPS-HUD integriert
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
        priority = 6,
        position = 'top-right',
        updateInterval = 1000,        -- Update every second
        format24h = true,             -- 24-hour format vs 12-hour
        showDate = true,
        showWeather = false,          -- Requires weather sync resource
        animations = true,
        components = {
            time = true,
            date = true,
            weather = false,
            temperature = false
        }
    },
    
    -- Location System Module
    location = {
        enabled = true,
        priority = 7,
        position = 'top-center',
        updateInterval = 1500,        -- Update street names every 1.5s
        showStreetNames = true,
        showZoneName = true,
        showPointer = true,
        showDegrees = true,
        annotations = true,
        components = {
            street = true,
            zone = true,
            direction = true,
            coordinates = false,
            postal = false
        }
    },
    
    -- Vehicle System Module
    vehicle = {
        enabled = true,
        priority = 8,
        position = 'bottom-right',
        updateInterval = 200,         -- Fast updates for speed
        showInVehicleOnly = true,     -- Only show when in vehicle
        showSpeedometer = true,
        showFuelGauge = true,
        showEngine = true,
        showNitro = false,
        showSeatbelt = true,
        showAltitude = true,          -- For aircraft
        useMPH = true,               -- false for KPH
        animations = true,
        components = {
            speed = true,
            fuel = true,
            engine = true,
            altitude = true,
            gear = false,
            rpm = false,
            nitro = false,
            seatbelt = true,
            cruise = true
        }
    },
    
    -- Menu System Module
    menu_ui = {
        enabled = true,
        priority = 9,
        openKey = 'I',               -- Default key to open HUD menu
        enableSounds = true,
        saveSettings = true,         -- Save settings to localStorage
        theme = Config.Theme.current,
        components = {
            settings = true,
            themes = true,
            modules = true,
            performance = true,
            about = true
        }
    },
    
    -- Export API System
    export_api = {
        enabled = true,
        priority = 2,
        enableLogging = Config.Debug,
        components = {
            visibility = true,
            themes = true,
            modules = true,
            callbacks = true,
            events = true
        }
    },
    
    -- Extensions System
    extensions = {
        enabled = true,
        priority = 999,              -- Load last
        autoLoad = true,             -- Automatically load files from extensions/
        allowCustomModules = true,
        components = {
            navigation = false,
            biometrics = false,
            environment = false,
            communication = false,
            custom = false
        }
    }
}

-- ================================================================
-- KEYBIND CONFIGURATION
-- ================================================================

Config.Keybinds = {
    openMenu = 'I',                  -- Open HUD menu
    toggleHUD = 'F2',                -- Toggle HUD visibility
    toggleCinematic = 'F1',          -- Toggle cinematic mode
    cycleVoice = 'F3',              -- Cycle voice levels
    toggleMap = 'M',                 -- Toggle minimap
    quickSettings = 'F9'             -- Quick settings menu
}

-- ================================================================
-- LOCALIZATION SETTINGS
-- ================================================================

Config.Locale = {
    default = 'en',                  -- Default language
    available = { 'en', 'de', 'fr', 'es', 'it', 'pl', 'ru' },
    autoDetect = true,               -- Auto-detect from client
    fallback = 'en'                  -- Fallback language
}

-- ================================================================
-- COMPATIBILITY SETTINGS
-- ================================================================

Config.Compatibility = {
    frameworks = {
        qbcore = true,               -- QBCore support
        esx = false,                 -- ESX support (future)
        standalone = false           -- Standalone mode
    },
    
    resources = {
        legacyFuel = true,           -- LegacyFuel integration
        pmaVoice = true,             -- PMA-Voice integration
        interactSound = true,        -- interact-sound support
        qbMenu = true,               -- qb-menu integration
        weatherSync = false,         -- Weather sync support
        qbTarget = true,             -- qb-target integration
        oxTarget = false             -- ox_target integration
    },
    
    scripts = {
        seatbelt = true,             -- Seatbelt system
        cruise = true,               -- Cruise control
        harness = false,             -- Racing harness
        nitro = false,               -- Nitro system
        racing = false               -- Racing scripts
    }
}

-- ================================================================
-- ADVANCED SETTINGS
-- ================================================================

Config.Advanced = {
    -- Performance optimization
    optimization = {
        enableCaching = true,        -- Enable data caching
        cacheTimeout = 5000,         -- Cache timeout (ms)
        batchUpdates = true,         -- Batch NUI updates
        throttleUpdates = true,      -- Throttle rapid updates
        useWebWorkers = false,       -- Use web workers (experimental)
        enableProfiling = false      -- Enable performance profiling
    },
    
    -- Security settings
    security = {
        validateInputs = true,       -- Validate all inputs
        sanitizeData = true,         -- Sanitize data before processing
        rateLimiting = true,         -- Rate limit requests
        encryptSettings = false,     -- Encrypt stored settings
        auditLog = false            -- Enable audit logging
    },
    
    -- Developer options
    developer = {
        enableDevMode = Config.Debug, -- Enable developer mode
        showFPS = false,             -- Show FPS counter
        showMemory = false,          -- Show memory usage
        enableConsole = Config.Debug, -- Enable debug console
        verboseLogging = false,      -- Verbose logging
        enableMetrics = false        -- Enable performance metrics
    },
    
    -- Experimental features
    experimental = {
        useGPU = false,              -- GPU acceleration (experimental)
        predictiveLoading = false,   -- Predictive resource loading
        adaptiveUI = false,          -- Adaptive UI scaling
        voiceRecognition = false,    -- Voice commands (future)
        gestureControl = false       -- Gesture controls (future)
    }
}

-- ================================================================
-- VALIDATION & INITIALIZATION
-- ================================================================

-- Validate configuration on load
CreateThread(function()
    Wait(100)
    
    -- Validate theme configuration
    if not Config.Theme.colors[Config.Theme.current] then
        print("^3[HUD-CONFIG] Invalid theme, falling back to neon-magenta^7")
        Config.Theme.current = 'neon-magenta'
    end
    
    -- Validate module priorities
    local priorities = {}
    for name, module in pairs(Config.Modules) do
        if module.enabled and module.priority then
            if priorities[module.priority] then
                print(string.format("^3[HUD-CONFIG] Duplicate priority %d for modules %s and %s^7", 
                      module.priority, name, priorities[module.priority]))
            else
                priorities[module.priority] = name
            end
        end
    end
    
    -- Validate keybinds
    local keybinds = {}
    for action, key in pairs(Config.Keybinds) do
        if keybinds[key] then
            print(string.format("^3[HUD-CONFIG] Duplicate keybind %s for actions %s and %s^7", 
                  key, action, keybinds[key]))
        else
            keybinds[key] = action
        end
    end
    
    if Config.Debug then
        print("^2[HUD-CONFIG] Configuration validated successfully^7")
    end
end)
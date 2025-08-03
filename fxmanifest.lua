fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'QBCore Framework'
description 'Enhanced Modular HUD System with GPS Interface - Next Generation HUD for QBCore'
version '3.0.0'

-- Shared Scripts
shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/de.lua',
    'config.lua'
}

-- Client Scripts - Modular Loading System
client_scripts {
    'init.lua',                      -- Master Module Loader & Coordinator
    'client/ui_manager.lua',         -- UI Manager (loads first)
    'client/export_api.lua',         -- Export API System (loads second)
    'client/gps_hud.lua',           -- GPS HUD System (MAIN INTERFACE)
    'client/health.lua',            -- Health System Module (backup/optional)
    'client/status.lua',            -- Status System Module (backup/optional)
    'client/time.lua',              -- Time & Weather System
    'client/location.lua',          -- Location & Streets System
    'client/vehicle.lua',           -- Vehicle HUD System
    'client/menu_ui.lua',           -- Settings Menu System
    'client/extensions/*.lua'       -- Future Extensions (optional)
}

-- Server Scripts
server_script 'server.lua'

-- NUI Resources
ui_page 'html/index.html'

-- Files for NUI
files {
    -- HTML Files
    'html/**/*',
    'html/index.html',
    'html/gps-hud.html',
    
    -- CSS Files
    'html/style.css',
    'html/ui-theme.css',
    'html/responsive.css',
    
    -- JavaScript Files
    'html/js/main.js',
    'html/js/modules/*.js',
    
    -- Module Templates
    'html/modules/*.html',
    
    -- Assets
    'html/assets/*',
    'html/fonts/*'
}

-- Dependencies
dependencies {
    'qb-core',
    'pma-voice'                     -- ✅ Voice System Integration
}

-- Optional Dependencies (graceful degradation if missing)
optional_dependencies {
    'LegacyFuel',                   -- Fuel System Integration
    'interact-sound',               -- Sound Effects
    'qb-menu',                      -- Settings Menu System
    'weathersync'                   -- Weather Integration
}

-- Resource Information
provide 'qb-hud'
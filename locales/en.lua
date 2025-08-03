local Translations = {
    notify = {
        -- 🔧 HUD System Notifications
        hud_settings_loaded = '🎯 HUD Settings loaded successfully',
        hud_restart = '⚡ Restarting Enhanced Neon HUD...',
        hud_start = '✅ Enhanced Neon HUD started successfully',
        
        -- 🎨 Theme System
        theme_changed = '🎨 Neon Theme changed: %{theme}',
        theme_cyberpunk = '🔵 Cyberpunk Protocol activated',
        theme_synthwave = '🟣 Synthwave Protocol activated', 
        theme_matrix = '🟢 Matrix Protocol activated',
        glow_intensity = '✨ Glow intensity set to: %{intensity}',
        
        -- 🗺️ GPS & Navigation
        gps_activated = '📍 GPS Navigation System: ONLINE',
        gps_deactivated = '📍 GPS Navigation System: OFFLINE',
        load_square_map = '🗺️ Loading Square Map Matrix...',
        loaded_square_map = '✅ Square Map Matrix loaded successfully',
        load_circle_map = '🗺️ Loading Circle Map Matrix...',
        loaded_circle_map = '✅ Circle Map Matrix loaded successfully',
        
        -- 🚗 Vehicle System
        low_fuel = '⛽ CRITICAL: Fuel level dangerously low!',
        engine_critical = '🔧 WARNING: Engine performance critical!',
        seatbelt_warning = '🚨 SAFETY: Seatbelt not engaged!',
        cruise_activated = '🎯 Cruise Control: ENGAGED',
        cruise_deactivated = '🎯 Cruise Control: DISENGAGED',
        nitro_activated = '🚀 NITRO: System charged and ready!',
        
        -- ⚡ Critical Health & Status
        health_critical = '🩸 CRITICAL: Health dangerously low!',
        armor_critical = '🛡️ WARNING: Armor critically damaged!',
        hunger_critical = '🍕 CRITICAL: Nutrition levels extremely low!',
        thirst_critical = '💧 CRITICAL: Dehydration warning!',
        stress_critical = '🧠 DANGER: Stress levels at maximum!',
        stress_high = '😰 WARNING: High stress detected',
        stress_gain = '📈 Stress level increased',
        stress_relieved = '😌 Stress levels normalized',
        stress_removed = '📉 Stress reduced',
        oxygen_critical = '🫁 EMERGENCY: Oxygen supply critical!',
        
        -- 🎮 Cinematic & Display
        cinematic_on = '🎬 Cinematic Mode: ACTIVATED',
        cinematic_off = '🎬 Cinematic Mode: DEACTIVATED',
        
        -- 🔊 Audio System
        menu_sounds = '🔊 Menu Audio: %{status}',
        system_sounds = '🎵 System Audio: %{status}',
        
        -- ⚙️ Performance & Settings
        performance_mode = '⚡ Performance Mode: %{mode}',
        settings_saved = '💾 HUD Settings saved successfully',
        settings_reset = '🔄 Settings reset to factory defaults',
        
        -- 🔗 Network & Connection
        server_sync = '🌐 Server synchronization complete',
        client_ready = '✅ Enhanced HUD client ready',
        
        -- 🛠️ Developer & Debug
        dev_mode_on = '🔧 Developer Mode: ACTIVATED',
        dev_mode_off = '🔧 Developer Mode: DEACTIVATED',
        debug_info = '🐛 Debug: %{info}',
        
        -- 🚨 Error Handling
        error_generic = '❌ ERROR: %{error}',
        error_theme_load = '❌ Failed to load theme: %{theme}',
        error_settings_load = '❌ Failed to load HUD settings',
        error_gps_init = '❌ GPS System initialization failed',
        
        -- 💰 Money & Economy
        money_gained = '💰 +$%{amount}',
        money_lost = '💸 -$%{amount}',
        bank_deposit = '🏦 Bank: +$%{amount}',
        bank_withdrawal = '🏦 Bank: -$%{amount}',
        
        -- 🔄 Status Updates
        status_updated = '📊 %{stat} updated: %{value}%',
        stat_normalized = '✅ %{stat} levels normalized',
        stat_warning = '⚠️ %{stat} requires attention',
        
        -- 🎯 Achievement & Progress
        milestone_reached = '🏆 Milestone: %{achievement}',
        level_up = '⬆️ Level Up: %{stat}',
        
        -- 🔧 System Maintenance
        system_update = '🔄 System updating...',
        system_ready = '✅ All systems operational',
        maintenance_mode = '🛠️ Maintenance Mode: %{status}',
        
        -- 🎨 UI Feedback
        ui_element_activated = '✨ %{element}: ACTIVATED',
        ui_element_deactivated = '⚪ %{element}: DEACTIVATED',
        animation_triggered = '🎬 %{animation} animation triggered',
        
        -- 🌐 Multiplayer
        player_joined = '👋 %{player} joined the session',
        player_left = '👋 %{player} left the session',
        sync_complete = '🔄 Player data synchronized',
    },
    
    error = {
        -- 🚨 Critical Errors
        critical_system_failure = 'CRITICAL: HUD system failure detected',
        memory_overflow = 'ERROR: Memory overflow in HUD system',
        resource_conflict = 'WARNING: Resource conflict detected',
        initialization_failed = 'FATAL: HUD initialization failed',
        
        -- 🔧 Configuration Errors
        invalid_config = 'ERROR: Invalid configuration detected',
        missing_dependency = 'ERROR: Missing required dependency: %{dep}',
        version_mismatch = 'WARNING: Framework version mismatch',
        
        -- 🗺️ GPS Errors
        gps_unavailable = 'ERROR: GPS system unavailable',
        location_not_found = 'WARNING: Location data not found',
        navigation_failed = 'ERROR: Navigation calculation failed',
        
        -- 🎨 Theme Errors
        theme_not_found = 'ERROR: Theme "%{theme}" not found',
        theme_corrupt = 'ERROR: Theme data corrupted',
        css_load_failed = 'ERROR: Failed to load theme CSS',
        
        -- 📡 Network Errors
        server_timeout = 'ERROR: Server connection timeout',
        sync_failed = 'WARNING: Data synchronization failed',
        connection_lost = 'ERROR: Connection to server lost',
        
        -- 💾 Data Errors
        save_failed = 'ERROR: Failed to save HUD settings',
        load_failed = 'ERROR: Failed to load saved data',
        data_corrupted = 'WARNING: Data file corrupted',
        
        -- 🎮 Performance Errors
        low_fps = 'WARNING: Low FPS detected - consider performance mode',
        memory_leak = 'WARNING: Potential memory leak detected',
        resource_heavy = 'WARNING: High resource usage detected',
    },
    
    ui = {
        -- 📋 Menu Labels
        menu_title = 'ENHANCED NEON HUD',
        menu_subtitle = 'Advanced Interface Control System',
        
        -- 🎯 Tab Names
        tab_hud_system = 'HUD System',
        tab_neon_themes = 'Neon Themes',
        tab_performance = 'Performance',
        tab_advanced = 'Advanced',
        
        -- 🔘 Button Labels
        btn_reset_settings = 'RESET SETTINGS',
        btn_restart_hud = 'RESTART HUD',
        btn_apply_theme = 'APPLY THEME',
        btn_save_config = 'SAVE CONFIG',
        btn_load_defaults = 'LOAD DEFAULTS',
        btn_export_settings = 'EXPORT SETTINGS',
        btn_import_settings = 'IMPORT SETTINGS',
        
        -- ⚙️ Setting Categories
        category_interface = 'INTERFACE OPTIONS',
        category_notifications = 'NOTIFICATION MATRIX',
        category_biometrics = 'BIOMETRIC STATUS',
        category_vehicle = 'VEHICLE INTERFACE',
        category_navigation = 'NAVIGATION SYSTEM',
        category_themes = 'THEME CONFIGURATION',
        category_performance = 'PERFORMANCE SETTINGS',
        
        -- 📊 Status Labels
        status_enabled = 'ENABLED',
        status_disabled = 'DISABLED',
        status_active = 'ACTIVE',
        status_inactive = 'INACTIVE',
        status_online = 'ONLINE',
        status_offline = 'OFFLINE',
        status_synced = 'SYNCED',
        status_optimized = 'OPTIMIZED',
        
        -- 🎨 Theme Names
        theme_cyberpunk_name = 'CYBERPUNK PROTOCOL',
        theme_cyberpunk_desc = 'High-tech cyan and purple aesthetic with digital matrix elements',
        theme_synthwave_name = 'SYNTHWAVE PROTOCOL', 
        theme_synthwave_desc = 'Retro-futuristic pink and blue neon with 80s aesthetic elements',
        theme_matrix_name = 'MATRIX PROTOCOL',
        theme_matrix_desc = 'Classic green matrix code aesthetic with digital rain effects',
        
        -- 📍 GPS Interface
        gps_title = 'GPS NAVIGATION MATRIX',
        gps_location = 'Current Location',
        gps_destination = 'Destination',
        gps_distance = 'Distance',
        gps_eta = 'Estimated Time',
        gps_status = 'Navigation Status',
        
        -- 🚗 Vehicle Status
        vehicle_speed = 'Speed',
        vehicle_fuel = 'Fuel Level',
        vehicle_engine = 'Engine Health',
        vehicle_altitude = 'Altitude',
        vehicle_gear = 'Current Gear',
        
        -- 💊 Health Status
        health_level = 'Health Level',
        armor_level = 'Armor Level',
        hunger_level = 'Nutrition Level',
        thirst_level = 'Hydration Level',
        stress_level = 'Stress Level',
        oxygen_level = 'Oxygen Level',
        stamina_level = 'Stamina Level',
        
        -- 🔊 Audio Labels
        audio_menu_sounds = 'Menu Audio Protocols',
        audio_system_sounds = 'System Reset Audio',
        audio_interface_feedback = 'Interface Feedback',
        audio_navigation_alerts = 'Navigation Alerts',
        audio_critical_warnings = 'Critical Fuel Warning',
        audio_cinematic_alerts = 'Cinematic Mode Alerts',
        
        -- ⚡ Performance Labels
        performance_fps_mode = 'Performance Mode',
        performance_fps_synced = 'Synced',
        performance_fps_optimized = 'Optimized',
        performance_compass_refresh = 'Compass Refresh',
        performance_reduced_animations = 'Reduced Animations',
        performance_high_quality = 'High Quality Effects',
        
        -- 🗺️ Map Labels
        map_minimap_mode = 'Minimap Vehicle Mode',
        map_compass_mode = 'Compass Vehicle Mode',
        map_camera_sync = 'Camera Compass Sync',
        map_shape_format = 'Minimap Format',
        map_shape_circle = 'circle',
        map_shape_square = 'square',
        map_borders = 'Minimap Border Enhancement',
        map_interface_active = 'Minimap Interface Active',
        
        -- 🧭 Navigation Labels
        nav_compass_active = 'Compass Navigation Active',
        nav_streets_system = 'Street Identification System',
        nav_directional_pointer = 'Directional Pointer Active',
        nav_degrees_display = 'Degrees Measurement Display',
        
        -- 🎬 Cinematic Labels
        cinematic_mode = 'Immersive Cinema Mode',
        cinematic_status = 'Cinematic Status',
        
        -- 💾 Data Labels
        data_current_theme = 'Current Theme',
        data_last_saved = 'Last Saved',
        data_sync_status = 'Sync Status',
        data_version = 'HUD Version',
        
        -- 🔧 Advanced Labels
        advanced_developer_mode = 'Developer Mode',
        advanced_debug_mode = 'Debug Mode',
        advanced_performance_monitor = 'Performance Monitor',
        advanced_memory_usage = 'Memory Usage',
        advanced_resource_monitor = 'Resource Monitor',
        
        -- 📊 Statistics Labels
        stats_uptime = 'System Uptime',
        stats_total_players = 'Total Players',
        stats_server_performance = 'Server Performance',
        stats_client_fps = 'Client FPS',
        stats_ping = 'Network Ping',
        
        -- 🔄 Status Messages
        msg_loading = 'Loading...',
        msg_processing = 'Processing...',
        msg_saving = 'Saving...',
        msg_syncing = 'Syncing...',
        msg_optimizing = 'Optimizing...',
        msg_initializing = 'Initializing...',
        msg_restarting = 'Restarting...',
        msg_complete = 'Complete',
        msg_failed = 'Failed',
        msg_ready = 'Ready',
    },
    
    help = {
        -- 📖 Help Text & Tooltips
        tooltip_reset_settings = 'Initialize default configuration protocols and restore factory settings',
        tooltip_restart_hud = 'Reboot HUD interface systems and reinitialize display matrix',
        tooltip_minimap_vehicle = 'Activate minimap display only when operating vehicles',
        tooltip_compass_vehicle = 'Display navigation compass exclusively during vehicle operation',
        tooltip_camera_sync = 'Synchronize compass orientation with camera movement controls',
        tooltip_theme_cyberpunk = 'Activate high-tech cyan and purple visual protocol',
        tooltip_theme_synthwave = 'Enable retro-futuristic pink and blue aesthetic matrix',
        tooltip_theme_matrix = 'Initialize classic green matrix code visual system',
        tooltip_performance_mode = 'Optimize rendering frequency for enhanced performance',
        tooltip_glow_effects = 'Enable luminous glow effects for enhanced visual impact',
        tooltip_animations = 'Activate smooth transitions and animated interface elements',
        tooltip_critical_alerts = 'Enable enhanced visual warnings for critical system states',
        tooltip_particles = 'Add atmospheric particle systems for immersive experience',
        
        -- 📚 Instructions
        instruction_first_setup = 'Welcome to Enhanced Neon HUD! Configure your preferences below.',
        instruction_theme_selection = 'Choose a visual theme that matches your preference.',
        instruction_performance = 'Adjust performance settings based on your system capabilities.',
        instruction_save_reminder = 'Remember to save your settings before closing the menu.',
        
        -- 🎮 Keybind Help
        keybind_menu = 'Press %{key} to open HUD menu',
        keybind_gps = 'Press %{key} to toggle GPS HUD',
        keybind_cinematic = 'Press %{key} for cinematic mode',
        keybind_performance = 'Press %{key} to toggle performance mode',
        
        -- 🔧 Troubleshooting
        troubleshoot_performance = 'If experiencing low FPS, enable Performance Mode',
        troubleshoot_sync = 'If settings not saving, check server connection',
        troubleshoot_theme = 'If theme not loading, restart HUD system',
        troubleshoot_gps = 'If GPS not working, check navigation permissions',
    },
    
    success = {
        -- ✅ Success Messages
        settings_applied = 'Settings successfully applied',
        theme_activated = 'Theme successfully activated',
        performance_optimized = 'Performance successfully optimized',
        sync_completed = 'Synchronization completed successfully',
        backup_created = 'Backup created successfully',
        export_completed = 'Settings exported successfully',
        import_completed = 'Settings imported successfully',
        reset_completed = 'Reset completed successfully',
        restart_completed = 'System restart completed successfully',
    },
    
    warning = {
        -- ⚠️ Warning Messages
        performance_impact = 'This setting may impact performance',
        restart_required = 'Restart required for changes to take effect',
        unsaved_changes = 'You have unsaved changes',
        experimental_feature = 'This is an experimental feature',
        high_resource_usage = 'High resource usage detected',
        network_unstable = 'Network connection unstable',
        low_memory = 'Low memory available',
        compatibility_issue = 'Potential compatibility issue detected',
    }
}

return Translations
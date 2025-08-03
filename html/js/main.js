/* ================================================================
   QBCore HUD - Main JavaScript Controller
   Version: 3.0.0
   Description: Central HUD management system with Neon Design DNA
   ================================================================ */

class HUDManager {
    constructor() {
        this.modules = new Map();
        this.theme = 'neon-magenta';
        this.debug = false;
        this.isVisible = true;
        this.cinematicMode = false;
        this.settings = this.loadSettings();
        
        // Initialize after DOM is ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.init());
        } else {
            this.init();
        }
    }

    init() {
        console.log('[HUD:MAIN] Initializing HUD Manager...');
        
        // Apply saved settings
        this.applySettings();
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Initialize modules
        this.initializeModules();
        
        // Setup settings menu
        this.setupSettingsMenu();
        
        console.log('[HUD:MAIN] HUD Manager initialized successfully');
    }

    // ================================================================
    // MODULE MANAGEMENT
    // ================================================================

    registerModule(name, module) {
        if (!name || typeof module !== 'object') {
            console.error(`[HUD:MAIN] Failed to register module: Invalid parameters`);
            return false;
        }
        
        this.modules.set(name, module);
        console.log(`[HUD:MAIN] Module '${name}' registered successfully`);
        return true;
    }

    initializeModules() {
        // Initialize modules in proper order
        const initOrder = ['health', 'status', 'time', 'location', 'vehicle'];
        
        initOrder.forEach(moduleName => {
            const module = this.modules.get(moduleName);
            if (module && typeof module.init === 'function') {
                try {
                    module.init();
                    console.log(`[HUD:MAIN] Module '${moduleName}' initialized`);
                } catch (error) {
                    console.error(`[HUD:MAIN] Failed to initialize module '${moduleName}':`, error);
                }
            }
        });
    }

    updateModule(name, data) {
        const module = this.modules.get(name);
        if (module && typeof module.update === 'function') {
            try {
                module.update(data);
            } catch (error) {
                console.error(`[HUD:MAIN] Failed to update module '${name}':`, error);
            }
        }
    }

    toggleModule(name, visible) {
        const element = document.getElementById(`module-${name}`);
        if (element) {
            if (visible) {
                element.classList.remove('hidden');
                element.classList.add('visible', 'fade-in');
            } else {
                element.classList.add('hidden');
                element.classList.remove('visible');
            }
        }
        
        // Update settings
        if (this.settings.modules) {
            this.settings.modules[name] = visible;
            this.saveSettings();
        }
    }

    // ================================================================
    // THEME MANAGEMENT
    // ================================================================

    setTheme(theme) {
        // Remove old theme class
        document.body.classList.remove(`theme-${this.theme}`);
        
        // Add new theme class
        document.body.classList.add(`theme-${theme}`);
        
        this.theme = theme;
        this.settings.theme = theme;
        this.saveSettings();
        
        // Update theme selector if open
        const themeSelector = document.getElementById('theme-selector');
        if (themeSelector) {
            themeSelector.value = theme;
        }
        
        console.log(`[HUD:MAIN] Theme changed to: ${theme}`);
    }

    // ================================================================
    // UI CONTROL
    // ================================================================

    setVisibility(visible) {
        this.isVisible = visible;
        const hudContainer = document.getElementById('hud-container');
        
        if (hudContainer) {
            if (visible) {
                hudContainer.classList.remove('hidden');
                hudContainer.classList.add('visible');
            } else {
                hudContainer.classList.add('hidden');
                hudContainer.classList.remove('visible');
            }
        }
    }

    setCinematicMode(enabled) {
        this.cinematicMode = enabled;
        const cinematicBars = document.getElementById('cinematic-bars');
        
        if (cinematicBars) {
            if (enabled) {
                cinematicBars.classList.remove('hidden');
                cinematicBars.classList.add('visible');
            } else {
                cinematicBars.classList.add('hidden');
                cinematicBars.classList.remove('visible');
            }
        }
        
        // Hide/show main HUD elements during cinematic mode
        const modules = ['health', 'status', 'time'];
        modules.forEach(moduleName => {
            const moduleElement = document.getElementById(`module-${moduleName}`);
            if (moduleElement) {
                if (enabled) {
                    moduleElement.style.opacity = '0.3';
                } else {
                    moduleElement.style.opacity = '';
                }
            }
        });
    }

    // ================================================================
    // SETTINGS MANAGEMENT
    // ================================================================

    loadSettings() {
        try {
            const saved = localStorage.getItem('qb-hud-settings');
            return saved ? JSON.parse(saved) : this.getDefaultSettings();
        } catch (error) {
            console.error('[HUD:MAIN] Failed to load settings:', error);
            return this.getDefaultSettings();
        }
    }

    saveSettings() {
        try {
            localStorage.setItem('qb-hud-settings', JSON.stringify(this.settings));
        } catch (error) {
            console.error('[HUD:MAIN] Failed to save settings:', error);
        }
    }

    getDefaultSettings() {
        return {
            theme: 'neon-magenta',
            modules: {
                health: true,
                status: true,
                time: true,
                location: true,
                vehicle: true
            },
            ui: {
                scaling: 1.0,
                opacity: 0.9,
                animations: true,
                glowEffects: true
            }
        };
    }

    applySettings() {
        // Apply theme
        this.setTheme(this.settings.theme);
        
        // Apply module visibility
        Object.entries(this.settings.modules).forEach(([name, visible]) => {
            const element = document.getElementById(`module-${name}`);
            if (element) {
                if (visible) {
                    element.classList.remove('hidden');
                    element.classList.add('visible');
                } else {
                    element.classList.add('hidden');
                    element.classList.remove('visible');
                }
            }
        });
        
        // Apply UI settings
        if (this.settings.ui) {
            const hudContainer = document.getElementById('hud-container');
            if (hudContainer) {
                hudContainer.style.transform = `scale(${this.settings.ui.scaling})`;
                hudContainer.style.opacity = this.settings.ui.opacity;
            }
        }
    }

    // ================================================================
    // SETTINGS MENU
    // ================================================================

    setupSettingsMenu() {
        const closeBtn = document.getElementById('close-settings');
        const themeSelector = document.getElementById('theme-selector');
        
        // Close button
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.hideSettingsMenu());
        }
        
        // Theme selector
        if (themeSelector) {
            themeSelector.value = this.theme;
            themeSelector.addEventListener('change', (e) => {
                this.setTheme(e.target.value);
            });
        }
        
        // Module toggles
        const moduleToggles = ['health-toggle', 'status-toggle', 'time-toggle'];
        moduleToggles.forEach(toggleId => {
            const toggle = document.getElementById(toggleId);
            if (toggle) {
                const moduleName = toggleId.replace('-toggle', '');
                toggle.checked = this.settings.modules[moduleName];
                toggle.addEventListener('change', (e) => {
                    this.toggleModule(moduleName, e.target.checked);
                });
            }
        });
    }

    showSettingsMenu() {
        const menu = document.getElementById('settings-menu');
        if (menu) {
            menu.classList.remove('hidden');
            menu.classList.add('visible', 'fade-in');
        }
    }

    hideSettingsMenu() {
        const menu = document.getElementById('settings-menu');
        if (menu) {
            menu.classList.add('hidden');
            menu.classList.remove('visible');
        }
    }

    // ================================================================
    // EVENT HANDLING
    // ================================================================

    setupEventListeners() {
        // NUI Message Handler
        window.addEventListener('message', (event) => {
            this.handleMessage(event.data);
        });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (event) => {
            // ESC to close settings menu
            if (event.key === 'Escape') {
                this.hideSettingsMenu();
            }
        });
        
        // Prevent context menu
        document.addEventListener('contextmenu', (event) => {
            event.preventDefault();
        });
    }

    handleMessage(data) {
        if (!data || !data.action) return;
        
        try {
            switch (data.action) {
                case 'updateModule':
                    if (data.module && data.data) {
                        this.updateModule(data.module, data.data);
                    }
                    break;
                    
                case 'toggleModule':
                    if (data.module && data.hasOwnProperty('visible')) {
                        this.toggleModule(data.module, data.visible);
                    }
                    break;
                    
                case 'setTheme':
                    if (data.theme) {
                        this.setTheme(data.theme);
                    }
                    break;
                    
                case 'setVisibility':
                    if (data.hasOwnProperty('visible')) {
                        this.setVisibility(data.visible);
                    }
                    break;
                    
                case 'setCinematicMode':
                    if (data.hasOwnProperty('enabled')) {
                        this.setCinematicMode(data.enabled);
                    }
                    break;
                    
                case 'showSettings':
                    this.showSettingsMenu();
                    break;
                    
                case 'hideSettings':
                    this.hideSettingsMenu();
                    break;
                    
                case 'showMoney':
                    this.showMoneyDisplay(data.data);
                    break;
                    
                case 'hideMoney':
                    this.hideMoneyDisplay();
                    break;
                    
                case 'updateMoney':
                    this.updateMoney(data.data);
                    break;
                    
                default:
                    if (this.debug) {
                        console.log(`[HUD:MAIN] Unknown action: ${data.action}`);
                    }
                    break;
            }
        } catch (error) {
            console.error('[HUD:MAIN] Error handling message:', error, data);
        }
    }

    // ================================================================
    // MONEY DISPLAY METHODS
    // ================================================================

    showMoneyDisplay(data) {
        const cashDisplay = document.getElementById('money-cash');
        const bankDisplay = document.getElementById('money-bank');
        
        if (data.cash !== undefined && cashDisplay) {
            document.getElementById('cash-amount').textContent = this.formatMoney(data.cash);
            cashDisplay.classList.remove('hidden');
            cashDisplay.classList.add('visible', 'fade-in');
        }
        
        if (data.bank !== undefined && bankDisplay) {
            document.getElementById('bank-amount').textContent = this.formatMoney(data.bank);
            bankDisplay.classList.remove('hidden');
            bankDisplay.classList.add('visible', 'fade-in');
        }
    }

    hideMoneyDisplay() {
        const cashDisplay = document.getElementById('money-cash');
        const bankDisplay = document.getElementById('money-bank');
        
        if (cashDisplay) {
            cashDisplay.classList.add('hidden');
            cashDisplay.classList.remove('visible');
        }
        
        if (bankDisplay) {
            bankDisplay.classList.add('hidden');
            bankDisplay.classList.remove('visible');
        }
    }

    updateMoney(data) {
        if (data.type && data.amount !== undefined) {
            const changeDisplay = document.getElementById('money-change');
            const changeSymbol = document.getElementById('change-symbol');
            const changeAmount = document.getElementById('change-amount');
            
            if (changeDisplay && changeSymbol && changeAmount) {
                // Update change display
                changeSymbol.textContent = data.amount >= 0 ? '+' : '-';
                changeSymbol.className = `change-symbol ${data.amount >= 0 ? 'positive' : 'negative'}`;
                changeAmount.textContent = this.formatMoney(Math.abs(data.amount));
                
                // Show change display
                changeDisplay.classList.remove('hidden');
                changeDisplay.classList.add('visible', 'fade-in');
                
                // Hide after 3 seconds
                setTimeout(() => {
                    changeDisplay.classList.add('hidden');
                    changeDisplay.classList.remove('visible');
                }, 3000);
            }
            
            // Update main money display
            if (data.type === 'cash') {
                document.getElementById('cash-amount').textContent = this.formatMoney(data.newAmount);
            } else if (data.type === 'bank') {
                document.getElementById('bank-amount').textContent = this.formatMoney(data.newAmount);
            }
        }
    }

    formatMoney(amount) {
        return new Intl.NumberFormat('en-US').format(amount);
    }

    // ================================================================
    // UTILITY METHODS
    // ================================================================

    post(action, data = {}) {
        fetch(`https://${GetParentResourceName()}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }).catch(error => {
            if (this.debug) {
                console.error(`[HUD:MAIN] Post request failed: ${action}`, error);
            }
        });
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    enableDebug() {
        this.debug = true;
        console.log('[HUD:MAIN] Debug mode enabled');
    }

    disableDebug() {
        this.debug = false;
        console.log('[HUD:MAIN] Debug mode disabled');
    }

    getStatus() {
        return {
            theme: this.theme,
            visible: this.isVisible,
            cinematicMode: this.cinematicMode,
            modules: Array.from(this.modules.keys()),
            settings: this.settings
        };
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create global HUD manager instance
const hudManager = new HUDManager();

// Export for module access
window.hudManager = hudManager;
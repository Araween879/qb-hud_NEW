// ================================================================
// QBCore HUD - Core JavaScript Module System
// Version: 3.0.0
// Description: Advanced JavaScript module system with Neon UI
// ================================================================

class HUDSystem {
    constructor() {
        this.initialized = false;
        this.modules = new Map();
        this.theme = 'neon-magenta';
        this.settings = {
            theme: 'neon-magenta',
            scaling: 1.0,
            opacity: 0.9,
            animations: true,
            glowEffects: true,
            cinematicMode: false,
            lowEndMode: false
        };
        
        this.performance = {
            frameCount: 0,
            lastFrameTime: 0,
            averageFPS: 60,
            updateCount: 0,
            renderTime: 0
        };
        
        this.debug = false;
        this.menuOpen = false;
        
        // Animation queues
        this.animationQueue = [];
        this.currentAnimations = new Set();
        
        // Update intervals
        this.updateIntervals = {
            fast: 100,      // Voice, critical systems
            normal: 200,    // Health, status
            slow: 1000,     // Time, less critical
            crawl: 5000     // System info, very slow updates
        };
        
        this.init();
    }
    
    // ================================================================
    // INITIALIZATION SYSTEM
    // ================================================================
    
    init() {
        this.log('🎮 Initializing HUD System...');
        
        // Setup DOM
        this.setupDOM();
        
        // Load theme system
        this.initializeThemeSystem();
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Initialize modules
        this.initializeModules();
        
        // Setup update loops
        this.setupUpdateLoops();
        
        // Setup performance monitoring
        this.setupPerformanceMonitoring();
        
        // Setup responsive system
        this.setupResponsiveSystem();
        
        this.initialized = true;
        this.log('✅ HUD System initialized successfully');
        
        // Send ready signal to FiveM
        this.postToFiveM({ action: 'hudReady' });
    }
    
    setupDOM() {
        // Ensure required DOM structure exists
        if (!document.getElementById('hud-container')) {
            const container = document.createElement('div');
            container.id = 'hud-container';
            document.body.appendChild(container);
        }
        
        // Add theme class to body
        document.body.className = `theme-${this.theme}`;
        
        // Prevent context menu
        document.addEventListener('contextmenu', e => e.preventDefault());
        
        // Prevent text selection
        document.addEventListener('selectstart', e => e.preventDefault());
        
        this.log('📄 DOM setup complete');
    }
    
    initializeThemeSystem() {
        // Theme definitions
        this.themes = {
            'neon-magenta': {
                primary: '#B026FF',
                secondary: '#0ff',
                accent: '#FFD700',
                background: '#1a1a1a',
                backgroundDark: '#111',
                textPrimary: '#fff',
                textSecondary: '#e0e0e0'
            },
            'neon-cyan': {
                primary: '#0ff',
                secondary: '#B026FF', 
                accent: '#FFD700',
                background: '#0a1a1a',
                backgroundDark: '#051111',
                textPrimary: '#fff',
                textSecondary: '#e0f0f0'
            },
            'synthwave': {
                primary: '#ff0080',
                secondary: '#00ffff',
                accent: '#ffff00',
                background: '#1a0a1a',
                backgroundDark: '#110511',
                textPrimary: '#fff',
                textSecondary: '#f0e0f0'
            },
            'classic': {
                primary: '#007acc',
                secondary: '#666',
                accent: '#ffa500',
                background: '#2d2d2d',
                backgroundDark: '#1e1e1e',
                textPrimary: '#fff',
                textSecondary: '#ccc'
            }
        };
        
        this.applyTheme(this.theme);
        this.log('🎨 Theme system initialized');
    }
    
    setupEventListeners() {
        // FiveM message handler
        window.addEventListener('message', (event) => {
            this.handleMessage(event.data);
        });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (event) => {
            this.handleKeyboard(event);
        });
        
        // Window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });
        
        // Visibility change
        document.addEventListener('visibilitychange', () => {
            this.handleVisibilityChange();
        });
        
        this.log('🎧 Event listeners setup complete');
    }
    
    initializeModules() {
        // Register core modules
        this.registerModule('gps', new GPSHUDModule(this));
        this.registerModule('health', new HealthModule(this));
        this.registerModule('time', new TimeModule(this));
        this.registerModule('location', new LocationModule(this));
        this.registerModule('vehicle', new VehicleModule(this));
        this.registerModule('status', new StatusModule(this));
        this.registerModule('menu', new MenuModule(this));
        
        this.log(`📦 ${this.modules.size} modules initialized`);
    }
    
    setupUpdateLoops() {
        // Fast update loop (100ms) - Critical systems
        setInterval(() => {
            this.updateFast();
        }, this.updateIntervals.fast);
        
        // Normal update loop (200ms) - Standard systems
        setInterval(() => {
            this.updateNormal();
        }, this.updateIntervals.normal);
        
        // Slow update loop (1000ms) - Non-critical systems
        setInterval(() => {
            this.updateSlow();
        }, this.updateIntervals.slow);
        
        // Crawl update loop (5000ms) - System monitoring
        setInterval(() => {
            this.updateCrawl();
        }, this.updateIntervals.crawl);
        
        this.log('🔄 Update loops initialized');
    }
    
    setupPerformanceMonitoring() {
        // FPS monitoring
        const fpsLoop = () => {
            const now = performance.now();
            const delta = now - this.performance.lastFrameTime;
            
            if (delta > 0) {
                const currentFPS = 1000 / delta;
                this.performance.averageFPS = (this.performance.averageFPS * 0.9) + (currentFPS * 0.1);
                this.performance.frameCount++;
            }
            
            this.performance.lastFrameTime = now;
            requestAnimationFrame(fpsLoop);
        };
        
        requestAnimationFrame(fpsLoop);
        
        // Memory monitoring
        if ('memory' in performance) {
            setInterval(() => {
                this.performance.memoryUsage = performance.memory.usedJSHeapSize;
            }, 5000);
        }
        
        this.log('📊 Performance monitoring setup');
    }
    
    setupResponsiveSystem() {
        // Detect screen size and adjust
        this.updateResponsiveLayout();
        
        // Media query listeners
        const mediaQueries = [
            { query: '(max-width: 1920px)', class: 'screen-1920' },
            { query: '(max-width: 1366px)', class: 'screen-1366' },
            { query: '(max-width: 1024px)', class: 'screen-1024' }
        ];
        
        mediaQueries.forEach(({ query, class: className }) => {
            const mq = window.matchMedia(query);
            
            const handler = (e) => {
                if (e.matches) {
                    document.body.classList.add(className);
                } else {
                    document.body.classList.remove(className);
                }
            };
            
            handler(mq);
            mq.addListener(handler);
        });
        
        this.log('📱 Responsive system setup');
    }
    
    // ================================================================
    // MODULE MANAGEMENT
    // ================================================================
    
    registerModule(name, module) {
        this.modules.set(name, module);
        this.log(`📦 Module registered: ${name}`);
    }
    
    getModule(name) {
        return this.modules.get(name);
    }
    
    updateModule(name, data) {
        const module = this.modules.get(name);
        if (module && module.update) {
            module.update(data);
        }
    }
    
    toggleModule(name, visible) {
        const module = this.modules.get(name);
        if (module && module.setVisible) {
            module.setVisible(visible);
        }
    }
    
    // ================================================================  
    // UPDATE LOOPS
    // ================================================================
    
    updateFast() {
        // Update critical modules that need fast refresh
        this.modules.forEach((module, name) => {
            if (module.updateFast) {
                module.updateFast();
            }
        });
        
        // Process animation queue
        this.processAnimations();
    }
    
    updateNormal() {
        this.performance.updateCount++;
        
        // Update standard modules
        this.modules.forEach((module, name) => {
            if (module.updateNormal) {
                module.updateNormal();
            }
        });
    }
    
    updateSlow() {
        // Update non-critical modules
        this.modules.forEach((module, name) => {
            if (module.updateSlow) {
                module.updateSlow();
            }
        });
    }
    
    updateCrawl() {
        // System monitoring and cleanup
        this.cleanupAnimations();
        
        // Performance logging if debug enabled
        if (this.debug) {
            this.logPerformance();
        }
    }
    
    // ================================================================
    // MESSAGE HANDLING
    // ================================================================
    
    handleMessage(data) {
        if (!data || !data.action) return;
        
        try {
            switch (data.action) {
                case 'updateGPSHUD':
                    this.updateModule('gps', data.data);
                    break;
                    
                case 'updateHealth':
                    this.updateModule('health', data.data);
                    break;
                    
                case 'updateTime':
                    this.updateModule('time', data.data);
                    break;
                    
                case 'updateLocation':
                    this.updateModule('location', data.data);
                    break;
                    
                case 'updateVehicle':
                    this.updateModule('vehicle', data.data);
                    break;
                    
                case 'updateStatus':
                    this.updateModule('status', data.data);
                    break;
                    
                case 'setTheme':
                    this.setTheme(data.theme);
                    break;
                    
                case 'toggleModule':
                    this.toggleModule(data.module, data.visible);
                    break;
                    
                case 'setHudVisibility':
                    this.setHudVisibility(data.visible);
                    break;
                    
                case 'setCinematicMode':
                    this.setCinematicMode(data.enabled);
                    break;
                    
                case 'setUIScale':
                    this.setUIScale(data.scale);
                    break;
                    
                case 'setUIOpacity':
                    this.setUIOpacity(data.opacity);
                    break;
                    
                case 'showCustomMessage':
                    this.showCustomMessage(data);
                    break;
                    
                case 'hideCustomMessage':
                    this.hideCustomMessage(data.id);
                    break;
                    
                case 'showMenu':
                    this.showMenu();
                    break;
                    
                case 'hideMenu':
                    this.hideMenu();
                    break;
                    
                case 'batchUpdate':
                    this.handleBatchUpdate(data);
                    break;
                    
                default:
                    this.warn(`Unknown action: ${data.action}`);
            }
        } catch (error) {
            this.error(`Error handling message: ${error.message}`, data);
        }
    }
    
    handleBatchUpdate(data) {
        if (data.updates && Array.isArray(data.updates)) {
            data.updates.forEach(update => {
                if (update.module && update.data) {
                    this.updateModule(update.module, update.data);
                }
            });
        }
    }
    
    // ================================================================
    // THEME SYSTEM
    // ================================================================
    
    setTheme(themeName) {
        if (!this.themes[themeName]) {
            this.warn(`Theme not found: ${themeName}`);
            return false;
        }
        
        this.theme = themeName;
        document.body.className = `theme-${themeName}`;
        
        this.applyTheme(themeName);
        
        // Notify modules of theme change
        this.modules.forEach((module, name) => {
            if (module.onThemeChange) {
                module.onThemeChange(themeName, this.themes[themeName]);
            }
        });
        
        this.log(`🎨 Theme changed to: ${themeName}`);
        return true;
    }
    
    applyTheme(themeName) {
        const theme = this.themes[themeName];
        if (!theme) return;
        
        // Update CSS custom properties
        const root = document.documentElement;
        Object.entries(theme).forEach(([key, value]) => {
            root.style.setProperty(`--${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`, value);
        });
    }
    
    // ================================================================
    // UI CONTROLS
    // ================================================================
    
    setHudVisibility(visible) {
        const container = document.getElementById('hud-container');
        if (container) {
            if (visible) {
                container.classList.remove('hidden');
                container.classList.add('visible');
            } else {
                container.classList.add('hidden'); 
                container.classList.remove('visible');
            }
        }
        
        this.log(`👁️ HUD visibility: ${visible ? 'visible' : 'hidden'}`);
    }
    
    setCinematicMode(enabled) {
        if (enabled) {
            document.body.classList.add('cinematic-mode');
            this.setHudVisibility(false);
        } else {
            document.body.classList.remove('cinematic-mode');
            this.setHudVisibility(true);
        }
        
        this.settings.cinematicMode = enabled;
        this.log(`🎬 Cinematic mode: ${enabled ? 'enabled' : 'disabled'}`);
    }
    
    setUIScale(scale) {
        scale = Math.max(0.5, Math.min(2.0, scale));
        document.documentElement.style.setProperty('--ui-scale', scale);
        this.settings.scaling = scale;
        
        this.log(`📏 UI scale: ${scale}`);
    }
    
    setUIOpacity(opacity) {
        opacity = Math.max(0.0, Math.min(1.0, opacity));
        document.documentElement.style.setProperty('--ui-opacity', opacity);
        this.settings.opacity = opacity;
        
        this.log(`👻 UI opacity: ${opacity}`);
    }
    
    // ================================================================
    // ANIMATION SYSTEM
    // ================================================================
    
    addAnimation(element, animation) {
        const animationId = Date.now() + Math.random();
        
        this.animationQueue.push({
            id: animationId,
            element: element,
            animation: animation,
            startTime: performance.now()
        });
        
        return animationId;
    }
    
    processAnimations() {
        const now = performance.now();
        
        this.animationQueue.forEach((anim, index) => {
            if (anim.startTime <= now) {
                // Start animation
                this.startAnimation(anim);
                this.currentAnimations.add(anim.id);
                this.animationQueue.splice(index, 1);
            }
        });
    }
    
    startAnimation(anim) {
        if (!anim.element || !anim.animation) return;
        
        const { type, duration = 300, easing = 'ease', ...props } = anim.animation;
        
        switch (type) {
            case 'fadeIn':
                anim.element.style.opacity = '0';
                anim.element.style.transition = `opacity ${duration}ms ${easing}`;
                requestAnimationFrame(() => {
                    anim.element.style.opacity = '1';
                });
                break;
                
            case 'fadeOut':
                anim.element.style.transition = `opacity ${duration}ms ${easing}`;
                anim.element.style.opacity = '0';
                break;
                
            case 'slideIn':
                const direction = props.direction || 'left';
                const distance = props.distance || '100px';
                
                anim.element.style.transform = this.getSlideTransform(direction, distance);
                anim.element.style.transition = `transform ${duration}ms ${easing}`;
                
                requestAnimationFrame(() => {
                    anim.element.style.transform = 'translate(0, 0)';
                });
                break;
                
            case 'pulse':
                anim.element.style.animation = `pulse ${duration}ms ${easing}`;
                break;
                
            case 'glow':
                anim.element.style.animation = `glow-pulse ${duration}ms ${easing} infinite`;
                break;
        }
        
        // Remove animation after completion
        setTimeout(() => {
            this.currentAnimations.delete(anim.id);
            if (anim.element) {
                anim.element.style.animation = '';
            }
        }, duration);
    }
    
    getSlideTransform(direction, distance) {
        switch (direction) {
            case 'left': return `translateX(-${distance})`;
            case 'right': return `translateX(${distance})`;
            case 'up': return `translateY(-${distance})`;  
            case 'down': return `translateY(${distance})`;
            default: return `translateX(-${distance})`;
        }
    }
    
    cleanupAnimations() {
        // Remove completed animations
        this.currentAnimations.forEach(id => {
            if (Date.now() - id > 10000) { // 10 second cleanup
                this.currentAnimations.delete(id);
            }
        });
    }
    
    // ================================================================
    // NOTIFICATION SYSTEM
    // ================================================================
    
    showCustomMessage(data) {
        const { id, text, duration = 3000, type = 'info' } = data;
        
        // Create notification element
        const notification = document.createElement('div');
        notification.id = `notification-${id}`;
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <span class="notification-text">${text}</span>
                <button class="notification-close">&times;</button>
            </div>
        `;
        
        // Add to container
        let container = document.getElementById('notifications-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'notifications-container';
            container.className = 'notifications-container';
            document.body.appendChild(container);
        }
        
        container.appendChild(notification);
        
        // Animate in
        this.addAnimation(notification, { type: 'slideIn', direction: 'right' });
        
        // Auto remove
        setTimeout(() => {
            this.hideCustomMessage(id);
        }, duration);
        
        // Close button
        notification.querySelector('.notification-close').addEventListener('click', () => {
            this.hideCustomMessage(id);
        });
    }
    
    hideCustomMessage(id) {
        const notification = document.getElementById(`notification-${id}`);
        if (notification) {
            this.addAnimation(notification, { type: 'fadeOut' });
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }    
    }
    
    // ================================================================
    // MENU SYSTEM
    // ================================================================
    
    showMenu() {
        this.menuOpen = true;
        const menu = this.getModule('menu');
        if (menu && menu.show) {
            menu.show();
        }
    }
    
    hideMenu() {
        this.menuOpen = false;
        const menu = this.getModule('menu');
        if (menu && menu.hide) {
            menu.hide();
        }
    }
    
    // ================================================================
    // EVENT HANDLERS
    // ================================================================
    
    handleKeyboard(event) {
        // ESC to close menu
        if (event.key === 'Escape' && this.menuOpen) {
            this.hideMenu();
            event.preventDefault();
        }
        
        // Debug toggle (F8)
        if (event.key === 'F8' && event.ctrlKey) {
            this.debug = !this.debug;
            this.log(`🐛 Debug mode: ${this.debug ? 'enabled' : 'disabled'}`);
            event.preventDefault();
        }
    }
    
    handleResize() {
        this.updateResponsiveLayout();
        
        // Notify modules
        this.modules.forEach((module, name) => {
            if (module.onResize) {
                module.onResize();
            }
        });
    }
    
    handleVisibilityChange() {
        if (document.hidden) {
            // Pause updates when tab is hidden
            this.paused = true;
        } else {
            // Resume updates
            this.paused = false;
        }
    }
    
    updateResponsiveLayout() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        // Set responsive classes
        document.body.classList.toggle('mobile', width < 768);
        document.body.classList.toggle('tablet', width >= 768 && width < 1024);
        document.body.classList.toggle('desktop', width >= 1024);
        
        // Update CSS variables
        document.documentElement.style.setProperty('--screen-width', `${width}px`);
        document.documentElement.style.setProperty('--screen-height', `${height}px`);
    }
    
    // ================================================================
    // UTILITY FUNCTIONS
    // ================================================================
    
    postToFiveM(data) {
        if (window.fetch) {
            fetch(`https://${this.getResourceName()}/hudCallback`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            }).catch(() => {}); // Ignore fetch errors in NUI
        }
    }
    
    getResourceName() {
        return window.location.hostname === 'nui-game-internal' ? 'qb-hud' : 'qb-hud';
    }
    
    getPerformanceStats() {
        return {
            fps: Math.round(this.performance.averageFPS),
            frameCount: this.performance.frameCount,
            updateCount: this.performance.updateCount,
            memoryUsage: this.performance.memoryUsage,
            activeAnimations: this.currentAnimations.size,
            moduleCount: this.modules.size
        };
    }
    
    logPerformance() {
        const stats = this.getPerformanceStats();
        this.log(`📊 Performance: ${stats.fps}fps | ${stats.activeAnimations} animations | ${this.modules.size} modules`);
    }
    
    // ================================================================
    // LOGGING SYSTEM
    // ================================================================
    
    log(message, data = null) {
        if (this.debug) {
            console.log(`[HUD] ${message}`, data || '');
        }
    }
    
    warn(message, data = null) {
        console.warn(`[HUD] ⚠️ ${message}`, data || '');
    }
    
    error(message, data = null) {
        console.error(`[HUD] ❌ ${message}`, data || '');
    }
}

// ================================================================
// BASE MODULE CLASS
// ================================================================

class HUDModule {
    constructor(hudSystem, name) {
        this.hud = hudSystem;
        this.name = name;
        this.visible = true;
        this.initialized = false;
        this.element = null;
        this.data = {};
        this.updateCount = 0;
        this.lastUpdate = 0;
    }
    
    init() {
        this.initialized = true;
        this.hud.log(`📦 Module initialized: ${this.name}`);
    }
    
    update(data) {
        this.data = { ...this.data, ...data };
        this.updateCount++;
        this.lastUpdate = performance.now();
        this.render();
    }
    
    render() {
        // Override in subclasses
    }
    
    setVisible(visible) {
        this.visible = visible;
        if (this.element) {
            this.element.style.display = visible ? 'block' : 'none';
        }
    }
    
    show() {
        this.setVisible(true);
    }
    
    hide() {
        this.setVisible(false);
    }
    
    updateFast() {
        // Override for fast updates
    }
    
    updateNormal() {
        // Override for normal updates
    }
    
    updateSlow() {
        // Override for slow updates
    }
    
    onThemeChange(theme, colors) {
        // Override for theme changes
    }
    
    onResize() {
        // Override for resize handling
    }
    
    log(message) {
        this.hud.log(`[${this.name}] ${message}`);
    }
    
    warn(message) {
        this.hud.warn(`[${this.name}] ${message}`);
    }
    
    error(message) {
        this.hud.error(`[${this.name}] ${message}`);
    }
}

// ================================================================
// INITIALIZE SYSTEM
// ================================================================

// Wait for DOM to be ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.HUDSystem = new HUDSystem();
    });
} else {
    window.HUDSystem = new HUDSystem();
}

// Export for external access
window.HUD = {
    system: null,
    getModule: (name) => window.HUDSystem?.getModule(name),
    updateModule: (name, data) => window.HUDSystem?.updateModule(name, data),
    setTheme: (theme) => window.HUDSystem?.setTheme(theme),
    toggleModule: (name, visible) => window.HUDSystem?.toggleModule(name, visible),
    showMessage: (data) => window.HUDSystem?.showCustomMessage(data),
    hideMessage: (id) => window.HUDSystem?.hideCustomMessage(id),
    getStats: () => window.HUDSystem?.getPerformanceStats()
};
/* ================================================================
   QBCore HUD - Location System Module (JavaScript)
   Version: 3.0.0
   Description: Street names, zone information, and location display management
   ================================================================ */

class LocationModule {
    constructor() {
        this.name = 'location';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 1500; // 1.5 seconds
        
        // Location data
        this.data = {
            street: 'Unknown Street',
            zone: 'Unknown Zone',
            direction: 'N',
            heading: 0,
            coords: { x: 0, y: 0, z: 0 }
        };
        
        // DOM elements cache
        this.elements = {};
        
        // Animation states
        this.animating = {
            street: false,
            zone: false,
            direction: false
        };
        
        console.log('[HUD:LOCATION] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:LOCATION] Initializing location module...');
        
        // Cache DOM elements
        this.cacheElements();
        
        // Setup initial state
        this.setupInitialState();
        
        // Register with HUD manager
        if (window.hudManager) {
            window.hudManager.registerModule(this.name, this);
        }
        
        console.log('[HUD:LOCATION] Location module initialized successfully');
    }

    cacheElements() {
        // Main container
        this.elements.container = document.getElementById('location-container');
        
        // Street elements
        this.elements.streetName = document.getElementById('street-name');
        this.elements.streetIcon = document.getElementById('street-icon');
        
        // Zone elements
        this.elements.zoneName = document.getElementById('zone-name');
        this.elements.zoneIcon = document.getElementById('zone-icon');
        
        // Direction elements
        this.elements.direction = document.getElementById('direction');
        this.elements.directionIcon = document.getElementById('direction-icon');
        this.elements.compass = document.getElementById('compass');
        
        // Debug elements
        this.elements.coords = document.getElementById('coordinates');
        this.elements.heading = document.getElementById('heading');
        
        console.log('[HUD:LOCATION] Elements cached:', Object.keys(this.elements).length);
    }

    setupInitialState() {
        // Set initial visibility
        this.setVisible(this.enabled);
        
        // Setup default content
        this.updateStreetName('Unknown Street');
        this.updateZoneName('Unknown Zone');
        this.updateDirection('N', 0);
        
        // Apply theme
        this.applyTheme('neon-magenta');
    }

    // ================================================================
    // LOCATION UPDATES
    // ================================================================

    update(data) {
        if (!data || typeof data !== 'object') {
            console.warn('[HUD:LOCATION] Invalid data provided to update');
            return false;
        }
        
        const now = Date.now();
        if (now - this.lastUpdate < this.updateInterval) {
            return false; // Skip update to prevent spam
        }
        
        // Update street name
        if (data.street && data.street !== this.data.street) {
            this.updateStreetName(data.street);
        }
        
        // Update zone name
        if (data.zone && data.zone !== this.data.zone) {
            this.updateZoneName(data.zone);
        }
        
        // Update direction/heading
        if (data.heading !== undefined || data.direction) {
            const direction = data.direction || this.calculateDirection(data.heading);
            const heading = data.heading !== undefined ? data.heading : this.data.heading;
            this.updateDirection(direction, heading);
        }
        
        // Update coordinates
        if (data.coords) {
            this.updateCoordinates(data.coords);
        }
        
        // Store data
        this.data = { ...this.data, ...data };
        this.lastUpdate = now;
        
        return true;
    }

    updateStreetName(streetName) {
        if (!streetName || typeof streetName !== 'string') return false;
        
        if (this.elements.streetName) {
            // Animate change if different
            if (streetName !== this.data.street && !this.animating.street) {
                this.animateTextChange(this.elements.streetName, streetName, 'street');
            } else {
                this.elements.streetName.textContent = streetName;
            }
        }
        
        this.data.street = streetName;
        return true;
    }

    updateZoneName(zoneName) {
        if (!zoneName || typeof zoneName !== 'string') return false;
        
        if (this.elements.zoneName) {
            // Animate change if different
            if (zoneName !== this.data.zone && !this.animating.zone) {
                this.animateTextChange(this.elements.zoneName, zoneName, 'zone');
            } else {
                this.elements.zoneName.textContent = zoneName;
            }
        }
        
        this.data.zone = zoneName;
        return true;
    }

    updateDirection(direction, heading) {
        if (!direction || typeof direction !== 'string') return false;
        
        const headingValue = parseFloat(heading) || 0;
        
        // Update direction text
        if (this.elements.direction) {
            if (direction !== this.data.direction && !this.animating.direction) {
                this.animateTextChange(this.elements.direction, direction, 'direction');
            } else {
                this.elements.direction.textContent = direction;
            }
        }
        
        // Update compass rotation
        if (this.elements.compass) {
            this.elements.compass.style.transform = `rotate(${headingValue}deg)`;
        }
        
        // Update heading display
        if (this.elements.heading) {
            this.elements.heading.textContent = `${Math.round(headingValue)}°`;
        }
        
        // Update direction icon
        if (this.elements.directionIcon) {
            this.updateDirectionIcon(direction);
        }
        
        this.data.direction = direction;
        this.data.heading = headingValue;
        
        return true;
    }

    updateCoordinates(coords) {
        if (!coords || typeof coords !== 'object') return false;
        
        if (this.elements.coords) {
            const coordsText = `${coords.x?.toFixed(1) || 0}, ${coords.y?.toFixed(1) || 0}, ${coords.z?.toFixed(1) || 0}`;
            this.elements.coords.textContent = coordsText;
        }
        
        this.data.coords = coords;
        return true;
    }

    // ================================================================
    // UTILITY FUNCTIONS
    // ================================================================

    calculateDirection(heading) {
        const headingValue = parseFloat(heading) || 0;
        const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        const index = Math.round((headingValue % 360) / 45) % 8;
        return directions[index];
    }

    updateDirectionIcon(direction) {
        if (!this.elements.directionIcon) return;
        
        // Map directions to icons
        const iconMap = {
            'N': 'fas fa-arrow-up',
            'NE': 'fas fa-arrow-up',
            'E': 'fas fa-arrow-right',
            'SE': 'fas fa-arrow-down',
            'S': 'fas fa-arrow-down',
            'SW': 'fas fa-arrow-down',
            'W': 'fas fa-arrow-left',
            'NW': 'fas fa-arrow-up'
        };
        
        const iconClass = iconMap[direction] || 'fas fa-compass';
        this.elements.directionIcon.className = iconClass;
    }

    // ================================================================
    // ANIMATIONS
    // ================================================================

    animateTextChange(element, newText, type) {
        if (!element || this.animating[type]) return;
        
        this.animating[type] = true;
        
        // Fade out
        element.style.transition = 'opacity 0.2s ease';
        element.style.opacity = '0';
        
        setTimeout(() => {
            // Change text
            element.textContent = newText;
            
            // Fade in
            element.style.opacity = '1';
            
            setTimeout(() => {
                this.animating[type] = false;
                element.style.transition = '';
            }, 200);
        }, 200);
    }

    triggerLocationPulse() {
        if (!this.elements.container) return;
        
        // Add pulse animation class
        this.elements.container.classList.add('location-pulse');
        
        setTimeout(() => {
            this.elements.container.classList.remove('location-pulse');
        }, 1000);
    }

    // ================================================================
    // THEME & STYLING
    // ================================================================

    applyTheme(themeName) {
        if (!this.elements.container) return;
        
        // Remove existing theme classes
        this.elements.container.className = this.elements.container.className
            .replace(/theme-\w+/g, '');
        
        // Add new theme class
        this.elements.container.classList.add(`theme-${themeName}`);
        
        console.log(`[HUD:LOCATION] Applied theme: ${themeName}`);
    }

    setVisible(visible) {
        if (!this.elements.container) return false;
        
        this.enabled = visible;
        
        if (visible) {
            this.elements.container.classList.remove('hidden');
            this.elements.container.classList.add('visible');
        } else {
            this.elements.container.classList.add('hidden');
            this.elements.container.classList.remove('visible');
        }
        
        return true;
    }

    // ================================================================
    // UTILITY METHODS
    // ================================================================

    getStatus() {
        return {
            ...this.data,
            enabled: this.enabled,
            lastUpdate: this.lastUpdate
        };
    }

    reset() {
        // Reset to default values
        this.data = {
            street: 'Unknown Street',
            zone: 'Unknown Zone',
            direction: 'N',
            heading: 0,
            coords: { x: 0, y: 0, z: 0 }
        };
        
        // Update display
        this.updateStreetName(this.data.street);
        this.updateZoneName(this.data.zone);
        this.updateDirection(this.data.direction, this.data.heading);
        this.updateCoordinates(this.data.coords);
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:LOCATION] Debug Info:', {
                data: this.data,
                elements: Object.keys(this.elements),
                enabled: this.enabled,
                lastUpdate: new Date(this.lastUpdate),
                animating: this.animating
            });
        }
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create and register location module
const locationModule = new LocationModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => locationModule.init());
} else {
    locationModule.init();
}

// Export for global access
window.locationModule = locationModule;
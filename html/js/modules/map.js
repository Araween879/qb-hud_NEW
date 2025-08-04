/* ================================================================
   QBCore HUD - Map & Compass System Module (JavaScript)
   Version: 3.0.0
   Description: Minimap controls, compass display, and map interaction management
   ================================================================ */

class MapModule {
    constructor() {
        this.name = 'map';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 100; // Fast updates for smooth compass
        
        // Map data
        this.data = {
            heading: 0,
            direction: 'N',
            mapShape: 'square', // 'square' or 'circle'
            mapVisible: true,
            zoomLevel: 1.0,
            position: { x: 0, y: 0 }
        };
        
        // DOM elements cache
        this.elements = {};
        
        // Animation states
        this.animating = {
            compass: false,
            zoom: false
        };
        
        // Compass directions
        this.directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        
        console.log('[HUD:MAP] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:MAP] Initializing map module...');
        
        // Cache DOM elements
        this.cacheElements();
        
        // Setup initial state
        this.setupInitialState();
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Register with HUD manager
        if (window.hudManager) {
            window.hudManager.registerModule(this.name, this);
        }
        
        console.log('[HUD:MAP] Map module initialized successfully');
    }

    cacheElements() {
        // Main container
        this.elements.container = document.getElementById('map-container');
        
        // Compass elements
        this.elements.compass = document.getElementById('compass');
        this.elements.compassNeedle = document.getElementById('compass-needle');
        this.elements.compassRose = document.getElementById('compass-rose');
        this.elements.compassText = document.getElementById('compass-text');
        
        // Direction indicators
        this.elements.directionN = document.getElementById('direction-n');
        this.elements.directionE = document.getElementById('direction-e');
        this.elements.directionS = document.getElementById('direction-s');
        this.elements.directionW = document.getElementById('direction-w');
        
        // Map controls
        this.elements.mapControls = document.getElementById('map-controls');
        this.elements.shapeToggle = document.getElementById('shape-toggle');
        this.elements.zoomIn = document.getElementById('zoom-in');
        this.elements.zoomOut = document.getElementById('zoom-out');
        
        // Map info
        this.elements.mapInfo = document.getElementById('map-info');
        this.elements.coordinates = document.getElementById('map-coordinates');
        this.elements.zoomLevel = document.getElementById('zoom-level');
        
        console.log('[HUD:MAP] Elements cached:', Object.keys(this.elements).length);
    }

    setupInitialState() {
        // Set initial visibility
        this.setVisible(this.enabled);
        
        // Setup default compass
        this.updateCompass(0);
        
        // Setup default map shape
        this.setMapShape('square');
        
        // Apply theme
        this.applyTheme('neon-magenta');
        
        // Initialize compass rose
        this.initializeCompassRose();
    }

    setupEventListeners() {
        // Shape toggle
        if (this.elements.shapeToggle) {
            this.elements.shapeToggle.addEventListener('click', () => {
                this.toggleMapShape();
            });
        }
        
        // Zoom controls
        if (this.elements.zoomIn) {
            this.elements.zoomIn.addEventListener('click', () => {
                this.zoomIn();
            });
        }
        
        if (this.elements.zoomOut) {
            this.elements.zoomOut.addEventListener('click', () => {
                this.zoomOut();
            });
        }
        
        // Compass click for centering
        if (this.elements.compass) {
            this.elements.compass.addEventListener('click', () => {
                this.centerCompass();
            });
        }
    }

    // ================================================================
    // COMPASS SYSTEM
    // ================================================================

    update(data) {
        if (!data || typeof data !== 'object') {
            console.warn('[HUD:MAP] Invalid data provided to update');
            return false;
        }
        
        const now = Date.now();
        if (now - this.lastUpdate < this.updateInterval) {
            return false; // Skip update to prevent spam
        }
        
        // Update compass heading
        if (data.heading !== undefined) {
            this.updateCompass(data.heading);
        }
        
        // Update map visibility
        if (data.mapVisible !== undefined) {
            this.setMapVisible(data.mapVisible);
        }
        
        // Update position
        if (data.position) {
            this.updatePosition(data.position);
        }
        
        // Update zoom level
        if (data.zoomLevel !== undefined) {
            this.setZoomLevel(data.zoomLevel);
        }
        
        // Store data
        this.data = { ...this.data, ...data };
        this.lastUpdate = now;
        
        return true;
    }

    updateCompass(heading) {
        const headingValue = parseFloat(heading) || 0;
        
        // Update compass needle rotation
        if (this.elements.compassNeedle) {
            this.elements.compassNeedle.style.transform = `rotate(${headingValue}deg)`;
        }
        
        // Update compass rose (counter-rotate for fixed directions)
        if (this.elements.compassRose) {
            this.elements.compassRose.style.transform = `rotate(${-headingValue}deg)`;
        }
        
        // Calculate and update direction
        const direction = this.calculateDirection(headingValue);
        this.updateDirection(direction);
        
        // Update compass text
        if (this.elements.compassText) {
            this.elements.compassText.textContent = `${Math.round(headingValue)}°`;
        }
        
        // Update individual direction indicators
        this.updateDirectionIndicators(headingValue);
        
        this.data.heading = headingValue;
        this.data.direction = direction;
        
        return true;
    }

    calculateDirection(heading) {
        const normalizedHeading = ((heading % 360) + 360) % 360;
        const directionIndex = Math.round(normalizedHeading / 45) % 8;
        return this.directions[directionIndex];
    }

    updateDirection(direction) {
        if (this.data.direction === direction) return;
        
        // Trigger direction change animation
        this.triggerDirectionChange(direction);
        
        this.data.direction = direction;
    }

    updateDirectionIndicators(heading) {
        const indicators = [
            { element: this.elements.directionN, angle: 0 },
            { element: this.elements.directionE, angle: 90 },
            { element: this.elements.directionS, angle: 180 },
            { element: this.elements.directionW, angle: 270 }
        ];
        
        indicators.forEach(({ element, angle }) => {
            if (!element) return;
            
            // Calculate relative angle
            const relativeAngle = ((angle - heading) + 360) % 360;
            
            // Highlight if close to current heading
            const proximity = Math.min(relativeAngle, 360 - relativeAngle);
            const isActive = proximity <= 22.5; // Within 45° total (22.5° each side)
            
            element.classList.toggle('active', isActive);
            
            // Set opacity based on proximity
            const opacity = isActive ? 1 : Math.max(0.3, 1 - (proximity / 90));
            element.style.opacity = opacity;
        });
    }

    initializeCompassRose() {
        if (!this.elements.compassRose) return;
        
        // Create direction markers
        const directions = [
            { name: 'N', angle: 0, major: true },
            { name: 'NE', angle: 45, major: false },
            { name: 'E', angle: 90, major: true },
            { name: 'SE', angle: 135, major: false },
            { name: 'S', angle: 180, major: true },
            { name: 'SW', angle: 225, major: false },
            { name: 'W', angle: 270, major: true },
            { name: 'NW', angle: 315, major: false }
        ];
        
        directions.forEach(({ name, angle, major }) => {
            const marker = document.createElement('div');
            marker.className = `compass-marker ${major ? 'major' : 'minor'}`;
            marker.style.transform = `rotate(${angle}deg) translateY(-45px)`;
            marker.textContent = name;
            
            this.elements.compassRose.appendChild(marker);
        });
    }

    centerCompass() {
        // Reset compass to North
        this.updateCompass(0);
        
        // Trigger center animation
        if (this.elements.compass) {
            this.elements.compass.classList.add('compass-center');
            setTimeout(() => {
                this.elements.compass.classList.remove('compass-center');
            }, 500);
        }
    }

    // ================================================================
    // MAP CONTROLS
    // ================================================================

    setMapShape(shape) {
        if (!['square', 'circle'].includes(shape)) return false;
        
        this.data.mapShape = shape;
        
        // Apply shape class to container
        if (this.elements.container) {
            this.elements.container.classList.remove('shape-square', 'shape-circle');
            this.elements.container.classList.add(`shape-${shape}`);
        }
        
        // Update shape toggle button
        if (this.elements.shapeToggle) {
            const icon = this.elements.shapeToggle.querySelector('i');
            if (icon) {
                icon.className = shape === 'square' ? 'fas fa-circle' : 'fas fa-square';
            }
        }
        
        return true;
    }

    toggleMapShape() {
        const newShape = this.data.mapShape === 'square' ? 'circle' : 'square';
        this.setMapShape(newShape);
        
        // Trigger shape change animation
        this.triggerShapeChange();
    }

    setMapVisible(visible) {
        this.data.mapVisible = visible;
        
        if (this.elements.container) {
            this.elements.container.classList.toggle('map-hidden', !visible);
        }
        
        return true;
    }

    setZoomLevel(zoomLevel) {
        const zoom = Math.max(0.5, Math.min(2.0, parseFloat(zoomLevel) || 1.0));
        this.data.zoomLevel = zoom;
        
        // Update zoom display
        if (this.elements.zoomLevel) {
            this.elements.zoomLevel.textContent = `${Math.round(zoom * 100)}%`;
        }
        
        // Apply zoom to map elements
        if (this.elements.container) {
            this.elements.container.style.transform = `scale(${zoom})`;
        }
        
        return true;
    }

    zoomIn() {
        const newZoom = Math.min(2.0, this.data.zoomLevel + 0.1);
        this.setZoomLevel(newZoom);
        this.triggerZoomAnimation('in');
    }

    zoomOut() {
        const newZoom = Math.max(0.5, this.data.zoomLevel - 0.1);
        this.setZoomLevel(newZoom);
        this.triggerZoomAnimation('out');
    }

    updatePosition(position) {
        if (!position || typeof position !== 'object') return false;
        
        this.data.position = position;
        
        // Update coordinates display
        if (this.elements.coordinates) {
            const coordsText = `${position.x?.toFixed(0) || 0}, ${position.y?.toFixed(0) || 0}`;
            this.elements.coordinates.textContent = coordsText;
        }
        
        return true;
    }

    // ================================================================
    // ANIMATIONS
    // ================================================================

    triggerDirectionChange(newDirection) {
        if (!this.elements.compassText) return;
        
        // Highlight new direction
        this.elements.compassText.classList.add('direction-change');
        setTimeout(() => {
            this.elements.compassText.classList.remove('direction-change');
        }, 300);
    }

    triggerShapeChange() {
        if (!this.elements.container) return;
        
        this.elements.container.classList.add('shape-transition');
        setTimeout(() => {
            this.elements.container.classList.remove('shape-transition');
        }, 300);
    }

    triggerZoomAnimation(direction) {
        if (!this.elements.container || this.animating.zoom) return;
        
        this.animating.zoom = true;
        this.elements.container.classList.add(`zoom-${direction}`);
        
        setTimeout(() => {
            this.elements.container.classList.remove(`zoom-${direction}`);
            this.animating.zoom = false;
        }, 200);
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
        
        console.log(`[HUD:MAP] Applied theme: ${themeName}`);
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
            heading: 0,
            direction: 'N',
            mapShape: 'square',
            mapVisible: true,
            zoomLevel: 1.0,
            position: { x: 0, y: 0 }
        };
        
        // Apply reset values
        this.updateCompass(0);
        this.setMapShape('square');
        this.setMapVisible(true);
        this.setZoomLevel(1.0);
        this.updatePosition({ x: 0, y: 0 });
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:MAP] Debug Info:', {
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

// Create and register map module
const mapModule = new MapModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => mapModule.init());
} else {
    mapModule.init();
}

// Export for global access
window.mapModule = mapModule;
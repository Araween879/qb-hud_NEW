/* ================================================================
   QBCore HUD - Vehicle System Module (JavaScript)
   Version: 3.0.0
   Description: Vehicle HUD management - speed, fuel, engine, seatbelt, etc.
   ================================================================ */

class VehicleModule {
    constructor() {
        this.name = 'vehicle';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 100; // Fast updates for smooth speedometer
        
        // Vehicle data
        this.data = {
            inVehicle: false,
            speed: 0,
            maxSpeed: 200,
            fuel: 100,
            engine: 100,
            seatbelt: false,
            harness: false,
            cruise: false,
            nitro: 0,
            gear: 1,
            rpm: 0,
            altitude: 0,
            speedUnit: 'MPH' // MPH or KPH
        };
        
        // DOM elements cache
        this.elements = {};
        
        // Animation states
        this.animating = {
            speedometer: false,
            fuel: false,
            engine: false,
            gear: false
        };
        
        // Performance tracking
        this.performance = {
            updateCount: 0,
            lastSpeedUpdate: 0,
            lastFuelUpdate: 0
        };
        
        console.log('[HUD:VEHICLE] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:VEHICLE] Initializing vehicle module...');
        
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
        
        console.log('[HUD:VEHICLE] Vehicle module initialized successfully');
    }

    cacheElements() {
        // Main container
        this.elements.container = document.getElementById('vehicle-container');
        
        // Speedometer elements
        this.elements.speedometer = document.getElementById('speedometer');
        this.elements.speedNeedle = document.getElementById('speed-needle');
        this.elements.speedValue = document.getElementById('speed-value');
        this.elements.speedUnit = document.getElementById('speed-unit');
        this.elements.maxSpeed = document.getElementById('max-speed');
        
        // Fuel elements
        this.elements.fuelGauge = document.getElementById('fuel-gauge');
        this.elements.fuelFill = document.getElementById('fuel-fill');
        this.elements.fuelValue = document.getElementById('fuel-value');
        this.elements.fuelIcon = document.getElementById('fuel-icon');
        
        // Engine elements
        this.elements.engineGauge = document.getElementById('engine-gauge');
        this.elements.engineFill = document.getElementById('engine-fill');
        this.elements.engineValue = document.getElementById('engine-value');
        this.elements.engineIcon = document.getElementById('engine-icon');
        
        // Status indicators
        this.elements.seatbeltIcon = document.getElementById('seatbelt-icon');
        this.elements.harnessIcon = document.getElementById('harness-icon');
        this.elements.cruiseIcon = document.getElementById('cruise-icon');
        this.elements.nitroIcon = document.getElementById('nitro-icon');
        
        // Additional info
        this.elements.gearDisplay = document.getElementById('gear-display');
        this.elements.rpmGauge = document.getElementById('rpm-gauge');
        this.elements.altitudeDisplay = document.getElementById('altitude-display');
        
        // Nitro gauge
        this.elements.nitroGauge = document.getElementById('nitro-gauge');
        this.elements.nitroFill = document.getElementById('nitro-fill');
        this.elements.nitroValue = document.getElementById('nitro-value');
        
        console.log('[HUD:VEHICLE] Elements cached:', Object.keys(this.elements).length);
    }

    setupInitialState() {
        // Set initial visibility (hidden when not in vehicle)
        this.setVisible(false);
        
        // Setup default values
        this.updateSpeed(0);
        this.updateFuel(100);
        this.updateEngine(100);
        this.updateGear(1);
        this.updateRPM(0);
        
        // Setup status indicators
        this.updateSeatbelt(false);
        this.updateHarness(false);
        this.updateCruise(false);
        this.updateNitro(0);
        
        // Apply theme
        this.applyTheme('neon-magenta');
        
        // Set speed unit
        this.setSpeedUnit(this.data.speedUnit);
    }

    setupEventListeners() {
        // Speed unit toggle
        if (this.elements.speedUnit) {
            this.elements.speedUnit.addEventListener('click', () => {
                this.toggleSpeedUnit();
            });
        }
        
        // Fuel gauge click for detailed info
        if (this.elements.fuelGauge) {
            this.elements.fuelGauge.addEventListener('click', () => {
                this.showFuelDetails();
            });
        }
        
        // Engine gauge click for detailed info
        if (this.elements.engineGauge) {
            this.elements.engineGauge.addEventListener('click', () => {
                this.showEngineDetails();
            });
        }
    }

    // ================================================================
    // VEHICLE UPDATES
    // ================================================================

    update(data) {
        if (!data || typeof data !== 'object') {
            console.warn('[HUD:VEHICLE] Invalid data provided to update');
            return false;
        }
        
        const now = Date.now();
        if (now - this.lastUpdate < this.updateInterval) {
            return false; // Skip update to prevent spam
        }
        
        // Update vehicle state
        if (data.inVehicle !== undefined) {
            this.setInVehicle(data.inVehicle);
        }
        
        // Update speed
        if (data.speed !== undefined) {
            this.updateSpeed(data.speed);
        }
        
        // Update fuel
        if (data.fuel !== undefined) {
            this.updateFuel(data.fuel);
        }
        
        // Update engine health
        if (data.engine !== undefined) {
            this.updateEngine(data.engine);
        }
        
        // Update gear
        if (data.gear !== undefined) {
            this.updateGear(data.gear);
        }
        
        // Update RPM
        if (data.rpm !== undefined) {
            this.updateRPM(data.rpm);
        }
        
        // Update status indicators
        if (data.seatbelt !== undefined) {
            this.updateSeatbelt(data.seatbelt);
        }
        
        if (data.harness !== undefined) {
            this.updateHarness(data.harness);
        }
        
        if (data.cruise !== undefined) {
            this.updateCruise(data.cruise);
        }
        
        if (data.nitro !== undefined) {
            this.updateNitro(data.nitro);
        }
        
        // Update altitude
        if (data.altitude !== undefined) {
            this.updateAltitude(data.altitude);
        }
        
        // Store data
        this.data = { ...this.data, ...data };
        this.lastUpdate = now;
        this.performance.updateCount++;
        
        return true;
    }

    setInVehicle(inVehicle) {
        this.data.inVehicle = inVehicle;
        this.setVisible(inVehicle);
        
        if (inVehicle) {
            this.triggerVehicleEnter();
        } else {
            this.triggerVehicleExit();
        }
    }

    updateSpeed(speed) {
        const speedValue = Math.max(0, parseFloat(speed) || 0);
        this.data.speed = speedValue;
        
        // Update speedometer needle
        if (this.elements.speedNeedle) {
            const maxSpeed = this.data.maxSpeed;
            const angle = (speedValue / maxSpeed) * 270; // 270° arc
            this.elements.speedNeedle.style.transform = `rotate(${angle - 135}deg)`;
        }
        
        // Update speed display
        if (this.elements.speedValue) {
            this.elements.speedValue.textContent = Math.round(speedValue);
        }
        
        // Add speed animation if significant change
        if (Math.abs(speedValue - (this.performance.lastSpeedUpdate || 0)) > 5) {
            this.triggerSpeedAnimation();
            this.performance.lastSpeedUpdate = speedValue;
        }
        
        return true;
    }

    updateFuel(fuel) {
        const fuelValue = Math.max(0, Math.min(100, parseFloat(fuel) || 0));
        this.data.fuel = fuelValue;
        
        // Update fuel gauge fill
        if (this.elements.fuelFill) {
            this.elements.fuelFill.style.height = `${fuelValue}%`;
        }
        
        // Update fuel value
        if (this.elements.fuelValue) {
            this.elements.fuelValue.textContent = `${Math.round(fuelValue)}%`;
        }
        
        // Update fuel icon color based on level
        if (this.elements.fuelIcon) {
            this.elements.fuelIcon.className = this.getFuelIconClass(fuelValue);
        }
        
        // Trigger low fuel warning
        if (fuelValue <= 15 && fuelValue > (this.performance.lastFuelUpdate || 100)) {
            this.triggerLowFuelWarning();
        }
        
        this.performance.lastFuelUpdate = fuelValue;
        return true;
    }

    updateEngine(engine) {
        const engineValue = Math.max(0, Math.min(100, parseFloat(engine) || 0));
        this.data.engine = engineValue;
        
        // Update engine gauge fill
        if (this.elements.engineFill) {
            this.elements.engineFill.style.height = `${engineValue}%`;
        }
        
        // Update engine value
        if (this.elements.engineValue) {
            this.elements.engineValue.textContent = `${Math.round(engineValue)}%`;
        }
        
        // Update engine icon color based on health
        if (this.elements.engineIcon) {
            this.elements.engineIcon.className = this.getEngineIconClass(engineValue);
        }
        
        // Trigger engine damage warning
        if (engineValue <= 25) {
            this.triggerEngineDamageWarning();
        }
        
        return true;
    }

    updateGear(gear) {
        this.data.gear = gear;
        
        if (this.elements.gearDisplay) {
            let gearText = gear;
            if (gear === 0) gearText = 'R';
            else if (gear === -1) gearText = 'P';
            
            this.elements.gearDisplay.textContent = gearText;
            
            // Add gear change animation
            if (!this.animating.gear) {
                this.triggerGearChange();
            }
        }
        
        return true;
    }

    updateRPM(rpm) {
        const rpmValue = Math.max(0, Math.min(1.0, parseFloat(rpm) || 0));
        this.data.rpm = rpmValue;
        
        if (this.elements.rpmGauge) {
            const angle = rpmValue * 270; // 270° arc
            this.elements.rpmGauge.style.transform = `rotate(${angle - 135}deg)`;
        }
        
        return true;
    }

    updateSeatbelt(seatbelt) {
        this.data.seatbelt = seatbelt;
        
        if (this.elements.seatbeltIcon) {
            this.elements.seatbeltIcon.classList.toggle('active', seatbelt);
            this.elements.seatbeltIcon.classList.toggle('warning', !seatbelt && this.data.speed > 30);
        }
        
        return true;
    }

    updateHarness(harness) {
        this.data.harness = harness;
        
        if (this.elements.harnessIcon) {
            this.elements.harnessIcon.classList.toggle('active', harness);
        }
        
        return true;
    }

    updateCruise(cruise) {
        this.data.cruise = cruise;
        
        if (this.elements.cruiseIcon) {
            this.elements.cruiseIcon.classList.toggle('active', cruise);
        }
        
        return true;
    }

    updateNitro(nitro) {
        const nitroValue = Math.max(0, Math.min(100, parseFloat(nitro) || 0));
        this.data.nitro = nitroValue;
        
        // Update nitro gauge
        if (this.elements.nitroFill) {
            this.elements.nitroFill.style.width = `${nitroValue}%`;
        }
        
        // Update nitro value
        if (this.elements.nitroValue) {
            this.elements.nitroValue.textContent = `${Math.round(nitroValue)}%`;
        }
        
        // Update nitro icon
        if (this.elements.nitroIcon) {
            this.elements.nitroIcon.classList.toggle('active', nitroValue > 0);
            this.elements.nitroIcon.classList.toggle('boost', nitroValue > 80);
        }
        
        return true;
    }

    updateAltitude(altitude) {
        const altitudeValue = parseFloat(altitude) || 0;
        this.data.altitude = altitudeValue;
        
        if (this.elements.altitudeDisplay) {
            this.elements.altitudeDisplay.textContent = `${Math.round(altitudeValue)}m`;
        }
        
        return true;
    }

    // ================================================================
    // UTILITY FUNCTIONS
    // ================================================================

    getFuelIconClass(fuelLevel) {
        if (fuelLevel <= 10) return 'fas fa-gas-pump fuel-critical';
        if (fuelLevel <= 25) return 'fas fa-gas-pump fuel-low';
        if (fuelLevel <= 50) return 'fas fa-gas-pump fuel-medium';
        return 'fas fa-gas-pump fuel-high';
    }

    getEngineIconClass(engineHealth) {
        if (engineHealth <= 25) return 'fas fa-exclamation-triangle engine-critical';
        if (engineHealth <= 50) return 'fas fa-wrench engine-damaged';
        if (engineHealth <= 75) return 'fas fa-cog engine-worn';
        return 'fas fa-cog engine-good';
    }

    setSpeedUnit(unit) {
        if (!['MPH', 'KPH'].includes(unit)) return false;
        
        this.data.speedUnit = unit;
        
        if (this.elements.speedUnit) {
            this.elements.speedUnit.textContent = unit;
        }
        
        // Update max speed display for different units
        if (this.elements.maxSpeed) {
            const maxSpeed = unit === 'MPH' ? 200 : 320;
            this.data.maxSpeed = maxSpeed;
            this.elements.maxSpeed.textContent = maxSpeed;
        }
        
        return true;
    }

    toggleSpeedUnit() {
        const newUnit = this.data.speedUnit === 'MPH' ? 'KPH' : 'MPH';
        this.setSpeedUnit(newUnit);
    }

    showFuelDetails() {
        // Could show detailed fuel consumption, range, etc.
        console.log('[HUD:VEHICLE] Fuel details requested');
    }

    showEngineDetails() {
        // Could show detailed engine diagnostics
        console.log('[HUD:VEHICLE] Engine details requested');
    }

    // ================================================================
    // ANIMATIONS
    // ================================================================

    triggerVehicleEnter() {
        if (!this.elements.container) return;
        
        this.elements.container.classList.add('vehicle-enter');
        setTimeout(() => {
            this.elements.container.classList.remove('vehicle-enter');
        }, 500);
    }

    triggerVehicleExit() {
        if (!this.elements.container) return;
        
        this.elements.container.classList.add('vehicle-exit');
        setTimeout(() => {
            this.elements.container.classList.remove('vehicle-exit');
        }, 300);
    }

    triggerSpeedAnimation() {
        if (!this.elements.speedometer || this.animating.speedometer) return;
        
        this.animating.speedometer = true;
        this.elements.speedometer.classList.add('speed-change');
        
        setTimeout(() => {
            this.elements.speedometer.classList.remove('speed-change');
            this.animating.speedometer = false;
        }, 200);
    }

    triggerGearChange() {
        if (!this.elements.gearDisplay || this.animating.gear) return;
        
        this.animating.gear = true;
        this.elements.gearDisplay.classList.add('gear-change');
        
        setTimeout(() => {
            this.elements.gearDisplay.classList.remove('gear-change');
            this.animating.gear = false;
        }, 300);
    }

    triggerLowFuelWarning() {
        if (!this.elements.fuelGauge) return;
        
        this.elements.fuelGauge.classList.add('fuel-warning');
        setTimeout(() => {
            this.elements.fuelGauge.classList.remove('fuel-warning');
        }, 2000);
    }

    triggerEngineDamageWarning() {
        if (!this.elements.engineGauge) return;
        
        this.elements.engineGauge.classList.add('engine-warning');
        setTimeout(() => {
            this.elements.engineGauge.classList.remove('engine-warning');
        }, 1500);
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
        
        console.log(`[HUD:VEHICLE] Applied theme: ${themeName}`);
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
            lastUpdate: this.lastUpdate,
            performance: this.performance
        };
    }

    reset() {
        // Reset to default values
        this.data = {
            inVehicle: false,
            speed: 0,
            maxSpeed: 200,
            fuel: 100,
            engine: 100,
            seatbelt: false,
            harness: false,
            cruise: false,
            nitro: 0,
            gear: 1,
            rpm: 0,
            altitude: 0,
            speedUnit: 'MPH'
        };
        
        // Apply reset values
        this.setInVehicle(false);
        this.updateSpeed(0);
        this.updateFuel(100);
        this.updateEngine(100);
        this.updateGear(1);
        this.updateRPM(0);
        this.updateSeatbelt(false);
        this.updateHarness(false);
        this.updateCruise(false);
        this.updateNitro(0);
        this.updateAltitude(0);
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:VEHICLE] Debug Info:', {
                data: this.data,
                elements: Object.keys(this.elements),
                enabled: this.enabled,
                lastUpdate: new Date(this.lastUpdate),
                animating: this.animating,
                performance: this.performance
            });
        }
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create and register vehicle module
const vehicleModule = new VehicleModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => vehicleModule.init());
} else {
    vehicleModule.init();
}

// Export for global access
window.vehicleModule = vehicleModule;
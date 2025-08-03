/* ================================================================
   QBCore HUD - Health System Module
   Version: 3.0.0
   Description: Health, Armor, Hunger, Thirst, Stress, Oxygen management
   ================================================================ */

class HealthModule {
    constructor() {
        this.name = 'health';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 500; // 500ms updates
        
        // Status values
        this.status = {
            health: 100,
            armor: 0,
            hunger: 100,
            thirst: 100,
            stress: 0,
            oxygen: 100
        };
        
        // Animation states
        this.animating = {
            health: false,
            armor: false,
            hunger: false,
            thirst: false,
            stress: false,
            oxygen: false
        };
        
        // DOM elements cache
        this.elements = {};
        
        console.log('[HUD:HEALTH] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:HEALTH] Initializing health module...');
        
        // Cache DOM elements
        this.cacheElements();
        
        // Setup initial state
        this.setupInitialState();
        
        // Register with HUD manager
        if (window.hudManager) {
            window.hudManager.registerModule(this.name, this);
        }
        
        console.log('[HUD:HEALTH] Health module initialized successfully');
    }

    cacheElements() {
        // Health elements
        this.elements.healthContainer = document.getElementById('health-container');
        this.elements.healthFill = document.getElementById('health-fill');
        this.elements.healthText = document.getElementById('health-text');
        
        // Armor elements
        this.elements.armorContainer = document.getElementById('armor-container');
        this.elements.armorFill = document.getElementById('armor-fill');
        this.elements.armorText = document.getElementById('armor-text');
        
        // Hunger elements
        this.elements.hungerContainer = document.getElementById('hunger-container');
        this.elements.hungerFill = document.getElementById('hunger-fill');
        this.elements.hungerText = document.getElementById('hunger-text');
        
        // Thirst elements
        this.elements.thirstContainer = document.getElementById('thirst-container');
        this.elements.thirstFill = document.getElementById('thirst-fill');
        this.elements.thirstText = document.getElementById('thirst-text');
        
        // Stress elements
        this.elements.stressContainer = document.getElementById('stress-container');
        this.elements.stressFill = document.getElementById('stress-fill');
        this.elements.stressText = document.getElementById('stress-text');
        
        // Oxygen elements
        this.elements.oxygenContainer = document.getElementById('oxygen-container');
        this.elements.oxygenFill = document.getElementById('oxygen-fill');
        this.elements.oxygenText = document.getElementById('oxygen-text');
    }

    setupInitialState() {
        // Set initial values
        this.updateHealthBar('health', 100);
        this.updateHealthBar('armor', 0);
        this.updateHealthBar('hunger', 100);
        this.updateHealthBar('thirst', 100);
        this.updateHealthBar('stress', 0);
        this.updateHealthBar('oxygen', 100);
        
        // Hide bars that should be hidden initially
        this.setBarVisibility('oxygen', false); // Hide oxygen until underwater
    }

    // ================================================================
    // UPDATE METHODS
    // ================================================================

    update(data) {
        if (!data || !this.enabled) return;
        
        const now = Date.now();
        if (now - this.lastUpdate < this.updateInterval) return;
        this.lastUpdate = now;
        
        try {
            // Update individual stats
            if (data.health !== undefined) {
                this.updateHealth(data.health);
            }
            
            if (data.armor !== undefined) {
                this.updateArmor(data.armor);
            }
            
            if (data.hunger !== undefined) {
                this.updateHunger(data.hunger);
            }
            
            if (data.thirst !== undefined) {
                this.updateThirst(data.thirst);
            }
            
            if (data.stress !== undefined) {
                this.updateStress(data.stress);
            }
            
            if (data.oxygen !== undefined) {
                this.updateOxygen(data.oxygen);
            }
            
            // Batch update if provided
            if (data.stats) {
                Object.entries(data.stats).forEach(([stat, value]) => {
                    this.updateStat(stat, value);
                });
            }
            
        } catch (error) {
            console.error('[HUD:HEALTH] Error updating health data:', error);
        }
    }

    updateStat(stat, value) {
        if (this.status.hasOwnProperty(stat)) {
            const oldValue = this.status[stat];
            this.status[stat] = Math.max(0, Math.min(100, value));
            
            // Update bar with animation
            this.updateHealthBar(stat, this.status[stat]);
            
            // Special handling for certain stats
            this.handleStatSpecialCases(stat, this.status[stat], oldValue);
        }
    }

    updateHealth(value) {
        this.updateStat('health', value);
    }

    updateArmor(value) {
        this.updateStat('armor', value);
        
        // Show/hide armor bar based on value
        this.setBarVisibility('armor', value > 0);
    }

    updateHunger(value) {
        this.updateStat('hunger', value);
    }

    updateThirst(value) {
        this.updateStat('thirst', value);
    }

    updateStress(value) {
        this.updateStat('stress', value);
        
        // Show/hide stress bar based on value
        this.setBarVisibility('stress', value > 0);
    }

    updateOxygen(value) {
        this.updateStat('oxygen', value);
        
        // Show/hide oxygen bar based on value (typically only when underwater)
        this.setBarVisibility('oxygen', value < 100);
    }

    // ================================================================
    // BAR UPDATE METHODS
    // ================================================================

    updateHealthBar(stat, value) {
        const fillElement = this.elements[`${stat}Fill`];
        const textElement = this.elements[`${stat}Text`];
        const containerElement = this.elements[`${stat}Container`];
        
        if (!fillElement || !textElement) return;
        
        // Clamp value between 0 and 100
        const clampedValue = Math.max(0, Math.min(100, value));
        
        // Animate the fill bar
        if (!this.animating[stat]) {
            this.animating[stat] = true;
            
            // Update fill width with smooth animation
            fillElement.style.width = `${clampedValue}%`;
            
            // Update text value
            textElement.textContent = Math.round(clampedValue);
            
            // Add visual effects based on value
            this.applyStatusEffects(stat, clampedValue, containerElement);
            
            // Reset animation flag after transition
            setTimeout(() => {
                this.animating[stat] = false;
            }, 300);
        }
    }

    applyStatusEffects(stat, value, containerElement) {
        if (!containerElement) return;
        
        // Remove existing effect classes
        containerElement.classList.remove('critical', 'warning', 'normal', 'full');
        
        // Apply appropriate class based on value and stat type
        if (this.isCriticalStat(stat)) {
            // Health, hunger, thirst, oxygen - critical when low
            if (value <= 15) {
                containerElement.classList.add('critical');
                this.addPulseEffect(containerElement);
            } else if (value <= 30) {
                containerElement.classList.add('warning');
            } else if (value >= 100) {
                containerElement.classList.add('full');
            } else {
                containerElement.classList.add('normal');
            }
        } else {
            // Stress, armor - critical when high (stress) or special handling
            if (stat === 'stress') {
                if (value >= 85) {
                    containerElement.classList.add('critical');
                    this.addPulseEffect(containerElement);
                } else if (value >= 60) {
                    containerElement.classList.add('warning');
                } else {
                    containerElement.classList.add('normal');
                }
            } else if (stat === 'armor') {
                if (value >= 100) {
                    containerElement.classList.add('full');
                } else {
                    containerElement.classList.add('normal');
                }
            }
        }
    }

    isCriticalStat(stat) {
        return ['health', 'hunger', 'thirst', 'oxygen'].includes(stat);
    }

    addPulseEffect(element) {
        element.classList.add('pulse');
        setTimeout(() => {
            element.classList.remove('pulse');
        }, 2000);
    }

    // ================================================================
    // VISIBILITY METHODS
    // ================================================================

    setBarVisibility(stat, visible) {
        const containerElement = this.elements[`${stat}Container`];
        if (!containerElement) return;
        
        if (visible) {
            containerElement.classList.remove('hidden');
            containerElement.classList.add('visible', 'fade-in');
        } else {
            containerElement.classList.add('hidden');
            containerElement.classList.remove('visible');
        }
    }

    setModuleVisibility(visible) {
        const moduleElement = document.getElementById('module-health');
        if (!moduleElement) return;
        
        this.enabled = visible;
        
        if (visible) {
            moduleElement.classList.remove('hidden');
            moduleElement.classList.add('visible', 'fade-in');
        } else {
            moduleElement.classList.add('hidden');
            moduleElement.classList.remove('visible');
        }
    }

    // ================================================================
    // SPECIAL CASE HANDLING
    // ================================================================

    handleStatSpecialCases(stat, newValue, oldValue) {
        switch (stat) {
            case 'health':
                this.handleHealthChange(newValue, oldValue);
                break;
                
            case 'armor':
                this.handleArmorChange(newValue, oldValue);
                break;
                
            case 'stress':
                this.handleStressChange(newValue, oldValue);
                break;
                
            case 'oxygen':
                this.handleOxygenChange(newValue, oldValue);
                break;
        }
    }

    handleHealthChange(newValue, oldValue) {
        // Flash red effect on damage
        if (newValue < oldValue && newValue < 50) {
            this.flashEffect('health', 'damage');
        }
        
        // Critical health warning
        if (newValue <= 15 && oldValue > 15) {
            this.triggerCriticalWarning('health');
        }
    }

    handleArmorChange(newValue, oldValue) {
        // Flash blue effect on armor loss
        if (newValue < oldValue) {
            this.flashEffect('armor', 'armor-break');
        }
    }

    handleStressChange(newValue, oldValue) {
        // Trigger stress effects at high levels
        if (newValue >= 85 && oldValue < 85) {
            this.triggerStressEffects();
        }
    }

    handleOxygenChange(newValue, oldValue) {
        // Show oxygen bar when underwater
        if (newValue < 100 && oldValue >= 100) {
            this.setBarVisibility('oxygen', true);
        }
        
        // Hide oxygen bar when back to full
        if (newValue >= 100 && oldValue < 100) {
            setTimeout(() => {
                this.setBarVisibility('oxygen', false);
            }, 2000);
        }
    }

    // ================================================================
    // VISUAL EFFECTS
    // ================================================================

    flashEffect(stat, effectType) {
        const containerElement = this.elements[`${stat}Container`];
        if (!containerElement) return;
        
        containerElement.classList.add(`flash-${effectType}`);
        setTimeout(() => {
            containerElement.classList.remove(`flash-${effectType}`);
        }, 500);
    }

    triggerCriticalWarning(stat) {
        const containerElement = this.elements[`${stat}Container`];
        if (!containerElement) return;
        
        // Add critical warning class
        containerElement.classList.add('critical-warning');
        
        // Remove after warning period
        setTimeout(() => {
            containerElement.classList.remove('critical-warning');
        }, 3000);
    }

    triggerStressEffects() {
        // Add screen effects for high stress
        const hudContainer = document.getElementById('hud-container');
        if (hudContainer) {
            hudContainer.classList.add('stress-effects');
            
            setTimeout(() => {
                hudContainer.classList.remove('stress-effects');
            }, 2000);
        }
    }

    // ================================================================
    // UTILITY METHODS
    // ================================================================

    getStatus() {
        return {
            ...this.status,
            enabled: this.enabled,
            lastUpdate: this.lastUpdate
        };
    }

    reset() {
        // Reset all values to default
        this.status = {
            health: 100,
            armor: 0,
            hunger: 100,
            thirst: 100,
            stress: 0,
            oxygen: 100
        };
        
        // Update all bars
        Object.keys(this.status).forEach(stat => {
            this.updateHealthBar(stat, this.status[stat]);
        });
        
        // Reset visibility
        this.setBarVisibility('armor', false);
        this.setBarVisibility('stress', false);
        this.setBarVisibility('oxygen', false);
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:HEALTH] Debug Info:', {
                status: this.status,
                elements: Object.keys(this.elements),
                enabled: this.enabled,
                lastUpdate: new Date(this.lastUpdate)
            });
        }
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create and register health module
const healthModule = new HealthModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => healthModule.init());
} else {
    healthModule.init();
}

// Export for global access
window.healthModule = healthModule;
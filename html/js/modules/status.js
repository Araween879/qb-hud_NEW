/* ================================================================
   QBCore HUD - Status Module (Voice, Radio, Armed, etc.)
   Version: 3.0.0
   Description: Voice, Radio, Armed, Parachute, Harness, Cruise, Dev indicators
   ================================================================ */

class StatusModule {
    constructor() {
        this.name = 'status';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 200; // Fast updates for voice
        
        // Status states
        this.status = {
            voice: {
                level: 1,
                talking: false,
                radioActive: false
            },
            armed: false,
            parachute: {
                active: false,
                level: 1
            },
            harness: {
                active: false,
                level: 100
            },
            cruise: {
                active: false,
                speed: 0
            },
            devMode: false
        };
        
        // DOM elements cache
        this.elements = {};
        
        // Animation timers
        this.animationTimers = {};
        
        console.log('[HUD:STATUS] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:STATUS] Initializing status module...');
        
        // Cache DOM elements
        this.cacheElements();
        
        // Setup initial state
        this.setupInitialState();
        
        // Register with HUD manager
        if (window.hudManager) {
            window.hudManager.registerModule(this.name, this);
        }
        
        console.log('[HUD:STATUS] Status module initialized successfully');
    }

    cacheElements() {
        // Voice indicator elements
        this.elements.voiceIndicator = document.getElementById('voice-indicator');
        this.elements.voiceIcon = document.getElementById('voice-icon');
        this.elements.voiceLevel = document.getElementById('voice-level');
        
        // Armed indicator
        this.elements.armedIndicator = document.getElementById('armed-indicator');
        
        // Parachute indicator
        this.elements.parachuteIndicator = document.getElementById('parachute-indicator');
        this.elements.parachuteLevel = document.getElementById('parachute-level');
        
        // Harness indicator
        this.elements.harnessIndicator = document.getElementById('harness-indicator');
        this.elements.harnessLevel = document.getElementById('harness-level');
        
        // Cruise indicator
        this.elements.cruiseIndicator = document.getElementById('cruise-indicator');
        this.elements.cruiseSpeed = document.getElementById('cruise-speed');
        
        // Dev mode indicator
        this.elements.devIndicator = document.getElementById('dev-indicator');
    }

    setupInitialState() {
        // Set initial voice level
        this.updateVoiceLevel(1);
        
        // Hide all optional indicators initially
        this.setIndicatorVisibility('armed', false);
        this.setIndicatorVisibility('parachute', false);
        this.setIndicatorVisibility('harness', false);
        this.setIndicatorVisibility('cruise', false);
        this.setIndicatorVisibility('dev', false);
    }

    // ================================================================
    // UPDATE METHODS
    // ================================================================

    update(data) {
        if (!data || !this.enabled) return;
        
        const now = Date.now();
        
        try {
            // Voice updates (high frequency)
            if (data.voice !== undefined) {
                this.updateVoice(data.voice);
            }
            
            // Other status updates (can be less frequent)
            if (now - this.lastUpdate >= this.updateInterval) {
                if (data.armed !== undefined) {
                    this.updateArmed(data.armed);
                }
                
                if (data.parachute !== undefined) {
                    this.updateParachute(data.parachute);
                }
                
                if (data.harness !== undefined) {
                    this.updateHarness(data.harness);
                }
                
                if (data.cruise !== undefined) {
                    this.updateCruise(data.cruise);
                }
                
                if (data.devMode !== undefined) {
                    this.updateDevMode(data.devMode);
                }
                
                this.lastUpdate = now;
            }
            
        } catch (error) {
            console.error('[HUD:STATUS] Error updating status data:', error);
        }
    }

    // ================================================================
    // VOICE SYSTEM
    // ================================================================

    updateVoice(voiceData) {
        if (typeof voiceData === 'object') {
            // Detailed voice update
            if (voiceData.level !== undefined) {
                this.updateVoiceLevel(voiceData.level);
            }
            
            if (voiceData.talking !== undefined) {
                this.updateTalkingStatus(voiceData.talking);
            }
            
            if (voiceData.radioActive !== undefined) {
                this.updateRadioStatus(voiceData.radioActive);
            }
        } else if (typeof voiceData === 'number') {
            // Simple level update
            this.updateVoiceLevel(voiceData);
        }
    }

    updateVoiceLevel(level) {
        this.status.voice.level = Math.max(1, Math.min(4, level));
        
        if (this.elements.voiceLevel) {
            this.elements.voiceLevel.textContent = this.status.voice.level;
        }
        
        // Update icon based on level
        this.updateVoiceIcon();
    }

    updateTalkingStatus(talking) {
        this.status.voice.talking = talking;
        
        if (this.elements.voiceIndicator) {
            if (talking) {
                this.elements.voiceIndicator.classList.add('talking');
                this.startTalkingAnimation();
            } else {
                this.elements.voiceIndicator.classList.remove('talking');
                this.stopTalkingAnimation();
            }
        }
    }

    updateRadioStatus(radioActive) {
        this.status.voice.radioActive = radioActive;
        
        if (this.elements.voiceIndicator) {
            if (radioActive) {
                this.elements.voiceIndicator.classList.add('radio-active');
                this.startRadioAnimation();
            } else {
                this.elements.voiceIndicator.classList.remove('radio-active');
                this.stopRadioAnimation();
            }
        }
    }

    updateVoiceIcon() {
        if (!this.elements.voiceIcon) return;
        
        // Change icon based on voice level
        const icons = {
            1: 'fa-microphone-slash',  // Whisper
            2: 'fa-microphone',        // Normal
            3: 'fa-volume-up',         // Shout
            4: 'fa-bullhorn'           // Megaphone
        };
        
        // Remove all voice icon classes
        Object.values(icons).forEach(iconClass => {
            this.elements.voiceIcon.classList.remove(iconClass);
        });
        
        // Add current level icon
        const currentIcon = icons[this.status.voice.level] || icons[2];
        this.elements.voiceIcon.classList.add(currentIcon);
    }

    // ================================================================
    // ARMED SYSTEM
    // ================================================================

    updateArmed(armed) {
        this.status.armed = armed;
        this.setIndicatorVisibility('armed', armed);
        
        if (armed) {
            this.startArmedAnimation();
        } else {
            this.stopArmedAnimation();
        }
    }

    // ================================================================
    // PARACHUTE SYSTEM
    // ================================================================

    updateParachute(parachuteData) {
        if (typeof parachuteData === 'object') {
            this.status.parachute.active = parachuteData.active || false;
            this.status.parachute.level = parachuteData.level || 1;
        } else {
            this.status.parachute.active = parachuteData;
        }
        
        this.setIndicatorVisibility('parachute', this.status.parachute.active);
        
        if (this.elements.parachuteLevel) {
            this.elements.parachuteLevel.textContent = this.status.parachute.level;
        }
    }

    // ================================================================
    // HARNESS SYSTEM
    // ================================================================

    updateHarness(harnessData) {
        if (typeof harnessData === 'object') {
            this.status.harness.active = harnessData.active || false;
            this.status.harness.level = Math.max(0, Math.min(100, harnessData.level || 100));
        } else {
            this.status.harness.active = harnessData;
        }
        
        this.setIndicatorVisibility('harness', this.status.harness.active);
        
        if (this.elements.harnessLevel) {
            this.elements.harnessLevel.textContent = Math.round(this.status.harness.level);
        }
        
        // Apply warning effects for low harness
        if (this.status.harness.active && this.status.harness.level <= 25) {
            this.addWarningEffect('harness');
        }
    }

    // ================================================================
    // CRUISE SYSTEM
    // ================================================================

    updateCruise(cruiseData) {
        if (typeof cruiseData === 'object') {
            this.status.cruise.active = cruiseData.active || false;
            this.status.cruise.speed = cruiseData.speed || 0;
        } else {
            this.status.cruise.active = cruiseData;
        }
        
        this.setIndicatorVisibility('cruise', this.status.cruise.active);
        
        if (this.elements.cruiseSpeed) {
            this.elements.cruiseSpeed.textContent = Math.round(this.status.cruise.speed);
        }
    }

    // ================================================================
    // DEV MODE SYSTEM
    // ================================================================

    updateDevMode(devMode) {
        this.status.devMode = devMode;
        this.setIndicatorVisibility('dev', devMode);
        
        if (devMode) {
            this.startDevModeAnimation();
        } else {
            this.stopDevModeAnimation();
        }
    }

    // ================================================================
    // VISIBILITY METHODS
    // ================================================================

    setIndicatorVisibility(indicator, visible) {
        const elementKey = `${indicator}Indicator`;
        const element = this.elements[elementKey];
        
        if (!element) return;
        
        if (visible) {
            element.classList.remove('hidden');
            element.classList.add('visible', 'fade-in');
        } else {
            element.classList.add('hidden');
            element.classList.remove('visible');
        }
    }

    setModuleVisibility(visible) {
        const moduleElement = document.getElementById('module-status');
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
    // ANIMATION METHODS
    // ================================================================

    startTalkingAnimation() {
        this.stopAnimation('talking');
        
        if (this.elements.voiceIndicator) {
            this.elements.voiceIndicator.classList.add('pulse');
            
            this.animationTimers.talking = setInterval(() => {
                if (this.elements.voiceIcon) {
                    this.elements.voiceIcon.style.transform = 'scale(1.1)';
                    setTimeout(() => {
                        if (this.elements.voiceIcon) {
                            this.elements.voiceIcon.style.transform = 'scale(1)';
                        }
                    }, 250);
                }
            }, 500);
        }
    }

    stopTalkingAnimation() {
        this.stopAnimation('talking');
        
        if (this.elements.voiceIndicator) {
            this.elements.voiceIndicator.classList.remove('pulse');
        }
        
        if (this.elements.voiceIcon) {
            this.elements.voiceIcon.style.transform = 'scale(1)';
        }
    }

    startRadioAnimation() {
        this.stopAnimation('radio');
        
        if (this.elements.voiceIndicator) {
            this.animationTimers.radio = setInterval(() => {
                this.elements.voiceIndicator.classList.add('glow-pulse');
                setTimeout(() => {
                    if (this.elements.voiceIndicator) {
                        this.elements.voiceIndicator.classList.remove('glow-pulse');
                    }
                }, 750);
            }, 1500);
        }
    }

    stopRadioAnimation() {
        this.stopAnimation('radio');
        
        if (this.elements.voiceIndicator) {
            this.elements.voiceIndicator.classList.remove('glow-pulse');
        }
    }

    startArmedAnimation() {
        this.stopAnimation('armed');
        
        if (this.elements.armedIndicator) {
            this.elements.armedIndicator.classList.add('pulse');
        }
    }

    stopArmedAnimation() {
        this.stopAnimation('armed');
        
        if (this.elements.armedIndicator) {
            this.elements.armedIndicator.classList.remove('pulse');
        }
    }

    startDevModeAnimation() {
        this.stopAnimation('devMode');
        
        if (this.elements.devIndicator) {
            this.elements.devIndicator.classList.add('scan-line');
        }
    }

    stopDevModeAnimation() {
        this.stopAnimation('devMode');
        
        if (this.elements.devIndicator) {
            this.elements.devIndicator.classList.remove('scan-line');
        }
    }

    stopAnimation(type) {
        if (this.animationTimers[type]) {
            clearInterval(this.animationTimers[type]);
            delete this.animationTimers[type];
        }
    }

    stopAllAnimations() {
        Object.keys(this.animationTimers).forEach(type => {
            this.stopAnimation(type);
        });
    }

    // ================================================================
    // VISUAL EFFECTS
    // ================================================================

    addWarningEffect(indicator) {
        const elementKey = `${indicator}Indicator`;
        const element = this.elements[elementKey];
        
        if (element) {
            element.classList.add('warning');
            setTimeout(() => {
                element.classList.remove('warning');
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
        // Reset all status values
        this.status = {
            voice: {
                level: 1,
                talking: false,
                radioActive: false
            },
            armed: false,
            parachute: {
                active: false,
                level: 1
            },
            harness: {
                active: false,
                level: 100
            },
            cruise: {
                active: false,
                speed: 0
            },
            devMode: false
        };
        
        // Stop all animations
        this.stopAllAnimations();
        
        // Reset visibility
        this.setIndicatorVisibility('armed', false);
        this.setIndicatorVisibility('parachute', false);
        this.setIndicatorVisibility('harness', false);
        this.setIndicatorVisibility('cruise', false);
        this.setIndicatorVisibility('dev', false);
        
        // Reset voice display
        this.updateVoiceLevel(1);
        this.updateTalkingStatus(false);
        this.updateRadioStatus(false);
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:STATUS] Debug Info:', {
                status: this.status,
                elements: Object.keys(this.elements),
                animations: Object.keys(this.animationTimers),
                enabled: this.enabled,
                lastUpdate: new Date(this.lastUpdate)
            });
        }
    }

    // Test all indicators (debug only)
    testIndicators() {
        console.log('[HUD:STATUS] Testing all indicators...');
        
        // Test voice
        this.updateVoice({ level: 3, talking: true, radioActive: true });
        setTimeout(() => this.updateVoice({ level: 1, talking: false, radioActive: false }), 3000);
        
        // Test armed
        this.updateArmed(true);
        setTimeout(() => this.updateArmed(false), 2000);
        
        // Test parachute
        this.updateParachute({ active: true, level: 2 });
        setTimeout(() => this.updateParachute({ active: false }), 2000);
        
        // Test harness
        this.updateHarness({ active: true, level: 75 });
        setTimeout(() => this.updateHarness({ active: false }), 2000);
        
        // Test cruise
        this.updateCruise({ active: true, speed: 120 });
        setTimeout(() => this.updateCruise({ active: false }), 2000);
        
        // Test dev mode
        this.updateDevMode(true);
        setTimeout(() => this.updateDevMode(false), 2000);
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create and register status module
const statusModule = new StatusModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => statusModule.init());
} else {
    statusModule.init();
}

// Export for global access
window.statusModule = statusModule;
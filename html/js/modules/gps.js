// ================================================================
// QBCore HUD - GPS HUD JavaScript Module (HAUPT-INTERFACE)
// Version: 3.0.0
// Description: Complete GPS HUD with all status indicators
// ================================================================

class GPSHUDModule extends HUDModule {
    constructor(hudSystem) {
        super(hudSystem, 'GPS HUD');
        
        this.statusElements = new Map();
        this.warningStates = new Map();
        this.animationTimeouts = new Map();
        
        // Status thresholds
        this.thresholds = {
            health: { low: 25, critical: 10 },
            armor: { low: 25, critical: 10 },
            hunger: { low: 25, critical: 10 },
            thirst: { low: 25, critical: 10 },
            stress: { high: 75, critical: 90 },
            stamina: { low: 25, critical: 10 },
            oxygen: { low: 25, critical: 10 }
        };
        
        // Voice level configurations
        this.voiceLevels = {
            1: { name: 'Whisper', icon: 'fa-microphone-slash', color: '#666' },
            2: { name: 'Normal', icon: 'fa-microphone', color: '#00ff88' },
            3: { name: 'Shouting', icon: 'fa-microphone', color: '#ffb74d' },
            4: { name: 'Screaming', icon: 'fa-microphone', color: '#ff4444' }
        };
        
        this.init();
    }
    
    init() {
        super.init();
        this.createElement();
        this.setupEventListeners();
        this.setupStatusBars();
        this.setupVoiceIndicator();
        this.log('GPS HUD module initialized');
    }
    
    createElement() {
        // Main GPS HUD container
        this.element = document.createElement('div');
        this.element.id = 'gps-hud';
        this.element.className = 'module pos-bottom-left neon-panel visible';
        
        this.element.innerHTML = `
            <div class="scan-line"></div>
            
            <!-- Voice Indicator -->
            <div class="status-row voice-row" data-status="voice">
                <div class="voice-indicator">
                    <i class="fas fa-microphone status-icon voice-icon"></i>
                    <div class="voice-level">
                        <div class="voice-dot" data-level="1"></div>
                        <div class="voice-dot" data-level="2"></div>
                        <div class="voice-dot" data-level="3"></div>
                        <div class="voice-dot" data-level="4"></div>
                    </div>
                    <div class="voice-info">
                        <span class="voice-mode">Normal</span>
                        <span class="radio-channel hidden">CH: 0</span>
                    </div>
                </div>
            </div>
            
            <!-- Health Status -->
            <div class="status-row health-row" data-status="health">
                <i class="fas fa-heart status-icon health-color"></i>
                <div class="status-bar health-bar">
                    <div class="status-fill health-color" style="width: 100%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value health-value">100</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Armor Status -->
            <div class="status-row armor-row" data-status="armor">
                <i class="fas fa-shield-alt status-icon armor-color"></i>
                <div class="status-bar armor-bar">
                    <div class="status-fill armor-color" style="width: 0%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value armor-value">0</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Hunger Status -->
            <div class="status-row hunger-row" data-status="hunger">
                <i class="fas fa-hamburger status-icon hunger-color"></i>
                <div class="status-bar hunger-bar">
                    <div class="status-fill hunger-color" style="width: 100%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value hunger-value">100</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Thirst Status -->
            <div class="status-row thirst-row" data-status="thirst">
                <i class="fas fa-tint status-icon thirst-color"></i>
                <div class="status-bar thirst-bar">
                    <div class="status-fill thirst-color" style="width: 100%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value thirst-value">100</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Stress Status -->
            <div class="status-row stress-row" data-status="stress">
                <i class="fas fa-brain status-icon stress-color"></i>
                <div class="status-bar stress-bar">
                    <div class="status-fill stress-color" style="width: 0%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value stress-value">0</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Stamina Status -->
            <div class="status-row stamina-row" data-status="stamina">
                <i class="fas fa-running status-icon stamina-color"></i>
                <div class="status-bar stamina-bar">
                    <div class="status-fill stamina-color" style="width: 100%;"></div>
                    <div class="status-overlay"></div>
                </div>
                <span class="status-value stamina-value">100</span>
                <div class="status-indicator"></div>
            </div>
            
            <!-- Money Display (optional) -->
            <div class="money-display hidden">
                <div class="money-row">
                    <i class="fas fa-wallet status-icon"></i>
                    <span class="money-cash">$0</span>
                    <span class="money-bank">$0</span>
                </div>
            </div>
        `;
        
        // Add to HUD container
        const hudContainer = document.getElementById('hud-container');
        if (hudContainer) {
            hudContainer.appendChild(this.element);
        }
        
        // Cache status elements
        this.cacheStatusElements();
    }
    
    cacheStatusElements() {
        // Cache all status bar elements for performance
        const statusTypes = ['health', 'armor', 'hunger', 'thirst', 'stress', 'stamina'];
        
        statusTypes.forEach(type => {
            this.statusElements.set(type, {
                row: this.element.querySelector(`.${type}-row`),
                icon: this.element.querySelector(`.${type}-row .status-icon`),
                bar: this.element.querySelector(`.${type}-bar .status-fill`),
                value: this.element.querySelector(`.${type}-value`),
                indicator: this.element.querySelector(`.${type}-row .status-indicator`)
            });
        });
        
        // Cache voice elements
        this.statusElements.set('voice', {
            row: this.element.querySelector('.voice-row'),
            icon: this.element.querySelector('.voice-icon'),
            dots: this.element.querySelectorAll('.voice-dot'),
            mode: this.element.querySelector('.voice-mode'),
            radioChannel: this.element.querySelector('.radio-channel')
        });
        
        // Cache money elements
        this.statusElements.set('money', {
            display: this.element.querySelector('.money-display'),
            cash: this.element.querySelector('.money-cash'),
            bank: this.element.querySelector('.money-bank')
        });
    }
    
    setupEventListeners() {
        // Click handlers for status icons
        const statusTypes = ['health', 'armor', 'hunger', 'thirst', 'stress', 'stamina'];
        
        statusTypes.forEach(type => {
            const row = this.statusElements.get(type)?.row;
            if (row) {
                row.addEventListener('click', () => {
                    this.onStatusClick(type);
                });
                
                row.addEventListener('mouseenter', () => {
                    this.onStatusHover(type, true);
                });
                
                row.addEventListener('mouseleave', () => {
                    this.onStatusHover(type, false);
                });
            }
        });
        
        // Voice level cycle
        const voiceRow = this.statusElements.get('voice')?.row;
        if (voiceRow) {
            voiceRow.addEventListener('click', () => {
                this.onVoiceClick();
            });
        }
        
        // Money display toggle
        const moneyDisplay = this.statusElements.get('money')?.display;
        if (moneyDisplay) {
            moneyDisplay.addEventListener('click', () => {
                this.onMoneyClick();
            });
        }
    }
    
    setupStatusBars() {
        // Add smooth transitions to all status bars
        const statusTypes = ['health', 'armor', 'hunger', 'thirst', 'stress', 'stamina'];
        
        statusTypes.forEach(type => {
            const bar = this.statusElements.get(type)?.bar;
            if (bar) {
                bar.style.transition = 'width 0.3s ease, background-color 0.3s ease';
            }
        });
    }
    
    setupVoiceIndicator() {
        // Setup voice dots
        const voiceDots = this.statusElements.get('voice')?.dots;
        if (voiceDots) {
            voiceDots.forEach(dot => {
                dot.style.transition = 'background-color 0.2s ease, box-shadow 0.2s ease';
            });
        }
    }
    
    update(data) {
        super.update(data);
        
        if (!data) return;
        
        // Update voice system
        if (data.voice) {
            this.updateVoiceIndicator(data.voice);
        }
        
        // Update biometric status
        const statusTypes = ['health', 'armor', 'hunger', 'thirst', 'stress', 'stamina'];
        statusTypes.forEach(type => {
            if (data[type] !== undefined) {
                this.updateStatusBar(type, data[type]);
            }
        });
        
        // Update money display
        if (data.money) {
            this.updateMoneyDisplay(data.money);
        }
        
        // Update warning states
        this.updateWarningStates();
        
        // Update visibility based on config
        if (data.config) {
            this.updateVisibility(data.config);
        }
    }
    
    updateVoiceIndicator(voiceData) {
        const voiceElements = this.statusElements.get('voice');
        if (!voiceElements) return;
        
        const { level = 2, talking = false, radioActive = false, radioChannel = 0, radioTalking = false } = voiceData;
        
        // Update voice level dots
        voiceElements.dots.forEach((dot, index) => {
            const dotLevel = index + 1;
            const isActive = dotLevel <= level;
            
            if (isActive) {
                dot.classList.add('active');
                if (talking || radioTalking) {
                    dot.classList.add('talking');
                } else {
                    dot.classList.remove('talking');
                }
            } else {
                dot.classList.remove('active', 'talking');
            }
        });
        
        // Update voice mode text
        const voiceConfig = this.voiceLevels[level];
        if (voiceConfig && voiceElements.mode) {
            voiceElements.mode.textContent = voiceConfig.name;
        }
        
        // Update voice icon
        if (voiceElements.icon && voiceConfig) {
            voiceElements.icon.className = `fas ${voiceConfig.icon} status-icon voice-icon`;
            
            if (talking) {
                voiceElements.icon.style.color = voiceConfig.color;
                voiceElements.icon.classList.add('talking');
            } else {
                voiceElements.icon.style.color = '';
                voiceElements.icon.classList.remove('talking');
            }
        }
        
        // Update radio channel
        if (voiceElements.radioChannel) {
            if (radioActive && radioChannel > 0) {
                voiceElements.radioChannel.textContent = `CH: ${radioChannel}`;
                voiceElements.radioChannel.classList.remove('hidden');
                
                if (radioTalking) {
                    voiceElements.radioChannel.classList.add('radio-talking');
                } else {
                    voiceElements.radioChannel.classList.remove('radio-talking');
                }
            } else {
                voiceElements.radioChannel.classList.add('hidden');
            }
        }
    }
    
    updateStatusBar(type, value) {
        const elements = this.statusElements.get(type);
        if (!elements) return;
        
        // Clamp value between 0 and 100
        value = Math.max(0, Math.min(100, value));
        
        // Update bar width
        if (elements.bar) {
            elements.bar.style.width = `${value}%`;
        }
        
        // Update value text
        if (elements.value) {
            elements.value.textContent = Math.round(value);
        }
        
        // Update warning state
        this.updateStatusWarning(type, value);
        
        // Add change animation
        if (elements.row) {
            this.addChangeAnimation(elements.row);
        }
    }
    
    updateStatusWarning(type, value) {
        const elements = this.statusElements.get(type);
        const threshold = this.thresholds[type];
        if (!elements || !threshold) return;
        
        const row = elements.row;
        const isStress = type === 'stress';
        
        // Determine warning level
        let warningLevel = 'normal';
        
        if (isStress) {
            // Stress warnings are inverted (high is bad)
            if (value >= threshold.critical) {
                warningLevel = 'critical';
            } else if (value >= threshold.high) {
                warningLevel = 'warning';
            }
        } else {
            // Normal stats (low is bad)
            if (value <= threshold.critical) {
                warningLevel = 'critical';
            } else if (value <= threshold.low) {
                warningLevel = 'warning';
            }
        }
        
        // Update warning classes
        row.classList.remove('warning', 'critical', 'pulse-warning');
        
        if (warningLevel !== 'normal') {
            row.classList.add(warningLevel);
            
            // Add pulse animation for critical states
            if (warningLevel === 'critical') {
                row.classList.add('pulse-warning');
                this.startWarningPulse(type);
            }
        }
        
        // Store warning state
        this.warningStates.set(type, warningLevel);
    }
    
    updateMoneyDisplay(moneyData) {
        const elements = this.statusElements.get('money');
        if (!elements) return;
        
        const { cash = 0, bank = 0, total = 0 } = moneyData;
        
        // Format money values
        if (elements.cash) {
            elements.cash.textContent = this.formatMoney(cash);
        }
        
        if (elements.bank) {
            elements.bank.textContent = this.formatMoney(bank);
        }
        
        // Show money display if configured
        if (elements.display && (cash > 0 || bank > 0)) {
            elements.display.classList.remove('hidden');
        }
    }
    
    updateWarningStates() {
        // Check for multiple critical warnings
        const criticalWarnings = Array.from(this.warningStates.values())
                                     .filter(state => state === 'critical').length;
        
        if (criticalWarnings >= 3) {
            // Multiple critical warnings - add emergency state
            this.element.classList.add('emergency-state');
        } else {
            this.element.classList.remove('emergency-state');
        }
    }
    
    updateVisibility(config) {
        const { components = {}, visual = {} } = config;
        
        // Update component visibility
        Object.entries(components).forEach(([component, visible]) => {
            const row = this.element.querySelector(`[data-status="${component}"]`);
            if (row) {
                row.style.display = visible ? 'flex' : 'none';
            }
        });
        
        // Update visual settings
        if (visual.showWhenFull === false) {
            // Hide full bars
            const statusTypes = ['health', 'armor', 'hunger', 'thirst', 'stamina'];
            statusTypes.forEach(type => {
                const value = this.data[type];
                const row = this.statusElements.get(type)?.row;
                if (row && value >= 100) {
                    row.classList.add('hidden-when-full');
                } else if (row) {
                    row.classList.remove('hidden-when-full');
                }
            });
        }
        
        if (visual.showPercentage) {
            this.element.classList.add('show-percentages');
        } else {
            this.element.classList.remove('show-percentages');
        }
        
        if (visual.compactMode) {
            this.element.classList.add('compact-mode');
        } else {
            this.element.classList.remove('compact-mode');
        }
    }
    
    // ================================================================
    // EVENT HANDLERS
    // ================================================================
    
    onStatusClick(type) {
        const value = this.data[type] || 0;
        const warningState = this.warningStates.get(type) || 'normal';
        
        // Send click event to FiveM
        this.hud.postToFiveM({
            action: 'statusIconClick',
            type: type,
            value: value,
            warningState: warningState
        });
        
        // Visual feedback
        this.addClickAnimation(type);
        
        this.log(`Status clicked: ${type} (${value}%)`);
    }
    
    onStatusHover(type, isHover) {
        const row = this.statusElements.get(type)?.row;
        if (!row) return;
        
        if (isHover) {
            row.classList.add('hover');
            this.showStatusTooltip(type, row);
        } else {
            row.classList.remove('hover');
            this.hideStatusTooltip();
        }
    }
    
    onVoiceClick() {
        // Send voice cycle request to FiveM
        this.hud.postToFiveM({
            action: 'cycleVoiceLevel'
        });
        
        // Visual feedback
        const voiceRow = this.statusElements.get('voice')?.row;
        if (voiceRow) {
            this.addClickAnimation('voice');
        }
        
        this.log('Voice level cycle requested');
    }
    
    onMoneyClick() {
        // Toggle money display format or send money details request
        this.hud.postToFiveM({
            action: 'getMoneyDetails'
        });
        
        this.log('Money details requested');
    }
    
    // ================================================================
    // ANIMATION HELPERS
    // ================================================================
    
    addChangeAnimation(element) {
        element.classList.add('status-changed');
        setTimeout(() => {
            element.classList.remove('status-changed');
        }, 600);
    }
    
    addClickAnimation(type) {
        const row = this.statusElements.get(type)?.row;
        if (!row) return;
        
        row.classList.add('clicked');
        setTimeout(() => {
            row.classList.remove('clicked');
        }, 200);
    }
    
    startWarningPulse(type) {
        // Clear existing pulse
        if (this.animationTimeouts.has(type)) {
            clearTimeout(this.animationTimeouts.get(type));
        }
        
        // Start new pulse
        const row = this.statusElements.get(type)?.row;
        if (row) {
            const pulse = () => {
                if (this.warningStates.get(type) === 'critical') {
                    row.classList.add('pulse-glow');
                    setTimeout(() => {
                        row.classList.remove('pulse-glow');
                    }, 500);
                    
                    this.animationTimeouts.set(type, setTimeout(pulse, 1500));
                }
            };
            
            pulse();
        }
    }
    
    // ================================================================
    // TOOLTIP SYSTEM
    // ================================================================
    
    showStatusTooltip(type, element) {
        const value = this.data[type] || 0;
        const warningState = this.warningStates.get(type) || 'normal';
        
        // Create tooltip
        const tooltip = document.createElement('div');
        tooltip.className = `status-tooltip ${type}-tooltip ${warningState}`;
        
        const statusName = this.getStatusName(type);
        const statusInfo = this.getStatusInfo(type, value);
        
        tooltip.innerHTML = `
            <div class="tooltip-header">${statusName}</div>
            <div class="tooltip-value">${value}%</div>
            <div class="tooltip-info">${statusInfo}</div>
        `;
        
        // Position tooltip
        const rect = element.getBoundingClientRect();
        tooltip.style.position = 'fixed';
        tooltip.style.left = `${rect.right + 10}px`;
        tooltip.style.top = `${rect.top}px`;
        
        document.body.appendChild(tooltip);
        
        // Store reference
        this.currentTooltip = tooltip;
        
        // Animate in
        setTimeout(() => {
            tooltip.classList.add('visible');
        }, 10);
    }
    
    hideStatusTooltip() {
        if (this.currentTooltip) {
            this.currentTooltip.classList.remove('visible');
            setTimeout(() => {
                if (this.currentTooltip && this.currentTooltip.parentNode) {
                    this.currentTooltip.parentNode.removeChild(this.currentTooltip);
                }
                this.currentTooltip = null;
            }, 200);
        }
    }
    
    // ================================================================
    // UTILITY FUNCTIONS
    // ================================================================
    
    getStatusName(type) {
        const names = {
            health: 'Health',
            armor: 'Armor',
            hunger: 'Hunger',
            thirst: 'Thirst',
            stress: 'Stress',
            stamina: 'Stamina',
            oxygen: 'Oxygen'
        };
        return names[type] || type;
    }
    
    getStatusInfo(type, value) {
        if (type === 'stress') {
            if (value >= 90) return 'Extremely Stressed!';
            if (value >= 75) return 'Very Stressed';
            if (value >= 50) return 'Moderately Stressed';
            return 'Relaxed';
        } else {
            if (value <= 10) return 'Critical!';
            if (value <= 25) return 'Low';
            if (value <= 50) return 'Moderate';
            return 'Good';
        }
    }
    
    formatMoney(amount) {
        if (amount >= 1000000) {
            return `$${(amount / 1000000).toFixed(1)}M`;
        } else if (amount >= 1000) {
            return `$${(amount / 1000).toFixed(1)}K`;
        } else {
            return `$${amount}`;
        }
    }
    
    // ================================================================
    // MODULE LIFECYCLE
    // ================================================================
    
    updateFast() {
        // Fast updates for voice and critical systems
        if (this.data.voice?.talking) {
            this.updateVoiceTalkingAnimation();
        }
        
        // Update warning pulses
        this.updateWarningPulses();
    }
    
    updateNormal() {
        // Standard update cycle
        this.checkForDataChanges();
    }
    
    updateSlow() {
        // Cleanup and maintenance
        this.cleanupAnimations();
    }
    
    updateVoiceTalkingAnimation() {
        const voiceIcon = this.statusElements.get('voice')?.icon;
        if (voiceIcon && this.data.voice?.talking) {
            voiceIcon.classList.add('talking-pulse');
        } else if (voiceIcon) {
            voiceIcon.classList.remove('talking-pulse');
        }
    }
    
    updateWarningPulses() {
        // Update pulse animations for critical warnings
        this.warningStates.forEach((state, type) => {
            if (state === 'critical') {
                const row = this.statusElements.get(type)?.row;
                if (row && !row.classList.contains('pulse-warning')) {
                    row.classList.add('pulse-warning');
                }
            }
        });
    }
    
    checkForDataChanges() {
        // Check for significant data changes that need special handling
        // This could trigger events, sounds, or special animations
    }
    
    cleanupAnimations() {
        // Clean up old animation timeouts
        this.animationTimeouts.forEach((timeout, type) => {
            if (this.warningStates.get(type) !== 'critical') {
                clearTimeout(timeout);
                this.animationTimeouts.delete(type);
            }
        });
    }
    
    onThemeChange(theme, colors) {
        // Update colors based on theme
        this.log(`Theme changed to: ${theme}`);
        
        // Force re-render with new theme
        this.render();
    }
    
    onResize() {
        // Handle responsive changes
        this.updateResponsiveLayout();
    }
    
    updateResponsiveLayout() {
        const width = window.innerWidth;
        
        if (width < 1366) {
            this.element.classList.add('responsive-small');
        } else {
            this.element.classList.remove('responsive-small');
        }
        
        if (width < 1024) {
            this.element.classList.add('responsive-tiny');
        } else {
            this.element.classList.remove('responsive-tiny');
        }
    }
}

// Export the module
window.GPSHUDModule = GPSHUDModule;
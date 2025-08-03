/* ================================================================
   QBCore HUD - Time Module
   Version: 3.0.0
   Description: Time, Date, and Weather display system
   ================================================================ */

class TimeModule {
    constructor() {
        this.name = 'time';
        this.enabled = true;
        this.lastUpdate = 0;
        this.updateInterval = 1000; // Update every second
        
        // Time configuration
        this.config = {
            format24h: true,
            showDate: true,
            showWeather: false,
            showSeconds: false
        };
        
        // Current time data
        this.timeData = {
            hours: 0,
            minutes: 0,
            seconds: 0,
            day: 1,
            month: 1,
            year: 2024,
            weather: 'clear',
            temperature: 20
        };
        
        // DOM elements cache
        this.elements = {};
        
        // Month names for display
        this.monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        
        // Weather icons mapping
        this.weatherIcons = {
            'clear': 'fa-sun',
            'sunny': 'fa-sun',
            'clouds': 'fa-cloud',
            'overcast': 'fa-cloud',
            'rain': 'fa-cloud-rain',
            'storm': 'fa-bolt',
            'fog': 'fa-smog',
            'snow': 'fa-snowflake',
            'wind': 'fa-wind',
            'night': 'fa-moon'
        };
        
        console.log('[HUD:TIME] Module constructed');
    }

    // ================================================================
    // INITIALIZATION
    // ================================================================

    init() {
        console.log('[HUD:TIME] Initializing time module...');
        
        // Cache DOM elements
        this.cacheElements();
        
        // Setup initial state
        this.setupInitialState();
        
        // Start update loop
        this.startUpdateLoop();
        
        // Register with HUD manager
        if (window.hudManager) {
            window.hudManager.registerModule(this.name, this);
        }
        
        console.log('[HUD:TIME] Time module initialized successfully');
    }

    cacheElements() {
        // Time display elements
        this.elements.timeDisplay = document.getElementById('time-display');
        this.elements.dateDisplay = document.getElementById('date-display');
        this.elements.weatherDisplay = document.getElementById('weather-display');
        this.elements.weatherIcon = document.getElementById('weather-icon');
        this.elements.weatherText = document.getElementById('weather-text');
    }

    setupInitialState() {
        // Initialize with current browser time as fallback
        const now = new Date();
        this.timeData.hours = now.getHours();
        this.timeData.minutes = now.getMinutes();
        this.timeData.seconds = now.getSeconds();
        this.timeData.day = now.getDate();
        this.timeData.month = now.getMonth() + 1;
        this.timeData.year = now.getFullYear();
        
        // Initial display update
        this.updateTimeDisplay();
        this.updateDateDisplay();
        
        // Hide weather display initially
        if (this.elements.weatherDisplay) {
            this.elements.weatherDisplay.classList.add('hidden');
        }
    }

    startUpdateLoop() {
        // Update time display every second
        setInterval(() => {
            if (this.enabled) {
                this.updateTimeDisplay();
            }
        }, 1000);
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
            // Update time data
            if (data.time) {
                this.updateTimeData(data.time);
            }
            
            // Update date data
            if (data.date) {
                this.updateDateData(data.date);
            }
            
            // Update weather data
            if (data.weather) {
                this.updateWeatherData(data.weather);
            }
            
            // Update configuration
            if (data.config) {
                this.updateConfig(data.config);
            }
            
        } catch (error) {
            console.error('[HUD:TIME] Error updating time data:', error);
        }
    }

    updateTimeData(timeData) {
        if (timeData.hours !== undefined) {
            this.timeData.hours = Math.max(0, Math.min(23, timeData.hours));
        }
        
        if (timeData.minutes !== undefined) {
            this.timeData.minutes = Math.max(0, Math.min(59, timeData.minutes));
        }
        
        if (timeData.seconds !== undefined) {
            this.timeData.seconds = Math.max(0, Math.min(59, timeData.seconds));
        }
        
        this.updateTimeDisplay();
    }

    updateDateData(dateData) {
        if (dateData.day !== undefined) {
            this.timeData.day = Math.max(1, Math.min(31, dateData.day));
        }
        
        if (dateData.month !== undefined) {
            this.timeData.month = Math.max(1, Math.min(12, dateData.month));
        }
        
        if (dateData.year !== undefined) {
            this.timeData.year = dateData.year;
        }
        
        this.updateDateDisplay();
    }

    updateWeatherData(weatherData) {
        if (weatherData.condition !== undefined) {
            this.timeData.weather = weatherData.condition;
        }
        
        if (weatherData.temperature !== undefined) {
            this.timeData.temperature = weatherData.temperature;
        }
        
        this.updateWeatherDisplay();
    }

    updateConfig(configData) {
        // Update configuration settings
        Object.keys(configData).forEach(key => {
            if (this.config.hasOwnProperty(key)) {
                this.config[key] = configData[key];
            }
        });
        
        // Refresh displays based on new config
        this.updateTimeDisplay();
        this.updateDateDisplay();
        this.updateWeatherDisplay();
    }

    // ================================================================
    // DISPLAY UPDATE METHODS
    // ================================================================

    updateTimeDisplay() {
        if (!this.elements.timeDisplay) return;
        
        let timeString = '';
        
        if (this.config.format24h) {
            // 24-hour format
            const hours = String(this.timeData.hours).padStart(2, '0');
            const minutes = String(this.timeData.minutes).padStart(2, '0');
            
            timeString = `${hours}:${minutes}`;
            
            if (this.config.showSeconds) {
                const seconds = String(this.timeData.seconds).padStart(2, '0');
                timeString += `:${seconds}`;
            }
        } else {
            // 12-hour format
            let hours = this.timeData.hours;
            const ampm = hours >= 12 ? 'PM' : 'AM';
            
            hours = hours % 12;
            hours = hours ? hours : 12; // 0 should be 12
            
            const minutes = String(this.timeData.minutes).padStart(2, '0');
            
            timeString = `${hours}:${minutes} ${ampm}`;
            
            if (this.config.showSeconds) {
                const seconds = String(this.timeData.seconds).padStart(2, '0');
                timeString = `${hours}:${minutes}:${seconds} ${ampm}`;
            }
        }
        
        this.elements.timeDisplay.textContent = timeString;
        
        // Add glow effect animation
        this.addTimeGlowEffect();
    }

    updateDateDisplay() {
        if (!this.elements.dateDisplay) return;
        
        if (!this.config.showDate) {
            this.elements.dateDisplay.classList.add('hidden');
            return;
        }
        
        this.elements.dateDisplay.classList.remove('hidden');
        
        const monthName = this.monthNames[this.timeData.month - 1] || 'Unknown';
        const dateString = `${this.timeData.day}. ${monthName} ${this.timeData.year}`;
        
        this.elements.dateDisplay.textContent = dateString;
    }

    updateWeatherDisplay() {
        if (!this.elements.weatherDisplay) return;
        
        if (!this.config.showWeather) {
            this.elements.weatherDisplay.classList.add('hidden');
            return;
        }
        
        this.elements.weatherDisplay.classList.remove('hidden');
        
        // Update weather icon
        if (this.elements.weatherIcon) {
            // Remove all weather icon classes
            Object.values(this.weatherIcons).forEach(iconClass => {
                this.elements.weatherIcon.classList.remove(iconClass);
            });
            
            // Add current weather icon
            const iconClass = this.weatherIcons[this.timeData.weather] || this.weatherIcons['clear'];
            this.elements.weatherIcon.classList.add(iconClass);
        }
        
        // Update weather text
        if (this.elements.weatherText) {
            const weatherText = this.capitalizeFirst(this.timeData.weather);
            const tempText = this.timeData.temperature ? ` ${this.timeData.temperature}°C` : '';
            this.elements.weatherText.textContent = weatherText + tempText;
        }
        
        // Add weather-specific styling
        this.applyWeatherStyling();
    }

    // ================================================================
    // VISUAL EFFECTS
    // ================================================================

    addTimeGlowEffect() {
        if (!this.elements.timeDisplay) return;
        
        // Remove existing glow
        this.elements.timeDisplay.classList.remove('time-glow');
        
        // Add glow effect
        setTimeout(() => {
            this.elements.timeDisplay.classList.add('time-glow');
        }, 10);
        
        // Remove glow after animation
        setTimeout(() => {
            this.elements.timeDisplay.classList.remove('time-glow');
        }, 1000);
    }

    applyWeatherStyling() {
        if (!this.elements.weatherDisplay) return;
        
        // Remove all weather classes
        const weatherClasses = ['sunny', 'rainy', 'stormy', 'snowy', 'foggy', 'cloudy'];
        weatherClasses.forEach(cls => {
            this.elements.weatherDisplay.classList.remove(`weather-${cls}`);
        });
        
        // Add current weather class
        let weatherClass = 'sunny'; // default
        
        switch (this.timeData.weather) {
            case 'rain':
                weatherClass = 'rainy';
                break;
            case 'storm':
                weatherClass = 'stormy';
                break;
            case 'snow':
                weatherClass = 'snowy';
                break;
            case 'fog':
                weatherClass = 'foggy';
                break;
            case 'clouds':
            case 'overcast':
                weatherClass = 'cloudy';
                break;
            default:
                weatherClass = 'sunny';
        }
        
        this.elements.weatherDisplay.classList.add(`weather-${weatherClass}`);
    }

    // ================================================================
    // TIME ZONE & FORMAT METHODS
    // ================================================================

    setFormat24h(use24h) {
        this.config.format24h = use24h;
        this.updateTimeDisplay();
    }

    toggleFormat() {
        this.config.format24h = !this.config.format24h;
        this.updateTimeDisplay();
        return this.config.format24h;
    }

    setShowSeconds(showSeconds) {
        this.config.showSeconds = showSeconds;
        this.updateTimeDisplay();
    }

    setShowDate(showDate) {
        this.config.showDate = showDate;
        this.updateDateDisplay();
    }

    setShowWeather(showWeather) {
        this.config.showWeather = showWeather;
        this.updateWeatherDisplay();
    }

    // ================================================================
    // VISIBILITY METHODS
    // ================================================================

    setModuleVisibility(visible) {
        const moduleElement = document.getElementById('module-time');
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
    // UTILITY METHODS
    // ================================================================

    capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    getCurrentTime() {
        return {
            hours: this.timeData.hours,
            minutes: this.timeData.minutes,
            seconds: this.timeData.seconds,
            formatted: this.elements.timeDisplay ? this.elements.timeDisplay.textContent : ''
        };
    }

    getCurrentDate() {
        return {
            day: this.timeData.day,
            month: this.timeData.month,
            year: this.timeData.year,
            formatted: this.elements.dateDisplay ? this.elements.dateDisplay.textContent : ''
        };
    }

    getStatus() {
        return {
            timeData: { ...this.timeData },
            config: { ...this.config },
            enabled: this.enabled,
            lastUpdate: this.lastUpdate
        };
    }

    reset() {
        // Reset to current system time
        const now = new Date();
        this.timeData = {
            hours: now.getHours(),
            minutes: now.getMinutes(),
            seconds: now.getSeconds(),
            day: now.getDate(),
            month: now.getMonth() + 1,
            year: now.getFullYear(),
            weather: 'clear',
            temperature: 20
        };
        
        // Reset config to defaults
        this.config = {
            format24h: true,
            showDate: true,
            showWeather: false,
            showSeconds: false
        };
        
        // Update displays
        this.updateTimeDisplay();
        this.updateDateDisplay();
        this.updateWeatherDisplay();
    }

    // ================================================================
    // DEBUG METHODS
    // ================================================================

    debug(enabled = true) {
        if (enabled) {
            console.log('[HUD:TIME] Debug Info:', {
                timeData: this.timeData,
                config: this.config,
                elements: Object.keys(this.elements),
                enabled: this.enabled,
                lastUpdate: new Date(this.lastUpdate)
            });
        }
    }

    // Test different time formats (debug only)
    testFormats() {
        console.log('[HUD:TIME] Testing time formats...');
        
        // Test 24h format
        this.setFormat24h(true);
        setTimeout(() => {
            // Test 12h format
            this.setFormat24h(false);
            setTimeout(() => {
                // Test with seconds
                this.setShowSeconds(true);
                setTimeout(() => {
                    // Back to default
                    this.setFormat24h(true);
                    this.setShowSeconds(false);
                }, 2000);
            }, 2000);
        }, 2000);
    }

    // Test weather display (debug only)
    testWeather() {
        console.log('[HUD:TIME] Testing weather display...');
        
        const weatherTypes = ['clear', 'rain', 'storm', 'snow', 'fog', 'clouds'];
        let index = 0;
        
        this.setShowWeather(true);
        
        const interval = setInterval(() => {
            this.updateWeatherData({
                condition: weatherTypes[index],
                temperature: Math.floor(Math.random() * 30) + 10
            });
            
            index++;
            if (index >= weatherTypes.length) {
                clearInterval(interval);
                this.setShowWeather(false);
            }
        }, 1500);
    }
}

// ================================================================
// GLOBAL INITIALIZATION
// ================================================================

// Create and register time module
const timeModule = new TimeModule();

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => timeModule.init());
} else {
    timeModule.init();
}

// Export for global access
window.timeModule = timeModule;
# 🚀 QBCore HUD Modularisierung - Master TODO

## 📖 PROJEKT-ÜBERSICHT

### 🎯 **HAUPT-ZIEL**
Vollständige Modularisierung des bestehenden `qb-hud` Systems in eine moderne, erweiterbare und wartbare Architektur mit futuristischem Neon-Design.

### 🔄 **TRANSFORMATION**
**VON:** Monolithische client.lua (1000+ Zeilen) mit gekoppeltem HTML/CSS/JS  
**ZU:** Modulare Architektur mit klarer Trennung, Export-API und Design-System

### 🎨 **DESIGN-DNA (OBERSTE REGEL)**
```css
Primärfarbe: #B026FF (Magenta/Violett)
Sekundärfarbe: #0ff (Cyan) 
Akzentfarbe: #FFD700 (Gold)
Hintergrund: #1a1a1a → #111 (Dunkelgrau Gradient)
Font: 'Orbitron', sans-serif (UPPERCASE + letter-spacing: 1px)
Glow-Effekte: box-shadow: 0 0 15px rgba(176, 38, 255, 0.4)
Transitions: all 0.3s ease
Hover: translateY(-2px) + scale(1.05) + verstärkter Glow
Ultra-thin UI: Minimales Padding, kompakte Abstände
Scanning-Animation: 6s infinite gradient von links nach rechts
```

---

## 📋 VOLLSTÄNDIGE TODO-LISTE

### 🏗️ **PHASE 1: GRUNDSTRUKTUR (KRITISCH)**

#### 1.1 Manifest & Initialisierung
- [ ] **fxmanifest.lua aktualisieren**
  ```lua
  fx_version 'cerulean'
  game 'gta5' 
  lua54 'yes'
  author 'QBCore Framework'
  description 'Modular HUD System with Neon UI'
  version '3.0.0'
  
  shared_scripts {
      '@qb-core/shared/locale.lua',
      'locales/*.lua',
      'config.lua'
  }
  
  client_scripts {
      'init.lua',
      'client/*.lua',
      'client/extensions/*.lua'
  }
  
  server_script 'server.lua'
  ui_page 'html/index.html'
  
  files {
      'html/**/*',
      'html/js/modules/*.js',
      'html/modules/*.html'
  }
  ```

- [ ] **init.lua erstellen** - Zentraler Modulloader
  ```lua
  -- Lädt alle Module in korrekter Reihenfolge
  -- Startet Debug-Modus wenn Config.Debug = true
  -- Registriert zentrale Events
  -- Initialisiert Export-API
  ```

#### 1.2 Erweiterte Konfiguration
- [ ] **config.lua erweitern** mit Modulsteuerung
  ```lua
  Config.Debug = false
  Config.Modules = {
      health = { enabled = true, position = 'bottom-left' },
      status = { enabled = true, position = 'bottom-center' },
      time = { enabled = true, position = 'top-right' },
      map = { enabled = true, position = 'bottom-right' },
      location = { enabled = true, position = 'top-center' },
      extensions = { enabled = true }
  }
  
  Config.Themes = {
      default = 'neon-magenta',
      available = { 'neon-magenta', 'neon-cyan', 'classic' }
  }
  
  Config.UI = {
      scaling = 1.0,
      opacity = 0.9,
      animations = true,
      glow_effects = true
  }
  ```

---

### 🧩 **PHASE 2: CLIENT-MODULE AUFTEILEN**

#### 2.1 Gesundheits-System (health.lua)
- [ ] **client/health.lua erstellen**
  ```lua
  -- FUNKTIONEN:
  -- Health.Init() - Initialisierung
  -- Health.Update(data) - Daten-Update 
  -- Health.SetVisible(bool) - Sichtbarkeit
  -- Health.RegisterEvents() - Event-Registrierung
  
  -- ÜBERWACHT:
  -- Gesundheit (GetEntityHealth)
  -- Rüstung (GetPedArmour) 
  -- Hunger (PlayerData.metadata.hunger)
  -- Durst (PlayerData.metadata.thirst)
  -- Stress (PlayerData.metadata.stress)
  
  -- EVENTS:
  -- hud:client:UpdateNeeds
  -- hud:client:UpdateStress
  -- health:update, health:show, health:hide
  ```

#### 2.2 Status-System (status.lua)
- [ ] **client/status.lua erstellen**
  ```lua
  -- FUNKTIONEN:
  -- Status.Init(), Status.Update(), Status.SetVisible()
  
  -- ÜBERWACHT:
  -- Voice-Level (LocalPlayer.state.proximity)
  -- Radio-Kanal (LocalPlayer.state.radioChannel)
  -- Talking-Status (NetworkIsPlayerTalking)
  -- Bewaffnet-Status (GetSelectedPedWeapon)
  -- Dev-Mode (dev variable)
  -- Sauerstoff (GetPlayerUnderwaterTimeRemaining)
  -- Fallschirm (GetPedParachuteState)
  
  -- EVENTS:
  -- qb-admin:client:ToggleDevmode
  -- pma-voice:radioActive
  ```

#### 2.3 Zeit-System (time.lua)
- [ ] **client/time.lua erstellen**
  ```lua
  -- FUNKTIONEN:
  -- Time.Init(), Time.Update(), Time.GetServerTime()
  
  -- ÜBERWACHT:
  -- Serverzeit (QBCore.Functions.GetCurrentTime)
  -- Wetter-Status (via WeatherSync wenn verfügbar)
  -- Datum (GetClockDayOfMonth, GetClockMonth)
  
  -- DISPLAY:
  -- 24h Format: "15:30"
  -- Datum: "15. März 2024"
  -- Wetter-Icon (optional)
  ```

#### 2.4 Karten-System (map.lua)
- [ ] **client/map.lua erstellen**
  ```lua
  -- FUNKTIONEN:
  -- Map.Init(), Map.UpdateCompass(), Map.ToggleShape()
  
  -- ÜBERWACHT:
  -- Kompass-Richtung (GetEntityHeading)
  -- Minimap-Form (circle/square)
  -- Minimap-Sichtbarkeit (DisplayRadar)
  -- Altitude (GetEntityCoords.z für Flugzeuge)
  
  -- FEATURES:
  -- Dynamische Kompass-Updates
  -- Map-Shape-Toggle (Kreis/Quadrat)
  -- Altitude-Anzeige bei Flugzeugen
  -- Navigation-Ready für zukünftige GPS-Module
  ```

#### 2.5 Standort-System (location.lua)
- [ ] **client/location.lua erstellen**
  ```lua
  -- FUNKTIONEN:
  -- Location.Init(), Location.UpdateStreets(), Location.GetZone()
  
  -- ÜBERWACHT:
  -- Straßennamen (GetStreetNameAtCoord)
  -- Zonen-Information (GetNameOfZone)
  -- Gebäude-Erkennung (für zukünftige Features)
  
  -- DISPLAY:
  -- "Vinewood Hills"
  -- "Elgin Avenue / Power Street"
  -- Zone-basierte Icons (optional)
  ```

#### 2.6 UI-Manager (ui_manager.lua)
- [ ] **client/ui_manager.lua erstellen**
  ```lua
  -- ZENTRALE STEUERUNG:
  -- UIManager.SetTheme(theme)
  -- UIManager.ToggleModule(module, visible)
  -- UIManager.SetScale(scale)
  -- UIManager.SetOpacity(opacity)
  -- UIManager.HandleCinematicMode()
  
  -- VERANTWORTLICH FÜR:
  -- Modul-Sichtbarkeit koordinieren
  -- Theme-Wechsel propagieren
  -- Cinematic-Mode (schwarze Balken)
  -- UI-Scaling und Responsiveness
  -- Konflikt-Lösung zwischen Modulen
  ```

#### 2.7 Export-API (export_api.lua)
- [ ] **client/export_api.lua erstellen**
  ```lua
  -- EXPORT-FUNKTIONEN:
  exports('SetHudVisibility', function(visible) end)
  exports('SetTheme', function(theme) end)
  exports('UpdateStatus', function(data) end)
  exports('ShowCustomMessage', function(id, text, duration) end)
  exports('ToggleModule', function(module, visible) end)
  exports('RegisterCustomModule', function(name, config) end)
  
  -- CALLBACK-SYSTEM:
  QBCore.Functions.CreateCallback('hud:getModuleStatus')
  QBCore.Functions.CreateCallback('hud:getTheme')
  
  -- EVENT-WEITERLEITUNGEN:
  -- Zentrale Events an Module weiterleiten
  -- Cross-Module Kommunikation verwalten
  ```

#### 2.8 Menü-System (menu_ui.lua)
- [ ] **client/menu_ui.lua erstellen**
  ```lua
  -- /hud COMMAND HANDLER:
  -- Modernisiertes Settings-Menü
  -- Theme-Auswahl (Neon-Magenta, Neon-Cyan, Classic)
  -- Modul Ein/Aus-Schalter
  -- UI-Scaling Slider
  -- Opacity-Einstellungen
  -- Position-Presets
  
  -- INTEGRATION:
  -- qb-menu oder natives NUI-Menü
  -- Live-Preview der Änderungen
  -- Settings in localStorage speichern
  ```

#### 2.9 Fahrzeug-System (vehicle.lua)
- [ ] **client/vehicle.lua erstellen**
  ```lua
  -- FAHRZEUG-SPEZIFISCHE FEATURES:
  -- Geschwindigkeitsanzeige (MPH/KPH)
  -- Kraftstoff-Level (LegacyFuel Integration)
  -- Motor-Gesundheit (GetVehicleEngineHealth)
  -- Sicherheitsgurt-Status 
  -- Gurt-Indikator (harness System)
  -- Tempomat-Anzeige
  -- Nitro-Level (wenn verfügbar)
  
  -- EVENTS:
  -- seatbelt:client:ToggleSeatbelt
  -- seatbelt:client:ToggleCruise
  -- hud:client:UpdateNitrous
  -- hud:client:UpdateHarness
  ```

#### 2.10 Extensions-Ordner
- [ ] **client/extensions/ erstellen** für zukünftige Module:
  ```
  client/extensions/
  ├── navigation.lua      (GPS, Routing)
  ├── biometrics.lua      (Erweiterte Vital-Daten)
  ├── environment.lua     (Umgebungssensoren)
  ├── communication.lua   (Erweiterte Radio-Features)
  └── custom_modules.lua  (User-definierte Module)
  ```

---

### 🎨 **PHASE 3: HTML/CSS/JS MODERNISIERUNG**

#### 3.1 HTML-Struktur
- [ ] **html/index.html neu strukturieren**
  ```html
  <!DOCTYPE html>
  <html>
  <head>
      <meta charset="utf-8">
      <title>QBCore HUD</title>
      <link rel="stylesheet" href="style.css">
      <link rel="stylesheet" href="ui-theme.css">
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
      <link rel="stylesheet" href="https://pro.fontawesome.com/releases/v5.13.0/css/all.css">
  </head>
  <body>
      <div id="hud-container">
          <!-- Module werden dynamisch geladen -->
          <div id="module-health"></div>
          <div id="module-status"></div>
          <div id="module-time"></div>
          <div id="module-map"></div>
          <div id="module-location"></div>
          <div id="module-vehicle"></div>
      </div>
      
      <!-- Settings Menu -->
      <div id="settings-menu" class="hidden"></div>
      
      <!-- Scripts -->
      <script src="js/main.js"></script>
      <script src="js/modules/health.js"></script>
      <script src="js/modules/status.js"></script>
      <script src="js/modules/time.js"></script>
      <script src="js/modules/map.js"></script>
      <script src="js/modules/location.js"></script>
      <script src="js/modules/vehicle.js"></script>
  </body>
  </html>
  ```

#### 3.2 CSS-System
- [ ] **html/style.css - Basis-Styling**
  ```css
  /* Reset & Base */
  * { margin: 0; padding: 0; box-sizing: border-box; }
  
  body {
      font-family: 'Orbitron', sans-serif;
      background: transparent;
      overflow: hidden;
      user-select: none;
  }
  
  #hud-container {
      position: fixed;
      top: 0; left: 0;
      width: 100vw; height: 100vh;
      pointer-events: none;
  }
  
  /* Module Positioning */
  .module {
      position: absolute;
      pointer-events: auto;
      transition: all 0.3s ease;
  }
  
  .module.hidden { opacity: 0; transform: scale(0.8); }
  .module.visible { opacity: 1; transform: scale(1); }
  ```

- [ ] **html/ui-theme.css - Neon Design-DNA**
  ```css
  /* DESIGN-DNA IMPLEMENTATION */
  :root {
      --primary: #B026FF;
      --secondary: #0ff;
      --accent: #FFD700;
      --bg-dark: #1a1a1a;
      --bg-darker: #111;
      --text-primary: #fff;
      --text-secondary: #e0e0e0;
      --glow-primary: 0 0 15px rgba(176, 38, 255, 0.4);
      --glow-secondary: 0 0 15px rgba(0, 255, 255, 0.4);
  }
  
  /* Neon Effects */
  .neon-glow {
      box-shadow: var(--glow-primary);
      border: 2px solid var(--primary);
  }
  
  .neon-text {
      color: var(--primary);
      text-shadow: 0 0 10px var(--primary);
      text-transform: uppercase;
      letter-spacing: 1px;
  }
  
  /* Scanning Animation */
  @keyframes scan {
      0% { left: -100%; }
      100% { left: 100%; }
  }
  
  .scan-line {
      position: absolute;
      top: 0; bottom: 0;
      width: 2px;
      background: linear-gradient(90deg, transparent, var(--primary), transparent);
      animation: scan 6s infinite;
  }
  
  /* Status Colors */
  .status-health { color: #ff4444; }
  .status-armor { color: #00bcd4; }
  .status-hunger { color: #ffb74d; }
  .status-thirst { color: #29b6f6; }
  .status-stress { color: #a020f0; }
  .status-stamina { color: #66bb6a; }
  ```

#### 3.3 JavaScript-Module
- [ ] **html/js/main.js - Zentrale Steuerung**
  ```javascript
  class HUDManager {
      constructor() {
          this.modules = new Map();
          this.theme = 'neon-magenta';
          this.debug = false;
      }
  
      registerModule(name, module) {
          this.modules.set(name, module);
      }
  
      updateModule(name, data) {
          const module = this.modules.get(name);
          if (module) module.update(data);
      }
  
      setTheme(theme) {
          document.body.className = `theme-${theme}`;
          this.theme = theme;
      }
  
      toggleModule(name, visible) {
          const element = document.getElementById(`module-${name}`);
          if (element) {
              element.classList.toggle('hidden', !visible);
              element.classList.toggle('visible', visible);
          }
      }
  }
  
  const hudManager = new HUDManager();
  
  // Message Handler
  window.addEventListener('message', (event) => {
      const { action, module, data } = event.data;
      
      switch (action) {
          case 'updateModule':
              hudManager.updateModule(module, data);
              break;
          case 'toggleModule':
              hudManager.toggleModule(module, data.visible);
              break;
          case 'setTheme':
              hudManager.setTheme(data.theme);
              break;
      }
  });
  ```

- [ ] **html/js/modules/ - Modul-spezifische JS-Dateien**
  - health.js - Health/Status Balken Management
  - status.js - Voice/Radio/Armed Indicators
  - time.js - Zeit/Datum Display
  - map.js - Kompass/Minimap Controls
  - location.js - Straßennamen Updates
  - vehicle.js - Fahrzeug-HUD Management

#### 3.4 HTML-Templates
- [ ] **html/modules/ - Modul-HTML-Templates**
  ```html
  <!-- health.html -->
  <div class="health-container neon-glow">
      <div class="health-bar">
          <i class="fas fa-heart status-health"></i>
          <div class="bar-fill" id="health-fill"></div>
      </div>
      <!-- Armor, Hunger, Thirst, Stress Bars -->
  </div>
  
  <!-- status.html -->
  <div class="status-container">
      <div class="voice-indicator neon-glow">
          <i class="fas fa-microphone"></i>
          <span id="voice-level"></span>
      </div>
      <!-- Radio, Armed, Dev-Mode Indicators -->
  </div>
  ```

---

### 🔌 **PHASE 4: INTEGRATION & KOMPATIBILITÄT**

#### 4.1 QBCore Integration
- [ ] **Bestehende Events beibehalten**
  ```lua
  -- Alle bisherigen Events müssen weiterhin funktionieren:
  -- hud:client:UpdateNeeds
  -- hud:client:UpdateStress
  -- hud:client:ToggleAirHud
  -- hud:client:ShowAccounts
  -- hud:client:OnMoneyChange
  -- seatbelt:client:ToggleSeatbelt
  -- etc.
  ```

- [ ] **Server-Events anpassen**
  ```lua
  -- server.lua modernisieren aber API beibehalten
  -- /cash, /bank Commands
  -- hud:server:GainStress, hud:server:RelieveStress
  -- Callback: hud:server:getMenu
  ```

#### 4.2 Externe Abhängigkeiten
- [ ] **LegacyFuel Integration prüfen**
- [ ] **interact-sound Kompatibilität**
- [ ] **qb-voice Integration**
- [ ] **qb-menu für Settings**

#### 4.3 Rückwärts-Kompatibilität
- [ ] **Alte Export-Calls weiterleiten**
- [ ] **Config-Migration implementieren**
- [ ] **Graceful Degradation bei fehlenden Modulen**

---

### 🧪 **PHASE 5: TESTING & DEBUGGING**

#### 5.1 Debug-System
- [ ] **Erweiterte Debug-Ausgaben**
  ```lua
  Config.Debug = true -- Aktiviert detaillierte Logs
  
  -- Debug-Funktionen:
  -- HUD:DebugModule(name) - Zeigt Modul-Status
  -- HUD:DebugEvents() - Event-Tracing
  -- HUD:DebugPerformance() - Performance-Monitoring
  ```

- [ ] **Performance-Monitoring**
  ```lua
  -- FPS-Impact Messung
  -- Memory-Usage Tracking
  -- Event-Frequency Monitoring
  ```

#### 5.2 Test-Szenarien
- [ ] **Modul-Toggle Tests**
- [ ] **Theme-Wechsel Tests**
- [ ] **Fahrzeug Ein/Ausstieg Tests**
- [ ] **Stress-System Tests**
- [ ] **Voice/Radio Tests**
- [ ] **Responsive Design Tests (verschiedene Auflösungen)**

---

### 🚀 **PHASE 6: ERWEITERUNGEN & ZUKUNFT**

#### 6.1 Geplante Extensions
- [ ] **Navigation-System (navigation.lua)**
  ```lua
  -- GPS-Integration
  -- Waypoint-System
  -- Route-Berechnung
  -- Turn-by-Turn Anweisungen
  ```

- [ ] **Biometrics-System (biometrics.lua)**
  ```lua
  -- Erweiterte Vital-Daten
  -- Herzfrequenz-Simulation
  -- Körpertemperatur
  -- Müdigkeits-Level
  ```

- [ ] **Environment-System (environment.lua)**
  ```lua
  -- Umgebungstemperatur
  -- Luftqualität
  -- Lärmpegel
  -- Wetter-Details
  ```

#### 6.2 API-Erweiterungen
- [ ] **Plugin-System für Third-Party Module**
- [ ] **Custom-Theme-Builder**
- [ ] **Advanced Animation System**
- [ ] **Mobile-Responsive Design**

---

## 📊 ERFOLGS-KRITERIEN

### ✅ FUNKTIONALE ANFORDERUNGEN
- [ ] Alle bestehenden HUD-Features funktionieren
- [ ] /hud Menü ist voll funktional
- [ ] Performance ist gleich oder besser als vorher
- [ ] Keine Breaking Changes für andere Ressourcen
- [ ] Alle QBCore-Events werden korrekt verarbeitet

### ✅ TECHNISCHE ANFORDERUNGEN  
- [ ] Modulare Architektur mit klarer Trennung
- [ ] Export-API für externe Ressourcen
- [ ] Event-basierte Kommunikation
- [ ] Vollständige Code-Dokumentation
- [ ] Debug-System für Entwickler

### ✅ DESIGN-ANFORDERUNGEN
- [ ] Neon Design-DNA durchgängig implementiert
- [ ] Orbitron Font überall verwendet
- [ ] Magenta/Cyan Farbschema konsequent
- [ ] Glow-Effekte und Animationen aktiv
- [ ] Ultra-thin Layout-Design
- [ ] Responsive für alle Auflösungen

### ✅ ERWEITERBARKEITS-ANFORDERUNGEN
- [ ] Neue Module können ohne Core-Änderungen hinzugefügt werden
- [ ] Theme-System ermöglicht einfache Design-Anpassungen
- [ ] Export-API ermöglicht externe Integration
- [ ] Extensions-Ordner bereit für Community-Module

---

## 🛡️ KRITISCHE SICHERHEITSREGELN

### ❌ VERBOTENE PRAKTIKEN
1. **Unvollständige SQL-Strings** - Immer `string.format()` richtig schließen
2. **Fehlende Typ-Prüfung** - Immer `type()` vor Funktionsaufrufen
3. **FiveM Natives im Browser** - Nur `fetch()` verwenden
4. **Unvalidierte Daten** - Immer Eingaben prüfen
5. **Ressourcen ohne Status-Check** - Immer Verfügbarkeit prüfen

### ✅ PFLICHT-PRAKTIKEN
1. **Event-basierte Kommunikation** zwischen Modulen
2. **Graceful Degradation** bei fehlenden Abhängigkeiten
3. **Performance-bewusste Updates** (nicht jeden Frame)
4. **Konsistente Error-Handling** in allen Modulen
5. **Vollständige Code-Dokumentation** für alle Funktionen

---

## 📝 ARBEITSSTAND & NÄCHSTE SCHRITTE

### 🎯 AKTUELLER STATUS
**Phase:** Planung abgeschlossen  
**Bereit für:** Implementierung PHASE 1  
**Priorität:** Grundstruktur (fxmanifest.lua, init.lua, config.lua)

### 🔄 NÄCHSTE ARBEITSSCHRITTE
1. **fxmanifest.lua** aktualisieren mit neuer Modulstruktur
2. **init.lua** erstellen als zentraler Modulloader  
3. **config.lua** erweitern um Modulkonfiguration
4. **client/health.lua** als erstes Beispielmodul implementieren
5. **HTML-Grundstruktur** mit Neon-Design aufbauen

### 🚨 WICHTIGE ERINNERUNGEN
- **Keine Breaking Changes** - Alles muss weiterhin funktionieren
- **Design-DNA einhalten** - Magenta/Cyan/Orbitron überall
- **Modular denken** - Jedes Modul eigenständig und austauschbar
- **Performance beachten** - Nicht mehr Ressourcen verbrauchen als nötig
- **Dokumentation schreiben** - Für andere Entwickler verständlich

---

**🎮 VISION:** Ein ultramodernes, erweiterbares HUD-System das als Grundlage für alle zukünftigen UI-Entwicklungen im QBCore-Framework dient - mit futuristischem Neon-Design und modularer Architektur.

**🏁 DEADLINE:** Vollständige Implementierung in logischen Phasen, ohne Zeitdruck aber mit konsequenter Umsetzung der Design-DNA und Architektur-Prinzipien.
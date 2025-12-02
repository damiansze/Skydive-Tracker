# Freefall-Detektion Anleitung

## Übersicht

Die Freefall-Detektion erfasst automatisch:
- **Exit-Zeitpunkt**: Wann der Freefall beginnt
- **Deployment-Zeitpunkt**: Wann der Schirm öffnet
- **Freefall-Dauer**: Gesamtdauer des Freefalls in Sekunden
- **Maximale Geschwindigkeit**: Höchste erreichte vertikale Geschwindigkeit (m/s und km/h)

## Verwendung

### 1. Sprung simulieren (für Tests)

Um die Freefall-Detektion mit simulierten Daten zu testen:

```bash
# Mit Simulation
flutter run --dart-define=USE_SIMULATED_SENSORS=true

# Mit echten Sensoren (Standard)
flutter run
```

### 2. Sprung erfassen mit Freefall-Detektion

1. **Neuen Sprung erstellen**: Tippe auf den `+` Button
2. **Freefall-Detektion starten**: 
   - Im Formular findest du die "Freefall-Detektion" Sektion
   - Tippe auf "Detektion starten"
   - Die Detektion läuft im Hintergrund
3. **Während des Sprungs**:
   - Die App zeigt Live-Updates:
     - Freefall-Dauer (läuft hoch)
     - Maximale Geschwindigkeit (wird aktualisiert)
     - Exit-Zeitpunkt (wird erkannt)
4. **Nach dem Sprung**:
   - Tippe auf "Stoppen" wenn der Sprung beendet ist
   - Die finalen Statistiken werden angezeigt
5. **Sprung speichern**:
   - Fülle die restlichen Felder aus (Ort, Höhe, etc.)
   - Tippe auf "Sprung speichern"
   - Die Freefall-Statistiken werden automatisch mitgespeichert

### 3. Freefall-Statistiken anzeigen

Die Freefall-Statistiken werden automatisch angezeigt:
- **In der Sprung-Liste**: Als Badge unter jedem Sprung mit Freefall-Daten
- **Beim Bearbeiten**: Die Daten werden geladen und können aktualisiert werden

## Simulation Details

Die Simulation erstellt realistische Freefall-Daten:
- **Phase 1 (0-2s)**: Exit-Phase mit hoher Beschleunigung
- **Phase 2 (2-50s)**: Freefall mit ~9.8 m/s² (Gravitation)
- **Phase 3 (50s+)**: Deployment mit starker Verzögerung

Die Simulation erkennt automatisch:
- Exit nach ~0.5 Sekunden
- Deployment nach ~50 Sekunden

## Technische Details

### Sensoren
- **Accelerometer**: Misst Beschleunigung (10 Hz Update-Rate)
- **Gyroscope**: Optional für bessere Genauigkeit

### Detektions-Algorithmus
- **Exit-Erkennung**: Plötzliche Beschleunigungsänderung (>2 m/s²)
- **Deployment-Erkennung**: Starke Verzögerung (>15 m/s²)
- **Geschwindigkeitsberechnung**: Integration der Beschleunigung über Zeit

### Datenbank
Die Freefall-Statistiken werden in folgenden Spalten gespeichert:
- `freefall_duration_seconds` (REAL)
- `max_vertical_velocity_ms` (REAL)
- `exit_time` (DATETIME)
- `deployment_time` (DATETIME)

## Fehlerbehebung

### Sensoren funktionieren nicht
- Prüfe die App-Berechtigungen für Sensoren
- Auf iOS: In `Info.plist` Sensor-Berechtigungen hinzufügen
- Auf Android: Berechtigungen werden automatisch angefordert

### Simulation funktioniert nicht
- Stelle sicher, dass `USE_SIMULATED_SENSORS=true` gesetzt ist
- Starte die App neu nach dem Setzen der Variable

### Keine Exit/Deployment-Erkennung
- Die Detektion benötigt ausreichend Sensordaten
- Bei Simulation: Warte bis die Simulation läuft
- Bei echten Sensoren: Stelle sicher, dass das Gerät bewegt wird

## Nächste Schritte

1. **Datenbank-Migration ausführen**:
   ```bash
   cd backend
   python migrate_db.py
   ```

2. **Backend starten**:
   ```bash
   cd backend
   python run.py
   ```

3. **App mit Simulation testen**:
   ```bash
   cd frontend
   flutter run --dart-define=USE_SIMULATED_SENSORS=true
   ```

4. **Echten Sprung testen**:
   - Starte die Detektion vor dem Sprung
   - Lasse sie während des gesamten Sprungs laufen
   - Stoppe sie nach der Landung

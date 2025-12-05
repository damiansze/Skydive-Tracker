# 🪂 Skydive Tracker

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)

**Eine umfassende App zur Erfassung, Verwaltung und Analyse von Fallschirmsprüngen**

*Verfügbar für Android, iOS und WearOS*

</div>

---

## ✨ Features

### 📱 Mobile App (Android & iOS)
- **Sprungerfassung** – Erfasse Sprünge mit Datum, Zeit, Ort (GPS & Kartenauswahl), Höhe und Sprungtyp
- **Wetter-Integration** – Automatischer Abruf von Wetterdaten (Temperatur, Wind, Luftfeuchtigkeit) via Open-Meteo API
- **Freefall-Detektion** – Automatische Erkennung von Exit und Deployment via Beschleunigungssensoren
- **Statistiken** – Gesamtzahl Sprünge, Freefall-Zeit, Durchschnittsgeschwindigkeit, Sprünge pro Monat
- **Achievements** – Freischaltbare Erfolge basierend auf Sprunganzahl und Meilensteinen
- **Equipment-Verwaltung** – Verwalte dein Gurtzeug, Schirme und weitere Ausrüstung
- **Profil** – Persönliche Daten und Lizenzinformationen
- **Design-Modi** – Hell, Dunkel und System-Modus
- **Einstellungen** – Metrisch/Imperial, 24h/12h Zeitformat

### ⌚ WearOS (Smartwatch)
- **Kompaktes UI** – Optimiert für runde Displays
- **Sprungerfassung** – Vereinfachte Erfassung direkt am Handgelenk
- **Live Freefall-Detektion** – Echtzeit-Tracking während des Sprungs
- **Statistiken** – Schneller Überblick über deine Sprungdaten
- **Simulationsmodus** – Zum Testen der Freefall-Detektion

---

## 🛠️ Tech Stack

### Frontend (Flutter)
| Technologie | Verwendung |
|-------------|------------|
| Flutter 3.x | Cross-Platform Framework |
| Dart | Programmiersprache |
| Riverpod | State Management |
| flutter_map | Kartenansicht |
| geolocator | GPS-Ortung |
| sensors_plus | Beschleunigungssensoren |
| intl | Internationalisierung |

### Backend (Python)
| Technologie | Verwendung |
|-------------|------------|
| FastAPI | REST API Framework |
| SQLAlchemy | ORM für SQLite |
| Pydantic | Schema Validation |
| httpx | HTTP Client (Wetter-API) |
| pytest | Testing |

### Externe APIs
- **Open-Meteo** – Wettervorhersage und historische Wetterdaten

---

## 📁 Projektstruktur

```
Skydive-Tracker/
├── 📂 frontend/                    # Flutter App
│   ├── 📂 lib/
│   │   ├── 📂 config/              # API-Konfiguration
│   │   ├── 📂 models/              # Datenmodelle
│   │   │   ├── achievement.dart
│   │   │   ├── equipment.dart
│   │   │   ├── freefall_stats.dart
│   │   │   ├── jump.dart
│   │   │   ├── profile.dart
│   │   │   └── weather.dart
│   │   ├── 📂 providers/           # Riverpod State Providers
│   │   ├── 📂 screens/             # UI Screens
│   │   │   ├── 📂 wear_os/         # WearOS-spezifische Screens
│   │   │   └── ...
│   │   ├── 📂 services/            # Business Logic & APIs
│   │   │   ├── api_service.dart
│   │   │   ├── freefall_detection_service.dart
│   │   │   ├── geocoding_service.dart
│   │   │   ├── weather_service.dart
│   │   │   └── ...
│   │   ├── 📂 widgets/             # Wiederverwendbare Widgets
│   │   │   └── 📂 wear_os/         # WearOS-spezifische Widgets
│   │   └── main.dart               # App Entry Point
│   ├── 📂 android/                 # Android-spezifische Konfiguration
│   ├── 📂 ios/                     # iOS-spezifische Konfiguration
│   └── pubspec.yaml                # Dependencies
│
├── 📂 backend/                     # Python FastAPI Backend
│   ├── 📂 app/
│   │   ├── 📂 api/v1/              # API Endpoints
│   │   │   ├── jumps.py
│   │   │   ├── equipment.py
│   │   │   ├── profile.py
│   │   │   ├── statistics.py
│   │   │   └── weather.py
│   │   ├── 📂 models/              # SQLAlchemy Models
│   │   ├── 📂 schemas/             # Pydantic Schemas
│   │   ├── 📂 services/            # Business Logic
│   │   │   ├── weather_service.py  # Open-Meteo Integration
│   │   │   └── ...
│   │   ├── 📂 db/                  # Datenbank-Konfiguration
│   │   └── main.py                 # FastAPI App
│   ├── 📂 tests/                   # Pytest Tests
│   ├── requirements.txt            # Python Dependencies
│   └── run.py                      # Server Startskript
│
└── README.md
```

---

## 📋 Voraussetzungen

### Für die Flutter App
- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.10
- [Android Studio](https://developer.android.com/studio) (für Android)
- [Xcode](https://developer.apple.com/xcode/) (für iOS, nur macOS)
- Android Emulator oder physisches Gerät

### Für das Backend
- [Python](https://www.python.org/downloads/) >= 3.10
- pip (Python Package Manager)

---

## 🚀 Installation & Setup

### 1. Repository klonen
```bash
git clone https://github.com/yourusername/Skydive-Tracker.git
cd Skydive-Tracker
```

### 2. Backend starten
```bash
# In das Backend-Verzeichnis wechseln
cd backend

# Virtuelle Umgebung erstellen (empfohlen)
python -m venv venv
source venv/bin/activate  # Linux/macOS
# oder: venv\Scripts\activate  # Windows

# Dependencies installieren
pip install -r requirements.txt

# Server starten
python run.py
```
Der Server läuft nun auf `http://localhost:8000`

**API-Dokumentation:** `http://localhost:8000/docs` (Swagger UI)

### 3. Frontend starten

**Emulator starten:**
- **Android Studio:** Device Manager → Create Device → Start Emulator
- **Command Line:** `emulator -avd <device_name>`
- **iOS Simulator (macOS):** `open -a Simulator`

```bash
# In das Frontend-Verzeichnis wechseln
cd frontend

# Dependencies installieren
flutter pub get

# App starten (Emulator muss laufen)
flutter run
```

**Hinweis:** Für Android-Entwicklung wird Android Studio empfohlen, da es den Android Emulator sowie alle notwendigen SDKs und Build-Tools mitbringt.

### 4. API-Endpunkt konfigurieren
Die Backend-URL kann in `frontend/lib/config/api_config.dart` angepasst werden:
```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';  // Android Emulator
  // static const String baseUrl = 'http://localhost:8000';  // iOS Simulator
}
```

---

## 📱 Build & Deployment

### Android APK
```bash
cd frontend
flutter build apk --release
```
Output: `frontend/build/app/outputs/flutter-apk/app-release.apk`

### iOS (nur macOS)
```bash
cd frontend
flutter build ios --release
```

### WearOS
```bash
cd frontend
flutter build apk --release
# APK auf WearOS-Gerät installieren
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Tests ausführen

### Alle Tests auf einmal
```bash
# Vom Projekt-Root
python run_tests.py
# oder
make test
```

### Backend Tests
```bash
cd backend
pytest
# oder
make test-backend
```

### Frontend Tests
```bash
cd frontend
flutter test
# oder
make test-frontend
```

### Integration Tests
```bash
cd frontend
flutter test integration_test
# oder
make test-integration
```

**Test-Coverage**: Backend min. 80%, Frontend min. 70%

📖 **Detaillierte Test-Dokumentation**: [TESTING.md](TESTING.md)

---

## 📡 API Endpoints

| Methode | Endpoint | Beschreibung |
|---------|----------|--------------|
| `GET` | `/api/v1/jumps/` | Alle Sprünge abrufen |
| `POST` | `/api/v1/jumps/` | Neuen Sprung erstellen |
| `GET` | `/api/v1/jumps/{id}` | Einzelnen Sprung abrufen |
| `PUT` | `/api/v1/jumps/{id}` | Sprung aktualisieren |
| `DELETE` | `/api/v1/jumps/{id}` | Sprung löschen |
| `GET` | `/api/v1/statistics/` | Statistiken abrufen |
| `POST` | `/api/v1/weather/` | Wetterdaten abrufen |
| `GET` | `/api/v1/equipment/` | Ausrüstung abrufen |
| `POST` | `/api/v1/equipment/` | Ausrüstung hinzufügen |
| `GET` | `/api/v1/profile/` | Profil abrufen |
| `PUT` | `/api/v1/profile/` | Profil aktualisieren |

Vollständige Dokumentation: `http://localhost:8000/docs`

---

## 🎯 Freefall-Detektion

Die App nutzt die Beschleunigungssensoren des Geräts zur automatischen Erkennung von:

- **Exit** – Plötzliche Beschleunigungsänderung beim Verlassen des Flugzeugs
- **Freefall** – Annähernd Schwerelosigkeit während des freien Falls
- **Deployment** – Starke Verzögerung bei Schirmöffnung

### Simulationsmodus
Zum Testen ohne echten Sprung:
1. WearOS: Einstellungen → "Freefall Simulation" aktivieren
2. Mobile: `flutter run --dart-define=USE_SIMULATED_SENSORS=true`

Mehr Details: [FREEFALL_DETECTION.md](FREEFALL_DETECTION.md)

---

## 🤝 Mitwirken

Beiträge sind willkommen! So kannst du mitmachen:

1. **Fork** das Repository
2. Erstelle einen **Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. **Push** zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen **Pull Request**

---

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe [LICENSE](LICENSE) für Details.

---

## 🙏 Danksagungen

- [Open-Meteo](https://open-meteo.com/) – Kostenlose Wetter-API
- [Flutter](https://flutter.dev/) – Cross-Platform Framework
- [FastAPI](https://fastapi.tiangolo.com/) – Python Web Framework

---

<div align="center">

**Made with ❤️ for Skydivers**

</div>

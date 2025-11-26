# Skydive Tracker Mobile App

React Native App für Android und iOS zur Erfassung und Verwaltung von Fallschirmsprüngen.

## Voraussetzungen

- Node.js >= 18
- npm oder yarn
- React Native CLI
- Android Studio (für Android)
- Xcode (für iOS, nur macOS)

## Setup

1. Dependencies installieren:
```bash
npm install
# oder
yarn install
```

2. iOS Dependencies installieren (nur macOS):
```bash
cd ios && pod install && cd ..
```

3. App starten:
```bash
# Metro Bundler starten
npm start

# In einem separaten Terminal:
npm run android  # für Android
npm run ios       # für iOS
```

## Projektstruktur

```
src/
├── components/      # Wiederverwendbare UI-Komponenten
├── screens/        # Screen-Komponenten (Hauptansichten)
├── services/       # Business Logic & API Calls
│   ├── database/   # SQLite Datenbank Service
│   ├── jumps/      # Sprung-Service
│   ├── equipment/  # Ausrüstungs-Service
│   └── profile/    # Profil-Service
├── models/         # TypeScript Interfaces/Types
├── navigation/     # Navigation Setup
└── utils/          # Helper-Funktionen
```

## Tests

Tests ausführen:
```bash
npm test
```

Mit Watch-Mode:
```bash
npm run test:watch
```

Mit Coverage:
```bash
npm run test:coverage
```

## Entwicklung

- TypeScript für Type-Safety
- ESLint für Code-Qualität
- Prettier für Code-Formatierung
- Jest für Unit-Tests

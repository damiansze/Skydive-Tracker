# Skydive Tracker

Eine mobile App zur Erfassung, Verwaltung und Analyse von Fallschirmsprüngen für Android und iOS.

## Projektstruktur

Das Projekt ist in zwei Hauptkomponenten aufgeteilt:

```
Skydive-Tracker/
├── mobile/          # React Native Mobile App (Android & iOS)
├── backend/         # Python FastAPI Backend
└── README.md        # Diese Datei
```

### Mobile App (`mobile/`)

Die React Native App für Android und iOS.

**Technologie-Stack:**
- React Native 0.73
- TypeScript
- React Navigation
- SQLite (lokale Datenbank)
- Jest für Tests

**Struktur:**
```
mobile/
├── src/
│   ├── components/      # Wiederverwendbare UI-Komponenten
│   ├── screens/         # Screen-Komponenten
│   │   ├── JumpsScreen.tsx
│   │   ├── JumpDetailScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   └── StatisticsScreen.tsx
│   ├── services/        # Business Logic Layer
│   │   ├── database/    # SQLite Datenbank Service
│   │   ├── jumps/       # Sprung-Service
│   │   ├── equipment/   # Ausrüstungs-Service
│   │   └── profile/     # Profil-Service
│   ├── models/          # TypeScript Interfaces
│   │   ├── Jump.ts
│   │   ├── Equipment.ts
│   │   └── Profile.ts
│   ├── navigation/      # Navigation Setup
│   │   └── AppNavigator.tsx
│   ├── utils/           # Helper-Funktionen
│   └── App.tsx          # Root Component
├── __tests__/           # Test-Dateien
├── package.json
├── tsconfig.json
└── jest.config.js
```

### Backend (`backend/`)

Python FastAPI Backend für zukünftige Cloud-Synchronisation und erweiterte Features.

**Technologie-Stack:**
- Python 3.10+
- FastAPI
- SQLAlchemy (ORM)
- Pydantic (Schema Validation)
- SQLite (kann später auf PostgreSQL/MongoDB erweitert werden)
- Pytest für Tests

**Struktur:**
```
backend/
├── app/
│   ├── api/             # API Routes
│   │   └── v1/
│   │       ├── jumps.py
│   │       ├── equipment.py
│   │       ├── profile.py
│   │       └── statistics.py
│   ├── models/          # SQLAlchemy Models
│   │   ├── jump.py
│   │   ├── equipment.py
│   │   └── profile.py
│   ├── schemas/         # Pydantic Schemas
│   │   ├── jump.py
│   │   ├── equipment.py
│   │   └── profile.py
│   ├── services/        # Business Logic
│   │   ├── jump_service.py
│   │   ├── equipment_service.py
│   │   ├── profile_service.py
│   │   └── statistics_service.py
│   ├── db/              # Database Configuration
│   │   └── database.py
│   └── main.py          # FastAPI App
├── tests/               # Test-Dateien
│   ├── conftest.py      # Pytest Fixtures
│   ├── test_jumps.py
│   └── test_statistics.py
├── requirements.txt
└── run.py
```

## Warum diese Struktur?

### 1. **Separation of Concerns**
- **Mobile App**: Fokus auf UI/UX und lokale Datenverwaltung
- **Backend**: Bereit für zukünftige Cloud-Features, Synchronisation, Multi-User-Support

### 2. **Skalierbarkeit**
- Klare Trennung zwischen Frontend und Backend ermöglicht unabhängige Entwicklung
- Backend kann später um Authentication, Cloud-Sync, Analytics erweitert werden
- Mobile App kann zunächst offline funktionieren, später mit Backend synchronisieren

### 3. **Wartbarkeit**
- **Feature-basierte Struktur**: Jede Funktionalität (Jumps, Equipment, Profile) hat eigene Services, Models, Schemas
- **Layered Architecture**: 
  - Models: Datenstrukturen
  - Services: Business Logic
  - API/Components: Präsentationsschicht
- **Type-Safety**: TypeScript im Frontend, Pydantic im Backend für frühe Fehlererkennung

### 4. **Testbarkeit**
- Services können isoliert getestet werden
- Models und Schemas sind unabhängig testbar
- Klare Dependency Injection durch Services

### 5. **Best Practices**
- **Mobile**: React Native Best Practices (Navigation, State Management vorbereitet)
- **Backend**: FastAPI Best Practices (Dependency Injection, Schema Validation, API Versioning)
- **Datenbank**: SQLite lokal für Offline-First, später erweiterbar

### 6. **Entwicklerfreundlichkeit**
- Klare Verzeichnisstruktur macht Navigation einfach
- Konsistente Namenskonventionen
- Path Aliases für einfachere Imports (`@components`, `@services`, etc.)

## Funktionen (geplant)

### 1. Sprungerfassung
- Automatisches Datum/Zeit (manuell anpassbar)
- Ort-Eingabe
- Höhenangabe
- Checkliste basierend auf Equipment

### 2. Profil und Ausrüstung
- Persönliche Daten (Name, Lizenz)
- Equipment-Verwaltung (Schirm, Gurtzeug, etc.)
- Integration in Checkliste

### 3. Statistik und Übersicht
- Gesamtzahl Sprünge
- Filterung nach Ort
- Weitere Statistiken

## Setup

### Mobile App Setup
Siehe [mobile/README.md](mobile/README.md)

### Backend Setup
Siehe [backend/README.md](backend/README.md)

## Entwicklung

### Workflow
1. Mobile App entwickelt Features lokal mit SQLite
2. Backend kann parallel entwickelt werden
3. Später: Synchronisation zwischen Mobile App und Backend

### Testing
- Mobile: `npm test` im `mobile/` Verzeichnis
- Backend: `pytest` im `backend/` Verzeichnis

## Nächste Schritte

1. UI-Komponenten implementieren
2. Formulare für Sprungerfassung
3. Equipment-Verwaltung UI
4. Statistik-Dashboards
5. Backend-Integration (später)

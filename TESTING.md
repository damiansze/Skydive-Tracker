# 🧪 Testing Guide

Dieses Dokument beschreibt das Test-Setup für das Skydive Tracker Projekt.

## 📋 Übersicht

Das Projekt verwendet eine umfassende Test-Strategie mit Unit-Tests, Integration-Tests und End-to-End-Tests.

### Backend Tests (Python)
- **Framework**: pytest
- **Coverage**: pytest-cov (min. 80% Coverage erforderlich)
- **Test-Typen**: Unit, Integration, API-Tests

### Frontend Tests (Flutter/Dart)
- **Framework**: flutter_test + mocktail
- **Integration Tests**: integration_test
- **Coverage**: flutter test --coverage

## 🚀 Tests ausführen

### Alle Tests auf einmal
```bash
# Von der Projekt-Root aus
python run_tests.py
```

### Backend Tests
```bash
cd backend
pytest
```

### Frontend Unit Tests
```bash
cd frontend
flutter test
```

### Integration Tests
```bash
cd frontend
flutter test integration_test
```

## 📊 Test Coverage

### Backend Coverage Report
```bash
cd backend
pytest --cov=app --cov-report=html
# Öffne htmlcov/index.html im Browser
```

### Frontend Coverage
```bash
cd frontend
flutter test --coverage
# Coverage-Dateien werden in coverage/ erstellt
```

## 🏗️ Test-Struktur

### Backend Tests (`backend/tests/`)

```
tests/
├── conftest.py              # pytest fixtures
├── test_jumps.py           # Jump API tests
├── test_statistics.py      # Statistics API tests
├── test_weather.py         # Weather API tests
├── test_equipment.py       # Equipment API tests
├── test_profile.py         # Profile API tests
└── test_services.py        # Business logic tests
```

### Frontend Tests (`frontend/test/`)

```
test/
├── models/
│   └── jump_test.dart      # Model tests
├── services/
│   ├── weather_service_test.dart
│   └── freefall_detection_service_test.dart
├── widgets/
│   └── home_screen_test.dart
└── widget_test.dart        # Main widget tests
```

## 📝 Test-Beispiele

### Backend API Test
```python
def test_create_jump(client):
    jump_data = {
        "date": datetime.now(timezone.utc).isoformat(),
        "location": "Test Dropzone",
        "altitude": 14000,
        "jumpType": "SOLO"
    }
    response = client.post("/api/v1/jumps/", json=jump_data)
    assert response.status_code == 201
    assert response.json()["location"] == "Test Dropzone"
```

### Frontend Widget Test
```dart
testWidgets('Home screen shows navigation elements', (WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();

  expect(find.text('Neuer Sprung'), findsOneWidget);
  expect(find.text('Statistiken'), findsOneWidget);
});
```

### Service Mock Test
```dart
test('WeatherService returns correct data', () async {
  when(() => mockHttpClient.get(any()))
      .thenAnswer((_) async => http.Response(mockWeatherJson, 200));

  final weather = await WeatherService.getWeather(
    latitude: 46.6863,
    longitude: 7.8632,
    dateTime: DateTime.now(),
    client: mockHttpClient,
  );

  expect(weather.temperatureCelsius, 15.5);
});
```

## 🔧 Test-Konfiguration

### Backend (pytest.ini)
```ini
[tool:pytest]
testpaths = tests
addopts =
    --cov=app
    --cov-report=term-missing
    --cov-fail-under=80
    -v
```

### Frontend (pubspec.yaml)
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.3
  integration_test:
    sdk: flutter
```

## 🎯 Test-Abdeckung

### Backend Coverage Ziele
- **Models**: 100% (einfache Datenstrukturen)
- **Schemas**: 95% (Pydantic validation)
- **Services**: 90% (Business Logic)
- **API Endpoints**: 85% (HTTP Handling)

### Frontend Coverage Ziele
- **Models**: 95% (fromMap/toMap)
- **Services**: 90% (API calls, error handling)
- **Widgets**: 80% (UI interactions)
- **Integration**: 70% (E2E flows)

## 🚨 CI/CD Integration

### GitHub Actions Beispiel
```yaml
- name: Run Backend Tests
  run: |
    cd backend
    pip install -r requirements.txt
    pytest

- name: Run Frontend Tests
  run: |
    cd frontend
    flutter test --coverage
```

## 🐛 Debugging Tests

### Backend Debug
```bash
# Einzelnen Test debuggen
pytest tests/test_jumps.py::test_create_jump -v -s

# Coverage für spezifischen Test
pytest --cov=app.services.jump_service tests/test_services.py -v
```

### Frontend Debug
```bash
# Einzelnen Test debuggen
flutter test test/models/jump_test.dart -v

# Integration Test mit Device
flutter test integration_test --device-id=YOUR_DEVICE_ID
```

## 📈 Test-Metriken

### Aktuelle Coverage
- **Backend**: ~85% (Ziel: 80%+)
- **Frontend**: ~75% (Ziel: 70%+)

### Test-Typen Verteilung
- **Unit Tests**: 70%
- **Integration Tests**: 20%
- **API Tests**: 10%

## 🔄 Best Practices

### Backend
- Verwende `conftest.py` für gemeinsame Fixtures
- Mocke externe APIs (Weather, etc.)
- Teste Error Cases und Edge Cases
- Verwende descriptive Test-Namen

### Frontend
- Verwende `mocktail` für saubere Mocks
- Teste UI-States und User Interactions
- Mocke Services und HTTP Calls
- Verwende `pumpAndSettle()` für Animationen

## 📚 Weiterführende Links

- [pytest Documentation](https://docs.pytest.org/)
- [Flutter Testing](https://docs.flutter.dev/testing)
- [Mocktail](https://pub.dev/packages/mocktail)
- [pytest-cov](https://pytest-cov.readthedocs.io/)

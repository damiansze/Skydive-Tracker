# Skydive Tracker Backend

FastAPI Backend für die Fallschirmsprung-Tracking-App.

## Setup

1. Virtual Environment erstellen:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# oder
venv\Scripts\activate  # Windows
```

2. Dependencies installieren:
```bash
pip install -r requirements.txt
```

3. Environment-Variablen konfigurieren:
```bash
cp .env.example .env
# Bearbeite .env nach Bedarf
```

4. Datenbank migrieren (falls vorhanden):
```bash
python migrate_db.py
```

5. Server starten:
```bash
python run.py
# oder
uvicorn app.main:app --reload
```

Die API ist dann unter `http://localhost:8000` erreichbar.

API Dokumentation:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Environment Variablen

- `DATABASE_URL`: SQLite Datenbank-Pfad (default: sqlite:///./skydive_tracker.db)
- `LOG_LEVEL`: Logging-Level (INFO, DEBUG, WARNING, ERROR)
- `ALLOWED_ORIGINS`: Komma-separierte Liste erlaubter CORS Origins (default: *)

## Tests

Tests ausführen:
```bash
pytest
```

Mit Coverage:
```bash
pytest --cov=app --cov-report=html
```

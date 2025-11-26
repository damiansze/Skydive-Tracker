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

3. Server starten:
```bash
python run.py
# oder
uvicorn app.main:app --reload
```

Die API ist dann unter `http://localhost:8000` erreichbar.

API Dokumentation:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Tests

Tests ausführen:
```bash
pytest
```

Mit Coverage:
```bash
pytest --cov=app --cov-report=html
```

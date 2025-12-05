# Skydive Tracker - Development Commands

.PHONY: help test test-backend test-frontend test-integration lint format clean setup dev backend frontend

# Default target
help:
	@echo "Available commands:"
	@echo "  setup         - Setup development environment"
	@echo "  test          - Run all tests"
	@echo "  test-backend  - Run backend tests only"
	@echo "  test-frontend - Run frontend tests only"
	@echo "  test-integration - Run integration tests"
	@echo "  lint          - Run linting"
	@echo "  format        - Format code"
	@echo "  clean         - Clean build artifacts"
	@echo "  dev           - Start development servers"
	@echo "  backend       - Start backend server"
	@echo "  frontend      - Start frontend development"

# Setup
setup:
	@echo "Setting up development environment..."
	# Backend setup
	cd backend && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
	# Frontend setup
	cd frontend && flutter pub get

# Testing
test:
	@echo "Running all tests..."
	python run_tests.py

test-backend:
	@echo "Running backend tests..."
	cd backend && python -m pytest

test-frontend:
	@echo "Running frontend tests..."
	cd frontend && flutter test

test-integration:
	@echo "Running integration tests..."
	cd frontend && flutter test integration_test

# Code Quality
lint:
	@echo "Running linting..."
	cd backend && flake8 app tests
	cd frontend && flutter analyze

format:
	@echo "Formatting code..."
	cd backend && black app tests && isort app tests
	cd frontend && flutter format lib test

# Development
dev:
	@echo "Starting development servers..."
	@echo "Backend: http://localhost:8000"
	@echo "Backend Docs: http://localhost:8000/docs"
	@echo "Frontend: Run 'make frontend' in another terminal"
	make backend &
	make frontend

backend:
	@echo "Starting backend server..."
	cd backend && python run.py

frontend:
	@echo "Starting frontend development..."
	cd frontend && flutter run

# Cleanup
clean:
	@echo "Cleaning build artifacts..."
	cd frontend && flutter clean
	rm -rf frontend/build/
	rm -rf backend/htmlcov/
	rm -rf backend/.coverage
	rm -rf backend/__pycache__/
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} +

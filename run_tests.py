#!/usr/bin/env python3
"""
Test runner script for Skydive Tracker
Runs all backend tests and provides coverage report
"""

import subprocess
import sys
import os
from pathlib import Path

def run_backend_tests():
    """Run backend pytest tests"""
    print("🚀 Running Backend Tests...")
    print("=" * 50)

    backend_dir = Path(__file__).parent / "backend"
    os.chdir(backend_dir)

    # Run pytest with coverage
    cmd = [
        "python", "-m", "pytest",
        "-v",
        "--cov=app",
        "--cov-report=term-missing",
        "--cov-report=html:htmlcov",
        "--cov-fail-under=80"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)

    return result.returncode == 0

def run_flutter_tests():
    """Run Flutter tests"""
    print("\n📱 Running Flutter Tests...")
    print("=" * 50)

    frontend_dir = Path(__file__).parent / "frontend"
    os.chdir(frontend_dir)

    # Run Flutter tests
    cmd = ["flutter", "test", "--coverage"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)

    return result.returncode == 0

def run_integration_tests():
    """Run Flutter integration tests"""
    print("\n🔗 Running Integration Tests...")
    print("=" * 50)

    frontend_dir = Path(__file__).parent / "frontend"
    os.chdir(frontend_dir)

    # Run integration tests (requires device/emulator)
    cmd = ["flutter", "test", "integration_test"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)

    return result.returncode == 0

def main():
    """Main test runner"""
    print("🪂 Skydive Tracker - Test Suite")
    print("=" * 50)

    # Change to project root
    os.chdir(Path(__file__).parent)

    results = []

    # Run backend tests
    backend_success = run_backend_tests()
    results.append(("Backend", backend_success))

    # Run Flutter unit tests
    flutter_success = run_flutter_tests()
    results.append(("Flutter Unit", flutter_success))

    # Run integration tests (optional, might require device)
    try:
        integration_success = run_integration_tests()
        results.append(("Integration", integration_success))
    except Exception as e:
        print(f"\n⚠️  Integration tests skipped: {e}")
        results.append(("Integration", None))

    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print("=" * 50)

    all_passed = True
    for name, success in results:
        if success is None:
            status = "⏭️  SKIPPED"
        elif success:
            status = "✅ PASSED"
        else:
            status = "❌ FAILED"
            all_passed = False
        print("25")

    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All tests passed!")
        return 0
    else:
        print("💥 Some tests failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())

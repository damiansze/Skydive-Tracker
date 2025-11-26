"""Tests for statistics endpoints"""
def test_get_total_jumps(client):
    """Test getting total jumps count"""
    response = client.get("/api/v1/statistics/total-jumps")
    assert response.status_code == 200
    assert "total_jumps" in response.json()

def test_get_statistics_summary(client):
    """Test getting statistics summary"""
    response = client.get("/api/v1/statistics/summary")
    assert response.status_code == 200
    assert "total_jumps" in response.json()
    assert "average_altitude" in response.json()

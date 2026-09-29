from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_home():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "running"
    assert data["message"] == "CI/CD Pipeline Automation"

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_application_info():
    response = client.get("/api/v1/info")
    assert response.status_code == 200
    data = response.json()
    assert data["application"] == "FastAPI"
    assert data["environment"] == "DevOps"
    assert data["version"] == "1.0.0"

def test_not_found():
    response = client.get("/non-existent-endpoint")
    assert response.status_code == 404

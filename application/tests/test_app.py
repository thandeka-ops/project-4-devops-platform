
import sys
from pathlib import Path

# Add the application directory to Python's import path
sys.path.insert(
    0,
    str(Path(__file__).resolve().parents[1])
)

from app import app


def test_home():
    client = app.test_client()
    response = client.get("/")

    assert response.status_code == 200
    assert response.json["application"] == "Project 4 DevOps Platform"


def test_health():
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json["status"] == "healthy"


def test_version():
    client = app.test_client()
    response = client.get("/version")

    assert response.status_code == 200
    assert "version" in response.json


def test_metrics():
    client = app.test_client()
    response = client.get("/metrics")

    assert response.status_code == 200
    assert b"http_requests_total" in response.data

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    assert client.get("/").status_code == 200

def test_dashboard():
    data = client.get("/api/dashboard").json()
    assert "groups" in data

def test_create_group():
    r = client.post("/api/groups", json={"name":"DSA Masters","topic":"DSA"})
    assert r.status_code == 200
    assert r.json()["name"] == "DSA Masters"

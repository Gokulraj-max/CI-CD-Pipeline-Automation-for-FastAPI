from fastapi import FastAPI

app = FastAPI(
    title="CI/CD Automation API",
    description="A lightweight REST API serving as the deployment target for Jenkins CI/CD automation pipeline.",
    version="1.0.0"
)

@app.get("/")
def home():
    return {
        "message": "CI/CD Pipeline Automation",
        "status": "running"
    }

@app.get("/health")
def health():
    return {
        "status": "healthy"
    }

@app.get("/api/v1/info")
def application_info():
    return {
        "application": "FastAPI",
        "environment": "DevOps",
        "version": "1.0.0"
    }

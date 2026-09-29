# CI/CD Pipeline Automation for Python FastAPI Application

[![CI/CD Pipeline](https://img.shields.io/badge/Jenkins-Pipeline-blue?logo=jenkins)](Jenkinsfile)
[![FastAPI](https://img.shields.io/badge/FastAPI-1.0.0-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)](Dockerfile)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://python.org)
[![Pytest](https://img.shields.io/badge/Pytest-Automated_Tests-0A9EDC?logo=pytest)](tests/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An end-to-end, automated software delivery pipeline built with **Jenkins**, **GitHub**, **Docker**, **Python**, and **Pytest**. Whenever code changes are pushed to GitHub, Jenkins automatically retrieves the source code, prepares an isolated virtual environment, installs dependencies, executes unit and API tests, builds a versioned Docker image, and deploys the application to the target environment with continuous health validation.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [Functional Requirements Traceability](#functional-requirements-traceability)
5. [Repository Structure](#repository-structure)
6. [Application Specification & Endpoints](#application-specification--endpoints)
7. [Local Development & Testing](#local-development--testing)
8. [Docker Containerization](#docker-containerization)
9. [Jenkins Installation & Configuration](#jenkins-installation--configuration)
10. [Jenkins CI/CD Pipeline Stages](#jenkins-cicd-pipeline-stages)
11. [GitHub Webhook Integration](#github-webhook-integration)
12. [Operational Bash Scripts](#operational-bash-scripts)
13. [Deployment Validation & Failure Test Plan](#deployment-validation--failure-test-plan)
14. [Security & Reliability Considerations](#security--reliability-considerations)
15. [Resume Description](#resume-description)

---

## 1. Project Overview

### Problem Statement
In traditional software development, developers often perform code integration, dependency installation, testing, application packaging, and deployment manually. This manual process introduces:
- **Human errors** and inconsistencies during deployment.
- **Environment drift** between local machines and servers.
- **Delayed releases** and slow feedback loops.
- **Difficulties identifying failures** when untested or breaking code reaches production.

### Objectives
This project automates each step of the delivery lifecycle:
- **Automated Integration**: Retrieve source code immediately upon push.
- **Automated Testing**: Execute unit and API tests using Pytest; halt pipeline on failure.
- **Reproducible Packaging**: Package the application into an immutable Docker image tagged by build number.
- **Continuous Deployment**: Deploy the container to a target Linux server on the `main` branch.
- **Health Validation**: Automatically poll HTTP endpoints to ensure application readiness before finishing deployment.
- **Failure Handling**: Prevent broken deployments from silently replacing a healthy release.

---

## 2. System Architecture

```mermaid
flowchart TD
    subgraph Developer_Station ["Developer"]
        Dev["Developer"] -->|Commit & Push| GH["GitHub Repository"]
    end

    subgraph GitHub_Cloud ["GitHub"]
        GH -->|Webhook Event (push)| JK["Jenkins Server"]
    end

    subgraph Jenkins_Pipeline ["Jenkins Pipeline"]
        JK --> S1["1. Checkout Source"]
        S1 --> S2["2. Install Dependencies (venv)"]
        S2 --> S3["3. Run Pytest"]
        S3 -->|Pass| S4["4. Build Docker Image"]
        S3 -->|Fail| FailNotify["Halt Pipeline & Report Failure"]
        S4 --> S5["5. Deploy Container (main branch)"]
        S5 --> S6["6. Health Check (15 retries)"]
        S6 -->|Healthy| SuccessDone["Deployment Complete (Port 8001)"]
        S6 -->|Unhealthy| FailDeploy["Halt & Preserve Stable State"]
    end

    subgraph Target_Host ["Target Environment (Ubuntu / Docker)"]
        SuccessDone -.-> RunningApp["FastAPI Container (ci-cd-api)"]
    end
```

---

## 3. Technology Stack

| Technology | Role |
| :--- | :--- |
| **Python + FastAPI** | High-performance asynchronous REST API serving application endpoints. |
| **Pytest + HTTPX** | Automated unit and integration testing suite. |
| **Docker** | Container runtime packaging code and dependencies into portable images. |
| **Jenkins** | Automation server orchestrating the end-to-end CI/CD pipeline. |
| **Git + GitHub** | Version control, branch management, and webhook event triggers. |
| **Ubuntu Linux + Bash** | Host operating system and operational automation scripts. |

---

## 4. Functional Requirements Traceability

| ID | Requirement | Description | Status |
| :--- | :--- | :--- | :---: |
| **FR-01** | GitHub integration | Jenkins accesses the repository via Git SCM integration. | Verified |
| **FR-02** | Automated trigger | Code push to GitHub automatically triggers the Jenkins pipeline. | Verified |
| **FR-03** | Dependency installation | Python packages installed in an isolated virtual environment. | Verified |
| **FR-04** | Automated testing | Pytest executes all unit and API tests; failed tests halt build. | Verified |
| **FR-05** | Docker build | Container image is created after successful tests. | Verified |
| **FR-06** | Image tagging | Images tagged with Jenkins `${BUILD_NUMBER}` and `latest`. | Verified |
| **FR-07** | Deployment | Container deployed to target environment upon merge to `main`. | Verified |
| **FR-08** | Health validation | Automated polling ensures `/health` returns HTTP 200. | Verified |
| **FR-09** | Logging | Jenkins console and container logs record deployment history. | Verified |
| **FR-10** | Failure handling | Broken builds do not replace a healthy release. | Verified |

---

## 5. Repository Structure

```text
ci-cd-pipeline-automation/
│
├── app/
│   ├── __init__.py
│   └── main.py
│
├── tests/
│   ├── __init__.py
│   └── test_main.py
│
├── scripts/
│   ├── deploy.sh
│   ├── health_check.sh
│   └── cleanup.sh
│
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── Dockerfile
├── .dockerignore
├── .gitignore
├── requirements.txt
├── Jenkinsfile
├── README.md
└── LICENSE
```

---

## 6. Application Specification & Endpoints

The API is built using **FastAPI** (`app/main.py`):

| Method | Endpoint | Description | Expected Response |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Home status endpoint | `{"message": "CI/CD Pipeline Automation", "status": "running"}` |
| `GET` | `/health` | Health check probe | `{"status": "healthy"}` |
| `GET` | `/api/v1/info`| Application metadata | `{"application": "FastAPI", "environment": "DevOps", "version": "1.0.0"}` |

---

## 7. Local Development & Testing

### 1. Set Up Virtual Environment
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
```

### 2. Run Tests
```bash
pytest -v
```
Expected output:
```text
tests/test_main.py::test_home PASSED
tests/test_main.py::test_health PASSED
tests/test_main.py::test_application_info PASSED
tests/test_main.py::test_not_found PASSED
```

### 3. Run Application Locally
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Verify endpoint:
```bash
curl http://localhost:8000/health
```

---

## 8. Docker Containerization

The container is built from `Dockerfile` using `python:3.12-slim`:

### Build and Run Container
```bash
# Build image
docker build -t ci-cd-api:local .

# Run container
docker run -d \
  --name ci-cd-api \
  -p 8001:8000 \
  ci-cd-api:local

# Validate endpoint
curl http://localhost:8001/health
```

---

## 9. Jenkins Installation & Configuration

### Step 1: Ubuntu Linux Setup
```bash
# Install core packages, Python, and Docker
sudo apt update
sudo apt install -y git curl wget ca-certificates python3 python3-pip python3-venv docker.io

# Install Java runtime (required for Jenkins)
sudo apt install -y openjdk-17-jre

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

# Enable and start services
sudo systemctl enable --now docker
sudo systemctl enable --now jenkins

# Grant Jenkins access to Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Retrieve initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Open Jenkins at `http://localhost:8080`.

### Step 2: Install Jenkins Plugins
From **Manage Jenkins** → **Plugins**, ensure the following plugins are installed:
- Pipeline
- Git
- GitHub Integration
- Credentials Binding
- Timestamps

---

## 10. Jenkins CI/CD Pipeline Stages

The declarative pipeline is defined in `Jenkinsfile`:

1. **Checkout**: Retrieves source code from Git repository via SCM.
2. **Install Dependencies**: Creates `.venv` and installs packages from `requirements.txt`.
3. **Automated Tests**: Runs `pytest -v`. Halts build if any test fails.
4. **Build Docker Image**: Builds Docker image tagged with `${BUILD_NUMBER}` and `latest`.
5. **Deploy**: Triggered on `main` branch; removes old container and starts new container on port `8001`.
6. **Health Check**: Executes a 15-attempt loop polling `http://localhost:8001/health`.

---

## 11. GitHub Webhook Integration

### Webhook Configuration
1. In Jenkins:
   - Create a Pipeline job pointing to `https://github.com/Gokulraj-max/CI-CD-Pipeline-Automation-for-FastAPI.git`.
   - Enable **GitHub hook trigger for GITScm polling**.
   - Set Script Path to `Jenkinsfile`.
2. In GitHub:
   - Navigate to **Settings** → **Webhooks** → **Add webhook**.
   - **Payload URL**: `http://<jenkins-host>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Trigger**: `Just the push event`.

---

## 12. Operational Bash Scripts

The `scripts/` directory provides essential automation:

- **`scripts/deploy.sh`**:
  Deploys the container image, verifies health, and includes rollback logic:
  ```bash
  chmod +x scripts/deploy.sh
  ./scripts/deploy.sh ci-cd-api latest ci-cd-api 8001
  ```

- **`scripts/health_check.sh`**:
  Polls the application health endpoint:
  ```bash
  chmod +x scripts/health_check.sh
  ./scripts/health_check.sh http://localhost:8001/health
  ```

- **`scripts/cleanup.sh`**:
  Prunes stopped containers and dangling images:
  ```bash
  chmod +x scripts/cleanup.sh
  ./scripts/cleanup.sh
  ```

---

## 13. Deployment Validation & Failure Test Plan

| # | Test Scenario | Action | Expected Result |
| :---: | :--- | :--- | :--- |
| **1** | **Successful pipeline** | Push valid commit to `main`. | All pipeline stages pass; container is deployed. |
| **2** | **Unit test failure** | Introduce failing test in `test_main.py`. | Pipeline halts at Automated Tests stage; image is not built. |
| **3** | **Docker build failure** | Add invalid Dockerfile instruction. | Build fails at Docker Image stage; deployment is aborted. |
| **4** | **Application health failure** | Configure health endpoint to fail. | Health check stage retries 15 times and exits with code 1. |
| **5** | **Webhook trigger** | Push commit to GitHub. | Jenkins receives webhook and starts pipeline automatically. |
| **6** | **Deployment restart** | Run `docker restart ci-cd-api`. | Container restarts and `/health` recovers. |
| **7** | **Log inspection** | Review Jenkins console & `docker logs`. | Execution history and application logs are recorded. |

---

## 14. Security & Reliability Considerations

- **Credentials Management**: Store GitHub tokens and secrets in Jenkins Credentials store, never hardcoded in scripts.
- **Image Versioning**: Every build is tagged with a unique `${BUILD_NUMBER}` alongside `latest`.
- **Health Verification**: Deployments are validated via HTTP health probes before marking the build as successful.
- **Container Cleanup**: `scripts/cleanup.sh` prevents disk exhaustion by pruning unused container resources.

---

## 15. Resume Description

```text
CI/CD Pipeline Automation for FastAPI | Jenkins, GitHub, Docker, Python, Pytest, Linux, Bash
• Developed a Jenkins CI/CD pipeline integrated with GitHub to automate source code checkout, dependency installation, automated testing and Docker image creation.
• Automated application deployment to a Linux environment using Docker and Bash scripts, with health checks to validate deployment status.
• Implemented pipeline failure handling, application validation and container management to improve deployment consistency and reliability.
```

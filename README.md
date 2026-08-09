# devops-intern-final

[![CI](https://github.com/tobakayanaha/devops-intern-final/actions/workflows/ci.yml/badge.svg)](https://github.com/tobakayanaha/devops-intern-final/actions/workflows/ci.yml)

## DevOps internship final assessment demonstrating Git, Linux, Docker, CI/CD, Nomad, and Grafana Loki.

## Author
Bahlakoana Fako

## Date 
9 August 2026


## 1. Git and Github Setup
The project respository was created on Github and cloned locally for development. 
A sample Python script was added to demonstrated a basic Git and Github workflow.

## Files
- README.md
- hello.py

## Run the Python Script
python3 hello.py

Expected output:

Hello, DevOps!

## 2 Linux and Scripting Basics
A shell script was created inside the scripts/ directory to display basic system information.

### Script

scripts/sysinfo.sh

The script uses the following Linux commands:
- whoami - displays the current user.
- date - dislays the current date and time.
- df -h - displays disk usage in a human readable format. 

### Make the script executable
chmod -x scripts/sysinfo.sh

### Run the script
From the project root:
./scripts/sysinfo.sh

### Expected output
The script displays:

Current user:
<current user>

Current date: 
<current date> 

Disk usage: 
<disk usage infomation>

### Test Evidence 

The script was tested locally and in WSL and executed successfully.

## 3 Docker Basics
The 'hello.py' Python application was containerized using Docker

### Dockerfile
The Dockerfile used Python 3.12 Slim as the base image, copies 'hello.py' into the container and runs the application when the container starts.

### Build the Docker image
From the project root:

```bash
docker build -t devopshello .
```

### Run Container
 
 ```bash
 docker run devopshello
```
### Expected output

Hello. Devops!

### Test Evidence

The Docker image was successfully build and the container was tested locally.

## 4 CI/CD with Github Actions
GitHub Actions was used to create a Continuous Integration (CI) pipeline for the project.

The workflow automatically runs python hello.py whenever changes are pushed to the GitHub repository.

### Workflow 
The CI workflow is located at:

.github/workflows/ci.yml

The workflow performs the following steps:

1. Checks out the repository.
2. Sets up Python 3.12.
3. Runs python hello.py.
4. Reports whether the workflow succeeded or failed.

### Trigger the CI Pipeline

The workflow runs automatically when changes are pushed:

```bash
git add .
git commit -m "Update project"
git push
```
### CI Status Badge
The CI passing badge indicates that the latest workflow run completed successfully.

### CI Test Evidence

The workflow successfully ran python hello.py using GitHub Actions.











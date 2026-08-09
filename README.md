# devops-intern-final

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






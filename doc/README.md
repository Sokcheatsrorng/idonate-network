# Project Automation Scripts

This project includes a set of bash scripts to automate common tasks like installing binaries, managing the Hyperledger Fabric network, and starting or stopping the monitoring dashboard. 🚀

## Usage

Each script accepts options to perform specific actions.
Use the instructions below to get started.

```bash

Using Justfile To Deploy Network:
1. just network create  ---> create new organization
2. just network destroy ---> down the docker container related to organization
 
Using Justfile to Set Up Prometheus-grafana Dashboard to Monitor Network
1. just dashboard start
2. just dashboard stop 

```


---

### Binary Management
Manage project binaries.

```bash
bash binary-option.sh <option>


bash ``

docker system prune -a
docker volume prune
docker network prune

docker-compose down
# docker-compose up --build

``
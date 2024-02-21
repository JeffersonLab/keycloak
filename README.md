# keycloak [![Docker](https://img.shields.io/docker/v/jeffersonlab/keycloak?sort=semver&label=DockerHub)](https://hub.docker.com/r/jeffersonlab/keycloak)
Configurable [Keycloak](https://www.keycloak.org/) Docker image

---
 - [Overview](https://github.com/JeffersonLab/keycloak#overview)
 - [Quick Start with Compose](https://github.com/JeffersonLab/keycloak#quick-start-with-compose) 
 - [Configure](https://github.com/JeffersonLab/keycloak#configure)
 - [Release](https://github.com/JeffersonLab/keycloak#release)
---

## Overview
This project provides a docker image which extends the production-oriented [keycloak](https://quay.io/repository/keycloak/keycloak) and adds features for development and testing.   The Jefferson Lab image sets up a Docker healthcheck and Docker entrypoint, installs client tools (see [lib.sh](https://github.com/JeffersonLab/keycloak/blob/main/scripts/lib.sh)), and adds some default configuration for the Jefferson Lab environment.  The entrypoint integrates with the healthcheck such that the container is "healthy" only when keycloak is both running and configured.  Configuration is supported via environment variables and a conventional directory named `/docker-entrypoint-initdb.d` of bash scripts that can be overwritten by mounting a volume.

## Quick Start with Compose
1. Grab project
```
git clone https://github.com/JeffersonLab/keycloak
cd keycloak
```
2. Launch [Compose](https://github.com/docker/compose)
```
docker compose up
```
3. Navigate to admin console
```
http://localhost:8080
```
*Note*: Login with username `admin` and password `admin` 

## Configure
Mount a volume at `/container-entrypoint-initdb.d` containing bash scripts to run, ordered by name ascending.  See [example](https://github.com/JeffersonLab/keycloak/tree/main/container/keycloak/initdb.d).

Environment variables:
| Name | Description |
|------|-------------|
| KEYCLOAK_FRONTEND_HOSTNAME | Front end hostname |
| KEYCLOAK_FRONTEND_PORT | Front end port |
| KEYCLOAK_SERVER_URL | Backend URL |
| KEYCLOAK_ADMIN | Admin username |
| KEYCLOAK_ADMIN_PASSWORD | Admin password |

## Release
1. Create a new release on the GitHub Releases page.  The release should enumerate changes and link issues.
1. [Publish to DockerHub](https://github.com/JeffersonLab/keycloak/actions/workflows/docker-publish.yml) GitHub Action should run automatically. 
1. Bump and commit quick start [image version](https://github.com/JeffersonLab/keycloak/blob/main/compose.override.yaml).

# keycloak [![Docker](https://img.shields.io/docker/v/jeffersonlab/keycloak?sort=semver&label=DockerHub)](https://hub.docker.com/r/jeffersonlab/keycloak)
Configurable [Keycloak](https://www.keycloak.org/) Docker image and bash setup scripts.

---
 - [Overview](https://github.com/JeffersonLab/keycloak#overview)
 - [Quick Start with Compose](https://github.com/JeffersonLab/keycloak#quick-start-with-compose) 
 - [Configure](https://github.com/JeffersonLab/keycloak#configure)
 - [Release](https://github.com/JeffersonLab/keycloak#release)
---

## Overview
This project provides a docker image which extends the production-oriented [keycloak](https://quay.io/repository/keycloak/keycloak) and adds features for development and testing.   The Jefferson Lab image sets up a Docker healthcheck and Docker entrypoint, installs client tools (see [lib.sh](https://github.com/JeffersonLab/keycloak/blob/main/scripts/lib.sh)), and adds some default configuration for the Jefferson Lab environment.  The entrypoint integrates with the healthcheck such that the container is "healthy" only when keycloak is both running and configured.  Configuration is supported via environment variables and a conventional directory named `/container-entrypoint-initdb.d` of bash scripts that can be overwritten by mounting a volume.

- 1.x version based on Keycloak 20.x
- 2.x version based on Keycloak 26.x

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
http://localhost:8081/auth
```
*Note*: Login with username `admin` and password `admin` 

## Configure
Mount a volume at `/container-entrypoint-initdb.d` containing bash scripts to run, ordered by name ascending.  See [example](https://github.com/JeffersonLab/keycloak/tree/main/container/keycloak/initdb.d).

Environment variables:
| Name | Description |
|------|-------------|
| KC_FRONTEND_URL | Front end scheme, hostname, port, and relative path |
| KC_BACKEND_URL | Back end scheme, hostname, port, and relative path |
| KC_HTTP_RELATIVE_PATH | Relative path, probably must match KC_FRONTEND_URL and KC_BACKEND_URL |
| KC_BOOTSTRAP_ADMIN_USERNAME | Admin username |
| KC_BOOTSTRAP_ADMIN_PASSWORD | Admin password |

## Release
1. Bump the version number in the VERSION file and commit and push to GitHub (using [Semantic Versioning](https://semver.org/)).
2. The [CD](https://github.com/JeffersonLab/keycloak/blob/main/.github/workflows/cd.yaml) GitHub Action should run automatically invoking:
    - The [Create release](https://github.com/JeffersonLab/container-workflows/blob/main/.github/workflows/gh-release.yaml) GitHub Action to tag the source and create release notes summarizing any pull requests.   Edit the release notes to add any missing details.
    - The [Publish docker image](https://github.com/JeffersonLab/container-workflows/blob/main/.github/workflows/docker-publish.yaml) GitHub Action to create a new demo Docker image.

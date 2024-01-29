#!/bin/bash

. /lib.sh

echo "----------------"
echo "| Create Realm |"
echo "----------------"
# KEYCLOAK_REALM set in 00_config.env as it's a shared value
KEYCLOAK_SECRET=yHi6W2raPmLvPXoxqMA7VWbLAA2WN0eB
KEYCLOAK_REALM_DISPLAY_NAME="TEST REALM"
KEYCLOAK_SESSION_IDLE_TIMEOUT=30
KEYCLOAK_SESSION_MAX_LIFESPAN=30
create_realm






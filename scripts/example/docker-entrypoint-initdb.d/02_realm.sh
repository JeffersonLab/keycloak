#!/bin/bash

echo "----------------"
echo "| Create Realm |"
echo "----------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create realms -s id=${KEYCLOAK_REALM} -s realm="${KEYCLOAK_REALM}" -s enabled=true -s displayName="${KEYCLOAK_REALM_DISPLAY_NAME}" -s loginWithEmailAllowed=false






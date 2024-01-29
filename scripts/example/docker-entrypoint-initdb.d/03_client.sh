#!/bin/bash

echo "-----------------"
echo "| Create Client |"
echo "-----------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create clients -r "${KEYCLOAK_REALM}" -s clientId=${KEYCLOAK_RESOURCE} -s 'redirectUris=["https://localhost:8443/'${KEYCLOAK_RESOURCE}'/*"]' -s secret=${KEYCLOAK_SECRET} -s 'serviceAccountsEnabled=true'
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_RESOURCE} --cclientid realm-management --rolename view-users
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_RESOURCE} --cclientid realm-management --rolename view-authorization
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_RESOURCE} --cclientid realm-management --rolename view-realm
#!/bin/bash

echo "----------------"
echo "| Create Roles |"
echo "----------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create roles -r "${KEYCLOAK_REALM}" -s name=${KEYCLOAK_RESOURCE}-user
${KEYCLOAK_HOME}/bin/kcadm.sh create roles -r "${KEYCLOAK_REALM}" -s name=${KEYCLOAK_RESOURCE}-admin

echo "----------------"
echo "| Create Users |"
echo "----------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create users -r "${KEYCLOAK_REALM}" -s username=jadams -s firstName=Jane -s lastName=Adams -s email=jadams@example.com -s enabled=true
${KEYCLOAK_HOME}/bin/kcadm.sh set-password -r "${KEYCLOAK_REALM}" --username jadams --new-password password
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername jadams --rolename ${KEYCLOAK_RESOURCE}-user

${KEYCLOAK_HOME}/bin/kcadm.sh create users -r "${KEYCLOAK_REALM}" -s username=jsmith -s firstName=John -s lastName=Smith -s email=jsmith@example.com -s enabled=true
${KEYCLOAK_HOME}/bin/kcadm.sh set-password -r "${KEYCLOAK_REALM}" --username jsmith --new-password password
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername jsmith --rolename ${KEYCLOAK_RESOURCE}-user

${KEYCLOAK_HOME}/bin/kcadm.sh create users -r "${KEYCLOAK_REALM}" -s username=tbrown -s firstName=Tom -s lastName=Brown -s email=tbrown@example.com -s enabled=true
${KEYCLOAK_HOME}/bin/kcadm.sh set-password -r "${KEYCLOAK_REALM}" --username tbrown --new-password password
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername tbrown --rolename ${KEYCLOAK_RESOURCE}-user
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername tbrown --rolename ${KEYCLOAK_RESOURCE}-admin
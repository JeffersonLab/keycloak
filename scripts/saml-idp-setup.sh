#!/bin/bash

FUNCTIONS=(login
           create_idp)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_ALIAS
           KEYCLOAK_REALM
           KEYCLOAK_SERVER_URL
           KEYCLOAK_IMPORT_FROM
           KEYCLOAK_DISPLAY_NAME
           KEYCLOAK_FIRST_LOGIN_FLOW
           KEYCLOAK_PRINCIPAL_TYPE)

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 [var file] <optional function>"
    echo "The var file arg should be the path to a file with bash variables that will be sourced."
    echo "The optional function name arg if provided is the sole function to call, else all functions are invoked sequentially."
    printf 'Variables: '
    printf '%s ' "${VARIABLES[@]}"
    printf '\n'
    printf 'Functions: '
    printf '%s ' "${FUNCTIONS[@]}"
    printf '\n'
    exit 0
fi

if [ ! -z "$1" ] && [ -f "$1" ]
then
echo "Loading environment $1"
. $1
fi

if [ ! -z "$COMMON_ENV_FILE" ] && [ -f "$COMMON_ENV_FILE" ]
then
echo "Loading common env: $COMMON_ENV_FILE"
. $COMMON_ENV_FILE
else
echo "No common env"
fi

# Verify expected env set:
for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done


login() {
#${KEYCLOAK_HOME}/bin/kcadm.sh config credentials --server "${KEYCLOAK_SERVER_URL}" --realm master --user "${KEYCLOAK_ADMIN}" --password "${KEYCLOAK_ADMIN_PASSWORD}"
TOKEN_URL="${KEYCLOAK_SERVER_URL}/realms/master/protocol/openid-connect/token"
AUTH="Authorization: bearer $(curl -s -d client_id=admin-cli -d username=${KEYCLOAK_ADMIN} -d password=${KEYCLOAK_ADMIN_PASSWORD} -d grant_type=password ${TOKEN_URL} | jq -r '.access_token')"
}

create_idp() {
CONVERTER_URL="${KEYCLOAK_SERVER_URL}/admin/realms/${KEYCLOAK_REALM}/identity-provider/import-config"
JSON=$(curl -s -X POST -H "${AUTH}"  -H 'content-type: application/json' ${CONVERTER_URL} -d '{"fromUrl":"'${KEYCLOAK_IMPORT_FROM}'","providerId":"saml"}')
#JSON=$(echo $JSON | jq '. += {"principalType": "'${KEYCLOAK_PRINCIPAL_TYPE}'", "principalAttribute": "'${KEYCLOAK_PRINCIPAL_ATTRIBUTE}'"}')
${KEYCLOAK_HOME}/bin/kcadm.sh create identity-provider/instances -r ${KEYCLOAK_REALM} -s alias=${KEYCLOAK_ALIAS} \
-s providerId=saml \
-s enabled=true \
-s displayName="${KEYCLOAK_DISPLAY_NAME}" \
-s firstBrokerLoginFlowAlias=${KEYCLOAK_FIRST_LOGIN_FLOW} \
-s config=${JSON}

# Seems like you must update data after import; didn't like adding more config to import
${KEYCLOAK_HOME}/bin/kcadm.sh update identity-provider/instances/${KEYCLOAK_ALIAS} -r ${KEYCLOAK_REALM} \
-s config.principalAttribute="${KEYCLOAK_PRINCIPAL_ATTRIBUTE}" \
-s config.principalType="${KEYCLOAK_PRINCIPAL_TYPE}"
}

if [ ! -z "$2" ]
then
  echo "------------------------"
  echo "$2"
  echo "------------------------"
  $2
else
for i in "${!FUNCTIONS[@]}"; do
  echo "------------------------"
  echo "${FUNCTIONS[$i]}"
  echo "------------------------"
  ${FUNCTIONS[$i]};
done
fi
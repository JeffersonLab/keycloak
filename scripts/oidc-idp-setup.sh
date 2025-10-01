#!/bin/bash

FUNCTIONS=(login
           create_idp)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_ALIAS
           KEYCLOAK_REALM
           KEYCLOAK_SERVER_URL
           KEYCLOAK_CLIENT_NAME
           KEYCLOAK_DISPLAY_NAME
           KEYCLOAK_AUTH_URL
           KEYCLOAK_TOKEN_URL
           KEYCLOAK_LOGOUT_URL
           KEYCLOAK_ISSUER_URL
           KEYCLOAK_JWKS_URL
           KEYCLOAK_SECRET)

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
${KEYCLOAK_HOME}/bin/kcadm.sh config credentials --server "${KEYCLOAK_SERVER_URL}" --realm master --user "${KEYCLOAK_ADMIN}" --password "${KEYCLOAK_ADMIN_PASSWORD}"
}

create_idp() {
${KEYCLOAK_HOME}/bin/kcadm.sh create identity-provider/instances -r ${KEYCLOAK_REALM} -s alias=${KEYCLOAK_ALIAS} \
-s providerId=keycloak-oidc \
-s enabled=true \
-s displayName=${KEYCLOAK_DISPLAY_NAME} \
-s firstBrokerLoginFlowAlias=${KEYCLOAK_FIRST_LOGIN_FLOW} \
-s config.clientId=${KEYCLOAK_CLIENT_NAME} \
-s config.disableUserInfo=true \
-s config.validateSignature=true \
-s config.useJwksUrl=true \
-s config.authorizationUrl=${KEYCLOAK_AUTH_URL} \
-s config.tokenUrl=${KEYCLOAK_TOKEN_URL} \
-s config.logoutUrl=${KEYCLOAK_LOGOUT_URL} \
-s config.issuer=${KEYCLOAK_ISSUER_URL} \
-s config.jwksUrl=${KEYCLOAK_JWKS_URL} \
-s config.backchannelSupported=true \
-s config.clientSecret=${KEYCLOAK_SECRET}
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
#!/bin/bash

FUNCTIONS=(login
           create_autolink_flow)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_ALIAS
           KEYCLOAK_REALM
           KEYCLOAK_SERVER_URL)

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

create_autolink_flow() {
${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/flows -r ${KEYCLOAK_REALM} -s alias=${KEYCLOAK_ALIAS} \
-s providerId=basic-flow \
-s id=${KEYCLOAK_REALM}-autolink-flow \
-s topLevel=true \
-s builtIn=false \
-s description="Automatically link brokered IdP on first login"

EXECUTION_ID=$(${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/flows/${KEYCLOAK_ALIAS}/executions/execution -r ${KEYCLOAK_REALM} -s provider=idp-create-user-if-unique -i)
${KEYCLOAK_HOME}/bin/kcadm.sh update authentication/flows/${KEYCLOAK_ALIAS}/executions -r ${KEYCLOAK_REALM} -b '{"id":"'${EXECUTION_ID}'","requirement":"ALTERNATIVE"}'

EXECUTION_ID=$(${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/flows/${KEYCLOAK_ALIAS}/executions/execution -r ${KEYCLOAK_REALM} -s provider=idp-auto-link -i)
${KEYCLOAK_HOME}/bin/kcadm.sh update authentication/flows/${KEYCLOAK_ALIAS}/executions -r ${KEYCLOAK_REALM} -b '{"id":"'${EXECUTION_ID}'","requirement":"ALTERNATIVE"}'
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
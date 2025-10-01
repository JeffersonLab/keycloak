#!/bin/bash

FUNCTIONS=(login
           create_flow
           order_execution
           add_execution
           delete_kerberos
           set_as_realm_default)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_ALIAS
           KEYCLOAK_REALM
           KEYCLOAK_SERVER_URL
           KEYCLOAK_WHITELIST_PATTERN)

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

create_flow() {
${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/flows/browser/copy -r ${KEYCLOAK_REALM} \
-s newName=${KEYCLOAK_ALIAS}
}

order_execution() {
EXECUTION_ID=$(${KEYCLOAK_HOME}/bin/kcadm.sh get -r ${KEYCLOAK_REALM} authentication/flows/${KEYCLOAK_ALIAS}/executions | jq -r ".[] | select(.displayName == \"Identity Provider Redirector\") | .id")
${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/executions/${EXECUTION_ID}/raise-priority -r ${KEYCLOAK_REALM}
}

add_execution() {
EXECUTION_ID=$(${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/flows/${KEYCLOAK_ALIAS}/executions/execution -r ${KEYCLOAK_REALM} -s provider=conditional-auth-spnego -i)
${KEYCLOAK_HOME}/bin/kcadm.sh update authentication/flows/${KEYCLOAK_ALIAS}/executions -r ${KEYCLOAK_REALM} -b '{"id":"'${EXECUTION_ID}'","requirement":"ALTERNATIVE"}'
${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/executions/${EXECUTION_ID}/raise-priority -r ${KEYCLOAK_REALM}
${KEYCLOAK_HOME}/bin/kcadm.sh create authentication/executions/${EXECUTION_ID}/config -r ${KEYCLOAK_REALM} -b "{\"config\":{\"XForwardedForWhitelistPattern\":\"${KEYCLOAK_WHITELIST_PATTERN}\"},\"alias\":\"conditional_spnego_config\"}"
}

delete_kerberos() {
EXECUTION_ID=$(${KEYCLOAK_HOME}/bin/kcadm.sh get -r ${KEYCLOAK_REALM} authentication/flows/${KEYCLOAK_ALIAS}/executions | jq -r ".[] | select(.displayName == \"Kerberos\") | .id")
${KEYCLOAK_HOME}/bin/kcadm.sh delete authentication/executions/${EXECUTION_ID} -r ${KEYCLOAK_REALM}
}

set_as_realm_default() {
${KEYCLOAK_HOME}/bin/kcadm.sh update realms/${KEYCLOAK_REALM} -b '{"browserFlow":"'${KEYCLOAK_ALIAS}'"}'
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
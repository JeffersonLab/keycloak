#!/bin/bash

# Get directory THIS script is in
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Source library of functions, assuming file is in same directory
. ${SCRIPT_DIR}/lib.sh

FUNCTIONS=(login
           create_roles_mapper)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_REALM_DISPLAY_NAME
           KEYCLOAK_SESSION_IDLE_TIMEOUT
           KEYCLOAK_SESSION_MAX_LIFESPAN
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

if [ -n "$1" ] && [ -f "$1" ]
then
echo "Loading environment $1"
. "$1"
fi

if [ -n "$COMMON_ENV_FILE" ] && [ -f "$COMMON_ENV_FILE" ]
then
echo "Loading common env: $COMMON_ENV_FILE"
. "$COMMON_ENV_FILE"
else
echo "No common env"
fi

# Verify expected env set:
for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

# Invoke library functions
if [ -n "$2" ]
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
  "${FUNCTIONS[$i]}";
done
fi

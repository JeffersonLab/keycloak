#!/bin/bash

FUNCTIONS=(login
           create_kerberos_storage_provider)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_SERVER_URL
           KEYCLOAK_SERVER_PRINCIPLE
           KEYCLOAK_DEBUG
           KEYCLOAK_KEYTAB
           KEYCLOAK_KERBEROS_REALM)

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

create_kerberos_storage_provider() {
${KEYCLOAK_HOME}/bin/kcadm.sh create components -r ${KEYCLOAK_REALM} -s parentId=${KEYCLOAK_REALM} \
-s id=${KEYCLOAK_REALM}-kerberos-provider -s name=${KEYCLOAK_REALM}-kerberos-provider \
-s providerId=kerberos -s providerType=org.keycloak.storage.UserStorageProvider \
-s config.debug=${KEYCLOAK_DEBUG} \
-s config.cachePolicy='["NO_CACHE"]' \
-s config.priority='["0"]' \
-s config.editMode='["READ_ONLY"]' \
-s config.serverPrincipal=${KEYCLOAK_SERVER_PRINCIPLE} \
-s config.keyTab=${KEYCLOAK_KEYTAB} \
-s config.kerberosRealm=${KEYCLOAK_KERBEROS_REALM} \
-s 'config.allowPasswordAuthentication=["true"]'
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
#!/bin/bash

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

create_roles_mapper() {
  # Update the realm-based roles scope so that a user's group IDs are put into the access token as a claim that all clients get.  This allows clients like
  # apache httpd to perform group-based authorization using the claim info in the access token.  This change affects all clients.  A similar approach can be used
  # on a per-client basis if needed (clients -> <client_name> -> scopes -> <app-dedicated scope> -> Add Realm Role -> Include in Access/ID token.
  # API described here -
  # https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmclient_templatesclient_scope_idprotocol_mappersmodelsid

  # Find the ID associated with the roles realm scope.
  scope_id=$(${KEYCLOAK_HOME}/bin/kcadm.sh get client-scopes -r "${KEYCLOAK_REALM}" --fields id,name \
    | jq -r '.[] | select(.name=="roles") | .id')

  # Find the ID for the roles realm scope mapper.  The mapper is a keycloak specific concept for customizing what scope info appears where.
  mapper_id=$(${KEYCLOAK_HOME}/bin/kcadm.sh get "client-scopes/${scope_id}/protocol-mappers/models" -r "${KEYCLOAK_REALM}" \
    | jq -r '.[] | select(.name=="realm roles") | .id')

  # keycloak wants the entire config object sent back, not just piecemeal updates.  Get the whole config and update the needed fields.
  new_config=$(${KEYCLOAK_HOME}/bin/kcadm.sh get "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" -r "${KEYCLOAK_REALM}" \
    | jq '.config["id.token.claim"]="true" | .config["access.token.claim"]="true" | .config["userinfo.token.claim"]="true"')

  # apply the new config.  Use bash-specific process substitution feature for convenience.
  ${KEYCLOAK_HOME}/bin/kcadm.sh update "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" -r "${KEYCLOAK_REALM}" -f <(echo "${new_config}")
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

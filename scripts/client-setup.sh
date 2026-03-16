#!/bin/bash

FUNCTIONS=(login
           create_client)

VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_CLIENT_NAME
           KEYCLOAK_REDIRECT_URIS
           KEYCLOAK_SERVER_URL
           KEYCLOAK_SERVICE_ACCOUNT_ENABLED)
	   
OPTIONAL_VARS=(KEYCLOAK_PROVIDES_CLIENT_ROLES
               KEYCLOAK_ASSIGNED_REALM_ROLES
               KEYCLOAK_ASSIGNED_CLIENT_ROLES)

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
${KEYCLOAK_HOME}/bin/kcadm.sh config credentials \
    --server "${KEYCLOAK_SERVER_URL}" \
    --realm master \
    --user "${KEYCLOAK_ADMIN}" \
    --password "${KEYCLOAK_ADMIN_PASSWORD}"
}

create_client() {
${KEYCLOAK_HOME}/bin/kcadm.sh create clients -r "${KEYCLOAK_REALM}" \
    -s clientId=${KEYCLOAK_CLIENT_NAME} \
    -s id=${KEYCLOAK_CLIENT_NAME} \
    -s enabled=true \
    -s serviceAccountsEnabled=${KEYCLOAK_SERVICE_ACCOUNT_ENABLED} \
    -s redirectUris=${KEYCLOAK_REDIRECT_URIS} \
    -s secret=${KEYCLOAK_SECRET}

if [ ${KEYCLOAK_SERVICE_ACCOUNT_ENABLED} = 'true' ] ; then
  ${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" \
      --uusername service-account-${KEYCLOAK_CLIENT_NAME} \
      --cclientid realm-management \
      --rolename view-users
  ${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" \
      --uusername service-account-${KEYCLOAK_CLIENT_NAME} \
      --cclientid realm-management \
      --rolename view-authorization
  ${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" \
      --uusername service-account-${KEYCLOAK_CLIENT_NAME} \
      --cclientid realm-management \
      --rolename view-realm
fi

# Client can provide a set of roles.  Since they exist with only the client
# no need to check for their existence.
if [ -n "${KEYCLOAK_PROVIDES_CLIENT_ROLES}" ] ; then
  for role in ${KEYCLOAK_PROVIDES_CLIENT_ROLES} ; do
    ${KEYCLOAK_HOME}/bin/kcadm.sh create clients/${KEYCLOAK_CLIENT_NAME}/roles \
	    -r ${KEYCLOAK_REALM} \
	    -s name=${role} 
  done
fi

# This client's service account can be assigned to roles provided by another 
# client.  Handle that here.
if [ -n "${KEYCLOAK_ASSIGNED_CLIENT_ROLES}" ] ; then
  for role in ${KEYCLOAK_ASSIGNED_CLIENT_ROLES} ; do
    # Expected in {client_id}/{role_name} format, e.g. wfbrowser/wfb_data
    clientid=`echo $role | awk -F'/' '{print $1}'`
    rolename=`echo $role | awk -F'/' '{print $2}'`
    ${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r ${KEYCLOAK_REALM} \
        --uusername service-account-${KEYCLOAK_CLIENT_NAME} \
	--cclientid ${clientid} \
	--rolename ${rolename}
  done
fi

# This creates (if needed) and assigns roles to the service account for the given client.
if [ -n "${KEYCLOAK_ASSIGNED_REALM_ROLES}" ] ; then
  for rolename in ${KEYCLOAK_ASSIGNED_REALM_ROLES} ; do
    ${KEYCLOAK_HOME}/bin/kcadm.sh get-roles -r ${KEYCLOAK_REALM} --rolename ${rolename}
    exit_code=$?
    if [ "${exit_code}" -ne 0 ] ; then
      ${KEYCLOAK_HOME}/bin/kcadm.sh create roles -r ${KEYCLOAK_REALM} \
          -s name=${rolename} \
	  -s description=""
    fi
    ${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r ${KEYCLOAK_REALM} \
        --rolename ${rolename} \
        --uusername service-account-${KEYCLOAK_CLIENT_NAME}
  done
fi
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

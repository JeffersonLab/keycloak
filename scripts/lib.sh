#!/bin/bash

bootstrap_login() {
VARIABLES=(KC_BOOTSTRAP_ADMIN_USERNAME
           KC_BOOTSTRAP_ADMIN_PASSWORD
           KC_HOME
           KC_BACKEND_URL)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh config credentials \
                             --server "${KC_BACKEND_URL}" \
                             --realm master \
                             --user "${KC_BOOTSTRAP_ADMIN_USERNAME}" \
                             --password "${KC_BOOTSTRAP_ADMIN_PASSWORD}"
}

login() {
VARIABLES=(KC_ADMIN_USERNAME
           KC_ADMIN_PASSWORD
           KC_HOME
           KC_BACKEND_URL)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh config credentials \
                             --server "${KC_BACKEND_URL}" \
                             --realm master \
                             --user "${KC_ADMIN_USERNAME}" \
                             --password "${KC_ADMIN_PASSWORD}"
}

create_realm() {
VARIABLES=(KC_HOME
           KC_REALM
           KC_REALM_DISPLAY_NAME
           KC_SESSION_IDLE_TIMEOUT
           KC_SESSION_MAX_LIFESPAN)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create realms \
                              -s id="${KC_REALM}" \
                              -s realm="${KC_REALM}" \
                              -s enabled=true \
                              -s displayName="${KC_REALM_DISPLAY_NAME}" \
                              -s ssoSessionIdleTimeout="${KC_SESSION_IDLE_TIMEOUT}" \
                              -s ssoSessionMaxLifespan="${KC_SESSION_MAX_LIFESPAN}" \
                              -s loginWithEmailAllowed=false
}

create_client() {
VARIABLES=(KC_CLIENT_NAME
           KC_HOME
           KC_REALM
           KC_REDIRECT_URIS
           KC_SECRET
           KC_SERVICE_ACCOUNT_ENABLED)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create clients \
                              -r "${KC_REALM}" \
                              -s clientId="${KC_CLIENT_NAME}" \
                              -s id="${KC_CLIENT_NAME}" \
                              -s enabled=true \
                              -s serviceAccountsEnabled=${KC_SERVICE_ACCOUNT_ENABLED} \
                              -s redirectUris=${KC_REDIRECT_URIS} \
                              -s secret="${KC_SECRET}"

if [ ${KC_SERVICE_ACCOUNT_ENABLED} = 'true' ] ; then
${KC_HOME}/bin/kcadm.sh add-roles -r "${KC_REALM}" --uusername service-account-${KC_CLIENT_NAME} --cclientid realm-management --rolename view-users
${KC_HOME}/bin/kcadm.sh add-roles -r "${KC_REALM}" --uusername service-account-${KC_CLIENT_NAME} --cclientid realm-management --rolename view-authorization
${KC_HOME}/bin/kcadm.sh add-roles -r "${KC_REALM}" --uusername service-account-${KC_CLIENT_NAME} --cclientid realm-management --rolename view-realm
fi
}

create_role() {
VARIABLES=(KC_HOME
           KC_REALM
           KC_ROLE_NAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create roles \
                              -r "${KC_REALM}" \
                              -s name="${KC_ROLE_NAME}"
}

create_user() {
VARIABLES=(KC_HOME
           KC_EMAIL
           KC_FIRSTNAME
           KC_LASTNAME
           KC_REALM
           KC_USERNAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create users \
                              -r "${KC_REALM}" \
                              -s username="${KC_USERNAME}" \
                              -s firstName="${KC_FIRSTNAME}" \
                              -s lastName="${KC_LASTNAME}" \
                              -s email="${KC_EMAIL}" \
                              -s enabled=true

${KC_HOME}/bin/kcadm.sh set-password \
                              -r "${KC_REALM}" \
                               --username "${KC_USERNAME}" \
                               --new-password "${KC_PASSWORD}"
}

assign_role() {
VARIABLES=(KC_HOME
           KC_REALM
           KC_ROLE_NAME
           KC_USERNAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh add-roles \
                              -r "${KC_REALM}" \
                              --uusername "${KC_USERNAME}" \
                              --rolename "${KC_ROLE_NAME}"
}

create_ldap_storage_provider() {
VARIABLES=(KC_BIND_CREDENTIAL
           KC_BIND_DN
           KC_DEBUG
           KC_HOME
           KC_IMPORT
           KC_KERBEROS_REALM
           KC_KEYTAB
           KC_LDAP_CONNECTION_URL
           KC_RDN
           KC_REALM
           KC_SERVER_PRINCIPLE
           KC_SPNEGO
           KC_USERNAME_ATTR
           KC_USER_OBJ_CLASSES
           KC_USERS_DN
           KC_UUID
           KC_VENDOR)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create components \
-r "${KC_REALM}" \
-s parentId="${KC_REALM}" \
-s id=${KC_REALM}-ldap-provider \
-s name=${KC_REALM}-ldap-provider \
-s providerId=ldap \
-s providerType=org.keycloak.storage.UserStorageProvider \
-s config.debug=${KC_DEBUG} \
-s config.authType='["simple"]' \
-s config.vendor=${KC_VENDOR} \
-s config.priority='["0"]' \
-s config.connectionUrl=${KC_LDAP_CONNECTION_URL} \
-s config.editMode='["READ_ONLY"]' \
-s config.usersDn="${KC_USERS_DN}" \
-s config.serverPrincipal="${KC_SERVER_PRINCIPLE}" \
-s config.bindDn="${KC_BIND_DN}" \
-s config.bindCredential="${KC_BIND_CREDENTIAL}" \
-s 'config.fullSyncPeriod=["86400"]' \
-s 'config.changedSyncPeriod=["-1"]' \
-s 'config.cachePolicy=["NO_CACHE"]' \
-s config.evictionDay=[] \
-s config.evictionHour=[] \
-s config.evictionMinute=[] \
-s config.maxLifespan=[] \
-s config.importEnabled=${KC_IMPORT} \
-s 'config.batchSizeForSync=["1000"]' \
-s config.syncRegistrations='["false"]' \
-s config.usernameLDAPAttribute=${KC_USERNAME_ATTR} \
-s config.rdnLDAPAttribute=${KC_RDN} \
-s config.uuidLDAPAttribute=${KC_UUID} \
-s config.userObjectClasses="${KC_USER_OBJ_CLASSES}" \
-s 'config.searchScope=["1"]' \
-s 'config.useTruststoreSpi=["ldapsOnly"]' \
-s 'config.connectionPooling=["true"]' \
-s 'config.pagination=["true"]' \
-s config.allowKerberosAuthentication=${KC_SPNEGO} \
-s config.keyTab=${KC_KEYTAB} \
-s config.kerberosRealm=${KC_KERBEROS_REALM} \
-s config.useKerberosForPasswordAuthentication=${KC_KERBEROS_FOR_PASS}
}

set_first_name_mapper_attribute() {
VARIABLES=(KC_HOME
           KC_REALM
           KC_FIRSTNAME_ATTR)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

MAPPER_ID=`${KC_HOME}/bin/kcadm.sh get components -r ${KC_REALM} -q name='first name' --fields id | jq -r .[0].id`

${KC_HOME}/bin/kcadm.sh update components/${MAPPER_ID} \
                              -r "${KC_REALM}" \
                              -s 'config."ldap.attribute"'="${KC_FIRSTNAME_ATTR}"
}

create_ldap_role_mapper() {
VARIABLES=(KC_HOME
           KC_REALM
           KC_ROLES_DN)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create components \
-r ${KC_REALM} \
-s parentId=${KC_REALM}-ldap-provider \
-s id=${KC_REALM}-ldap-role-mapper \
-s name=${KC_REALM}-ldap-role-mapper \
-s providerId=role-ldap-mapper \
-s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper \
-s 'config."roles.dn"'=${KC_ROLES_DN} \
-s 'config."role.name.ldap.attribute"=["cn"]' \
-s 'config."role.object.classes"=["groupOfNames"]' \
-s 'config."membership.ldap.attribute"=["member"]' \
-s 'config."membership.attribute.type"=["DN"]' \
-s 'config."membership.user.ldap.attribute"=["uid"]' \
-s 'config.mode=["READ_ONLY"]' \
-s 'config."user.roles.retrieve.strategy"=["GET_ROLES_FROM_USER_MEMBEROF_ATTRIBUTE"]' \
-s 'config."memberof.ldap.attribute"=["memberOf"]' \
-s 'config."use.realm.roles.mapping"=["true"]'
}

run_user_storage_sync() {
VARIABLES=(KC_HOME
           KC_PROVIDER
           KC_REALM)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create \
                              -r ${KC_REALM} \
                              user-storage/${KC_PROVIDER}/sync?action=triggerFullSync
}

create_idp() {
VARIABLES=(KC_ALIAS
           KC_AUTH_URL
           KC_CLIENT_NAME
           KC_DISPLAY_NAME
           KC_FIRST_LOGIN_FLOW
           KC_HOME
           KC_ISSUER_URL
           KC_JWKS_URL
           KC_LOGOUT_URL
           KC_REALM
           KC_SECRET
           KC_TOKEN_URL)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KC_HOME}/bin/kcadm.sh create identity-provider/instances -r ${KC_REALM} -s alias=${KC_ALIAS} \
-s providerId=keycloak-oidc \
-s enabled=true \
-s displayName=${KC_DISPLAY_NAME} \
-s firstBrokerLoginFlowAlias=${KC_FIRST_LOGIN_FLOW} \
-s config.clientId=${KC_CLIENT_NAME} \
-s config.disableUserInfo=true \
-s config.validateSignature=true \
-s config.useJwksUrl=true \
-s config.authorizationUrl=${KC_AUTH_URL} \
-s config.tokenUrl=${KC_TOKEN_URL} \
-s config.logoutUrl=${KC_LOGOUT_URL} \
-s config.issuer=${KC_ISSUER_URL} \
-s config.jwksUrl=${KC_JWKS_URL} \
-s config.backchannelSupported=true \
-s config.clientSecret=${KC_SECRET}
}

create_autolink_flow() {
  VARIABLES=(KC_ALIAS
             KC_HOME
             KC_REALM)

  for i in "${!VARIABLES[@]}"; do
    var=${VARIABLES[$i]}
    [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
  done

${KC_HOME}/bin/kcadm.sh create authentication/flows -r ${KC_REALM} -s alias=${KC_ALIAS} \
-s providerId=basic-flow \
-s id=${KC_REALM}-autolink-flow \
-s topLevel=true \
-s builtIn=false \
-s description="Automatically link brokered IdP on first login"

EXECUTION_ID=$(${KC_HOME}/bin/kcadm.sh create authentication/flows/${KC_ALIAS}/executions/execution -r ${KC_REALM} -s provider=idp-create-user-if-unique -i)
${KC_HOME}/bin/kcadm.sh update authentication/flows/${KC_ALIAS}/executions -r ${KC_REALM} -b '{"id":"'${EXECUTION_ID}'","requirement":"ALTERNATIVE"}'

EXECUTION_ID=$(${KC_HOME}/bin/kcadm.sh create authentication/flows/${KC_ALIAS}/executions/execution -r ${KC_REALM} -s provider=idp-auto-link -i)
${KC_HOME}/bin/kcadm.sh update authentication/flows/${KC_ALIAS}/executions -r ${KC_REALM} -b '{"id":"'${EXECUTION_ID}'","requirement":"ALTERNATIVE"}'

}

update_realm_roles_scope() {
  # Update the realm-based roles scope so that a user's group IDs are put into the access token as a claim that all
  # clients get.  This allows clients like apache httpd to perform group-based authorization using the claim info in the
  # access token.  This change affects all clients.  A similar approach can be used on a per-client basis if needed
  # (clients -> <client_name> -> scopes -> <app-dedicated scope> -> Add Realm Role -> Include in Access/ID token.
  # API described here -
  # https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmclient_templatesclient_scope_idprotocol_mappersmodelsid

VARIABLES=(KC_HOME
           KC_REALM)

  for i in "${!VARIABLES[@]}"; do
    var=${VARIABLES[$i]}
    [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
  done

  # Find the ID associated with the roles realm scope.
  scope_id=$("${KC_HOME}"/bin/kcadm.sh \
    get client-scopes -r "${KC_REALM}" --fields id,name \
    | jq -r '.[] | select(.name=="roles") | .id')

  # Find the ID for the roles realm scope mapper.  The mapper is a keycloak specific concept for customizing what scope
  # info appears where.
  mapper_id=$("${KC_HOME}"/bin/kcadm.sh \
    get "client-scopes/${scope_id}/protocol-mappers/models" \
    -r "${KC_REALM}" \
    | jq -r '.[] | select(.name=="realm roles") | .id')

  # keycloak wants the entire config object sent back, not just piecemeal updates.  Must get the whole config and update
  # the needed fields.
  jq_str='.config["id.token.claim"]="true"'
  jq_str+=' | .config["access.token.claim"]="true"'
  jq_str+=' | .config["userinfo.token.claim"]="true"'
  new_config=$("${KC_HOME}"/bin/kcadm.sh \
    get "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" -r "${KC_REALM}" \
    | jq "$jq_str")

  # apply the new config.  Use bash-specific process substitution feature for convenience.
  "${KC_HOME}"/bin/kcadm.sh \
    update "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" -r "${KC_REALM}" \
    -f <(echo "${new_config}")
}

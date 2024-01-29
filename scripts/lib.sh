#!/bin/bash

login() {
VARIABLES=(KEYCLOAK_ADMIN
           KEYCLOAK_ADMIN_PASSWORD
           KEYCLOAK_HOME
           KEYCLOAK_SERVER_URL)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh config credentials \
                             --server "${KEYCLOAK_SERVER_URL}" \
                             --realm master \
                             --user "${KEYCLOAK_ADMIN}" \
                             --password "${KEYCLOAK_ADMIN_PASSWORD}"
}

create_realm() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_REALM_DISPLAY_NAME
           KEYCLOAK_SESSION_IDLE_TIMEOUT
           KEYCLOAK_SESSION_MAX_LIFESPAN)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create realms \
                              -s id="${KEYCLOAK_REALM}" \
                              -s realm="${KEYCLOAK_REALM}" \
                              -s enabled=true \
                              -s displayName="${KEYCLOAK_REALM_DISPLAY_NAME}" \
                              -s ssoSessionIdleTimeout="${KEYCLOAK_SESSION_IDLE_TIMEOUT}" \
                              -s ssoSessionMaxLifespan="${KEYCLOAK_SESSION_MAX_LIFESPAN}" \
                              -s loginWithEmailAllowed=false
}

create_client() {
VARIABLES=(KEYCLOAK_CLIENT_NAME
           KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_REDIRECT_URIS
           KEYCLOAK_SECRET
           KEYCLOAK_SERVICE_ACCOUNT_ENABLED)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create clients \
                              -r "${KEYCLOAK_REALM}" \
                              -s clientId="${KEYCLOAK_CLIENT_NAME}" \
                              -s id="${KEYCLOAK_CLIENT_NAME}" \
                              -s enabled=true \
                              -s serviceAccountsEnabled=${KEYCLOAK_SERVICE_ACCOUNT_ENABLED} \
                              -s redirectUris=${KEYCLOAK_REDIRECT_URIS} \
                              -s secret="${KEYCLOAK_SECRET}"

if [ ${KEYCLOAK_SERVICE_ACCOUNT_ENABLED} = 'true' ] ; then
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_CLIENT_NAME} --cclientid realm-management --rolename view-users
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_CLIENT_NAME} --cclientid realm-management --rolename view-authorization
${KEYCLOAK_HOME}/bin/kcadm.sh add-roles -r "${KEYCLOAK_REALM}" --uusername service-account-${KEYCLOAK_CLIENT_NAME} --cclientid realm-management --rolename view-realm
fi
}

create_role() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_ROLE_NAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create roles \
                              -r "${KEYCLOAK_REALM}" \
                              -s name="${KEYCLOAK_ROLE_NAME}"
}

create_user() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_EMAIL
           KEYCLOAK_FIRSTNAME
           KEYCLOAK_LASTNAME
           KEYCLOAK_REALM
           KEYCLOAK_USERNAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create users \
                              -r "${KEYCLOAK_REALM}" \
                              -s username="${KEYCLOAK_USERNAME}" \
                              -s firstName="${KEYCLOAK_FIRSTNAME}" \
                              -s lastName="${KEYCLOAK_LASTNAME}" \
                              -s email="${KEYCLOAK_EMAIL}" \
                              -s enabled=true

${KEYCLOAK_HOME}/bin/kcadm.sh set-password \
                              -r "${KEYCLOAK_REALM}" \
                               --username "${KEYCLOAK_USERNAME}" \
                               --new-password "${KEYCLOAK_PASSWORD}"
}

assign_role() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_ROLE_NAME
           KEYCLOAK_USERNAME)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh add-roles \
                              -r "${KEYCLOAK_REALM}" \
                              --uusername "${KEYCLOAK_USERNAME}" \
                              --rolename "${KEYCLOAK_ROLE_NAME}"
}

create_ldap_storage_provider() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create components \
-r "${KEYCLOAK_REALM}" \
-s parentId="${KEYCLOAK_REALM}" \
-s id=${KEYCLOAK_REALM}-ldap-provider \
-s name=${KEYCLOAK_REALM}-ldap-provider \
-s providerId=ldap \
-s providerType=org.keycloak.storage.UserStorageProvider \
-s config.debug=${KEYCLOAK_DEBUG} \
-s config.authType='["simple"]' \
-s config.vendor=${KEYCLOAK_VENDOR} \
-s config.priority='["0"]' \
-s config.connectionUrl=${KEYCLOAK_LDAP_CONNECTION_URL} \
-s config.editMode='["READ_ONLY"]' \
-s config.usersDn=${KEYCLOAK_USERS_DN} \
-s config.serverPrincipal=${KEYCLOAK_SERVER_PRINCIPLE} \
-s config.bindDn=${KEYCLOAK_BIND_DN} \
-s config.bindCredential=${KEYCLOAK_BIND_CREDENTIAL} \
-s 'config.fullSyncPeriod=["86400"]' \
-s 'config.changedSyncPeriod=["-1"]' \
-s 'config.cachePolicy=["NO_CACHE"]' \
-s config.evictionDay=[] \
-s config.evictionHour=[] \
-s config.evictionMinute=[] \
-s config.maxLifespan=[] \
-s config.importEnabled=${KEYCLOAK_IMPORT} \
-s 'config.batchSizeForSync=["1000"]' \
-s config.syncRegistrations='["false"]' \
-s config.usernameLDAPAttribute=${KEYCLOAK_USERNAME_ATTR} \
-s config.rdnLDAPAttribute=${KEYCLOAK_RDN} \
-s config.uuidLDAPAttribute=${KEYCLOAK_UUID} \
-s config.userObjectClasses=${KEYCLOAK_OBJ_CLASSES} \
-s 'config.searchScope=["1"]' \
-s 'config.useTruststoreSpi=["ldapsOnly"]' \
-s 'config.connectionPooling=["true"]' \
-s 'config.pagination=["true"]' \
-s config.allowKerberosAuthentication=${KEYCLOAK_SPNEGO} \
-s config.keyTab=${KEYCLOAK_KEYTAB} \
-s config.kerberosRealm=${KEYCLOAK_KERBEROS_REALM} \
-s 'config.useKerberosForPasswordAuthentication=["true"]'
}

set_first_name_mapper_attribute() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM
           KEYCLOAK_FIRSTNAME_ATTR)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

MAPPER_ID=`${KEYCLOAK_HOME}/bin/kcadm.sh get components -r ${KEYCLOAK_REALM} -q name='first name' --fields id | jq -r .[0].id`

${KEYCLOAK_HOME}/bin/kcadm.sh update components/${MAPPER_ID} \
                              -r "${KEYCLOAK_REALM}" \
                              -s config.ldap.attribute=${KEYCLOAK_FIRSTNAME_ATTR}
}

create_role_mapper() {
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_REALM)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create components \
-r ${KEYCLOAK_REALM} \
-s parentId=${KEYCLOAK_REALM}-ldap-provider \
-s id=${KEYCLOAK_REALM}-ldap-role-mapper \
-s name=${KEYCLOAK_REALM}-ldap-role-mapper \
-s providerId=role-ldap-mapper \
-s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper \
-s 'config."roles.dn"'=${KEYCLOAK_ROLES_DN} \
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
VARIABLES=(KEYCLOAK_HOME
           KEYCLOAK_PROVIDER
           KEYCLOAK_REALM)

for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

${KEYCLOAK_HOME}/bin/kcadm.sh create \
                              -r ${KEYCLOAK_REALM} \
                              user-storage/${KEYCLOAK_PROVIDER}/sync?action=triggerFullSync
}
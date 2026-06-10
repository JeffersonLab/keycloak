#!/bin/bash

# Located in root of container
. /kc-lib.sh

echo "----------------------------"
echo "| Update Realm Roles Scope |"
echo "----------------------------"
update_realm_roles_scope

echo "------------------------------"
echo "| LDAP User Storage Provider |"
echo "------------------------------"
KC_DEBUG='["true"]'
KC_LDAP_CONNECTION_URL='["ldap://dirsrv:3389"]'
KC_USERS_DN='["cn=users,cn=accounts,dc=example,dc=com"]'
KC_BIND_DN='["cn=Directory Manager"]'
KC_BIND_CREDENTIAL='["password"]'
KC_USER_OBJ_CLASSES='["person","organizationalPerson","inetorgperson"]'
KC_KERBEROS_AUTHN='["false"]'
KC_KERBEROS_FOR_PASS='["false"]'
KC_KEYTAB='["/etc/test-realm.keytab"]'
KC_VENDOR='["rhds"]'
KC_IMPORT='["false"]'
KC_SPNEGO='["false"]'
KC_SERVER_PRINCIPLE='["HTTP/test.example.com@EXAMPLE.COM"]'
KC_USERNAME_ATTR='["uid"]'
KC_RDN='["uid"]'
KC_UUID='["uid"]'
KC_KERBEROS_REALM='["EXAMPLE.COM"]'
KC_PROVIDER="${KC_REALM}-ldap-provider"
KC_ROLES_DN='["cn=groups,cn=accounts,dc=example,dc=com"]'
create_ldap_storage_provider

# See: https://github.com/keycloak/keycloak/issues/15623
KC_FIRSTNAME_ATTR='["givenName"]'
set_first_name_mapper_attribute

run_user_storage_sync

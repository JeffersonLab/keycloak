#!/bin/bash

. /lib.sh

echo "------------------------------"
echo "| LDAP User Storage Provider |"
echo "------------------------------"
KEYCLOAK_DEBUG='["true"]'
KEYCLOAK_LDAP_CONNECTION_URL='["ldap://dirsrv:3389"]'
KEYCLOAK_USERS_DN='["cn=users,cn=accounts,dc=example,dc=com"]'
KEYCLOAK_BIND_DN='["cn=Directory Manager"]'
KEYCLOAK_BIND_CREDENTIAL='["password"]'
KEYCLOAK_USER_OBJ_CLASSES='["person","organizationalPerson","inetorgperson"]'
KEYCLOAK_KERBEROS_AUTHN='["false"]'
KEYCLOAK_KERBEROS_FOR_PASS='["false"]'
KEYCLOAK_KEYTAB='["/etc/test-realm.keytab"]'
KEYCLOAK_VENDOR='["rhds"]'
KEYCLOAK_IMPORT='["false"]'
KEYCLOAK_SPNEGO='["false"]'
KEYCLOAK_SERVER_PRINCIPLE='["HTTP/test.example.com@EXAMPLE.COM"]'
KEYCLOAK_USERNAME_ATTR='["uid"]'
KEYCLOAK_RDN='["uid"]'
KEYCLOAK_UUID='["uid"]'
KEYCLOAK_KERBEROS_REALM='["EXAMPLE.COM"]'
KEYCLOAK_PROVIDER="${KEYCLOAK_REALM}-ldap-provider"
KEYCLOAK_FIRSTNAME_ATTR='["given_name"]'
KEYCLOAK_ROLES_DN='["cn=groups,cn=accounts,dc=example,dc=com"]'
create_ldap_storage_provider
set_first_name_mapper_attribute
run_user_storage_sync

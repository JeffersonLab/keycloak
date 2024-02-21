#!/bin/bash

. /lib.sh

echo "----------------"
echo "| Create Roles |"
echo "----------------"
KEYCLOAK_ROLE_NAME=${KEYCLOAK_RESOURCE}-user
create_role
KEYCLOAK_ROLE_NAME=${KEYCLOAK_RESOURCE}-admin
create_role

echo "----------------"
echo "| Create Users |"
echo "----------------"
KEYCLOAK_USERNAME=jadams
KEYCLOAK_FIRSTNAME=Jane
KEYCLOAK_LASTNAME=Adams
KEYCLOAK_EMAIL=jadams@example.com
KEYCLOAK_PASSWORD=password
KEYCLOAK_ROLE_NAME=${KEYCLOAK_RESOURCE}-user
create_user
assign_role

KEYCLOAK_USERNAME=jsmith
KEYCLOAK_FIRSTNAME=John
KEYCLOAK_LASTNAME=Smith
KEYCLOAK_EMAIL=jsmith@example.com
create_user
assign_role

KEYCLOAK_USERNAME=tbrown
KEYCLOAK_FIRSTNAME=Tom
KEYCLOAK_LASTNAME=Brown
KEYCLOAK_EMAIL=tbrown@example.com
create_user
assign_role
KEYCLOAK_ROLE_NAME=${KEYCLOAK_RESOURCE}-admin
assign_role

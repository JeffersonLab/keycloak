#!/bin/bash

# This is an example overriding 02_accounts.sh.

# Located in root of container
. /kc-lib.sh

echo "----------------"
echo "| Create Roles |"
echo "----------------"
KC_ROLE_NAME=${KC_RESOURCE}-user
create_role
KC_ROLE_NAME=${KC_RESOURCE}-admin
create_role

echo "----------------"
echo "| Create Users |"
echo "----------------"
KC_USERNAME=jadams
KC_FIRSTNAME=Jane
KC_LASTNAME=Adams
KC_EMAIL=jadams@example.com
KC_PASSWORD=password
KC_ROLE_NAME=${KC_RESOURCE}-user
create_user
assign_role

KC_USERNAME=jsmith
KC_FIRSTNAME=John
KC_LASTNAME=Smith
KC_EMAIL=jsmith@example.com
create_user
assign_role

KC_USERNAME=tbrown
KC_FIRSTNAME=Tom
KC_LASTNAME=Brown
KC_EMAIL=tbrown@example.com
create_user
assign_role
KC_ROLE_NAME=${KC_RESOURCE}-admin
assign_role

KC_USERNAME=jdoe
KC_FIRSTNAME=John
KC_LASTNAME=Doe
KC_EMAIL=jdoe@example.com
create_user
KC_ROLE_NAME=${KC_RESOURCE}-user
assign_role
KC_ROLE_NAME=${KC_RESOURCE}-admin
assign_role

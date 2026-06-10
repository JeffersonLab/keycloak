#!/bin/bash

# Located in root of container
. /kc-lib.sh

echo "---------"
echo "| Login |"
echo "---------"
bootstrap_login

echo "----------------"
echo "| Create Realm |"
echo "----------------"
create_realm

echo "-----------------"
echo "| Create Client |"
echo "-----------------"
create_client


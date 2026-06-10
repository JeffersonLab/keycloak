#!/bin/bash

. /lib.sh

echo "---------"
echo "| Login |"
echo "---------"
login

echo "----------------"
echo "| Create Realm |"
echo "----------------"
create_realm

echo "-----------------"
echo "| Create Client |"
echo "-----------------"
create_client


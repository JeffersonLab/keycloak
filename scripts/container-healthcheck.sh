#!/bin/bash

test -f ${KEYCLOAK_HOME}/setup-complete && curl ${KEYCLOAK_SERVER_URL} -sf -o /dev/null
#!/bin/bash

test -f ${KC_HOME}/setup-complete && curl ${KC_BACKEND_URL} -sf -o /dev/null
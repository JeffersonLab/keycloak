#!/bin/bash

# Same marker location as container-entrypoint.sh
if [[ -z "${KC_DB}" || "${KC_DB}" == "dev-file" ]]; then
    SETUP_MARKER="${KC_HOME}/data/setup-complete"
else
    SETUP_MARKER="${KC_HOME}/setup-complete"
fi

test -f "${SETUP_MARKER}" && curl ${KC_BACKEND_URL} -sf -o /dev/null

#!/bin/bash
#
#   setup-roles-in-access-tokens.sh ENV_FILE [FUNCTION]
#
# Sources ENV_FILE, then COMMON_ENV_FILE if it is set, and runs the kc-lib.sh function FUNCTION or,
# if none is named, these, stopping at the first that fails:
#   login update_realm_roles_scope
# kc-lib.sh -e ENV_FILE login ... does the same; kc-lib.sh --help lists the functions.

# shellcheck source-path=SCRIPTDIR source=kc-lib.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/kc-lib.sh"

_wrapper_main 'login update_realm_roles_scope' "$@"

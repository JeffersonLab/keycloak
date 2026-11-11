#!/bin/bash
#
#   ldap-setup.sh ENV_FILE [FUNCTION]
#
# Sources ENV_FILE, then COMMON_ENV_FILE if it is set, and runs the kc-lib.sh function FUNCTION or,
# if none is named, these, stopping at the first that fails:
#   login create_ldap_storage_provider set_first_name_mapper_attribute create_ldap_role_mapper run_user_storage_sync
# kc-lib.sh -e ENV_FILE login ... does the same; kc-lib.sh --help lists the functions.

# Defaults, which ENV_FILE can override
export KC_FIRSTNAME_ATTR='["givenName"]'
export KC_KERBEROS_FOR_PASS='["true"]'

# shellcheck source-path=SCRIPTDIR source=kc-lib.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/kc-lib.sh"

_wrapper_main 'login create_ldap_storage_provider set_first_name_mapper_attribute create_ldap_role_mapper run_user_storage_sync' "$@"

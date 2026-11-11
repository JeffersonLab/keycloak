#!/bin/bash
#
# kc-lib.sh: functions that configure Keycloak with kcadm.sh.
#
# Source it and call the functions from your own script:
#
#   . /kc-lib.sh
#   KC_ROLE_NAME=myapp-user
#   create_role
#
# or run it with env files and the functions to call, in order:
#
#   /kc-lib.sh -e /setup.env login create_realm create_client
#
# Each function checks the variables it needs, says which are missing, and returns non-zero. It
# never exits, so it can't end the shell that sourced it. Run it with --help for the list of
# functions and their variables.
#
# Names starting with _ are private helpers: they may change and can't be run from the command line.

#### Log in (the other functions use this login)

# Logs kcadm.sh in to the master realm as the bootstrap admin.
# Required: KC_BACKEND_URL KC_BOOTSTRAP_ADMIN_PASSWORD KC_BOOTSTRAP_ADMIN_USERNAME KC_HOME
bootstrap_login() {
  _require_vars KC_BACKEND_URL KC_BOOTSTRAP_ADMIN_PASSWORD KC_BOOTSTRAP_ADMIN_USERNAME KC_HOME || return
  _kcadm_login "${KC_BOOTSTRAP_ADMIN_USERNAME}" "${KC_BOOTSTRAP_ADMIN_PASSWORD}"
}

# Logs kcadm.sh in to the master realm as an admin.
# Required: KC_ADMIN_PASSWORD KC_ADMIN_USERNAME KC_BACKEND_URL KC_HOME
login() {
  _require_vars KC_ADMIN_PASSWORD KC_ADMIN_USERNAME KC_BACKEND_URL KC_HOME || return
  _kcadm_login "${KC_ADMIN_USERNAME}" "${KC_ADMIN_PASSWORD}"
}

#### Realms, clients, roles and users

# Creates the realm.
# Required: KC_HOME KC_REALM KC_REALM_DISPLAY_NAME KC_SESSION_IDLE_TIMEOUT KC_SESSION_MAX_LIFESPAN
create_realm() {
  _require_vars KC_HOME KC_REALM KC_REALM_DISPLAY_NAME KC_SESSION_IDLE_TIMEOUT \
    KC_SESSION_MAX_LIFESPAN || return
  _kcadm create realms \
    -s id="${KC_REALM}" \
    -s realm="${KC_REALM}" \
    -s enabled=true \
    -s displayName="${KC_REALM_DISPLAY_NAME}" \
    -s ssoSessionIdleTimeout="${KC_SESSION_IDLE_TIMEOUT}" \
    -s ssoSessionMaxLifespan="${KC_SESSION_MAX_LIFESPAN}" \
    -s loginWithEmailAllowed=false
}

# Creates a client whose ID and client ID are KC_CLIENT_NAME. With a service account, gives it the
# realm-management roles view-users, view-authorization and view-realm. Tries every step even if
# one fails, and then returns non-zero.
# Required: KC_CLIENT_NAME KC_HOME KC_REALM KC_REDIRECT_URIS KC_SECRET KC_SERVICE_ACCOUNT_ENABLED
# Optional: KC_PROVIDES_CLIENT_ROLES: space-separated roles to create on the client
# Optional: KC_ASSIGNED_CLIENT_ROLES: space-separated CLIENT_ID/ROLE roles of other clients to give
#           the service account
# Optional: KC_ASSIGNED_REALM_ROLES: space-separated realm roles to give the service account,
#           created if needed
# Optional: KC_UPDATE_CLIENT_ROLES_MAPPER: true to also run update_client_roles_mapper
create_client() {
  _require_vars KC_CLIENT_NAME KC_HOME KC_REALM KC_REDIRECT_URIS KC_SECRET \
    KC_SERVICE_ACCOUNT_ENABLED || return
  local rc=0 role clientid rolename
  local account="service-account-${KC_CLIENT_NAME}"

  _kcadm create clients \
    -r "${KC_REALM}" \
    -s clientId="${KC_CLIENT_NAME}" \
    -s id="${KC_CLIENT_NAME}" \
    -s enabled=true \
    -s serviceAccountsEnabled="${KC_SERVICE_ACCOUNT_ENABLED}" \
    -s redirectUris="${KC_REDIRECT_URIS}" \
    -s secret="${KC_SECRET}" || rc=1

  if [[ "${KC_SERVICE_ACCOUNT_ENABLED}" == true ]]; then
    for role in view-users view-authorization view-realm; do
      _kcadm add-roles -r "${KC_REALM}" --uusername "${account}" --cclientid realm-management \
        --rolename "${role}" || rc=1
    done
  fi

  # The client's own roles exist only within it, so they can't exist already.
  for role in ${KC_PROVIDES_CLIENT_ROLES:-}; do
    _kcadm create "clients/${KC_CLIENT_NAME}/roles" -r "${KC_REALM}" -s name="${role}" || rc=1
  done

  # Roles that another client provides, as CLIENT_ID/ROLE.
  for role in ${KC_ASSIGNED_CLIENT_ROLES:-}; do
    clientid=${role%%/*}
    rolename=${role#*/}
    rolename=${rolename%%/*}
    _kcadm add-roles -r "${KC_REALM}" --uusername "${account}" --cclientid "${clientid}" \
      --rolename "${rolename}" || rc=1
  done

  for rolename in ${KC_ASSIGNED_REALM_ROLES:-}; do
    if ! _kcadm get-roles -r "${KC_REALM}" --rolename "${rolename}"; then
      _kcadm create roles -r "${KC_REALM}" -s name="${rolename}" -s description="" || rc=1
    fi
    _kcadm add-roles -r "${KC_REALM}" --rolename "${rolename}" --uusername "${account}" || rc=1
  done

  if [[ "${KC_UPDATE_CLIENT_ROLES_MAPPER:-}" == true ]]; then
    update_client_roles_mapper || rc=1
  fi
  return "${rc}"
}

# Creates a realm role.
# Required: KC_HOME KC_REALM KC_ROLE_NAME
create_role() {
  _require_vars KC_HOME KC_REALM KC_ROLE_NAME || return
  _kcadm create roles -r "${KC_REALM}" -s name="${KC_ROLE_NAME}"
}

# Creates an enabled user and, if KC_PASSWORD is set, sets the user's password, also when the user
# already exists.
# Required: KC_EMAIL KC_FIRSTNAME KC_HOME KC_LASTNAME KC_REALM KC_USERNAME
# Optional: KC_PASSWORD: the user's password
create_user() {
  _require_vars KC_EMAIL KC_FIRSTNAME KC_HOME KC_LASTNAME KC_REALM KC_USERNAME || return
  local rc=0
  _kcadm create users \
    -r "${KC_REALM}" \
    -s username="${KC_USERNAME}" \
    -s firstName="${KC_FIRSTNAME}" \
    -s lastName="${KC_LASTNAME}" \
    -s email="${KC_EMAIL}" \
    -s enabled=true || rc=1
  if [[ -n "${KC_PASSWORD:-}" ]]; then
    _kcadm set-password -r "${KC_REALM}" --username "${KC_USERNAME}" \
      --new-password "${KC_PASSWORD}" || rc=1
  fi
  return "${rc}"
}

# Gives a user a realm role.
# Required: KC_HOME KC_REALM KC_ROLE_NAME KC_USERNAME
assign_role() {
  _require_vars KC_HOME KC_REALM KC_ROLE_NAME KC_USERNAME || return
  _kcadm add-roles -r "${KC_REALM}" --uusername "${KC_USERNAME}" --rolename "${KC_ROLE_NAME}"
}

#### LDAP user storage

# Prints the LDAP provider's component ID, which is part of each user's ID (the sub claim) when user
# import is off: f:<provider ID>:<username>. Keycloak expects a UUID or exactly 22 characters of
# letters, digits, _ and -, and logs a warning at each login otherwise. A generated ID would change
# on every new install, and with it every user's ID, so this derives one from the realm instead.
# Required: KC_REALM, unless KC_PROVIDER_ID is set
# Optional: KC_PROVIDER_ID: the ID to use instead
ldap_provider_id() {
  if [[ -n "${KC_PROVIDER_ID:-}" ]]; then
    echo "${KC_PROVIDER_ID}"
  else
    _require_vars KC_REALM || return
    printf '%s' "${KC_REALM}-ldap-provider" | sha256sum | cut -c1-22
  fi
}

# Creates the read-only LDAP user storage provider KC_REALM-ldap-provider, with the ID that
# ldap_provider_id prints.
# Required: KC_BIND_CREDENTIAL KC_BIND_DN KC_DEBUG KC_HOME KC_IMPORT KC_KERBEROS_REALM KC_KEYTAB
#           KC_LDAP_CONNECTION_URL KC_RDN KC_REALM KC_SERVER_PRINCIPLE KC_SPNEGO KC_USERNAME_ATTR
#           KC_USER_OBJ_CLASSES KC_USERS_DN KC_UUID KC_VENDOR
# Optional: KC_KERBEROS_FOR_PASS: whether to use Kerberos for password authentication
# Optional: KC_PROVIDER_ID: the provider's ID; derived from KC_REALM if unset
create_ldap_storage_provider() {
  _require_vars KC_BIND_CREDENTIAL KC_BIND_DN KC_DEBUG KC_HOME KC_IMPORT KC_KERBEROS_REALM \
    KC_KEYTAB KC_LDAP_CONNECTION_URL KC_RDN KC_REALM KC_SERVER_PRINCIPLE KC_SPNEGO \
    KC_USERNAME_ATTR KC_USER_OBJ_CLASSES KC_USERS_DN KC_UUID KC_VENDOR || return
  local id
  id=$(ldap_provider_id) || return
  _kcadm create components \
    -r "${KC_REALM}" \
    -s parentId="${KC_REALM}" \
    -s id="${id}" \
    -s name="${KC_REALM}-ldap-provider" \
    -s providerId=ldap \
    -s providerType=org.keycloak.storage.UserStorageProvider \
    -s config.debug="${KC_DEBUG}" \
    -s 'config.authType=["simple"]' \
    -s config.vendor="${KC_VENDOR}" \
    -s 'config.priority=["0"]' \
    -s config.connectionUrl="${KC_LDAP_CONNECTION_URL}" \
    -s 'config.editMode=["READ_ONLY"]' \
    -s config.usersDn="${KC_USERS_DN}" \
    -s config.serverPrincipal="${KC_SERVER_PRINCIPLE}" \
    -s config.bindDn="${KC_BIND_DN}" \
    -s config.bindCredential="${KC_BIND_CREDENTIAL}" \
    -s 'config.fullSyncPeriod=["86400"]' \
    -s 'config.changedSyncPeriod=["-1"]' \
    -s 'config.cachePolicy=["NO_CACHE"]' \
    -s 'config.evictionDay=[]' \
    -s 'config.evictionHour=[]' \
    -s 'config.evictionMinute=[]' \
    -s 'config.maxLifespan=[]' \
    -s config.importEnabled="${KC_IMPORT}" \
    -s 'config.batchSizeForSync=["1000"]' \
    -s 'config.syncRegistrations=["false"]' \
    -s config.usernameLDAPAttribute="${KC_USERNAME_ATTR}" \
    -s config.rdnLDAPAttribute="${KC_RDN}" \
    -s config.uuidLDAPAttribute="${KC_UUID}" \
    -s config.userObjectClasses="${KC_USER_OBJ_CLASSES}" \
    -s 'config.searchScope=["1"]' \
    -s 'config.useTruststoreSpi=["ldapsOnly"]' \
    -s 'config.connectionPooling=["true"]' \
    -s 'config.pagination=["true"]' \
    -s config.allowKerberosAuthentication="${KC_SPNEGO}" \
    -s config.keyTab="${KC_KEYTAB}" \
    -s config.kerberosRealm="${KC_KERBEROS_REALM}" \
    -s config.useKerberosForPasswordAuthentication="${KC_KERBEROS_FOR_PASS:-}"
}

# Sets the LDAP attribute of the 'first name' mapper, such as '["givenName"]'.
# See https://github.com/keycloak/keycloak/issues/15623
# Required: KC_FIRSTNAME_ATTR KC_HOME KC_REALM
set_first_name_mapper_attribute() {
  _require_vars KC_FIRSTNAME_ATTR KC_HOME KC_REALM || return
  local mapper_id
  mapper_id=$(_kcadm get components -r "${KC_REALM}" -q name='first name' --fields id \
    | jq -r '.[0].id') || return
  _kcadm update "components/${mapper_id}" -r "${KC_REALM}" \
    -s 'config."ldap.attribute"'="${KC_FIRSTNAME_ATTR}"
}

# Creates the LDAP role mapper KC_REALM-ldap-role-mapper, which maps the groupOfNames entries under
# KC_ROLES_DN to realm roles.
# Required: KC_HOME KC_REALM KC_ROLES_DN
# Optional: KC_PROVIDER_ID: the LDAP provider's ID; derived from KC_REALM if unset
create_ldap_role_mapper() {
  _require_vars KC_HOME KC_REALM KC_ROLES_DN || return
  local id
  id=$(ldap_provider_id) || return
  _kcadm create components \
    -r "${KC_REALM}" \
    -s parentId="${id}" \
    -s id="${KC_REALM}-ldap-role-mapper" \
    -s name="${KC_REALM}-ldap-role-mapper" \
    -s providerId=role-ldap-mapper \
    -s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper \
    -s 'config."roles.dn"'="${KC_ROLES_DN}" \
    -s 'config."role.name.ldap.attribute"=["cn"]' \
    -s 'config."role.object.classes"=["groupOfNames"]' \
    -s 'config."membership.ldap.attribute"=["member"]' \
    -s 'config."membership.attribute.type"=["DN"]' \
    -s 'config."membership.user.ldap.attribute"=["uid"]' \
    -s 'config.mode=["READ_ONLY"]' \
    -s 'config."user.roles.retrieve.strategy"=["GET_ROLES_FROM_USER_MEMBEROF_ATTRIBUTE"]' \
    -s 'config."memberof.ldap.attribute"=["memberOf"]' \
    -s 'config."use.realm.roles.mapping"=["true"]'
}

# Runs a full sync of the user storage provider KC_PROVIDER: its name, such as
# KC_REALM-ldap-provider, or its ID.
# Required: KC_HOME KC_PROVIDER KC_REALM
run_user_storage_sync() {
  _require_vars KC_HOME KC_PROVIDER KC_REALM || return
  local provider_id
  provider_id=$(_kcadm get components -r "${KC_REALM}" -q name="${KC_PROVIDER}" --fields id \
    | jq -r '.[0].id // empty')
  _kcadm create -r "${KC_REALM}" "user-storage/${provider_id:-${KC_PROVIDER}}/sync?action=triggerFullSync"
}

#### Identity providers

# Creates a Keycloak OIDC identity provider.
# Required: KC_ALIAS KC_AUTH_URL KC_CLIENT_NAME KC_DISPLAY_NAME KC_FIRST_LOGIN_FLOW KC_HOME
#           KC_ISSUER_URL KC_JWKS_URL KC_LOGOUT_URL KC_REALM KC_SECRET KC_TOKEN_URL
create_idp() {
  _require_vars KC_ALIAS KC_AUTH_URL KC_CLIENT_NAME KC_DISPLAY_NAME KC_FIRST_LOGIN_FLOW KC_HOME \
    KC_ISSUER_URL KC_JWKS_URL KC_LOGOUT_URL KC_REALM KC_SECRET KC_TOKEN_URL || return
  _kcadm create identity-provider/instances -r "${KC_REALM}" \
    -s alias="${KC_ALIAS}" \
    -s providerId=keycloak-oidc \
    -s enabled=true \
    -s displayName="${KC_DISPLAY_NAME}" \
    -s firstBrokerLoginFlowAlias="${KC_FIRST_LOGIN_FLOW}" \
    -s config.clientId="${KC_CLIENT_NAME}" \
    -s config.disableUserInfo=true \
    -s config.validateSignature=true \
    -s config.useJwksUrl=true \
    -s config.authorizationUrl="${KC_AUTH_URL}" \
    -s config.tokenUrl="${KC_TOKEN_URL}" \
    -s config.logoutUrl="${KC_LOGOUT_URL}" \
    -s config.issuer="${KC_ISSUER_URL}" \
    -s config.jwksUrl="${KC_JWKS_URL}" \
    -s config.backchannelSupported=true \
    -s config.clientSecret="${KC_SECRET}"
}

# Creates the authentication flow KC_ALIAS, to use as an identity provider's first login flow: it
# creates the user if unique, or else links the brokered login to the existing user. Tries every
# step even if one fails, and then returns non-zero.
# Required: KC_ALIAS KC_HOME KC_REALM
create_autolink_flow() {
  _require_vars KC_ALIAS KC_HOME KC_REALM || return
  local rc=0 provider execution_id
  _kcadm create authentication/flows -r "${KC_REALM}" \
    -s alias="${KC_ALIAS}" \
    -s providerId=basic-flow \
    -s id="${KC_REALM}-autolink-flow" \
    -s topLevel=true \
    -s builtIn=false \
    -s description="Automatically link brokered IdP on first login" || rc=1

  for provider in idp-create-user-if-unique idp-auto-link; do
    execution_id=$(_kcadm create "authentication/flows/${KC_ALIAS}/executions/execution" \
      -r "${KC_REALM}" -s provider="${provider}" -i) || rc=1
    _kcadm update "authentication/flows/${KC_ALIAS}/executions" -r "${KC_REALM}" \
      -b "{\"id\":\"${execution_id}\",\"requirement\":\"ALTERNATIVE\"}" || rc=1
  done
  return "${rc}"
}

#### Roles in tokens

# Puts users' realm roles in the ID token, access token and userinfo of every client in the realm,
# by changing the 'realm roles' mapper of the built-in roles client scope. Clients such as Apache
# httpd can then authorize by role from the token.
# Required: KC_HOME KC_REALM
update_realm_roles_scope() {
  # To do this for one client instead, see update_client_roles_mapper, or in the admin console:
  # clients -> <client_name> -> scopes -> <app-dedicated scope> -> Add Realm Role -> Include in
  # Access/ID token. API:
  # https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmclient_templatesclient_scope_idprotocol_mappersmodelsid
  _require_vars KC_HOME KC_REALM || return
  local scope_id mapper_id new_config

  # The ID of the roles client scope, and of its 'realm roles' mapper.
  scope_id=$(_kcadm get client-scopes -r "${KC_REALM}" --fields id,name \
    | jq -r '.[] | select(.name=="roles") | .id') || return
  mapper_id=$(_kcadm get "client-scopes/${scope_id}/protocol-mappers/models" -r "${KC_REALM}" \
    | jq -r '.[] | select(.name=="realm roles") | .id') || return

  # Keycloak wants the whole config object back, not just the changed fields.
  new_config=$(_kcadm get "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" \
      -r "${KC_REALM}" \
    | jq '.config["id.token.claim"]="true"
          | .config["access.token.claim"]="true"
          | .config["userinfo.token.claim"]="true"') || return

  _kcadm update "client-scopes/${scope_id}/protocol-mappers/models/${mapper_id}" -r "${KC_REALM}" \
    -f <(echo "${new_config}")
}

# Puts users' realm roles in the ID token and userinfo of the client KC_CLIENT_NAME only, by adding
# a copy of the realm's 'realm roles' mapper to the client's dedicated scope. Clients such as Apache
# httpd can then authorize by role from the token.
# Required: KC_CLIENT_NAME KC_HOME KC_REALM
update_client_roles_mapper() {
  # The admin console (client -> client scopes -> dedicated scope -> mappers) offers a predefined
  # mapper, but the REST API doesn't seem to, so this copies the roles client scope's one instead.
  _require_vars KC_CLIENT_NAME KC_HOME KC_REALM || return
  local scope_id mapper

  _log "Updating dedicated client scope roles mapper for '${KC_CLIENT_NAME}'"

  scope_id=$(_kcadm get client-scopes -r "${KC_REALM}" --fields id,name \
    | jq -r '.[] | select(.name=="roles") | .id') || return

  mapper=$(_kcadm get "client-scopes/${scope_id}/protocol-mappers/models" -r "${KC_REALM}" \
    | jq '.[] | select(.name=="realm roles")
          | del(.id)
          | .config["id.token.claim"]="true"
          | .config["userinfo.token.claim"]="true"') || return

  _kcadm create "clients/${KC_CLIENT_NAME}/protocol-mappers/models" -r "${KC_REALM}" \
    -f <(echo "${mapper}")
}

#### Private helpers

_log() {
  echo "$*"
}

_err() {
  echo "ERROR: $*" >&2
}

# Returns non-zero, naming the calling function and each variable, if any of the named variables is
# unset or empty.
_require_vars() {
  local var
  local -a missing=()
  for var in "$@"; do
    [[ -n "${!var:-}" ]] || missing+=("${var}")
  done
  if (( ${#missing[@]} )); then
    _err "${FUNCNAME[1]} needs ${missing[*]}, which $( (( ${#missing[@]} == 1 )) && echo is || echo are ) not set"
    return 1
  fi
}

# Runs kcadm.sh with the given arguments.
_kcadm() {
  "${KC_HOME}/bin/kcadm.sh" "$@"
}

# Arguments: user, password.
_kcadm_login() {
  _kcadm config credentials --server "${KC_BACKEND_URL}" --realm master --user "$1" --password "$2"
}

# The public functions: those defined in this file whose names don't start with _.
_public_functions() {
  sed -nE 's/^([a-z][a-z0-9_]*)\(\) \{$/\1/p' "${BASH_SOURCE[0]}"
}

# Runs each named function in order, stopping at the first that fails. Refuses, before running
# any, a name that isn't a public function.
_run_functions() {
  local fn
  local -a public
  mapfile -t public < <(_public_functions)
  for fn in "$@"; do
    if [[ " ${public[*]} " != *" ${fn} "* ]]; then
      _err "Unknown function: ${fn} (kc-lib.sh --help lists them)"
      return 2
    fi
  done

  for fn in "$@"; do
    _log "------------------------"
    _log "${fn}"
    _log "------------------------"
    if ! "${fn}"; then
      _err "${fn} failed"
      return 1
    fi
  done
}

_usage() {
  cat <<EOF
Usage: ${0##*/} [-e ENV_FILE]... FUNCTION...
       . ${0##*/}

Runs each FUNCTION in order, stopping at the first that fails. Each -e ENV_FILE is a file of bash
variable assignments, sourced first, in order. Source this file instead to call the functions from
a script. Each function checks the variables it needs.

Functions:
EOF
  # Print each section heading, and each public function with the comment block above it.
  awk '
    /^#### Private/  { exit }
    /^#### /         { sub(/^#### /, ""); printf "\n  %s\n", $0; doc = ""; next }
    /^#/             { line = $0; sub(/^# ?/, "", line); doc = doc "      " line "\n"; next }
    /^[a-z][a-z0-9_]*\(\) \{$/ { sub(/\(\) \{$/, ""); printf "    %s\n%s", $0, doc; doc = ""; next }
                     { doc = "" }
  ' "${BASH_SOURCE[0]}"
}

# The command line of the wrapper scripts (realm-setup.sh and the like), which source this file:
# WRAPPER ENV_FILE [FUNCTION]. Sources ENV_FILE if it is a file, then COMMON_ENV_FILE if that is set
# and a file, and runs FUNCTION or, with none named, the wrapper's defaults.
# Arguments: the wrapper's default functions, space-separated; then the wrapper's own arguments.
_wrapper_main() {
  local -a defaults
  read -r -a defaults <<< "$1"
  shift

  if (( $# == 0 )); then
    echo "Usage: ${0##*/} ENV_FILE [FUNCTION]"
    echo "Sources ENV_FILE, a file of bash variable assignments, then COMMON_ENV_FILE if it is set."
    echo "Runs FUNCTION, which can be any kc-lib.sh function, or else these, in order, stopping at"
    echo "the first that fails."
    printf '\n'
    printf 'Functions: '
    printf '%s ' "${defaults[@]}"
    printf '\n\n'
    echo "The same as: kc-lib.sh -e ENV_FILE ${defaults[*]}"
    echo "kc-lib.sh --help lists every function and the variables it needs."
    return 0
  fi

  if [[ -n "$1" && -f "$1" ]]; then
    _log "Loading environment $1"
    # shellcheck disable=SC1090
    . "$1"
  elif [[ -n "$1" ]]; then
    _err "Env file not found: $1; continuing without it"
  fi

  if [[ -n "${COMMON_ENV_FILE:-}" && -f "${COMMON_ENV_FILE}" ]]; then
    _log "Loading common env: ${COMMON_ENV_FILE}"
    # shellcheck disable=SC1090
    . "${COMMON_ENV_FILE}"
  else
    _log "No common env"
  fi

  if [[ -n "${2:-}" ]]; then
    _run_functions "$2"
  else
    _run_functions "${defaults[@]}"
  fi
}

_main() {
  set -uo pipefail
  local -a fns=()
  while (( $# )); do
    case "$1" in
      -h|--help)
        _usage
        return 0 ;;
      -e|--env)
        if [[ ! -f "${2:-}" ]]; then
          _err "Env file not found: ${2:-}"
          return 2
        fi
        _log "Loading environment $2"
        # shellcheck disable=SC1090
        . "$2"
        shift 2 ;;
      -*)
        _err "Unknown option: $1"
        return 2 ;;
      *)
        fns+=("$1")
        shift ;;
    esac
  done

  if (( ${#fns[@]} == 0 )); then
    _usage >&2
    return 2
  fi
  _run_functions "${fns[@]}"
}

# Run only when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  _main "$@"
fi

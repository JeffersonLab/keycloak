#!/bin/bash

# Marks that the setup scripts have run.  With the default dev-file database the marker lives in the data
# directory next to the database, so both persist (or not) together when a volume is mounted on
# ${KC_HOME}/data.  With any other database (e.g. KC_DB=oracle) the marker stays in the container's own layer.
# Keep in sync with container-healthcheck.sh.
if [[ -z "${KC_DB}" || "${KC_DB}" == "dev-file" ]]; then
    SETUP_MARKER="${KC_HOME}/data/setup-complete"
else
    SETUP_MARKER="${KC_HOME}/setup-complete"
fi

# Pass docker stop's SIGTERM (or Ctrl-C's SIGINT) on to Keycloak, wait for it to shut down, and exit with its status
function stop_keycloak {
  echo "CONTAINER: Stopping Keycloak..."
  kill -TERM "${KC_PID}" 2>/dev/null
  wait "${KC_PID}"
  exit $?
}

trap stop_keycloak TERM INT

echo "--------------------------"
echo "| Step 1: Start Keycloak |"
echo "--------------------------"

# start-dev implies --hostname-strict false --http-enabled true
${KC_HOME}/bin/kc.sh start-dev --hostname ${KC_FRONTEND_URL} --hostname-admin ${KC_FRONTEND_URL} --hostname-backchannel-dynamic true --hostname-debug true --http-relative-path ${KC_HTTP_RELATIVE_PATH} &
KC_PID=$!

echo "--------------------------------------"
echo "| Step 2: Wait for Keycloak to start |"
echo "--------------------------------------"

if [[ -z "${KC_BACKEND_URL}" ]]; then
    echo "Skipping Keycloak Setup: Must provide KC_BACKEND_URL in environment"
    wait "${KC_PID}"
    exit $?
fi

until curl ${KC_BACKEND_URL} -sf -o /dev/null;
do
  if ! kill -0 "${KC_PID}" 2>/dev/null; then
    wait "${KC_PID}"
    status=$?
    echo "CONTAINER: Keycloak exited with status ${status} before it started"
    exit ${status}
  fi
  echo $(date) " Still waiting for Keycloak to start..."
  sleep 5
done

echo "---------------------"
echo "| Step 3: Configure |"
echo "---------------------"
# Run custom scripts provided by the user
# usage: run_custom_scripts PATH
#    ie: run_custom_scripts /container-entrypoint-initdb.d
# This runs *.sh files
# Inspired by: https://github.com/gvenzl/oci-oracle-xe/blob/0cedd27ab04771789f1425639434d33940935f6c/container-entrypoint.sh#L208
function run_custom_scripts {

  SCRIPTS_ROOT="${1}";

  # Check whether parameter has been passed on
  if [ -z "${SCRIPTS_ROOT}" ]; then
    echo "No SCRIPTS_ROOT passed on, no scripts will be run.";
    return;
  fi;

  # Execute custom provided files (only if directory exists and has files in it)
  if [ -d "${SCRIPTS_ROOT}" ] && [ -n "$(ls -A "${SCRIPTS_ROOT}")" ]; then

    echo -e "\nCONTAINER: Executing user defined scripts..."

    run_custom_scripts_recursive ${SCRIPTS_ROOT}

    echo -e "CONTAINER: DONE: Executing user defined scripts.\n"

  fi;
}

# True when KC_SKIP_DEFAULT_SETUP=true and the file is an unmodified copy of one of the image's /defaults files
# at the top of /container-entrypoint-initdb.d, so user provided scripts still run
function is_skipped_default {
  local d="/defaults/$(basename "${1}")"
  [ "${KC_SKIP_DEFAULT_SETUP}" == "true" ] && [ "$(dirname "${1}")" == "/container-entrypoint-initdb.d" ] \
    && [ -f "${1}" ] && [ -f "${d}" ] && [ "$(< "${1}")" == "$(< "${d}")" ]
}

# This recursive function traverses through sub directories by calling itself with them
# usage: run_custom_scripts_recursive PATH
#    ie: run_custom_scripts_recursive /container-entrypoint-initdb.d/001_subdir
# This runs *.sh files and traverses in sub directories
function run_custom_scripts_recursive {
  local f
  for f in "${1}"/*; do
    if is_skipped_default "${f}"; then
                    echo -e "\nCONTAINER: skipping default ${f} (KC_SKIP_DEFAULT_SETUP=true)"
                    echo "";
                    continue
    fi;
    case "${f}" in
      *.sh)
        if [ -x "${f}" ]; then
                    echo -e "\nCONTAINER: running ${f} ...";     "${f}";     echo "CONTAINER: DONE: running ${f}"
        fi;
        ;;

      *.env)
        if [ -f "${f}" ]; then
                    echo -e "\nCONTAINER: sourcing ${f} ...";    . "${f}";    echo "CONTAINER: DONE: sourcing ${f}"
        fi;
        ;;

      *)
        if [ -d "${f}" ]; then
                    echo -e "\nCONTAINER: descending into ${f} ...";    run_custom_scripts_recursive "${f}";    echo "CONTAINER: DONE: descending into ${f}"
        else
                    echo -e "\nCONTAINER: ignoring ${f}"
        fi;
        ;;
    esac
    echo "";
  done
}

if [ ! -f "${SETUP_MARKER}" ]; then
echo -e "Running setup scripts"
run_custom_scripts "/container-entrypoint-initdb.d"
mkdir -p "$(dirname "${SETUP_MARKER}")"
touch "${SETUP_MARKER}"
else
echo -e "Setup already run; skipping"
fi

echo "----------"
echo "| READY! |"
echo "----------"

# Run until Keycloak exits, so the container stops with it and Docker's restart policy applies
wait "${KC_PID}"
status=$?
echo "CONTAINER: Keycloak exited with status ${status}"
exit ${status}

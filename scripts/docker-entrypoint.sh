#!/bin/bash

export KEYCLOAK_HOME='/opt/keycloak'

echo "--------------------------"
echo "| Step 1: Start Keycloak |"
echo "--------------------------"

${KEYCLOAK_HOME}/bin/kc.sh start-dev --hostname $KEYCLOAK_FRONTEND_HOSTNAME --hostname-port=$KEYCLOAK_FRONTEND_PORT &

echo "--------------------------------------"
echo "| Step 2: Wait for Keycloak to start |"
echo "--------------------------------------"

if [[ -z "${KEYCLOAK_SERVER_URL}" ]]; then
    echo "Skipping Keycloak Setup: Must provide KEYCLOAK_SERVER_URL in environment"
    return 0
fi

until curl ${KEYCLOAK_SERVER_URL} -sf -o /dev/null;
do
  echo $(date) " Still waiting for Keycloak to start..."
  sleep 5
done

echo "---------------------"
echo "| Step 3: Configure |"
echo "---------------------"
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

# This recursive function traverses through sub directories by calling itself with them
# usage: run_custom_scripts_recursive PATH
#    ie: run_custom_scripts_recursive /container-entrypoint-initdb.d/001_subdir
# This runs *.sh files and traverses in sub directories
function run_custom_scripts_recursive {
  local f
  for f in "${1}"/*; do
    case "${f}" in
      *.sh)
        if [ -x "${f}" ]; then
                    echo -e "\nCONTAINER: running ${f} ...";     "${f}";     echo "CONTAINER: DONE: running ${f}"
        fi;
        ;;

      *.env)
        if [ -f "${f}" ]; then
                    echo -e "\nCONTAINER: sourcing ${f} ...";    . "${f}"    echo "CONTAINER: DONE: sourcing ${f}"
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

if [ ! -f /${KEYCLOAK_HOME}/setup-complete ]; then
echo -e "Running setup scripts"
run_custom_scripts "/docker-entrypoint-initdb.d"
touch /${KEYCLOAK_HOME}/setup-complete
else
echo -e "Setup already run; skipping"
fi

echo "----------"
echo "| READY! |"
echo "----------"

sleep infinity


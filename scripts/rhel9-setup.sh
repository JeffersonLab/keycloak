#!/bin/bash

FUNCTIONS=(create_user_and_group
           download
           unzip_and_chmod
           create_symbolic_links
           create_systemd_service
           create_log_file_cleanup_cron)

VARIABLES=(KEYCLOAK_BIND_ADDRESS
           KEYCLOAK_GROUP
           KEYCLOAK_GROUP_ID
           KEYCLOAK_HTTPS_PORT
           KEYCLOAK_USER
           KEYCLOAK_USER_HOME
           KEYCLOAK_USER_ID
           KEYCLOAK_VERSION)

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 [var file] <optional function>"
    echo "The var file arg should be the path to a file with bash variables that will be sourced."
    echo "The optional function name arg if provided is the sole function to call, else all functions are invoked sequentially."
    printf 'Variables: '
    printf '%s ' "${VARIABLES[@]}"
    printf '\n'
    printf 'Functions: '
    printf '%s ' "${FUNCTIONS[@]}"
    printf '\n'
    exit 0
fi

if [ ! -z "$1" ] && [ -f "$1" ]
then
echo "Loading environment $1"
. $1
fi

# Verify expected env set:
for i in "${!VARIABLES[@]}"; do
  var=${VARIABLES[$i]}
  [ -z "${!var}" ] && { echo "$var is not set. Exiting."; exit 1; }
done

KEYCLOAK_APP_HOME=${KEYCLOAK_USER_HOME}/${KEYCLOAK_VERSION}

remove_java_11() {
# We're assuming this leaves only JDK17
yum remove java-11-openjdk-headless -y
alternatives --auto java
}

create_user_and_group() {
groupadd -r -g ${KEYCLOAK_GROUP_ID} ${KEYCLOAK_GROUP}
useradd -r -m -u ${KEYCLOAK_USER_ID} -g ${KEYCLOAK_GROUP_ID} -d ${KEYCLOAK_USER_HOME} -s /bin/bash ${KEYCLOAK_USER}
}

download() {
cd /tmp
wget https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.zip
}

unzip_and_chmod() {
unzip /tmp/keycloak-${KEYCLOAK_VERSION}.zip -d ${KEYCLOAK_USER_HOME}
mv ${KEYCLOAK_USER_HOME}/keycloak-${KEYCLOAK_VERSION} ${KEYCLOAK_APP_HOME}
chown -R ${KEYCLOAK_USER}:${KEYCLOAK_GROUP} ${KEYCLOAK_USER_HOME}
}

create_symbolic_links() {
cd ${KEYCLOAK_USER_HOME}
ln -s ${KEYCLOAK_VERSION} current
ln -s current/conf conf
ln -s current/data/log log
}

create_systemd_service() {
if (( ${KEYCLOAK_HTTPS_PORT} < 1024 ))
then
  sysctl -w net.ipv4.ip_unprivileged_port_start=${KEYCLOAK_HTTPS_PORT} >> /etc/sysctl.conf
fi

cat > /etc/systemd/system/keycloak.service << EOF
[Unit]
Description=The Keycloak Server
After=syslog.target network.target sssd.service
[Service]
EnvironmentFile=${KEYCLOAK_USER_HOME}/current/conf/run.env
User=${KEYCLOAK_USER}
LimitNOFILE=102642
PIDFile=/run/keycloak.pid
ExecStart=${KEYCLOAK_USER_HOME}/current/bin/kc.sh start --optimized
StandardOutput=null
SuccessExitStatus=143
[Install]
WantedBy=multi-user.target
EOF
systemctl enable keycloak
}

create_log_file_cleanup_cron() {
cat > /root/delete-old-keycloak-logs.sh << EOF
#!/bin/sh
if [ -d ${KEYCLOAK_USER_HOME}/log ] ; then
 /usr/bin/find ${KEYCLOAK_USER_HOME}/log/ -mtime +30 -exec /usr/bin/rm {} \;
fi
EOF
chmod +x /root/delete-old-keycloak-logs.sh
cat > /etc/cron.d/delete-old-keycloak-logs.cron << EOF
0 0 * * * /root/delete-old-keycloak-logs.sh >/dev/null 2>&1
EOF
}

if [ ! -z "$2" ]
then
  echo "------------------------"
  echo "$2"
  echo "------------------------"
  $2
else
for i in "${!FUNCTIONS[@]}"; do
  echo "------------------------"
  echo "${FUNCTIONS[$i]}"
  echo "------------------------"
  ${FUNCTIONS[$i]};
done
fi

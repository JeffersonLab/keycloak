#!/bin/bash

# Note: the dscontainer -H healthcheck returns before the server is really ready for two reasons:
# 1. The Directory Manager password is set AFTER healthy is reported!
# 2. The connection tested is ldapi local pipe connection.   The socket connection may not be ready yet!
# The following error is the symptom:
# "ldap_bind: Invalid credentials (49)"
# During the Docker build we set the default test Directory Manager password, so unless you change it from the default
# the re-setting to same thing may not be a problem depending on how dirsrv behaves during set password transaction. To
# be safer best sleep a little.
# The local pipe vs port issue can be ameliorated by trying the port bind in a loop.
# See:
# - https://github.com/389ds/389-ds-base/pull/6070
# - https://github.com/389ds/389-ds-base/blob/d65eea90311543b3ea906cdc29ff526ae6b64956/src/lib389/cli/dscontainer#L389
# - https://github.com/389ds/389-ds-base/blob/d65eea90311543b3ea906cdc29ff526ae6b64956/src/lib389/cli/dscontainer#L402
until ldapwhoami -H ldap://localhost:3389 -x | grep -q "anonymous";
do
  echo $(date) " Still waiting for dirsrv to start (after Healthcheck says healthy)..."
  sleep 1
done
# Now sleep a minimize chance of encountering (but no guarantee) Directory Manager password change after healthy issue
sleep 2

## Note: we rely on "standard" LDAP schemas as defined in /usr/share/dirsrv/schema
echo "Creating Backend Database ${DS_BACKEND_NAME}"
dsconf localhost backend create --suffix="${DS_SUFFIX_NAME}" --be-name="${DS_BACKEND_NAME}"

# Add structure
echo "Adding example dcObject"
ldapadd -D "cn=Directory Manager" -w ${DS_DM_PASSWORD} -H ldap://localhost:3389 -x <<EOF
dn: ${DS_SUFFIX_NAME}
dc: ${DS_BACKEND_NAME}
objectClass: dcObject
EOF

# We are simulating freeipa LDAP so need freeipa flat schema
# See https://github.com/freeipa/freeipa/blob/master/install/share/bootstrap-template.ldif
echo "Adding accounts nsContainer"
ldapadd -D "cn=Directory Manager" -w ${DS_DM_PASSWORD} -H ldap://localhost:3389 -x <<EOF
dn: cn=accounts,${DS_SUFFIX_NAME}
changetype: add
objectClass: top
objectClass: nsContainer
cn: accounts
EOF

echo "Adding users nsContainer"
ldapadd -D "cn=Directory Manager" -w ${DS_DM_PASSWORD} -H ldap://localhost:3389 -x <<EOF
dn: cn=users,cn=accounts,${DS_SUFFIX_NAME}
changetype: add
objectClass: top
objectClass: nsContainer
cn: users
EOF

echo "Adding groups nsContainer"
ldapadd -D "cn=Directory Manager" -w ${DS_DM_PASSWORD} -H ldap://localhost:3389 -x <<EOF
dn: cn=groups,cn=accounts,${DS_SUFFIX_NAME}
changetype: add
objectClass: top
objectClass: nsContainer
cn: groups
EOF

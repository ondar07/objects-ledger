#!/bin/bash

set -e

# Initialize the root CA
# BOOTSTRAP_USER_PASS=$ROOT_CA_ADMIN_USER_PASS (makeDocker.sh)
# (например, rca-admin:rca-adminpw )
fabric-ca-server init -b $BOOTSTRAP_USER_PASS

# Copy the root CA's signing certificate to the data directory to be used by others
# $TARGET_CERTFILE=ROOT_CA_CERTFILE=/${DATA}/${ORG}-ca-cert.pem
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $TARGET_CERTFILE

# Add the custom orgs
# $FABRIC_ORGS -- see in docker-compose.yml
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
#    org0: []
#    org1: []
#    org2: []"

aff="${aff#\\n   }"
echo "aff="
echo aff
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# sed команда выше добавит $aff в fabric-ca-server-config.yaml:
# affiliations:
#    org0: []
#    org1: []
#    org2: []
#    org1:
#       - department1
#       - department2
#    org2:
#       - department1

# Start the root CA
fabric-ca-server start

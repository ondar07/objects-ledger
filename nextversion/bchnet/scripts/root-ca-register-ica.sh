#!/bin/bash

source $(dirname "$0")/env.sh

set -e

# enroll rca bootstrap identity
export FABRIC_CA_CLIENT_HOME=$HOME/fabric-ca/clients/rca-admin
# см. env.sh
# т.к. у любой организации один Root CA, то initOrgVars можно взять любую организацию
initOrgVars "org1"
fabric-ca-client enroll -u http://$ROOT_CA_ADMIN_USER_PASS@$ROOT_CA_HOST:7054

# register ICA bootstrap identities
for ORG in $PEER_ORGS; do
    initOrgVars $ORG
    # ROOT_CA_INT_USER=ica-${ORG}
    # ROOT_CA_INT_PASS=ica-${ORG}pw
    fabric-ca-client register --id.name $ROOT_CA_INT_USER --id.attrs '"hf.Registrar.Roles=user,peer",hf.Revoker=true,hf.IntermediateCA=true' --id.secret $ROOT_CA_INT_PASS
done


# finish register procedure
touch $ROOT_CA_SUCCESS_FILE

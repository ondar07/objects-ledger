#!/bin/bash

source $(dirname "$0")/env.sh
# $ORG -- org0 для ica для org0 (см. docker-compose)
# следующая функция настроит все нужные перменные для $ORG (например, для org0)
initOrgVars $ORG

set -e

# зарегать ica identity
# и далее ica identity пусть выступает в качестве $PARENT_URL в следующей init команде (см. ниже)
if [[ "$ORG" = "org1" || "$ORG" = "org2" || "$ORG" = "org3" ]]
then
    dowait "root CA must be ready" 60 $ROOT_CA_LOGFILE $ROOT_CA_SUCCESS_FILE
fi

# Wait for the root CA to start
waitPort "root CA to start" 60 $ROOT_CA_LOGFILE $ROOT_CA_HOST 7054


# Initialize the intermediate CA
# $BOOTSTRAP_USER_PASS=ica-{ORG}-admin:ica-{ORG}-adminpw (см. docker-compose.yml)
# $PARENT_URL это имя identity, под которым сущность ica зарегана у root ca
fabric-ca-server init -b $BOOTSTRAP_USER_PASS -u $PARENT_URL

# Copy the intermediate CA's certificate chain to the data directory to be used by others
# $TARGET_CHAINFILE=/data/org0-ca-chain.pem
# т.е. после этого как все сгенерили (сертификаты, chain файл, ключи), мы после этого перетаскиваем
# ca-chain.pem файл в shared /data директорию
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $TARGET_CHAINFILE

# Add the custom orgs
# тут так же, как в скрипте для rca
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the intermediate CA
fabric-ca-server start


# чтобы запустить ica:
# # $BOOTSTRAP_USER_PASS=ica-org0-admin:ica-org0-adminpw
# # $PARENT_URL=https://rca-org0-admin:rca-org0-adminpw@rca-org0:7054
# fabric-ca-server init -b $BOOTSTRAP_USER_PASS -u $PARENT_URL
# fabric-ca-server start

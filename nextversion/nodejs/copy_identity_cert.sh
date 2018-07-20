#!/bin/bash

# copy admin cert and key of org1
# Run this script on localhost
# (maybe root credentials are need)
set -e

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Usage ./<this_scripts.sh> <number of org>"
    exit 1
fi

ORG_NR=$1
ORG=org$ORG_NR
IDENTITY_NAME=admin
IDENTITY_DIR=../bchnet/data/orgs/$ORG/admin

if [ ! -d "$IDENTITY_DIR" ]; then
    # if $IDENTITY_DIR doesn't exist.
    echo "admin dir: $IDENTITY_DIR doesn't exist"
    exit 1
fi

DESTINATION_DIR=./hfc-key-store
IDENTITY_CERT=$IDENTITY_DIR/msp/signcerts/cert.pem

# check if destination dir exists
# if it doesn't exist, then create it
if [ ! -d "$DESTINATION_DIR" ]; then
	mkdir $DESTINATION_DIR
fi

# 2. extract key
# save current dir
pushd $IDENTITY_DIR/msp/keystore
KEY_NAME=`ls | grep *_sk`
IDENTITY_KEY=$IDENTITY_DIR/msp/keystore/$KEY_NAME
popd

DEST_ID=admin$ORG_NR
DEST_KEY=${KEY_NAME}

# copy
cp $IDENTITY_KEY $DESTINATION_DIR/$DEST_KEY
cp $IDENTITY_CERT $DESTINATION_DIR/${DEST_ID}_cert.pem

# 3.
python3 convert_cert_to_nodejs.py $DESTINATION_DIR/${DEST_ID}_cert.pem $DESTINATION_DIR/$DEST_ID

# 4.
chown ondar:ondar $DESTINATION_DIR/${DEST_ID}_cert.pem
chown ondar:ondar $DESTINATION_DIR/${DEST_ID}
chown ondar:ondar $DESTINATION_DIR/${DEST_KEY}

echo "Copy admin certificate and key successfully"
exit 0

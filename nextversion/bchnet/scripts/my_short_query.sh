#!/bin/bash
set -e

# this block must be run by host
CHANNEL_NAME=mychannel
CHAINCODE_NAME=mycc
ORG=org1
#DOCKER_PEER_CONTAINER="run"
PEER_HOST=peer1-org1
CORE_PEER_ID=$PEER_HOST
CORE_PEER_ADDRESS=$PEER_HOST:7051
CORE_PEER_LOCALMSPID=$ORG_MSP_ID
FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric/orgs/$ORG/user
CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
docker exec -e "PEER_HOST=$PEER_HOST" -e "CORE_PEER_ID=$CORE_PEER_ID" -e "CORE_PEER_ADDRESS=$PEER_HOST:7051" -e "CORE_PEER_LOCALMSPID=org1MSP" -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" run peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query", "a"]}'


: << COMMENTBLOCK
# WARNING!
# this block MUST BE RUN within run container
#

function main {
   CHANNEL_NAME=mychannel
   ORG_MSP_ID=org1MSP

   PEER_HOST=peer1-org1
   export CORE_PEER_ID=$PEER_HOST
   export CORE_PEER_ADDRESS=$PEER_HOST:7051
   export CORE_PEER_LOCALMSPID=$ORG_MSP_ID

   export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric/orgs/org1/user
   export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
   peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'
}

main
COMMENTBLOCK

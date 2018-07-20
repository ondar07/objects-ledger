#!/bin/bash
set -e

source $(dirname "$0")/scripts/env.sh

#CHANNEL_NAME="mychannel"
#CHAINCODE_NAME="mycc"
#ORG="org1"
#DOCKER_PEER_CONTAINER="run"
#echo $DOCKER_PEER_CONTAINER
#export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric/orgs/$ORG/user
#export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
#peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query","a"]}'
#docker exec -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" run peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query", "a"]}'

function main {
   # Convert PEER_ORGS to an array named PORGS
   IFS=', ' read -r -a PORGS <<< "$PEER_ORGS"

   # Query chaincode from the 1st peer of the 1st org
   initPeerVars ${PORGS[0]} 1
   switchToUserIdentity
   chaincodeQuery
}

function chaincodeQuery {
   set +e
   logr "Querying chaincode in the channel '$CHANNEL_NAME' on the peer '$PEER_HOST' ..."
   local rc=1
   local starttime=$(date +%s)
   # Continue to poll until we get a successful response or reach QUERY_TIMEOUT
   while test "$(($(date +%s)-starttime))" -lt "$QUERY_TIMEOUT"; do
      sleep 1
      peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >& log.txt
      VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
      echo $VALUE
   done
}

main

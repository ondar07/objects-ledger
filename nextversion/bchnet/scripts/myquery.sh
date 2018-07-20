#!/bin/bash
set -e

CHANNEL_NAME=mychannel
#CHAINCODE_NAME="mycc"
#ORG="org1"
#DOCKER_PEER_CONTAINER="run"
#echo $DOCKER_PEER_CONTAINER
#export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/fabric/orgs/$ORG/user
#export CORE_PEER_MSPCONFIGPATH=$FABRIC_CA_CLIENT_HOME/msp
#peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query","a"]}'
#docker exec -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" run peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query", "a"]}'

# initPeerVars <ORG> <NUM>
function myInitPeerVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initPeerVars <ORG> <NUM>: $*"
      exit 1
   fi
   ORG=$1
   ORG_MSP_ID=${ORG}MSP

   NUM=$2
   PEER_HOST=peer${NUM}-${ORG}
   PEER_NAME=peer${NUM}-${ORG}
   MYHOME=/opt/gopath/src/github.com/hyperledger/fabric/peer

   export FABRIC_CA_CLIENT=$MYHOME
   export CORE_PEER_ID=$PEER_HOST
   export CORE_PEER_ADDRESS=$PEER_HOST:7051
   export CORE_PEER_LOCALMSPID=$ORG_MSP_ID
   #export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
   # the following setting starts chaincode containers on the same
   # bridge network as the peers
   # https://docs.docker.com/compose/networking/
   #export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${COMPOSE_PROJECT_NAME}_${NETWORK}
   #export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=net_${NETWORK}
   export CORE_LOGGING_LEVEL=DEBUG
   #export CORE_PEER_TLS_ENABLED=false
   #export CORE_PEER_PROFILE_ENABLED=true
   # gossip variables
   #export CORE_PEER_GOSSIP_USELEADERELECTION=true
   #export CORE_PEER_GOSSIP_ORGLEADER=false
   #export CORE_PEER_GOSSIP_EXTERNALENDPOINT=$PEER_HOST:7051
   #if [ $NUM -gt 1 ]; then
   #   # Point the non-anchor peers to the anchor peer, which is always the 1st peer
   #   export CORE_PEER_GOSSIP_BOOTSTRAP=peer1-${ORG}:7051
   #fi
}

function main {
   # Query chaincode from the 1st peer of the 1st org
   #myInitPeerVars org1 1
   #ORG=org1
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

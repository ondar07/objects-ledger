#!/bin/bash

#
# This script does the following:
# 1) registers orderer and peer identities with intermediate fabric-ca-servers
# 2) Builds the channel artifacts (e.g. genesis block, etc)
#

function main {
   log "Beginning building channel artifacts ..."
   registerIdentities
   getCACerts
   makeConfigTxYaml
   generateChannelArtifacts
   log "Finished building channel artifacts"
   touch /$SETUP_SUCCESS_FILE
}

# Enroll the CA administrator
function enrollCAAdmin {
    # из-за того, что (см. env.sh USE_INTERMEDIATE_CA=true) используем interm ca,
    # то $CA_NAME=$INT_CA_NAME (например, ica-org0)
   waitPort "$CA_NAME to start" 90 $CA_LOGFILE $CA_HOST 7054
   log "Enrolling with $CA_NAME as bootstrap identity ..."
   export FABRIC_CA_CLIENT_HOME=$HOME/cas/$CA_NAME
   #export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
   # $CA_ADMIN_USER_PASS=$INT_CA_ADMIN_USER_PASS (ica-org0-admin:ica-org0-adminpw)
   # $CA_HOST=$INT_CA_HOST (ica-org0)
   #fabric-ca-client enroll -d -u https://$CA_ADMIN_USER_PASS@$CA_HOST:7054
   fabric-ca-client enroll -d -u http://$CA_ADMIN_USER_PASS@$CA_HOST:7054
}

function registerIdentities {
   log "Registering identities ..."
   registerOrdererIdentities
   registerPeerIdentities
}

# Register any identities associated with the orderer
# эта функция похожа на registerPeerIdentities.
# только в данном примере у нас $ORDERER_ORGS="org0" (т.е. 1 orderer)
function registerOrdererIdentities {
   for ORG in $ORDERER_ORGS; do
      # $ORG="org0"
      initOrgVars $ORG
      enrollCAAdmin
      local COUNT=1
      while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
         initOrdererVars $ORG $COUNT
         log "Registering $ORDERER_NAME with $CA_NAME"
         fabric-ca-client register -d --id.name $ORDERER_NAME --id.secret $ORDERER_PASS --id.type orderer
         COUNT=$((COUNT+1))
      done
      log "Registering admin identity with $CA_NAME"
      # The admin identity has the "admin" attribute which is added to ECert by default
      fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "admin=true:ecert"
   done
}

# Register any identities associated with a peer
# для каждой org эта функция 1) enroll-ит bootstrap identity (bootstrap admin) для каждой ica (ica-org1, ica-org2)
# 2) регистрирует в ica-org1/ica-org2 peer сущность (peer1, peer2, если 2 пира)
# 3) регистрирует в ica-org1/ica-org2 одного admin-org1/admin-org2 сущность (это не bootstrap admin)
# 4) регистрирует в ica-org1/ica-org2 одного юзера user-org1/user-org2
function registerPeerIdentities {
   # $PEER_ORGS="org1 org2" -- names of the peer organizations
   for ORG in $PEER_ORGS; do
      initOrgVars $ORG
      # enroll intermediate ca bootstrap admin
      enrollCAAdmin
      local COUNT=1
      while [[ "$COUNT" -le $NUM_PEERS ]]; do
         initPeerVars $ORG $COUNT
         log "Registering $PEER_NAME with $CA_NAME"
         fabric-ca-client register -d --id.name $PEER_NAME --id.secret $PEER_PASS --id.type peer
         COUNT=$((COUNT+1))
      done
      log "Registering admin identity with $CA_NAME"
      # The admin identity has the "admin" attribute which is added to ECert by default
      # Это ОТДЕЛЬНЫЙ admin identity (наверху мы enroll-или bootstrap identity для ica)
      # $ADMIN_NAME=admin-org1 или admin-org2 (см. env.sh)
      fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs '"hf.Registrar.Roles=client,user",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert'
      log "Registering user identity with $CA_NAME"
      fabric-ca-client register -d --id.name $USER_NAME --id.secret $USER_PASS
   done
}

function getCACerts {
   log "Getting CA certificates ..."
   # $ORGS="org0", "org1", "org2"
   for ORG in $ORGS; do
      initOrgVars $ORG
      # $ORG_MSP_DIR=./${DATA}/orgs/${ORG}/msp
      log "Getting CA certs for organization $ORG and storing in $ORG_MSP_DIR"
      # $CA_CHAINFILE=$INT_CA_CHAINFILE=/${DATA}/${ORG}-ca-chain.pem
      # Subject: C = US, ST = North Carolina, O = Hyperledger, OU = client, CN = rca-org1-admin <-- это из org1-ca-chain.pem
      # т.к. rca-org1-admin -- bootstrap identity (так и identity для ica), org1-ca-chain.pem -- все правильно,
      # это цепочка сертов от rca до ica
      #export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
      # опция "-M" позволяет сохранить cert chain в $ORG_MSP_DIR
      # команда getcacert, в общем, позволяет все файлы сервера (которые лежат рядом с server home (при старте fabric-ca-server))
      # (к таким файлам относится серт админа, серт самого сервера и пр.)
      # получить от сервера и сохранить в локальном msp (в локальном для клиента)
      fabric-ca-client getcacert -d -u http://$CA_HOST:7054 -M $ORG_MSP_DIR
      # создаем tlscerts, tlsintermediatecerts директории, если такие еще не существуют
      finishMSPSetup $ORG_MSP_DIR
      # If ADMINCERTS is true, we need to enroll the admin now to populate (заполнить) the admincerts directory
      # у нас $ADMINCERTS=true (см. env.sh)
      # если bootstrap admin of ica (admin-org1, например) не за-enroll-ен, то enroll
      # создаются директории admincerts/
      if [ $ADMINCERTS ]; then
         switchToAdminIdentity
      fi
   done
}

# printOrg
function printOrg {
   echo "
  - &$ORG_CONTAINER_NAME

    Name: $ORG

    # ID to load the MSP definition as
    ID: $ORG_MSP_ID

    # MSPDir is the filesystem path which contains the MSP configuration
    MSPDir: $ORG_MSP_DIR"
}

# printOrdererOrg <ORG>
function printOrdererOrg {
   initOrgVars $1
   printOrg
}

# printPeerOrg <ORG> <COUNT>
function printPeerOrg {
   initPeerVars $1 $2
   printOrg
   echo "
    AnchorPeers:
       # AnchorPeers defines the location of peers which can be used
       # for cross org gossip communication.  Note, this value is only
       # encoded in the genesis block in the Application section context
       - Host: $PEER_HOST
         Port: 7051"
}

function makeConfigTxYaml {
   {
   echo "################################################################################
#
#   Profile
#
#   - Different configuration profiles may be encoded here to be specified
#   as parameters to the configtxgen tool
#
################################################################################
Profiles:

  OrgsOrdererGenesis:
    Orderer:
      # Orderer Type: The orderer implementation to start
      # Available types are \"solo\" and \"kafka\"
      OrdererType: solo
      Addresses:"

   for ORG in $ORDERER_ORGS; do
      local COUNT=1
      while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
         initOrdererVars $ORG $COUNT
         echo "        - $ORDERER_HOST:7050"
         COUNT=$((COUNT+1))
      done
   done

   echo "
      # Batch Timeout: The amount of time to wait before creating a batch
      BatchTimeout: 2s

      # Batch Size: Controls the number of messages batched into a block
      BatchSize:

        # Max Message Count: The maximum number of messages to permit in a batch
        MaxMessageCount: 10

        # Absolute Max Bytes: The absolute maximum number of bytes allowed for
        # the serialized messages in a batch.
        AbsoluteMaxBytes: 99 MB

        # Preferred Max Bytes: The preferred maximum number of bytes allowed for
        # the serialized messages in a batch. A message larger than the preferred
        # max bytes will result in a batch larger than preferred max bytes.
        PreferredMaxBytes: 512 KB

      Kafka:
        # Brokers: A list of Kafka brokers to which the orderer connects
        # NOTE: Use IP:port notation
        Brokers:
          - 127.0.0.1:9092

      # Organizations is the list of orgs which are defined as participants on
      # the orderer side of the network
      Organizations:"

   for ORG in $ORDERER_ORGS; do
      initOrgVars $ORG
      echo "        - *${ORG_CONTAINER_NAME}"
   done

   echo "
    Consortiums:

      SampleConsortium:

        Organizations:"

   for ORG in $PEER_ORGS; do
      initOrgVars $ORG
      echo "          - *${ORG_CONTAINER_NAME}"
   done

   echo "
  OrgsChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:"

   for ORG in $PEER_ORGS; do
      initOrgVars $ORG
      echo "        - *${ORG_CONTAINER_NAME}"
   done

   echo "
################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:"

   for ORG in $ORDERER_ORGS; do
      printOrdererOrg $ORG
   done

   for ORG in $PEER_ORGS; do
      printPeerOrg $ORG 1
   done

   echo "
################################################################################
#
#   SECTION: Application
#
#   This section defines the values to encode into a config transaction or
#   genesis block for application related parameters
#
################################################################################
Application: &ApplicationDefaults

    # Organizations is the list of orgs which are defined as participants on
    # the application side of the network
    Organizations:
"

   } > /etc/hyperledger/fabric/configtx.yaml
   # Copy it to the data directory to make debugging easier
   cp /etc/hyperledger/fabric/configtx.yaml /$DATA
}

function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatal "configtxgen tool not found. exiting"
  fi

  log "Generating orderer genesis block at $GENESIS_BLOCK_FILE"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  configtxgen -profile OrgsOrdererGenesis -outputBlock $GENESIS_BLOCK_FILE
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate orderer genesis block"
  fi

  log "Generating channel configuration transaction at $CHANNEL_TX_FILE"
  configtxgen -profile OrgsChannel -outputCreateChannelTx $CHANNEL_TX_FILE -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate channel configuration transaction"
  fi

  for ORG in $PEER_ORGS; do
     initOrgVars $ORG
     log "Generating anchor peer update transaction for $ORG at $ANCHOR_TX_FILE"
     configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $ANCHOR_TX_FILE \
                 -channelID $CHANNEL_NAME -asOrg $ORG
     if [ "$?" -ne 0 ]; then
        fatal "Failed to generate anchor peer update for $ORG"
     fi
  done
}

set -e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main

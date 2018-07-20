#!/bin/bash

set -e

# the current dir (Source DIR)
SDIR=$(dirname "$0")
source ${SDIR}/scripts/env.sh

cd ${SDIR}

# Delete docker containers
dockerContainers=$(docker ps -a | awk '$2~/hyperledger/ {print $1}')
if [ "$dockerContainers" != "" ]; then
   log "Deleting existing docker containers ..."
   docker rm -f $dockerContainers > /dev/null
fi

# Remove chaincode docker images
chaincodeImages=`docker images | grep "^dev-peer" | awk '{print $3}'`
if [ "$chaincodeImages" != "" ]; then
   log "Removing chaincode docker images ..."
   docker rmi -f $chaincodeImages > /dev/null
fi

# Start with a clean data directory
DDIR=${SDIR}/${DATA}
if [ -d ${DDIR} ]; then
   log "Cleaning up the data directory from previous run at $DDIR"
   rm -rf ${SDIR}/data
fi
mkdir -p ${DDIR}/logs

# Create the docker-compose file
${SDIR}/makeDocker.sh

# Create the docker containers
log "Creating docker containers ..."
docker-compose up -d

#exit 0

# Wait for the setup container to complete
dowait "the 'setup' container to finish registering identities, creating the genesis block and other artifacts" 90 $SDIR/$SETUP_LOGFILE $SDIR/$SETUP_SUCCESS_FILE

# Wait for the run container to start and then tails it's summary log
dowait "the docker 'run' container to start" 60 ${SDIR}/${SETUP_LOGFILE} ${SDIR}/${RUN_SUMFILE}
# команда tail:
#    При использовании специального ключа -f утилита tail следит за файлом:
#    новые строки (добавляемые в конец файла другим процессом) автоматически выводятся на экран в реальном времени
#    & -- для запуска этой команды в фоновом режиме
#    $SDIR/RUN_SUMFILE -- ./data/logs/run.sum
# т.е. вывод работы конейнера run будет, на самом деле, транслироваться из файла ./data/logs/run.sum
tail -f ${SDIR}/${RUN_SUMFILE}&
TAIL_PID=$!

# Wait for the run container to complete
while true; do 
   # если появился файл $RUN_SUCCESS_FILE, то убиваем процесс tail (см. выше) и выходим из скрипта со статусом 0
   # если появился $RUN_FAIL_FILE, то убиваем процесс, и выходим из скрипта со статусом 1
   # иначе спим еще 1 секунду (ждем 1 секунду)
   if [ -f ${SDIR}/${RUN_SUCCESS_FILE} ]; then
      kill -9 $TAIL_PID
      exit 0
      echo "ALL is OK!!!"
   elif [ -f ${SDIR}/${RUN_FAIL_FILE} ]; then
      kill -9 $TAIL_PID
      exit 1
      echo "FAIL!!!"
   else
      sleep 1
   fi
done

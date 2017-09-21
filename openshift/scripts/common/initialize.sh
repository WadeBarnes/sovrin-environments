#!/bin/bash

if [ ! -z "${SOVRINNODE1_SERVICE_HOST}" ]; then 
  echo ===============================================================================
  echo "Configuring OpenShift environment ..."
  echo "Changing;"
  echo -e "\tNODE_IP_LIST: ${NODE_IP_LIST}"
  export NODE_IP_LIST=${SOVRINNODE1_SERVICE_HOST},${SOVRINNODE2_SERVICE_HOST},${SOVRINNODE3_SERVICE_HOST},${SOVRINNODE4_SERVICE_HOST}
  echo -e "\tto"
  echo -e "\tNODE_IP_LIST: ${NODE_IP_LIST}"
  echo ===============================================================================
  echo
fi

if [ ! -z "${NODE_NAME}" ] && [ ! -z "${NODE_PORT}" ] && [ ! -z "${CLIENT_PORT}" ]; then 
  echo ===============================================================================
  echo "Initializing sovrin node:"
  echo -e "\tName: ${NODE_NAME}"
  echo -e "\tNode Port: ${NODE_PORT}"
  echo -e "\tClient Port: ${CLIENT_PORT}"
  echo -------------------------------------------------------------------------------
  init_sovrin_node ${NODE_NAME} ${NODE_PORT} ${CLIENT_PORT}
  echo ===============================================================================
  echo
fi 

if [ ! -z "${NODE_COUNT}" ] && [ ! -z "${CLIENT_COUNT}" ] && [ ! -z "${NODE_NUMBER}" ] && [ ! -z "${NODE_IP_LIST}" ]; then 
  echo ===============================================================================
  echo "Generating sovrin pool transactions for sovrin node:"
  echo -e "\tNode Count: ${NODE_COUNT}"
  echo -e "\tClient Count: ${CLIENT_COUNT}"
  echo -e "\tNode Number: ${NODE_NUMBER}"
  echo -e "\tNode IP Address List: ${NODE_IP_LIST}"
  echo -------------------------------------------------------------------------------
  generate_sovrin_pool_transactions --nodes ${NODE_COUNT} --clients ${CLIENT_COUNT} --nodeNum ${NODE_NUMBER} --ips "${NODE_IP_LIST}"; 
  echo ===============================================================================
  echo
fi

if [ -z "${NODE_NUMBER}" ] && [ ! -z "${AGENT_NAME}" ] &&[ ! -z "${NODE_COUNT}" ] && [ ! -z "${CLIENT_COUNT}" ] && [ ! -z "${NODE_IP_LIST}" ]; then 
  echo ===============================================================================
  echo "Generating sovrin pool transactions for agent node:"
  echo -e "\tAgent Name: ${AGENT_NAME}"
  echo -e "\tNode Count: ${NODE_COUNT}"
  echo -e "\tClient Count: ${CLIENT_COUNT}"
  echo -e "\tNode IP Address List: ${NODE_IP_LIST}"
  echo -------------------------------------------------------------------------------
  generate_sovrin_pool_transactions --nodes ${NODE_COUNT} --clients ${CLIENT_COUNT} --ips "${NODE_IP_LIST}"; 
  echo ===============================================================================
  echo
fi

if [ -z "${NODE_NUMBER}" ] && [ -z "${AGENT_NAME}" ] &&[ ! -z "${NODE_COUNT}" ] && [ ! -z "${CLIENT_COUNT}" ] && [ ! -z "${NODE_IP_LIST}" ]; then 
  echo ===============================================================================
  echo "Generating sovrin pool transactions for client node:"
  echo -e "\tNode Count: ${NODE_COUNT}"
  echo -e "\tClient Count: ${CLIENT_COUNT}"
  echo -e "\tNode IP Address List: ${NODE_IP_LIST}"
  echo -------------------------------------------------------------------------------
  generate_sovrin_pool_transactions --nodes ${NODE_COUNT} --clients ${CLIENT_COUNT} --ips "${NODE_IP_LIST}"; 
  echo ===============================================================================
  echo
fi
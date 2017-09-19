#!/bin/bash

if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    #echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default}:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi

echo ===============================================================================
echo "Initializing sovrin node:"
echo -e "\tName: ${NODE_NAME}"
echo -e "\tNode Port: ${NODE_PORT}"
echo -e "\tClient Port: ${CLIENT_PORT}"
echo -------------------------------------------------------------------------------
init_sovrin_node ${NODE_NAME} ${NODE_PORT} ${CLIENT_PORT}
echo ===============================================================================
echo

if [ ! -z "${NODE_COUNT}" ] && [ ! -z "${CLIENT_COUNT}" ] && [ ! -z "${NODE_NUMBER}" ] && [ ! -z "${NODE_IP_LIST}" ]; then 
  echo ===============================================================================
  echo "Generating sovrin pool transactions:"
  echo -e "\tNode Count: ${NODE_COUNT}"
  echo -e "\tClient Count: ${CLIENT_COUNT}"
  echo -e "\tNode Number: ${NODE_NUMBER}"
  echo -e "\tNode IP Address List: ${NODE_IP_LIST}"
  echo -------------------------------------------------------------------------------
  generate_sovrin_pool_transactions --nodes ${NODE_COUNT} --clients ${CLIENT_COUNT} --nodeNum ${NODE_NUMBER} --ips "${NODE_IP_LIST}"; 
  echo ===============================================================================
  echo
fi

# echo "Setting the file and folder permissions for the sovrin environment and configuration files ..."
# chown -R sovrin:root /home/sovrin
# chgrp -R 0 /home/sovrin
# chmod -R g+rwX /home/sovrin

echo "Starting sovrin node ..."
exec /sbin/init --log-target=journal 3>&1

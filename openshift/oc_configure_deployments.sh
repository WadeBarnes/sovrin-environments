#!/bin/bash

# =====================================================================================
# Script for setting up the deployment environment for the Alice example in OpenShift
#
# * Requires the OpenShift Origin CLI
# -------------------------------------------------------------------------------------
#
# Usage on Windows:
#  
#  MSYS_NO_PATHCONV=1 ./oc_configure_deployments.sh
#
# -------------------------------------------------------------------------------------
#
# ToDo:
# * Parameterize.
# * Add support for create or update.
#
# =====================================================================================

USER_ID="$(id -u)"
SCRIPT_DIR=$(dirname $0)
TEMPLATE_DIR="templates"

ProjectName="myproject"
DeploymentConfigTemplate="${SCRIPT_DIR}/${TEMPLATE_DIR}/deploymentConfig.json"

DeploymentConfigPostfix="_DeploymentConfig.json"
SovrinNodeDeploymentConfigNameBase="sovrinNode"
SovrinClientDeploymentConfig="sovrinClient${DeploymentConfigPostfix}"

SovrinClientName="sovrinclient"
SovrinNodeName="sovrinnode"
SovrinHomeDirectory="/home/sovrin"

ImageTag="latest"

if [ -z "$POOL_DATA_FILE" ]; then
	POOL_DATA_FILE="pool_data"
fi

if [ -z "$CLIENT_COUNT" ]; then
  CLIENT_COUNT=10
fi

echo "============================================================================="
echo "Switching to project ${ProjectName} ..."
echo "============================================================================"
oc project ${ProjectName}
echo 

echo "============================================================================="
echo "Deleting previous deployment configuration files ..."
echo "============================================================================="
for file in *${DeploymentConfigPostfix}; do 
	rm -rf ${file};
done
echo

echo "============================================================================="
echo "Generating deployment configuration files ..."
echo "============================================================================="
echo

# ===========================================================================
# Sovin Node Deployment Configurations
# ---------------------------------------------------------------------------
# ToDo:
# * Clean this up.
# ===========================================================================
echo "Reading pool data ..."
read -r POOL_DATA < $POOL_DATA_FILE
ORIGINAL_IFS=$IFS
IFS=","
POOL_DATA=($POOL_DATA)

echo "Parsing pool data ..."
NODE_IP_LIST=""
NODE_COUNT=${#POOL_DATA[@]}

for NODE_DATA in "${POOL_DATA[@]}"; do
	IFS=" "
	NODE_DATA_ARRAY=(${NODE_DATA})
	NODE_IP=${NODE_DATA_ARRAY[1]}
	NODE_IP_LIST="${NODE_IP_LIST},${NODE_IP}"	
done
NODE_IP_LIST="${NODE_IP_LIST:1}"

for NODE_DATA in "${POOL_DATA[@]}"; do
	IFS=" "
	NODE_DATA_ARRAY=(${NODE_DATA})
	SOVRIN_NODE_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${NODE_DATA_ARRAY:0:1})${NODE_DATA_ARRAY:1}"
	NODE_NUMBER="${SOVRIN_NODE_NAME:(-1)}"
	NODE_IP=${NODE_DATA_ARRAY[1]}
	NODE_PORT=${NODE_DATA_ARRAY[2]}
	CLIENT_PORT=${NODE_DATA_ARRAY[3]}
	
	echo "------------------------------------------------------------------------"
	echo "Parsed pool data for ${SOVRIN_NODE_NAME} ..."
	echo "------------------------------------------------------------------------"
	echo "NODE_DATA=${NODE_DATA}"
	echo "SOVRIN_NODE_NAME=${SOVRIN_NODE_NAME}"
	echo "NODE_NUMBER=${NODE_NUMBER}"
	echo "NODE_IP=${NODE_IP}"
	echo "NODE_PORT=${NODE_PORT}"
	echo "CLIENT_PORT=${CLIENT_PORT}"
	echo "NODE_IP_LIST=${NODE_IP_LIST}"
	echo "------------------------------------------------------------------------"
	echo
	
	
	SovrinNodeApplicationName="${SovrinNodeName}${NODE_NUMBER}"
	SovrinNodeDeploymentConfig="${SovrinNodeDeploymentConfigNameBase}${NODE_NUMBER}${DeploymentConfigPostfix}"
	ServiceDescription="Exposes and load balances the pods for ${SOVRIN_NODE_NAME}."
	ApplicationHostName=""
	ImageNamespace=""
	
	echo "------------------------------------------------------------------------"
	echo "Generating deployment configuration file for ${SOVRIN_NODE_NAME} ..."
	echo "------------------------------------------------------------------------"
	echo "Template=${DeploymentConfigTemplate}"
	echo "APPLICATION_NAME=${SovrinNodeApplicationName}"
	echo "APPLICATION_SERVICE_DESCRIPTION=${ServiceDescription}"
	echo "APPLICATION_HOSTNAME=${ApplicationHostName}"
	echo "SOURCE_IMAGE_NAME=${SovrinNodeName}"
	echo "IMAGE_NAMESPACE=${ImageNamespace}"
	echo "DEPLOYMENT_TAG=${ImageTag}"
	echo "NODE_NAME=${SOVRIN_NODE_NAME}"
	echo "NODE_NUMBER=${NODE_NUMBER}"
	echo "NODE_PORT=${NODE_PORT}"
	echo "CLIENT_PORT=${CLIENT_PORT}"
	echo "NODE_IP_LIST=${NODE_IP_LIST}"
	echo "NODE_COUNT=${NODE_COUNT}"
	echo "CLIENT_COUNT=${CLIENT_COUNT}"
	echo "HOME_DIR=${SovrinHomeDirectory}"	
	echo "Output File=${SovrinNodeDeploymentConfig}"
	echo "------------------------------------------------------------------------"
	echo
	
	oc process \
	-f ${DeploymentConfigTemplate} \
	-p APPLICATION_NAME=${SovrinNodeApplicationName} \
	-p APPLICATION_SERVICE_DESCRIPTION="${ServiceDescription}" \
	-p APPLICATION_HOSTNAME=${ApplicationHostName} \
	-p SOURCE_IMAGE_NAME=${SovrinNodeName} \
	-p IMAGE_NAMESPACE=${ImageNamespace} \
	-p DEPLOYMENT_TAG=${ImageTag} \
	-p NODE_NAME=${SOVRIN_NODE_NAME} \
	-p NODE_NUMBER=${NODE_NUMBER} \
	-p NODE_PORT=${NODE_PORT} \
	-p CLIENT_PORT=${CLIENT_PORT} \
	-p NODE_IP_LIST=${NODE_IP_LIST} \
	-p NODE_COUNT=${NODE_COUNT} \
	-p CLIENT_COUNT=${CLIENT_COUNT} \
	-p HOME_DIR=${SovrinHomeDirectory} \
	> ${SovrinNodeDeploymentConfig}
	echo "Generated ${SovrinNodeDeploymentConfig} ..."
	echo	
done
# ===========================================================================

# ===========================================================================
# Sovin Client Deployment Configuration
# ---------------------------------------------------------------------------
# ToDo:
# * Clean this up.
# ===========================================================================

ServiceDescription="Exposes and load balances the pods for ${SovrinClientName}."
ApplicationHostName=""
ImageNamespace=""

echo "------------------------------------------------------------------------"
echo "Generating deploytment configuration file for ${SovrinClientName} ..."
echo "------------------------------------------------------------------------"
echo "Template=${DeploymentConfigTemplate}"
echo "APPLICATION_NAME=${SovrinClientName}"
echo "APPLICATION_SERVICE_DESCRIPTION=${ServiceDescription}"
echo "APPLICATION_HOSTNAME=${ApplicationHostName}"
echo "SOURCE_IMAGE_NAME=${SovrinClientName}"
echo "IMAGE_NAMESPACE=${ImageNamespace}"
echo "DEPLOYMENT_TAG=${ImageTag}"
echo "NODE_IP_LIST=${NODE_IP_LIST}"
echo "NODE_COUNT=${NODE_COUNT}"
echo "CLIENT_COUNT=${CLIENT_COUNT}"
echo "HOME_DIR=${SovrinHomeDirectory}"	
echo "Output File=${SovrinClientDeploymentConfig}"
echo "------------------------------------------------------------------------"
echo

oc process \
-f ${DeploymentConfigTemplate} \
-p APPLICATION_NAME=${SovrinClientName} \
-p APPLICATION_SERVICE_DESCRIPTION="${ServiceDescription}" \
-p APPLICATION_HOSTNAME=${ApplicationHostName} \
-p SOURCE_IMAGE_NAME=${SovrinClientName} \
-p IMAGE_NAMESPACE=${ImageNamespace} \
-p DEPLOYMENT_TAG=${ImageTag} \
-p NODE_IP_LIST=${NODE_IP_LIST} \
-p NODE_COUNT=${NODE_COUNT} \
-p CLIENT_COUNT=${CLIENT_COUNT} \
-p HOME_DIR=${SovrinHomeDirectory} \
> ${SovrinClientDeploymentConfig}
echo "Generated ${SovrinClientDeploymentConfig} ..."
echo	
# ===========================================================================

echo "============================================================================="
echo "Cleaning out all existing OpenShift resources ..."
echo "============================================================================"
oc delete routes,services,dc --all
echo

echo "============================================================================="
echo "Creating deployment configurations in OpenShift project; ${ProjectName} ..."
echo "============================================================================="
for file in *${DeploymentConfigPostfix}; do 
	echo "Loading ${file} ...";
	oc create -f ${file};
	echo;
done
echo

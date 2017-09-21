#!/bin/bash

# ==============================================================================
# Script for setting up the build environment for the Alice example in OpenShift
#
# * Requires the OpenShift Origin CLI
# ------------------------------------------------------------------------------
#
# Usage on Windows:
#  
#  MSYS_NO_PATHCONV=1 ./oc_configure_builds.sh
#
# ------------------------------------------------------------------------------
#
# ToDo:
# * Parameterize.
# * Add support for create or update.
#
# ==============================================================================

USER_ID="$(id -u)"
SCRIPT_DIR=$(dirname $0)
TEMPLATE_DIR="templates"

ProjectName="myproject"
BuildConfigTemplate="${SCRIPT_DIR}/${TEMPLATE_DIR}/buildConfig.json"

BuildConfigPostfix="_BuildConfig.json"
SovrinBaseBuildConfig="sovrinBase${BuildConfigPostfix}"
SovrinCoreBuildConfig="sovrinCore${BuildConfigPostfix}"
SovrinNodeBuildConfig="sovrinNode${BuildConfigPostfix}"
SovrinClientBuildConfig="sovrinClient${BuildConfigPostfix}"
SovrinAgentBuildConfig="sovrinAgent${BuildConfigPostfix}"

SovrinBaseDockerFile="base.systemd.ubuntu.dockerfile"
SovrinCoreDockerFile="core.ubuntu.dockerfile"
SovrinNodeDockerFile="node.init.ubuntu.dockerfile"
SovrinClientDockerFile="client.ubuntu.dockerfile"
SovrinAgentDockerFile="agent.ubuntu.dockerfile"

SovrinBaseName="sovrinbase"
SovrinCoreName="sovrincore"
SovrinNodeName="sovrinnode"
SovrinClientName="sovrinclient"
SovrinAgentName="sovrinagent"

SovrinAgentInstanceName="Faber"
SovrinAgentInstancePort="5555"

SovrinBaseSourceImageKind="DockerImage"
SovrinCoreSourceImageKind="ImageStreamTag"
SovrinNodeSourceImageKind="ImageStreamTag"
SovrinClientSourceImageKind="ImageStreamTag"
SovrinAgentSourceImageKind="ImageStreamTag"

SovrinBaseSourceImageName="solita/ubuntu-systemd"
SovrinCoreSourceImageName="sovrinbase"
SovrinNodeSourceImageName="sovrincore"
SovrinClientSourceImageName="sovrincore"
SovrinAgentSourceImageName="sovrincore"

OutputImageTag="latest"
SovrinBaseSourceImageTag="16.04"
SovrinCoreSourceImageTag="${OutputImageTag}"
SovrinNodeSourceImageTag="${OutputImageTag}"
SovrinClientSourceImageTag="${OutputImageTag}"
SovrinAgentSourceImageTag="${OutputImageTag}"

GitRef="OpenShift"
GitUri="https://github.com/WadeBarnes/sovrin-environments.git"
GitContextDir="openshift"

echo "============================================================================="
echo "Switching to project ${ProjectName} ..."
echo "============================================================================"
oc project ${ProjectName}
echo 

echo "============================================================================="
echo "Deleting previous build configuration files ..."
echo "============================================================================="
for file in *_BuildConfig.json; do 
	rm -rf ${file};
done
echo

echo "============================================================================="
echo "Generating build configuration files ..."
echo "============================================================================="
echo

# Sovrin Base Image
oc process \
-f ${BuildConfigTemplate} \
-p BUILD_NAME=${SovrinBaseName} \
-p SOURCE_IMAGE_KIND=${SovrinBaseSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinBaseSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinBaseSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinBaseDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${SovrinBaseName} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
> ${SovrinBaseBuildConfig}
echo "Generated ${SovrinBaseBuildConfig} ..."
echo

# Sovrin Core Image
oc process \
-f ${BuildConfigTemplate} \
-p BUILD_NAME=${SovrinCoreName} \
-p SOURCE_IMAGE_KIND=${SovrinCoreSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinCoreSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinCoreSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinCoreDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${SovrinCoreName} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
> ${SovrinCoreBuildConfig}
echo "Generated ${SovrinCoreBuildConfig} ..."
echo

# ===========================================================================
# Generate pool data
# ---------------------------------------------------------------------------
# ToDo:
# * Clean this up.
# ===========================================================================
BASE_NODE_NAME="Node"

if [ -z "$BASE_IP" ]; then
  BASE_IP="10.0.0."
fi

if [ -z "$NODE_COUNT" ]; then
  NODE_COUNT=4
fi

if [ -z "$CLIENT_COUNT" ]; then
  CLIENT_COUNT=10
fi

if [ -z "$START_PORT" ]; then
  START_PORT=9701
fi

if [ -z "$NODE_IP_LIST" ]; then
  for i in `seq 1 $NODE_COUNT`; do
    NODE_ADDRESS=$((i+1))
	NODE_IP="${BASE_IP}${NODE_ADDRESS}"
	NODE_IP_LIST="${NODE_IP_LIST},${NODE_IP}"
  done
  NODE_IP_LIST=${NODE_IP_LIST:1}
fi

if [ -z "$POOL_DATA_FILE" ]; then
	POOL_DATA_FILE="pool_data"
fi

echo "Creating pool of ${NODE_COUNT} nodes with ips ${NODE_IP_LIST} ..."
PORT=$START_PORT
ORIGINAL_IFS=$IFS
IFS=','
IPS_ARRAY=($NODE_IP_LIST)
IFS=$ORIGINAL_IFS
for i in `seq 1 $NODE_COUNT`; do
	NODE_NAME="${BASE_NODE_NAME}${i}"
	NODE_PORT=$PORT
	((PORT++))
	CLIENT_PORT=$PORT
	((PORT++))
	SOVRIN_NODE_NAME="$(echo "$NODE_NAME" | tr '[:upper:]' '[:lower:]')"
	POOL_DATA="${POOL_DATA},$SOVRIN_NODE_NAME ${IPS_ARRAY[i-1]} $NODE_PORT $CLIENT_PORT"	
done

POOL_DATA=${POOL_DATA:1}
echo "Writing node pool data to $POOL_DATA_FILE for referance ..."
echo "$POOL_DATA" > $POOL_DATA_FILE
echo "Node pool data created."
echo
# ===========================================================================

# ===========================================================================
# Sovin Node Image
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
NODE_COUNT=${#POOL_DATA[@]}
NODE_DATA=${POOL_DATA[0]}
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
echo "NODE_IP_LIST=${NODE_IP_LIST:1}"
echo "------------------------------------------------------------------------"
echo
IFS=$ORIGINAL_IFS

echo "------------------------------------------------------------------------"
echo "Generating build configuration file for ${SovrinNodeName} ..."
echo "------------------------------------------------------------------------"
echo "Template=${BuildConfigTemplate}"
echo "BUILD_NAME=${SovrinNodeName}"
echo "SOURCE_IMAGE_KIND=${SovrinNodeSourceImageKind}"
echo "SOURCE_IMAGE_NAME=${SovrinNodeSourceImageName}"
echo "SOURCE_IMAGE_TAG=${SovrinNodeSourceImageTag}"
echo "DOCKER_FILE_PATH=${SovrinNodeDockerFile}"
echo "SOURCE_CONTEXT_DIR=${GitContextDir}"
echo "GIT_REF=${GitRef}"
echo "GIT_URI=${GitUri}"
echo "OUTPUT_IMAGE_NAME=${SovrinNodeName}"
echo "OUTPUT_IMAGE_TAG=${OutputImageTag}"
echo "SOVRIN_NODE_NAME=${SOVRIN_NODE_NAME}"
echo "SOVRIN_NODE_PORT=${NODE_PORT}"
echo "SOVRIN_CLIENT_PORT=${CLIENT_PORT}"
echo "SOVRIN_NODE_IP_LIST=${NODE_IP_LIST}"
echo "SOVRIN_NODE_COUNT=${NODE_COUNT}"
echo "SOVRIN_CLIENT_COUNT=${CLIENT_COUNT}"
echo "SOVRIN_NODE_NUMBER=${NODE_NUMBER}"
echo "Output File=${SovrinNodeBuildConfig}"
echo "------------------------------------------------------------------------"

oc process \
-f ${BuildConfigTemplate} \
-p BUILD_NAME=${SovrinNodeName} \
-p SOURCE_IMAGE_KIND=${SovrinNodeSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinNodeSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinNodeSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinNodeDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${SovrinNodeName} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
-p SOVRIN_NODE_NAME=${SOVRIN_NODE_NAME} \
-p SOVRIN_NODE_PORT=${NODE_PORT} \
-p SOVRIN_CLIENT_PORT=${CLIENT_PORT} \
-p SOVRIN_NODE_IP_LIST=${NODE_IP_LIST} \
-p SOVRIN_NODE_COUNT=${NODE_COUNT} \
-p SOVRIN_CLIENT_COUNT=${CLIENT_COUNT} \
-p SOVRIN_NODE_NUMBER=${NODE_NUMBER} \
> ${SovrinNodeBuildConfig}
echo "Generated ${SovrinNodeBuildConfig} ..."
echo		
# ===========================================================================

# ===========================================================================
# Sovin Client Image
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
LAST_NODE_IP=""
for NODE_DATA in "${POOL_DATA[@]}"; do
	IFS=" "
	NODE_DATA_ARRAY=(${NODE_DATA})
	SOVRIN_NODE_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${NODE_DATA_ARRAY:0:1})${NODE_DATA_ARRAY:1}"
	NODE_IP=${NODE_DATA_ARRAY[1]}
	NODE_PORT=${NODE_DATA_ARRAY[2]}
	CLIENT_PORT=${NODE_DATA_ARRAY[3]}
	LAST_NODE_IP=${NODE_IP}
	NODE_IP_LIST="${NODE_IP_LIST},${NODE_IP}"

	echo "------------------------------------------------------------------------"
	echo "Parsed pool data for ${SOVRIN_NODE_NAME} ..."
	echo "------------------------------------------------------------------------"
	echo "NODE_DATA=${NODE_DATA}"
	echo "SOVRIN_NODE_NAME=${SOVRIN_NODE_NAME}"
	echo "NODE_IP=${NODE_IP}"
	echo "NODE_PORT=${NODE_PORT}"
	echo "CLIENT_PORT=${CLIENT_PORT}"
	echo "LAST_NODE_IP=${LAST_NODE_IP}"
	echo "NODE_IP_LIST=${NODE_IP_LIST:1}"
	echo "------------------------------------------------------------------------"
	echo
done

NODE_IP_LIST=${NODE_IP_LIST:1}
IFS=$ORIGINAL_IFS

if [ -z "$CLIENT_IP" ]; then
	IP_REGEXP="([0-9]+\\.[0-9]+\\.[0-9]+\\.)([0-9]+)"
	BASE_IP=$(echo "$LAST_NODE_IP" | sed -r "s/${IP_REGEXP}/\1/")
	LAST_GROUP=$(echo "$LAST_NODE_IP" | sed -r "s/${IP_REGEXP}/\2/")
	((LAST_GROUP++))
	CLIENT_IP="${BASE_IP}${LAST_GROUP}"
fi

echo "Node count is ${NODE_COUNT}"
echo "Node IP addresses are ${NODE_IP_LIST}"
echo "Client IP is ${CLIENT_IP}"

echo "------------------------------------------------------------------------"
echo "Generating build configuration file for ${SovrinClientName} ..."
echo "------------------------------------------------------------------------"
echo "Template=${BuildConfigTemplate}"
echo "BUILD_NAME=${SovrinClientName}"
echo "SOURCE_IMAGE_KIND=${SovrinClientSourceImageKind}"
echo "SOURCE_IMAGE_NAME=${SovrinClientSourceImageName}"
echo "SOURCE_IMAGE_TAG=${SovrinClientSourceImageTag}"
echo "DOCKER_FILE_PATH=${SovrinClientDockerFile}"
echo "SOURCE_CONTEXT_DIR=${GitContextDir}"
echo "GIT_REF=${GitRef}"
echo "GIT_URI=${GitUri}"
echo "OUTPUT_IMAGE_NAME=${SovrinClientName}"
echo "OUTPUT_IMAGE_TAG=${OutputImageTag}"
echo "SOVRIN_NODE_IP_LIST=${NODE_IP_LIST}"
echo "SOVRIN_NODE_COUNT=${NODE_COUNT}"
echo "SOVRIN_CLIENT_COUNT=${CLIENT_COUNT}"
echo "Output File=${SovrinClientBuildConfig}"
echo "------------------------------------------------------------------------"

oc process \
-f ${BuildConfigTemplate} \
-p BUILD_NAME=${SovrinClientName} \
-p SOURCE_IMAGE_KIND=${SovrinClientSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinClientSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinClientSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinClientDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${SovrinClientName} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
-p SOVRIN_NODE_IP_LIST=${NODE_IP_LIST} \
-p SOVRIN_NODE_COUNT=${NODE_COUNT} \
-p SOVRIN_CLIENT_COUNT=${CLIENT_COUNT} \
> ${SovrinClientBuildConfig}
echo "Generated ${SovrinClientBuildConfig} ..."
echo
# ===========================================================================

# ===========================================================================
# Sovin Agent Image
# ---------------------------------------------------------------------------
# ToDo:
# * Clean this up.
# ===========================================================================
echo "------------------------------------------------------------------------"
echo "Generating build configuration file for ${SovrinAgentName} ..."
echo "------------------------------------------------------------------------"
echo "Template=${BuildConfigTemplate}"
echo "BUILD_NAME=${SovrinAgentName}"
echo "SOURCE_IMAGE_KIND=${SovrinAgentSourceImageKind}"
echo "SOURCE_IMAGE_NAME=${SovrinAgentSourceImageName}"
echo "SOURCE_IMAGE_TAG=${SovrinAgentSourceImageTag}"
echo "DOCKER_FILE_PATH=${SovrinAgentDockerFile}"
echo "SOURCE_CONTEXT_DIR=${GitContextDir}"
echo "GIT_REF=${GitRef}"
echo "GIT_URI=${GitUri}"
echo "OUTPUT_IMAGE_NAME=${SovrinAgentName}"
echo "OUTPUT_IMAGE_TAG=${OutputImageTag}"
echo "SOVRIN_NODE_IP_LIST=${NODE_IP_LIST}"
echo "SOVRIN_NODE_COUNT=${NODE_COUNT}"
echo "SOVRIN_CLIENT_COUNT=${CLIENT_COUNT}"
echo "SOVRIN_AGENT_NAME=${SovrinAgentInstanceName}"
echo "SOVRIN_AGENT_PORT=${SovrinAgentInstancePort}"
echo "Output File=${SovrinAgentBuildConfig}"
echo "------------------------------------------------------------------------"

oc process \
-f ${BuildConfigTemplate} \
-p BUILD_NAME=${SovrinAgentName} \
-p SOURCE_IMAGE_KIND=${SovrinAgentSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinAgentSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinAgentSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinAgentDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${SovrinAgentName} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
-p SOVRIN_NODE_IP_LIST=${NODE_IP_LIST} \
-p SOVRIN_NODE_COUNT=${NODE_COUNT} \
-p SOVRIN_CLIENT_COUNT=${CLIENT_COUNT} \
-p SOVRIN_AGENT_NAME=${SovrinAgentInstanceName} \
-p SOVRIN_AGENT_PORT=${SovrinAgentInstancePort} \
> ${SovrinAgentBuildConfig}
echo "Generated ${SovrinAgentBuildConfig} ..."
echo
# ===========================================================================

echo "============================================================================="
echo "Cleaning out existing OpenShift resources ..."
echo "============================================================================"
oc delete imagestreams,bc --all
echo

echo "============================================================================="
echo "Creating build configurations in OpenShift project; ${ProjectName} ..."
echo "============================================================================="
for file in *_BuildConfig.json; do 
	echo "Loading ${file} ...";
	oc create -f ${file};
	echo;
done
echo

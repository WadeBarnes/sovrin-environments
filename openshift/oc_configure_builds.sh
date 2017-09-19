#!/bin/bash

# ==============================================================================
# Script for setting up the build environment for the Alice example in OpenShift
#
# * Requires the OpenShift Origin CLI
# ------------------------------------------------------------------------------
#
# Usage on Windows:
#  
# ./oc_configure_builds.sh
#
# ------------------------------------------------------------------------------
#
# ToDo:
# * Parameterize.
# * Add support for create or update.
#
# ==============================================================================

SCRIPT_DIR=$(dirname $0)
USER_ID="$(id -u)"

ProjectName="myproject"
BuildConfigTemplate="buildConfigTemplate.json"

BuildConfigPostfix="_BuildConfig.json"
SovrinBaseBuildConfig="sovrinBase${BuildConfigPostfix}"
SovrinCoreBuildConfig="sovrinCore${BuildConfigPostfix}"
SovrinNodeBuildConfigNameBase="sovrinNode"
SovrinClientBuildConfig="sovrinClient${BuildConfigPostfix}"

SovrinBaseDockerFile="base.systemd.ubuntu.dockerfile"
SovrinCoreDockerFile="core.ubuntu.dockerfile"
SovrinNodeDockerFile="node.init.ubuntu.dockerfile"
SovrinClientDockerFile="client.ubuntu.dockerfile"

SovrinBaseName="sovrinbase"
SovrinCoreName="sovrincore"
SovrinNodeName="sovrinnode"
SovrinClientName="sovrinclient"

SovrinBaseSourceImageKind="DockerImage"
SovrinCoreSourceImageKind="ImageStreamTag"
SovrinNodeSourceImageKind="ImageStreamTag"
SovrinClientSourceImageKind="ImageStreamTag"

SovrinBaseSourceImageName="solita/ubuntu-systemd"
SovrinCoreSourceImageName="sovrinbase"
SovrinNodeSourceImageName="sovrincore"
SovrinClientSourceImageName="sovrincore"

OutputImageTag="latest"
SovrinBaseSourceImageTag="16.04"
SovrinCoreSourceImageTag="${OutputImageTag}"
SovrinNodeSourceImageTag="${OutputImageTag}"
SovrinClientSourceImageTag="${OutputImageTag}"

GitRef="master"
GitUri="https://github.com/evernym/sovrin-environments.git"
GitContextDir="docker"

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
BASE_NODE_NAME=${SovrinNodeName}

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
	NODE_IMAGE_NAME="$(echo "$NODE_NAME" | tr '[:upper:]' '[:lower:]')"
	POOL_DATA="${POOL_DATA},$NODE_IMAGE_NAME ${IPS_ARRAY[i-1]} $NODE_PORT $CLIENT_PORT"	
done

POOL_DATA=${POOL_DATA:1}
echo "Writing node pool data to $POOL_DATA_FILE for referance ..."
echo "$POOL_DATA" > $POOL_DATA_FILE
echo "Node pool data created."
echo
# ===========================================================================

# ===========================================================================
# Sovin Node Images
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
NODE_IMAGE_NAME=${NODE_DATA_ARRAY[0]}
NODE_NUMBER="${NODE_IMAGE_NAME:(-1)}"
NODE_IP=${NODE_DATA_ARRAY[1]}
NODE_PORT=${NODE_DATA_ARRAY[2]}
CLIENT_PORT=${NODE_DATA_ARRAY[3]}

echo "------------------------------------------------------------------------"
echo "Parsed pool data for ${NODE_IMAGE_NAME} ..."
echo "------------------------------------------------------------------------"
echo "NODE_DATA=${NODE_DATA}"
echo "NODE_IMAGE_NAME=${NODE_IMAGE_NAME}"
echo "NODE_NUMBER=${NODE_NUMBER}"
echo "NODE_IP=${NODE_IP}"
echo "NODE_PORT=${NODE_PORT}"
echo "CLIENT_PORT=${CLIENT_PORT}"
echo "NODE_IP_LIST=${NODE_IP_LIST:1}"
echo "------------------------------------------------------------------------"
echo
IFS=$ORIGINAL_IFS

SovrinNodeBuildConfig="${SovrinNodeBuildConfigNameBase}${NODE_NUMBER}${BuildConfigPostfix}"

echo "------------------------------------------------------------------------"
echo "Generating build configuration file for ${NODE_IMAGE_NAME} ..."
echo "------------------------------------------------------------------------"
echo "Template=${BuildConfigTemplate}"
echo "BUILD_NAME=${NODE_IMAGE_NAME}"
echo "SOURCE_IMAGE_KIND=${SovrinNodeSourceImageKind}"
echo "SOURCE_IMAGE_NAME=${SovrinNodeSourceImageName}"
echo "SOURCE_IMAGE_TAG=${SovrinNodeSourceImageTag}"
echo "DOCKER_FILE_PATH=${SovrinNodeDockerFile}"
echo "SOURCE_CONTEXT_DIR=${GitContextDir}"
echo "GIT_REF=${GitRef}"
echo "GIT_URI=${GitUri}"
echo "OUTPUT_IMAGE_NAME=${NODE_IMAGE_NAME}"
echo "OUTPUT_IMAGE_TAG=${OutputImageTag}"
echo "SOVRIN_NODE_NAME=${NODE_IMAGE_NAME}"
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
-p BUILD_NAME=${NODE_IMAGE_NAME} \
-p SOURCE_IMAGE_KIND=${SovrinNodeSourceImageKind} \
-p SOURCE_IMAGE_NAME=${SovrinNodeSourceImageName} \
-p SOURCE_IMAGE_TAG=${SovrinNodeSourceImageTag} \
-p DOCKER_FILE_PATH=${SovrinNodeDockerFile} \
-p SOURCE_CONTEXT_DIR=${GitContextDir} \
-p GIT_REF=${GitRef} \
-p GIT_URI=${GitUri} \
-p OUTPUT_IMAGE_NAME=${NODE_IMAGE_NAME} \
-p OUTPUT_IMAGE_TAG=${OutputImageTag} \
-p SOVRIN_NODE_NAME=${NODE_IMAGE_NAME} \
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
	NODE_IMAGE_NAME=${NODE_DATA_ARRAY[0]}
	NODE_IP=${NODE_DATA_ARRAY[1]}
	NODE_PORT=${NODE_DATA_ARRAY[2]}
	CLIENT_PORT=${NODE_DATA_ARRAY[3]}
	LAST_NODE_IP=${NODE_IP}
	NODE_IP_LIST="${NODE_IP_LIST},${NODE_IP}"

	echo "------------------------------------------------------------------------"
	echo "Parsed pool data for ${NODE_IMAGE_NAME} ..."
	echo "------------------------------------------------------------------------"
	echo "NODE_DATA=${NODE_DATA}"
	echo "NODE_IMAGE_NAME=${NODE_IMAGE_NAME}"
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

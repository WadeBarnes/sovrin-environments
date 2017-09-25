#!/bin/bash

USER_ID="$(id -u)"
SCRIPT_DIR=$(dirname $0)

# ==============================================================================
# Script for setting up the build environment for the Alice example in OpenShift
#
# * Requires the OpenShift Origin CLI
# ------------------------------------------------------------------------------
# Usage on Windows:
#  MSYS_NO_PATHCONV=1 ./oc_configure_builds.sh
# ------------------------------------------------------------------------------
# ToDo:
# * Parameterize.
# * Add support for create or update.
# ==============================================================================

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
echo "-----------------------------------------------------------------------------"
oc project ${ProjectName}
echo "============================================================================"
echo 


echo "============================================================================="
echo "Deleting previous build configuration files ..."
echo "-----------------------------------------------------------------------------"
for file in *_BuildConfig.json; do 
	echo "Deleting ${file} ..."
	rm -rf ${file};
done
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating base build configuration ..."
echo "-----------------------------------------------------------------------------"
${SCRIPT_DIR}/oc_configure_base_build.sh \
	${BuildConfigTemplate} \
	${BuildConfigPostfix} \
	${SovrinBaseName} \
	${SovrinBaseSourceImageKind} \
	${SovrinBaseSourceImageName} \
	${SovrinBaseSourceImageTag} \
	${SovrinBaseDockerFile} \
	${GitContextDir} \
	${GitRef} \
	${GitUri} \
	${SovrinBaseName} \
	${OutputImageTag} \	
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating core build configuration ..."
echo "-----------------------------------------------------------------------------"
${SCRIPT_DIR}/oc_configure_base_build.sh \
	${BuildConfigTemplate} \
	${BuildConfigPostfix} \
	${SovrinCoreName} \
	${SovrinCoreSourceImageKind} \
	${SovrinCoreSourceImageName} \
	${SovrinCoreSourceImageTag} \
	${SovrinCoreDockerFile} \
	${GitContextDir} \
	${GitRef} \
	${GitUri} \
	${SovrinCoreName} \
	${OutputImageTag} \	
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating node pool data ..."
echo "-----------------------------------------------------------------------------"
if [ -z "${POOL_DATA_FILE}" ]; then
	POOL_DATA_FILE="pool_data"
fi

${SCRIPT_DIR}/generatePoolData.sh ${POOL_DATA_FILE}
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating node build configuration ..."
echo "-----------------------------------------------------------------------------"
if [ -z "${CLIENT_COUNT}" ]; then
	CLIENT_COUNT=10
fi

NODE_DATA=$(${SCRIPT_DIR}/getNodeInfoFromPool.sh ${POOL_DATA_FILE})
NODE_NAME=$(${SCRIPT_DIR}/getNodeInfo.sh "${NODE_DATA}" "name")
NODE_NUMBER=$(${SCRIPT_DIR}/getNodeInfo.sh "${NODE_DATA}" "number")
NODE_IP=$(${SCRIPT_DIR}/getNodeInfo.sh "${NODE_DATA}" "ip")
NODE_PORT=$(${SCRIPT_DIR}/getNodeInfo.sh "${NODE_DATA}" "nodeport")
CLIENT_PORT=$(${SCRIPT_DIR}/getNodeInfo.sh "${NODE_DATA}" "clientport")

NODE_IP_LIST=$(${SCRIPT_DIR}/getNodeAddressListFromPool.sh ${POOL_DATA_FILE})
NODE_COUNT=$(${SCRIPT_DIR}/getNodeCount.sh ${NODE_IP_LIST})

if [ ! -z "$DEBUG_MESSAGES" ]; then
	echo "------------------------------------------------------------------------"
	echo "Parsed pool data for ${NODE_NAME} ..."
	echo "------------------------------------------------------------------------"
	echo "NODE_DATA=${NODE_DATA}"
	echo "NODE_NAME=${NODE_NAME}"
	echo "NODE_NUMBER=${NODE_NUMBER}"
	echo "NODE_IP=${NODE_IP}"
	echo "NODE_PORT=${NODE_PORT}"
	echo "CLIENT_PORT=${CLIENT_PORT}"
	echo
	echo "NODE_IP_LIST=${NODE_IP_LIST}"
	echo "NODE_COUNT=${NODE_COUNT}"
	echo "------------------------------------------------------------------------"
	echo
fi

${SCRIPT_DIR}/oc_configure_node_build.sh \
	${BuildConfigTemplate} \
	${BuildConfigPostfix} \
	${SovrinNodeName} \
	${SovrinNodeSourceImageKind} \
	${SovrinNodeSourceImageName} \
	${SovrinNodeSourceImageTag} \
	${SovrinNodeDockerFile} \
	${GitContextDir} \
	${GitRef} \
	${GitUri} \
	${SovrinNodeName} \
	${OutputImageTag} \
	${NODE_NAME} \
	${NODE_PORT} \
	${CLIENT_PORT} \
	${NODE_IP_LIST} \
	${NODE_COUNT} \
	${CLIENT_COUNT} \
	${NODE_NUMBER}
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating client build configuration ..."
echo "-----------------------------------------------------------------------------"
${SCRIPT_DIR}/oc_configure_client_build.sh \
	${BuildConfigTemplate} \
	${BuildConfigPostfix} \
	${SovrinClientName} \
	${SovrinClientSourceImageKind} \
	${SovrinClientSourceImageName} \
	${SovrinClientSourceImageTag} \
	${SovrinClientDockerFile} \
	${GitContextDir} \
	${GitRef} \
	${GitUri} \
	${SovrinClientName} \
	${OutputImageTag} \
	${NODE_IP_LIST} \
	${NODE_COUNT} \
	${CLIENT_COUNT}
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating agent build configuration ..."
echo "-----------------------------------------------------------------------------"
${SCRIPT_DIR}/oc_configure_agent_build.sh \
	${BuildConfigTemplate} \
	${BuildConfigPostfix} \
	${SovrinAgentName} \
	${SovrinAgentSourceImageKind} \
	${SovrinAgentSourceImageName} \
	${SovrinAgentSourceImageTag} \
	${SovrinAgentDockerFile} \
	${GitContextDir} \
	${GitRef} \
	${GitUri} \
	${SovrinAgentName} \
	${OutputImageTag} \
	${NODE_IP_LIST} \
	${NODE_COUNT} \
	${CLIENT_COUNT} \
	${SovrinAgentInstanceName} \
	${SovrinAgentInstancePort}

echo "============================================================================="
echo

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

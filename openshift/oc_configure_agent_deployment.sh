#!/bin/bash

USER_ID="$(id -u)"
SCRIPT_DIR=$(dirname $0)

# ===========================================================================
# Generate a Sovin Agent Deployment Configuration
# ===========================================================================
DeploymentConfigTemplate="${1}"
DeploymentConfigPostFix="${2}"
SourceImageName="${3}"
ImageTag="${4}"
NodeIpList="${5}"
NodeCount="${6}"
ClientCount="${7}"
HomeDirectory="${8}"
AgentName="${9}"
AgentPort="${10}"
# -----------------------------------------------------------------------------------
ApplicationName="$(echo "$AgentName" | tr '[:upper:]' '[:lower:]')-agent"
ServiceDescription="Exposes and load balances the pods for the ${AgentName} agent."
ApplicationHostName=""
ImageNamespace=""
DeploymentConfig="${ApplicationName}${DeploymentConfigPostFix}"
# ===================================================================================

echo "------------------------------------------------------------------------"
echo "Generating deploytment configuration file for the ${AgentName} agent..."
echo "------------------------------------------------------------------------"
echo "Template=${DeploymentConfigTemplate}"
echo "APPLICATION_NAME=${ApplicationName}"
echo "APPLICATION_SERVICE_DESCRIPTION=${ServiceDescription}"
echo "APPLICATION_HOSTNAME=${ApplicationHostName}"
echo "SOURCE_IMAGE_NAME=${SourceImageName}"
echo "IMAGE_NAMESPACE=${ImageNamespace}"
echo "DEPLOYMENT_TAG=${ImageTag}"
echo "NODE_IP_LIST=${NodeIpList}"
echo "NODE_COUNT=${NodeCount}"
echo "CLIENT_COUNT=${ClientCount}"
echo "HOME_DIR=${HomeDirectory}"	
echo "AGENT_NAME=${AgentName}"
echo "AGENT_PORT=${AgentPort}"
echo "Output File=${DeploymentConfig}"
echo "------------------------------------------------------------------------"
echo

oc process \
-f ${DeploymentConfigTemplate} \
-p APPLICATION_NAME=${ApplicationName} \
-p APPLICATION_SERVICE_DESCRIPTION="${ServiceDescription}" \
-p APPLICATION_HOSTNAME=${ApplicationHostName} \
-p SOURCE_IMAGE_NAME=${SourceImageName} \
-p IMAGE_NAMESPACE=${ImageNamespace} \
-p DEPLOYMENT_TAG=${ImageTag} \
-p NODE_IP_LIST=${NodeIpList} \
-p NODE_COUNT=${NodeCount} \
-p CLIENT_COUNT=${ClientCount} \
-p HOME_DIR=${HomeDirectory} \
-p AGENT_NAME=${AgentName} \
-p AGENT_PORT=${AgentPort} \
> ${DeploymentConfig}
echo "Generated ${DeploymentConfig} ..."
echo
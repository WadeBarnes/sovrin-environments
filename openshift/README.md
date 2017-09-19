# Prerequisites
* Docker
* OpenShift

# Starting and Stopping a local OpenShift Cluster

_Refer to https://github.com/WadeBarnes/dev-tools/tree/master/chocolatey for information on setting up a location OpenShift environment._

To start a local cluster: `MSYS_NO_PATHCONV=1 ./oc_cluster_up.sh`

To stop a location cluster: `./oc_cluster_down`

# Description

**This is a work in progress ...**

Configuration and deployment scripts for deploying the example sovrin network in OpenShift.

## oc_configure_builds.sh

Use: `./oc_configure_builds.sh`

Creates the build configurations and image streams for the sovrin images in OpenShift.

## oc_configure_deployments.sh

Use: `./oc_configure_deployments.sh`

Creates the deployment configurations, services, and routes for the example sovrin network in OpenShift.

# Status

**This has been a bit of a challenge ...**

## The main friction points:
* systemd on Ubuntu 16.04
* expected permissions for running sovrin-node.service
* best practices for running containers on OpenShift.

## Details:
* Best practice in OpenShift states containers should not run as root, but as an arbitrary user.
* The sovrin-node-service runs as 'sovrin' and it's very particular about the permissions set on all of the configuration, transaction files, certificates and keys.
* systemd on Ubuntu, in practice and from what I've found on the web, seems to be somewhat broken.
    * Following the steps and examples I've found to launch it using an arbitrary user account leave the container in a state where systemd seems to be running, but the sovrin-node service is not running and it is difficult to determine the state of the systemd services as (even with sudo installed) systemctl is left non-functional.
    * Attempts to fix the systemctl accessibility issue, using examples and references, have been unsuccessful.

## Current State:
* Created scripts to generate build configurations (builds and image streams) for sovrincore, sovrinbase, sovrinnodes, and sovrinclient.
    * Working
* Created scripts to generate deployment configurations (deployments, services, and routes) for the sovrin network.
    * Working (work in progress).
* Created initialization scripts that take sovrin network configuration parameters injected into the pod's deployment environment and perform node and transaction file initialization on startup.
    * Works well in Docker when the container is run as root.
    * When the container is run as a non-root user, the initialization scripts still work, creating the expected files, but the sovrin-node service fails to start due to systemd permission issues, or file permission issues.   Troubleshooting has been difficult.
* In a privileged OpenShift environment, one that allows containers to run as root;
    * Nodes come up and dynamically configure themselves as expected.
    * Some additional permission and intercommunication troubleshooting is required as the sovrin-node service is not starting as expected.
* Apart from that, I have run through some samples of configuring systemd to run using an arbitrary user account (which is OpenShift best practice).  It seems to work however the sovrin-node service does not start and it is difficult to troubleshoot the issue without systemctl being functional with any account other than root (even with sudo installed and properly configured).

# References:

[solita/ubuntu-systemd](https://hub.docker.com/r/solita/ubuntu-systemd/)

[How-To: Run a Pod as Root](http://appagile.io/2017/03/29/how-to-run-a-pod-as-root/)
* A reference for how to configure an OpenShift project to allow pods to run as root.

[RHsyseng/container-rhel-examples/starter-systemd/](https://github.com/RHsyseng/container-rhel-examples/tree/master/starter-systemd)
* Reference for configuring systemd to run using an arbitrary user account.

[Running systemd Within a Docker Container](https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/)
* Alternate location [Running systemd Within a Docker Container](https://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/)

[Running systemd in a non-privileged container](https://developers.redhat.com/blog/2016/09/13/running-systemd-in-a-non-privileged-container/)

[How do I setup a systemd service to be started by a non root user as a user daemon?](https://superuser.com/questions/476379/how-do-i-setup-a-systemd-service-to-be-started-by-a-non-root-user-as-a-user-daem)

**Various references for systemd/systemctl issues**
* [Trying to run as user instance, but $XDG_RUNTIME_DIR is not set](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=769370)
* [Systemd User Services: Failed to connect to bus](https://bbs.archlinux.org/viewtopic.php?id=219054)
* [Failed to connect to bus: No such file or directory on systemd operations](https://github.com/tknerr/vagrant-docker-baseimages/issues/7)
* [Failed to connect to bus: No such file or directory](https://github.com/influxdata/telegraf/issues/1022)
* [Failed to connect to bus: No such file or directory in Ubuntu Docker Container](https://github.com/moby/moby/issues/32616)
* [systemctl —user: Failed to d-bus connection: No such file or directory](https://www.centos.org/forums/viewtopic.php?t=59484)

[gdraheim/docker-systemctl-replacement](https://github.com/gdraheim/docker-systemctl-replacement)
* A possible replacement for systemctl in Docker containers.
* I have not tried this yet.
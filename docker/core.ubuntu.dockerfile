FROM sovrinbase

ARG uid=1000
ARG gid=0

# Install environment
RUN apt-get update -y && apt-get install -y \ 
	git \
	wget \
	python3.5 \
	python3-pip \
	python-setuptools \
	python3-nacl \
	apt-transport-https \
	ca-certificates 
RUN pip3 install -U \ 
	pip \ 
	setuptools

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BD33704C
RUN echo "deb https://repo.evernym.com/deb xenial master" >> /etc/apt/sources.list 
RUN echo "deb https://repo.sovrin.org/deb xenial master" >> /etc/apt/sources.list

RUN useradd -ms /bin/bash -l -u $uid -G $gid sovrin
RUN apt-get update -y && apt-get install -y sovrin

#================================================================================================================
# Configure systemd to run as an arbitrary user ...
#
# Inspired by:
# https://github.com/RHsyseng/container-rhel-examples/tree/master/starter-systemd
#================================================================================================================
COPY systemd_setup /tmp/

# Setup user for build execution and application runtime
ENV USER_NAME=default \
    APP_ROOT=/opt/app-root
	
ENV PATH=${APP_ROOT}/bin:${PATH} HOME=${APP_ROOT}

COPY bin/ ${APP_ROOT}/bin/

RUN chmod -R u+x ${APP_ROOT}/bin /tmp/systemd_setup && sync && \
    chgrp -R 0 ${APP_ROOT} && \
	chgrp -R 0 /home/sovrin && \
    chmod -R g=u ${APP_ROOT} /home/sovrin /tmp/systemd_setup /etc/passwd

# systemd requirements - to cleanly shutdown systemd, use SIGRTMIN+3
STOPSIGNAL SIGRTMIN+3

ENV container=oci

RUN MASK_JOBS="sys-fs-fuse-connections.mount getty.target systemd-initctl.socket systemd-logind.service" && \
    systemctl mask ${MASK_JOBS} && \
    for i in ${MASK_JOBS}; do find /usr/lib/systemd/ -iname $i | grep ".wants" | xargs rm -f; done && \
    rm -f /etc/fstab && \
    systemctl set-default multi-user.target && \
    systemctl enable sovrin-node
	
RUN /tmp/systemd_setup
#================================================================================================================

# Containers should NOT run as root as a good practice
USER 10001
WORKDIR ${APP_ROOT}
VOLUME /var/log/httpd /tmp /run
CMD [ "/sbin/init" ]
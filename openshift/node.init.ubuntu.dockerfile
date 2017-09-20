# Development
FROM sovrincore

ARG nodename
ARG nport
ARG cport
ARG ips
ARG nodenum
ARG nodecnt
ARG clicnt=10

ENV NODE_NUMBER $nodenum
ENV NODE_NAME $nodename
ENV NODE_PORT $nport
ENV CLIENT_PORT $cport
ENV NODE_IP_LIST $ips
ENV NODE_COUNT $nodecnt
ENV CLIENT_COUNT $clicnt
ENV HOME=/home/sovrin
ENV TEST_MODE=
ENV HOLD_EXT="sovrin "

EXPOSE $nport $cport

USER 10001
COPY ./scripts/common/initialize.sh /home/sovrin/
COPY ./scripts/node/start.sh /home/sovrin/

WORKDIR /home/sovrin
CMD ["/home/sovrin/start.sh"]

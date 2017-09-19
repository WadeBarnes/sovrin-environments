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

EXPOSE $nport $cport

COPY nodeStartupScript.sh /home/sovrin/

CMD ["/home/sovrin/nodeStartupScript.sh"]

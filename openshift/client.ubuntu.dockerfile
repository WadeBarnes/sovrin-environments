FROM sovrincore

ARG ips
ARG nodecnt
ARG clicnt=10

ENV NODE_IP_LIST $ips
ENV NODE_COUNT $nodecnt
ENV CLIENT_COUNT $clicnt
ENV HOME=/home/sovrin

EXPOSE 5000-9799

COPY ./scripts/common/initialize.sh /home/sovrin/
COPY ./scripts/client/start.sh /home/sovrin/

CMD ["/home/sovrin/start.sh"]

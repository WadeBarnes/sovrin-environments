FROM sovrincore

ARG ips
ARG nodecnt
ARG clicnt=10

ENV HOME=/home/sovrin

USER root
RUN chgrp -R 0 /home/sovrin && chmod -R g+rwX /home/sovrin
EXPOSE 5000-9799
USER sovrin
# Init pool data
RUN if [ ! -z "$ips" ] && [ ! -z "$nodecnt" ]; then generate_sovrin_pool_transactions --nodes $nodecnt --clients $clicnt --ips "$ips"; fi

WORKDIR /home/sovrin
CMD sovrin

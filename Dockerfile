FROM alpine:edge

# Version of RabbitMQ to install
ENV RABBITMQ_VERSION=3.6.6 \
    AUTOCLUSTER_VERSION=0.6.1 \
    ERL_EPMD_PORT=4369 \
    HOME=/var/lib/rabbitmq \
    PATH=/usr/lib/rabbitmq/sbin:$PATH \
    RABBITMQ_LOGS=- \
    RABBITMQ_SASL_LOGS=- \
    RABBITMQ_DIST_PORT=25672 \
    RABBITMQ_SERVER_ERL_ARGS="+K true +A128 +P 1048576 -kernel inet_default_connect_options [{nodelay,true}]" \
    RABBITMQ_MNESIA_DIR=/var/lib/rabbitmq/mnesia \
    RABBITMQ_PID_FILE=/var/lib/rabbitmq/rabbitmq.pid \
    RABBITMQ_PLUGINS_DIR=/usr/lib/rabbitmq/plugins \
    RABBITMQ_PLUGINS_EXPAND_DIR=/var/lib/rabbitmq/plugins \
    LANG=en_US.UTF-8

RUN \
  apk --update upgrade \
  && apk add \
    coreutils curl xz "su-exec>=0.2" \
    erlang erlang-asn1 erlang-crypto erlang-eldap erlang-erts erlang-inets erlang-mnesia \
    erlang-os-mon erlang-public-key erlang-sasl erlang-ssl erlang-syntax-tools erlang-xmerl \
  && curl -sL -o /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz \
  && cd /usr/lib \
  && tar xf /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz \
  && rm /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz \
  && mv /usr/lib/rabbitmq_server-${RABBITMQ_VERSION} /usr/lib/rabbitmq \
  && curl -sL -o /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz https://github.com/aweber/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/autocluster-${AUTOCLUSTER_VERSION}.tgz \
  && tar -xvz -C /usr/lib/rabbitmq -f /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz \
  && rm /tmp/autocluster-${AUTOCLUSTER_VERSION}.tgz \
  && apk --purge del \
    curl \
    tar \
    gzip \
    xz \
  && rm -rf \
    /etc/apk/cache/* \
    /var/cache/apk/* \
    /tmp/*

COPY root/ /

# Fetch the external plugins and setup RabbitMQ
RUN \
  adduser -D -u 1000 -h $HOME rabbitmq rabbitmq && \
  cp /var/lib/rabbitmq/.erlang.cookie /root/ && \
  chown rabbitmq /var/lib/rabbitmq/.erlang.cookie && \
  chmod 0600 /var/lib/rabbitmq/.erlang.cookie /root/.erlang.cookie && \
  chown -R rabbitmq /usr/lib/rabbitmq /var/lib/rabbitmq && \
  /usr/lib/rabbitmq/sbin/rabbitmq-plugins --offline enable \
    rabbitmq_management \
    rabbitmq_management_visualiser \
    rabbitmq_consistent_hash_exchange \
    rabbitmq_federation \
    rabbitmq_federation_management \
    rabbitmq_mqtt \
    rabbitmq_shovel \
    rabbitmq_shovel_management \
    rabbitmq_stomp \
    rabbitmq_web_stomp \
    autocluster

VOLUME $HOME
EXPOSE 4369 5671 5672 15672 25672
ENTRYPOINT ["/launch.sh"]
CMD ["rabbitmq-server"]

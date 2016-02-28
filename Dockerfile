FROM blacklabelops/java:openjre8
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG BITBUCKET_VERSION=4.3.2
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

ENV BITBUCKET_HOME=/var/atlassian/bitbucket \
    BITBUCKET_INSTALL=/opt/bitbucket \
    BITBUCKET_PROXY_NAME= \
    BITBUCKET_PROXY_PORT= \
    BITBUCKET_PROXY_SCHEME=

RUN export MYSQL_DRIVER_VERSION=5.1.38 && \
    export POSTGRESQL_DRIVER_VERSION=9.4.1207 && \
    export CONTAINER_USER=bitbucket &&  \
    export CONTAINER_GROUP=bitbucket &&  \
    addgroup -g $CONTAINER_GID $CONTAINER_GROUP &&  \
    adduser -u $CONTAINER_UID \
            -G $CONTAINER_GROUP \
            -h /home/$CONTAINER_USER \
            -s /bin/bash \
            -S $CONTAINER_USER &&  \
    apk add --update \
      ca-certificates \
      gzip \
      git \
      perl \
      wget &&  \
    apk add xmlstarlet --update-cache \
      --repository \
      http://dl-3.alpinelinux.org/alpine/edge/testing/ \
      --allow-untrusted &&  \
    wget -O /tmp/bitbucket.tar.gz https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz && \
    tar zxf /tmp/bitbucket.tar.gz -C /tmp && \
    mv /tmp/atlassian-bitbucket-${BITBUCKET_VERSION} /tmp/bitbucket && \
    mkdir -p ${BITBUCKET_HOME} && \
    mkdir -p /opt && \
    mv /tmp/bitbucket /opt/bitbucket && \
    # Adding letsencrypt-ca to truststore
    wget -O /home/${CONTAINER_USER}/letsencryptauthorityx1.der https://letsencrypt.org/certs/letsencryptauthorityx1.der && \
    keytool -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt -importcert -file /home/${CONTAINER_USER}/letsencryptauthorityx1.der && \
    rm -f /home/${CONTAINER_USER}/letsencryptauthorityx1.der && \
    # Install atlassian ssl tool
    wget -O /home/${CONTAINER_USER}/SSLPoke.class https://confluence.atlassian.com/kb/files/779355358/SSLPoke.class && \
    # Container user permissions
    chown -R confluence:confluence /home/${CONTAINER_USER} && \
    chown -R bitbucket:bitbucket ${BITBUCKET_HOME} && \
    chmod -R u=rwx,g=rwx,o=-rwx ${BITBUCKET_INSTALL} && \
    chown -R bitbucket:bitbucket ${BITBUCKET_INSTALL} && \
    # Remove obsolete packages
    apk del \
      ca-certificates \
      gzip \
      wget &&  \
    # Clean caches and tmps
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

USER bitbucket
WORKDIR /var/atlassian/bitbucket
VOLUME ["/var/atlassian/bitbucket"]
EXPOSE 7990 7999
COPY imagescripts /home/bitbucket
ENTRYPOINT ["/home/bitbucket/docker-entrypoint.sh"]
CMD ["bitbucket"]

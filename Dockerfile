# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=registry.access.redhat.com/ubi9
ARG RUN_IMAGE=quay.io/keycloak/keycloak:26.0.7

ARG ORACLE_DRIVER_URL=https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/23.5.0.24.07/ojdbc11-23.5.0.24.07.jar
ARG ORACLE_NLS_URL=https://repo1.maven.org/maven2/com/oracle/database/nls/orai18n/23.5.0.24.07/orai18n-23.5.0.24.07.jar

################## Stage 0
FROM ${BUILD_IMAGE} as builder
ARG ORACLE_DRIVER_URL
ARG ORACLE_NLS_URL

USER root

RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs jq vim curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

COPY ./scripts /mnt/rootfs

# Download Oracle DB Driver
RUN mkdir -p /mnt/rootfs/opt/keycloak/providers
ADD --chown=keycloak:keycloak --chmod=644 "${ORACLE_DRIVER_URL}" /mnt/rootfs/opt/keycloak/providers/ojdbc11.jar
ADD --chown=keycloak:keycloak --chmod=644 "${ORACLE_NLS_URL}" /mnt/rootfs/opt/keycloak/providers/orai18n.jar

################## Stage 1
FROM ${RUN_IMAGE} as runner

ENV KEYCLOAK_HOME=/opt/keycloak
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=oracle

USER root

COPY --from=builder /mnt/rootfs /

RUN /opt/keycloak/bin/kc.sh build

RUN mkdir /container-entrypoint-initdb.d \
    && chown -R keycloak:keycloak /opt/keycloak

USER keycloak
WORKDIR /opt/keycloak
ENTRYPOINT ["/container-entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --start-interval=5s --retries=5 CMD /container-healthcheck.sh
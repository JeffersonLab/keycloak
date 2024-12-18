# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=registry.access.redhat.com/ubi9
ARG RUN_IMAGE=quay.io/keycloak/keycloak:26.0.7

ARG ORACLE_DRIVER_URL=https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/21.7.0.0/ojdbc11-21.7.0.0.jar
ARG ORACLE_DRIVER_NAME=ojdbc11-21.7.0.0.jar

################## Stage 0
FROM ${BUILD_IMAGE} as builder
ARG ORACLE_DRIVER_URL
ARG ORACLE_DRIVER_NAME

RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs jq vim curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

USER root
WORKDIR /
COPY ./scripts /mnt/rootfs

# Download Oracle DB Driver
RUN dnf install wget --nodocs -y

RUN mkdir -p /mnt/rootfs/opt/keycloak/providers

RUN wget -O /mnt/rootfs/opt/keycloak/providers/"${ORACLE_DRIVER_NAME}" "${ORACLE_DRIVER_URL}"

################## Stage 1
FROM ${RUN_IMAGE} as runner
COPY --from=builder /mnt/rootfs /
USER root
RUN mkdir /container-entrypoint-initdb.d
USER keycloak
ENTRYPOINT ["/container-entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --start-interval=5s --retries=5 CMD /container-healthcheck.sh
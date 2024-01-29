# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=alpine:3.19.1
ARG RUN_IMAGE=quay.io/keycloak/keycloak:20.0.5

################## Stage 0
FROM ${BUILD_IMAGE} as builder
USER root
WORKDIR /
COPY . /app

## Let's minimize layers in final-product by organizing files into a single copy structure
RUN mkdir /unicopy \
    && cp /app/scripts/docker-entrypoint.sh /unicopy \
    && cp /app/scripts/docker-healthcheck.sh /unicopy

################## Stage 1
FROM ${RUN_IMAGE} as runner
COPY --from=builder /unicopy /
USER root
RUN mkdir /docker-entrypoint-initdb.d
USER keycloak
ENTRYPOINT ["/docker-entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --start-interval=5s --retries=5 CMD /docker-healthcheck.sh
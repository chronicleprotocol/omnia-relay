FROM golang:1.20-alpine3.16 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

WORKDIR /go/src/omnia
ARG ETHSIGN_REF="tags/v1.13.3"
RUN git clone https://github.com/chronicleprotocol/omnia.git . \
  && git checkout --quiet ${ETHSIGN_REF} \
  && cd ethsign \
  && go mod vendor \
  && go build .

## SSB Go Client
WORKDIR /go/src/ssb
ARG SSB_RPC_CLIENT_REF="tags/v0.1.0"
RUN git clone https://github.com/chronicleprotocol/ssb.git . \
  && git checkout --quiet ${SSB_RPC_CLIENT_REF} \
  && cd ssb-rpc-client \
  && go mod vendor \
  && go build .

FROM ghcr.io/chronicleprotocol/oracle-suite:0.11.0-dev.7 as oracle-suite

# NOTE: ghcr.io/chronicleprotocol/omnia_base:latest is built in `omnia-feed` repo.
FROM ghcr.io/chronicleprotocol/omnia_base@sha256:c4bb82b6ebe3d22646143cbc00178c7ed1b9fdb6b1633cfd87720ac188a150d5

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates parallel tree \
  bash bash-doc bash-completion linux-headers gcompat git \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

COPY --from=go-builder \
  /go/src/omnia/ethsign/ethsign \
  /go/src/ssb/ssb-rpc-client/ssb-rpc-client \
  /usr/local/bin/

COPY --from=oracle-suite \
  /usr/local/bin/spire \
  /usr/local/bin/gofer \
  /usr/local/bin/

COPY ./omnia/bin /opt/omnia/bin/
COPY ./omnia/exec /opt/omnia/exec/
COPY ./omnia/lib /opt/omnia/lib/
COPY ./version /opt/omnia/version

# Installing setzer
ARG SETZER_REF="tags/v0.7.0"
RUN git clone https://github.com/chronicleprotocol/setzer.git \
  && cd setzer \
  && git checkout --quiet ${SETZER_REF} \
  && mkdir /opt/setzer/ \
  && cp -R libexec/ /opt/setzer/libexec/ \
  && cp -R bin /opt/setzer/bin \
  && cd .. \
  && rm -rf setzer

ENV HOME=/home/omnia

ENV OMNIA_CONFIG=${HOME}/omnia.json \
  SPIRE_CONFIG=${HOME}/spire.hcl \
  GOFER_CONFIG=${HOME}/gofer.hcl \
  ETH_RPC_URL=http://geth.local:8545 \
  ETH_GAS=7000000 \
  CHLORIDE_JS='1'

COPY --from=oracle-suite /usr/share/oracle-suite/config.hcl ${SPIRE_CONFIG}
COPY --from=oracle-suite /usr/share/oracle-suite/config.hcl ${GOFER_CONFIG}
COPY ./omnia/config/relay.json ${OMNIA_CONFIG}

WORKDIR ${HOME}
COPY ./omnia/docker/keystore/ .ethereum/keystore/
# COPY ./omnia/docker/ssb-server/config/manifest.json .ssb/manifest.json
# COPY ./omnia/docker/ssb-server/config/secret .ssb/secret
# COPY ./omnia/docker/ssb-server/config/config.json .ssb/config

ARG USER=1000
ARG GROUP=1000
RUN chown -R ${USER}:${GROUP} ${HOME}
USER ${USER}:${GROUP}

# Removing notification from `parallel`
RUN printf 'will cite' | parallel --citation 1>/dev/null 2>/dev/null; exit 0

# Setting up PATH for setzer and omnia bin folder
# Here we have set of different pathes included:
# - /opt/setzer - For `setzer` executable
# - /opt/omnia/bin - Omnia executables
# - /opt/omnia/exec - Omnia transports executables
ENV PATH="/opt/setzer/bin:/opt/omnia/bin:/opt/omnia/exec:${PATH}"

CMD ["omnia"]

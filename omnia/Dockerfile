FROM golang:1.20-alpine3.16 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

COPY ./ethsign /go/src/ethsign
WORKDIR /go/src/ethsign
RUN go mod vendor
RUN go build .

FROM ghcr.io/chronicleprotocol/gofer:sha-0aac781d as oracle-suite-gofer
FROM ghcr.io/chronicleprotocol/spire:sha-0aac781d as oracle-suite-spire

FROM ghcr.io/chronicleprotocol/omnia_base:v1.10.4

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates parallel tree \
  bash bash-doc bash-completion linux-headers gcompat git \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

COPY --from=go-builder \
  /go/src/ethsign/ethsign \
  /usr/local/bin/

COPY --from=oracle-suite-gofer \
  /usr/local/bin/gofer \
  /usr/local/bin/

COPY --from=oracle-suite-spire \
  /usr/local/bin/spire \
  /usr/local/bin/

COPY ./omnia/bin /opt/omnia/bin
COPY ./omnia/config /opt/omnia/config
COPY ./omnia/exec /opt/omnia/exec
COPY ./omnia/lib /opt/omnia/lib
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

ENV OMNIA_CONFIG=/opt/omnia/config/relay.json \
  SPIRE_CONFIG=${HOME}/spire.hcl \
  GOFER_CONFIG=${HOME}/gofer.hcl \
  ETH_RPC_URL=http://geth.local:8545 \
  ETH_GAS=7000000 \
  CHLORIDE_JS='1'

COPY --from=oracle-suite-spire /usr/share/oracle-suite/config.hcl ${SPIRE_CONFIG}
COPY --from=oracle-suite-gofer /usr/share/oracle-suite/config.hcl ${GOFER_CONFIG}

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

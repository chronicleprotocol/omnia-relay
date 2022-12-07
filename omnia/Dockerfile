FROM alpine:3.16 as rust-builder
ARG TARGETARCH

WORKDIR /opt
RUN apk add clang lld curl build-base linux-headers git \
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh \
  && chmod +x ./rustup.sh \
  && ./rustup.sh -y

RUN [[ "$TARGETARCH" = "arm64" ]] && echo "export CFLAGS=-mno-outline-atomics" >> $HOME/.profile || true

WORKDIR /opt/foundry

ARG CAST_REF="master"
RUN git clone https://github.com/foundry-rs/foundry.git . \
  && git checkout --quiet ${CAST_REF} 

RUN source $HOME/.profile && cargo build --release \
  && strip /opt/foundry/target/release/cast

FROM golang:1.18-alpine3.16 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

WORKDIR /go/src/omnia
ARG ETHSIGN_REF="tags/v1.11.0"
RUN git clone https://github.com/chronicleprotocol/omnia.git . \
  && git checkout --quiet ${ETHSIGN_REF} \
  && cd ethsign \
  && go mod vendor \
  && go build .

# Building gofer & spire
WORKDIR /go/src/oracle-suite
ARG ORACLE_SUITE_REF="tags/v0.7.2"
RUN git clone https://github.com/chronicleprotocol/oracle-suite.git . \
  && git checkout --quiet ${ORACLE_SUITE_REF}

RUN go mod vendor \
    && go build ./cmd/spire \
    && go build ./cmd/gofer \
    && go build ./cmd/ssb-rpc-client

FROM python:3.9-alpine3.16

ENV GLIBC_KEY=https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
ENV GLIBC_KEY_FILE=/etc/apk/keys/sgerrand.rsa.pub
ENV GLIBC_RELEASE=https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates parallel tree \
  bash bash-doc bash-completion linux-headers gcompat git \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  nodejs \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

RUN wget -q -O ${GLIBC_KEY_FILE} ${GLIBC_KEY} \
  && wget -O glibc.apk ${GLIBC_RELEASE} \
  && apk add glibc.apk --force

COPY --from=rust-builder /opt/foundry/target/release/cast /usr/local/bin/cast
COPY --from=go-builder \
  /go/src/omnia/ethsign/ethsign \
  /go/src/oracle-suite/spire \
  /go/src/oracle-suite/gofer \
  /go/src/oracle-suite/ssb-rpc-client \
  /usr/local/bin/

RUN pip install --no-cache-dir mpmath sympy ecdsa==0.16.0

COPY ./bin /opt/omnia/bin/
COPY ./exec /opt/omnia/exec/
COPY ./lib /opt/omnia/lib/
COPY ./version /opt/omnia/version

# Installing setzer
ARG SETZER_REF="tags/v0.5.1"
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
  SPIRE_CONFIG=${HOME}/spire.json \
  GOFER_CONFIG=${HOME}/gofer.json \
  ETH_RPC_URL=http://geth.local:8545 \
  ETH_GAS=7000000 \
  CHLORIDE_JS='1'

COPY ./config/feed.json ${OMNIA_CONFIG}
COPY ./docker/spire/config/client_feed.json ${SPIRE_CONFIG}
COPY ./docker/gofer/client.json ${GOFER_CONFIG}

WORKDIR ${HOME}
COPY ./docker/keystore/ .ethereum/keystore/
COPY ./docker/ssb-server/config/manifest.json .ssb/manifest.json
COPY ./docker/ssb-server/config/secret .ssb/secret
COPY ./docker/ssb-server/config/config.json .ssb/config

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

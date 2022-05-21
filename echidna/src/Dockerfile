# syntax=docker/dockerfile-upstream:master-experimental
FROM debian:bullseye AS builder-echidna
ENV LD_LIBRARY_PATH=/usr/local/lib PREFIX=/usr/local HOST_OS=Linux
RUN apt-get update && apt-get install -y -qq --no-install-suggests --no-install-recommends \
        cmake \
        curl \
        libbz2-dev \
        libgmp-dev \
        build-essential \
        dpkg-sig \
        libcap-dev \
        libc6-dev \
        libgmp-dev \
        libbz2-dev \
        libreadline-dev \
        libsecp256k1-dev \
        libssl-dev \
        software-properties-common \
        sudo \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
    
WORKDIR /echidna
COPY .github/scripts/install-libff.sh .
RUN install-libff.sh
RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /echidna/

RUN stack upgrade && stack setup && stack install --extra-include-dirs=/usr/local/include --extra-lib-dirs=/usr/local/lib

FROM debian:bullseye AS builder-python3
RUN apt-get update && apt-get install -y --no-install-suggests --no-install-recommends \
        gcc \
        python3.9-dev \
        python3.9-venv \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
RUN python3 -m venv /venv && /venv/bin/pip3 install slither-analyzer

FROM gcr.io/distroless/python3-debian11:nonroot AS final
COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=builder-python3 /venv /venv
ENV PATH="$PATH:/venv/bin"
ENTRYPOINT [ "/usr/local/bin/echidna-test" ]

###
# Build image
###
FROM alpine:edge AS build

WORKDIR /usr/local/src

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd-dev \
      openssl-dev \
      hwloc-dev@testing \
      build-base\
      cmake \
      coreutils \
      git

ENV XMR_STAK_CPU_VERSION v1.3.0-1.5.0

RUN    git clone https://github.com/fireice-uk/xmr-stak-cpu.git \
    && cd xmr-stak-cpu \
    && git checkout -b build ${XMR_STAK_CPU_VERSION} \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' donate-level.h \
    && cmake -DCMAKE_LINK_STATIC=ON . \
    && make -j$(nproc) \
    && sed -i -r \
        -e 's/^("pool_address" : ).*,/\1"xmr.mypool.online:3333",/' \
        -e 's/^("wallet_address" : ).*,/\1"49TfoHGd6apXxNQTSHrMBq891vH6JiHmZHbz5Vx36nLRbz6WgcJunTtgcxnoG6snKFeGhAJB5LjyAEnvhBgCs5MtEgML3LU",/' \
        -e 's/^("pool_password" : ).*,/\1"docker-xmr-stak-cpu:x",/' \
        config.txt

###
# Deployed image
###
FROM alpine:edge

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd \
      openssl \
      hwloc@testing

COPY --from=build /usr/local/src/xmr-stak-cpu/bin/xmr-stak-cpu /usr/local/bin/xmr-stak-cpu
COPY --from=build /usr/local/src/xmr-stak-cpu/config.txt /usr/local/etc/config.txt

ENTRYPOINT ["xmr-stak-cpu"]
CMD ["/usr/local/etc/config.txt"]


FROM ubuntu:22.04 as builder

COPY pin-3.23-98579-gb15ab7903-gcc-linux.tar.gz /tmp/

RUN tar -xf /tmp/pin-3.23-98579-gb15ab7903-gcc-linux.tar.gz && mv pin-3.23-98579-gb15ab7903-gcc-linux /opt/pin

FROM ubuntu:22.04

# Install lua for testing
RUN apt-get update &&\
    apt-get install -y --no-install-recommends lua5.3 liblua5.3-dev luarocks cmake ninja-build make gcc g++ libc6-dev &&\
    luarocks install rxi-json-lua &&\
    apt-get clean autoclean

# Otherwise, the .tar.gz file is kept in Docker layer because it's added in a separate command (even if the file is removed after unpacking).
COPY --from=builder /opt/pin /opt/pin

ENV PIN_ROOT=/opt/pin


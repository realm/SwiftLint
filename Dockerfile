# Explicitly specify `focal` because `swift:latest` does not use `ubuntu:latest`.
ARG BUILDER_IMAGE=swiftlang/swift:nightly-5.6-focal
ARG RUNTIME_IMAGE=ubuntu:focal

# builder image
FROM ${BUILDER_IMAGE} AS builder
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
 && rm -r /var/lib/apt/lists/*
WORKDIR /workdir/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./

ARG SWIFT_FLAGS="-c release"
RUN swift build $SWIFT_FLAGS
RUN mkdir -p /executables
RUN mv $(swift build $SWIFT_FLAGS --show-bin-path)/swiftlint /executables

# runtime image
FROM ${RUNTIME_IMAGE}
LABEL org.opencontainers.image.source https://github.com/realm/SwiftLint
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
 && rm -r /var/lib/apt/lists/*
COPY --from=builder /usr/lib/libsourcekitdInProc.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/* /usr/lib
COPY --from=builder /executables/* /usr/bin

RUN swiftlint version

CMD ["swiftlint"]

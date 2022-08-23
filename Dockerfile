# Explicitly specify `focal` because `swift:latest` does not use `ubuntu:latest`.
ARG BUILDER_IMAGE=swift:focal
ARG RUNTIME_IMAGE=ubuntu:focal

# builder image
FROM ${BUILDER_IMAGE} AS builder
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    curl \
 && rm -r /var/lib/apt/lists/*
RUN curl -O -L https://github.com/bazelbuild/bazelisk/releases/download/v1.12.2/bazelisk-linux-amd64
RUN mv bazelisk-linux-amd64 /usr/bin/bazel
RUN chmod +x /usr/bin/bazel
RUN bazel version

WORKDIR /workdir/
COPY Source Source/
COPY Tests Tests/
COPY WORKSPACE ./
COPY BUILD ./
COPY bazel bazel/

ENV CC=clang

RUN bazel build -c opt swiftlint
RUN mkdir -p /executables
RUN mv bazel-bin/swiftlint /executables

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

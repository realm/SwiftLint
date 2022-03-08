# Explicitly specify `focal` because `swift:latest` does not use `ubuntu:latest`.
ARG BUILDER_IMAGE=swift:focal
ARG RUNTIME_IMAGE=swift:focal-slim

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

RUN mkdir -p /executables
RUN swift build -c release
RUN install -v .build/release/swiftlint /executables

# runtime image
FROM ${RUNTIME_IMAGE}
LABEL org.opencontainers.image.source https://github.com/realm/SwiftLint
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
 && rm -r /var/lib/apt/lists/*
COPY --from=builder /executables/swiftlint /usr/bin

RUN swiftlint version

CMD ["swiftlint"]

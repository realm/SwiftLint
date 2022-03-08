FROM swift:focal
LABEL org.opencontainers.image.source https://github.com/realm/SwiftLint

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libcurl4 \
    libxml2 \
 && rm -r /var/lib/apt/lists/*

WORKDIR /workdir/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./

RUN swift build -c release
RUN install -v .build/release/swiftlint /usr/bin

RUN swiftlint version

CMD ["swiftlint"]

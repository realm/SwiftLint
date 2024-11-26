# Explicitly specify `noble` to keep the Swift & Ubuntu images in sync.
ARG BUILDER_IMAGE=swift:6.0-noble
ARG RUNTIME_IMAGE=ubuntu:noble

# Builder image
FROM ${BUILDER_IMAGE} AS builder
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
 && rm -r /var/lib/apt/lists/*
WORKDIR /workdir/
COPY Plugins Plugins/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./

RUN swift package update
ARG SWIFT_FLAGS="-c release -Xswiftc -static-stdlib -Xlinker -l_CFURLSessionInterface -Xlinker -l_CFXMLInterface -Xlinker -lcurl -Xlinker -lxml2 -Xswiftc -I. -Xlinker -fuse-ld=lld -Xlinker -L/usr/lib/swift/linux"
RUN swift build $SWIFT_FLAGS --product swiftlint
RUN mv `swift build $SWIFT_FLAGS --show-bin-path`/swiftlint /usr/bin
RUN strip /usr/bin/swiftlint

# Runtime image
FROM ${RUNTIME_IMAGE}
LABEL org.opencontainers.image.source=https://github.com/realm/SwiftLint
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
 && rm -r /var/lib/apt/lists/*
COPY --from=builder /usr/lib/libsourcekitdInProc.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftBasicFormat.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftCompilerPluginMessageHandling.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftDiagnostics.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftIDEUtils.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftOperators.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftParser.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftParserDiagnostics.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftRefactor.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftSyntax.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftSyntaxBuilder.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftSyntaxMacroExpansion.so /usr/lib
COPY --from=builder /usr/lib/swift/host/libSwiftSyntaxMacros.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/lib_FoundationICU.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libBlocksRuntime.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libdispatch.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundation.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationInternationalization.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationEssentials.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationNetworking.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationXML.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_Concurrency.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_RegexParser.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_StringProcessing.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftCore.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftDispatch.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftGlibc.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftSynchronization.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftSwiftOnoneSupport.so /usr/lib
COPY --from=builder /usr/bin/swiftlint /usr/bin

RUN swiftlint version
RUN echo "_ = 0" | swiftlint --use-stdin

CMD ["swiftlint"]

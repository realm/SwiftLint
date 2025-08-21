# syntax=docker/dockerfile:1

ARG SWIFT_VERSION=6.1.2
ARG UBUNTU_VERSION=noble

# Builder image
FROM swift:${SWIFT_VERSION}-${UBUNTU_VERSION} AS builder
WORKDIR /workspace
COPY Plugins Plugins/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./
ARG TARGETPLATFORM
RUN swift build -c release --product swiftlint
RUN mv $(swift build -c release --show-bin-path)/swiftlint .

# Runtime image
FROM ubuntu:${UBUNTU_VERSION} AS runtime
LABEL org.opencontainers.image.source=https://github.com/realm/SwiftLint
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.description="The SwiftLint command-line tool with all its runtime dependencies."
RUN apt-get update
RUN apt-get install -y libcurl4-openssl-dev libxml2-dev
RUN rm -r /var/lib/apt/lists/*

COPY --from=builder /usr/lib/libsourcekitdInProc.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftBasicFormat.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftCompilerPluginMessageHandling.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftDiagnostics.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftIDEUtils.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftIfConfig.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftOperators.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftParser.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftParserDiagnostics.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftSyntax.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftSyntaxBuilder.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftSyntaxMacroExpansion.so /usr/lib
COPY --from=builder /usr/lib/swift/host/compiler/lib_CompilerSwiftSyntaxMacros.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libBlocksRuntime.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundation.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationEssentials.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationInternationalization.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationNetworking.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libFoundationXML.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/lib_FoundationICU.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libdispatch.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftCore.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftDispatch.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftGlibc.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswiftSynchronization.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_Concurrency.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_RegexParser.so /usr/lib
COPY --from=builder /usr/lib/swift/linux/libswift_StringProcessing.so /usr/lib
COPY --from=builder /workspace/swiftlint /usr/bin

RUN swiftlint version
RUN echo "_ = 0" | swiftlint --use-stdin

ENTRYPOINT [ "/usr/bin/swiftlint" ]
CMD ["."]

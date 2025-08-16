# syntax=docker/dockerfile:1

ARG SWIFT_VERSION=6.0.3
ARG UBUNTU_VERSION=noble

# Builder image
FROM swift:${SWIFT_VERSION}-${UBUNTU_VERSION} AS builder
WORKDIR /workspace
COPY Plugins Plugins/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./
COPY tools/build-linux-release.sh tools/
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM ./tools/build-linux-release.sh

# Runtime image
FROM ubuntu:${UBUNTU_VERSION} AS runtime
LABEL org.opencontainers.image.source=https://github.com/realm/SwiftLint
RUN apt-get update
RUN apt-get install -y libcurl4-openssl-dev libxml2-dev
RUN rm -r /var/lib/apt/lists/*

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
COPY --from=builder /workspace/swiftlint_linux_* /usr/bin

RUN ln -s /usr/bin/swiftlint_linux_* /usr/bin/swiftlint

RUN swiftlint version
RUN echo "_ = 0" | swiftlint --use-stdin

ENTRYPOINT [ "/usr/bin/swiftlint" ]
CMD ["."]

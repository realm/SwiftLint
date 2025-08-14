# syntax=docker/dockerfile:1

# Base image and static SDK have to be updated together.
ARG SWIFT_VERSION=6.1.2
ARG SWIFT_SDK_VERSION=0.0.1
ARG SWIFT_SDK_CHECKSUM=df0b40b9b582598e7e3d70c82ab503fd6fbfdff71fd17e7f1ab37115a0665b3b
ARG RUNTIME_IMAGE=ubuntu:noble
FROM swift:${SWIFT_VERSION}-noble AS builder

LABEL org.opencontainers.image.source=https://github.com/realm/SwiftLint

RUN apt-get update
RUN apt-get install -y libcurl4-openssl-dev libxml2-dev
RUN rm -r /var/lib/apt/lists/*

WORKDIR /workspace
COPY Plugins Plugins/
COPY Source Source/
COPY Tests Tests/
COPY Package.* ./
COPY tools/build-linux-release.sh tools/

RUN swift sdk install \
	https://download.swift.org/swift-${SWIFT_VERSION}-release/static-sdk/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE_static-linux-${SWIFT_SDK_VERSION}.artifactbundle.tar.gz \
	--checksum ${SWIFT_SDK_CHECKSUM}

ARG TARGETPLATFORM
RUN --mount=type=cache,target=/workspace/.build,id=build-$TARGETPLATFORM ./tools/build-linux-release.sh

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
COPY --from=builder /workspace/swiftlint_linux_* /usr/bin/

RUN swiftlint version
RUN echo "_ = 0" | swiftlint --use-stdin

ENTRYPOINT [ "/usr/bin/swiftlint" ]
CMD ["."]

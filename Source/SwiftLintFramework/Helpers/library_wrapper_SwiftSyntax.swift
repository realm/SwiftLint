import SwiftSyntax

let initializeSwiftSyntax: Void = {
    _ = toolchainLoader.load(path: "lib_InternalSwiftSyntaxParser.dylib")
    do {
        _ = try SyntaxParser.parse(source: "")
    } catch ParserError.parserCompatibilityCheckFailed {
        queuedFatalError("Unable to find appropriate Xcode")
    } catch {
    }
}()

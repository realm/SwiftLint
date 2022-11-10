import Foundation
import IndexStore
import SwiftSyntax

// MARK: - UnusedDeclarationException

/// A rule determining that a declaration should not be reported as unused.
struct UnusedDeclarationException {
    /// Whether a declaration should not be reported as unused.
    let skipReportingUnusedDeclaration: (Declaration, SourceFileSyntax) -> Bool
}

// MARK: - Exceptions

extension UnusedDeclarationException {
    /// All exceptions that should be applied when calculating unused declarations, in the order they should
    /// be checked. The order should generally be computationally cheapest to most expensive.
    static var all: [UnusedDeclarationException] {
        [
            .hasAttributesToSkip,
            .isAppDelegate,
            .isSceneDelegate,
            .isUNNotificationContentExtension,
            .isPreviewProvider,
            .isDisabledByCommentCommand,
            .isRawValueEnumCase,
            .isSkippableInitializer
        ]
    }
}

// MARK: - Private

private extension UnusedDeclarationException {
    /// The declaration has some attributes that shouldn't be reported as unused because they can be
    /// referenced from interface builder or accessed at runtime.
    static let hasAttributesToSkip = UnusedDeclarationException { declaration, tree in
        let attributes = declaration.attributes(in: tree)
        if attributes.contains("main") {
            return true
        } else if declaration.kind == .instanceProperty && attributes.contains("IBInspectable") {
            return true
        } else if declaration.kind == .instanceMethod && attributes.contains("objc") {
            return true
        } else {
            return false
        }
    }

    /// The occurrence is a UIKit app delegate, which are typically never referenced explicitly but looked up
    /// at runtime.
    static let isAppDelegate = UnusedDeclarationException { declaration, tree in
        let visitor = ConformanceVisitor(symbolName: declaration.name)
        visitor.walk(tree)
        return visitor.conformances.contains("UIApplicationDelegate")
    }

    /// The occurrence is a UIKit scene delegate, which are typically never referenced explicitly but
    /// referenced in the target's Info.plist.
    static let isSceneDelegate = UnusedDeclarationException { declaration, tree in
        let visitor = ConformanceVisitor(symbolName: declaration.name)
        visitor.walk(tree)
        return visitor.conformances.contains("UISceneDelegate")
    }

    /// The occurrence is a `UNNotificationContentExtension`, which are typically never referenced explicitly
    /// but specified in the extension's `Info.plist`.
    static let isUNNotificationContentExtension = UnusedDeclarationException { declaration, tree in
        let visitor = ConformanceVisitor(symbolName: declaration.name)
        visitor.walk(tree)
        return visitor.conformances.contains("UNNotificationContentExtension")
    }

    /// The occurrence is a SwiftUI Preview Provider, which are typically never referenced explicitly but
    /// loaded by Xcode Live Previews.
    static let isPreviewProvider = UnusedDeclarationException { declaration, tree in
        guard declaration.name.hasSuffix("_Previews") else {
            return false
        }

        let visitor = ConformanceVisitor(symbolName: declaration.name)
        visitor.walk(tree)
        return visitor.conformances.contains("PreviewProvider")
    }

    /// The declaration is in a SwiftLint-style disabled region: `// swiftlint:disable unused_declaration`.
    static let isDisabledByCommentCommand = UnusedDeclarationException { declaration, tree in
        return declaration.isDisabled(in: tree)
    }

    /// The declaration is an enum case backed by a raw value which can be constructed indirectly.
    static let isRawValueEnumCase = UnusedDeclarationException { declaration, tree in
        guard declaration.kind == .enumCase else {
            return false
        }

        let locationConverter = SourceLocationConverter(file: declaration.file, tree: tree)
        let visitor = RawValueEnumCaseVisitor(line: declaration.line, locationConverter: locationConverter)
        return visitor.walk(tree: tree, handler: \.isRawValueEnumCase)
    }

    static let isSkippableInitializer = UnusedDeclarationException { declaration, tree in
        guard declaration.kind == .initializer else {
            return false
        }

        let locationConverter = SourceLocationConverter(file: declaration.file, tree: tree)
        let visitor = SkippableInitVisitor(line: declaration.line, locationConverter: locationConverter)
        return visitor.walk(tree: tree, handler: \.unusedDeclarationException)
    }
}

private extension Declaration {
    func attributes(in tree: SourceFileSyntax) -> [String] {
        AttributeVisitor(line: line, locationConverter: SourceLocationConverter(file: file, tree: tree))
            .walk(tree: tree, handler: \.attributes)
    }
}

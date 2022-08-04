import Foundation
import SourceKittenFramework

public struct ForceUnwrappingRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("if let url = NSURL(string: query)"),
            Example("navigationController?.pushViewController(viewController, animated: true)"),
            Example("let s as! Test"),
            Example("try! canThrowErrors()"),
            Example("let object: Any!"),
            Example("@IBOutlet var constraints: [NSLayoutConstraint]!"),
            Example("setEditing(!editing, animated: true)"),
            Example("navigationController.setNavigationBarHidden(!navigationController." +
                "navigationBarHidden, animated: true)"),
            Example("if addedToPlaylist && (!self.selectedFilters.isEmpty || " +
                "self.searchBar?.text?.isEmpty == false) {}"),
            Example("print(\"\\(xVar)!\")"),
            Example("var test = (!bar)"),
            Example("var a: [Int]!"),
            Example("private var myProperty: (Void -> Void)!"),
            Example("func foo(_ options: [AnyHashable: Any]!) {"),
            Example("func foo() -> [Int]!"),
            Example("func foo() -> [AnyHashable: Any]!"),
            Example("func foo() -> [Int]! { return [] }"),
            Example("return self")
        ],
        triggeringExamples: [
            Example("let url = NSURL(string: query)↓!"),
            Example("navigationController↓!.pushViewController(viewController, animated: true)"),
            Example("let unwrapped = optional↓!"),
            Example("return cell↓!"),
            Example("let url = NSURL(string: \"http://www.google.com\")↓!"),
            Example("let dict = [\"Boooo\": \"👻\"]func bla() -> String { return dict[\"Boooo\"]↓! }"),
            Example("let dict = [\"Boooo\": \"👻\"]func bla() -> String { return dict[\"Boooo\"]↓!.contains(\"B\") }"),
            Example("let a = dict[\"abc\"]↓!.contains(\"B\")"),
            Example("dict[\"abc\"]↓!.bar(\"B\")"),
            Example("if dict[\"a\"]↓!!!! {"),
            Example("var foo: [Bool]! = dict[\"abc\"]↓!"),
            Example("""
            context("abc") {
              var foo: [Bool]! = dict["abc"]↓!
            }
            """),
            Example("open var computed: String { return foo.bar↓! }"),
            Example("return self↓!")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // capture previous of "!"
    // http://userguide.icu-project.org/strings/regexp
    private static let pattern = "([^\\s\\p{Ps}])(!+)"
    // Match any variable declaration
    // Has a small bug in @IBOutlet due suffix "let"
    // But that does not compromise the filtering for var declarations
    private static let varDeclarationPattern = "\\s?(?:let|var)\\s+[^=\\v{]*!"

    private static let functionReturnPattern = "\\)\\s*->\\s*[^\\n\\{=]*!"

    private static let regularExpression = regex(pattern)
    private static let varDeclarationRegularExpression = regex(varDeclarationPattern)
    private static let excludingSyntaxKindsForFirstCapture =
        SyntaxKind.commentAndStringKinds.union([.keyword, .typeidentifier])
    private static let excludingSyntaxKindsForSecondCapture = SyntaxKind.commentAndStringKinds

    private func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let syntaxMap = file.syntaxMap

        let varDeclarationRanges = Self.varDeclarationRegularExpression
            .matches(in: file)
            .compactMap { match -> NSRange? in
                return match.range
            }

        let functionDeclarationRanges = regex(Self.functionReturnPattern)
            .matches(in: file)
            .compactMap { match -> NSRange? in
                return match.range
            }

        return Self.regularExpression
            .matches(in: file)
            .compactMap { match -> NSRange? in
                if match.range.intersects(varDeclarationRanges) || match.range.intersects(functionDeclarationRanges) {
                    return nil
                }

                return violationRange(match: match, syntaxMap: syntaxMap, file: file)
            }
    }

    private func violationRange(match: NSTextCheckingResult, syntaxMap: SwiftLintSyntaxMap,
                                file: SwiftLintFile) -> NSRange? {
        if match.numberOfRanges < 3 { return nil }

        let firstRange = match.range(at: 1)
        let secondRange = match.range(at: 2)

        guard let matchByteFirstRange = file.stringView
            .NSRangeToByteRange(start: firstRange.location, length: firstRange.length),
            let matchByteSecondRange = file.stringView
                .NSRangeToByteRange(start: secondRange.location, length: secondRange.length)
            else { return nil }

        // check first captured range
        // If not empty, first captured range is comment, string, typeidentifier or keyword that is not `self`.
        // We checks "not empty" because kinds may empty without filtering.
        guard !isFirstRangeExcludedToken(byteRange: matchByteFirstRange, syntaxMap: syntaxMap, file: file) else {
            return nil
        }

        let violationRange = NSRange(location: NSMaxRange(firstRange), length: 0)
        let kindsInFirstRange = syntaxMap.kinds(inByteRange: matchByteFirstRange)

        // if first captured range is identifier or keyword (self), generate violation
        if !Set(kindsInFirstRange).isDisjoint(with: [.identifier, .keyword]) {
            return violationRange
        }

        // check if firstCapturedString is either ")" or "]" 
        // and '!' is not within comment or string
        // and matchByteFirstRange is not a type annotation
        let firstCapturedString = file.stringView.substring(with: firstRange)
        if [")", "]"].contains(firstCapturedString) {
            // check second capture '!'
            let kindsInSecondRange = syntaxMap.kinds(inByteRange: matchByteSecondRange)
            let forceUnwrapNotInCommentOrString = !kindsInSecondRange
                .contains(where: Self.excludingSyntaxKindsForSecondCapture.contains)
            if forceUnwrapNotInCommentOrString &&
                !isTypeAnnotation(in: file, byteRange: matchByteFirstRange) {
                return violationRange
            }
        }

        return nil
    }

    // check if first captured range is comment, string, typeidentifier, or a keyword that is not `self`.
    private func isFirstRangeExcludedToken(byteRange: ByteRange, syntaxMap: SwiftLintSyntaxMap,
                                           file: SwiftLintFile) -> Bool {
        let tokens = syntaxMap.tokens(inByteRange: byteRange)
        return tokens.contains { token in
            guard let kind = token.kind,
                Self.excludingSyntaxKindsForFirstCapture.contains(kind)
                else { return false }
            // check for `self
            guard kind == .keyword else { return true }
            return file.contents(for: token) != "self"
        }
    }

    // check deepest kind matching range in structure is a typeAnnotation
    private func isTypeAnnotation(in file: SwiftLintFile, byteRange: ByteRange) -> Bool {
        let kinds = file.structureDictionary.kinds(forByteOffset: byteRange.location)
        guard let lastItem = kinds.last,
            let lastKind = SwiftDeclarationKind(rawValue: lastItem.kind),
            SwiftDeclarationKind.variableKinds.contains(lastKind) else {
                return false
        }

        // range is in some "source.lang.swift.decl.var.*"
        let varRange = ByteRange(location: lastItem.byteRange.location,
                                 length: byteRange.location - lastItem.byteRange.location)
        if let varDeclarationString = file.stringView.substringWithByteRange(varRange),
            varDeclarationString.contains("=") {
            // if declarations contains "=", range is not type annotation
            return false
        }

        // range is type annotation of declaration
        return true
    }
}

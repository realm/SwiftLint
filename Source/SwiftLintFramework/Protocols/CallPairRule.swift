import Foundation
import SourceKittenFramework

internal protocol CallPairRule: Rule {}

extension CallPairRule {
    /**
     Validates the given file for pairs of expressions where the first part of the expression
     is a method call (with or without parameters) having the given `callNameSuffix` and the
     second part is some expression matching the given pattern which is looked up in expressions
     of the given syntax kind.
     
     Example:
     ```
     .someMethodCall(someParams: param).someExpression
     \_____________/                  \______________/
      callNameSuffix                      pattern
     ```
     
     - parameter file: The file to validate
     - parameter pattern: Regular expression which matches the second part of the expression
     - parameter patternSyntaxKinds: Syntax kinds matches should have
     - parameter callNameSuffix: Suffix of the first method call name
     - parameter severity: Severity of violations
     - parameter reason: The reason of the generated violations
     - parameter predicate: Predicate to apply after checking callNameSuffix
     */
    internal func validate(file: SwiftLintFile,
                           pattern: String,
                           patternSyntaxKinds: [SyntaxKind],
                           callNameSuffix: String,
                           severity: ViolationSeverity,
                           reason: String? = nil,
                           predicate: (SourceKittenDictionary) -> Bool = { _ in true }) -> [StyleViolation] {
        let firstRanges = file.match(pattern: pattern, with: patternSyntaxKinds)
        let stringView = file.stringView
        let dictionary = file.structureDictionary

        let violatingLocations: [ByteCount] = firstRanges.compactMap { range in
            guard let bodyByteRange = stringView.NSRangeToByteRange(start: range.location, length: range.length),
                case let firstLocation = range.location + range.length - 1,
                let firstByteRange = stringView.NSRangeToByteRange(start: firstLocation, length: 1) else {
                return nil
            }

            return methodCall(forByteOffset: bodyByteRange.location - 1,
                              excludingOffset: firstByteRange.location,
                              dictionary: dictionary,
                              predicate: { dictionary in
                guard let name = dictionary.name else {
                    return false
                }

                return name.hasSuffix(callNameSuffix) && predicate(dictionary)
            })
        }

        return violatingLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: severity,
                           location: Location(file: file, byteOffset: $0),
                           reason: reason)
        }
    }

    private func methodCall(forByteOffset byteOffset: ByteCount, excludingOffset: ByteCount,
                            dictionary: SourceKittenDictionary,
                            predicate: (SourceKittenDictionary) -> Bool) -> ByteCount? {
        if dictionary.expressionKind == .call, let byteRange = dictionary.byteRange {
            if byteRange.contains(byteOffset) &&
                !byteRange.contains(excludingOffset) &&
                predicate(dictionary) {
                return dictionary.offset
            }
        }

        for dictionary in dictionary.substructure {
            if let offset = methodCall(forByteOffset: byteOffset,
                                       excludingOffset: excludingOffset,
                                       dictionary: dictionary,
                                       predicate: predicate) {
                return offset
            }
        }

        return nil
    }
}

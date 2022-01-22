/// A protocol that enabled caching for collecting rules
public protocol CollectingCacheable {
    /// Converts the collecting info to a dto used for caching
    func toDto() -> CollectingCacheDto
    /// Initializies the collecting info from a cache dto
    static func fromDto(_ collectingCacheDto: CollectingCacheDto) -> Self?
}

/// The dto used to cache the collect info of a rule
public enum CollectingCacheDto: Codable {
    /// Wraps the cache dto for the UnusedDeclarationRule
    case unusedDeclaration(UnusedDeclarationRule.FileInfo.CacheDto)
    /// Wraps the cache dto for the CaptureVariableRule
    case captureVariable(CaptureVariableRule.FileInfo.CacheDto)

    public init(from decoder: Decoder) throws {
        guard let key = decoder.codingPath.last else {
            let context = DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: ErrorDescription.expectedOneKey(decoder.codingPath)
            )
            throw DecodingError.dataCorrupted(context)
        }

        switch RuleId(rawValue: key.stringValue) {
        case .unusedDeclaration:
            let wrapped = try UnusedDeclarationRule.FileInfo.CacheDto(from: decoder)
            self = .unusedDeclaration(wrapped)

        case .captureVariable:
            let wrapped = try CaptureVariableRule.FileInfo.CacheDto(from: decoder)
            self = .captureVariable(wrapped)

        case nil:
            let context = DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: ErrorDescription.unsupportedKey(key)
            )
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        guard let key = encoder.codingPath.last else {
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: ErrorDescription.expectedOneKey(encoder.codingPath)
            )
            throw EncodingError.invalidValue(self, context)
        }

        guard let ruleId = RuleId(rawValue: key.stringValue) else {
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: ErrorDescription.unsupportedKey(key)
            )
            throw EncodingError.invalidValue(self, context)
        }

        let result: Codable
        switch (ruleId, self) {
        case let (.unusedDeclaration, .unusedDeclaration(wrapped)): result = wrapped
        case let (.captureVariable, .captureVariable(wrapped)): result = wrapped
        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: ErrorDescription.unexpectedEncodingKey(key, for: self.ruleId)
            )
            throw EncodingError.invalidValue(self, context)
        }
        try result.encode(to: encoder)
    }

    private var ruleId: RuleId {
        switch self {
        case .unusedDeclaration: return .unusedDeclaration
        case .captureVariable: return .captureVariable
        }
    }
}

private enum RuleId: RawRepresentable, CaseIterable {
    case unusedDeclaration
    case captureVariable

    init?(rawValue: String) {
        switch rawValue {
        case Self.unusedDeclaration.rawValue: self = .unusedDeclaration
        case Self.captureVariable.rawValue: self = .captureVariable
        default: return nil
        }
    }

    var rawValue: String {
        let rule: Rule.Type
        switch self {
        case .unusedDeclaration: rule = UnusedDeclarationRule.self
        case .captureVariable: rule = CaptureVariableRule.self
        }
        return rule.description.identifier
    }
}

private enum ErrorDescription {
    static func expectedOneKey(_ codingPath: [CodingKey]) -> String {
        return "Invalid codingPath '\(codingPath)' found: expected at least one component"
    }

    static func unsupportedKey(_ key: CodingKey) -> String {
        return [
            "Unsupported key '\(key.stringValue)' does not match any of the supported values:",
            RuleId.allCases.map { $0.rawValue }.joined(separator: ", ")
        ].joined(separator: " ")
    }

    static func unexpectedEncodingKey(_ key: CodingKey, for value: RuleId) -> String {
        return "Encoding key '\(key.stringValue)' does not match encoding value '\(value.rawValue)'"
    }
}

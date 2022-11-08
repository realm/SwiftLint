import Foundation
import SourceKittenFramework

struct FileTypesOrderRule: ConfigurationProviderRule, OptInRule {
    private typealias FileTypeOffset = (fileType: FileType, offset: ByteCount)

    var configuration = FileTypesOrderConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "file_types_order",
        name: "File Types Order",
        description: "Specifies how the types within a file should be ordered.",
        kind: .style,
        nonTriggeringExamples: FileTypesOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: FileTypesOrderRuleExamples.triggeringExamples
    )

    // swiftlint:disable:next function_body_length
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let mainTypeSubstructure = mainTypeSubstructure(in: file),
              let mainTypeSubstuctureOffset = mainTypeSubstructure.offset else { return [] }

        let extensionsSubstructures = self.extensionsSubstructures(
            in: file,
            mainTypeSubstructure: mainTypeSubstructure
        )

        let supportingTypesSubstructures = self.supportingTypesSubstructures(
            in: file,
            mainTypeSubstructure: mainTypeSubstructure
        )

        let previewProviderSubstructures = self.substructures(
            in: file,
            withInheritedType: "PreviewProvider"
        )

        let libraryContentSubstructures = self.substructures(
            in: file,
            withInheritedType: "LibraryContentProvider"
        )

        let mainTypeOffset: [FileTypeOffset] = [(.mainType, mainTypeSubstuctureOffset)]
        let extensionOffsets: [FileTypeOffset] = extensionsSubstructures.offsets(for: .extension)
        let supportingTypeOffsets: [FileTypeOffset] = supportingTypesSubstructures.offsets(for: .supportingType)
        let previewProviderOffsets: [FileTypeOffset] = previewProviderSubstructures.offsets(for: .previewProvider)
        let libraryContentOffsets: [FileTypeOffset] = libraryContentSubstructures.offsets(for: .libraryContentProvider)

        let allOffsets = mainTypeOffset
            + extensionOffsets
            + supportingTypeOffsets
            + previewProviderOffsets
            + libraryContentOffsets

        let orderedFileTypeOffsets = allOffsets.sorted { lhs, rhs in lhs.offset < rhs.offset }

        var violations = [StyleViolation]()

        var lastMatchingIndex = -1
        for expectedTypes in configuration.order {
            var potentialViolatingIndexes = [Int]()

            let startIndex = lastMatchingIndex + 1
            (startIndex..<orderedFileTypeOffsets.count).forEach { index in
                let fileType = orderedFileTypeOffsets[index].fileType
                if expectedTypes.contains(fileType) {
                    lastMatchingIndex = index
                } else {
                    potentialViolatingIndexes.append(index)
                }
            }

            let violatingIndexes = potentialViolatingIndexes.filter { $0 < lastMatchingIndex }
            violatingIndexes.forEach { index in
                let fileTypeOffset = orderedFileTypeOffsets[index]

                let fileType = fileTypeOffset.fileType.rawValue
                let expected = expectedTypes.map { $0.rawValue }.joined(separator: ",")
                let article = ["a", "e", "i", "o", "u"].contains(fileType.substring(from: 0, length: 1)) ? "An" : "A"

                let styleViolation = StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: fileTypeOffset.offset),
                    reason: "\(article) '\(fileType)' should not be placed amongst the file type(s) '\(expected)'."
                )
                violations.append(styleViolation)
            }
        }

        return violations
    }

    private func extensionsSubstructures(
        in file: SwiftLintFile,
        mainTypeSubstructure: SourceKittenDictionary
    ) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary
        return dict.substructure.filter { substructure in
            guard let kind = substructure.kind else { return false }
            return substructure.offset != mainTypeSubstructure.offset
                && kind.contains(SwiftDeclarationKind.extension.rawValue)
        }
    }

    private func supportingTypesSubstructures(
        in file: SwiftLintFile,
        mainTypeSubstructure: SourceKittenDictionary
    ) -> [SourceKittenDictionary] {
        var supportingTypeKinds = SwiftDeclarationKind.typeKinds
        supportingTypeKinds.insert(SwiftDeclarationKind.protocol)

        let dict = file.structureDictionary
        return dict.substructure.filter { substructure in
            guard let declarationKind = substructure.declarationKind else { return false }
            guard !substructure.hasExcludedInheritedType else { return false }

            return substructure.offset != mainTypeSubstructure.offset
                && supportingTypeKinds.contains(declarationKind)
        }
    }

    private func substructures(
        in file: SwiftLintFile,
        withInheritedType inheritedType: String
    ) -> [SourceKittenDictionary] {
        file.structureDictionary.substructure.filter { substructure in
            substructure.inheritedTypes.contains(inheritedType)
        }
    }

    private func mainTypeSubstructure(in file: SwiftLintFile) -> SourceKittenDictionary? {
        let dict = file.structureDictionary

        guard let filePath = file.path else {
            return self.mainTypeSubstructure(in: dict)
        }

        let fileName = URL(fileURLWithPath: filePath, isDirectory: false)
            .lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        guard let mainTypeSubstructure = dict.substructure.first(where: { $0.name == fileName }) else {
            return self.mainTypeSubstructure(in: file.structureDictionary)
        }

        // specify type with name matching the files name as main type
        return mainTypeSubstructure
    }

    private func mainTypeSubstructure(in dict: SourceKittenDictionary) -> SourceKittenDictionary? {
        let priorityKinds: [SwiftDeclarationKind] = [.class, .enum, .struct]

        let priorityKindSubstructures = dict.substructure.filter { substructure in
            guard let kind = substructure.declarationKind else { return false }
            guard !substructure.hasExcludedInheritedType else { return false }

            return priorityKinds.contains(kind)
        }

        let substructuresSortedByBodyLength = priorityKindSubstructures.sorted { lhs, rhs in
            (lhs.bodyLength ?? 0) > (rhs.bodyLength ?? 0)
        }

        // specify class, enum or struct with longest body as main type
        return substructuresSortedByBodyLength.first
    }
}

private extension SourceKittenDictionary {
    var hasExcludedInheritedType: Bool {
        self.inheritedTypes.contains { inheritedType in
            inheritedType == "PreviewProvider" || inheritedType == "LibraryContentProvider"
        }
    }
}

private extension Array where Element == SourceKittenDictionary {
    func offsets(for fileType: FileType) -> [(fileType: FileType, offset: ByteCount)] {
        self.compactMap { substructure in
            guard let offset = substructure.offset else { return nil }
            return (fileType, offset)
        }
    }
}

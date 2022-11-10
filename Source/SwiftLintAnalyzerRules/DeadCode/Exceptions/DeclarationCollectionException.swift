import IndexStore

// MARK: - DeclarationCollectionException

/// A rule determining that an occurrence should not be collected as a declaration because it should not be
/// treated as unused if there are no references to it.
struct DeclarationCollectionException {
    /// Whether an occurrence should be skipped when collecting declarations.
    let skipCollectingOccurrence: (SymbolOccurrence) -> Bool

    /// All exceptions that should be applied when collecting declarations, in order they should be checked.
    /// Order should generally be computationally cheapest to most expensive.
    static var all: [DeclarationCollectionException] {
        [
            .notADefinition,
            .isStaticAllTests,
            .isGenericParameter,
            .hasKindsToSkip,
            .hasSymbolPropertiesToSkip,
            .hasRolesToSkip,
            .isDyldWarningWorkaround,
            // The following are fuzzy checks. It would be nice to more formally identify these cases.
            .isLikelyCodableCodingKeys,
            .isLikelySR11985FalsePositive,
            .isLikelyProtocolRequirement,
            .isLikelyResultBuilder,
            .isLikelyDynamicMemberLookup,
            .isLikelyPropertyWrapperProjectedValue
        ]
    }
}

// MARK: - Private

private extension DeclarationCollectionException {
    /// The occurrence is not a definition, so it should be skipped when collecting declaration occurrences.
    static let notADefinition = DeclarationCollectionException { occurrence in
        !occurrence.roles.contains(.definition)
    }

    /// The occurrence is a static `allTests` variable, so it should be skipped when collecting declaration occurrences.
    static let isStaticAllTests = DeclarationCollectionException { occurrence in
        occurrence.symbol.kind == .staticProperty &&
            occurrence.symbol.roles.contains(.childOf) &&
            occurrence.symbol.name == "allTests"
    }

    /// The occurrence is a generic parameter.
    static let isGenericParameter = DeclarationCollectionException { occurrence in
        occurrence.symbol.subkind == .swiftGenericParameter
    }

    /// The occurrence is of a kind that should not be surfaced as unused, such as:
    ///
    /// * deinitializers
    /// * function parameters
    /// * type extensions
    static let hasKindsToSkip = DeclarationCollectionException { occurrence in
        let kindsToSkip: [SymbolKind] = [
            .destructor,
            .parameter,
            .extension
        ]

        return kindsToSkip.contains(occurrence.symbol.kind)
    }

    /// The occurrence has associated symbol properties that should not be surfaced as unused, such as:
    ///
    /// * having Interface Builder annotations, or
    /// * being part of the unit test machinery
    static let hasSymbolPropertiesToSkip = DeclarationCollectionException { occurrence in
#if os(macOS)
        let propertiesToSkip: SymbolProperty = [
            .IBAnnotated,
            .unitTest
        ]

        return !occurrence.symbol.properties.isDisjoint(with: propertiesToSkip)
#else
        let properties = occurrence.symbol.properties
        let ibannotated = SymbolProperty(SymbolProperty.IBAnnotated)
        let unittest = SymbolProperty(SymbolProperty.unitTest)
        return properties & ibannotated == ibannotated ||
            properties & unittest == unittest
#endif
    }

    /// The occurrence has associated symbol roles that should not be surfaced as unused, such as:
    ///
    /// * being an accessor
    /// * being implicit (not source code)
    /// * being a superclass or protocol override
    /// * being marked as "dynamic", meaning it can be accessed dynamically by the runtime even if not
    ///   explicitly referenced in source code
    static let hasRolesToSkip = DeclarationCollectionException { occurrence in
        let rolesToSkip: SymbolRoles = [
            .accessorOf,
            .implicit,
            .overrideOf
        ]

        return !occurrence.roles.isDisjoint(with: rolesToSkip) ||
            !occurrence.symbol.roles.isDisjoint(with: rolesToSkip)
    }

    /// The occurrence is part of a DyldWarningWorkaround macro.
    static let isDyldWarningWorkaround = DeclarationCollectionException { occurrence in
        occurrence.symbol.usr.contains("DyldWarningWorkaround") ||
            occurrence.symbol.name.starts(with: "__set___objc_dupclass_sym___duplicate_class__")
    }

    /// The occurrence is likely to be the `CodingKeys` enum used by Codable.
    static let isLikelyCodableCodingKeys = DeclarationCollectionException { occurrence in
        return occurrence.symbol.name == "CodingKeys" &&
            occurrence.symbol.kind == .enum &&
            occurrence.symbol.roles.contains(.childOf)
    }

    /// The occurrence is likely to be a UIKit delegate protocol function, which don't get indexed properly:
    /// https://bugs.swift.org/browse/SR-11985
    static let isLikelySR11985FalsePositive = DeclarationCollectionException { occurrence in
        /// Not an exhaustive list, add as needed.
        let functionsToSkip = [
            "navigationBar(_:didPop:)",
            "position(for:)",
            "scrollViewDidEndDecelerating(_:)",
            "scrollViewDidEndDragging(_:willDecelerate:)",
            "scrollViewDidScroll(_:)",
            "scrollViewDidScrollToTop(_:)",
            "scrollViewWillBeginDragging(_:)",
            "scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)",
            "tableView(_:canEditRowAt:)",
            "tableView(_:commit:forRowAt:)",
            "tableView(_:editingStyleForRowAt:)",
            "tableView(_:willDisplayHeaderView:forSection:)",
            "tableView(_:willSelectRowAt:)"
        ]

        return occurrence.symbol.kind == .instanceMethod &&
            functionsToSkip.contains(occurrence.symbol.name)
    }

    /// The occurrence is likely to be a protocol requirement because it is a child of a protocol definition.
    static let isLikelyProtocolRequirement = DeclarationCollectionException { occurrence in
        guard SymbolKind.protocolRequirementKinds.contains(occurrence.symbol.kind) else {
            return false
        }

        return occurrence.mapFirstRelation(
            matching: { $0.kind == .protocol && $1.contains(.childOf) },
            transform: { _, _ in true }
        ) ?? false
    }

    /// The occurrence is likely to be defined to implement a result builder. These static
    /// functions are typically never referenced explicitly but implicitly referenced by the compiler.
    static let isLikelyResultBuilder = DeclarationCollectionException { occurrence in
        guard occurrence.symbol.kind == .staticMethod else {
            return false
        }

        // https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md#result-building-methods
        let resultBuilderStaticMethods = [
            "buildBlock(_:)",
            "buildIf(_:)",
            "buildOptional(_:)",
            "buildEither(_:)",
            "buildArray(_:)",
            "buildExpression(_:)",
            "buildFinalResult(_:)",
            "buildLimitedAvailability(_:)",
            // https://github.com/apple/swift-evolution/blob/main/proposals/0348-buildpartialblock.md
            "buildPartialBlock(first:)",
            "buildPartialBlock(accumulated:next:)"
        ]

        return resultBuilderStaticMethods.contains(occurrence.symbol.name)
    }

    /// The occurrence is likely to be used for `@dynamicMemberLookup`, which are typically never referenced
    /// explicitly but used by the dynamic member lookup syntax.
    static let isLikelyDynamicMemberLookup = DeclarationCollectionException { occurrence in
        return occurrence.symbol.kind == .instanceProperty &&
            occurrence.symbol.name == "subscript(dynamicMember:)"
    }

    /// The occurrence is likely to be used for `@propertyWrapper`, which are typically never referenced
    /// explicitly but required to implement property wrappers.
    static let isLikelyPropertyWrapperProjectedValue = DeclarationCollectionException { occurrence in
        return occurrence.symbol.kind == .instanceProperty &&
            occurrence.symbol.name == "projectedValue"
    }
}

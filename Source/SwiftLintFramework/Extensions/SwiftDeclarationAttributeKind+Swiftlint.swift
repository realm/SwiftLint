import SourceKittenFramework

extension SwiftDeclarationAttributeKind {
    static var attributesRequiringFoundation: Set<SwiftDeclarationAttributeKind> {
        return [
            .objc,
            .objcName,
            .objcMembers,
            .objcNonLazyRealization
        ]
    }

    enum ModifierGroup: String, CustomDebugStringConvertible {
        case `override`
        case acl
        case setterACL
        case owned
        case mutators
        case final
        case typeMethods
        case `required`
        case `convenience`
        case `lazy`
        case `dynamic`
        case atPrefixed

        init?(rawAttribute: String) {
            let allModifierGroups: Set<SwiftDeclarationAttributeKind.ModifierGroup> = [
                .acl, .setterACL, .mutators, .override, .owned, .atPrefixed, .dynamic, .final, .typeMethods,
                .required, .convenience, .lazy
            ]
            let modifierGroup = allModifierGroups.first {
                $0.swiftDeclarationAttributeKinds.contains(where: { $0.rawValue == rawAttribute })
            }

            if let modifierGroup {
                self = modifierGroup
            } else {
                return nil
            }
        }

        var swiftDeclarationAttributeKinds: Set<SwiftDeclarationAttributeKind> {
            switch self {
            case .acl:
                return [
                    .private,
                    .fileprivate,
                    .internal,
                    .public,
                    .open
                ]
            case .setterACL:
                return [
                    .setterPrivate,
                    .setterFilePrivate,
                    .setterInternal,
                    .setterPublic,
                    .setterOpen
                ]
            case .mutators:
                return [
                    .mutating,
                    .nonmutating
                ]
            case .override:
                return [.override]
            case .owned:
                return [.weak]
            case .final:
                return [.final]
            case .typeMethods:
                return []
            case .required:
                return [.required]
            case .convenience:
                return [.convenience]
            case .lazy:
                return [.lazy]
            case .dynamic:
                return [.dynamic]
            case .atPrefixed:
                return [
                    .objc,
                    .nonobjc,
                    .objcMembers,
                    .ibaction,
                    .iboutlet,
                    .ibdesignable,
                    .ibinspectable,
                    .nsManaged,
                    .nsCopying
                ]
            }
        }

        var debugDescription: String {
            return self.rawValue
        }
    }
}

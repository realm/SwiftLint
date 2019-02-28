internal struct NSObjectPreferIsEqualRuleExamples {
    static let nonTriggeringExamples: [String] = [
        // NSObject subclass without ==
        """
        class AClass: NSObject {
        }
        """,
        // @objc class without ==
        """
        @objc class AClass: SomeNSObjectSubclass {
        }
        """,
        // Class with == which does not subclass NSObject
        """
        class AClass: Equatable {
            static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return true
            }
        """,
        // NSObject subclass implementing isEqual
        """
        class AClass: NSObject {
            override func isEqual(_ object: Any?) -> Bool {
                return true
            }
        }
        """,
        // @objc class implementing isEqual
        """
        @objc class AClass: SomeNSObjectSubclass {
            override func isEqual(_ object: Any?) -> Bool {
                return false
            }
        }
        """,
        // NSObject subclass with non-static ==
        """
        class AClass: NSObject {
            func ==(lhs: AClass, rhs: AClass) -> Bool {
                return true
            }
        }
        """,
        // NSObject subclass implementing == with different signature
        """
        class AClass: NSObject {
            static func ==(lhs: AClass, rhs: BClass) -> Bool {
                return true
            }
        }
        """,
        // Equatable struct
        """
        struct AStruct: Equatable {
            static func ==(lhs: AStruct, rhs: AStruct) -> Bool {
                return false
            }
        }
        """,
        // Equatable enum
        """
        enum AnEnum: Equatable {
            static func ==(lhs: AnEnum, rhs: AnEnum) -> Bool {
                return true
            }
        }
        """
    ]

    static let triggeringExamples: [String] = [
        // NSObject subclass implementing ==
        """
        class AClass: NSObject {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """,
        // @objc class implementing ==
        """
        @objc class AClass: SomeOtherNSObjectSubclass {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return true
            }
        }
        """,
        // Equatable NSObject subclass implementing ==
        """
        class AClass: NSObject, Equatable {
            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """,
        // NSObject subclass overriding isEqual and implementing ==
        """
        class AClass: NSObject {
            override func isEqual(_ object: Any?) -> Bool {
                guard let other = object as? AClass else {
                    return false
                }
                return true
            }

            ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
                return false
            }
        }
        """
    ]
}

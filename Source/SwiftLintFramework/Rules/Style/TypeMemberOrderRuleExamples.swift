internal struct TypeMemberOrderRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct Car {
            let numberOfDoors: Int
            let `wheelSize`: Int
        }
        """),
        Example("""
        struct Car {
            let numberOfDoors: Int
            let wheelSize: Int

            // MARK: More stuff
            let accessories: [Accessory]
        """),
        Example("""
        struct Car {
            let numberOfDoors: Int
            let wheelSize: Int

            func accelerate() {}
            func brake() {}
        }
        """),
        Example("""
        // with `separate_by_member_types` set to false in configuration
        struct Car {
            func accelerate() {}
            func brake() {}
            let numberOfDoors: Int
            func rev() {}
            let wheelSize: Int
        }
        """, configuration: ["separate_by_member_types": false]),
        Example("""
        // with `separate_by_member_types` set to false in configuration
        struct Car {
            func accelerate() {}

            struct Wheel {
                let wheelSize: Int
            }

            let wheelCount: Int
        }
        """, configuration: ["separate_by_member_types": false])
    ]

    static let triggeringExamples = [
        Example("""
        struct Car {
            let wheelSize: Int
            let ↓numberOfDoors: Int
        }
        """),
        Example("""
        struct Car {
            let numberOfDoors: Int
            let wheelSize: Int

            func brake() {}
            func ↓accelerate() {}
        }
        """),
        Example("""
        // with `separate_by_member_types` set to false in configuration
        struct Car {
            func accelerate() {}
            func brake() {}
            func rev() {}

            let ↓numberOfDoors: Int
            let wheelSize: Int
        }
        """, configuration: ["separate_by_member_types": false])
    ]
}

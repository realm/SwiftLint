struct RedundantSelfInClosureRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
            struct S {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f {
                        x = 1
                        f { x = 1 }
                        g()
                    }
                }
            }
            """),
        Example("""
            class C {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { [weak self] in
                        self?.x = 1
                        self?.g()
                        guard let self = self ?? C() else { return }
                        self?.x = 1
                    }
                    C().f { self.x = 1 }
                    f { [weak self] in if let self { x = 1 } }
                }
            }
            """),
        Example("""
            struct S {
                var x = 0, error = 0, exception = 0
                var y: Int?, z: Int?, u: Int, v: Int?, w: Int?
                func f(_ work: @escaping (Int) -> Void) { work() }
                func g(x: Int) {
                    f { u in
                        self.x = x
                        let x = 1
                        self.x = 2
                        if let y, let v {
                            self.y = 3
                            self.v = 1
                        }
                        guard let z else {
                            let v = 4
                            self.x = 5
                            self.v = 6
                            return
                        }
                        self.z = 7
                        while let v { self.v = 8 }
                        for w in [Int]() { self.w = 9 }
                        self.u = u
                        do {} catch { self.error = 10 }
                        do {} catch let exception { self.exception = 11 }
                    }
                }
            }
            """),
        Example("""
            enum E {
                case a(Int)
                case b(Int, Int)
            }
            struct S {
                var x: E = .a(3), y: Int, z: Int
                func f(_ work: @escaping () -> Void) { work() }
                func g(x: Int) {
                    f {
                        switch x {
                        case let .a(y):
                            self.y = 1
                        case .b(let y, var z):
                            self.y = 2
                            self.z = 3
                        }
                    }
                }
            }
            """),
        Example("""
            class C {
                var a = 0
                init(_ a: Int) {
                    self.a = a
                    f { [weak self] in
                        guard let self else { return }
                        self.a = 1
                    }
                }
                func f(_: () -> Void) {}
            }
            """, excludeFromDocumentation: true),
    ]

    static let triggeringExamples = [
        Example("""
            struct S {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f {
                        ↓self.x = 1
                        if ↓self.x == 1 { ↓self.g() }
                    }
                }
            }
            """),
        Example("""
            class C {
                var x = 0
                func g() {
                    {
                        ↓self.x = 1
                        ↓self.g()
                    }()
                }
            }
            """),
        Example("""
            class C {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { [self] in
                        ↓self.x = 1
                        ↓self.g()
                        f { self.x = 1 }
                    }
                }
            }
            """),
        Example("""
            class C {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { [unowned self] in ↓self.x = 1 }
                    f { [self = self] in ↓self.x = 1 }
                    f { [s = self] in s.x = 1 }
                }
            }
            """),
        Example("""
            struct S {
                var x = 0
                var y: Int?, z: Int?, v: Int?, w: Int?
                func f(_ work: @escaping () -> Void) { work() }
                func g(w: Int, _ v: Int) {
                    f {
                        self.w = 1
                        ↓self.x = 2
                        if let y { ↓self.x = 3 }
                        else { ↓self.y = 3 }
                        guard let z else {
                            ↓self.z = 4
                            ↓self.x = 5
                            return
                        }
                        ↓self.y = 6
                        while let y { ↓self.x = 7 }
                        for y in [Int]() { ↓self.x = 8 }
                        self.v = 9
                        do {
                            let x = 10
                            self.x = 11
                        }
                        ↓self.x = 12
                    }
                }
            }
            """),
        Example("""
            struct S {
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { let g = ↓self.g() }
                }
            }
            """, excludeFromDocumentation: true),
        Example("""
            extension E {
                static func f(_ work: @escaping () -> Void) { work() }
                func g() { Self.f { self.g() } }
                struct S {
                    func g() { E.f { ↓self.g() } }
                }
            }
            """, excludeFromDocumentation: true),
        Example("""
            class C {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { [weak self] in
                        self?.x = 1
                        guard let self else { return }
                        ↓self.x = 1
                    }
                    f { [weak self] in
                        self?.x = 1
                        if let self = self else { ↓self.x = 1 }
                        self?.x = 1
                    }
                    f { [weak self] in
                        self?.x = 1
                        while let self else { ↓self.x = 1 }
                        self?.x = 1
                    }
                }
            }
            """),
    ]

    static let corrections = [
        Example("""
            struct S {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f {
                        ↓self.x = 1
                        if ↓self.x == 1 { ↓self.g() }
                    }
                }
            }
            """): Example("""
                struct S {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f {
                            x = 1
                            if x == 1 { g() }
                        }
                    }
                }
                """),
    ]
}

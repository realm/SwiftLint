private struct StaticStringImitator {
    let string: String

    func withStaticString(_ closure: (StaticString) -> Void) {
        let isASCII = string.utf8.allSatisfy { $0 < 0x7f }
        string.utf8CString.dropLast().withUnsafeBytes {
            let imitator = Imitator(
                startPtr: $0.baseAddress!, utf8CodeUnitCount: $0.count, isASCII: isASCII)
            closure(imitator.staticString)
        }
    }

    struct Imitator {
        let startPtr: UnsafeRawPointer
        let utf8CodeUnitCount: Int
        let flags: Int8

        init(startPtr: UnsafeRawPointer, utf8CodeUnitCount: Int, isASCII: Bool) {
            self.startPtr = startPtr
            self.utf8CodeUnitCount = utf8CodeUnitCount
            flags = isASCII ? 0x2 : 0x0
        }

        var staticString: StaticString {
            unsafeBitCast(self, to: StaticString.self)
        }
    }
}

public extension String {
    func withStaticString(_ closure: (StaticString) -> Void) {
        StaticStringImitator(string: self).withStaticString(closure)
    }
}

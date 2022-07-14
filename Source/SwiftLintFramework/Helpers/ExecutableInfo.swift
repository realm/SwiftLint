#if os(macOS)
import Foundation
import MachO

enum ExecutableInfo {
    static let buildID: String? = {
        // It should be possible to read the UUID directly from the `_mh_execute_header` but that fails with
        // Fatal error: load from misaligned raw pointer
        //
        //   var header = _mh_execute_header
        //   let uuidString = withUnsafePointer(to: &header) { header in
        //       return getUUID(pointer: header)?.uuidString
        //   }

        // This works in pure Swift but requires reading the entire executable from disk, so it's 100x slower than
        // the Objective-C version
        let execData = try? Data(contentsOf: URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0]))
        return execData?.withUnsafeBytes { pointer -> String? in
            return getUUID(pointer: pointer.baseAddress!)?.uuidString
        }
    }()

    private static func getUUID(pointer: UnsafeRawPointer) -> UUID? {
        var offset: UInt64 = 0
        let header = pointer.bindMemory(to: mach_header_64.self, capacity: 1)
        offset += UInt64(MemoryLayout<mach_header_64>.size)
        for _ in 0..<header.pointee.ncmds {
            let loadCommand = pointer.load(fromByteOffset: Int(offset), as: load_command.self)
            if loadCommand.cmd == LC_UUID {
                let uuidCommand = pointer.load(fromByteOffset: Int(offset), as: uuid_command.self)
                return UUID(uuid: uuidCommand.uuid)
            }
            offset += UInt64(loadCommand.cmdsize)
        }
        return nil
    }
}

#else
enum ExecutableInfo {
    static let buildID: String? = nil
}
#endif

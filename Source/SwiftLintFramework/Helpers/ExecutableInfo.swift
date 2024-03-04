#if os(macOS)
import Foundation
import MachO
#endif

/// Information about this executable.
public enum ExecutableInfo {
    /// A stable identifier for this executable. Uses the Mach-O header UUID on macOS. Nil on Linux.
    public static let buildID: String? = {
#if os(macOS)
        func getUUID(pointer: UnsafeRawPointer) -> UUID? {
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

        if let handle = dlopen(nil, RTLD_LAZY) {
            defer { dlclose(handle) }

            if let ptr = dlsym(handle, MH_EXECUTE_SYM) {
                return getUUID(pointer: ptr)?.uuidString
            }
        }
#endif
        return nil
    }()
}

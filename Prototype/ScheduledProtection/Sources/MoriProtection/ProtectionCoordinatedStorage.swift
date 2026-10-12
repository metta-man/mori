import Foundation

public struct ProtectionCoordinatedStorage: ProtectionStorage {
    private let underlying: any ProtectionStorage
    private let coordinationURL: URL
    public init(_ underlying: any ProtectionStorage, coordinationURL: URL) {
        self.underlying = underlying; self.coordinationURL = coordinationURL
    }
    public func exclusive<T>(_ body: (ProtectionStorageAccess) throws -> T) throws -> T {
        try ProtectionWriterCoordination.exclusive(url: coordinationURL) { try underlying.exclusive(body) }
    }
    public func load() throws -> ProtectionState { try exclusive { try $0.load() } }
    public func transaction<T>(_ body: (inout ProtectionState) throws -> T) throws -> T {
        try exclusive { access in
            var state = try access.load(); let result = try body(&state); try access.save(state); return result
        }
    }
}

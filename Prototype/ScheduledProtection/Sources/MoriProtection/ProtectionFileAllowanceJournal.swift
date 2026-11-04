import Foundation

public struct ProtectionAllowanceRecord: Codable {
    public let baseline: ProtectionGrantBaseline
    public let eventID: UUID
    public let historyGeneration: String
    public let expectedEnd: Date
    public let beforeFeedReceiptExisted: Bool
    public var acknowledged: Bool
}

/// Shared by the native wrapper and pure fault/relaunch tests. A retained file,
/// regardless of its acknowledgement marker, is an unfinished transaction.
public final class ProtectionFileAllowanceJournal: ProtectionAllowanceJournal {
    private let url: URL
    private let eventID: UUID
    private let generation: String
    private let end: Date
    private let receiptExisted: () throws -> Bool
    private let io: ProtectionFileIO
    public init(url: URL, eventID: UUID, generation: String, end: Date, io: ProtectionFileIO = .system, receiptExisted: @escaping () throws -> Bool) {
        self.url = url; self.eventID = eventID; self.generation = generation; self.end = end; self.receiptExisted = receiptExisted; self.io = io
    }
    private func save(_ record: ProtectionAllowanceRecord) throws {
        try io.write(JSONEncoder().encode(record), url)
    }
    public func prepare(_ baseline: ProtectionGrantBaseline) throws {
        guard try io.optionalData(at: url) == nil else { throw ProtectionWriterError.busy }
        try save(.init(baseline: baseline, eventID: eventID, historyGeneration: generation,
            expectedEnd: end, beforeFeedReceiptExisted: try receiptExisted(), acknowledged: false))
    }
    public func record() throws -> ProtectionAllowanceRecord { try Self.read(url, io: io) }
    public func acknowledge() throws {
        var record = try Self.read(url, io: io); record.acknowledged = true; try save(record)
    }
    public func finishCompensation() throws {
        try io.removeIfPresent(at: url)
    }
    public static func read(_ url: URL, io: ProtectionFileIO = .system) throws -> ProtectionAllowanceRecord {
        try JSONDecoder().decode(ProtectionAllowanceRecord.self, from: io.read(url))
    }
    public static func recover(at url: URL, io: ProtectionFileIO = .system, compensate: (ProtectionAllowanceRecord) throws -> Void) throws {
        guard let data = try io.optionalData(at: url) else { return }
        let record = try JSONDecoder().decode(ProtectionAllowanceRecord.self, from: data)
        try compensate(record)
        // Never delete before participant removal, repair and scheduled rollback acknowledge.
        try io.removeIfPresent(at: url)
    }
}

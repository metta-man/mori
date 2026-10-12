import Foundation
import XCTest
@testable import Mori

final class MoriBuild7StorageCompatibilityTests: XCTestCase {
    private let referenceDay = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 2_000_000_000))

    func testBuild7CollectionRoundTripAndUnrelatedSaveKeepUntouchedMetadata() throws {
        try withStore { defaults, store in
            let original = record(on: referenceDay, emotion: "happy", tone: "positive")
            let skippedDay = referenceDay.addingTimeInterval(-86_400)
            let skipped = record(on: skippedDay, emotion: nil, tone: "neutral", skipped: true)
            defaults.set(try JSONSerialization.data(withJSONObject: [original, skipped]), forKey: "habit_entries")

            let loaded = store.loadEntries()
            XCTAssertEqual(loaded.count, 2)
            store.saveEntries(loaded)
            try assertMetadata(original, in: defaults, on: referenceDay)
            try assertMetadata(skipped, in: defaults, on: skippedDay)

            let manager = HabitDataManager(store: store)
            _ = manager.saveEntry(on: referenceDay.addingTimeInterval(86_400), tone: .neutral, note: "Synthetic new day")
            try assertMetadata(original, in: defaults, on: referenceDay)
            try assertMetadata(skipped, in: defaults, on: skippedDay)
        }
    }

    func testBackdatedOrdinaryEditsKeepEveryInstalledEmotionAndObservation() throws {
        let cases: [(String, HabitDayTone)] = [
            ("happy", .positive), ("okay", .neutral), ("sad", .negative),
            ("content", .positive), ("grateful", .positive), ("relieved", .positive)
        ]
        for (emotion, tone) in cases {
            try withStore { defaults, store in
                let original = record(on: referenceDay, emotion: emotion, tone: tone.rawValue)
                defaults.set(try JSONSerialization.data(withJSONObject: [original]), forKey: "habit_entries")
                let manager = HabitDataManager(store: store)
                _ = manager.saveEntry(on: referenceDay, tone: tone, note: "Synthetic note edit")
                try assertMetadata(original, in: defaults, on: referenceDay)
            }
        }
        try withStore { defaults, store in
            let original = record(on: referenceDay, emotion: nil, tone: "neutral", skipped: true)
            defaults.set(try JSONSerialization.data(withJSONObject: [original]), forKey: "habit_entries")
            _ = HabitDataManager(store: store).saveEntry(on: referenceDay, tone: .neutral, note: "Synthetic skipped edit")
            try assertMetadata(original, in: defaults, on: referenceDay)
        }
    }

    func testLegacyRecordWithoutNewKeysStillDecodesAndSaves() throws {
        try withStore { defaults, store in
            var legacy = record(on: referenceDay, emotion: "calm", tone: "positive")
            legacy.removeValue(forKey: "journalMood")
            legacy.removeValue(forKey: "journalEmotionWasSkipped")
            defaults.set(try JSONSerialization.data(withJSONObject: [legacy]), forKey: "habit_entries")
            let entry = try XCTUnwrap(store.loadEntries().first)
            XCTAssertNil(entry.journalMood)
            XCTAssertFalse(entry.journalEmotionWasSkipped)
            store.saveEntries([entry])
            let saved = try XCTUnwrap(savedRecords(defaults).first)
            XCTAssertNil(saved["journalMood"])
            XCTAssertNil(saved["journalEmotionWasSkipped"])
            XCTAssertEqual(saved["journalEmotionID"] as? String, "calm")
        }
    }

    private func record(on day: Date, emotion: String?, tone: String, skipped: Bool = false) -> [String: Any] {
        var mood: [String: Any] = [
            "id": "12345678-1234-1234-1234-123456789ABC",
            "recordedAt": day.timeIntervalSinceReferenceDate + 42,
            "valence": "pleasant", "contextID": "money", "version": 3, "sharedVersion": 2
        ]
        if let emotion { mood["emotionID"] = emotion }
        var value: [String: Any] = [
            "id": UUID().uuidString, "date": day.timeIntervalSinceReferenceDate,
            "createdAt": day.timeIntervalSinceReferenceDate + 60,
            "tone": tone, "isPositive": tone == "positive", "note": "Synthetic installed record",
            "journalContextID": "work-or-study", "journalResponseID": "just-record-it", "journalMood": mood
        ]
        if let emotion { value["journalEmotionID"] = emotion }
        if skipped { value["journalEmotionWasSkipped"] = true }
        return value
    }

    private func savedRecords(_ defaults: UserDefaults) throws -> [[String: Any]] {
        let data = try XCTUnwrap(defaults.data(forKey: "habit_entries"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }

    private func assertMetadata(_ expected: [String: Any], in defaults: UserDefaults, on day: Date) throws {
        let saved = try XCTUnwrap(savedRecords(defaults).first {
            ($0["date"] as? Double) == day.timeIntervalSinceReferenceDate
        })
        XCTAssertEqual(saved["journalEmotionID"] as? String, expected["journalEmotionID"] as? String)
        XCTAssertEqual(saved["journalContextID"] as? String, expected["journalContextID"] as? String)
        XCTAssertEqual(saved["journalResponseID"] as? String, expected["journalResponseID"] as? String)
        XCTAssertEqual(saved["journalEmotionWasSkipped"] as? Bool ?? false,
                       expected["journalEmotionWasSkipped"] as? Bool ?? false)
        let actualMood = try XCTUnwrap(saved["journalMood"] as? [String: Any])
        let oldMood = try XCTUnwrap(expected["journalMood"] as? [String: Any])
        XCTAssertEqual(NSDictionary(dictionary: actualMood), NSDictionary(dictionary: oldMood))
    }

    private func withStore(_ body: (UserDefaults, HabitEntryStore) throws -> Void) rethrows {
        let suite = "Mori.Build7.Compatibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HabitEntryStore(defaults: defaults, notificationCenter: NotificationCenter())
        try body(defaults, store)
    }
}

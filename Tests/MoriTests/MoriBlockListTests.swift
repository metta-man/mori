import XCTest
import FamilyControls
@testable import Mori

final class MoriBlockListTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    override func setUp() {
        suite = "MoriBlockListTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() { defaults.removePersistentDomain(forName: suite) }

    func testCreateRenameDeleteAndReloadKeepOtherListsAndAppliedSelection() throws {
        let store = MoriBlockListStore(defaults: defaults)
        let originalData = Data("existing-applied-selection".utf8)
        defaults.set(originalData, forKey: MoriScreenTimeShared.defaultSelectionKey)
        var work = MoriBlockList(name: " Work ")
        let study = MoriBlockList(name: "Study")
        try store.save(work)
        try store.save(study)
        XCTAssertEqual(try store.load().map(\.name), ["Work", "Study"])
        work.name = "Office"
        try store.save(work)
        XCTAssertEqual(try store.load().map(\.id), [work.id, study.id])
        try store.delete(id: work.id)
        XCTAssertEqual(try MoriBlockListStore(defaults: defaults).load().map(\.name), ["Study"])
        XCTAssertEqual(defaults.data(forKey: MoriScreenTimeShared.defaultSelectionKey), originalData)
    }

    func testEmptyAndDuplicateNamesCannotOverwriteExistingList() throws {
        let store = MoriBlockListStore(defaults: defaults)
        try store.save(MoriBlockList(name: "Work"))
        XCTAssertThrowsError(try store.save(MoriBlockList(name: " \n ")))
        XCTAssertThrowsError(try store.save(MoriBlockList(name: " work ")))
        XCTAssertEqual(try store.load().map(\.name), ["Work"])
    }

    func testCorruptDataIsPreservedInsteadOfOverwritten() {
        let corrupt = Data("not-json".utf8)
        defaults.set(corrupt, forKey: MoriBlockListStore.storageKey)
        let store = MoriBlockListStore(defaults: defaults)
        XCTAssertThrowsError(try store.load())
        XCTAssertThrowsError(try store.save(MoriBlockList(name: "Study")))
        XCTAssertThrowsError(try store.delete(id: UUID()))
        XCTAssertEqual(defaults.data(forKey: MoriBlockListStore.storageKey), corrupt)
    }

    func testDraftChangesDoNotMutateSavedListAndDataResetClearsLibrary() throws {
        let store = MoriBlockListStore(defaults: defaults)
        try store.save(MoriBlockList(name: "Work"))
        var draft = try XCTUnwrap(store.load().first)
        draft.name = "Unsaved"
        XCTAssertEqual(try store.load().first?.name, "Work")
        ScreenTimeSelectionPersistence(defaults: defaults).clearAll()
        XCTAssertTrue(try store.load().isEmpty)
    }
}

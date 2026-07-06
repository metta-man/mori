import Combine
import CryptoKit
import Foundation
import Security

enum ScreenTimeSettingsLockMode: String, Codable, CaseIterable, Identifiable {
    case selfPIN
    case accountabilityPIN

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selfPIN: return MoriL10n.display("Self PIN")
        case .accountabilityPIN: return MoriL10n.display("Accountability PIN")
        }
    }

    var setupTitle: String {
        switch self {
        case .selfPIN: return MoriL10n.display("Create my PIN")
        case .accountabilityPIN: return MoriL10n.display("Send PIN to friends")
        }
    }

    var detail: String {
        switch self {
        case .selfPIN:
            return MoriL10n.display("You keep the PIN and use it whenever App Limits need editing.")
        case .accountabilityPIN:
            return MoriL10n.display("Mori generates a PIN for 1-3 trusted friends to hold for you.")
        }
    }
}

enum ScreenTimeSettingsLockError: LocalizedError {
    case invalidPIN
    case confirmationMismatch
    case incorrectPIN
    case cooldownActive(Int)
    case keychainFailure

    var errorDescription: String? {
        switch self {
        case .invalidPIN:
            return MoriL10n.display("Enter a 6-digit PIN.")
        case .confirmationMismatch:
            return MoriL10n.display("PINs do not match.")
        case .incorrectPIN:
            return MoriL10n.display("Incorrect PIN.")
        case .cooldownActive(let seconds):
            return MoriL10n.string("screen_time.lock.too_many_attempts", defaultValue: "Too many incorrect attempts. Try again in %ds.", arguments: [seconds])
        case .keychainFailure:
            return MoriL10n.display("Could not save the PIN securely.")
        }
    }
}

@MainActor
final class ScreenTimeSettingsLockStore: ObservableObject {
    static let shared = ScreenTimeSettingsLockStore()

    nonisolated static let pinLength = 6

    @Published private(set) var isConfigured = false
    @Published private(set) var mode: ScreenTimeSettingsLockMode?
    @Published private(set) var cooldownUntil: Date?

    private let defaults = MoriAppGroup.defaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private static let keychainService = "com.mettalabs.mori.screen-time-settings-lock"
    private static let keychainAccount = "screen-time-settings-pin"
    private static let failedAttemptsKey = "mori_screen_time_settings_lock_failed_attempts"
    private static let cooldownUntilKey = "mori_screen_time_settings_lock_cooldown_until"
    private static let maximumFailedAttempts = 5
    private static let cooldownSeconds: TimeInterval = 60

    private init() {
        refresh()
    }

    func refresh() {
        let metadata = loadMetadata()
        isConfigured = metadata != nil
        mode = metadata?.mode
        cooldownUntil = loadCooldownUntil()
    }

    func createSelfPIN(_ pin: String, confirmation: String) throws {
        try validate(pin: pin, confirmation: confirmation)
        try save(pin: pin, mode: .selfPIN)
        resetFailedAttempts()
        refresh()
    }

    func createAccountabilityPIN() throws -> String {
        let pin = Self.generatedPIN()
        try save(pin: pin, mode: .accountabilityPIN)
        resetFailedAttempts()
        refresh()
        return pin
    }

    func verify(_ pin: String) throws -> Bool {
        guard cooldownRemainingSeconds() == 0 else {
            throw ScreenTimeSettingsLockError.cooldownActive(cooldownRemainingSeconds())
        }
        guard Self.isValidPIN(pin) else {
            throw ScreenTimeSettingsLockError.invalidPIN
        }
        guard let metadata = loadMetadata() else {
            refresh()
            return true
        }

        let digest = Self.hash(pin: pin, salt: metadata.salt)
        guard Self.constantTimeEquals(digest, metadata.hash) else {
            recordFailedAttempt()
            throw ScreenTimeSettingsLockError.incorrectPIN
        }

        resetFailedAttempts()
        refresh()
        return true
    }

    func changeSelfPIN(currentPIN: String, newPIN: String, confirmation: String) throws {
        _ = try verify(currentPIN)
        try validate(pin: newPIN, confirmation: confirmation)
        try save(pin: newPIN, mode: .selfPIN)
        resetFailedAttempts()
        refresh()
    }

    func changeToAccountabilityPIN(currentPIN: String) throws -> String {
        _ = try verify(currentPIN)
        let pin = try createAccountabilityPIN()
        refresh()
        return pin
    }

    func clearAfterVerification(currentPIN: String) throws {
        _ = try verify(currentPIN)
        try deleteMetadata()
        resetFailedAttempts()
        refresh()
    }

    func cooldownRemainingSeconds(now: Date = Date()) -> Int {
        guard let cooldownUntil = loadCooldownUntil(),
              cooldownUntil > now
        else {
            return 0
        }
        return max(0, Int(ceil(cooldownUntil.timeIntervalSince(now))))
    }

    private func validate(pin: String, confirmation: String) throws {
        guard Self.isValidPIN(pin) else {
            throw ScreenTimeSettingsLockError.invalidPIN
        }
        guard pin == confirmation else {
            throw ScreenTimeSettingsLockError.confirmationMismatch
        }
    }

    private func save(pin: String, mode: ScreenTimeSettingsLockMode) throws {
        var salt = Data(count: 16)
        let status = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw ScreenTimeSettingsLockError.keychainFailure
        }

        let now = Date()
        let existingCreatedAt = loadMetadata()?.createdAt
        let metadata = LockMetadata(
            mode: mode,
            salt: salt,
            hash: Self.hash(pin: pin, salt: salt),
            createdAt: existingCreatedAt ?? now,
            updatedAt: now
        )

        guard let data = try? encoder.encode(metadata) else {
            throw ScreenTimeSettingsLockError.keychainFailure
        }

        try saveMetadataData(data)
    }

    private func loadMetadata() -> LockMetadata? {
        guard let data = Self.keychainData() else { return nil }
        return try? decoder.decode(LockMetadata.self, from: data)
    }

    private func saveMetadataData(_ data: Data) throws {
        let query = Self.baseKeychainQuery()
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw ScreenTimeSettingsLockError.keychainFailure
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw ScreenTimeSettingsLockError.keychainFailure
        }
    }

    private func deleteMetadata() throws {
        let status = SecItemDelete(Self.baseKeychainQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ScreenTimeSettingsLockError.keychainFailure
        }
    }

    private func recordFailedAttempt() {
        let attempts = defaults.integer(forKey: Self.failedAttemptsKey) + 1
        defaults.set(attempts, forKey: Self.failedAttemptsKey)
        if attempts >= Self.maximumFailedAttempts {
            defaults.set(Date().addingTimeInterval(Self.cooldownSeconds).timeIntervalSince1970, forKey: Self.cooldownUntilKey)
            defaults.set(0, forKey: Self.failedAttemptsKey)
        }
        refresh()
    }

    private func resetFailedAttempts() {
        defaults.set(0, forKey: Self.failedAttemptsKey)
        defaults.removeObject(forKey: Self.cooldownUntilKey)
    }

    private func loadCooldownUntil() -> Date? {
        let timestamp = defaults.double(forKey: Self.cooldownUntilKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private static func isValidPIN(_ pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy(\.isNumber)
    }

    private static func generatedPIN() -> String {
        var bytes = [UInt8](repeating: 0, count: 4)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let value: UInt32
        if status == errSecSuccess {
            value = bytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) } % 1_000_000
        } else {
            value = UInt32.random(in: 0...999_999)
        }
        return String(format: "%06d", value)
    }

    private static func hash(pin: String, salt: Data) -> Data {
        var data = Data()
        data.append(salt)
        data.append(Data(pin.utf8))
        return Data(SHA256.hash(data: data))
    }

    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for index in lhs.indices {
            difference |= lhs[index] ^ rhs[index]
        }
        return difference == 0
    }

    private static func keychainData() -> Data? {
        var query = baseKeychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func baseKeychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
    }

    private struct LockMetadata: Codable {
        let mode: ScreenTimeSettingsLockMode
        let salt: Data
        let hash: Data
        let createdAt: Date
        let updatedAt: Date
    }
}

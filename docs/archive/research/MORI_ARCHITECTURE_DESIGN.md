# Mori 架构设计文档

**Author:** Blaze 🌟  
**Date:** 2026-02-23  
**Status:** Draft v1

---

## 📐 技术选型结论

| 层级 | 技术 | 理由 |
|------|------|------|
| **UI Framework** | SwiftUI | 原生体验、团队经验(MiniHabitIsland)、iOS优先策略 |
| **本地存储** | CoreData + CloudKit | 原生集成、自动iCloud同步、无需后端 |
| **云同步** | iCloud (CloudKit) | 零成本、Apple生态原生支持、隐私优先 |
| **架构模式** | MVVM + Repository | 可测试性、清晰职责分离 |

---

## 🏗️ 架构分层

```
┌─────────────────────────────────────────────────────┐
│                    Views (SwiftUI)                  │
│  LifeGridView │ TheClockView │ HabitView │ GratitudeView
├─────────────────────────────────────────────────────┤
│                   ViewModels                        │
│  LifeGridVM │ ClockVM │ HabitVM │ GratitudeVM       │
├─────────────────────────────────────────────────────┤
│                 Repositories                        │
│  LifeRepository │ HabitRepository │ GratitudeRepo   │
├─────────────────────────────────────────────────────┤
│                  CoreData Stack                     │
│  NSPersistentContainer + CloudKit integration       │
└─────────────────────────────────────────────────────┘
```

---

## 📦 数据模型设计

### 1. LifeGrid 核心模型

```swift
// MARK: - LifeGrid Constants
enum LifeGridConfig {
    /// 人的一生约80年 = 4160周
    static let totalYears: Int = 80
    static let weeksPerYear: Int = 52
    static let totalWeeks: Int = totalYears * weeksPerYear // 4160
    
    /// Grid显示配置
    static let gridColumns: Int = 52  // 每行52周 = 1年
    static let gridRows: Int = 80     // 80行 = 80年
}

// MARK: - User Life Data (CoreData Entity)
@Entity
class UserProfile: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var birthDate: Date
    @NSManaged var lifeExpectancyYears: Int  // 默认80，可自定义
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}

// MARK: - Life Week (CoreData Entity)
@Entity
class LifeWeek: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var weekIndex: Int           // 0-4159
    @NSManaged var yearIndex: Int           // 0-79
    @NSManaged var weekOfYear: Int          // 1-52
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var isLived: Bool            // 已过去的周
    @NSManaged var mood: String?            // 可选: "good" | "bad" | "neutral"
    @NSManaged var note: String?            // 可选备注
}
```

### 2. Habit 系统模型

```swift
// MARK: - Habit Entry (CoreData Entity)
@Entity
class HabitEntry: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var isPositive: Bool         // true = + / false = -
    @NSManaged var createdAt: Date
    @NSManaged var note: String?
}

// MARK: - Habit Streak (Computed)
struct HabitStreak {
    let currentStreak: Int
    let longestStreak: Int
    let totalPositiveDays: Int
    let totalNegativeDays: Int
    let lastWeekTrend: TrendDirection
    
    enum TrendDirection {
        case improving, declining, stable
    }
}
```

### 3. Gratitude 感恩日记模型

```swift
// MARK: - Gratitude Entry (CoreData Entity)
@Entity
class GratitudeEntry: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var content: String
    @NSManaged var promptType: String?      // 可选提示类型
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}

// MARK: - Prompt Types
enum GratitudePrompt: String, CaseIterable {
    case today = "今天最感謝的是…"
    case smallJoy = "一個小確幸…"
    case moment = "我想記住這一刻…"
    case person = "今天想感謝的人…"
    case growth = "今天學到的事…"
}
```

---

## ⏱️ 倒计时算法

### 核心算法

```swift
// MARK: - Life Countdown Calculator
struct LifeCalculator {
    
    /// 计算已度过的周数
    static func weeksLived(from birthDate: Date, to currentDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: birthDate, to: currentDate)
        return max(0, components.weekOfYear ?? 0)
    }
    
    /// 计算剩余周数
    static func weeksRemaining(
        from birthDate: Date,
        lifeExpectancy: Int = 80,
        currentDate: Date = Date()
    ) -> Int {
        let totalWeeks = lifeExpectancy * 52
        let lived = weeksLived(from: birthDate, to: currentDate)
        return max(0, totalWeeks - lived)
    }
    
    /// 精确倒计时 (天/时/分/秒)
    static func preciseCountdown(
        from birthDate: Date,
        lifeExpectancy: Int = 80,
        currentDate: Date = Date()
    ) -> CountdownResult {
        let calendar = Calendar.current
        
        // 计算生命终点日期 (80岁生日那天)
        let endOfLife = calendar.date(
            byAdding: .year,
            value: lifeExpectancy,
            to: birthDate
        ) ?? birthDate
        
        let components = calendar.dateComponents(
            [.day, .hour, .minute, .second],
            from: currentDate,
            to: endOfLife
        )
        
        return CountdownResult(
            days: max(0, components.day ?? 0),
            hours: max(0, components.hour ?? 0),
            minutes: max(0, components.minute ?? 0),
            seconds: max(0, components.second ?? 0)
        )
    }
    
    /// 计算当前周进度 (0.0 - 1.0)
    static func currentWeekProgress(currentDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        // 周日=1, 周一=2...周六=7
        // 转换为周一=0...周日=6
        let adjustedWeekday = (weekday + 5) % 7
        return Double(adjustedWeekday) / 7.0
    }
}

struct CountdownResult {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    
    var formatted: String {
        return "\(days)天 \(hours)時 \(minutes)分"
    }
}
```

### Life Grid 填充算法

```swift
// MARK: - Life Grid Population
extension LifeCalculator {
    
    /// 批量创建或更新LifeWeek实体
    static func populateLifeWeeks(
        for profile: UserProfile,
        in context: NSManagedObjectContext
    ) -> [LifeWeek] {
        let calendar = Calendar.current
        var weeks: [LifeWeek] = []
        
        for yearIndex in 0..<profile.lifeExpectancyYears {
            for weekOfYear in 1...52 {
                let weekIndex = yearIndex * 52 + (weekOfYear - 1)
                
                // 计算这周的起止日期
                let startOfYear = calendar.date(
                    from: DateComponents(
                        year: calendar.component(.year, from: profile.birthDate) + yearIndex,
                        month: 1,
                        day: 1
                    )
                )!
                
                let weekStart = calendar.date(
                    byAdding: .weekOfYear,
                    value: weekOfYear - 1,
                    to: startOfYear
                )!
                
                let weekEnd = calendar.date(
                    byAdding: .day,
                    value: 6,
                    to: weekStart
                )!
                
                // 判断是否已过去
                let isLived = weekEnd < Date()
                
                let week = LifeWeek(context: context)
                week.id = UUID()
                week.weekIndex = weekIndex
                week.yearIndex = yearIndex
                week.weekOfYear = weekOfYear
                week.startDate = weekStart
                week.endDate = weekEnd
                week.isLived = isLived
                
                weeks.append(week)
            }
        }
        
        return weeks
    }
}
```

---

## ☁️ 云同步策略

### CoreData + CloudKit 配置

```swift
// MARK: - Persistence Controller
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Mori")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // CloudKit 配置
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to load persistent store description")
        }
        
        // 启用自动云同步
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourcompany.mori"
        )
        
        // 优化选项
        description.setOption(true as NSNumber, 
            forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData store failed: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
```

### 同步策略说明

| 特性 | 实现方式 |
|------|----------|
| **自动同步** | NSPersistentCloudKitContainer 自动处理 |
| **离线支持** | CoreData 本地存储优先，网络恢复后自动同步 |
| **冲突解决** | NSMergeByPropertyObjectTrumpMergePolicy (本地优先) |
| **隐私** | CloudKit 私有数据库，端到端加密 |

---

## 📂 文件结构

```
Mori/
├── MoriApp.swift
├── Models/
│   ├── UserProfile.swift
│   ├── LifeWeek.swift
│   ├── HabitEntry.swift
│   ├── GratitudeEntry.swift
│   └── Calculators/
│       └── LifeCalculator.swift
├── ViewModels/
│   ├── LifeGridViewModel.swift
│   ├── ClockViewModel.swift
│   ├── HabitViewModel.swift
│   └── GratitudeViewModel.swift
├── Repositories/
│   ├── LifeRepository.swift
│   ├── HabitRepository.swift
│   └── GratitudeRepository.swift
├── Views/
│   ├── LifeGrid/
│   │   ├── LifeGridView.swift
│   │   ├── LifeGridCell.swift
│   │   └── LifeGridStyle.swift
│   ├── Clock/
│   │   ├── TheClockView.swift
│   │   └── CountdownNumberView.swift
│   ├── Habit/
│   │   ├── HabitButtonView.swift
│   │   └── HabitStreakView.swift
│   ├── Gratitude/
│   │   ├── GratitudeListView.swift
│   │   ├── GratitudeEditorView.swift
│   │   └── PromptChipView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   └── PersistenceController.swift
├── Design/
│   ├── DesignTokens.swift
│   └── Color+Mori.swift
└── Resources/
    └── Mori.xcdatamodeld
```

---

## 🎨 Design Tokens Implementation

```swift
// MARK: - Mori Design Tokens
enum MoriTokens {
    
    // MARK: Colors
    enum Colors {
        static let bgBase = Color(hex: "FDF5E6")
        static let bgSurface = Color(hex: "FFF8E7")
        static let borderSoft = Color(hex: "E8E8E8")
        static let textPrimary = Color(hex: "333333")
        static let textSecondary = Color(hex: "7A7A7A")
        static let accentDeep = Color(hex: "4A4A4A")
        static let stateSuccess = Color(hex: "6E9B72")
        static let stateCaution = Color(hex: "B07A62")
    }
    
    // MARK: Typography
    enum Typography {
        static let hero = Font.system(size: 40, weight: .semibold, design: .default)
        static let sectionTitle = Font.system(size: 20, weight: .semibold)
        static let bodyPrimary = Font.system(size: 16, weight: .regular)
        static let bodySecondary = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
    }
    
    // MARK: Spacing
    enum Spacing {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 24
        static let s6: CGFloat = 32
    }
    
    // MARK: Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }
}
```

---

## 🔄 Repository Pattern

```swift
// MARK: - Life Repository
protocol LifeRepository {
    func fetchUserProfile() async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    func fetchLifeWeeks() async throws -> [LifeWeek]
    func updateLifeWeek(_ week: LifeWeek) async throws
}

class CoreDataLifeRepository: LifeRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchUserProfile() async throws -> UserProfile {
        // Implementation
    }
    
    // ... other methods
}

// MARK: - Habit Repository
protocol HabitRepository {
    func fetchEntries(from: Date, to: Date) async throws -> [HabitEntry]
    func saveEntry(_ entry: HabitEntry) async throws
    func calculateStreak() async throws -> HabitStreak
}

// MARK: - Gratitude Repository
protocol GratitudeRepository {
    func fetchEntries(for date: Date) async throws -> [GratitudeEntry]
    func saveEntry(_ entry: GratitudeEntry) async throws
    func deleteEntry(_ entry: GratitudeEntry) async throws
}
```

---

## 📊 CoreData Model (.xcdatamodeld)

```
Entities:
├── UserProfile
│   ├── id: UUID (PK)
│   ├── birthDate: Date
│   ├── lifeExpectancyYears: Integer 16
│   ├── createdAt: Date
│   └── updatedAt: Date
│
├── LifeWeek
│   ├── id: UUID (PK)
│   ├── weekIndex: Integer 32
│   ├── yearIndex: Integer 16
│   ├── weekOfYear: Integer 16
│   ├── startDate: Date
│   ├── endDate: Date
│   ├── isLived: Boolean
│   ├── mood: String (optional)
│   └── note: String (optional)
│
├── HabitEntry
│   ├── id: UUID (PK)
│   ├── date: Date
│   ├── isPositive: Boolean
│   ├── createdAt: Date
│   └── note: String (optional)
│
└── GratitudeEntry
    ├── id: UUID (PK)
    ├── date: Date
    ├── content: String
    ├── promptType: String (optional)
    ├── createdAt: Date
    └── updatedAt: Date
```

---

## 🚀 实施路线

### Phase 1: Foundation (Week 1)
- [ ] Xcode项目搭建
- [ ] CoreData模型定义
- [ ] Design Tokens实现
- [ ] PersistenceController配置

### Phase 2: Core Features (Week 2)
- [ ] LifeCalculator算法实现
- [ ] LifeGridView + ViewModel
- [ ] TheClockView + 倒计时
- [ ] Habit +/- 系统

### Phase 3: Polish (Week 3)
- [ ] Gratitude日记系统
- [ ] iCloud同步测试
- [ ] UI打磨 + 动画
- [ ] 微文案集成

### Phase 4: Ship (Week 4)
- [ ] TestFlight测试
- [ ] Bug修复
- [ ] App Store提交

---

**文档完成** ✅  
**下一步:** 团队评审 → 开始Phase 1实施

---

## 🛡️ 错误处理策略

### Result-Based Error Handling

```swift
// MARK: - Mori Error Types
enum MoriError: LocalizedError {
    case invalidBirthDate
    case lifeExpectancyTooLow
    case coreDataSaveFailed(Error)
    case cloudKitSyncFailed(Error)
    case invalidWeekIndex(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidBirthDate:
            return "出生日期无效"
        case .lifeExpectancyTooLow:
            return "预期寿命必须大于0"
        case .coreDataSaveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        case .cloudKitSyncFailed(let error):
            return "同步失败: \(error.localizedDescription)"
        case .invalidWeekIndex(let index):
            return "无效的周索引: \(index)"
        }
    }
}

// MARK: - Repository with Result Types
protocol LifeRepository {
    func fetchUserProfile() async -> Result<UserProfile, MoriError>
    func updateUserProfile(_ profile: UserProfile) async -> Result<Void, MoriError>
    func fetchLifeWeeks() async -> Result<[LifeWeek], MoriError>
}
```

### SwiftUI Error Handling

```swift
// MARK: - Error State in Views
struct LifeGridView: View {
    @StateObject private var viewModel: LifeGridViewModel
    @State private var error: MoriError?
    @State private var showError = false
    
    var body: some View {
        // ...
        .alert("错误", isPresented: $showError) {
            Button("重试") { viewModel.retry() }
            Button("取消", role: .cancel) { }
        } message: {
            Text(error?.errorDescription ?? "未知错误")
        }
    }
}
```

---

## 🧪 测试策略

### Unit Tests

```swift
// MARK: - Life Calculator Tests
final class LifeCalculatorTests: XCTestCase {
    
    func testWeeksLived() {
        let birthDate = Date(timeIntervalSinceNow: -30 * 365.25 * 24 * 3600) // 30 years ago
        let weeks = LifeCalculator.weeksLived(from: birthDate)
        XCTAssertGreaterThanOrEqual(weeks, 1560) // ~30 * 52
        XCTAssertLessThanOrEqual(weeks, 1565)
    }
    
    func testWeeksRemaining() {
        let birthDate = Date(timeIntervalSinceNow: -40 * 365.25 * 24 * 3600)
        let remaining = LifeCalculator.weeksRemaining(from: birthDate, lifeExpectancy: 80)
        XCTAssertEqual(remaining, 40 * 52) // 2080 weeks
    }
    
    func testPreciseCountdown() {
        let birthDate = Calendar.current.date(
            from: DateComponents(year: 1990, month: 1, day: 1)
        )!
        let countdown = LifeCalculator.preciseCountdown(
            from: birthDate,
            lifeExpectancy: 80,
            currentDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        )
        XCTAssertEqual(countdown.days, 365 * 44 + 11) // Leap years accounted
    }
    
    func testCurrentWeekProgress() {
        // Monday should be ~0% progress
        // Sunday should be ~100% progress
    }
}

// MARK: - Repository Tests
final class CoreDataLifeRepositoryTests: XCTestCase {
    var sut: CoreDataLifeRepository!
    var mockContainer: NSPersistentContainer!
    
    override func setUp() {
        mockContainer = NSPersistentContainer(name: "Mori")
        mockContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        mockContainer.loadPersistentStores { _, _ in }
        sut = CoreDataLifeRepository(context: mockContainer.viewContext)
    }
    
    func testSaveAndFetchUserProfile() async {
        let profile = UserProfile(birthDate: Date(), lifeExpectancyYears: 80)
        await sut.saveUserProfile(profile)
        
        let fetched = await sut.fetchUserProfile()
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.lifeExpectancyYears, 80)
    }
}
```

### UI Tests

```swift
// MARK: - Life Grid UI Tests
final class LifeGridUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testLifeGridDisplays() {
        // Verify grid appears
        XCTAssertTrue(app.scrollViews["LifeGrid"].exists)
        
        // Verify 80 rows
        let rows = app.scrollViews["LifeGrid"].children(matching: .any)
        XCTAssertEqual(rows.count, 80)
    }
    
    func testOnboardingFlow() {
        // First launch should show birth date picker
        XCTAssertTrue(app.datePickers["BirthDatePicker"].exists)
        
        // Enter birth date
        app.datePickers["BirthDatePicker"].adjust(to: Date(timeIntervalSince1970: 0))
        
        // Tap continue
        app.buttons["Continue"].tap()
        
        // Should show Life Grid
        XCTAssertTrue(app.scrollViews["LifeGrid"].waitForExistence(timeout: 2))
    }
}
```

---

## ♿ 无障碍支持 (Accessibility)

### VoiceOver 配置

```swift
// MARK: - Accessible Life Grid
struct LifeGridCell: View {
    let week: LifeWeek
    let index: Int
    
    var body: some View {
        Circle()
            .fill(week.isLived ? Color.accentDeep : Color.borderSoft)
            .frame(width: 8, height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
    }
    
    private var accessibilityLabel: String {
        let year = index / 52 + 1
        let weekOfYear = index % 52 + 1
        return "第\(year)年，第\(weekOfYear)周"
    }
    
    private var accessibilityHint: String {
        week.isLived ? "已度过" : "未来"
    }
}

// MARK: - Accessible Countdown
struct CountdownView: View {
    let countdown: CountdownResult
    
    var body: some View {
        VStack {
            Text("\(countdown.days)")
                .accessibilityLabel("剩余\(countdown.days)天")
            Text("\(countdown.hours)时\(countdown.minutes)分")
                .accessibilityLabel("\(countdown.hours)小时\(countdown.minutes)分钟")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("你还有\(countdown.days)天\(countdown.hours)小时\(countdown.minutes)分钟")
    }
}
```

### Dynamic Type 支持

```swift
// MARK: - Scalable Typography
enum MoriTypography {
    static func hero(sizeCategory: ContentSizeCategory) -> Font {
        let baseSize: CGFloat = 40
        let scaledSize = scaledSize(baseSize, for: sizeCategory)
        return .system(size: scaledSize, weight: .semibold)
    }
    
    static func body(sizeCategory: ContentSizeCategory) -> Font {
        let baseSize: CGFloat = 16
        let scaledSize = scaledSize(baseSize, for: sizeCategory)
        return .system(size: scaledSize, weight: .regular)
    }
    
    private static func scaledSize(_ base: CGFloat, for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return base * 0.8
        case .small: return base * 0.9
        case .medium: return base
        case .large: return base * 1.1
        case .extraLarge: return base * 1.2
        case .extraExtraLarge: return base * 1.35
        case .extraExtraExtraLarge: return base * 1.5
        case .accessibilityMedium: return base * 1.65
        case .accessibilityLarge: return base * 1.8
        case .accessibilityExtraLarge: return base * 2.0
        case .accessibilityExtraExtraLarge: return base * 2.25
        case .accessibilityExtraExtraExtraLarge: return base * 2.5
        @unknown default: return base
        }
    }
}
```

### Reduce Motion 支持

```swift
// MARK: - Motion-Aware Animations
struct MoriAnimation {
    @Environment(\.accessibilityReduceMotion) static var reduceMotion
    
    static func spring<T>(value: T) -> Animation {
        if reduceMotion {
            return .easeInOut(duration: 0.1)
        } else {
            return .spring(response: 0.3, dampingFraction: 0.7)
        }
    }
    
    static func transition() -> AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            )
        }
    }
}
```

---

## 📊 Analytics & Events

### Event Tracking

```swift
// MARK: - Analytics Events
enum MoriEvent: String {
    case appOpened = "app_opened"
    case lifeGridViewed = "life_grid_viewed"
    case countdownViewed = "countdown_viewed"
    case habitMarked = "habit_marked"
    case gratitudeSaved = "gratitude_saved"
    case settingsChanged = "settings_changed"
    
    var parameters: [String: Any]? {
        switch self {
        case .habitMarked:
            return ["is_positive": true] // or false
        case .gratitudeSaved:
            return ["has_prompt": true] // or false
        default:
            return nil
        }
    }
}

// MARK: - Analytics Manager
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    func track(_ event: MoriEvent, parameters: [String: Any]? = nil) {
        // Firebase Analytics / Amplitude / Mixpanel
        var allParams = event.parameters ?? [:]
        parameters?.forEach { allParams[$0.key] = $0.value }
        
        // Analytics.logEvent(event.rawValue, parameters: allParams)
        print("📊 Analytics: \(event.rawValue) \(allParams)")
    }
}
```

---

## 🌍 本地化支持 (Localization)

### String Catalog

```
// Localizable.xcstrings
{
  "你的人生地圖": {
    "localizations": {
      "en": "Your Life Map",
      "zh-Hant": "你的人生地圖",
      "ja": "あなたの人生マップ"
    }
  },
  "你還有 %d 天 去創造回憶": {
    "localizations": {
      "en": "You have %d days to create memories",
      "zh-Hant": "你還有 %d 天 去創造回憶",
      "ja": "思い出を作る日数は残り%d日"
    }
  }
}
```

### DateFormatter 本地化

```swift
// MARK: - Localized Date Formatting
extension DateFormatter {
    static let moriDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let moriRelative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
```

---

## 🔒 隐私 & 安全

### Data Protection

```swift
// MARK: - Secure Storage
class SecureStorage {
    static let shared = SecureStorage()
    
    private let keychain = Keychain(service: "com.yourcompany.mori")
    
    func storeSensitiveData(_ data: Data, key: String) throws {
        try keychain.set(data, key: key)
    }
    
    func retrieveSensitiveData(key: String) throws -> Data? {
        return try keychain.get(key)
    }
}

// MARK: - CoreData Encryption
// CloudKit automatically encrypts data at rest
// For additional security, use NSFileProtectionComplete
let storeDescription = NSPersistentStoreDescription()
storeDescription.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)
```

### Privacy Manifest (iOS 17+)

```xml
<!-- PrivacyInfo.xcprivacy -->
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyTrackingDomains</key>
<array/>
<key>NSPrivacyCollectedDataTypes</key>
<array>
    <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeHealth</string>
        <key>NSPrivacyCollectedDataTypeLinked</key>
        <false/>
        <key>NSPrivacyCollectedDataTypeTracking</key>
        <false/>
    </dict>
</array>
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
</array>
```

---

**文档增强完成** ✅

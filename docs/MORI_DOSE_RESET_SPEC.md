# Mori DOSE Reset — Product Specification

**Version:** 1.0  
**Date:** 2026-04-29  
**Author:** Lumi  
**Status:** Draft — Pending Review  

---

## 1. Vision

> **Mori 唔係教你放鬆，係教你重新攞返個腦嘅控制權。**

Mori 原本係一個 memento mori app——用 Life Grid 同 Countdown Clock 提醒你時間有限。而家我哋將佢升級為一套完整嘅「大腦重置系統」，結合兩個核心框架：

1. **DOSE Framework**（來自 *The DOSE Effect* by T.J. Power）— 每日用四種化學物質對應嘅習慣，重建大腦健康
2. **24hr Brain Reset**（來自 Dan Koe）— 當你覺得自己「死機」時，做一次深度重置

原有嘅 Life Grid + Countdown Clock **保留並強化**，作為 Anti-Vision 嘅視覺錨點。

---

## 2. Core Concept：點樣將兩套系統融合

### Life Grid = 終極 Anti-Vision

Dan Koe 講嘅「反向願景」係要你想像「如果乜都唔改，你嘅人生會有幾悲慘」。Mori 嘅 Life Grid 本身就係呢個概念嘅視覺化：

- 你見到已過去嘅格仔（不可逆轉）
- 你見到剩低嘅格仔（越來越少）
- 每一格 = 一週 = 一個唔可以返轉頭嘅機會

**唔係嚇你，係叫你醒。** 呢個就係 Dan Koe 講嘅「用恐懼做燃料」，但用溫暖而非冷酷嘅方式呈現。

### Countdown Clock = 死線即動力

「你仲有 X 日」唔係倒數死亡，係倒數你仲有幾多時間可以選擇。每一秒都係一個選擇嘅機會。

---

## 3. Feature Architecture

### 🧱 Layer 1: Foundation（保留 + 強化）

| Feature | 現狀 | 改動 |
|---------|------|------|
| **Life Grid** | ✅ 已實現 | 加入 DOSE 色彩標記（每週完成咗邊個 DOSE 任務會有對應顏色）、Anti-Vision 引導模式 |
| **Countdown Clock** | ✅ 已實現 | 加入 "DOSE Score" 環形圖（今日嘅 DOSE 完成度圍住個 clock） |
| **Habit Tracker** | ✅ 已實現 | 改為 DOSE 四維度追蹤，不再只係 +/- |
| **Gratitude Journal** | ✅ 已實現 | 保留，作為 Serotonin 維度嘅一部分 |
| **Onboarding** | ✅ 已實現 | 加入 DOSE 介紹 + Anti-Vision 引導寫作 |

### 🔄 Layer 2: DOSE Daily System（新功能）

#### 3.1 DOSE Dashboard（主頁重新設計）

每日打開 Mori，首頁係一個 DOSE 儀表板：

```
┌─────────────────────────────────┐
│        🔥 DOSE Score: 2/4       │
│                                 │
│   ┌─────┐  ┌─────┐             │
│   │  D  │  │  O  │             │
│   │ ✅  │  │ ☐   │             │
│   └─────┘  └─────┘             │
│   Dopamine  Oxytocin           │
│   小目標完成  今日未連結         │
│                                 │
│   ┌─────┐  ┌─────┐             │
│   │  S  │  │  E  │             │
│   │ ✅  │  │ ☐   │             │
│   └─────┘  └─────┘             │
│   Serotonin Endorphins         │
│   曬咗太陽   未運動             │
│                                 │
│  ─────────────────────────────  │
│  ⏰ 你仲有 18,932 日            │
│  Life Grid: ████████░░░░  52%  │
└─────────────────────────────────┘
```

#### 3.2 DOSE 任務系統

每個維度有**一個每日任務**，從任務池隨機抽取，保持新鮮感：

**D — Dopamine（動力 / 延遲滿足）**
| 任務 | 類型 | 難度 |
|------|------|------|
| 完成一個 25 分鐘专注時段（Pomodoro） | 行動 | ⭐ |
| 早晨頭 30 分鐘唔撳手機 | 戒斷 | ⭐ |
| 完成一件拖延咗嘅小任務 | 行動 | ⭐⭐ |
| 設定一個本週目標並拆細做 3 步 | 規劃 | ⭐⭐ |
| 全日唔用社交媒體 | 戒斷 | ⭐⭐⭐ |
| 用手寫寫低 3 個今日要完成嘅事 | 規劃 | ⭐ |

**O — Oxytocin（連結 / 安全感）**
| 任務 | 類型 | 難度 |
|------|------|------|
| 打電話畀一個重要嘅人 | 行動 | ⭐ |
| 向一個人講「多謝」或者欣賞嘅說話 | 行動 | ⭐ |
| 幫一個人做一件小事 | 行動 | ⭐⭐ |
| 同朋友/家人面對面傾計 15 分鐘 | 行動 | ⭐⭐ |
| 寫一段欣賞訊息傳畀某個人 | 行動 | ⭐ |
| 今日唔用社交媒體，改為真實互動 | 戒斷 | ⭐⭐⭐ |

**S — Serotonin（穩定 / 日照 / 節奏）**
| 任務 | 類型 | 難度 |
|------|------|------|
| 出去曬太陽 10 分鐘 | 行動 | ⭐ |
| 寫低 3 件感恩嘅事（Gratitude Journal） | 習慣 | ⭐ |
| 今晚 11 點前瞓 | 習慣 | ⭐⭐ |
| 去戶外行 15 分鐘（唔睇手機） | 行動 | ⭐⭐ |
| 調整姿勢：每小時站起來伸展一次 | 習慣 | ⭐ |
| 冥想 / 靜坐 5 分鐘 | 習慣 | ⭐⭐ |

**E — Endorphins（抗壓 / 身體挑戰）**
| 任務 | 類型 | 難度 |
|------|------|------|
| 做 5 分鐘呼吸練習 | 行動 | ⭐ |
| 做 10 分鐘運動（任何形式） | 行動 | ⭐⭐ |
| 用凍水沖涼 30 秒 | 挑戰 | ⭐⭐⭐ |
| 做 3 組深呼吸（4-7-8 呼吸法） | 行動 | ⭐ |
| 行樓梯唔搭 lift | 挑戰 | ⭐⭐ |
| 看一套喜劇 / 搞笑片令自己笑出聲 | 行動 | ⭐ |

#### 3.3 DOSE 任務完成機制

- **一鍵打卡**：完成就撳 ✅，唔使填表
- **自由替換**：如果覺得今日嗰個任務唔適合，可以「換一個」
- **自訂任務**：Pro 版本可以自訂自己嘅 DOSE 任務池
- **Streak 連續紀錄**：連續完成 DOSE 4/4 會有 streak counter
- **週報**：每週 summary，邊個維度做得好、邊個需要加強

#### 3.4 Life Grid DOSE Overlay

原本嘅 Life Grid 灰色/白色格子，加入 DOSE 色彩：

- **完成 4/4 DOSE** 嘅週 → 金色格子
- **完成 3/4** → 銀色
- **完成 1-2/4** → 淡色
- **0/4** → 灰色（錯過）

你會見到自己嘅人生地圖慢慢「著色」，每一格都代表你嗰週有幾認真對待自己。

### ⚡ Layer 3: 24hr Brain Reset（新功能 — 重度模式）

當用戶覺得自己「死機」—— 冇動力、焦慮、沉迷手機、生活失控——可以啟動一次 **24hr Brain Reset**。

呢個係一個 **guided experience**，唔係普通功能。四個步驟，每步有引導、有 timer、有完成確認：

#### Step 1: Dopamine Fast（多巴胺斷食）
```
┌─────────────────────────────────┐
│  📴 DOPAMINE FAST               │
│                                 │
│  接下來 24 小時：                │
│  ✗ 手機飛航模式                  │
│  ✗ 唔睇 YouTube / Netflix       │
│  ✗ 唔打機                        │
│  ✗ 唔聽 Podcast / 音樂           │
│                                 │
│  [開始斷食]  [我準備好喇]         │
│                                 │
│  💡 提示：一開始會焦慮，          │
│  呢個係正常嘅戒斷反應。           │
│  你嘅大腦正在修復。               │
└─────────────────────────────────┘
```
- App 進入「斷食模式」，UI 變成極簡黑白
- 只有 Mori 嘅功能可用（journal、breathing）
- 提供 system-level 建議：開飛航、放低手機

#### Step 2: Brain Dump（認知卸載）
```
┌─────────────────────────────────┐
│  🧠 BRAIN DUMP                  │
│                                 │
│  用手寫低腦入面所有嘢。           │
│  焦慮、未做嘅事、煩人嘅關係...    │
│  全部倒出嚟。                    │
│                                 │
│  寫完之後，你會覺得即刻輕咗。     │
│                                 │
│  ┌─────────────────────────┐    │
│  │ (自由文字輸入區)          │    │
│  │                         │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  [完成傾倒]  ⏱ 已用 8:32        │
└─────────────────────────────────┘
```
- 鼓勵手寫（彈出提示：「最好用紙筆」）
- App 內都可以打字記錄
- 冇字數限制、冇格式要求
- 完成後有「大腦 RAM 已釋放」嘅視覺回饋

#### Step 3: Anti-Vision（反向願景）

**呢度接返 Life Grid！**

```
┌─────────────────────────────────┐
│  ⚠️ ANTI-VISION                 │
│                                 │
│  如果你由今日開始乜都唔改...     │
│                                 │
│  [Life Grid 動畫：              │
│   剩低嘅格仔逐漸變暗、           │
│   變灰，最後全部空白]             │
│                                 │
│  「你嘅 Life Grid 會係咁樣       │
│    如果繼續而家嘅生活方式。」      │
│                                 │
│  寫低你最驚嘅結局：              │
│  ┌─────────────────────────┐    │
│  │ 如果我繼續咁樣落去...     │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  [直面恐懼]                     │
└─────────────────────────────────┘
```
- Life Grid 做背景，用動畫展示「如果乜都唔改」嘅未來
- 引導式寫作：「如果我繼續而家嘅生活方式，3 年後我會變成點？5 年後呢？」
- 寫完之後，轉場到 Step 4 嘅感覺係「我一定要改」

#### Step 4: Rebuild Order（重建秩序）
```
┌─────────────────────────────────┐
│  🔧 REBUILD ORDER               │
│                                 │
│  從你嘅 Brain Dump 同 Anti-Vision│
│  揀出最關鍵嘅 3 件事。           │
│                                 │
│  ❶ _______________              │
│  ❷ _______________              │
│  ❸ _______________              │
│                                 │
│  聽日起床，你只係一個執行者。     │
│  唔需要思考，唔需要猶豫。         │
│  只需要做呢 3 件事。              │
│                                 │
│  [鎖定明日計劃 ✊]               │
└─────────────────────────────────┘
```
- 從 Brain Dump 嘅內容自動提取關鍵詞（可選）
- 用戶最終只揀 3 件核心任務
- 鎖定後，聽日 Mori 主頁會變成「執行模式」—— 只顯示呢 3 件事
- 每完成一件就有明確嘅 ✅ 回饋

### 📊 Layer 4: Insights & Streaks（數據層）

#### DOSE Score 趨勢圖
- 7 日 / 30 日 / 90 日 DOSE 完成度折線圖
- 每個維度獨立追蹤
- 識別「薄弱維度」並推薦加強建議

#### Brain Reset 歷史
- 記錄每次 Reset 嘅日期、Anti-Vision 內容、重建嘅 3 件事
- 對比 Reset 前後嘅 DOSE Score 變化
- 彷彿一個「系統重置日誌」

#### Life Grid DOSE 熱力圖
- 年度視圖：每週嘅 DOSE 分數用顏色深淺表示
- 一眼睇出邊段時間生活最有紀律、邊段時間放飛咗

---

## 4. User Journey

### 4.1 每日流程（Daily Loop）

```
起床
  │
  ▼
打開 Mori
  │
  ▼
見到 Countdown Clock（你仲有 X 日）
  │
  ▼
見到今日 DOSE 任務（D/O/S/E 各一個）
  │
  ▼
一日入面逐一完成（一鍵打卡）
  │
  ▼
睡前回顧：DOSE Score + Gratitude
  │
  ▼
Life Grid 本週格仔著色
```

### 4.2 週末流程（Weekly Reflection）

```
週日打開 Mori
  │
  ▼
週報：本週 DOSE 完成度、Gratitude 摘要
  │
  ▼
Life Grid 回顧：呢一週過得點？
  │
  ▼
下週 DOSE 任務預覽（可以提前調整難度）
```

### 4.3 死機流程（Brain Reset）

```
感覺失控 / 冇動力 / 沉迷手機
  │
  ▼
打開 Mori → 撳「⚡ Brain Reset」
  │
  ▼
Step 1: Dopamine Fast（進入斷食模式）
  │
  ▼
Step 2: Brain Dump（傾倒大腦垃圾）
  │
  ▼
Step 3: Anti-Vision（Life Grid 動畫 + 恐懼寫作）
  │
  ▼
Step 4: Rebuild Order（揀 3 件核心任務）
  │
  ▼
聽日：執行模式（只顯示 3 件事）
  │
  ▼
完成後：回到 DOSE Daily Loop
```

---

## 5. Screen Map

```
Tab 1: DOSE（主頁）
├── DOSE Dashboard（4 維度打卡）
├── 任務詳情（展開某個維度）
└── 替換任務

Tab 2: Life（原本嘅 Life Grid）
├── Life Grid（DOSE 色彩 overlay）
├── Countdown Clock
├── 點擊格仔 → 該週回憶 + DOSE 狀態
└── Anti-Vision 模式

Tab 3: Journal
├── Gratitude Journal（保留）
├── Brain Dump（新）
├── Anti-Vision 寫作（新）
└── 歷史回顧

Tab 4: Reset（新 Tab）
├── 啟動 Brain Reset
├── Reset 歷史
├── 重置前後 DOSE 對比
└── 執行模式（3 件事打卡）

Tab 5: Insights
├── DOSE Score 趨勢
├── Streak 連續紀錄
├── 薄弱維度分析
└── Life Grid 年度熱力圖
```

---

## 6. Technical Design

### 6.1 新增 Data Models

```swift
// MARK: - DOSE Daily Task
struct DOSETask: Codable, Identifiable {
    let id: UUID
    let dimension: DOSEDimension  // .dopamine, .oxytocin, .serotonin, .endorphins
    let title: String
    let type: TaskType            // .action, .habit, .detox, .challenge
    let difficulty: Int           // 1-3
    let isCompleted: Bool
    let completedAt: Date?
    let isCustom: Bool
}

enum DOSEDimension: String, Codable, CaseIterable {
    case dopamine = "D"
    case oxytocin = "O"
    case serotonin = "S"
    case endorphins = "E"
    
    var color: Color {
        switch self {
        case .dopamine: return .orange
        case .oxytocin: return .pink
        case .serotonin: return .yellow
        case .endorphins: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .dopamine: return "flame.fill"
        case .oxytocin: return "heart.fill"
        case .serotonin: return "sun.max.fill"
        case .endorphins: return "bolt.fill"
        }
    }
}

enum TaskType: String, Codable {
    case action    // 一次性行動
    case habit     // 習慣養成
    case detox     // 戒斷類
    case challenge // 挑戰類
}

// MARK: - DOSE Daily Record
struct DOSEDailyRecord: Codable {
    let date: Date
    var tasks: [DOSETask]
    var score: Int { tasks.filter(\.isCompleted).count }  // 0-4
    var isPerfect: Bool { score == 4 }
}

// MARK: - Brain Reset Session
struct BrainResetSession: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    var completedAt: Date?
    var step1Completed: Bool  // Dopamine Fast
    var step2Content: String?  // Brain Dump
    var step3Content: String?  // Anti-Vision
    var step3Tasks: [String]?  // Rebuild Order - 3 tasks
    var doseScoreBefore: Int?  // 7-day avg before reset
    var doseScoreAfter: Int?   // 7-day avg after reset
}

// MARK: - DOSE Week Overlay（for Life Grid）
struct DOSEWeekOverlay: Codable {
    let weekIndex: Int
    var doseScore: Int         // 0-4, 該週平均 DOSE 分數
    var color: String          // gold, silver, light, grey
}
```

### 6.2 Task Pool（本地 JSON）

預載一套完整嘅任務池（每個維度 20-30 個任務），存為本地 JSON。每日從池中隨機抽取，確保連續 7 日唔重複。

### 6.3 儲存策略

- 維持 **CoreData + CloudKit** 架構
- 新增 entities: `DOSEDailyRecord`, `BrainResetSession`
- Life Grid 嘅 `LifeWeek` entity 加入 `doseScore` 欄位
- 所有數據本地優先，iCloud 自動同步

### 6.4 Notifications

| 類型 | 時間 | 內容 |
|------|------|------|
| Morning DOSE | 08:00 | 「今日嘅 DOSE 任務已準備好 🔥」 |
| Midday Nudge | 13:00 | 「完成咗幾多個 DOSE？」（如果 < 2） |
| Evening Reflect | 21:00 | 「睡前回顧：今日 DOSE Score？」 |
| Reset Check | 週日 20:00 | 「呢個禮拜過得點？需要 Brain Reset 嗎？」 |

---

## 7. Monetization

| 層級 | 免費版 | Pro（HK$28/月） |
|------|--------|-----------------|
| Life Grid | ✅ | ✅ |
| Countdown Clock | ✅ | ✅ |
| DOSE Daily（基礎任務池） | ✅ | ✅ |
| Gratitude Journal | ✅（限 7 日歷史） | ✅（無限） |
| Brain Reset | ✅（每月 1 次） | ✅（無限） |
| 自訂 DOSE 任務 | ❌ | ✅ |
| DOSE Insights 趨勢 | ❌ | ✅ |
| Life Grid 熱力圖 | ❌ | ✅ |
| Reset 歷史對比 | ❌ | ✅ |
| Notification 自訂 | ❌ | ✅ |

---

## 8. MVP Scope（Phase 1）

**目標：6 週內交付**

### Phase 1A — DOSE Daily（Week 1-3）
- [x] DOSE Dashboard UI
- [ ] 任務池（每維度 10 個任務 = 40 個）
- [ ] 每日隨機派發 + 一鍵打卡
- [ ] 替換任務功能
- [ ] DOSE Score 計算 + 顯示
- [ ] Streak 連續紀錄
- [ ] 基礎 notification（早午晚）

### Phase 1B — Brain Reset（Week 3-4）
- [ ] Brain Reset 入口 + 4 步引導 UI
- [ ] Brain Dump 文字輸入
- [ ] Anti-Vision Life Grid 動畫
- [ ] Rebuild Order（揀 3 件事）
- [ ] 執行模式（隔日主頁變成 3 件事）

### Phase 1C — Integration（Week 5-6）
- [ ] Life Grid DOSE Overlay 色彩
- [ ] Tab bar 重構（5 tabs）
- [ ] 週報 summary
- [ ] Onboarding 更新（DOSE 介紹）
- [ ] Bug fix + Polish
- [ ] App Store 提交準備

### Post-MVP（Phase 2）
- DOSE Insights 趨勢圖
- 自訂任務（Pro）
- 熱力圖年度視圖
- Apple Health / Apple Watch 整合
- Widget（DOSE Score + 倒數）
- 社交分享（匿名 DOSE 分數比較）

---

## 9. Brand & Tone

### 聲音
- **直接但有溫度**：唔扮勵志大師，好似一個醒目嘅朋友提點你
- **粵英混合**：HK 用戶自然嘅語言習慣
- **唔囉嗦**：一句講完唔用三句

### 範例文案
- ✅ 「今日嘅 D 任務：完成一件拖延咗嘅事。你知邊件。」
- ✅ 「你已經連續 7 日完成 DOSE。呢個唔係運氣，係紀律。」
- ✅ 「Anti-Vision 唔係嚇你。係叫你睇清楚。」
- ❌ 「讓我們一起努力，每一天都是嶄新的開始！💪✨」
- ❌ 「Believe in yourself! You can do it! 🌈」

### 顏色更新

保留原本嘅 Warm Minimalism，加入 DOSE 四色作為 accent：

| 維度 | 顏色 | Hex |
|------|------|-----|
| Dopamine | 暖橙 | `#FF8C42` |
| Oxytocin | 柔粉 | `#FF6B8A` |
| Serotonin | 日光黃 | `#FFD166` |
| Endorphins | 冷藍 | `#4ECDC4` |

基調依然係米白/暖灰，DOSE 色只係點綴。

---

## 10. Competitive Positioning

| | Mori | Finch | Fabriq | Daylio |
|---|---|---|---|---|
| Memento Mori / Anti-Vision | ✅ | ❌ | ❌ | ❌ |
| DOSE 化學物質框架 | ✅ | ❌ | ❌ | ❌ |
| Brain Reset 引導 | ✅ | ❌ | ❌ | ❌ |
| 日常習慣追蹤 | ✅ | ✅ | ✅ | ✅ |
| Journaling | ✅ | ✅ | ❌ | ❌ |
| Life Visualization | ✅ | ❌ | ❌ | ❌ |

**差異化重點**：Mori 係唯一一個將「死亡覺醒 + 大腦化學 + 重置系統」三合一嘅 app。

---

## 11. Success Metrics

| 指標 | MVP 目標 | 6 個月目標 |
|------|----------|-----------|
| DAU | 100 | 1,000 |
| 7 日留存 | 30% | 40% |
| DOSE 日完成率 | 50% 用戶 ≥ 2/4 | 60% 用戶 ≥ 3/4 |
| Brain Reset 使用率 | 20% 用戶每月 ≥ 1 次 | 35% |
| App Store 評分 | ≥ 4.2 | ≥ 4.5 |
| Pro 轉換率 | — | 5% |

---

## 12. Open Questions

- [ ] 任務池語言：全中文？中英混合？根據用戶語言設定？
- [ ] Brain Reset 要唔需要「完成斷食先可以入下一步」？定係自由跳步？
- [ ] Life Grid DOSE Overlay 會唔會令原本嘅簡潔感消失？需要 A/B test
- [ ] 社交元素：未來加唔加「朋友 DOSE 分數比較」？
- [ ] Apple Watch：DOSE 打卡可唔可以喺手錶做？

---

**下一步：Review 完後，交畀 Flare 出 UI Mockups，Phoenix 開始搭 DOSE Dashboard。**

---

## 13. Screen Time Integration

### 13.1 Apple FamilyControls

利用 iOS 原生嘅 FamilyControls + DeviceActivity + ManagedSettings framework，實際限制手機使用，而唔係靠意志力。

**需要的 entitlement：**
- `Family Controls` entitlement（向 Apple 申請）
- 用戶明確授權（系統權限對話框）
- iOS 16+ 完整支援

**功能對應：**

| DOSE Feature | Screen Time 用法 |
|---|---|
| Dopamine Fast | ManagedSettings block 指定 apps（社交媒體、YouTube、遊戲） |
| Morning 離手機任務 | DeviceActivity 監測起床後 30 分鐘手機使用 |
| Daily DOSE Score | Screen Time 數據作為 Dopamine 維度客觀指標 |
| Insights | 對比 Screen Time vs DOSE Score 關聯分析 |
| Brain Reset 24hr | 全面限制，進入 Deep Focus 模式 |

### 13.2 Screen Time 數據 → DOSE Dopamine 評分

Screen Time 可以作為 Dopamine 維度嘅**客觀補充**：

- 每日 Screen Time < 目標值 → Dopamine 任務自動 ✅
- 每日 Screen Time > 目標值 → Dopamine 分數下降
- 社交媒體使用時間 > 閾值 → 觸發「建議進行 Dopamine Fast」提示

---

## 14. Emergency Contact Unlock（Accountability Partner）

### 14.1 核心機制

當用戶啟動 Dopamine Fast / Brain Reset 時，Mori 會鎖定指定 apps。如果用戶真係需要解鎖，唔係自己撳個掣就解到——要搵你嘅 Accountability Partner。

```
用戶啟動 Dopamine Fast / Brain Reset
  │
  ▼
Mori 透過 ManagedSettings 鎖定指定 apps
  │
  ▼
Lock screen：「專注模式進行中 — 剩餘 18:32:15」
  │
  ▼
用戶想解鎖：
  → 撳「Emergency Unlock」
  → Mori 發 SMS / Push Notification 去 Emergency Contact
  → 訊息：「XX 正在進行專注模式，佢請求解鎖。
           如果你覺得合理，畀呢個密碼佢：7294」
  │
  ├─ Emergency Contact 畀了密碼 → 用戶輸入密碼解鎖
  │   （Fast 中斷，DOSE score 受影響，記錄在 Reset 歷史）
  │
  └─ Emergency Contact 唔畀 → 用戶繼續 Fast
      （有外力支持，更容易堅持）
```

### 14.2 點解呢個設計好

1. **社交承諾壓力（Accountability）** — 你要搵人幫你解鎖，呢個本身就係強大嘅阻嚇力
2. **Oxytocin 自動觸發** — 同 Emergency Contact 嘅互動 = 真實人際連結，完美結合 DOSE 嘅 O 維度
3. **唔係死鎖** — 真正有需要時有出路，唔會搞到用戶焦慮反而放棄
4. **Accountability Partner 角色化** — 唔只係一個 contact，而係你嘅「DOSE 守護者」

### 14.3 Emergency Contact 設定

```
┌─────────────────────────────────┐
│  🛡️ Accountability Partner      │
│                                 │
│  你嘅「DOSE 守護者」             │
│  當你進行 Fast 時，             │
│  只有佢哋可以授權解鎖。          │
│                                 │
│  守護者 1: 媽媽 ☎️ ✅           │
│  守護者 2: +852 9XXX XXXX ✅    │
│  守護者 3: + 新增               │
│                                 │
│  解鎖密碼發送方式：              │
│  ○ SMS（推薦）                  │
│  ○ Push Notification（需裝 Mori）│
│                                 │
│  模式：                         │
│  ● Grace Mode（有守護者後備）    │
│  ○ Strict Mode（完全唔能解鎖）  │
│                                 │
│  自訂訊息：                     │
│  「我正在進行專注模式，           │
│   如果你覺得OK，畀呢個密碼我。」 │
│                                 │
│  [儲存設定]                     │
└─────────────────────────────────┘
```

### 14.4 Unlock Flow Detail

**一次解鎖流程：**

1. 用戶在鎖定狀態下撳「Emergency Unlock」
2. Mori 彈出確認：「你確定要請求解鎖？你嘅守護者會收到通知。」
3. 確認後：
   - 生成 4 位數一次性密碼（OTP）
   - 發送到 Emergency Contact（SMS / Push）
   - 訊息包含：用戶名、模式名稱、剩餘時間、OTP
4. 用戶輸入 OTP → 解鎖成功
5. 記錄：
   - 解鎖時間
   - 哪個守護者授權
   - Fast 剩餘時間
   - DOSE Score 影響

**DOSE Score 影響：**
- 完成整個 Fast（冇解鎖）：Dopamine ✅ + 額外 bonus
- 解鎖 1 次：Dopamine 仍然 ✅（因為有 accountability 過程）
- 解鎖 2+ 次：Dopamine ❌（證明意志力不足）
- 提前終止 Fast：Dopamine ❌

### 14.5 訊息模板

**SMS 範例（預設）：**
> 🛡️ Mori 專注模式通知
> {{userName}} 正在進行「Dopamine Fast」（剩餘 {{remainingTime}}）。
> 佢請求解鎖。如果你覺得合理，請將以下密碼告知：
> 🔓 {{OTP}}
> （一次性密碼，5 分鐘內有效）

**自訂訊息（用戶可改）：**
> {{userName}} 搵你幫手解鎖專注模式。佢已經堅持咗 {{elapsedTime}}。如果你覺得OK，密碼係 {{OTP}}。

### 14.6 技術實現

```swift
// Emergency Contact Model
struct AccountabilityPartner: Codable {
    let id: UUID
    var name: String
    var phone: String          // E.164 format
    var relationship: String?  // e.g. "媽媽", "好朋友"
    var notifyMethod: NotifyMethod  // .sms or .push
}

enum NotifyMethod: String, Codable {
    case sms
    case push  // requires Mori installed on partner's device
}

// Unlock Request
struct UnlockRequest: Codable {
    let id: UUID
    let sessionId: UUID           // BrainResetSession or FastSession
    let partnerId: UUID           // which partner was contacted
    let otp: String               // 4-digit code
    let otpExpiresAt: Date        // 5 min validity
    var isResolved: Bool
    var resolvedAt: Date?
    var wasGranted: Bool
    var partnerResponseTime: TimeInterval?
}

// Fast Session (extends BrainResetSession)
struct FastSession: Codable {
    let id: UUID
    let startedAt: Date
    var plannedEndTime: Date
    var actualEndTime: Date?
    var isActive: Bool
    var unlockAttempts: [UnlockRequest]
    var mode: FastMode
    var blockedApps: [String]     // bundle IDs
    var doseImpact: DoseImpact
}

enum FastMode: String, Codable {
    case grace    // 有守護者後備
    case strict   // 完全唔能解鎖
}
```

### 14.7 保安考慮

- OTP 只有 5 分鐘有效期
- 每次解鎖 request 只能發一次 OTP
- OTP 用完即失效，唔可以重用
- 所有 unlock 記錄加密存儲
- Emergency Contact 電話號碼唔會上傳到 server（本地 only）
- SMS 經過第三方 gateway 發送（如 Twilio），Mori server 唔儲存通訊內容

---

## 15. Updated MVP Scope（加入 Screen Time + Emergency Unlock）

### Phase 1A — DOSE Daily（Week 1-3）— 不變
- DOSE Dashboard + Task Pool + Streak

### Phase 1B — Brain Reset（Week 3-4）— 更新
- Brain Reset 4 步引導
- **NEW: Screen Time 整合** — 用 DeviceActivity 監測 Fast 期間手機使用
- **NEW: Emergency Contact 設定頁面**（Onboarding 一部分）
- **NEW: Emergency Unlock 流程**（SMS OTP）

### Phase 1C — Integration（Week 5-6）— 更新
- Life Grid DOSE Overlay
- **NEW: Screen Time vs DOSE Score 對比圖**
- **NEW: Unlock 歷史記錄**
- Polish + App Store

### Phase 2（Post-MVP）
- ManagedSettings 深度整合（直接 block apps）
- Apple Watch companion（DOSE 打卡 + 快速 check）
- Widget（DOSE Score + Screen Time + Countdown）
- 社交功能（匿名 DOSE 排行榜 + Accountability Partner matching）

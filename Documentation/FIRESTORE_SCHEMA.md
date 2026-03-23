# Firestore Schema

Soulverse 在 Firestore 上的完整資料結構定義。

## 整體結構

```
Firestore
├── users/{uid}                              # 使用者資料
│   ├── mood_checkins/{checkinId}            # 情緒打卡紀錄
│   ├── drawings/{drawingId}                 # 繪畫紀錄
│   └── journals/{journalId}                 # 日記紀錄
│
Firebase Storage
└── users/{uid}/drawings/{drawingId}/
    ├── image.png                            # 完成的繪畫圖片 (PNG)
    ├── recording.pkd                        # PencilKit 繪畫過程二進位資料
    └── thumbnail.png                        # 縮圖 (未來由 Cloud Functions 產生)
```

---

## Collections

### 1. `users/{uid}`

使用者基本資料，在登入或 onboarding 時建立/更新。

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `uid` | `string` (DocumentID) | auto | Firebase Auth UID，作為 document ID |
| `email` | `string` | Yes | 使用者 email |
| `displayName` | `string` | Yes | 顯示名稱 |
| `platform` | `string` | Yes | 登入平台（如 `"apple"`, `"google"`, `"facebook"`） |
| `birthday` | `timestamp` | No | 生日 |
| `gender` | `string` | No | 性別 |
| `planetName` | `string` | No | 使用者的星球名稱 |
| `emoPetName` | `string` | No | 情緒寵物名稱 |
| `selectedTopic` | `string` | No | Onboarding 選擇的主題 |
| `hasCompletedOnboarding` | `boolean` | No | 是否完成 onboarding |
| `fcmToken` | `string` | No | Firebase Cloud Messaging 推播 token |
| `createdAt` | `timestamp` | auto | 建立時間（`@ServerTimestamp`） |
| `updatedAt` | `timestamp` | auto | 更新時間（`@ServerTimestamp`） |

**對應程式碼**: `UserModel` (`Shared/Service/UserService/UserModel.swift`)

---

### 2. `users/{uid}/mood_checkins/{checkinId}`

情緒打卡紀錄，每次打卡產生一筆。欄位對應打卡流程的四個步驟：Sensing → Naming → Attributing → Evaluating。

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `id` | `string` (DocumentID) | auto | 自動產生的 document ID |
| `colorHex` | `string` | Yes | 選擇的顏色（hex 格式，如 `"#FF5733"`） |
| `colorIntensity` | `number` | Yes | 顏色強度（`0.0` ~ `1.0`） |
| `emotion` | `string` | Yes | 情緒名稱（`RecordedEmotion.uniqueKey`） |
| `topic` | `string` | Yes | 歸因主題（`Topic.rawValue`） |
| `evaluation` | `string` | Yes | 自我評估（`EvaluationOption.rawValue`） |
| `reflectionPrompt` | `string` | Yes | 反思提示詞（submit 時必填，model 宣告 optional 以相容舊文件） |
| `reflection` | `string` | No | 使用者的反思文字 |
| `journalId` | `string` | No | 關聯的日記 ID（由 `FirestoreJournalService` batch write 設定） |
| `drawingId` | `string` | No | 關聯的繪畫 ID（由 `FirestoreDrawingService` batch write 設定） |
| `timezoneOffsetMinutes` | `number` | Yes | 使用者時區偏移（分鐘） |
| `createdAt` | `timestamp` | auto | 建立時間（`@ServerTimestamp`） |
| `updatedAt` | `timestamp` | auto | 更新時間（`@ServerTimestamp`） |

**對應程式碼**: `MoodCheckInModel` (`Shared/Service/MoodCheckInService/MoodCheckInModel.swift`)

**常用查詢**:
- 依 `createdAt` 降冪排序取最新 N 筆
- 以 `createdAt` 做 cursor-based 分頁
- 依日期範圍查詢（`createdAt >= startDate` 且 `createdAt < endDate`）

**雙向參照**:
- `journalId` ↔ `journals/{journalId}.checkinId`
- `drawingId` ↔ `drawings/{drawingId}.checkinId`
- 透過 Firestore batch write 確保一致性

---

### 3. `users/{uid}/drawings/{drawingId}`

繪畫紀錄，可獨立存在或連結到某次情緒打卡。實際圖檔存放於 Firebase Storage。

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `id` | `string` (DocumentID) | auto | 自動產生的 document ID |
| `checkinId` | `string` | No | 關聯的打卡紀錄 ID（若從打卡流程中建立） |
| `isFromCheckIn` | `boolean` | Yes | 是否從打卡流程中建立 |
| `imageURL` | `string` | Yes | 完成圖片的 Storage 下載 URL |
| `recordingURL` | `string` | Yes | PencilKit 繪畫過程的 Storage 下載 URL |
| `thumbnailURL` | `string` | No | 縮圖 URL（未來功能） |
| `promptUsed` | `string` | No | 使用的繪畫提示/模板 ID |
| `templateName` | `string` | No | 模板名稱 |
| `timezoneOffsetMinutes` | `number` | Yes | 使用者時區偏移（分鐘） |
| `createdAt` | `timestamp` | auto | 建立時間（`@ServerTimestamp`） |
| `updatedAt` | `timestamp` | auto | 更新時間（`@ServerTimestamp`） |

**對應程式碼**: `DrawingModel` (`Shared/Service/DrawingService/DrawingModel.swift`)

**常用查詢**:
- 依日期範圍查詢（`createdAt` 範圍）
- 依 `checkinId` 查詢關聯繪畫

---

### 4. `users/{uid}/journals/{journalId}`

日記紀錄，每筆對應一次情緒打卡（1:1 關係）。

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `id` | `string` (DocumentID) | auto | 自動產生的 document ID |
| `title` | `string` | No | 日記標題 |
| `content` | `string` | No | 日記內容 |
| `prompt` | `string` | No | 寫作提示詞 |
| `checkinId` | `string` | Yes | 關聯的打卡紀錄 ID |
| `timezoneOffsetMinutes` | `number` | Yes | 使用者時區偏移（分鐘） |
| `createdAt` | `timestamp` | auto | 建立時間（`@ServerTimestamp`） |
| `updatedAt` | `timestamp` | auto | 更新時間（`@ServerTimestamp`） |

**對應程式碼**: `JournalModel` (`Shared/Service/JournalService/JournalModel.swift`)

**常用查詢**:
- 依 `checkinId` 查詢關聯日記（0 或 1 筆）
- 依 `journalId` 直接取得（透過 checkin 的 `journalId` 欄位）
- 依日期範圍查詢

**一致性保證**:
- `submitJournal` 使用 batch write 同時建立 journal 文件和設定 checkin 的 `journalId`
- `deleteJournal` 使用 batch write 同時刪除 journal 文件和清除 checkin 的 `journalId`
- 1:1 關係由 application layer 在 submit 前檢查確保

---

## Firebase Storage 結構

所有繪畫檔案存放於：`users/{uid}/drawings/{drawingId}/`

| 檔案 | Content Type | 說明 |
|------|-------------|------|
| `image.png` | `image/png` | 完成的繪畫圖片 |
| `recording.pkd` | `application/octet-stream` | PencilKit 繪畫過程二進位資料 |
| `thumbnail.png` | `image/png` | 縮圖（未來由 Cloud Functions 自動產生） |

**對應程式碼**: `StorageFile` enum (`Shared/Service/FirestoreSchema.swift`)

---

## 資料關聯

```
UserModel (users/{uid})
│
├── MoodCheckInModel (mood_checkins/{checkinId})
│   ├── drawingId ←→ DrawingModel.checkinId    (雙向參照, batch write)
│   └── journalId ←→ JournalModel.checkinId    (雙向參照, batch write)
│
├── DrawingModel (drawings/{drawingId})
│   ├── checkinId → 可指向某筆 mood_checkins
│   └── Storage files → users/{uid}/drawings/{drawingId}/*
│
└── JournalModel (journals/{journalId})
    └── checkinId → 指向某筆 mood_checkins
```

**資料組裝邏輯**（`MoodEntriesDataAssembler`）：
1. 每筆打卡成為一張卡片
2. 有 `checkinId` 的繪畫附加到對應打卡卡片
3. 介於兩次打卡之間的獨立繪畫，附加到前一次打卡
4. 當天沒有打卡的獨立繪畫，成為「孤兒卡片」（以日期分組）

---

## Schema 定義檔

所有 collection name 和 Storage path 統一定義於 `FirestoreSchema.swift`：

- `FirestoreCollection.users` → `"users"`
- `FirestoreCollection.moodCheckIns` → `"mood_checkins"`
- `FirestoreCollection.drawings` → `"drawings"`
- `FirestoreCollection.journals` → `"journals"`
- `StorageFile` enum → 檔案名稱與 content type

**不要在程式碼中直接寫 collection 字串，一律使用 `FirestoreCollection` 常數。**

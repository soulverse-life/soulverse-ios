# Claude Code 進階學習指南

> 為 Soulverse iOS 專案量身定制，涵蓋 Agent/Sub-agent、Git Worktree、Skills 三大核心概念，
> 以及我們實際建構的 `/fix-bug` 自動化工作流程。

---

## 1. Agent / Sub-agent 系統

### 什麼是 Sub-agent？

Sub-agent 是在獨立 context window 中執行特定任務的助手。每個 sub-agent 可以有自己的 system prompt、工具權限、model 選擇。主要好處是隔離 token 消耗，讓主對話保持乾淨。

### 內建 Agent 類型

| Agent | Model | 可用工具 | 最適合 |
|-------|-------|---------|--------|
| **Explore** | Haiku（快速） | 唯讀（Read, Grep, Glob） | 快速搜尋 codebase |
| **Plan** | 繼承 | 唯讀 | 規劃實作方案 |
| **General-purpose** | 繼承 | 全部 | 複雜多步驟任務 |
| **Bash** | 繼承 | 終端指令 | 執行 command |

### 什麼時候該用 Sub-agent？

**適合：**
- 任務會產生大量 output（跑測試、處理 log）
- 需要限制工具權限（只讀、只能用 bash）
- 工作可以獨立完成，只需要回傳摘要
- 需要平行處理多個方向
- 隔離大量 token 消耗的子任務

**不適合：**
- 需要頻繁來回互動
- 多階段共享大量 context
- 快速小改動

### 建立自定義 Sub-agent

在 `.claude/agents/` 目錄下建立 Markdown 檔案：

```yaml
---
name: regression-checker
description: "Verify iOS project builds and check for regressions."
tools: Bash, Read, Grep, Glob
model: sonnet
maxTurns: 12
permissionMode: acceptEdits   # 自動接受編輯，不跳確認
---

你是 QA 工程師，負責驗證 Soulverse iOS 專案的變更...
```

**重要 Frontmatter 欄位：**

| 欄位 | 說明 |
|------|------|
| `name` | 唯一識別碼 |
| `description` | Claude 根據描述決定何時自動委派 |
| `tools` | 允許使用的工具 |
| `model` | sonnet / opus / haiku / inherit |
| `maxTurns` | 最大執行回合數 |
| `permissionMode` | default / acceptEdits / plan / bypassPermissions |

### Soulverse 實際使用的 Sub-agents

| Agent | 用途 | 檔案 |
|-------|------|------|
| **project-manager** | PRD、Todo 管理、進度追蹤 | `.claude/agents/project-manager.md` |
| **regression-checker** | Build/Test/靜態分析驗證 | `.claude/agents/regression-checker.md` |

---

## 2. Git Worktree

### 什麼是 Git Worktree？

讓你從同一個 repo 同時 checkout 多個 branch 到不同目錄，共享 Git history，但各自有獨立的工作區。

### Soulverse 的 Worktree 策略：固定 Worktree

因為 CocoaPods 的 `pod install` 很慢，我們採用**固定 worktree** 而不是每次建新的：

```
Soulverse/              ← 主 repo（main branch）
../soulverse-fix/       ← 固定的 fix worktree（一次 pod install，重複使用）
```

**流程：**
```bash
# 第一次：建立 worktree + 安裝 pods（只做一次）
git worktree add "../soulverse-fix" main
cd "../soulverse-fix" && pod install

# 之後每次修 bug：
cd "../soulverse-fix"
git checkout main && git pull origin main
git branch --merged main | grep 'fix/' | xargs -r git branch -d   # 清理已 merge 的 branch
git checkout -b "fix/<slug>"
# ... 修完 push 後，branch 可刪，worktree 留著
```

### 為什麼比每次建新 Worktree 好？

| | 每次新 Worktree | 固定 Worktree |
|---|---|---|
| `pod install` | 每次都要跑 | 只跑一次 |
| 磁碟空間 | 每個都有完整 Pods/ | 共用一份 |
| 啟動速度 | 慢（等 pods） | 快（直接開 branch） |
| 清理 | 要記得 `git worktree remove` | 自動清 merged branch |

---

## 3. Skill 系統

### 什麼是 Skill？

Skill 是教 Claude 執行特定任務的擴充功能，由 `SKILL.md` 定義。

### 觸發方式

| 方式 | 說明 |
|------|------|
| **自動** | Claude 根據 description 自動判斷 |
| **手動** | 用 `/skill-name` 呼叫 |
| **禁止自動** | `disable-model-invocation: true`，只能手動 |

### 可以同時使用多個 Skill 嗎？

**可以。** 幾種方式：
1. Claude 根據需求自動載入多個相關 skill
2. Sub-agent 的 `skills:` 欄位預載多個
3. 手動連續呼叫 `/skill-a` → `/skill-b`

### Soulverse 現有的 Skills

| Skill | 用途 |
|-------|------|
| **fix-bug** | 自動化 bug 修復全流程 |
| **ios-developer** | iOS/Swift/SwiftUI 開發知識 |
| **firebase** | Firebase 整合 |
| **github-automation** | GitHub 自動化 |
| **mobile-design** | 行動裝置設計原則 |
| **ios-hig** | Apple Human Interface Guidelines |

---

## 4. `/fix-bug` 工作流程（實戰案例）

這是我們用 Skill + Sub-agent + Worktree + Hooks 組合出的完整自動化流程。

### 架構圖

```
/fix-bug <bug描述>
       │
  Phase 1 ── 檢查固定 worktree → sync main → 清理 merged branches → 建 fix/ branch
       │
  Phase 2 ── 分析 bug（互動式，可以問你問題）
       │
  Phase 3a ─ 🛑 HARD GATE：提出修復計畫 → macOS 通知 → 等你確認
       │
       │     你說「好」之後，以下全部自動執行 ↓
       │
  Phase 3b ─ /pm add 建立持久 task（寫入 TODO.md）
       │
  Phase 4 ── sub-agent 實作 fix（自動放行 Edit 權限）
       │
  Phase 5 ── regression-checker agent 驗證 build/test → macOS 通知
       │         │
       │    失敗 → 重新實作（最多 3 輪）
       │
  Phase 6 ── git commit + push + gh pr create
       │     /pm done + /pm sync
       │     macOS 通知「PR 已建立」
       ▼
     完成！
```

### 設計決策與學習要點

#### 1. HARD GATE 模式

Claude 在面對簡單任務時會自行跳過「等待確認」的步驟。解法是同時用「命令式」和「解釋 why」：

```markdown
## Phase 3a: Fix Plan — 🛑 HARD GATE

Present the plan below and then STOP. Do not proceed to Phase 3b or Phase 4.
Do not write any code. Do not spawn any sub-agents. Do not touch any files.

Why: the user needs to review the plan before code changes...
```

跟 Claude 說「為什麼」比只說「一定要」更有效，但兩個一起用效果最好。

#### 2. `/pm` 整合實現斷線恢復

```
Phase 3b: /pm add fix/<slug>: <摘要> [P1] [M]   → 寫入 TODO.md
Phase 6c: /pm done <task_id> + /pm sync          → 標記完成
```

斷線恢復：
1. `TODO.md` task 持久化
2. Worktree 和 branch 留在磁碟上
3. 新 session → `/pm load` → 看到進行中的 task → 繼續

#### 3. macOS 通知（Hooks + osascript）

**通用 Hook**（`.claude/settings.json`）：
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"...\" with title \"Soulverse\" sound name \"Glass\"'"
      }]
    }]
  }
}
```

**精準觸發**（SKILL.md 內嵌）：
| 時間點 | 訊息 | 音效 |
|--------|------|------|
| Plan 就緒 | 修復計畫已準備好 | Glass |
| 驗證完成 | Regression 驗證完成 | Glass |
| PR 建好 | Bug fix 完成！PR 已建立 | Hero |

#### 4. 權限自動放行

`settings.local.json` 中設定：
```json
{
  "permissions": {
    "allow": [
      "Edit(*)",
      "Write(*)",
      "Bash(git worktree:*)",
      "Bash(git branch:*)",
      "Bash(osascript:*)"
    ]
  }
}
```

Sub-agent 也可以在 frontmatter 設定 `permissionMode: acceptEdits`。

#### 5. 固定 Worktree 避免重複 pod install

CocoaPods 專案的痛點：每個 worktree 都要跑 `pod install`。
解法：用一個固定的 `../soulverse-fix/` worktree，只在第一次建立時 install pods，之後只切 branch。

---

## 5. 快速對照表

### Sub-agent vs Skill vs Command

| 特性 | Sub-agent | Skill | Command |
|------|-----------|-------|---------|
| 位置 | `.claude/agents/` | `.claude/skills/` | `.claude/commands/` |
| Context | 獨立 window | 在主 context | 在主 context |
| 觸發 | 自動或 Task tool | 自動或 `/name` | 只能 `/name` |
| 最適合 | 隔離任務 | 可重用流程 | 快速操作 |

### Permission Modes

| Mode | 行為 |
|------|------|
| `default` | 每個工具首次使用要確認 |
| `acceptEdits` | Edit/Write 自動放行 |
| `plan` | 唯讀，不能修改 |
| `bypassPermissions` | 全部自動放行 |

### Hook Events

| Event | 觸發時機 | 用途 |
|-------|---------|------|
| `Notification` | Claude 發通知時 | 桌面提醒 |
| `Stop` | Claude 回覆結束時 | 等待輸入提醒 |
| `PreToolUse` | 工具執行前 | 攔截/驗證 |
| `PostToolUse` | 工具執行後 | log/格式化 |

---

## 延伸資源

- [Claude Code Sub-agents 文件](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Skills 文件](https://code.claude.com/docs/en/skills.md)
- [Claude Code Hooks 文件](https://code.claude.com/docs/en/hooks)
- [Claude Code Permissions 文件](https://code.claude.com/docs/en/permissions.md)
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows.md)
- [Git Worktree 官方文件](https://git-scm.com/docs/git-worktree)

---
name: new-feature
description: "End-to-end feature development workflow for the Soulverse iOS project. Takes a feature idea or PRD, brainstorms and refines it, creates a detailed implementation plan, implements with sub-agents, runs verification, and opens a PR. Automatically applies the right superpowers skills at each phase — you don't need to remember which to use. Use whenever the user wants to build a new feature, add functionality, implement a screen, or says things like 'I want to add...', 'let's build...', 'new feature:', or describes functionality they want."
disable-model-invocation: true
argument-hint: "<feature description, PRD, or Figma link>"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Task
---

# New Feature — Soulverse Feature Development Workflow

The user triggered `/new-feature` with: **$ARGUMENTS**

## Skill Orchestration Map

This workflow automatically applies the right skills at each phase.
You do NOT need to ask the user which skill to use — just follow the map.

```
Phase 1  Setup        → worktree + feat/ branch
Phase 2  Brainstorm   → refine requirements ← brainstorming + multi-agent-brainstorming
Phase 3  Plan         → implementation plan ← writing-plans + ios-developer + ios-hig
                        🛑 HARD GATE: wait for user approval
Phase 4  TODO.md      → write task to TODO.md  ─┐
Phase 5  Implement    → build the feature         │ auto-continue
                        ← executing-plans          │ after plan
                        + ios-developer            │ approval
                        + mobile-design            │
Phase 6  Review       → self-review (MANDATORY OUTPUT) ← requesting-code-review + verification-before-completion
Phase 7  Verify       → regression check
Phase 8  PR + /pm     → create PR + complete tasks ─┘
```

## Execution Rules

**HARD GATE — Phase 3**: Present plan → STOP → wait for user approval. No exceptions.

All other gates (Phase 4 through Phase 8) auto-continue after plan approval.
The user confirmed the direction — let Claude handle the rest.

TODO.md writes in Phase 4 and Phase 8 are MANDATORY (session recovery on disconnection).
Phase 6 self-review MUST produce visible output — do NOT skip or merge into Phase 7.

---

## Phase 1: Worktree & Branch Setup

Generate a short kebab-case slug from the feature (e.g. `mood-journal`, `onboarding-flow`).

Reuse the fixed worktree to avoid repeated `pod install`:

### 1a. Ensure worktree exists

```bash
if [ -d "../soulverse-feature" ]; then
  echo "Worktree exists"
else
  git worktree add "../soulverse-feature" main
  cd "../soulverse-feature" && pod install
fi
```

### 1b. Clean up, sync, and create branch

```bash
cd "../soulverse-feature"
git status --porcelain
```

If uncommitted changes exist, ask the user: stash, discard, or abort.

```bash
git checkout main && git pull origin main

# Clean up merged feature and fix branches
git branch --merged main | grep -E '(feat/|fix/)' | xargs -r git branch -d

git checkout -b "feat/<slug>"
```

---

## Phase 2: Brainstorm & Refine Requirements

**Skills used: `brainstorming` + `multi-agent-brainstorming`**

This phase adapts based on what the user provided:

### If the user provided a PRD or detailed spec:
1. Read and summarize the key requirements
2. Identify ambiguities or missing pieces
3. Ask targeted clarifying questions (max 3)

### If the user provided a rough idea:
1. Use the **brainstorming** approach — Socratic questioning to refine:
   - "What problem does this solve for the user?"
   - "What's the minimum viable version of this?"
   - "What screens or interactions are involved?"
2. For complex features, consider using **multi-agent-brainstorming** via the Task tool:
   spawn a sub-agent to run a structured design review with multiple perspectives
   (product, engineering, UX, edge cases)

### If the user provided a Figma link:
1. Fetch the design using the Figma MCP tool if available
2. Extract screen layouts, components, and interaction patterns
3. Map Figma components to existing Soulverse UI patterns

### Output of Phase 2:

Summarize the refined requirements:
```
## Feature Requirements

### User Story
As a [user type], I want to [action] so that [benefit].

### Scope
- What's included: [list]
- What's NOT included: [list]

### Key Screens / Interactions
1. [Screen/Interaction 1]
2. [Screen/Interaction 2]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

Get a quick confirmation from the user: "這些需求正確嗎？" before proceeding to planning.

---

## Phase 3: Implementation Plan — 🛑 HARD GATE

**Skills used: `writing-plans` + `ios-developer` + `ios-hig` + `mobile-design`**

Create a detailed implementation plan following the **writing-plans** pattern:
bite-sized tasks (each 2-5 minutes), exact file paths, verification steps.

Apply domain knowledge from:
- **ios-developer**: Swift patterns, VIPER architecture, iOS APIs
- **ios-hig**: Accessibility, dark mode, touch targets, haptics
- **mobile-design**: Touch interaction, performance, platform conventions

### Plan Format:

```
## Implementation Plan: <Feature Name>

### Architecture Decision
- Where this feature lives: Soulverse/Features/<FeatureName>/
- Pattern: [VIPER — Presenter/Views/ViewModels]
- New files needed: [list]
- Existing files to modify: [list]

### Task Breakdown

#### Task 1: Create feature folder structure
- Create: Soulverse/Features/<Feature>/Presenter/
- Create: Soulverse/Features/<Feature>/Views/
- Create: Soulverse/Features/<Feature>/ViewModels/
- Verify: folders exist

#### Task 2: Define data models
- Create: Soulverse/Features/<Feature>/ViewModels/<Model>.swift
- Contents: [describe struct/class]
- Verify: builds without error

#### Task 3: Build the ViewModel
- Create: Soulverse/Features/<Feature>/ViewModels/<Feature>ViewModel.swift
- No UIKit imports
- Verify: logic works independently

#### Task 4: Build the View
- Create: Soulverse/Features/<Feature>/Views/<Feature>View.swift
- Use SnapKit for layout
- Theme-aware colors (.themeTextPrimary, etc.)
- NSLocalizedString for all text
- Verify: renders correctly

[... more tasks as needed ...]

#### Final Task: Integration
- Register in AppCoordinator if needed
- Add tab bar integration in MainViewController if needed
- Add analytics events
- Verify: full flow works end to end

### Soulverse Checklist
- [ ] Theme-aware colors only
- [ ] NSLocalizedString for all user-facing text
- [ ] [weak self] in escaping closures
- [ ] ViewModel has no UIKit imports
- [ ] SnapKit for layout
- [ ] Accessibility labels
- [ ] en + zh-TW localization strings

### HIG Checklist
- [ ] Touch targets ≥ 44pt
- [ ] Dynamic Type support
- [ ] Dark mode tested
- [ ] VoiceOver navigation makes sense
```

After outputting the plan, send a macOS notification:

```bash
osascript -e 'display notification "實作計畫已準備好，等待你的確認" with title "🛑 Soulverse New Feature" sound name "Glass"'
```

Then say exactly:
> **請確認這個實作計畫，我才會繼續。如果需要調整請告訴我。**

STOP and wait for explicit approval. Do not write code until approved.

---

## Phase 4: Create TODO.md Task — MANDATORY

**Immediately after user approves**, record the task in TODO.md for session recovery.

⚠️ **IMPORTANT**: Do NOT use `/pm add` — slash commands cannot be invoked from within a skill.
Instead, use the Edit or Bash tool to directly write to TODO.md.

### Steps:

1. Read the current `TODO.md` to understand its format
2. Add a new entry under "## In Progress":

```bash
# Append task to TODO.md
cat >> TODO.md << 'TASK'

### feat/<slug>: <1-line summary> [P1] [L]
- Status: in_progress
- Branch: feat/<slug>
- Worktree: ../soulverse-feature/
- Created: $(date +%Y-%m-%d)
TASK
```

3. Output this confirmation message — this line MUST appear in your response:
> **✅ 已寫入 TODO.md task（feat/<slug>）。開始實作...**

Then **immediately** proceed to Phase 5 — no need to wait for user input.

---

## Phase 5: Implementation (auto-continue)

**Skills used: `executing-plans` + `ios-developer` + `mobile-design`**

Follow the **executing-plans** pattern: work through the plan task by task.

Use the **Task tool** to spawn implementation sub-agents. For large features,
split into logical chunks and dispatch parallel sub-agents where tasks are independent:

### For each implementation chunk, provide this context:

```
Implement the following tasks for the Soulverse iOS project.

## Working Directory
<worktree-path>

## Project Context
- Architecture: VIPER-inspired (Presenter/Views/ViewModels)
- UI Framework: UIKit with SnapKit for layout
- Networking: Moya
- Dependencies: CocoaPods
- Build: xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse"

## Mandatory Rules (from CLAUDE.md)
- ALL UI colors must use theme-aware colors (.themeTextPrimary, .themeTextSecondary, etc.)
- NEVER use hardcoded colors like .black, .darkGray, .lightGray
- ALL user-facing strings must use NSLocalizedString()
- Add strings to both en.lproj/Localizable.strings and zh-TW.lproj/Localizable.strings
- Use descriptive keys with feature prefix
- ViewModels must have no UIKit imports
- Use [weak self] in escaping closures
- Use SnapKit for Auto Layout
- Follow existing code conventions in the feature module

## Tasks to Implement
<specific tasks from the plan>

## Acceptance Criteria
<from Phase 2>

After implementation, provide a summary of all files created/modified.
```

---

## Phase 6: Self-Review — MANDATORY OUTPUT

**Skills used: `requesting-code-review` + `verification-before-completion`**

⚠️ **This phase MUST produce visible output.** Do NOT skip it or merge it into Phase 7.

### 6a. Spawn review sub-agent

Use the **Task tool** to spawn a review sub-agent with this prompt:

```
Review the code changes in <worktree-path> for the "<feature-name>" feature.

Check against this plan:
<the approved plan>

## Review Checklist

### Plan Compliance
- [ ] Every task in the plan was implemented
- [ ] No tasks were skipped or half-done
- [ ] No leftover TODO/FIXME markers

### Soulverse Conventions
- [ ] ALL colors use theme-aware colors (.themeTextPrimary, .themeTextSecondary, etc.)
- [ ] NO hardcoded colors (.black, .darkGray, .lightGray)
- [ ] ALL user-facing strings use NSLocalizedString()
- [ ] Strings added to both en.lproj and zh-TW.lproj
- [ ] ViewModels have NO UIKit imports
- [ ] SnapKit used for all Auto Layout

### HIG Compliance
- [ ] Touch targets ≥ 44pt
- [ ] Dynamic Type support
- [ ] Dark mode tested
- [ ] VoiceOver labels present

### Code Quality
- [ ] [weak self] in all escaping closures
- [ ] Proper error handling with Result types
- [ ] Clean VIPER layer separation
- [ ] No retain cycles

Report ALL issues found. Be specific: file path, line number, what's wrong, how to fix.
If no issues found, explicitly state "No issues found."
```

### 6b. Show review results — MANDATORY

After the sub-agent returns, you MUST output the results in this format:

```
## 🔍 Self-Review Results

### Issues Found: <count>

1. **[file:line]** — <issue description>
   Fix: <how to fix>

2. **[file:line]** — <issue description>
   Fix: <how to fix>

(or "✅ No issues found — all checks passed.")

### Checklist Summary
- Plan compliance: ✅/❌
- Soulverse conventions: ✅/❌
- HIG compliance: ✅/❌
- Code quality: ✅/❌
```

> **📝 Self-review 完成。** <summary>

### 6c. Fix issues if any

If issues were found, spawn another implementation sub-agent to fix them.
After fixes, re-run the review sub-agent (max 2 review cycles).
Only proceed to Phase 7 when all checks pass.

---

## Phase 7: Regression Verification (auto-continue)

Use the **Task tool** to spawn the **regression-checker** agent:

```
You are working in directory: <worktree-path>

Run the full Soulverse verification pipeline.

Focus on changes in these files:
<list of files created/modified>
```

When complete, notify:

```bash
osascript -e 'display notification "Regression 驗證完成，請查看結果" with title "Soulverse New Feature" sound name "Glass"'
```

**READY FOR PR** → Phase 8.

**NEEDS FIXES** → Fix and re-verify (max 3 cycles).

---

## Phase 8: Pull Request + Complete /pm Task

### 8a. Commit

```bash
cd <worktree-path>
git add -A
git commit -m "$(cat <<'EOF'
feat: <short description>

<1-2 sentence summary of what was added>
EOF
)"
```

### 8b. Push & Create PR

```bash
git push -u origin "feat/<slug>"

gh pr create \
  --title "feat: <short description>" \
  --base main \
  --body "$(cat <<'EOF'
## Summary
<what this feature does and why>

## Changes
- `path/to/NewFile.swift` — <what it does>
- `path/to/ModifiedFile.swift` — <what changed>

## Screenshots / Demo
<if applicable>

## Acceptance Criteria
- [ ] <criterion from Phase 2>

## Regression Check
- Build: PASS
- Tests: <PASS/SKIPPED>
- Impact Analysis: <PASS/WARN>

## HIG Compliance
- Touch targets ≥ 44pt: ✅
- Dynamic Type: ✅
- Dark mode: ✅
- VoiceOver: ✅

---
🤖 Generated with Claude Code `/new-feature` workflow
EOF
)"
```

### 8c. Mark TODO.md Task Complete — MANDATORY

⚠️ **IMPORTANT**: Do NOT use `/pm done` or `/pm sync` — slash commands cannot be invoked from within a skill.
Instead, use the Edit tool to directly update TODO.md.

1. Read `TODO.md`
2. Find the `feat/<slug>` task entry
3. Change its status from `in_progress` to `completed`
4. Add completion date

```bash
# Example: use Edit tool to change the task status in TODO.md
# Change "- Status: in_progress" to "- Status: completed"
# Add "- Completed: $(date +%Y-%m-%d)"
```

5. Output this confirmation — MUST appear in your response:
> **✅ TODO.md task（feat/<slug>）已標記完成。**

### 8d. Report

```bash
osascript -e 'display notification "Feature 完成！PR 已建立。" with title "✅ Soulverse New Feature" sound name "Hero"'
```

Share:
- The PR URL
- Summary of what was built
- Any notes or follow-up items

---

## Session Recovery

If interrupted:
1. `TODO.md` task persists (written directly in Phase 4)
2. Worktree and feat/ branch persist on disk
3. New session → read `TODO.md` or run `/pm load` → see in-progress task → resume

---

## Error Handling

If any phase fails:
1. Tell user which phase failed and why
2. Options: retry, adjust, or abort
3. If aborting:
   ```bash
   cd "../soulverse-feature"
   git checkout main
   git branch -D "feat/<slug>"
   ```
   Update /pm task accordingly.

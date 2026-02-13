---
name: fix-bug
description: "Automated end-to-end bug fix workflow for the Soulverse iOS project. Creates a git worktree, sets up a fix/ branch (git-flow), analyzes the bug, plans and implements the fix, runs regression checks, and opens a PR. Integrates with /pm for persistent task tracking across sessions. Use whenever the user reports a bug, a crash, or something broken — e.g. 'fix this bug', 'there is a crash in...', 'this feature is broken', 'login screen freezes', or any issue that needs a code fix."
disable-model-invocation: true
argument-hint: "<bug description or GitHub issue number>"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Task
---

# Fix Bug — Soulverse Automated Bug Fix Workflow

The user triggered `/fix-bug` with: **$ARGUMENTS**

## Execution Rules

This workflow has 6 phases. Each phase has a completion condition.
You advance to the next phase ONLY after the current phase's condition is met.

**HARD GATES — you MUST stop at these points:**
- **Phase 3a**: Present plan → STOP → wait for user approval. No exceptions.
- **Phase 3b**: Write task to TODO.md → confirm task created. No exceptions.
- **Phase 6c**: Update TODO.md task to completed → confirm completed. No exceptions.

Why these gates exist: the user needs to review the plan before code changes, and TODO.md tasks provide crash recovery if the session is interrupted by network issues or API limits. Without these steps, progress is lost on disconnection.

⚠️ **IMPORTANT**: Do NOT use `/pm add`, `/pm done`, or `/pm sync` — slash commands cannot be invoked from within a skill. Use Edit/Bash tools to write directly to TODO.md instead.

Skipping any gate is a workflow violation — even if the fix is a one-line change.

```
Phase 1  Setup       → worktree + fix/ branch
Phase 2  Analysis    → understand the bug (interactive — ask questions if needed)
Phase 3a Plan        → present fix plan → 🛑 HARD GATE: wait for user approval
Phase 3b TODO.md     → write task to TODO.md (mandatory) ─┐
Phase 4  Implement   → delegate to sub-agent               │ auto-continue
Phase 5  Verify      → regression-checker agent             │ after plan
Phase 6  PR + TODO   → create PR + update TODO.md         ─┘ approval
```

---

## Phase 1: Worktree & Branch Setup

Generate a short kebab-case slug from the bug description (e.g. `login-crash`, `nil-pointer-feed`).

The project uses a **fixed worktree** (`../soulverse-fix/`) to avoid running `pod install` every time.
Each bug fix creates a new `fix/<slug>` branch inside this same worktree.

### 1a. Ensure the fixed worktree exists

```bash
# Check if the worktree already exists
if [ -d "../soulverse-fix" ]; then
  echo "Worktree exists"
else
  # First-time setup: create worktree from main and install pods
  git worktree add "../soulverse-fix" main
  cd "../soulverse-fix" && pod install
fi
```

### 1b. Clean up merged branches, sync main, and create the fix branch

```bash
cd "../soulverse-fix"

# Make sure the worktree is clean before starting
git status --porcelain
```

If there are uncommitted changes, ask the user what to do (stash, discard, or abort).

```bash
# Sync main into the worktree
git checkout main && git pull origin main

# Delete local fix/ branches that have already been merged into main
git branch --merged main | grep 'fix/' | xargs -r git branch -d
```

If any branches were deleted, briefly list them so the user knows.

```bash
# Create the fix branch
git checkout -b "fix/<slug>"
```

### 1c. Confirm to the user

- Worktree: `../soulverse-fix/`
- Branch: `fix/<slug>`
- Pods: already installed (shared across fixes)

**All subsequent commands must run inside `../soulverse-fix/`.**

---

## Phase 2: Bug Analysis

This phase is interactive. You stay in the main conversation so you can ask the user questions.

### 2a. Gather Context

1. **Error signals** — Search for crash messages, class names, function names mentioned in the bug:
   ```
   Grep for keywords from $ARGUMENTS across the Soulverse/ directory
   ```

2. **Related code** — The project follows VIPER. Identify which feature module is involved:
   ```
   Soulverse/Features/<FeatureName>/
     Presenter/
     Views/
     ViewModels/
   ```

3. **Recent changes** — Check git log for suspect files:
   ```bash
   git log --oneline -15 -- <suspect-files>
   ```

4. **Dependencies** — What services, protocols, or other features interact with this area?

### 2b. Clarify Unknowns

If anything is unclear, ask the user. Examples:
- "Can you describe the exact steps to reproduce?"
- "Does this happen on every launch or only in certain conditions?"
- "Are there crash logs from Firebase Crashlytics?"

Do **not** proceed to Phase 3 until you have a confident hypothesis.

---

## Phase 3a: Fix Plan — 🛑 HARD GATE

Present the plan below and then STOP. Do not proceed to Phase 3b or Phase 4.
Do not write any code. Do not spawn any sub-agents. Do not touch any files.
This gate applies regardless of how simple or obvious the fix appears.

Output the plan in this exact format, then end your message and wait:

```
## Bug Fix Plan

### Root Cause
[1-2 sentences explaining why the bug occurs]

### Fix Strategy
[High-level approach to fixing it]

### Files to Modify
1. `Soulverse/Features/<Feature>/Views/SomeView.swift` — [what and why]
2. `Soulverse/Features/<Feature>/Presenter/SomePresenter.swift` — [what and why]

### Soulverse Checklist
- [ ] Theme-aware colors only (no hardcoded .black, .darkGray)
- [ ] NSLocalizedString for all user-facing text
- [ ] [weak self] in escaping closures
- [ ] ViewModel has no UIKit imports
- [ ] SnapKit for layout constraints

### Risk Assessment
- Impact scope: [which features could be affected]
- Confidence: [high / medium / low]
```

After outputting the plan, send a macOS notification so the user knows to review:

```bash
osascript -e 'display notification "修復計畫已準備好，等待你的確認" with title "🛑 Soulverse Fix Bug" sound name "Glass"'
```

Then say exactly:
> **請確認這個修復計畫，我才會繼續。如果需要調整請告訴我。**

Then STOP and wait for the user's explicit approval (e.g. "ok", "go", "approved", "可以", "好").
If the user requests changes, revise and present again. Do not proceed until approved.

---

## Phase 3b: Write TODO.md Task — 🛑 MANDATORY EXECUTION

This step is NOT optional. Execute it immediately after receiving user approval.
Even for trivial bugs, the TODO.md task provides session recovery if anything breaks.

⚠️ Do NOT use `/pm add` — slash commands cannot be invoked from within a skill.
Use Edit or Bash tools to write directly to TODO.md.

### Steps:

1. Read the current `TODO.md` to understand its format
2. Add a new entry under "## In Progress":

```bash
# Append task to TODO.md
cat >> TODO.md << 'TASK'

### fix/<slug>: <1-line summary of the fix> [P1] [M]
- Status: in_progress
- Branch: fix/<slug>
- Worktree: ../soulverse-fix/
- Created: $(date +%Y-%m-%d)
TASK
```

3. Output this confirmation — this line MUST appear in your response:
> **✅ 已寫入 TODO.md task（fix/<slug>）。開始實作...**

Then **immediately** proceed to Phase 4 — no need to wait for user input.
The plan was already approved in Phase 3a. From here through Phase 6, run automatically.

---

## Phase 4: Implementation (auto-continue)

Use the **Task tool** to spawn a sub-agent for implementation. Provide full Soulverse context:

```
Implement the following bug fix in the Soulverse iOS project.

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
- Use descriptive keys with feature prefix (e.g. "mood_checkin_naming_title")
- ViewModels must have no UIKit imports
- Use [weak self] in escaping closures
- Use SnapKit for Auto Layout
- Follow existing code conventions in the feature module

## Bug Description
<original $ARGUMENTS>

## Root Cause
<from Phase 3>

## Fix Plan
<the approved plan with all file changes>

Implement this fix. After done, provide a summary of all changes.
```

When the sub-agent completes, review its summary. If it flagged concerns, inform the user.

---

## Phase 5: Regression Verification

Use the **Task tool** to spawn the **regression-checker** agent:

```
You are working in directory: <worktree-path>

Run the full Soulverse verification pipeline.

Focus on changes in these files:
<list of files modified in Phase 4>
```

### Handle Results

When regression check completes, notify the user:

```bash
osascript -e 'display notification "Regression 驗證完成，請查看結果" with title "Soulverse Fix Bug" sound name "Glass"'
```

**READY FOR PR** → Proceed to Phase 6.

**NEEDS FIXES** → Show the regression report to the user. Options:
- A: Spawn another implementation sub-agent to fix the issues
- B: User fixes manually
- C: Abort and clean up

If Option A, repeat Phase 4 → Phase 5 (max 3 cycles).

---

## Phase 6: Pull Request + Complete /pm Task

### 6a. Commit

```bash
cd <worktree-path>
git add -A
git commit -m "$(cat <<'EOF'
fix: <short description>

<root cause and what was fixed, 1-2 sentences>
EOF
)"
```

### 6b. Push & Create PR

```bash
git push -u origin "fix/<slug>"

gh pr create \
  --title "fix: <short description>" \
  --base main \
  --body "$(cat <<'EOF'
## Bug Description
<original bug description>

## Root Cause
<root cause from analysis>

## Fix
<summary of changes>

## Files Changed
- `path/to/File.swift` — <what changed>

## Regression Check
- Build: PASS
- Tests: <PASS/SKIPPED>
- Impact Analysis: <PASS/WARN>

## How to Verify
<steps to manually verify the fix>

---
🤖 Generated with Claude Code `/fix-bug` workflow
EOF
)"
```

### 6c. Mark TODO.md Task Complete — MANDATORY

This step is NOT optional.

⚠️ Do NOT use `/pm done` or `/pm sync` — slash commands cannot be invoked from within a skill.
Use the Edit tool to directly update TODO.md.

1. Read `TODO.md`
2. Find the `fix/<slug>` task entry
3. Change its status from `in_progress` to `completed`
4. Add completion date

5. Output this confirmation — MUST appear in your response:
> **✅ TODO.md task（fix/<slug>）已標記完成。**

### 6d. Report to User

Notify the user that the workflow is complete:

```bash
osascript -e 'display notification "Bug fix 完成！PR 已建立。" with title "✅ Soulverse Fix Bug" sound name "Hero"'
```

Share:
- The PR URL
- Summary of what was done
- Note: the worktree stays at `../soulverse-fix/` for reuse. The fix branch can be deleted after PR merge:
  ```bash
  git branch -d "fix/<slug>"
  ```

---

## Session Recovery

If the session is interrupted (network, API limit, etc.):

1. The `TODO.md` task persists (written directly in Phase 3b)
2. The worktree (`../soulverse-fix/`) and fix branch persist on disk
3. Pods are already installed — no setup needed
4. On a new session, the user can:
   - Read `TODO.md` or run `/pm load` to see the in-progress fix task
   - `cd ../soulverse-fix && git branch` to see the fix branch
   - Resume from whatever phase was interrupted
   - Or re-run `/fix-bug <same description>` — Phase 1 will detect the branch and pick up where it left off

---

## Error Handling

If any phase fails:
1. Tell the user which phase failed and why
2. Options: retry, adjust, or abort
3. If aborting, clean up the branch (worktree stays for reuse):
   ```bash
   cd "../soulverse-fix"
   git checkout main
   git branch -D "fix/<slug>"
   ```
   And update the /pm task:
   ```
   /pm done <task_id>
   ```
   (Mark as done with a note that it was aborted, or leave as pending for later)

---

## Important Reminders

- Always work inside the worktree, never the main repo
- Never force-push or modify the main branch
- User must approve the plan before implementation
- If `gh` CLI is not available, provide the command for the user to run
- Keep the user informed at each phase transition

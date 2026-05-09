# Onboarding Quest — Plan 1 of 7: Cloud Functions + Firestore Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the server-side foundation for the Onboarding Quest feature: Cloud Functions (Gen 2, TypeScript), Firestore data-model triggers, the survey schedule engine, the hourly notification cron, and tightened Security Rules. After this plan, mood check-in submissions will automatically increment `distinctCheckInDays` in `quest_state`, survey submissions will write derived fields, and the schedule engine will mark surveys as pending — all without iOS code.

**Architecture:** TypeScript Cloud Functions in a new `functions/` directory at the repo root. Four triggers (`onUserCreated`, `onMoodCheckInCreated`, `onSurveySubmissionCreated`) plus one scheduled cron (`questNotificationCron`). All Quest state lives in Firestore at `users/{uid}/quest_state` (single aggregate doc). Server-only writes for derived fields enforced via Security Rules.

**Tech Stack:** TypeScript, Firebase Functions v2 (Gen 2), Firebase Admin SDK, firebase-functions-test, @firebase/rules-unit-testing, Vitest, Firestore Emulator, Functions Emulator.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md`

---

## File structure

After this plan, the repo will have:

```
functions/
  package.json
  tsconfig.json
  .eslintrc.js
  vitest.config.ts
  src/
    index.ts                          # Exports all functions
    types.ts                          # TypeScript types for Firestore docs
    utils/
      dayKey.ts                       # Timezone-aware date bucketing
      tieBreaker.ts                   # Importance Check-In tie-breaker chain
    schedule/
      surveyTypes.ts                  # SurveyType enum
      eligibilityCondition.ts         # EligibilityCondition grammar + evaluator
      schedule.ts                     # SURVEY_SCHEDULE constant + MILESTONE_NOTIFICATIONS
      composer.ts                     # composePendingSurveys, surveyEligibleSinceMap
    triggers/
      onUserCreated.ts
      onMoodCheckInCreated.ts
      onSurveySubmissionCreated.ts
    cron/
      questNotificationCron.ts
  test/
    utils/dayKey.test.ts
    utils/tieBreaker.test.ts
    schedule/eligibilityCondition.test.ts
    schedule/composer.test.ts
    triggers/onUserCreated.test.ts
    triggers/onMoodCheckInCreated.test.ts
    triggers/onSurveySubmissionCreated.test.ts
    cron/questNotificationCron.test.ts
    rules/firestoreRules.test.ts
firebase.json                          # MODIFIED — add functions, emulators
firestore.rules                        # MODIFIED — add new collection rules
firestore.indexes.json                 # MODIFIED — add notificationHour index
```

The rest of the codebase (iOS app) is untouched in this plan.

---

## Pre-launch operational items (NOT TDD tasks)

These are infrastructure setup that humans must complete before functions can deploy. Track them as gates, not as engineering tasks:

- [ ] **Pre-launch 1:** Upgrade Firebase project `soulverse-35106` to **Blaze plan** (pay-as-you-go). Required for Cloud Functions deployment. Owner: project admin. Cost at MVP scale: $0–10/month.
- [ ] **Pre-launch 2:** Generate APNs auth key (`.p8`) in Apple Developer Portal. Capture key ID + team ID. Owner: iOS dev with Apple Developer access.
- [ ] **Pre-launch 3:** Upload APNs key to Firebase project: Project Settings → Cloud Messaging → Apple app configuration → APNs Authentication Key.

These three must complete before Task 27 (deploy). Tasks 1–26 can proceed locally against emulators.

---

## Task 1: Initialize `functions/` with TypeScript Gen 2

**Files:**
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/.eslintrc.js`
- Create: `functions/.gitignore`
- Create: `functions/vitest.config.ts`
- Create: `functions/src/index.ts`

- [ ] **Step 1: Initialize package.json**

```bash
mkdir -p functions/src functions/test
cd functions
```

Create `functions/package.json`:

```json
{
  "name": "soulverse-functions",
  "private": true,
  "engines": {
    "node": "20"
  },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "build:watch": "tsc --watch",
    "lint": "eslint --ext .js,.ts .",
    "test": "vitest run",
    "test:watch": "vitest",
    "serve": "npm run build && firebase emulators:start --only functions,firestore,auth",
    "shell": "npm run build && firebase functions:shell",
    "deploy": "firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "@firebase/rules-unit-testing": "^3.0.0",
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "eslint": "^8.0.0",
    "eslint-config-google": "^0.14.0",
    "firebase-functions-test": "^3.3.0",
    "typescript": "^5.4.0",
    "vitest": "^1.5.0"
  }
}
```

- [ ] **Step 2: Add tsconfig.json**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2020",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "test"]
}
```

- [ ] **Step 3: Add .eslintrc.js, .gitignore, and vitest.config.ts**

`functions/.eslintrc.js`:

```js
module.exports = {
  root: true,
  env: { es6: true, node: true },
  extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2020, sourceType: "module" },
  ignorePatterns: ["lib/", "node_modules/"],
  rules: {}
};
```

`functions/.gitignore`:

```
node_modules/
lib/
*.log
.env
```

`functions/vitest.config.ts`:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    testTimeout: 30000
  }
});
```

`functions/src/index.ts` (initial empty file — exports added in later tasks):

```ts
// All function exports go here.
// Each trigger / cron is exported by name and bundled by `tsc`.
```

- [ ] **Step 4: Install dependencies and verify build**

Run:

```bash
cd functions
npm install
npm run build
```

Expected: `lib/index.js` is created with no errors.

- [ ] **Step 5: Commit**

```bash
git add functions/
git commit -m "feat(functions): initialize Cloud Functions project with TypeScript Gen 2"
```

---

## Task 2: Configure firebase.json for functions and emulators

**Files:**
- Modify: `firebase.json`

- [ ] **Step 1: Update firebase.json to register functions and configure emulators**

Replace the contents of `firebase.json` with:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run lint",
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "emulators": {
    "auth":      { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "ui":        { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  }
}
```

- [ ] **Step 2: Verify the emulators start**

Run from repo root:

```bash
firebase emulators:start --only functions,firestore,auth
```

Expected: emulators start without error. Press Ctrl-C to stop.

- [ ] **Step 3: Commit**

```bash
git add firebase.json
git commit -m "chore(firebase): register functions codebase and emulator config"
```

---

## Task 3: Define TypeScript types for Firestore documents

**Files:**
- Create: `functions/src/types.ts`

- [ ] **Step 1: Write the types**

Create `functions/src/types.ts`:

```ts
import { Timestamp } from "firebase-admin/firestore";

/** Eight wellness dimensions. Identical to mood_checkins.topic enum values. */
export type WellnessDimension =
  | "physical"
  | "emotional"
  | "social"
  | "intellectual"
  | "spiritual"
  | "occupational"
  | "environmental"
  | "financial";

export const ALL_DIMENSIONS: WellnessDimension[] = [
  "physical", "emotional", "social", "intellectual",
  "spiritual", "occupational", "environmental", "financial"
];

export type SurveyType =
  | "importance_check_in"
  | "8dim"
  | "state_of_change"
  | "satisfaction_check_in";

/** Per-rule notification idempotency state. */
export interface NotificationStateEntry {
  lastSentAt: Timestamp | null;
}

/** Aggregate document at users/{uid}/quest_state. Source of truth for Quest UI. */
export interface QuestState {
  // Day counter & quest progression
  distinctCheckInDays: number;
  lastDistinctDayKey: string | null;     // "YYYY-MM-DD"
  questCompletedAt: Timestamp | null;    // set when distinctCheckInDays first reaches 21

  // Focus dimension & UX state
  focusDimension: WellnessDimension | null;
  focusDimensionAssignedAt: Timestamp | null;

  // Server-derived pending surveys
  pendingSurveys: SurveyType[];
  surveyEligibleSinceMap: Record<string, Timestamp>;

  // Survey submission timestamps
  importanceCheckInSubmittedAt: Timestamp | null;
  lastEightDimSubmittedAt: Timestamp | null;
  lastEightDimDimension: WellnessDimension | null;
  lastEightDimSummary: { stage: number; stageKey: string; messageKey: string } | null;
  lastStateOfChangeSubmittedAt: Timestamp | null;
  lastStateOfChangeStage: number | null;
  satisfactionCheckInSubmittedAt: Timestamp | null;
  lastSatisfactionTopCategory: WellnessDimension | null;
  lastSatisfactionLowestCategory: WellnessDimension | null;

  // Notification state (server-only writes)
  notification_state: Record<string, NotificationStateEntry>;

  // Cron query optimization
  notificationHour: number;              // 0-23, user-local 9am as UTC hour
  timezoneOffsetMinutes: number;
}

/** Mood check-in document (existing). Includes timezone offset stored at write time. */
export interface MoodCheckIn {
  colorHex: string;
  colorIntensity: number;
  emotion: string;
  topic: WellnessDimension;
  evaluation: string;
  createdAt: Timestamp;
  timezoneOffsetMinutes: number;
}

/** Discriminated union of survey submission payloads. */
export interface SurveyResponse {
  questionKey: string;
  questionText: string;
  value: number;
}

export interface ImportanceComputed {
  categoryMeans: Record<WellnessDimension, number>;
  topCategory: WellnessDimension;
  tieBreakerLevel: 1 | 2 | 3;
}

export interface EightDimComputed {
  totalScore: number;
  meanScore: number;
  stage: 1 | 2 | 3;
  stageKey: string;
  messageKey: string;
}

export interface StateOfChangeComputed {
  substageMeans: {
    precontemplation: number;
    contemplation: number;
    preparation: number;
    action: number;
    maintenance: number;
  };
  readinessIndex: number;
  stage: 1 | 2 | 3 | 4 | 5;
  stageKey: string;
  stageMessageKey: string;
}

export interface SatisfactionComputed {
  categoryMeans: Record<WellnessDimension, number>;
  topCategory: WellnessDimension;
  lowestCategory: WellnessDimension;
}

export interface SurveySubmission {
  submissionId: string;
  surveyType: SurveyType;
  submittedAt: Timestamp;
  appVersion: string;
  submittedFromQuestDay: number;
  payload:
    | { responses: SurveyResponse[]; computed: ImportanceComputed; }
    | { dimension: WellnessDimension; responses: SurveyResponse[]; computed: EightDimComputed; }
    | { dimension: WellnessDimension; responses: SurveyResponse[]; computed: StateOfChangeComputed; }
    | { responses: SurveyResponse[]; computed: SatisfactionComputed; };
}
```

- [ ] **Step 2: Verify the types compile**

Run:

```bash
cd functions && npm run build
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add functions/src/types.ts
git commit -m "feat(functions): define TypeScript types for Quest Firestore documents"
```

---

## Task 4: Day-key utility (timezone-aware date bucketing)

**Files:**
- Create: `functions/src/utils/dayKey.ts`
- Create: `functions/test/utils/dayKey.test.ts`

This utility computes `YYYY-MM-DD` from a `createdAt` timestamp using the *record's stored* `timezoneOffsetMinutes`. Day boundaries are in the user's local time at write time, not UTC and not the current device's timezone.

- [ ] **Step 1: Write the failing test**

Create `functions/test/utils/dayKey.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { computeDayKey } from "../../src/utils/dayKey";

describe("computeDayKey", () => {
  it("buckets a UTC+0 record by its UTC date", () => {
    // 2026-04-29 23:30 UTC, offset 0
    const ts = Timestamp.fromDate(new Date("2026-04-29T23:30:00Z"));
    expect(computeDayKey(ts, 0)).toBe("2026-04-29");
  });

  it("buckets a UTC+8 record by local date (Asia/Taipei)", () => {
    // 2026-04-29 23:30 UTC = 2026-04-30 07:30 in UTC+8
    const ts = Timestamp.fromDate(new Date("2026-04-29T23:30:00Z"));
    expect(computeDayKey(ts, 8 * 60)).toBe("2026-04-30");
  });

  it("buckets a UTC-7 record by local date (US/Pacific)", () => {
    // 2026-04-30 02:00 UTC = 2026-04-29 19:00 in UTC-7
    const ts = Timestamp.fromDate(new Date("2026-04-30T02:00:00Z"));
    expect(computeDayKey(ts, -7 * 60)).toBe("2026-04-29");
  });

  it("handles cross-date-line travel: same UTC timestamp, different offsets", () => {
    const ts = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));
    expect(computeDayKey(ts, 8 * 60)).toBe("2026-05-01");   // UTC+8: 8am, May 1
    expect(computeDayKey(ts, -8 * 60)).toBe("2026-04-30");  // UTC-8: 4pm, Apr 30
  });

  it("zero-pads months and days", () => {
    const ts = Timestamp.fromDate(new Date("2026-01-05T12:00:00Z"));
    expect(computeDayKey(ts, 0)).toBe("2026-01-05");
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/utils/dayKey.test.ts
```

Expected: FAIL with "Cannot find module '../../src/utils/dayKey'".

- [ ] **Step 3: Implement the utility**

Create `functions/src/utils/dayKey.ts`:

```ts
import { Timestamp } from "firebase-admin/firestore";

/**
 * Compute the YYYY-MM-DD day key in the local timezone defined by the offset.
 * Uses the *record's stored* offset, not the current device offset.
 *
 * @param ts Firestore Timestamp from the record's createdAt
 * @param timezoneOffsetMinutes minutes east of UTC (positive = east, e.g. UTC+8 = 480)
 */
export function computeDayKey(ts: Timestamp, timezoneOffsetMinutes: number): string {
  const utcMs = ts.toMillis();
  const localMs = utcMs + timezoneOffsetMinutes * 60_000;
  const localDate = new Date(localMs);

  const yyyy = localDate.getUTCFullYear();
  const mm = String(localDate.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(localDate.getUTCDate()).padStart(2, "0");

  return `${yyyy}-${mm}-${dd}`;
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
cd functions && npm test -- test/utils/dayKey.test.ts
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/utils/dayKey.ts functions/test/utils/dayKey.test.ts
git commit -m "feat(functions): add timezone-aware day-key utility for mood check-in bucketing"
```

---

## Task 5: SurveyType enum and EligibilityCondition grammar

**Files:**
- Create: `functions/src/schedule/surveyTypes.ts`
- Create: `functions/src/schedule/eligibilityCondition.ts`
- Create: `functions/test/schedule/eligibilityCondition.test.ts`

The grammar models the survey schedule's predicates. An `EligibilityCondition` evaluates to a boolean given a `QuestState`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/schedule/eligibilityCondition.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { evaluateCondition, EligibilityCondition } from "../../src/schedule/eligibilityCondition";
import { QuestState } from "../../src/types";

const baseState = (overrides: Partial<QuestState> = {}): QuestState => ({
  distinctCheckInDays: 0,
  lastDistinctDayKey: null,
  questCompletedAt: null,
  focusDimension: null,
  focusDimensionAssignedAt: null,
  pendingSurveys: [],
  surveyEligibleSinceMap: {},
  importanceCheckInSubmittedAt: null,
  lastEightDimSubmittedAt: null,
  lastEightDimDimension: null,
  lastEightDimSummary: null,
  lastStateOfChangeSubmittedAt: null,
  lastStateOfChangeStage: null,
  satisfactionCheckInSubmittedAt: null,
  lastSatisfactionTopCategory: null,
  lastSatisfactionLowestCategory: null,
  notification_state: {},
  notificationHour: 1,
  timezoneOffsetMinutes: 480,
  ...overrides
});

const nowMs = () => Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));

describe("evaluateCondition", () => {
  it("distinctCheckInDays threshold: false when below", () => {
    const cond: EligibilityCondition = { type: "distinctCheckInDays", threshold: 7 };
    expect(evaluateCondition(cond, baseState({ distinctCheckInDays: 6 }), nowMs())).toBe(false);
  });

  it("distinctCheckInDays threshold: true when at threshold", () => {
    const cond: EligibilityCondition = { type: "distinctCheckInDays", threshold: 7 };
    expect(evaluateCondition(cond, baseState({ distinctCheckInDays: 7 }), nowMs())).toBe(true);
  });

  it("distinctCheckInDays threshold: true when above", () => {
    const cond: EligibilityCondition = { type: "distinctCheckInDays", threshold: 7 };
    expect(evaluateCondition(cond, baseState({ distinctCheckInDays: 21 }), nowMs())).toBe(true);
  });

  it("focusDimensionAssigned: false when null", () => {
    const cond: EligibilityCondition = { type: "focusDimensionAssigned" };
    expect(evaluateCondition(cond, baseState(), nowMs())).toBe(false);
  });

  it("focusDimensionAssigned: true when non-null", () => {
    const cond: EligibilityCondition = { type: "focusDimensionAssigned" };
    expect(evaluateCondition(cond, baseState({ focusDimension: "emotional" }), nowMs())).toBe(true);
  });

  it("daysSinceQuestComplete: false when not completed", () => {
    const cond: EligibilityCondition = { type: "daysSinceQuestComplete", days: 90 };
    expect(evaluateCondition(cond, baseState(), nowMs())).toBe(false);
  });

  it("daysSinceQuestComplete: false when not enough days passed", () => {
    const completedAt = Timestamp.fromDate(new Date("2026-04-15T00:00:00Z"));
    const cond: EligibilityCondition = { type: "daysSinceQuestComplete", days: 90 };
    // now is 2026-05-01, completed 2026-04-15 → only 16 days
    expect(evaluateCondition(cond, baseState({ questCompletedAt: completedAt }), nowMs())).toBe(false);
  });

  it("daysSinceQuestComplete: true when enough days passed", () => {
    const completedAt = Timestamp.fromDate(new Date("2025-12-01T00:00:00Z"));
    const cond: EligibilityCondition = { type: "daysSinceQuestComplete", days: 90 };
    expect(evaluateCondition(cond, baseState({ questCompletedAt: completedAt }), nowMs())).toBe(true);
  });

  it("daysSinceLastSubmission: false when no prior submission", () => {
    const cond: EligibilityCondition = {
      type: "daysSinceLastSubmission",
      days: 30,
      surveyType: "8dim"
    };
    expect(evaluateCondition(cond, baseState(), nowMs())).toBe(false);
  });

  it("daysSinceLastSubmission: 8dim — true when ≥30 days since lastEightDimSubmittedAt", () => {
    const last = Timestamp.fromDate(new Date("2026-03-01T00:00:00Z"));
    const cond: EligibilityCondition = {
      type: "daysSinceLastSubmission",
      days: 30,
      surveyType: "8dim"
    };
    expect(evaluateCondition(cond, baseState({ lastEightDimSubmittedAt: last }), nowMs())).toBe(true);
  });

  it("allOf: true when all conditions true", () => {
    const cond: EligibilityCondition = {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 7 },
        { type: "focusDimensionAssigned" }
      ]
    };
    const state = baseState({ distinctCheckInDays: 10, focusDimension: "emotional" });
    expect(evaluateCondition(cond, state, nowMs())).toBe(true);
  });

  it("allOf: false when any condition false", () => {
    const cond: EligibilityCondition = {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 7 },
        { type: "focusDimensionAssigned" }
      ]
    };
    const state = baseState({ distinctCheckInDays: 10, focusDimension: null });
    expect(evaluateCondition(cond, state, nowMs())).toBe(false);
  });

  it("oneOf: true when any condition true", () => {
    const cond: EligibilityCondition = {
      type: "oneOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 100 },
        { type: "focusDimensionAssigned" }
      ]
    };
    const state = baseState({ distinctCheckInDays: 10, focusDimension: "emotional" });
    expect(evaluateCondition(cond, state, nowMs())).toBe(true);
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/schedule/eligibilityCondition.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the SurveyType enum**

Create `functions/src/schedule/surveyTypes.ts`:

```ts
import { SurveyType } from "../types";

/** All survey types in MVP. Order matters only for fallback iteration. */
export const ALL_SURVEY_TYPES: SurveyType[] = [
  "importance_check_in",
  "8dim",
  "state_of_change",
  "satisfaction_check_in"
];
```

- [ ] **Step 4: Implement the EligibilityCondition grammar and evaluator**

Create `functions/src/schedule/eligibilityCondition.ts`:

```ts
import { Timestamp } from "firebase-admin/firestore";
import { QuestState, SurveyType } from "../types";

export type EligibilityCondition =
  | { type: "distinctCheckInDays"; threshold: number }
  | { type: "daysSinceQuestComplete"; days: number }
  | { type: "daysSinceLastSubmission"; days: number; surveyType: SurveyType }
  | { type: "focusDimensionAssigned" }
  | { type: "allOf"; conditions: EligibilityCondition[] }
  | { type: "oneOf"; conditions: EligibilityCondition[] };

const MS_PER_DAY = 24 * 60 * 60 * 1000;

function lastSubmittedAtFor(state: QuestState, surveyType: SurveyType): Timestamp | null {
  switch (surveyType) {
    case "importance_check_in":   return state.importanceCheckInSubmittedAt;
    case "8dim":                  return state.lastEightDimSubmittedAt;
    case "state_of_change":       return state.lastStateOfChangeSubmittedAt;
    case "satisfaction_check_in": return state.satisfactionCheckInSubmittedAt;
  }
}

export function evaluateCondition(
  cond: EligibilityCondition,
  state: QuestState,
  now: Timestamp
): boolean {
  switch (cond.type) {
    case "distinctCheckInDays":
      return state.distinctCheckInDays >= cond.threshold;

    case "focusDimensionAssigned":
      return state.focusDimension !== null;

    case "daysSinceQuestComplete":
      if (!state.questCompletedAt) return false;
      const elapsedSinceComplete =
        (now.toMillis() - state.questCompletedAt.toMillis()) / MS_PER_DAY;
      return elapsedSinceComplete >= cond.days;

    case "daysSinceLastSubmission":
      const last = lastSubmittedAtFor(state, cond.surveyType);
      if (!last) return false;
      const elapsedSinceLast = (now.toMillis() - last.toMillis()) / MS_PER_DAY;
      return elapsedSinceLast >= cond.days;

    case "allOf":
      return cond.conditions.every(c => evaluateCondition(c, state, now));

    case "oneOf":
      return cond.conditions.some(c => evaluateCondition(c, state, now));
  }
}
```

- [ ] **Step 5: Run the test and verify it passes**

```bash
cd functions && npm test -- test/schedule/eligibilityCondition.test.ts
```

Expected: all 12 tests pass.

- [ ] **Step 6: Commit**

```bash
git add functions/src/schedule/ functions/test/schedule/eligibilityCondition.test.ts
git commit -m "feat(functions): add SurveyType enum and EligibilityCondition grammar"
```

---

## Task 6: SURVEY_SCHEDULE constant + MILESTONE_NOTIFICATIONS

**Files:**
- Create: `functions/src/schedule/schedule.ts`

This task locks in the MVP schedule per the design doc §8.

- [ ] **Step 1: Write the schedule constants**

Create `functions/src/schedule/schedule.ts`:

```ts
import { SurveyType } from "../types";
import { EligibilityCondition } from "./eligibilityCondition";

export interface SurveyScheduleEntry {
  surveyType: SurveyType;
  firstAvailable: EligibilityCondition;
  reTakeCadence?: EligibilityCondition;
  notification: { titleKey: string; bodyKey: string };
  recentResultWindowDays: number;
  pickFocusDimensionFromResult?: boolean;
}

export interface MilestoneNotification {
  notificationKey: string;
  predicate: EligibilityCondition;
  titleKey: string;
  bodyKey: string;
}

export const SURVEY_SCHEDULE: SurveyScheduleEntry[] = [
  // Importance Check-In: Day 7 first, every 7 months thereafter
  {
    surveyType: "importance_check_in",
    firstAvailable: { type: "distinctCheckInDays", threshold: 7 },
    reTakeCadence:  { type: "daysSinceLastSubmission", days: 210, surveyType: "importance_check_in" },
    notification: {
      titleKey: "quest_notification_importance_title",
      bodyKey:  "quest_notification_importance_body"
    },
    recentResultWindowDays: 7,
    pickFocusDimensionFromResult: true
  },
  // 8-Dim: gated by focus assignment, monthly re-take
  {
    surveyType: "8dim",
    firstAvailable: {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 7 },
        { type: "focusDimensionAssigned" }
      ]
    },
    reTakeCadence: { type: "daysSinceLastSubmission", days: 30, surveyType: "8dim" },
    notification: {
      titleKey: "quest_notification_8dim_title",
      bodyKey:  "quest_notification_8dim_body"
    },
    recentResultWindowDays: 7
  },
  // State-of-Change: Day 21 + focus, quarterly re-take
  {
    surveyType: "state_of_change",
    firstAvailable: {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 21 },
        { type: "focusDimensionAssigned" }
      ]
    },
    reTakeCadence: { type: "daysSinceLastSubmission", days: 90, surveyType: "state_of_change" },
    notification: {
      titleKey: "quest_notification_soc_title",
      bodyKey:  "quest_notification_soc_body"
    },
    recentResultWindowDays: 7
  },
  // Satisfaction: 90 days post-Quest-complete, every 6 months
  {
    surveyType: "satisfaction_check_in",
    firstAvailable: { type: "daysSinceQuestComplete", days: 90 },
    reTakeCadence:  { type: "daysSinceLastSubmission", days: 180, surveyType: "satisfaction_check_in" },
    notification: {
      titleKey: "quest_notification_satisfaction_title",
      bodyKey:  "quest_notification_satisfaction_body"
    },
    recentResultWindowDays: 7
  }
];

export const MILESTONE_NOTIFICATIONS: MilestoneNotification[] = [
  {
    notificationKey: "MilestoneDay14",
    predicate: { type: "distinctCheckInDays", threshold: 14 },
    titleKey: "quest_notification_milestone_day14_title",
    bodyKey:  "quest_notification_milestone_day14_body"
  },
  {
    notificationKey: "MilestoneDay21",
    predicate: { type: "distinctCheckInDays", threshold: 21 },
    titleKey: "quest_notification_milestone_day21_title",
    bodyKey:  "quest_notification_milestone_day21_body"
  }
];
```

- [ ] **Step 2: Verify the build**

```bash
cd functions && npm run build
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add functions/src/schedule/schedule.ts
git commit -m "feat(functions): define MVP survey schedule and milestone notifications"
```

---

## Task 7: composePendingSurveys + surveyEligibleSinceMap

**Files:**
- Create: `functions/src/schedule/composer.ts`
- Create: `functions/test/schedule/composer.test.ts`

Given a `QuestState`, returns the list of currently-pending surveys plus the map of when each became eligible (for client-side deck ordering).

- [ ] **Step 1: Write the failing test**

Create `functions/test/schedule/composer.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { composePendingSurveys } from "../../src/schedule/composer";
import { QuestState } from "../../src/types";

const baseState = (overrides: Partial<QuestState> = {}): QuestState => ({
  distinctCheckInDays: 0,
  lastDistinctDayKey: null,
  questCompletedAt: null,
  focusDimension: null,
  focusDimensionAssignedAt: null,
  pendingSurveys: [],
  surveyEligibleSinceMap: {},
  importanceCheckInSubmittedAt: null,
  lastEightDimSubmittedAt: null,
  lastEightDimDimension: null,
  lastEightDimSummary: null,
  lastStateOfChangeSubmittedAt: null,
  lastStateOfChangeStage: null,
  satisfactionCheckInSubmittedAt: null,
  lastSatisfactionTopCategory: null,
  lastSatisfactionLowestCategory: null,
  notification_state: {},
  notificationHour: 1,
  timezoneOffsetMinutes: 480,
  ...overrides
});

const now = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));

describe("composePendingSurveys", () => {
  it("returns empty when distinctCheckInDays < 7", () => {
    const result = composePendingSurveys(baseState({ distinctCheckInDays: 5 }), now);
    expect(result.pendingSurveys).toEqual([]);
  });

  it("returns importance_check_in when day 7 first reached and not submitted", () => {
    const result = composePendingSurveys(baseState({ distinctCheckInDays: 7 }), now);
    expect(result.pendingSurveys).toEqual(["importance_check_in"]);
  });

  it("returns 8dim only after Importance is submitted (focus assigned)", () => {
    const state = baseState({
      distinctCheckInDays: 8,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-29T00:00:00Z"))
    });
    const result = composePendingSurveys(state, now);
    expect(result.pendingSurveys).toEqual(["8dim"]);
  });

  it("returns state_of_change at day 21 with focus assigned and not yet submitted", () => {
    const state = baseState({
      distinctCheckInDays: 21,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-15T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-04-20T00:00:00Z"))
    });
    const result = composePendingSurveys(state, now);
    expect(result.pendingSurveys).toContain("state_of_change");
  });

  it("does NOT return 8dim when its result is fresh (within 30-day re-take cadence)", () => {
    const state = baseState({
      distinctCheckInDays: 22,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-15T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-04-25T00:00:00Z"))   // 6 days ago
    });
    const result = composePendingSurveys(state, now);
    expect(result.pendingSurveys).not.toContain("8dim");
  });

  it("returns 8dim re-take when ≥30 days since last submission", () => {
    const state = baseState({
      distinctCheckInDays: 30,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-03-01T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-03-15T00:00:00Z")),  // 47 days ago
      questCompletedAt: Timestamp.fromDate(new Date("2026-03-20T00:00:00Z"))
    });
    const result = composePendingSurveys(state, now);
    expect(result.pendingSurveys).toContain("8dim");
  });

  it("populates surveyEligibleSinceMap for all pending entries", () => {
    const result = composePendingSurveys(baseState({ distinctCheckInDays: 7 }), now);
    expect(result.surveyEligibleSinceMap["importance_check_in"]).toBeDefined();
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/schedule/composer.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the composer**

Create `functions/src/schedule/composer.ts`:

```ts
import { Timestamp } from "firebase-admin/firestore";
import { QuestState, SurveyType } from "../types";
import { SURVEY_SCHEDULE } from "./schedule";
import { evaluateCondition } from "./eligibilityCondition";

function hasSubmissionFor(state: QuestState, surveyType: SurveyType): boolean {
  switch (surveyType) {
    case "importance_check_in":   return state.importanceCheckInSubmittedAt !== null;
    case "8dim":                  return state.lastEightDimSubmittedAt !== null;
    case "state_of_change":       return state.lastStateOfChangeSubmittedAt !== null;
    case "satisfaction_check_in": return state.satisfactionCheckInSubmittedAt !== null;
  }
}

export interface PendingComposition {
  pendingSurveys: SurveyType[];
  surveyEligibleSinceMap: Record<string, Timestamp>;
}

/**
 * Returns the list of currently-pending surveys for the given user state, plus a map
 * of when each became eligible (used by the client to order the deck-of-cards by
 * oldest-pending-first).
 */
export function composePendingSurveys(state: QuestState, now: Timestamp): PendingComposition {
  const pending: SurveyType[] = [];
  const eligibleSinceMap: Record<string, Timestamp> = {};

  for (const entry of SURVEY_SCHEDULE) {
    const submitted = hasSubmissionFor(state, entry.surveyType);

    if (!submitted) {
      // First-time pending check
      if (evaluateCondition(entry.firstAvailable, state, now)) {
        pending.push(entry.surveyType);
        eligibleSinceMap[entry.surveyType] = now;   // approximation for first-time
      }
    } else if (entry.reTakeCadence) {
      // Re-take pending check
      if (evaluateCondition(entry.reTakeCadence, state, now)) {
        pending.push(entry.surveyType);
        eligibleSinceMap[entry.surveyType] = now;
      }
    }
  }

  return { pendingSurveys: pending, surveyEligibleSinceMap: eligibleSinceMap };
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
cd functions && npm test -- test/schedule/composer.test.ts
```

Expected: all 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/schedule/composer.ts functions/test/schedule/composer.test.ts
git commit -m "feat(functions): implement composePendingSurveys for server-derived pending state"
```

---

## Task 8: Importance Check-In tie-breaker chain

**Files:**
- Create: `functions/src/utils/tieBreaker.ts`
- Create: `functions/test/utils/tieBreaker.test.ts`

The tie-breaker chain (per spec §6.4): primary = highest mean; secondary = mood-check-in topic count; tertiary = predetermined order.

- [ ] **Step 1: Write the failing test**

Create `functions/test/utils/tieBreaker.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { pickFocusDimension } from "../../src/utils/tieBreaker";
import { WellnessDimension } from "../../src/types";

describe("pickFocusDimension", () => {
  it("returns the unique highest-mean category (level 1)", () => {
    const means = {
      physical: 3.0, emotional: 4.5, social: 3.5, intellectual: 3.0,
      spiritual: 2.5, occupational: 4.0, environmental: 3.0, financial: 3.5
    };
    const moodCounts: Record<WellnessDimension, number> = {
      physical: 0, emotional: 0, social: 0, intellectual: 0,
      spiritual: 0, occupational: 0, environmental: 0, financial: 0
    };
    const result = pickFocusDimension(means, moodCounts);
    expect(result.dimension).toBe("emotional");
    expect(result.tieBreakerLevel).toBe(1);
  });

  it("uses mood-check-in topic count when means tie (level 2)", () => {
    const means = {
      physical: 4.0, emotional: 4.0, social: 3.0, intellectual: 3.0,
      spiritual: 3.0, occupational: 3.0, environmental: 3.0, financial: 3.0
    };
    const moodCounts: Record<WellnessDimension, number> = {
      physical: 2, emotional: 5, social: 0, intellectual: 0,
      spiritual: 0, occupational: 0, environmental: 0, financial: 0
    };
    const result = pickFocusDimension(means, moodCounts);
    expect(result.dimension).toBe("emotional");
    expect(result.tieBreakerLevel).toBe(2);
  });

  it("falls back to predetermined order when means and counts tie (level 3)", () => {
    const means = {
      physical: 4.0, emotional: 4.0, social: 4.0, intellectual: 3.0,
      spiritual: 3.0, occupational: 3.0, environmental: 3.0, financial: 3.0
    };
    const moodCounts: Record<WellnessDimension, number> = {
      physical: 0, emotional: 0, social: 0, intellectual: 0,
      spiritual: 0, occupational: 0, environmental: 0, financial: 0
    };
    const result = pickFocusDimension(means, moodCounts);
    // Predetermined order: physical → emotional → social → ...
    expect(result.dimension).toBe("physical");
    expect(result.tieBreakerLevel).toBe(3);
  });

  it("level 2 only chooses among the means-tied set", () => {
    // Even though 'physical' has a higher mood count, it's not tied for the top mean
    const means = {
      physical: 3.0, emotional: 4.0, social: 4.0, intellectual: 3.0,
      spiritual: 3.0, occupational: 3.0, environmental: 3.0, financial: 3.0
    };
    const moodCounts: Record<WellnessDimension, number> = {
      physical: 99, emotional: 1, social: 5, intellectual: 0,
      spiritual: 0, occupational: 0, environmental: 0, financial: 0
    };
    const result = pickFocusDimension(means, moodCounts);
    expect(result.dimension).toBe("social");      // tied means; higher mood count among tied
    expect(result.tieBreakerLevel).toBe(2);
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/utils/tieBreaker.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the tie-breaker**

Create `functions/src/utils/tieBreaker.ts`:

```ts
import { ALL_DIMENSIONS, WellnessDimension } from "../types";

export interface FocusPickResult {
  dimension: WellnessDimension;
  tieBreakerLevel: 1 | 2 | 3;
}

/** Predetermined order used as the level-3 tie-breaker (matches wellness doc). */
const PRIORITY_ORDER: WellnessDimension[] = [
  "physical", "emotional", "social", "intellectual",
  "spiritual", "occupational", "environmental", "financial"
];

export function pickFocusDimension(
  categoryMeans: Record<WellnessDimension, number>,
  moodTopicCounts: Record<WellnessDimension, number>
): FocusPickResult {
  // Level 1: unique highest mean
  const maxMean = Math.max(...ALL_DIMENSIONS.map(d => categoryMeans[d]));
  const tiedAtMax = ALL_DIMENSIONS.filter(d => categoryMeans[d] === maxMean);

  if (tiedAtMax.length === 1) {
    return { dimension: tiedAtMax[0], tieBreakerLevel: 1 };
  }

  // Level 2: among tied, the one with highest mood-check-in topic count
  const maxCount = Math.max(...tiedAtMax.map(d => moodTopicCounts[d]));
  const tiedAtCount = tiedAtMax.filter(d => moodTopicCounts[d] === maxCount);

  if (tiedAtCount.length === 1) {
    return { dimension: tiedAtCount[0], tieBreakerLevel: 2 };
  }

  // Level 3: predetermined order
  for (const d of PRIORITY_ORDER) {
    if (tiedAtCount.includes(d)) {
      return { dimension: d, tieBreakerLevel: 3 };
    }
  }

  // Unreachable (tiedAtCount is non-empty subset of ALL_DIMENSIONS)
  throw new Error("pickFocusDimension: unreachable fallback");
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
cd functions && npm test -- test/utils/tieBreaker.test.ts
```

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/utils/tieBreaker.ts functions/test/utils/tieBreaker.test.ts
git commit -m "feat(functions): implement Importance Check-In focus-dimension tie-breaker chain"
```

---

## Task 9: `onUserCreated` trigger — initialize quest_state

**Files:**
- Create: `functions/src/triggers/onUserCreated.ts`
- Create: `functions/test/triggers/onUserCreated.test.ts`
- Modify: `functions/src/index.ts`

When a new user authenticates for the first time, initialize their `quest_state` doc with all defaults. Triggered by Firestore `onCreate` on `users/{uid}` (we use Firestore-side trigger because the existing app creates the user doc on first auth, and Firebase Auth's `onCreate` is gen-1 only).

- [ ] **Step 1: Write the failing test**

Create `functions/test/triggers/onUserCreated.test.ts`:

```ts
import { beforeAll, afterAll, describe, it, expect } from "vitest";
import { initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { setDoc, doc, getDoc } from "firebase/firestore";

// We test the function logic by calling it directly with a fake event.
import { initializeQuestState } from "../../src/triggers/onUserCreated";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-test",
    firestore: { host: "localhost", port: 8080 }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe("initializeQuestState", () => {
  it("creates quest_state with default values", async () => {
    const adminFirestore = testEnv.unauthenticatedContext().firestore();
    const uid = "test-user-1";

    await initializeQuestState(uid, adminFirestore as any);

    const snap = await getDoc(doc(adminFirestore, `users/${uid}/quest_state/state`));
    const data = snap.data()!;
    expect(data.distinctCheckInDays).toBe(0);
    expect(data.focusDimension).toBe(null);
    expect(data.pendingSurveys).toEqual([]);
    expect(data.notificationHour).toBeGreaterThanOrEqual(0);
    expect(data.notificationHour).toBeLessThan(24);
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

Make sure Firestore Emulator is running:

```bash
firebase emulators:start --only firestore
```

In another terminal:

```bash
cd functions && npm test -- test/triggers/onUserCreated.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the trigger**

Create `functions/src/triggers/onUserCreated.ts`:

```ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { QuestState } from "../types";

if (getApps().length === 0) initializeApp();

/**
 * Compute the UTC hour at which the user's local time is 09:00.
 * Defaults to UTC+0 if offset is unknown (some users may not have set it yet).
 */
export function deriveNotificationHour(timezoneOffsetMinutes: number): number {
  // Local 9am = UTC (9 - offsetHours)
  const offsetHours = timezoneOffsetMinutes / 60;
  return ((9 - offsetHours) % 24 + 24) % 24;
}

export async function initializeQuestState(
  uid: string,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);
  const exists = (await ref.get()).exists;
  if (exists) return;   // idempotent: do not overwrite

  const defaultOffset = 0;   // updated by client at app launch
  const initialState: Partial<QuestState> = {
    distinctCheckInDays: 0,
    lastDistinctDayKey: null,
    questCompletedAt: null,
    focusDimension: null,
    focusDimensionAssignedAt: null,
    pendingSurveys: [],
    surveyEligibleSinceMap: {},
    importanceCheckInSubmittedAt: null,
    lastEightDimSubmittedAt: null,
    lastEightDimDimension: null,
    lastEightDimSummary: null,
    lastStateOfChangeSubmittedAt: null,
    lastStateOfChangeStage: null,
    satisfactionCheckInSubmittedAt: null,
    lastSatisfactionTopCategory: null,
    lastSatisfactionLowestCategory: null,
    notification_state: {},
    notificationHour: deriveNotificationHour(defaultOffset),
    timezoneOffsetMinutes: defaultOffset
  };

  await ref.set(initialState);
}

export const onUserCreated = onDocumentCreated(
  "users/{uid}",
  async event => {
    const uid = event.params.uid;
    await initializeQuestState(uid, getFirestore());
  }
);
```

- [ ] **Step 4: Wire into index.ts**

Modify `functions/src/index.ts`:

```ts
export { onUserCreated } from "./triggers/onUserCreated";
```

- [ ] **Step 5: Run the test and verify it passes**

```bash
cd functions && npm test -- test/triggers/onUserCreated.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add functions/src/triggers/onUserCreated.ts functions/test/triggers/onUserCreated.test.ts functions/src/index.ts
git commit -m "feat(functions): add onUserCreated trigger to initialize quest_state"
```

---

## Task 10: `onMoodCheckInCreated` trigger — increment day counter

**Files:**
- Create: `functions/src/triggers/onMoodCheckInCreated.ts`
- Create: `functions/test/triggers/onMoodCheckInCreated.test.ts`
- Modify: `functions/src/index.ts`

Triggers on `users/{uid}/mood_checkins/{id}` create. Computes `dayKey` from the record's stored `timezoneOffsetMinutes`. If new dayKey, atomically bumps `distinctCheckInDays`. If count just hit 21, sets `questCompletedAt`. Does NOT yet recompute pendingSurveys (Task 11).

- [ ] **Step 1: Write the failing test**

Create `functions/test/triggers/onMoodCheckInCreated.test.ts`:

```ts
import { beforeAll, afterAll, describe, it, expect, beforeEach } from "vitest";
import { initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase-admin/firestore";
import { processMoodCheckIn } from "../../src/triggers/onMoodCheckInCreated";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-test",
    firestore: { host: "localhost", port: 8080 }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("processMoodCheckIn", () => {
  const uid = "test-user-2";

  async function seedQuestState(db: any, partial: any = {}) {
    await db.doc(`users/${uid}/quest_state/state`).set({
      distinctCheckInDays: 0,
      lastDistinctDayKey: null,
      questCompletedAt: null,
      focusDimension: null,
      focusDimensionAssignedAt: null,
      pendingSurveys: [],
      surveyEligibleSinceMap: {},
      importanceCheckInSubmittedAt: null,
      lastEightDimSubmittedAt: null,
      lastEightDimDimension: null,
      lastEightDimSummary: null,
      lastStateOfChangeSubmittedAt: null,
      lastStateOfChangeStage: null,
      satisfactionCheckInSubmittedAt: null,
      lastSatisfactionTopCategory: null,
      lastSatisfactionLowestCategory: null,
      notification_state: {},
      notificationHour: 1,
      timezoneOffsetMinutes: 480,
      ...partial
    });
  }

  it("increments distinctCheckInDays on first check-in", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db);

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-04-29T10:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(1);
    expect(snap.data().lastDistinctDayKey).toBe("2026-04-29");
  });

  it("does NOT increment for a same-day second check-in", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, { distinctCheckInDays: 1, lastDistinctDayKey: "2026-04-29" });

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-04-29T18:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(1);
  });

  it("increments for a new day", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, { distinctCheckInDays: 1, lastDistinctDayKey: "2026-04-29" });

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-04-30T18:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(2);
    expect(snap.data().lastDistinctDayKey).toBe("2026-04-30");
  });

  it("sets questCompletedAt when reaching day 21", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, { distinctCheckInDays: 20, lastDistinctDayKey: "2026-05-19" });

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-05-20T05:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(21);
    expect(snap.data().questCompletedAt).toBeDefined();
    expect(snap.data().questCompletedAt).not.toBeNull();
  });

  it("does NOT change questCompletedAt on day 22+", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    const previouslyCompletedAt = Timestamp.fromDate(new Date("2026-05-20T05:00:00Z"));
    await seedQuestState(db, {
      distinctCheckInDays: 21,
      lastDistinctDayKey: "2026-05-20",
      questCompletedAt: previouslyCompletedAt
    });

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-05-21T05:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(22);
    expect(snap.data().questCompletedAt.toMillis()).toBe(previouslyCompletedAt.toMillis());
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/triggers/onMoodCheckInCreated.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the trigger**

Create `functions/src/triggers/onMoodCheckInCreated.ts`:

```ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { computeDayKey } from "../utils/dayKey";
import { MoodCheckIn } from "../types";

export async function processMoodCheckIn(
  uid: string,
  checkin: MoodCheckIn,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      // Defensive: if quest_state doesn't exist yet (shouldn't happen post-onUserCreated),
      // skip silently. The next mood check-in after init will catch up.
      return;
    }
    const state = snap.data()!;
    const dayKey = computeDayKey(checkin.createdAt, checkin.timezoneOffsetMinutes);

    if (dayKey === state.lastDistinctDayKey) {
      return;   // same-day repeat — no change
    }

    const newCount = (state.distinctCheckInDays as number) + 1;
    const updates: Record<string, unknown> = {
      distinctCheckInDays: newCount,
      lastDistinctDayKey: dayKey
    };

    if (newCount === 21 && state.questCompletedAt === null) {
      updates.questCompletedAt = FieldValue.serverTimestamp();
    }

    tx.update(ref, updates);
  });
}

export const onMoodCheckInCreated = onDocumentCreated(
  "users/{uid}/mood_checkins/{id}",
  async event => {
    const uid = event.params.uid;
    const checkin = event.data?.data() as MoodCheckIn | undefined;
    if (!checkin) return;
    await processMoodCheckIn(uid, checkin, getFirestore());
  }
);
```

- [ ] **Step 4: Wire into index.ts**

Modify `functions/src/index.ts`:

```ts
export { onUserCreated } from "./triggers/onUserCreated";
export { onMoodCheckInCreated } from "./triggers/onMoodCheckInCreated";
```

- [ ] **Step 5: Run the test and verify it passes**

```bash
cd functions && npm test -- test/triggers/onMoodCheckInCreated.test.ts
```

Expected: all 5 tests pass.

- [ ] **Step 6: Commit**

```bash
git add functions/src/triggers/onMoodCheckInCreated.ts functions/test/triggers/onMoodCheckInCreated.test.ts functions/src/index.ts
git commit -m "feat(functions): add onMoodCheckInCreated trigger for distinct-day counter and quest completion timestamp"
```

---

## Task 11: Wire `composePendingSurveys` into mood-check-in trigger

**Files:**
- Modify: `functions/src/triggers/onMoodCheckInCreated.ts`
- Modify: `functions/test/triggers/onMoodCheckInCreated.test.ts`

After incrementing the day counter, recompute `pendingSurveys` and `surveyEligibleSinceMap` and write them atomically in the same transaction.

- [ ] **Step 1: Add a failing test**

Append to `functions/test/triggers/onMoodCheckInCreated.test.ts`:

```ts
  it("populates pendingSurveys with importance_check_in when day 7 is reached", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, { distinctCheckInDays: 6, lastDistinctDayKey: "2026-04-28" });

    await processMoodCheckIn(uid, {
      createdAt: Timestamp.fromDate(new Date("2026-04-29T05:00:00Z")),
      timezoneOffsetMinutes: 8 * 60
    } as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(7);
    expect(snap.data().pendingSurveys).toEqual(["importance_check_in"]);
    expect(snap.data().surveyEligibleSinceMap["importance_check_in"]).toBeDefined();
  });
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/triggers/onMoodCheckInCreated.test.ts
```

Expected: the new test FAILS (`pendingSurveys` is still `[]`).

- [ ] **Step 3: Update the trigger**

Modify `functions/src/triggers/onMoodCheckInCreated.ts`. Replace the body of `processMoodCheckIn` with:

```ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { computeDayKey } from "../utils/dayKey";
import { MoodCheckIn, QuestState } from "../types";
import { composePendingSurveys } from "../schedule/composer";

export async function processMoodCheckIn(
  uid: string,
  checkin: MoodCheckIn,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const state = snap.data() as QuestState;
    const dayKey = computeDayKey(checkin.createdAt, checkin.timezoneOffsetMinutes);

    if (dayKey === state.lastDistinctDayKey) return;

    const newCount = state.distinctCheckInDays + 1;
    const now = Timestamp.now();

    // Build updated state for re-composing pending surveys
    const updatedState: QuestState = {
      ...state,
      distinctCheckInDays: newCount,
      lastDistinctDayKey: dayKey,
      questCompletedAt: (newCount === 21 && state.questCompletedAt === null)
        ? now
        : state.questCompletedAt
    };

    const composition = composePendingSurveys(updatedState, now);

    const updates: Record<string, unknown> = {
      distinctCheckInDays: newCount,
      lastDistinctDayKey: dayKey,
      pendingSurveys: composition.pendingSurveys,
      surveyEligibleSinceMap: composition.surveyEligibleSinceMap
    };

    if (newCount === 21 && state.questCompletedAt === null) {
      updates.questCompletedAt = FieldValue.serverTimestamp();
    }

    tx.update(ref, updates);
  });
}

export const onMoodCheckInCreated = onDocumentCreated(
  "users/{uid}/mood_checkins/{id}",
  async event => {
    const uid = event.params.uid;
    const checkin = event.data?.data() as MoodCheckIn | undefined;
    if (!checkin) return;
    await processMoodCheckIn(uid, checkin, getFirestore());
  }
);
```

- [ ] **Step 4: Run all mood-check-in tests**

```bash
cd functions && npm test -- test/triggers/onMoodCheckInCreated.test.ts
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/triggers/onMoodCheckInCreated.ts functions/test/triggers/onMoodCheckInCreated.test.ts
git commit -m "feat(functions): recompute pendingSurveys after distinct-day increment"
```

---

## Task 12: `onSurveySubmissionCreated` — Importance handler with focus assignment

**Files:**
- Create: `functions/src/triggers/onSurveySubmissionCreated.ts`
- Create: `functions/test/triggers/onSurveySubmissionCreated.test.ts`
- Modify: `functions/src/index.ts`

The trigger fans out by `surveyType`. The Importance handler picks the focus dimension via the tie-breaker chain (Task 8) and writes it to `quest_state.focusDimension`. After all handlers, `pendingSurveys` is recomputed. This task implements the Importance handler only; the other three handlers come in Task 13.

- [ ] **Step 1: Write the failing test**

Create `functions/test/triggers/onSurveySubmissionCreated.test.ts`:

```ts
import { beforeAll, afterAll, beforeEach, describe, it, expect } from "vitest";
import { initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase-admin/firestore";
import { processSurveySubmission } from "../../src/triggers/onSurveySubmissionCreated";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-test",
    firestore: { host: "localhost", port: 8080 }
  });
});

afterAll(async () => { await testEnv.cleanup(); });
beforeEach(async () => { await testEnv.clearFirestore(); });

const uid = "test-user-3";

async function seedQuestState(db: any, partial: any = {}) {
  await db.doc(`users/${uid}/quest_state/state`).set({
    distinctCheckInDays: 7,
    lastDistinctDayKey: "2026-04-29",
    questCompletedAt: null,
    focusDimension: null,
    focusDimensionAssignedAt: null,
    pendingSurveys: ["importance_check_in"],
    surveyEligibleSinceMap: {},
    importanceCheckInSubmittedAt: null,
    lastEightDimSubmittedAt: null,
    lastEightDimDimension: null,
    lastEightDimSummary: null,
    lastStateOfChangeSubmittedAt: null,
    lastStateOfChangeStage: null,
    satisfactionCheckInSubmittedAt: null,
    lastSatisfactionTopCategory: null,
    lastSatisfactionLowestCategory: null,
    notification_state: {},
    notificationHour: 1,
    timezoneOffsetMinutes: 480,
    ...partial
  });
}

describe("processSurveySubmission — Importance Check-In", () => {
  it("writes focusDimension based on top category", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db);

    const submission = {
      submissionId: "sub1",
      surveyType: "importance_check_in",
      submittedAt: Timestamp.now(),
      appVersion: "1.0.0",
      submittedFromQuestDay: 7,
      payload: {
        responses: [],
        computed: {
          categoryMeans: {
            physical: 3.0, emotional: 4.5, social: 3.5, intellectual: 3.0,
            spiritual: 2.5, occupational: 4.0, environmental: 3.0, financial: 3.5
          },
          topCategory: "emotional",
          tieBreakerLevel: 1
        }
      }
    };

    await processSurveySubmission(uid, submission as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().focusDimension).toBe("emotional");
    expect(snap.data().importanceCheckInSubmittedAt).toBeDefined();
    // Importance is no longer pending; 8-Dim becomes pending
    expect(snap.data().pendingSurveys).toContain("8dim");
    expect(snap.data().pendingSurveys).not.toContain("importance_check_in");
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/triggers/onSurveySubmissionCreated.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the dispatcher and Importance handler**

Create `functions/src/triggers/onSurveySubmissionCreated.ts`:

```ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { QuestState, SurveySubmission, ImportanceComputed } from "../types";
import { composePendingSurveys } from "../schedule/composer";

export async function processSurveySubmission(
  uid: string,
  submission: SurveySubmission,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const state = snap.data() as QuestState;
    const now = Timestamp.now();

    const baseUpdates = handleSurveySpecific(submission, state, now);
    const updatedState: QuestState = { ...state, ...baseUpdates };

    const composition = composePendingSurveys(updatedState, now);

    tx.update(ref, {
      ...baseUpdates,
      pendingSurveys: composition.pendingSurveys,
      surveyEligibleSinceMap: composition.surveyEligibleSinceMap
    });
  });
}

function handleSurveySpecific(
  submission: SurveySubmission,
  state: QuestState,
  now: Timestamp
): Partial<QuestState> {
  switch (submission.surveyType) {
    case "importance_check_in": {
      const computed = (submission.payload as { computed: ImportanceComputed }).computed;
      return {
        focusDimension: state.focusDimension ?? computed.topCategory,
        focusDimensionAssignedAt: state.focusDimensionAssignedAt ?? now,
        importanceCheckInSubmittedAt: now
      };
    }
    // Other survey types added in Task 13
    default:
      return {};
  }
}

export const onSurveySubmissionCreated = onDocumentCreated(
  "users/{uid}/survey_submissions/{id}",
  async event => {
    const uid = event.params.uid;
    const submission = event.data?.data() as SurveySubmission | undefined;
    if (!submission) return;
    await processSurveySubmission(uid, submission, getFirestore());
  }
);
```

- [ ] **Step 4: Wire into index.ts**

Modify `functions/src/index.ts`:

```ts
export { onUserCreated } from "./triggers/onUserCreated";
export { onMoodCheckInCreated } from "./triggers/onMoodCheckInCreated";
export { onSurveySubmissionCreated } from "./triggers/onSurveySubmissionCreated";
```

- [ ] **Step 5: Run the test and verify it passes**

```bash
cd functions && npm test -- test/triggers/onSurveySubmissionCreated.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add functions/src/triggers/onSurveySubmissionCreated.ts functions/test/triggers/onSurveySubmissionCreated.test.ts functions/src/index.ts
git commit -m "feat(functions): handle Importance Check-In submission with focus-dimension assignment"
```

---

## Task 13: Other survey-type handlers (8-Dim, State-of-Change, Satisfaction)

**Files:**
- Modify: `functions/src/triggers/onSurveySubmissionCreated.ts`
- Modify: `functions/test/triggers/onSurveySubmissionCreated.test.ts`

- [ ] **Step 1: Add failing tests**

Append to `functions/test/triggers/onSurveySubmissionCreated.test.ts`:

```ts
describe("processSurveySubmission — 8-Dim", () => {
  it("writes lastEightDim* fields", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, { focusDimension: "emotional", importanceCheckInSubmittedAt: Timestamp.now() });

    const submission = {
      submissionId: "sub2",
      surveyType: "8dim",
      submittedAt: Timestamp.now(),
      appVersion: "1.0.0",
      submittedFromQuestDay: 8,
      payload: {
        dimension: "emotional",
        responses: [],
        computed: {
          totalScore: 37,
          meanScore: 3.7,
          stage: 2,
          stageKey: "quest_stage_8dim_emotional_2_label",
          messageKey: "quest_stage_8dim_emotional_2_message"
        }
      }
    };

    await processSurveySubmission(uid, submission as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().lastEightDimSubmittedAt).toBeDefined();
    expect(snap.data().lastEightDimDimension).toBe("emotional");
    expect(snap.data().lastEightDimSummary.stage).toBe(2);
  });
});

describe("processSurveySubmission — State-of-Change", () => {
  it("writes lastStateOfChange* fields", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, {
      distinctCheckInDays: 21,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.now(),
      lastEightDimSubmittedAt: Timestamp.now(),
      questCompletedAt: Timestamp.now()
    });

    const submission = {
      submissionId: "sub3",
      surveyType: "state_of_change",
      submittedAt: Timestamp.now(),
      appVersion: "1.0.0",
      submittedFromQuestDay: 21,
      payload: {
        dimension: "emotional",
        responses: [],
        computed: {
          substageMeans: {
            precontemplation: 2.33, contemplation: 3.67,
            preparation: 4.00, action: 3.33, maintenance: 3.00
          },
          readinessIndex: 16.32,
          stage: 3,
          stageKey: "quest_stage_soc_3_label",
          stageMessageKey: "quest_stage_soc_3_message"
        }
      }
    };

    await processSurveySubmission(uid, submission as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().lastStateOfChangeSubmittedAt).toBeDefined();
    expect(snap.data().lastStateOfChangeStage).toBe(3);
  });
});

describe("processSurveySubmission — Satisfaction", () => {
  it("writes lastSatisfaction* fields", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedQuestState(db, {
      distinctCheckInDays: 30,
      focusDimension: "emotional",
      questCompletedAt: Timestamp.fromDate(new Date("2025-01-01T00:00:00Z"))
    });

    const submission = {
      submissionId: "sub4",
      surveyType: "satisfaction_check_in",
      submittedAt: Timestamp.now(),
      appVersion: "1.0.0",
      submittedFromQuestDay: 100,
      payload: {
        responses: [],
        computed: {
          categoryMeans: {
            physical: 4.0, emotional: 3.0, social: 3.5, intellectual: 3.0,
            spiritual: 2.5, occupational: 2.0, environmental: 3.5, financial: 3.0
          },
          topCategory: "physical",
          lowestCategory: "occupational"
        }
      }
    };

    await processSurveySubmission(uid, submission as any, db);

    const snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().satisfactionCheckInSubmittedAt).toBeDefined();
    expect(snap.data().lastSatisfactionTopCategory).toBe("physical");
    expect(snap.data().lastSatisfactionLowestCategory).toBe("occupational");
  });
});
```

- [ ] **Step 2: Run the tests and verify the new ones fail**

```bash
cd functions && npm test -- test/triggers/onSurveySubmissionCreated.test.ts
```

Expected: 3 new tests FAIL (existing fields stay null).

- [ ] **Step 3: Extend `handleSurveySpecific`**

Modify `functions/src/triggers/onSurveySubmissionCreated.ts`. Replace `handleSurveySpecific` with:

```ts
import {
  QuestState, SurveySubmission, ImportanceComputed,
  EightDimComputed, StateOfChangeComputed, SatisfactionComputed,
  WellnessDimension
} from "../types";

function handleSurveySpecific(
  submission: SurveySubmission,
  state: QuestState,
  now: Timestamp
): Partial<QuestState> {
  switch (submission.surveyType) {
    case "importance_check_in": {
      const computed = (submission.payload as { computed: ImportanceComputed }).computed;
      return {
        focusDimension: state.focusDimension ?? computed.topCategory,
        focusDimensionAssignedAt: state.focusDimensionAssignedAt ?? now,
        importanceCheckInSubmittedAt: now
      };
    }

    case "8dim": {
      const payload = submission.payload as {
        dimension: WellnessDimension;
        computed: EightDimComputed;
      };
      return {
        lastEightDimSubmittedAt: now,
        lastEightDimDimension: payload.dimension,
        lastEightDimSummary: {
          stage: payload.computed.stage,
          stageKey: payload.computed.stageKey,
          messageKey: payload.computed.messageKey
        }
      };
    }

    case "state_of_change": {
      const computed = (submission.payload as { computed: StateOfChangeComputed }).computed;
      return {
        lastStateOfChangeSubmittedAt: now,
        lastStateOfChangeStage: computed.stage
      };
    }

    case "satisfaction_check_in": {
      const computed = (submission.payload as { computed: SatisfactionComputed }).computed;
      return {
        satisfactionCheckInSubmittedAt: now,
        lastSatisfactionTopCategory: computed.topCategory,
        lastSatisfactionLowestCategory: computed.lowestCategory
      };
    }
  }
}
```

- [ ] **Step 4: Run all tests and verify they pass**

```bash
cd functions && npm test -- test/triggers/onSurveySubmissionCreated.test.ts
```

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/triggers/onSurveySubmissionCreated.ts functions/test/triggers/onSurveySubmissionCreated.test.ts
git commit -m "feat(functions): handle 8-Dim, State-of-Change, and Satisfaction submissions"
```

---

## Task 14: Add `notificationHour` index

**Files:**
- Modify: `firestore.indexes.json`

The hourly cron query is `collectionGroup('quest_state').where('notificationHour', '==', X)`. Requires a single-field index.

- [ ] **Step 1: Update firestore.indexes.json**

Replace the file's contents with:

```json
{
  "indexes": [
    {
      "collectionGroup": "drawings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "checkinId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "quest_state",
      "fieldPath": "notificationHour",
      "indexes": [
        { "queryScope": "COLLECTION_GROUP", "order": "ASCENDING" }
      ]
    }
  ]
}
```

- [ ] **Step 2: Validate by deploying to emulator**

```bash
firebase emulators:start --only firestore
# Stop with Ctrl-C after seeing "indexes loaded"
```

Expected: emulator starts cleanly. The index will be applied when deployed (`firebase deploy --only firestore:indexes`) in Task 27.

- [ ] **Step 3: Commit**

```bash
git add firestore.indexes.json
git commit -m "chore(firestore): add single-field index on quest_state.notificationHour for cron query"
```

---

## Task 15: `questNotificationCron` — hourly schedule + per-user query

**Files:**
- Create: `functions/src/cron/questNotificationCron.ts`
- Create: `functions/test/cron/questNotificationCron.test.ts`
- Modify: `functions/src/index.ts`

Hourly cron iterates users matching `notificationHour == currentUTCHour`. For each user, evaluates the schedule + milestone notifications and dispatches FCM. This task wires the cron skeleton; FCM dispatch comes in Task 16; idempotency comes in Task 17.

- [ ] **Step 1: Write the failing test**

Create `functions/test/cron/questNotificationCron.test.ts`:

```ts
import { beforeAll, afterAll, beforeEach, describe, it, expect } from "vitest";
import { initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase-admin/firestore";
import { findUsersToNotify } from "../../src/cron/questNotificationCron";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-test",
    firestore: { host: "localhost", port: 8080 }
  });
});

afterAll(async () => { await testEnv.cleanup(); });
beforeEach(async () => { await testEnv.clearFirestore(); });

async function seedUser(db: any, uid: string, partial: any = {}) {
  await db.doc(`users/${uid}/quest_state/state`).set({
    distinctCheckInDays: 0,
    lastDistinctDayKey: null,
    questCompletedAt: null,
    focusDimension: null,
    focusDimensionAssignedAt: null,
    pendingSurveys: [],
    surveyEligibleSinceMap: {},
    importanceCheckInSubmittedAt: null,
    lastEightDimSubmittedAt: null,
    lastEightDimDimension: null,
    lastEightDimSummary: null,
    lastStateOfChangeSubmittedAt: null,
    lastStateOfChangeStage: null,
    satisfactionCheckInSubmittedAt: null,
    lastSatisfactionTopCategory: null,
    lastSatisfactionLowestCategory: null,
    notification_state: {},
    notificationHour: 1,
    timezoneOffsetMinutes: 480,
    ...partial
  });
}

describe("findUsersToNotify", () => {
  it("returns users matching the given UTC hour", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedUser(db, "u1", { notificationHour: 1 });
    await seedUser(db, "u2", { notificationHour: 14 });
    await seedUser(db, "u3", { notificationHour: 1 });

    const matched = await findUsersToNotify(db, 1);
    const uids = matched.map(m => m.uid).sort();
    expect(uids).toEqual(["u1", "u3"]);
  });

  it("returns empty when no users match", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;
    await seedUser(db, "u1", { notificationHour: 5 });

    const matched = await findUsersToNotify(db, 12);
    expect(matched).toEqual([]);
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
cd functions && npm test -- test/cron/questNotificationCron.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement the cron skeleton**

Create `functions/src/cron/questNotificationCron.ts`:

```ts
import { onSchedule } from "firebase-functions/v2/scheduler";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { QuestState } from "../types";

export interface NotifyCandidate {
  uid: string;
  state: QuestState;
}

export async function findUsersToNotify(
  db: Firestore,
  utcHour: number
): Promise<NotifyCandidate[]> {
  const querySnap = await db.collectionGroup("quest_state")
    .where("notificationHour", "==", utcHour)
    .get();

  return querySnap.docs.map(doc => {
    // doc.ref.path = "users/{uid}/quest_state/state"
    const segments = doc.ref.path.split("/");
    const uid = segments[1];
    return { uid, state: doc.data() as QuestState };
  });
}

export const questNotificationCron = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Etc/UTC",
    memory: "256MiB",
    timeoutSeconds: 540
  },
  async () => {
    const utcHour = new Date().getUTCHours();
    const candidates = await findUsersToNotify(getFirestore(), utcHour);
    // Per-user dispatch implemented in Task 16.
    console.log(`[questNotificationCron] hour=${utcHour}, candidates=${candidates.length}`);
  }
);
```

- [ ] **Step 4: Wire into index.ts**

Modify `functions/src/index.ts`:

```ts
export { onUserCreated } from "./triggers/onUserCreated";
export { onMoodCheckInCreated } from "./triggers/onMoodCheckInCreated";
export { onSurveySubmissionCreated } from "./triggers/onSurveySubmissionCreated";
export { questNotificationCron } from "./cron/questNotificationCron";
```

- [ ] **Step 5: Run the test and verify it passes**

```bash
cd functions && npm test -- test/cron/questNotificationCron.test.ts
```

Expected: 2 tests pass.

- [ ] **Step 6: Commit**

```bash
git add functions/src/cron/questNotificationCron.ts functions/test/cron/questNotificationCron.test.ts functions/src/index.ts
git commit -m "feat(functions): hourly cron skeleton for notification dispatch with notificationHour query"
```

---

## Task 16: Cron — per-user rule evaluation and FCM dispatch

**Files:**
- Modify: `functions/src/cron/questNotificationCron.ts`
- Modify: `functions/test/cron/questNotificationCron.test.ts`

Adds the per-user rule loop. For each candidate user, computes which notifications should fire (survey-driven from `pendingSurveys` + milestone). Writes idempotency state BEFORE calling FCM (per spec §7.1: prefer rare miss over double-send). FCM dispatch is mocked in tests.

- [ ] **Step 1: Add a failing test**

Append to `functions/test/cron/questNotificationCron.test.ts`:

```ts
import { computePushesToFire } from "../../src/cron/questNotificationCron";

describe("computePushesToFire", () => {
  it("fires a survey-driven push when survey is pending and not yet sent", () => {
    const state: any = {
      distinctCheckInDays: 7,
      pendingSurveys: ["importance_check_in"],
      notification_state: {},
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("importance_check_in_first");
  });

  it("does not fire when already sent for this eligibility window", () => {
    const state: any = {
      distinctCheckInDays: 7,
      pendingSurveys: ["importance_check_in"],
      notification_state: {
        importance_check_in_first: { lastSentAt: Timestamp.now() }
      },
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("importance_check_in_first");
  });

  it("fires milestone push at day 14", () => {
    const state: any = {
      distinctCheckInDays: 14,
      pendingSurveys: [],
      notification_state: {},
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("MilestoneDay14");
  });

  it("doesn't fire MilestoneDay14 if already sent", () => {
    const state: any = {
      distinctCheckInDays: 14,
      pendingSurveys: [],
      notification_state: {
        MilestoneDay14: { lastSentAt: Timestamp.now() }
      },
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("MilestoneDay14");
  });

  it("fires retake notification on a NEW retake window after a prior submission+notification", () => {
    // Multi-cycle retake case: user has submitted 8-Dim once and got the first retake notification,
    // then submitted again (entering a new retake window). 30 days later the next retake is due.
    const oldNotifyAt = Timestamp.fromDate(new Date("2026-04-01T00:00:00Z"));
    const recentSubmitAt = Timestamp.fromDate(new Date("2026-04-15T00:00:00Z"));
    const state: any = {
      distinctCheckInDays: 60,
      pendingSurveys: ["8dim"],
      lastEightDimSubmittedAt: recentSubmitAt,
      notification_state: {
        "8dim_retake": { lastSentAt: oldNotifyAt }    // older than the most recent submission
      },
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("8dim_retake");
  });

  it("does NOT fire retake notification within the same retake window (lastSentAt is after lastSubmittedAt)", () => {
    const submitAt = Timestamp.fromDate(new Date("2026-04-01T00:00:00Z"));
    const recentNotifyAt = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));
    const state: any = {
      distinctCheckInDays: 60,
      pendingSurveys: ["8dim"],
      lastEightDimSubmittedAt: submitAt,
      notification_state: {
        "8dim_retake": { lastSentAt: recentNotifyAt }   // newer than last submission — same window
      },
      notificationHour: 1
    };
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("8dim_retake");
  });
});
```

- [ ] **Step 2: Run the tests and verify the new ones fail**

```bash
cd functions && npm test -- test/cron/questNotificationCron.test.ts
```

Expected: 4 new tests FAIL (function not exported).

- [ ] **Step 3: Implement `computePushesToFire`**

Modify `functions/src/cron/questNotificationCron.ts`. Append:

```ts
import { SURVEY_SCHEDULE, MILESTONE_NOTIFICATIONS } from "../schedule/schedule";
import { evaluateCondition } from "../schedule/eligibilityCondition";

export interface PushToFire {
  notificationKey: string;
  titleKey: string;
  bodyKey: string;
}

function lastSubmittedField(surveyType: string): keyof QuestState | null {
  switch (surveyType) {
    case "importance_check_in":   return "importanceCheckInSubmittedAt";
    case "8dim":                  return "lastEightDimSubmittedAt";
    case "state_of_change":       return "lastStateOfChangeSubmittedAt";
    case "satisfaction_check_in": return "satisfactionCheckInSubmittedAt";
    default: return null;
  }
}

/**
 * Decide whether a notification should fire for the current eligibility window.
 *
 * Rules:
 *   - "_first" key:   fire iff lastSentAt is null. Never re-fire.
 *   - "_retake" key:  fire iff lastSentAt is null OR lastSubmittedAt > lastSentAt.
 *                     The latter means the user submitted since we last notified —
 *                     they're now in a new retake window.
 *   - milestone-only: fire iff lastSentAt is null. Never re-fire.
 *   - Self-correction guard: ignore lastSentAt > now (clock skew) and re-fire.
 */
function shouldFire(
  notificationKey: string,
  state: QuestState,
  surveyType: string | null,
  now: Timestamp
): boolean {
  const sent = state.notification_state?.[notificationKey];
  if (!sent || !sent.lastSentAt) return true;

  // Clock-skew guard
  if (sent.lastSentAt.toMillis() > now.toMillis()) return true;

  if (notificationKey.endsWith("_retake") && surveyType) {
    const submittedField = lastSubmittedField(surveyType);
    if (!submittedField) return false;
    const lastSubmittedAt = (state as any)[submittedField] as Timestamp | null;
    if (!lastSubmittedAt) return false;
    return lastSubmittedAt.toMillis() > sent.lastSentAt.toMillis();
  }

  // "_first" and milestones — never re-fire after the first send.
  return false;
}

export function computePushesToFire(state: QuestState): PushToFire[] {
  const result: PushToFire[] = [];
  const now = Timestamp.now();

  // Survey-driven pushes
  for (const surveyType of state.pendingSurveys) {
    const entry = SURVEY_SCHEDULE.find(e => e.surveyType === surveyType);
    if (!entry) continue;

    const submittedField = lastSubmittedField(surveyType);
    const isFirstTime = !submittedField || (state as any)[submittedField] === null;
    const notificationKey = `${surveyType}_${isFirstTime ? "first" : "retake"}`;

    if (!shouldFire(notificationKey, state, surveyType, now)) continue;

    result.push({
      notificationKey,
      titleKey: entry.notification.titleKey,
      bodyKey:  entry.notification.bodyKey
    });
  }

  // Milestone-only pushes
  for (const milestone of MILESTONE_NOTIFICATIONS) {
    if (!evaluateCondition(milestone.predicate, state, now)) continue;
    if (!shouldFire(milestone.notificationKey, state, null, now)) continue;

    result.push({
      notificationKey: milestone.notificationKey,
      titleKey: milestone.titleKey,
      bodyKey:  milestone.bodyKey
    });
  }

  return result;
}
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
cd functions && npm test -- test/cron/questNotificationCron.test.ts
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/cron/questNotificationCron.ts functions/test/cron/questNotificationCron.test.ts
git commit -m "feat(functions): compute pending pushes per user from pendingSurveys + milestone rules"
```

---

## Task 17: Cron — FCM dispatch with write-before-send idempotency

**Files:**
- Modify: `functions/src/cron/questNotificationCron.ts`

Implements the actual FCM call and the idempotency rule from spec §7.1: write `notification_state.{key}.lastSentAt = serverTimestamp()` BEFORE calling `getMessaging().send(...)`.

- [ ] **Step 1: Update the cron to dispatch**

Modify `functions/src/cron/questNotificationCron.ts`. Replace the `questNotificationCron` export at the bottom with:

```ts
import { getMessaging } from "firebase-admin/messaging";
import { FieldValue } from "firebase-admin/firestore";

async function dispatchPushesForUser(
  uid: string,
  state: QuestState,
  pushes: PushToFire[],
  db: Firestore
): Promise<void> {
  if (pushes.length === 0) return;

  // Find the user's devices
  const devicesSnap = await db.collection(`users/${uid}/devices`).get();
  const tokens = devicesSnap.docs.map(d => d.data().fcmToken).filter(Boolean) as string[];

  for (const push of pushes) {
    // Step 1: write lastSentAt BEFORE sending (idempotency rule).
    await db.doc(`users/${uid}/quest_state/state`).update({
      [`notification_state.${push.notificationKey}.lastSentAt`]: FieldValue.serverTimestamp()
    });

    // Step 2: send FCM. If this fails, lastSentAt is already set —
    // we accept the rare missed notification per spec §7.1.
    if (tokens.length === 0) continue;

    try {
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: push.titleKey,    // Client localizes via NSLocalizedString lookup.
          body: push.bodyKey
        },
        data: {
          notificationKey: push.notificationKey
        }
      });
    } catch (e) {
      console.error(`[questNotificationCron] FCM send failed for uid=${uid} key=${push.notificationKey}`, e);
    }
  }
}

export const questNotificationCron = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Etc/UTC",
    memory: "256MiB",
    timeoutSeconds: 540
  },
  async () => {
    const db = getFirestore();
    const utcHour = new Date().getUTCHours();
    const candidates = await findUsersToNotify(db, utcHour);

    for (const candidate of candidates) {
      const pushes = computePushesToFire(candidate.state);
      await dispatchPushesForUser(candidate.uid, candidate.state, pushes, db);
    }

    console.log(`[questNotificationCron] hour=${utcHour}, candidates=${candidates.length}, completed`);
  }
);
```

- [ ] **Step 2: Verify the build**

```bash
cd functions && npm run build
```

Expected: no errors. (Direct Cron testing requires triggering via emulator harness; we cover the logic in `computePushesToFire` already.)

- [ ] **Step 3: Commit**

```bash
git add functions/src/cron/questNotificationCron.ts
git commit -m "feat(functions): FCM dispatch with write-before-send idempotency"
```

---

## Task 18: Tighten Firestore Security Rules — quest_state and survey_submissions

**Files:**
- Modify: `firestore.rules`

Adds rules for the new collections per spec §7.2. Existing `mood_checkins` rule is also tightened to enforce server-stamped `createdAt` and timezoneOffsetMinutes range.

- [ ] **Step 1: Update firestore.rules**

Replace the file's contents with:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      // Mood check-ins — server-stamped createdAt, timezoneOffsetMinutes range
      match /mood_checkins/{checkinId} {
        allow read, delete: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.keys().hasAll([
                           'colorHex', 'colorIntensity', 'emotion',
                           'topic', 'evaluation', 'createdAt',
                           'timezoneOffsetMinutes'
                         ])
                      && request.resource.data.createdAt == request.time
                      && request.resource.data.timezoneOffsetMinutes is int
                      && request.resource.data.timezoneOffsetMinutes >= -840
                      && request.resource.data.timezoneOffsetMinutes <= 840;
        allow update: if request.auth.uid == uid;
      }

      // Drawings (existing — unchanged)
      match /drawings/{drawingId} {
        allow read, delete: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.keys().hasAll([
                           'imageURL', 'recordingURL', 'isFromCheckIn', 'createdAt'
                         ]);
        allow update: if request.auth.uid == uid;
      }

      // Journals (existing — unchanged)
      match /journals/{journalId} {
        allow read, delete: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.keys().hasAll(['checkinId', 'createdAt']);
        allow update: if request.auth.uid == uid;
      }

      // Quest aggregate state — most fields server-only.
      // Client may set timezoneOffsetMinutes and notificationHour at app launch.
      match /quest_state/{document=**} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid;
        allow update: if request.auth.uid == uid
                      && request.resource.data.diff(resource.data).affectedKeys()
                            .hasOnly(['timezoneOffsetMinutes', 'notificationHour']);
        allow delete: if false;
      }

      // Habit aggregate doc — client read/write within own scope (shape trust accepted).
      match /habits/state {
        allow read, write: if request.auth.uid == uid;
      }

      // Survey submissions — write-once.
      match /survey_submissions/{submissionId} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.submittedAt == request.time
                      && request.resource.data.surveyType in
                          ['importance_check_in', '8dim',
                           'state_of_change', 'satisfaction_check_in'];
        allow update, delete: if false;
      }

      // Notification state — server-only via Admin SDK.
      match /notification_state/{ruleId} {
        allow read: if request.auth.uid == uid;
        allow write: if false;
      }

      // FCM device tokens.
      match /devices/{deviceId} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

- [ ] **Step 2: Verify the rules deploy to emulator**

```bash
firebase emulators:start --only firestore
# Expect: "✔ rules: rules file firestore.rules compiled successfully"
# Stop with Ctrl-C
```

- [ ] **Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat(firestore): tighten Security Rules for Quest collections (server-only writes, write-once submissions)"
```

---

## Task 19: Rules emulator tests

**Files:**
- Create: `functions/test/rules/firestoreRules.test.ts`

End-to-end Security Rules tests using the rules-emulator. Verifies cross-user blocking, write-once enforcement, and server-only paths.

- [ ] **Step 1: Write the failing tests**

Create `functions/test/rules/firestoreRules.test.ts`:

```ts
import { beforeAll, afterAll, beforeEach, describe, it, expect } from "vitest";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertSucceeds,
  assertFails
} from "@firebase/rules-unit-testing";
import { setDoc, doc, deleteDoc, updateDoc, getDoc, serverTimestamp } from "firebase/firestore";
import { readFileSync } from "fs";
import { resolve } from "path";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-rules-test",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8"),
      host: "localhost",
      port: 8080
    }
  });
});

afterAll(async () => { await testEnv.cleanup(); });
beforeEach(async () => { await testEnv.clearFirestore(); });

describe("Firestore Security Rules — Quest paths", () => {
  it("user CAN read their own quest_state", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/quest_state/state"), { distinctCheckInDays: 0 });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(getDoc(doc(u1Db, "users/u1/quest_state/state")));
  });

  it("user CANNOT read another user's quest_state", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/quest_state/state"), { distinctCheckInDays: 0 });
    });
    const u2Db = testEnv.authenticatedContext("u2").firestore();
    await assertFails(getDoc(doc(u2Db, "users/u1/quest_state/state")));
  });

  it("user CANNOT update distinctCheckInDays in quest_state (server-only)", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/quest_state/state"), {
        distinctCheckInDays: 0,
        notificationHour: 1,
        timezoneOffsetMinutes: 480
      });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(updateDoc(doc(u1Db, "users/u1/quest_state/state"), { distinctCheckInDays: 999 }));
  });

  it("user CAN update notificationHour and timezoneOffsetMinutes", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/quest_state/state"), {
        distinctCheckInDays: 0,
        notificationHour: 1,
        timezoneOffsetMinutes: 480
      });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(updateDoc(doc(u1Db, "users/u1/quest_state/state"), {
      notificationHour: 13,
      timezoneOffsetMinutes: -300
    }));
  });

  it("user CAN create their own survey_submission with valid surveyType", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(setDoc(doc(u1Db, "users/u1/survey_submissions/s1"), {
      submittedAt: serverTimestamp(),
      surveyType: "8dim"
    }));
  });

  it("user CANNOT create survey_submission with invalid surveyType", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(setDoc(doc(u1Db, "users/u1/survey_submissions/s1"), {
      submittedAt: serverTimestamp(),
      surveyType: "garbage"
    }));
  });

  it("user CANNOT update existing survey_submission (write-once)", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/survey_submissions/s1"), {
        submittedAt: new Date(),
        surveyType: "8dim"
      });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(updateDoc(doc(u1Db, "users/u1/survey_submissions/s1"), { surveyType: "satisfaction_check_in" }));
  });

  it("user CANNOT delete survey_submission", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/survey_submissions/s1"), {
        submittedAt: new Date(),
        surveyType: "8dim"
      });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(deleteDoc(doc(u1Db, "users/u1/survey_submissions/s1")));
  });

  it("user CANNOT write to notification_state (server-only)", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(setDoc(doc(u1Db, "users/u1/notification_state/MilestoneDay14"), {
      lastSentAt: new Date()
    }));
  });

  it("user CAN read their own notification_state", async () => {
    await testEnv.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), "users/u1/notification_state/MilestoneDay14"), {
        lastSentAt: new Date()
      });
    });
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(getDoc(doc(u1Db, "users/u1/notification_state/MilestoneDay14")));
  });

  it("user CAN write their own FCM device token", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(setDoc(doc(u1Db, "users/u1/devices/abc"), {
      fcmToken: "tok_abc",
      platform: "ios"
    }));
  });

  it("user CANNOT write to another user's device tokens", async () => {
    const u2Db = testEnv.authenticatedContext("u2").firestore();
    await assertFails(setDoc(doc(u2Db, "users/u1/devices/abc"), {
      fcmToken: "tok_evil",
      platform: "ios"
    }));
  });

  it("user CANNOT create mood_checkin with client-supplied createdAt", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(setDoc(doc(u1Db, "users/u1/mood_checkins/m1"), {
      colorHex: "#fff", colorIntensity: 0.5, emotion: "happy",
      topic: "emotional", evaluation: "good",
      createdAt: new Date(),                      // client-supplied — must use serverTimestamp
      timezoneOffsetMinutes: 480
    }));
  });

  it("user CANNOT create mood_checkin with out-of-range timezoneOffsetMinutes", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertFails(setDoc(doc(u1Db, "users/u1/mood_checkins/m1"), {
      colorHex: "#fff", colorIntensity: 0.5, emotion: "happy",
      topic: "emotional", evaluation: "good",
      createdAt: serverTimestamp(),
      timezoneOffsetMinutes: 9999                  // out of -840..840
    }));
  });

  it("user CAN create mood_checkin with valid fields", async () => {
    const u1Db = testEnv.authenticatedContext("u1").firestore();
    await assertSucceeds(setDoc(doc(u1Db, "users/u1/mood_checkins/m1"), {
      colorHex: "#fff", colorIntensity: 0.5, emotion: "happy",
      topic: "emotional", evaluation: "good",
      createdAt: serverTimestamp(),
      timezoneOffsetMinutes: 480
    }));
  });
});
```

- [ ] **Step 2: Start the Firestore Emulator**

In one terminal:

```bash
firebase emulators:start --only firestore
```

- [ ] **Step 3: Run the tests**

In another terminal:

```bash
cd functions && npm test -- test/rules/firestoreRules.test.ts
```

Expected: all 14 tests pass.

- [ ] **Step 4: Commit**

```bash
git add functions/test/rules/firestoreRules.test.ts
git commit -m "test(firestore): add comprehensive Security Rules emulator tests for Quest paths"
```

---

## Task 20: Final integration smoke test in emulator

**Files:**
- Create: `functions/test/integration/end-to-end.test.ts`

End-to-end emulator test: simulate the full Day-7 flow. Create a user, write 7 mood check-ins on 7 different days, assert that `pendingSurveys` becomes `["importance_check_in"]`. Submit an Importance Check-In; assert that `focusDimension` is set and `pendingSurveys` becomes `["8dim"]`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/integration/end-to-end.test.ts`:

```ts
import { beforeAll, afterAll, beforeEach, describe, it, expect } from "vitest";
import { initializeTestEnvironment, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase-admin/firestore";
import { initializeQuestState } from "../../src/triggers/onUserCreated";
import { processMoodCheckIn } from "../../src/triggers/onMoodCheckInCreated";
import { processSurveySubmission } from "../../src/triggers/onSurveySubmissionCreated";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "soulverse-e2e",
    firestore: { host: "localhost", port: 8080 }
  });
});

afterAll(async () => { await testEnv.cleanup(); });
beforeEach(async () => { await testEnv.clearFirestore(); });

describe("End-to-end Day-7 flow", () => {
  const uid = "e2e-user";

  it("Day 1-7 mood check-ins → Importance pending → submit → 8-Dim pending", async () => {
    const db = testEnv.unauthenticatedContext().firestore() as any;

    // Step 1: User created → quest_state initialized
    await initializeQuestState(uid, db);

    // Step 2: 7 mood check-ins on 7 different days
    const offset = 8 * 60;   // UTC+8
    for (let day = 1; day <= 7; day++) {
      const isoDate = `2026-04-${String(28 + day).padStart(2, "0")}T05:00:00Z`;
      await processMoodCheckIn(uid, {
        createdAt: Timestamp.fromDate(new Date(isoDate)),
        timezoneOffsetMinutes: offset
      } as any, db);
    }

    let snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().distinctCheckInDays).toBe(7);
    expect(snap.data().pendingSurveys).toEqual(["importance_check_in"]);
    expect(snap.data().focusDimension).toBeNull();

    // Step 3: User submits Importance Check-In with topCategory = emotional
    await processSurveySubmission(uid, {
      submissionId: "imp1",
      surveyType: "importance_check_in",
      submittedAt: Timestamp.now(),
      appVersion: "1.0.0",
      submittedFromQuestDay: 7,
      payload: {
        responses: [],
        computed: {
          categoryMeans: {
            physical: 3.0, emotional: 4.5, social: 3.5, intellectual: 3.0,
            spiritual: 2.5, occupational: 4.0, environmental: 3.0, financial: 3.5
          },
          topCategory: "emotional",
          tieBreakerLevel: 1
        }
      }
    } as any, db);

    snap = await db.doc(`users/${uid}/quest_state/state`).get();
    expect(snap.data().focusDimension).toBe("emotional");
    expect(snap.data().importanceCheckInSubmittedAt).not.toBeNull();
    expect(snap.data().pendingSurveys).toContain("8dim");
    expect(snap.data().pendingSurveys).not.toContain("importance_check_in");
  });
});
```

- [ ] **Step 2: Run the test**

Make sure Firestore Emulator is running, then:

```bash
cd functions && npm test -- test/integration/end-to-end.test.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/end-to-end.test.ts
git commit -m "test(functions): end-to-end emulator test for Day-7 → Importance → 8-Dim flow"
```

---

## Task 21: Deploy to Firebase project

**Files:**
- (No new files)

After Pre-launch items 1, 2, 3 complete (Blaze plan + APNs key + key uploaded), deploy.

- [ ] **Step 1: Verify all tests pass**

```bash
cd functions && npm test
```

Expected: every test in every file passes (utils, schedule, triggers, cron, rules, integration).

- [ ] **Step 2: Build production bundle**

```bash
cd functions && npm run build
```

Expected: `lib/` populated with no errors.

- [ ] **Step 3: Deploy functions**

```bash
firebase deploy --only functions
```

Expected: Firebase CLI reports `Deploy complete!` with all 4 function names listed (onUserCreated, onMoodCheckInCreated, onSurveySubmissionCreated, questNotificationCron).

- [ ] **Step 4: Deploy Firestore rules and indexes**

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Expected: `Deploy complete!` Notification: index for `quest_state.notificationHour` shows "Building" — wait until index status becomes "Ready" in Firebase console (a few minutes).

- [ ] **Step 5: Smoke test in production**

In the Firebase console:
1. Use the Auth tab to create a test user `test@soulverse.life`.
2. Verify `users/{testUid}/quest_state/state` doc auto-created (check Firestore tab).
3. Manually create 7 docs at `users/{testUid}/mood_checkins/m1..m7` with distinct `createdAt` dates spread across 7 different days (use `serverTimestamp()` and `timezoneOffsetMinutes: 0` for simplicity).
4. After each write, verify `quest_state.distinctCheckInDays` increments and the 7th write produces `pendingSurveys: ["importance_check_in"]`.
5. Delete the test user after verification.

- [ ] **Step 6: Final commit (deployment marker)**

No code change, but tag the deploy:

```bash
git tag -a quest-cloud-functions-v1 -m "Plan 1 complete: Cloud Functions deployed"
git push origin quest-cloud-functions-v1
```

---

## Plan summary & next steps

**This plan delivers:**
- Working Cloud Functions deployed to Firebase
- Server-side day counter, focus assignment, schedule engine, notification cron
- Tightened Firestore Security Rules with rules-emulator test coverage
- End-to-end emulator test demonstrating Day-7 → Importance → 8-Dim flow

**Pending iOS work** (covered in Plans 2–7):
- Plan 2: Quest screen UI shell (ProgressSection, locked cards, Day-1 CTA)
- Plan 3: Habit Checker
- Plan 4: Survey infrastructure (generic SurveyViewController, question banks)
- Plan 5: Survey integration + radar chart refactor
- Plan 6: Notifications (FCM token registration, permission UX)
- Plan 7: Polish + final QA

The next plan (Plan 2) can begin after Plan 1 deploys, since Plan 2 reads the now-populated `quest_state` from a real backend.

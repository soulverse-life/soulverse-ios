import { Timestamp } from "firebase-admin/firestore";

/** Eight wellness dimensions. Identical to mood_checkins.topic enum values. */
export type WellnessDimension =
  | "physical"
  | "emotional"
  | "social"
  | "intellectual"
  | "spiritual"
  | "occupational"
  | "environment"
  | "financial";

export const ALL_DIMENSIONS: WellnessDimension[] = [
  "physical", "emotional", "social", "intellectual",
  "spiritual", "occupational", "environment", "financial"
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

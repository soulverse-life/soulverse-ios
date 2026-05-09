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

const now = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));

describe("evaluateCondition", () => {
  it("distinctCheckInDays threshold: false when below", () => {
    expect(evaluateCondition(
      { type: "distinctCheckInDays", threshold: 7 },
      baseState({ distinctCheckInDays: 6 }), now
    )).toBe(false);
  });

  it("distinctCheckInDays threshold: true when at threshold", () => {
    expect(evaluateCondition(
      { type: "distinctCheckInDays", threshold: 7 },
      baseState({ distinctCheckInDays: 7 }), now
    )).toBe(true);
  });

  it("focusDimensionAssigned: false when null", () => {
    expect(evaluateCondition(
      { type: "focusDimensionAssigned" }, baseState(), now
    )).toBe(false);
  });

  it("focusDimensionAssigned: true when non-null", () => {
    expect(evaluateCondition(
      { type: "focusDimensionAssigned" },
      baseState({ focusDimension: "emotional" }), now
    )).toBe(true);
  });

  it("daysSinceQuestComplete: false when not completed", () => {
    expect(evaluateCondition(
      { type: "daysSinceQuestComplete", days: 90 }, baseState(), now
    )).toBe(false);
  });

  it("daysSinceQuestComplete: true when enough days passed", () => {
    const completedAt = Timestamp.fromDate(new Date("2025-12-01T00:00:00Z"));
    expect(evaluateCondition(
      { type: "daysSinceQuestComplete", days: 90 },
      baseState({ questCompletedAt: completedAt }), now
    )).toBe(true);
  });

  it("daysSinceLastSubmission: false when no prior submission", () => {
    expect(evaluateCondition(
      { type: "daysSinceLastSubmission", days: 30, surveyType: "8dim" },
      baseState(), now
    )).toBe(false);
  });

  it("daysSinceLastSubmission: 8dim — true when ≥30 days since lastEightDimSubmittedAt", () => {
    const last = Timestamp.fromDate(new Date("2026-03-01T00:00:00Z"));
    expect(evaluateCondition(
      { type: "daysSinceLastSubmission", days: 30, surveyType: "8dim" },
      baseState({ lastEightDimSubmittedAt: last }), now
    )).toBe(true);
  });

  it("allOf: true when all conditions true", () => {
    const cond: EligibilityCondition = {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 7 },
        { type: "focusDimensionAssigned" }
      ]
    };
    expect(evaluateCondition(cond, baseState({
      distinctCheckInDays: 10, focusDimension: "emotional"
    }), now)).toBe(true);
  });

  it("allOf: false when any condition false", () => {
    const cond: EligibilityCondition = {
      type: "allOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 7 },
        { type: "focusDimensionAssigned" }
      ]
    };
    expect(evaluateCondition(cond, baseState({
      distinctCheckInDays: 10, focusDimension: null
    }), now)).toBe(false);
  });

  it("oneOf: true when any condition true", () => {
    const cond: EligibilityCondition = {
      type: "oneOf",
      conditions: [
        { type: "distinctCheckInDays", threshold: 100 },
        { type: "focusDimensionAssigned" }
      ]
    };
    expect(evaluateCondition(cond, baseState({
      distinctCheckInDays: 10, focusDimension: "emotional"
    }), now)).toBe(true);
  });
});

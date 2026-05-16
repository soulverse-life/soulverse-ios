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
    expect(composePendingSurveys(baseState({ distinctCheckInDays: 5 }), now).pendingSurveys).toEqual([]);
  });

  it("returns importance_check_in when day 7 first reached and not submitted", () => {
    expect(composePendingSurveys(baseState({ distinctCheckInDays: 7 }), now).pendingSurveys).toEqual(["importance_check_in"]);
  });

  it("returns 8dim only after Importance is submitted (focus assigned)", () => {
    const state = baseState({
      distinctCheckInDays: 8,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-29T00:00:00Z"))
    });
    expect(composePendingSurveys(state, now).pendingSurveys).toEqual(["8dim"]);
  });

  it("returns state_of_change at day 21 with focus assigned and not yet submitted", () => {
    const state = baseState({
      distinctCheckInDays: 21,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-15T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-04-20T00:00:00Z"))
    });
    expect(composePendingSurveys(state, now).pendingSurveys).toContain("state_of_change");
  });

  it("does NOT return 8dim when its result is fresh (within 30-day re-take cadence)", () => {
    const state = baseState({
      distinctCheckInDays: 22,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-04-15T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-04-25T00:00:00Z"))
    });
    expect(composePendingSurveys(state, now).pendingSurveys).not.toContain("8dim");
  });

  it("returns 8dim re-take when ≥30 days since last submission", () => {
    const state = baseState({
      distinctCheckInDays: 30,
      focusDimension: "emotional",
      importanceCheckInSubmittedAt: Timestamp.fromDate(new Date("2026-03-01T00:00:00Z")),
      lastEightDimSubmittedAt: Timestamp.fromDate(new Date("2026-03-15T00:00:00Z")),
      questCompletedAt: Timestamp.fromDate(new Date("2026-03-20T00:00:00Z"))
    });
    expect(composePendingSurveys(state, now).pendingSurveys).toContain("8dim");
  });

  it("populates surveyEligibleSinceMap for all pending entries", () => {
    expect(composePendingSurveys(baseState({ distinctCheckInDays: 7 }), now).surveyEligibleSinceMap["importance_check_in"]).toBeDefined();
  });
});

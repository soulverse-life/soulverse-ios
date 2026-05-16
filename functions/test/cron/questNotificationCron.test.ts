import { describe, it, expect } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { computePushesToFire } from "../../src/cron/questNotificationCron";
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

describe("computePushesToFire", () => {
  it("fires a survey-driven push when survey is pending and not yet sent", () => {
    const state = baseState({
      distinctCheckInDays: 7,
      pendingSurveys: ["importance_check_in"]
    });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("importance_check_in_first");
  });

  it("does not fire when already sent for this eligibility window", () => {
    const state = baseState({
      distinctCheckInDays: 7,
      pendingSurveys: ["importance_check_in"],
      notification_state: {
        importance_check_in_first: { lastSentAt: Timestamp.now() }
      }
    });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("importance_check_in_first");
  });

  it("fires milestone push at day 14", () => {
    const state = baseState({ distinctCheckInDays: 14 });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("MilestoneDay14");
  });

  it("doesn't fire MilestoneDay14 if already sent", () => {
    const state = baseState({
      distinctCheckInDays: 14,
      notification_state: {
        MilestoneDay14: { lastSentAt: Timestamp.now() }
      }
    });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("MilestoneDay14");
  });

  it("fires retake notification on a NEW retake window after a prior submission+notification", () => {
    const oldNotifyAt = Timestamp.fromDate(new Date("2026-04-01T00:00:00Z"));
    const recentSubmitAt = Timestamp.fromDate(new Date("2026-04-15T00:00:00Z"));
    const state = baseState({
      distinctCheckInDays: 60,
      pendingSurveys: ["8dim"],
      lastEightDimSubmittedAt: recentSubmitAt,
      notification_state: {
        "8dim_retake": { lastSentAt: oldNotifyAt }
      }
    });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).toContain("8dim_retake");
  });

  it("does NOT fire retake notification within the same retake window (lastSentAt is after lastSubmittedAt)", () => {
    const submitAt = Timestamp.fromDate(new Date("2026-04-01T00:00:00Z"));
    const recentNotifyAt = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));
    const state = baseState({
      distinctCheckInDays: 60,
      pendingSurveys: ["8dim"],
      lastEightDimSubmittedAt: submitAt,
      notification_state: {
        "8dim_retake": { lastSentAt: recentNotifyAt }
      }
    });
    const pushes = computePushesToFire(state);
    expect(pushes.map(p => p.notificationKey)).not.toContain("8dim_retake");
  });
});

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

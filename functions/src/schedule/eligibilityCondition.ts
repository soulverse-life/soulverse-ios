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

    case "daysSinceQuestComplete": {
      if (!state.questCompletedAt) return false;
      const elapsed = (now.toMillis() - state.questCompletedAt.toMillis()) / MS_PER_DAY;
      return elapsed >= cond.days;
    }

    case "daysSinceLastSubmission": {
      const last = lastSubmittedAtFor(state, cond.surveyType);
      if (!last) return false;
      const elapsed = (now.toMillis() - last.toMillis()) / MS_PER_DAY;
      return elapsed >= cond.days;
    }

    case "allOf":
      return cond.conditions.every(c => evaluateCondition(c, state, now));

    case "oneOf":
      return cond.conditions.some(c => evaluateCondition(c, state, now));
  }
}

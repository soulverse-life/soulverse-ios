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
 * of when each became eligible (used by the client to order the deck-of-cards).
 */
export function composePendingSurveys(state: QuestState, now: Timestamp): PendingComposition {
  const pending: SurveyType[] = [];
  const eligibleSinceMap: Record<string, Timestamp> = {};

  for (const entry of SURVEY_SCHEDULE) {
    const submitted = hasSubmissionFor(state, entry.surveyType);

    if (!submitted) {
      if (evaluateCondition(entry.firstAvailable, state, now)) {
        pending.push(entry.surveyType);
        eligibleSinceMap[entry.surveyType] = now;
      }
    } else if (entry.reTakeCadence) {
      if (evaluateCondition(entry.reTakeCadence, state, now)) {
        pending.push(entry.surveyType);
        eligibleSinceMap[entry.surveyType] = now;
      }
    }
  }

  return { pendingSurveys: pending, surveyEligibleSinceMap: eligibleSinceMap };
}

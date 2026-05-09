import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore } from "firebase-admin/firestore";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { QuestState } from "../types";

if (getApps().length === 0) initializeApp();

/**
 * Compute the UTC hour at which the user's local time is 09:00.
 * Defaults to UTC+0 if offset is unknown.
 */
export function deriveNotificationHour(timezoneOffsetMinutes: number): number {
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

  const defaultOffset = 0;
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

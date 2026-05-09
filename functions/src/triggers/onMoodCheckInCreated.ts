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

    // Build hypothetical updated state for re-composing pending surveys
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

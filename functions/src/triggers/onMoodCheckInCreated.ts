import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { Firestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { computeDayKey } from "../utils/dayKey";
import { MoodCheckIn, QuestState } from "../types";
import { composePendingSurveys } from "../schedule/composer";
import { defaultQuestState } from "./onUserCreated";

export async function processMoodCheckIn(
  uid: string,
  checkin: MoodCheckIn,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const existing = snap.data();

    // Self-heal: the doc may be missing entirely (account predates this CF)
    // OR partially seeded (iOS's `writeTimezone` writes only
    // `timezoneOffsetMinutes` + `notificationHour` on first launch, which
    // satisfies `snap.exists` but leaves `distinctCheckInDays` undefined).
    // Treat anything without `distinctCheckInDays` as needing a fresh seed,
    // preserving whatever partial fields are already there (e.g. timezone).
    const needsSeed = !existing || existing.distinctCheckInDays === undefined;
    if (needsSeed) {
      logger.warn("quest_state seed/heal", {
        uid,
        reason: !existing ? "missing" : "partial",
        existingFields: existing ? Object.keys(existing) : []
      });
    }

    const state: QuestState = {
      ...defaultQuestState(),
      ...(existing ?? {})
    } as QuestState;

    const dayKey = computeDayKey(checkin.createdAt, checkin.timezoneOffsetMinutes);
    logger.info("mood check-in received", { uid, dayKey, hasState: !needsSeed });

    if (dayKey === state.lastDistinctDayKey) {
      logger.info("quest_state unchanged (same day)", { uid, dayKey });
      return;
    }

    const newCount = state.distinctCheckInDays + 1;
    const now = Timestamp.now();

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

    // On fresh seed: write the full default shape (preserving any partial
    // fields like timezone) alongside the bump. Otherwise just the deltas.
    // `set` with merge handles both create and update; `update` would have
    // failed on the missing-doc case.
    const writeData = needsSeed
      ? { ...defaultQuestState(), ...(existing ?? {}), ...updates }
      : updates;

    tx.set(ref, writeData, { merge: true });

    logger.info("quest_state bumped", {
      uid,
      distinctCheckInDays: newCount,
      dayKey,
      pendingSurveysCount: composition.pendingSurveys.length
    });
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

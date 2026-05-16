import { onSchedule } from "firebase-functions/v2/scheduler";
import { Firestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { QuestState } from "../types";
import { SURVEY_SCHEDULE, MILESTONE_NOTIFICATIONS } from "../schedule/schedule";
import { evaluateCondition } from "../schedule/eligibilityCondition";

export interface NotifyCandidate {
  uid: string;
  state: QuestState;
}

export async function findUsersToNotify(
  db: Firestore,
  utcHour: number
): Promise<NotifyCandidate[]> {
  const querySnap = await db.collectionGroup("quest_state")
    .where("notificationHour", "==", utcHour)
    .get();

  return querySnap.docs.map(doc => {
    // doc.ref.path = "users/{uid}/quest_state/state"
    const segments = doc.ref.path.split("/");
    const uid = segments[1];
    return { uid, state: doc.data() as QuestState };
  });
}

export interface PushToFire {
  notificationKey: string;
  titleKey: string;
  bodyKey: string;
}

/** Subset of QuestState keys that hold a submission Timestamp (or null). */
type SubmissionField =
  | "importanceCheckInSubmittedAt"
  | "lastEightDimSubmittedAt"
  | "lastStateOfChangeSubmittedAt"
  | "satisfactionCheckInSubmittedAt";

function lastSubmittedField(surveyType: string): SubmissionField | null {
  switch (surveyType) {
    case "importance_check_in":   return "importanceCheckInSubmittedAt";
    case "8dim":                  return "lastEightDimSubmittedAt";
    case "state_of_change":       return "lastStateOfChangeSubmittedAt";
    case "satisfaction_check_in": return "satisfactionCheckInSubmittedAt";
    default: return null;
  }
}

function readSubmissionTimestamp(state: QuestState, field: SubmissionField): Timestamp | null {
  return state[field];
}

/**
 * Decide whether a notification should fire for the current eligibility window.
 *
 * Rules:
 *   - "_first" key:    fire iff lastSentAt is null. Never re-fire.
 *   - "_retake" key:   fire iff lastSentAt is null OR lastSubmittedAt > lastSentAt
 *                      (user has submitted since we last notified — new window).
 *   - milestone-only:  fire iff lastSentAt is null. Never re-fire.
 *   - Self-correction guard: ignore lastSentAt > now (clock skew) and re-fire.
 */
function shouldFire(
  notificationKey: string,
  state: QuestState,
  surveyType: string | null,
  now: Timestamp
): boolean {
  const sent = state.notification_state?.[notificationKey];
  if (!sent || !sent.lastSentAt) return true;

  if (sent.lastSentAt.toMillis() > now.toMillis()) return true;

  if (notificationKey.endsWith("_retake") && surveyType) {
    const submittedField = lastSubmittedField(surveyType);
    if (!submittedField) return false;
    const lastSubmittedAt = readSubmissionTimestamp(state, submittedField);
    if (!lastSubmittedAt) return false;
    return lastSubmittedAt.toMillis() > sent.lastSentAt.toMillis();
  }

  return false;
}

export function computePushesToFire(state: QuestState): PushToFire[] {
  const result: PushToFire[] = [];
  const now = Timestamp.now();

  for (const surveyType of state.pendingSurveys) {
    const entry = SURVEY_SCHEDULE.find(e => e.surveyType === surveyType);
    if (!entry) continue;

    const submittedField = lastSubmittedField(surveyType);
    const isFirstTime = !submittedField || readSubmissionTimestamp(state, submittedField) === null;
    const notificationKey = `${surveyType}_${isFirstTime ? "first" : "retake"}`;

    if (!shouldFire(notificationKey, state, surveyType, now)) continue;

    result.push({
      notificationKey,
      titleKey: entry.notification.titleKey,
      bodyKey:  entry.notification.bodyKey
    });
  }

  for (const milestone of MILESTONE_NOTIFICATIONS) {
    if (!evaluateCondition(milestone.predicate, state, now)) continue;
    if (!shouldFire(milestone.notificationKey, state, null, now)) continue;

    result.push({
      notificationKey: milestone.notificationKey,
      titleKey: milestone.titleKey,
      bodyKey:  milestone.bodyKey
    });
  }

  return result;
}

async function dispatchPushesForUser(
  uid: string,
  state: QuestState,
  pushes: PushToFire[],
  db: Firestore
): Promise<void> {
  if (pushes.length === 0) return;

  // Find the user's devices
  const devicesSnap = await db.collection(`users/${uid}/devices`).get();
  const tokens = devicesSnap.docs.map(d => d.data().fcmToken).filter(Boolean) as string[];

  for (const push of pushes) {
    // Step 1: write lastSentAt BEFORE sending (idempotency rule per spec §7.1).
    await db.doc(`users/${uid}/quest_state/state`).update({
      [`notification_state.${push.notificationKey}.lastSentAt`]: FieldValue.serverTimestamp()
    });

    if (tokens.length === 0) continue;

    try {
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: push.titleKey,    // Client localizes via NSLocalizedString lookup.
          body: push.bodyKey
        },
        data: {
          notificationKey: push.notificationKey
        }
      });
    } catch (e) {
      console.error(`[questNotificationCron] FCM send failed for uid=${uid} key=${push.notificationKey}`, e);
    }
  }
}

export const questNotificationCron = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Etc/UTC",
    memory: "256MiB",
    timeoutSeconds: 540
  },
  async () => {
    const db = getFirestore();
    const utcHour = new Date().getUTCHours();
    const candidates = await findUsersToNotify(db, utcHour);

    for (const candidate of candidates) {
      const pushes = computePushesToFire(candidate.state);
      await dispatchPushesForUser(candidate.uid, candidate.state, pushes, db);
    }

    console.log(`[questNotificationCron] hour=${utcHour}, candidates=${candidates.length}, completed`);
  }
);

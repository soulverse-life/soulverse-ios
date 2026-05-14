import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import {
  QuestState, SurveySubmission, ImportanceComputed,
  EightDimComputed, StateOfChangeComputed, SatisfactionComputed,
  WellnessDimension
} from "../types";
import { composePendingSurveys } from "../schedule/composer";
import { defaultQuestState } from "./onUserCreated";

export async function processSurveySubmission(
  uid: string,
  submission: SurveySubmission,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const existing = snap.data();

    // Self-heal: see onMoodCheckInCreated for the same rationale. The doc
    // may be partially seeded (only timezone fields) before the user has
    // logged their first check-in / survey.
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

    logger.info("survey submission received", {
      uid,
      surveyType: submission.surveyType,
      hasState: !needsSeed
    });

    const now = Timestamp.now();

    const baseUpdates = handleSurveySpecific(submission, state, now);
    const updatedState: QuestState = { ...state, ...baseUpdates };

    const composition = composePendingSurveys(updatedState, now);

    const updates = {
      ...baseUpdates,
      pendingSurveys: composition.pendingSurveys,
      surveyEligibleSinceMap: composition.surveyEligibleSinceMap
    };

    const writeData = needsSeed
      ? { ...defaultQuestState(), ...(existing ?? {}), ...updates }
      : updates;

    tx.set(ref, writeData, { merge: true });

    logger.info("quest_state updated by survey", {
      uid,
      surveyType: submission.surveyType,
      pendingSurveysCount: composition.pendingSurveys.length
    });
  });
}

function handleSurveySpecific(
  submission: SurveySubmission,
  state: QuestState,
  now: Timestamp
): Partial<QuestState> {
  switch (submission.surveyType) {
    case "importance_check_in": {
      const computed = (submission.payload as { computed: ImportanceComputed }).computed;
      return {
        focusDimension: state.focusDimension ?? computed.topCategory,
        focusDimensionAssignedAt: state.focusDimensionAssignedAt ?? now,
        importanceCheckInSubmittedAt: now
      };
    }

    case "8dim": {
      const payload = submission.payload as {
        dimension: WellnessDimension;
        computed: EightDimComputed;
      };
      return {
        lastEightDimSubmittedAt: now,
        lastEightDimDimension: payload.dimension,
        lastEightDimSummary: {
          stage: payload.computed.stage,
          stageKey: payload.computed.stageKey,
          messageKey: payload.computed.messageKey
        }
      };
    }

    case "state_of_change": {
      const computed = (submission.payload as { computed: StateOfChangeComputed }).computed;
      return {
        lastStateOfChangeSubmittedAt: now,
        lastStateOfChangeStage: computed.stage
      };
    }

    case "satisfaction_check_in": {
      const computed = (submission.payload as { computed: SatisfactionComputed }).computed;
      return {
        satisfactionCheckInSubmittedAt: now,
        lastSatisfactionTopCategory: computed.topCategory,
        lastSatisfactionLowestCategory: computed.lowestCategory
      };
    }
  }
}

export const onSurveySubmissionCreated = onDocumentCreated(
  "users/{uid}/survey_submissions/{id}",
  async event => {
    const uid = event.params.uid;
    const submission = event.data?.data() as SurveySubmission | undefined;
    if (!submission) return;
    await processSurveySubmission(uid, submission, getFirestore());
  }
);

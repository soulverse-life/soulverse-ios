import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import {
  QuestState, SurveySubmission, ImportanceComputed,
  EightDimComputed, StateOfChangeComputed, SatisfactionComputed,
  WellnessDimension
} from "../types";
import { composePendingSurveys } from "../schedule/composer";

export async function processSurveySubmission(
  uid: string,
  submission: SurveySubmission,
  db: Firestore
): Promise<void> {
  const ref = db.doc(`users/${uid}/quest_state/state`);

  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const state = snap.data() as QuestState;
    const now = Timestamp.now();

    const baseUpdates = handleSurveySpecific(submission, state, now);
    const updatedState: QuestState = { ...state, ...baseUpdates };

    const composition = composePendingSurveys(updatedState, now);

    tx.update(ref, {
      ...baseUpdates,
      pendingSurveys: composition.pendingSurveys,
      surveyEligibleSinceMap: composition.surveyEligibleSinceMap
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

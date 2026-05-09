import { ALL_DIMENSIONS, WellnessDimension } from "../types";

export interface FocusPickResult {
  dimension: WellnessDimension;
  tieBreakerLevel: 1 | 2 | 3;
}

/** Predetermined order used as the level-3 tie-breaker (matches wellness doc). */
const PRIORITY_ORDER: WellnessDimension[] = [
  "physical", "emotional", "social", "intellectual",
  "spiritual", "occupational", "environmental", "financial"
];

export function pickFocusDimension(
  categoryMeans: Record<WellnessDimension, number>,
  moodTopicCounts: Record<WellnessDimension, number>
): FocusPickResult {
  // Level 1: unique highest mean
  const maxMean = Math.max(...ALL_DIMENSIONS.map(d => categoryMeans[d]));
  const tiedAtMax = ALL_DIMENSIONS.filter(d => categoryMeans[d] === maxMean);

  if (tiedAtMax.length === 1) {
    return { dimension: tiedAtMax[0], tieBreakerLevel: 1 };
  }

  // Level 2: among tied, the one with highest mood-check-in topic count
  const maxCount = Math.max(...tiedAtMax.map(d => moodTopicCounts[d]));
  const tiedAtCount = tiedAtMax.filter(d => moodTopicCounts[d] === maxCount);

  if (tiedAtCount.length === 1) {
    return { dimension: tiedAtCount[0], tieBreakerLevel: 2 };
  }

  // Level 3: predetermined order
  for (const d of PRIORITY_ORDER) {
    if (tiedAtCount.includes(d)) {
      return { dimension: d, tieBreakerLevel: 3 };
    }
  }

  throw new Error("pickFocusDimension: unreachable fallback");
}

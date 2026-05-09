import { Timestamp } from "firebase-admin/firestore";

/**
 * Compute the YYYY-MM-DD day key in the local timezone defined by the offset.
 * Uses the *record's stored* offset, not the current device offset.
 *
 * @param ts Firestore Timestamp from the record's createdAt
 * @param timezoneOffsetMinutes minutes east of UTC (positive = east, e.g. UTC+8 = 480)
 */
export function computeDayKey(ts: Timestamp, timezoneOffsetMinutes: number): string {
  const utcMs = ts.toMillis();
  const localMs = utcMs + timezoneOffsetMinutes * 60_000;
  const localDate = new Date(localMs);

  const yyyy = localDate.getUTCFullYear();
  const mm = String(localDate.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(localDate.getUTCDate()).padStart(2, "0");

  return `${yyyy}-${mm}-${dd}`;
}

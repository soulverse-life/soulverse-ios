import { describe, it, expect } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { computeDayKey } from "../../src/utils/dayKey";

describe("computeDayKey", () => {
  it("buckets a UTC+0 record by its UTC date", () => {
    const ts = Timestamp.fromDate(new Date("2026-04-29T23:30:00Z"));
    expect(computeDayKey(ts, 0)).toBe("2026-04-29");
  });

  it("buckets a UTC+8 record by local date (Asia/Taipei)", () => {
    // 2026-04-29 23:30 UTC = 2026-04-30 07:30 in UTC+8
    const ts = Timestamp.fromDate(new Date("2026-04-29T23:30:00Z"));
    expect(computeDayKey(ts, 8 * 60)).toBe("2026-04-30");
  });

  it("buckets a UTC-7 record by local date (US/Pacific)", () => {
    // 2026-04-30 02:00 UTC = 2026-04-29 19:00 in UTC-7
    const ts = Timestamp.fromDate(new Date("2026-04-30T02:00:00Z"));
    expect(computeDayKey(ts, -7 * 60)).toBe("2026-04-29");
  });

  it("handles cross-date-line travel: same UTC timestamp, different offsets", () => {
    const ts = Timestamp.fromDate(new Date("2026-05-01T00:00:00Z"));
    expect(computeDayKey(ts, 8 * 60)).toBe("2026-05-01");
    expect(computeDayKey(ts, -8 * 60)).toBe("2026-04-30");
  });

  it("zero-pads months and days", () => {
    const ts = Timestamp.fromDate(new Date("2026-01-05T12:00:00Z"));
    expect(computeDayKey(ts, 0)).toBe("2026-01-05");
  });
});

import { describe, it, expect } from "vitest";
import { pickFocusDimension } from "../../src/utils/tieBreaker";
import { WellnessDimension } from "../../src/types";

const zeroCounts = (): Record<WellnessDimension, number> => ({
  physical: 0, emotional: 0, social: 0, intellectual: 0,
  spiritual: 0, occupational: 0, environment: 0, financial: 0
});

describe("pickFocusDimension", () => {
  it("returns the unique highest-mean category (level 1)", () => {
    const result = pickFocusDimension(
      { physical: 3.0, emotional: 4.5, social: 3.5, intellectual: 3.0,
        spiritual: 2.5, occupational: 4.0, environment: 3.0, financial: 3.5 },
      zeroCounts()
    );
    expect(result.dimension).toBe("emotional");
    expect(result.tieBreakerLevel).toBe(1);
  });

  it("uses mood-check-in topic count when means tie (level 2)", () => {
    const counts = zeroCounts();
    counts.physical = 2;
    counts.emotional = 5;
    const result = pickFocusDimension(
      { physical: 4.0, emotional: 4.0, social: 3.0, intellectual: 3.0,
        spiritual: 3.0, occupational: 3.0, environment: 3.0, financial: 3.0 },
      counts
    );
    expect(result.dimension).toBe("emotional");
    expect(result.tieBreakerLevel).toBe(2);
  });

  it("falls back to predetermined order when means and counts tie (level 3)", () => {
    const result = pickFocusDimension(
      { physical: 4.0, emotional: 4.0, social: 4.0, intellectual: 3.0,
        spiritual: 3.0, occupational: 3.0, environment: 3.0, financial: 3.0 },
      zeroCounts()
    );
    expect(result.dimension).toBe("physical");
    expect(result.tieBreakerLevel).toBe(3);
  });

  it("level 2 only chooses among the means-tied set", () => {
    const counts = zeroCounts();
    counts.physical = 99;     // not tied for top mean
    counts.emotional = 1;
    counts.social = 5;
    const result = pickFocusDimension(
      { physical: 3.0, emotional: 4.0, social: 4.0, intellectual: 3.0,
        spiritual: 3.0, occupational: 3.0, environment: 3.0, financial: 3.0 },
      counts
    );
    expect(result.dimension).toBe("social");
    expect(result.tieBreakerLevel).toBe(2);
  });
});

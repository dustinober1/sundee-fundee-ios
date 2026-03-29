import { describe, it, expect } from "vitest";
import {
  STANDARD_BARBELL_KG,
  WOMENS_BARBELL_KG,
  AVAILABLE_PLATES,
  platesPerSide,
  plateDescription,
} from "../plate-calculation";

describe("constants", () => {
  it("standard barbell is 20 kg", () => {
    expect(STANDARD_BARBELL_KG).toBe(20);
  });
  it("women's barbell is 15 kg", () => {
    expect(WOMENS_BARBELL_KG).toBe(15);
  });
  it("available plates are correct", () => {
    expect(AVAILABLE_PLATES).toEqual([25, 20, 15, 10, 5, 2.5, 1.25]);
  });
});

describe("platesPerSide", () => {
  it("returns empty for barbell-only weight", () => {
    expect(platesPerSide(20, 20)).toEqual([]);
  });

  it("returns empty when total is less than barbell weight", () => {
    expect(platesPerSide(15, 20)).toEqual([]);
  });

  it("calculates plates for 60 kg (20 kg barbell): 2×20 per side", () => {
    // (60 - 20) / 2 = 20 per side → 1×20
    expect(platesPerSide(60, STANDARD_BARBELL_KG)).toEqual([
      { weight: 20, count: 1 },
    ]);
  });

  it("calculates plates for 100 kg (20 kg barbell): 40 per side → 1×25 + 1×15", () => {
    // (100 - 20) / 2 = 40 per side
    // greedy: 40 / 25 = 1, remainder 15
    // 15 / 15 = 1
    expect(platesPerSide(100, STANDARD_BARBELL_KG)).toEqual([
      { weight: 25, count: 1 },
      { weight: 15, count: 1 },
    ]);
  });

  it("calculates plates for 140 kg (20 kg barbell): 60 per side → 2×25 + 1×10", () => {
    // (140 - 20) / 2 = 60 per side
    // 60 / 25 = 2 → remainder 10
    // 10 / 10 = 1
    expect(platesPerSide(140, STANDARD_BARBELL_KG)).toEqual([
      { weight: 25, count: 2 },
      { weight: 10, count: 1 },
    ]);
  });

  it("handles women's barbell", () => {
    // (65 - 15) / 2 = 25 per side → 1×25
    expect(platesPerSide(65, WOMENS_BARBELL_KG)).toEqual([
      { weight: 25, count: 1 },
    ]);
  });

  it("handles fractional plates (2.5 kg)", () => {
    // (25 - 20) / 2 = 2.5 per side → 1×2.5
    expect(platesPerSide(25, STANDARD_BARBELL_KG)).toEqual([
      { weight: 2.5, count: 1 },
    ]);
  });

  it("handles 1.25 kg plates", () => {
    // (22.5 - 20) / 2 = 1.25 per side → 1×1.25
    expect(platesPerSide(22.5, STANDARD_BARBELL_KG)).toEqual([
      { weight: 1.25, count: 1 },
    ]);
  });

  it("handles 0 total weight", () => {
    expect(platesPerSide(0, 20)).toEqual([]);
  });

  it("calculates a complex load: 102.5 kg (20 kg barbell)", () => {
    // (102.5 - 20) / 2 = 41.25 per side
    // 41.25 / 25 = 1, remainder 16.25
    // 16.25 / 15 = 1, remainder 1.25
    // 1.25 / 1.25 = 1
    expect(platesPerSide(102.5, STANDARD_BARBELL_KG)).toEqual([
      { weight: 25, count: 1 },
      { weight: 15, count: 1 },
      { weight: 1.25, count: 1 },
    ]);
  });
});

describe("plateDescription", () => {
  it("returns 'Barbell only' when no plates needed", () => {
    expect(plateDescription(20, 20)).toBe("Barbell only");
  });

  it("returns 'Barbell only' when total < barbell weight", () => {
    expect(plateDescription(10, 20)).toBe("Barbell only");
  });

  it("describes single plate type", () => {
    // 60 kg, 20 kg barbell → 1×20 per side
    expect(plateDescription(60, STANDARD_BARBELL_KG)).toBe("1×20 per side");
  });

  it("describes multiple plate types with + separator", () => {
    // 140 kg: 2×25 + 1×10 per side
    expect(plateDescription(140, STANDARD_BARBELL_KG)).toBe("2×25 + 1×10 per side");
  });

  it("describes fractional plates", () => {
    // 25 kg: 1×2.5 per side
    expect(plateDescription(25, STANDARD_BARBELL_KG)).toBe("1×2.5 per side");
  });
});

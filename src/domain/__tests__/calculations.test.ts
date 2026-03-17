import epleyFixtures from '../__fixtures__/epley-formula.json';
import weightFixtures from '../__fixtures__/weight-calculations.json';

// ---------------------------------------------------------------------------
// Import implementations (will fail until implemented)
// ---------------------------------------------------------------------------
import {
  estimated1RM,
  isPR,
  roundToNearestFive,
  snapBarbellWeightLb,
  snapBarbellWeightKg,
  snapDumbbellWeightLb,
  snapKettlebellWeightLb,
  calculateTargetWeight,
  isPersonalRecord,
  calculateVolumeLoad,
  detectPlateau,
  lbToKg,
  kgToLb,
  POUNDS_PER_KG,
  valueFromKilograms,
  kilogramsFrom,
  platesPerSideLb,
  platesPerSideKg,
  STANDARD_BAR_LB,
  WOMEN_BAR_LB,
  STANDARD_BAR_KG,
  WOMEN_BAR_KG,
  AVAILABLE_PLATES_LB,
  AVAILABLE_PLATES_KG,
  AVAILABLE_DUMBBELL_WEIGHTS_LB,
  AVAILABLE_KETTLEBELL_WEIGHTS_LB,
  barbellPresets,
  suggestedPresetName,
} from '../calculations';

// ---------------------------------------------------------------------------
// Epley Formula — fixture-driven parity tests
// ---------------------------------------------------------------------------

describe('estimated1RM', () => {
  test.each(epleyFixtures.cases)(
    'weight=$weight reps=$reps → $expected1RM',
    ({ weight, reps, expected1RM: expected }) => {
      expect(estimated1RM(weight, reps)).toBeCloseTo(expected, 4);
    }
  );

  test('reps=1 returns weight unchanged', () => {
    expect(estimated1RM(100, 1)).toBe(100);
    expect(estimated1RM(315, 1)).toBe(315);
  });

  test('reps=0 returns weight unchanged (guard <=1)', () => {
    expect(estimated1RM(100, 0)).toBe(100);
  });

  test('weight=0 returns 0', () => {
    expect(estimated1RM(0, 5)).toBe(0);
  });

  test('large reps produces large estimate', () => {
    const result = estimated1RM(100, 30);
    expect(result).toBeCloseTo(200, 4);
  });
});

describe('isPR', () => {
  test('new estimate greater than current max → true', () => {
    expect(isPR(120, 100)).toBe(true);
  });

  test('new estimate less than current max → false', () => {
    expect(isPR(80, 100)).toBe(false);
  });

  test('new estimate equal to current max → false', () => {
    expect(isPR(100, 100)).toBe(false);
  });

  test('undefined currentMax → true (first ever lift)', () => {
    expect(isPR(100, undefined)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// roundToNearestFive
// ---------------------------------------------------------------------------

describe('roundToNearestFive', () => {
  test.each(weightFixtures.roundToNearestFive)(
    'input=$input → $expected',
    ({ input, expected }) => {
      expect(roundToNearestFive(input)).toBe(expected);
    }
  );
});

// ---------------------------------------------------------------------------
// snapBarbellWeightLb
// ---------------------------------------------------------------------------

describe('snapBarbellWeightLb', () => {
  test.each(weightFixtures.snapBarbellWeightLb)(
    'lb=$lb barLb=$barLb → $expected',
    ({ lb, barLb, expected }) => {
      expect(snapBarbellWeightLb(lb, barLb)).toBe(expected);
    }
  );

  test('default barLb is 45', () => {
    expect(snapBarbellWeightLb(135)).toBe(135);
  });

  test('weight below bar weight returns bar weight', () => {
    expect(snapBarbellWeightLb(20, 45)).toBe(45);
  });
});

// ---------------------------------------------------------------------------
// snapBarbellWeightKg
// ---------------------------------------------------------------------------

describe('snapBarbellWeightKg', () => {
  test('snaps to nearest 2.5 kg increment above bar weight', () => {
    // bar=20kg, plateLoad should snap in 2.5kg increments per side (5kg total)
    expect(snapBarbellWeightKg(60, 20)).toBe(60);
    expect(snapBarbellWeightKg(62, 20)).toBe(60);
    expect(snapBarbellWeightKg(63, 20)).toBe(65);
  });

  test('weight below bar returns bar weight', () => {
    expect(snapBarbellWeightKg(10, 20)).toBe(20);
  });
});

// ---------------------------------------------------------------------------
// Dumbbell / Kettlebell snapping
// ---------------------------------------------------------------------------

describe('snapDumbbellWeightLb', () => {
  test('snaps to nearest available dumbbell weight', () => {
    expect(snapDumbbellWeightLb(12)).toBe(10);
    expect(snapDumbbellWeightLb(13)).toBe(15);
    expect(snapDumbbellWeightLb(22)).toBe(20);
    expect(snapDumbbellWeightLb(27)).toBe(25);
    // 60 is equidistant between 50 and 70; first match wins (50)
    expect(snapDumbbellWeightLb(60)).toBe(50);
    expect(snapDumbbellWeightLb(61)).toBe(70);
  });
});

describe('snapKettlebellWeightLb', () => {
  test('snaps to nearest available kettlebell weight', () => {
    // 20 is equidistant between 15 and 25; Swift min(by:) picks first (15)
    expect(snapKettlebellWeightLb(20)).toBe(15);
    expect(snapKettlebellWeightLb(18)).toBe(15);
    expect(snapKettlebellWeightLb(40)).toBe(32);
    expect(snapKettlebellWeightLb(60)).toBe(53);
    expect(snapKettlebellWeightLb(22)).toBe(25);
  });
});

// ---------------------------------------------------------------------------
// calculateTargetWeight
// ---------------------------------------------------------------------------

describe('calculateTargetWeight', () => {
  test('rounds oneRepMax * percentage to nearest 5', () => {
    expect(calculateTargetWeight(100, 0.75)).toBe(75);
    expect(calculateTargetWeight(100, 0.80)).toBe(80);
    expect(calculateTargetWeight(133, 0.70)).toBe(95);
  });
});

// ---------------------------------------------------------------------------
// isPersonalRecord
// ---------------------------------------------------------------------------

describe('isPersonalRecord', () => {
  test.each(weightFixtures.isPersonalRecord)(
    'weight=$weight previousMax=$previousMax → $expected',
    ({ weight, previousMax, expected }) => {
      expect(isPersonalRecord(weight, previousMax)).toBe(expected);
    }
  );
});

// ---------------------------------------------------------------------------
// calculateVolumeLoad
// ---------------------------------------------------------------------------

describe('calculateVolumeLoad', () => {
  test('multiplies weight × reps × sets', () => {
    expect(calculateVolumeLoad(100, 5, 3)).toBe(1500);
    expect(calculateVolumeLoad(50, 10, 4)).toBe(2000);
    expect(calculateVolumeLoad(0, 5, 3)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// detectPlateau
// ---------------------------------------------------------------------------

describe('detectPlateau', () => {
  test('returns false with fewer than 3 weights', () => {
    expect(detectPlateau([])).toBe(false);
    expect(detectPlateau([100])).toBe(false);
    expect(detectPlateau([100, 105])).toBe(false);
  });

  test('returns true when last 3 weights differ by < 5', () => {
    expect(detectPlateau([90, 100, 100, 102])).toBe(true);
  });

  test('returns false when last 3 weights have spread >= 5', () => {
    expect(detectPlateau([100, 105, 110])).toBe(false);
    expect(detectPlateau([80, 100, 105, 110])).toBe(false);
  });

  test('exactly 5 difference is not a plateau', () => {
    expect(detectPlateau([100, 100, 105])).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Weight unit conversion
// ---------------------------------------------------------------------------

describe('lbToKg', () => {
  test('100 lb → ~45.3592 kg', () => {
    expect(lbToKg(100)).toBeCloseTo(45.3592, 4);
  });

  test('0 lb → 0 kg', () => {
    expect(lbToKg(0)).toBe(0);
  });

  test('POUNDS_PER_KG constant is 2.2046226218', () => {
    expect(POUNDS_PER_KG).toBe(2.2046226218);
  });

  test('roundtrip: kgToLb(lbToKg(x)) ≈ x', () => {
    expect(kgToLb(lbToKg(135))).toBeCloseTo(135, 4);
  });
});

describe('kgToLb', () => {
  test('100 kg → ~220.4623 lb', () => {
    expect(kgToLb(100)).toBeCloseTo(220.4623, 4);
  });

  test('0 kg → 0 lb', () => {
    expect(kgToLb(0)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// Plate calculation
// ---------------------------------------------------------------------------

describe('platesPerSideLb', () => {
  test('225 lb with 45 lb bar → [45×2] per side', () => {
    const result = platesPerSideLb(225, 45);
    expect(result).toEqual([{ weight: 45, count: 2 }]);
  });

  test('135 lb with 45 lb bar → [45×1] per side', () => {
    const result = platesPerSideLb(135, 45);
    expect(result).toEqual([{ weight: 45, count: 1 }]);
  });

  test('bar-only (weight <= bar) → empty array', () => {
    const result = platesPerSideLb(45, 45);
    expect(result).toEqual([]);
  });

  test('weight below bar → empty array', () => {
    const result = platesPerSideLb(30, 45);
    expect(result).toEqual([]);
  });

  test('315 lb with 45 lb bar → [45×3] per side', () => {
    const result = platesPerSideLb(315, 45);
    expect(result).toEqual([{ weight: 45, count: 3 }]);
  });

  test('155 lb with 45 lb bar → [45×1, 10×1] per side', () => {
    const result = platesPerSideLb(155, 45);
    expect(result).toEqual([
      { weight: 45, count: 1 },
      { weight: 10, count: 1 },
    ]);
  });

  test('uses default bar weight of 45 lb', () => {
    expect(platesPerSideLb(135)).toEqual([{ weight: 45, count: 1 }]);
  });
});

describe('platesPerSideKg', () => {
  test('bar-only → empty array', () => {
    const barKg = STANDARD_BAR_KG;
    expect(platesPerSideKg(barKg, barKg)).toEqual([]);
  });

  test('plate list is in lb-equivalent denominations converted to kg', () => {
    expect(AVAILABLE_PLATES_KG.length).toBe(AVAILABLE_PLATES_LB.length);
  });
});

// ---------------------------------------------------------------------------
// Barbell defaults
// ---------------------------------------------------------------------------

describe('barbellPresets', () => {
  test('has at least 4 presets', () => {
    expect(barbellPresets.length).toBeGreaterThanOrEqual(4);
  });

  test('Standard preset exists with correct weight (~20.4 kg)', () => {
    const standard = barbellPresets.find((p) => p.name === 'Standard');
    expect(standard).toBeDefined();
    expect(standard!.weightKg).toBeCloseTo(45 / POUNDS_PER_KG, 4);
  });

  test("Women's preset exists with correct weight (~15.9 kg)", () => {
    const womens = barbellPresets.find((p) => p.name === "Women's");
    expect(womens).toBeDefined();
    expect(womens!.weightKg).toBeCloseTo(35 / POUNDS_PER_KG, 4);
  });

  test('presets have sortOrder', () => {
    barbellPresets.forEach((p) => {
      expect(typeof p.sortOrder).toBe('number');
    });
  });
});

describe('suggestedPresetName', () => {
  test('curl exercise → EZ Curl', () => {
    expect(suggestedPresetName('Barbell Curl', undefined)).toBe('EZ Curl');
    expect(suggestedPresetName('tricep extension', undefined)).toBe('EZ Curl');
    expect(suggestedPresetName('skull crush', undefined)).toBe('EZ Curl');
  });

  test("compound + female gender → Women's", () => {
    expect(suggestedPresetName('Back Squat', 'female')).toBe("Women's");
    expect(suggestedPresetName('Bench Press', 'female')).toBe("Women's");
    expect(suggestedPresetName('Deadlift', 'female')).toBe("Women's");
  });

  test('compound + non-female → Standard', () => {
    expect(suggestedPresetName('Back Squat', 'male')).toBe('Standard');
    expect(suggestedPresetName('Overhead Press', undefined)).toBe('Standard');
    expect(suggestedPresetName('barbell row', undefined)).toBe('Standard');
  });

  test('unknown exercise → Standard regardless of gender', () => {
    expect(suggestedPresetName('Lunges', undefined)).toBe('Standard');
    // Calf Raises does not match any compound keyword → Standard regardless of gender
    expect(suggestedPresetName('Calf Raises', 'female')).toBe('Standard');
    expect(suggestedPresetName('Calf Raises', undefined)).toBe('Standard');
  });
});

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

describe('constants', () => {
  test('STANDARD_BAR_LB is 45', () => {
    expect(STANDARD_BAR_LB).toBe(45);
  });

  test('WOMEN_BAR_LB is 35', () => {
    expect(WOMEN_BAR_LB).toBe(35);
  });

  test('STANDARD_BAR_KG ≈ 20.41 kg', () => {
    expect(STANDARD_BAR_KG).toBeCloseTo(45 / POUNDS_PER_KG, 4);
  });

  test('WOMEN_BAR_KG ≈ 15.88 kg', () => {
    expect(WOMEN_BAR_KG).toBeCloseTo(35 / POUNDS_PER_KG, 4);
  });

  test('AVAILABLE_PLATES_LB is [45, 25, 15, 10, 5, 2.5]', () => {
    expect(AVAILABLE_PLATES_LB).toEqual([45, 25, 15, 10, 5, 2.5]);
  });

  test('AVAILABLE_DUMBBELL_WEIGHTS_LB contains expected values', () => {
    expect(AVAILABLE_DUMBBELL_WEIGHTS_LB).toContain(10);
    expect(AVAILABLE_DUMBBELL_WEIGHTS_LB).toContain(50);
  });

  test('AVAILABLE_KETTLEBELL_WEIGHTS_LB contains expected values', () => {
    expect(AVAILABLE_KETTLEBELL_WEIGHTS_LB).toContain(15);
    expect(AVAILABLE_KETTLEBELL_WEIGHTS_LB).toContain(53);
  });
});

// ---------------------------------------------------------------------------
// valueFromKilograms / kilogramsFrom
// ---------------------------------------------------------------------------

describe('valueFromKilograms', () => {
  test('kg unit returns value unchanged', () => {
    expect(valueFromKilograms(100, 'kg')).toBe(100);
  });

  test('lb unit converts kg → lb', () => {
    expect(valueFromKilograms(1, 'lb')).toBeCloseTo(POUNDS_PER_KG, 4);
  });
});

describe('kilogramsFrom', () => {
  test('kg unit returns value unchanged', () => {
    expect(kilogramsFrom(100, 'kg')).toBe(100);
  });

  test('lb unit converts lb → kg', () => {
    expect(kilogramsFrom(POUNDS_PER_KG, 'lb')).toBeCloseTo(1, 4);
  });
});

// ---------------------------------------------------------------------------
// platesPerSideKg — with actual plate data
// ---------------------------------------------------------------------------

describe('platesPerSideKg extended', () => {
  test('100 kg total with ~20.4 kg bar → plates per side', () => {
    // (100 - 20.41) / 2 ≈ 39.79 kg per side
    // 45 lb plate in kg ≈ 20.41, 1 plate per side used, then 25 lb ≈ 11.34 per side
    const result = platesPerSideKg(100);
    expect(result.length).toBeGreaterThan(0);
    // total should be reasonable
    const totalPerSide = result.reduce((sum, p) => sum + p.weight * p.count, 0);
    expect(totalPerSide).toBeGreaterThan(0);
  });

  test('weight slightly above bar → small plate load', () => {
    const barKg = STANDARD_BAR_KG;
    // Add 2× smallest plate (2.5 lb in kg per side = 5 lb in kg total)
    const smallestPlateKg = AVAILABLE_PLATES_KG[AVAILABLE_PLATES_KG.length - 1];
    const total = barKg + smallestPlateKg * 2;
    const result = platesPerSideKg(total, barKg);
    expect(result).toEqual([{ weight: smallestPlateKg, count: 1 }]);
  });
});

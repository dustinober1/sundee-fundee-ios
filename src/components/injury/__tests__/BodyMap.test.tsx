/**
 * BodyMap.test.tsx
 *
 * Tests for the BodyMap component — primarily the static locationLabel helper.
 */

import { BodyMap } from '../BodyMap';
import type { BodyLocation } from '@/src/domain/types/index';

describe('BodyMap.locationLabel', () => {
  const cases: Array<[BodyLocation, string]> = [
    ['head', 'Head'],
    ['neck', 'Neck'],
    ['leftShoulder', 'Left Shoulder'],
    ['rightShoulder', 'Right Shoulder'],
    ['chest', 'Chest'],
    ['upperBack', 'Upper Back'],
    ['lowerBack', 'Lower Back'],
    ['leftElbow', 'Left Elbow'],
    ['rightElbow', 'Right Elbow'],
    ['leftWrist', 'Left Wrist'],
    ['rightWrist', 'Right Wrist'],
    ['leftHip', 'Left Hip'],
    ['rightHip', 'Right Hip'],
    ['leftKnee', 'Left Knee'],
    ['rightKnee', 'Right Knee'],
    ['leftAnkle', 'Left Ankle'],
    ['rightAnkle', 'Right Ankle'],
  ];

  test.each(cases)('locationLabel(%s) returns %s', (location, expected) => {
    expect(BodyMap.locationLabel(location)).toBe(expected);
  });

  it('returns a non-empty string for every BodyLocation value', () => {
    const allLocations: BodyLocation[] = [
      'head', 'neck', 'leftShoulder', 'rightShoulder', 'chest',
      'upperBack', 'lowerBack', 'leftElbow', 'rightElbow',
      'leftWrist', 'rightWrist', 'leftHip', 'rightHip',
      'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle',
    ];
    for (const loc of allLocations) {
      const label = BodyMap.locationLabel(loc);
      expect(typeof label).toBe('string');
      expect(label.length).toBeGreaterThan(0);
    }
  });
});

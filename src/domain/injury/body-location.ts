/**
 * body-location.ts
 * Helper functions for the BodyLocation type.
 * The BodyLocation union type is defined in src/domain/types/index.ts.
 */

import { BodyLocation, BodyLocationEngineKey } from '../types';

/**
 * All valid body location values (matches Swift BodyLocation.Region.allCases).
 */
export const BODY_LOCATIONS: BodyLocation[] = [
  'head',
  'neck',
  'leftShoulder',
  'rightShoulder',
  'chest',
  'upperBack',
  'lowerBack',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

/**
 * Human-readable display name matching Swift BodyLocation.Region.displayName.
 */
export function bodyLocationDisplayName(location: BodyLocation): string {
  const names: Record<BodyLocation, string> = {
    head: 'Head',
    neck: 'Neck',
    leftShoulder: 'Left Shoulder',
    rightShoulder: 'Right Shoulder',
    chest: 'Chest',
    upperBack: 'Upper Back',
    lowerBack: 'Lower Back',
    leftElbow: 'Left Elbow',
    rightElbow: 'Right Elbow',
    leftWrist: 'Left Wrist',
    rightWrist: 'Right Wrist',
    leftHip: 'Left Hip',
    rightHip: 'Right Hip',
    leftKnee: 'Left Knee',
    rightKnee: 'Right Knee',
    leftAnkle: 'Left Ankle',
    rightAnkle: 'Right Ankle',
  };
  return names[location];
}

/**
 * Maps a BodyLocation to the engine's contraindication key.
 * Matches Swift BodyLocation.Region.engineKey.
 */
export function bodyLocationEngineKeyFromRegion(location: BodyLocation): BodyLocationEngineKey {
  switch (location) {
    case 'head':
    case 'neck':
    case 'upperBack':
    case 'lowerBack':
      return 'back';
    case 'leftShoulder':
    case 'rightShoulder':
    case 'chest':
      return 'shoulder';
    case 'leftElbow':
    case 'rightElbow':
    case 'leftWrist':
    case 'rightWrist':
      return 'wrist';
    case 'leftHip':
    case 'rightHip':
      return 'hip';
    case 'leftKnee':
    case 'rightKnee':
      return 'knee';
    case 'leftAnkle':
    case 'rightAnkle':
      return 'ankle';
  }
}

/**
 * Parses a comma-separated raw string into an array of BodyLocation values.
 * Unknown values are silently dropped (matches Swift compactMap behaviour).
 */
export function parseRegions(raw: string): BodyLocation[] {
  return raw
    .split(',')
    .map(s => s.trim())
    .filter((s): s is BodyLocation => (BODY_LOCATIONS as string[]).includes(s));
}

/**
 * Encodes an array of BodyLocation values to a comma-separated raw string.
 */
export function encodeRegions(regions: BodyLocation[]): string {
  return regions.join(',');
}

/**
 * Mock for expo-audio.
 * useWorkoutTimer imports createAudioPlayer and calls player.play().
 */
export const createAudioPlayer = jest.fn().mockReturnValue({
  play: jest.fn(),
  pause: jest.fn(),
  stop: jest.fn(),
  remove: jest.fn(),
});

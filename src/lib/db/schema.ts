export interface DatabaseSchema {
  users: {
    key: string;
    indexes: { 'ByName': string };
  };
  oneRepMaxes: {
    key: string;
    indexes: { 'ByUserId': string; 'ByExerciseId': string; 'ByDate': Date };
  };
  activeCycles: {
    key: string;
    indexes: { 'ByUserId': string; 'ByProgramId': string; 'ByStatus': string };
  };
  completedWorkouts: {
    key: string;
    indexes: { 'ByUserId': string; 'ByActiveCycleId': string; 'ByCompletedAt': Date };
  };
  completedSets: {
    key: string;
    indexes: { 'ByWorkoutId': string; 'ByExerciseId': string };
  };
  setMetrics: {
    key: string;
    indexes: { 'BySetId': string };
  };
}

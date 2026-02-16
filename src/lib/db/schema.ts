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
    indexes: {
      'ByUserId': string;
      'ByProgramId': string;
      'ByStatus': string;
      'ByCurrentPhase': string;
      'ByCurrentSessionId': string;
    };
  };
  completedWorkouts: {
    key: string;
    indexes: {
      'ByUserId': string;
      'ByActiveCycleId': string;
      'BySessionId': string;
      'ByCompletedAt': Date;
    };
  };
  completedSets: {
    key: string;
    indexes: { 'ByWorkoutId': string; 'ByExerciseId': string };
  };
  setMetrics: {
    key: string;
    indexes: { 'BySetId': string };
  };
  periodLogs: {
    key: string;
    indexes: { 'ByUserId': string; 'ByStartDate': Date };
  };
  symptomLogs: {
    key: string;
    indexes: { 'ByUserId': string; 'ByDate': Date };
  };
  bbtLogs: {
    key: string;
    indexes: { 'ByUserId': string; 'ByDate': Date };
  };
  symptomDefinitions: {
    key: string;
    indexes: { 'ByCategory': string };
  };
  cycleSettings: {
    key: string;
    indexes: { 'ByUserId': string };
  };
  programs: {
    key: string;
    indexes: { 'ByCategory': string; 'ByDifficulty': string };
  };
  userProgramPreferences: {
    key: string;
    indexes: { 'ByUserId': string; 'ByProgramId': string; 'ByUserProgram': string };
  };
}

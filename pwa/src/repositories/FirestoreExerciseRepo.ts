import { doc, setDoc, getDocs, deleteDoc, collection } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { Exercise } from '../domain/exercises/exercise-types';
import type { ExerciseRepository } from './ExerciseRepo';

export class FirestoreExerciseRepo implements ExerciseRepository {
  async getCustomExercises(uid: string): Promise<Exercise[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'customExercises'));
    return snapshot.docs.map((d) => d.data() as Exercise);
  }

  async saveCustomExercise(uid: string, exercise: Exercise): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'customExercises', exercise.id), exercise);
  }

  async deleteCustomExercise(uid: string, exerciseId: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'customExercises', exerciseId));
  }
}

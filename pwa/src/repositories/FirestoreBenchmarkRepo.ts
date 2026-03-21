import { doc, setDoc, getDocs, deleteDoc, collection, query, where } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { BenchmarkDefinition } from '../domain/types/index';
import type { BenchmarkResultRecord, BenchmarkRepository } from './BenchmarkRepo';

export class FirestoreBenchmarkRepo implements BenchmarkRepository {
  async saveResult(uid: string, result: BenchmarkResultRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'benchmarkResults', result.id), result);
  }

  async getResults(uid: string, benchmarkId: string): Promise<BenchmarkResultRecord[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'benchmarkResults'),
      where('benchmarkId', '==', benchmarkId),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as BenchmarkResultRecord);
  }

  async getAllResults(uid: string): Promise<BenchmarkResultRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'benchmarkResults'));
    return snapshot.docs.map((d) => d.data() as BenchmarkResultRecord);
  }

  async saveCustomBenchmark(uid: string, definition: BenchmarkDefinition): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'customBenchmarks', definition.id), definition);
  }

  async getCustomBenchmarks(uid: string): Promise<BenchmarkDefinition[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'customBenchmarks'));
    return snapshot.docs.map((d) => d.data() as BenchmarkDefinition);
  }

  async deleteCustomBenchmark(uid: string, benchmarkId: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'customBenchmarks', benchmarkId));
  }
}

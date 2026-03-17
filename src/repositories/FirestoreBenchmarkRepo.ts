/**
 * FirestoreBenchmarkRepo — Firestore implementation of BenchmarkRepository.
 *
 * Stores benchmark results at /users/{uid}/benchmarkResults/{resultId}.
 * Stores custom benchmark definitions at /users/{uid}/customBenchmarks/{benchmarkId}.
 * Results are ordered by date descending for display.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { BenchmarkDefinition } from '../domain/types/index';
import type { BenchmarkRepository, BenchmarkResultRecord } from './BenchmarkRepo';

export class FirestoreBenchmarkRepo implements BenchmarkRepository {
  /**
   * Saves (upserts) a benchmark result to /users/{uid}/benchmarkResults/{resultId}.
   */
  async saveResult(uid: string, result: BenchmarkResultRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('benchmarkResults')
      .doc(result.id)
      .set(result);
  }

  /**
   * Retrieves all results for a specific benchmark, ordered by date descending.
   */
  async getResults(uid: string, benchmarkId: string): Promise<BenchmarkResultRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('benchmarkResults')
      .where('benchmarkId', '==', benchmarkId)
      .orderBy('date', 'desc')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => BenchmarkResultRecord }) => doc.data() as BenchmarkResultRecord
    );
  }

  /**
   * Retrieves all benchmark results for a user, ordered by date descending.
   */
  async getAllResults(uid: string): Promise<BenchmarkResultRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('benchmarkResults')
      .orderBy('date', 'desc')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => BenchmarkResultRecord }) => doc.data() as BenchmarkResultRecord
    );
  }

  /**
   * Saves (upserts) a custom benchmark definition to /users/{uid}/customBenchmarks/{benchmarkId}.
   */
  async saveCustomBenchmark(uid: string, definition: BenchmarkDefinition): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('customBenchmarks')
      .doc(definition.id)
      .set(definition);
  }

  /**
   * Retrieves all custom benchmark definitions for a user.
   */
  async getCustomBenchmarks(uid: string): Promise<BenchmarkDefinition[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('customBenchmarks')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => BenchmarkDefinition }) => doc.data() as BenchmarkDefinition
    );
  }

  /**
   * Deletes a custom benchmark definition by its document ID.
   */
  async deleteCustomBenchmark(uid: string, benchmarkId: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('customBenchmarks')
      .doc(benchmarkId)
      .delete();
  }
}

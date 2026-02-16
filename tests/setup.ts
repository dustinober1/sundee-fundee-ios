import '@testing-library/jest-dom/vitest'
import { vi } from 'vitest'

// Mock IndexedDB for tests
vi.stubGlobal('indexedDB', {})

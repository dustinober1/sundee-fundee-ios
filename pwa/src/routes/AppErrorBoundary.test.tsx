/**
 * Tests for AppErrorBoundary
 * Uses mocked useRouteError / isRouteErrorResponse to simulate React Router error boundary context.
 */
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router';

vi.mock('react-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('react-router')>();
  return {
    ...actual,
    useRouteError: vi.fn(),
    isRouteErrorResponse: vi.fn(),
  };
});

import { useRouteError, isRouteErrorResponse } from 'react-router';
import { AppErrorBoundary } from './AppErrorBoundary';

const mockUseRouteError = useRouteError as ReturnType<typeof vi.fn>;
const mockIsRouteErrorResponse = isRouteErrorResponse as ReturnType<typeof vi.fn>;

describe('AppErrorBoundary', () => {
  beforeEach(() => {
    mockIsRouteErrorResponse.mockReturnValue(false);
  });

  it('renders "Something went wrong" heading', () => {
    mockUseRouteError.mockReturnValue(new Error('test error'));
    render(
      <MemoryRouter>
        <AppErrorBoundary />
      </MemoryRouter>
    );
    expect(screen.getByRole('heading', { name: /something went wrong/i })).toBeInTheDocument();
  });

  it('renders a "Back to Dashboard" link pointing to "/"', () => {
    mockUseRouteError.mockReturnValue(new Error('test error'));
    render(
      <MemoryRouter>
        <AppErrorBoundary />
      </MemoryRouter>
    );
    const link = screen.getByRole('link', { name: /back to dashboard/i });
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute('href', '/');
  });

  it('displays error message from useRouteError', () => {
    mockUseRouteError.mockReturnValue(new Error('app-level crash'));
    render(
      <MemoryRouter>
        <AppErrorBoundary />
      </MemoryRouter>
    );
    expect(screen.getByText('app-level crash')).toBeInTheDocument();
  });

  it('displays status and statusText for a route error response', () => {
    mockIsRouteErrorResponse.mockReturnValue(true);
    mockUseRouteError.mockReturnValue({ status: 403, statusText: 'Forbidden' });
    render(
      <MemoryRouter>
        <AppErrorBoundary />
      </MemoryRouter>
    );
    expect(screen.getByText('403 Forbidden')).toBeInTheDocument();
  });

  it('displays fallback message for unknown error type', () => {
    mockUseRouteError.mockReturnValue(null);
    render(
      <MemoryRouter>
        <AppErrorBoundary />
      </MemoryRouter>
    );
    expect(screen.getByText('An unexpected error occurred.')).toBeInTheDocument();
  });
});

/**
 * Tests for RootErrorBoundary
 * Uses mocked useRouteError / isRouteErrorResponse to simulate React Router error boundary context.
 */
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('react-router', () => ({
  useRouteError: vi.fn(),
  isRouteErrorResponse: vi.fn(),
}));

import { useRouteError, isRouteErrorResponse } from 'react-router';
import { RootErrorBoundary } from './RootErrorBoundary';

const mockUseRouteError = useRouteError as ReturnType<typeof vi.fn>;
const mockIsRouteErrorResponse = isRouteErrorResponse as ReturnType<typeof vi.fn>;

describe('RootErrorBoundary', () => {
  beforeEach(() => {
    mockIsRouteErrorResponse.mockReturnValue(false);
  });

  it('renders "Something went wrong" heading', () => {
    mockUseRouteError.mockReturnValue(new Error('test error'));
    render(<RootErrorBoundary />);
    expect(screen.getByRole('heading', { name: /something went wrong/i })).toBeInTheDocument();
  });

  it('renders a Reload App link pointing to "/"', () => {
    mockUseRouteError.mockReturnValue(new Error('test error'));
    render(<RootErrorBoundary />);
    const link = screen.getByRole('link', { name: /reload app/i });
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute('href', '/');
  });

  it('displays the error message when error is an Error instance', () => {
    mockUseRouteError.mockReturnValue(new Error('something exploded'));
    render(<RootErrorBoundary />);
    expect(screen.getByText('something exploded')).toBeInTheDocument();
  });

  it('displays status and statusText for a route error response', () => {
    mockIsRouteErrorResponse.mockReturnValue(true);
    mockUseRouteError.mockReturnValue({ status: 404, statusText: 'Not Found' });
    render(<RootErrorBoundary />);
    expect(screen.getByText('404 Not Found')).toBeInTheDocument();
  });

  it('displays fallback message for unknown error type', () => {
    mockUseRouteError.mockReturnValue('some string error');
    render(<RootErrorBoundary />);
    expect(screen.getByText('An unexpected error occurred.')).toBeInTheDocument();
  });
});

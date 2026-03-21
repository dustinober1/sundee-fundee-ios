/**
 * Component tests for SignIn screen.
 * Covers: email sign-in, email sign-up, Google sign-in, guest sign-in,
 * error display, and button disable during loading.
 */
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock react-router — must come before component import
vi.mock('react-router', () => ({
  useNavigate: vi.fn(),
}));

// Mock Firebase auth module
vi.mock('../firebase/auth', () => ({
  signInWithEmailAndPassword: vi.fn(),
  createUserWithEmailAndPassword: vi.fn(),
  sendEmailVerification: vi.fn(),
  signInAnonymously: vi.fn(),
  signInWithGoogle: vi.fn(),
  signInWithApple: vi.fn(),
}));

import { useNavigate } from 'react-router';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendEmailVerification,
  signInAnonymously,
  signInWithGoogle,
} from '../firebase/auth';
import { SignIn } from './SignIn';

const mockNavigate = vi.fn();

const fakeUser = {
  uid: 'test-uid',
  email: 'test@example.com',
  emailVerified: true,
  isAnonymous: false,
};

beforeEach(() => {
  vi.clearAllMocks();
  (useNavigate as ReturnType<typeof vi.fn>).mockReturnValue(mockNavigate);
  (signInWithEmailAndPassword as ReturnType<typeof vi.fn>).mockResolvedValue(fakeUser);
  (createUserWithEmailAndPassword as ReturnType<typeof vi.fn>).mockResolvedValue(fakeUser);
  (sendEmailVerification as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);
  (signInAnonymously as ReturnType<typeof vi.fn>).mockResolvedValue(fakeUser);
  (signInWithGoogle as ReturnType<typeof vi.fn>).mockResolvedValue(fakeUser);
});

describe('SignIn', () => {
  it('renders sign-in form with email, password, social, and guest buttons', () => {
    render(<SignIn />);

    expect(screen.getByPlaceholderText('Email')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Password')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /continue with google/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /continue with apple/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /continue as guest/i })).toBeInTheDocument();
  });

  it('email sign-in success: calls signInWithEmailAndPassword and navigates to /', async () => {
    render(<SignIn />);

    fireEvent.change(screen.getByPlaceholderText('Email'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'password123' },
    });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(signInWithEmailAndPassword).toHaveBeenCalledWith(
        'test@example.com',
        'password123',
      );
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });

  it('email sign-up success: calls createUserWithEmailAndPassword and navigates to /verify-email', async () => {
    render(<SignIn />);

    // Switch to sign-up mode
    fireEvent.click(screen.getByRole('button', { name: /don't have an account/i }));

    fireEvent.change(screen.getByPlaceholderText('Email'), {
      target: { value: 'new@example.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'newpassword' },
    });
    fireEvent.click(screen.getByRole('button', { name: /create account/i }));

    await waitFor(() => {
      expect(createUserWithEmailAndPassword).toHaveBeenCalledWith(
        'new@example.com',
        'newpassword',
      );
      expect(mockNavigate).toHaveBeenCalledWith('/verify-email');
    });
  });

  it('Google sign-in success: calls signInWithGoogle and navigates to /', async () => {
    render(<SignIn />);

    fireEvent.click(screen.getByRole('button', { name: /continue with google/i }));

    await waitFor(() => {
      expect(signInWithGoogle).toHaveBeenCalled();
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });

  it('guest sign-in success: calls signInAnonymously and navigates to /', async () => {
    render(<SignIn />);

    fireEvent.click(screen.getByRole('button', { name: /continue as guest/i }));

    await waitFor(() => {
      expect(signInAnonymously).toHaveBeenCalled();
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });

  it('shows error message on auth failure (wrong password)', async () => {
    (signInWithEmailAndPassword as ReturnType<typeof vi.fn>).mockRejectedValue({
      code: 'auth/wrong-password',
    });

    render(<SignIn />);

    fireEvent.change(screen.getByPlaceholderText('Email'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'wrongpassword' },
    });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(screen.getByText('Incorrect password.')).toBeInTheDocument();
    });
  });

  it('disables buttons while loading (sign-in submit initiates loading)', async () => {
    // Use a promise we can control to keep loading state active
    let resolveSignIn!: (value: typeof fakeUser) => void;
    const pendingSignIn = new Promise<typeof fakeUser>((resolve) => {
      resolveSignIn = resolve;
    });
    (signInWithEmailAndPassword as ReturnType<typeof vi.fn>).mockReturnValue(pendingSignIn);

    render(<SignIn />);

    fireEvent.change(screen.getByPlaceholderText('Email'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'password123' },
    });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    // During the pending promise, buttons should be disabled
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /loading/i })).toBeDisabled();
    });
    expect(screen.getByRole('button', { name: /continue with google/i })).toBeDisabled();
    expect(screen.getByRole('button', { name: /continue as guest/i })).toBeDisabled();

    // Resolve so the component finishes cleanly
    resolveSignIn(fakeUser);
    await waitFor(() => expect(mockNavigate).toHaveBeenCalled());
  });
});

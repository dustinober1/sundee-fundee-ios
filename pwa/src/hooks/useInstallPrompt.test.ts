import { renderHook, act } from '@testing-library/react';
import { useInstallPrompt } from './useInstallPrompt';

describe('useInstallPrompt', () => {
  beforeEach(() => {
    sessionStorage.clear();
    // Reset matchMedia mock
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: vi.fn().mockImplementation((query: string) => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      })),
    });
    // Reset userAgent
    Object.defineProperty(navigator, 'userAgent', {
      writable: true,
      value: 'Mozilla/5.0 (Windows NT 10.0)',
    });
  });

  it('returns isStandalone=true when display-mode: standalone matches', () => {
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: vi.fn().mockImplementation((query: string) => ({
        matches: query === '(display-mode: standalone)',
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      })),
    });

    const { result } = renderHook(() => useInstallPrompt());

    expect(result.current.isStandalone).toBe(true);
    expect(result.current.showPrompt).toBe(false);
  });

  it('captures beforeinstallprompt event and stores androidPrompt', () => {
    const { result } = renderHook(() => useInstallPrompt());

    const fakeEvent = {
      preventDefault: vi.fn(),
      prompt: vi.fn(),
      userChoice: Promise.resolve({ outcome: 'accepted', platform: 'web' }),
    };

    act(() => {
      window.dispatchEvent(Object.assign(new Event('beforeinstallprompt'), fakeEvent));
    });

    expect(result.current.androidPrompt).not.toBeNull();
  });

  it('detects iOS Safari via user agent when not standalone', () => {
    Object.defineProperty(navigator, 'userAgent', {
      writable: true,
      value: 'Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    });

    const { result } = renderHook(() => useInstallPrompt());

    expect(result.current.isIOS).toBe(true);
  });

  it('dismiss() sets sessionStorage flag and isDismissed=true', () => {
    const { result } = renderHook(() => useInstallPrompt());

    act(() => {
      result.current.dismiss();
    });

    expect(sessionStorage.getItem('installPromptDismissed')).toBe('1');
    expect(result.current.isDismissed).toBe(true);
  });

  it('isDismissed initializes to true when sessionStorage flag already set', () => {
    sessionStorage.setItem('installPromptDismissed', '1');

    const { result } = renderHook(() => useInstallPrompt());

    expect(result.current.isDismissed).toBe(true);
  });

  it('triggerAndroid() calls prompt() on captured event', async () => {
    const { result } = renderHook(() => useInstallPrompt());

    const fakePrompt = vi.fn().mockResolvedValue({ outcome: 'accepted' });
    const fakeEvent = {
      preventDefault: vi.fn(),
      prompt: fakePrompt,
      userChoice: Promise.resolve({ outcome: 'accepted', platform: 'web' }),
    };

    act(() => {
      window.dispatchEvent(Object.assign(new Event('beforeinstallprompt'), fakeEvent));
    });

    await act(async () => {
      await result.current.triggerAndroid();
    });

    expect(fakePrompt).toHaveBeenCalled();
  });
});

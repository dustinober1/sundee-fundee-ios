/**
 * InstallBanner — cross-platform PWA install instruction banner.
 *
 * iOS variant: shows share icon + "Tap Share then 'Add to Home Screen'" instructions
 * Android variant: shows "Install Sundee Fundee" with a native install trigger button
 *
 * Art Deco theme: cream (#F4F0DF) background, navy (#0D1A40) text, orange (#F2731A) CTA
 */

export interface InstallBannerProps {
  isIOS: boolean;
  onInstall: () => void;
  onDismiss: () => void;
  onAfterDismiss?: () => void;
}

export function InstallBanner({ isIOS, onInstall, onDismiss, onAfterDismiss }: InstallBannerProps) {
  function handleDismiss() {
    onDismiss();
    if (onAfterDismiss) onAfterDismiss();
  }

  function handleInstall() {
    onInstall();
    if (onAfterDismiss) onAfterDismiss();
  }

  return (
    <div
      role="banner"
      aria-label="Install Sundee Fundee app"
      style={{
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        background: '#F4F0DF',
        color: '#0D1A40',
        padding: '16px 20px',
        boxShadow: '0 -2px 12px rgba(13, 26, 64, 0.15)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 12,
        zIndex: 9999,
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        {isIOS ? (
          <>
            <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4 }}>
              Add to Home Screen
            </div>
            <div style={{ fontSize: 13, color: '#0D1A40', opacity: 0.8 }}>
              Tap{' '}
              <span
                aria-label="Share button"
                style={{ fontSize: 16 }}
              >
                &#x2B06;
              </span>{' '}
              [Share] then &ldquo;Add to Home Screen&rdquo;
            </div>
          </>
        ) : (
          <>
            <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4 }}>
              Install Sundee Fundee
            </div>
            <div style={{ fontSize: 13, color: '#0D1A40', opacity: 0.8 }}>
              Add the app to your home screen for quick access
            </div>
          </>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0 }}>
        {!isIOS && (
          <button
            onClick={handleInstall}
            aria-label="Install app"
            style={{
              background: '#F2731A',
              color: '#F4F0DF',
              border: 'none',
              borderRadius: 6,
              padding: '8px 16px',
              fontWeight: 700,
              fontSize: 14,
              cursor: 'pointer',
            }}
          >
            Install
          </button>
        )}
        <button
          onClick={handleDismiss}
          aria-label="Dismiss install banner"
          style={{
            background: 'transparent',
            color: '#0D1A40',
            border: 'none',
            borderRadius: 4,
            padding: '4px 8px',
            fontSize: 20,
            cursor: 'pointer',
            lineHeight: 1,
          }}
        >
          &times;
        </button>
      </div>
    </div>
  );
}

"use client";

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body>
        <main
          style={{
            minHeight: "100vh",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: "1.5rem",
            textAlign: "center",
            fontFamily: "Inter, system-ui, sans-serif",
            backgroundColor: "#f4f0df",
            color: "#0d1a40",
          }}
        >
          <p
            style={{
              fontSize: "0.75rem",
              letterSpacing: "0.3em",
              textTransform: "uppercase",
              color: "#b8860b",
              marginBottom: "1rem",
              fontFamily: "monospace",
            }}
          >
            Error
          </p>
          <h1 style={{ fontSize: "2rem", fontWeight: "bold", marginBottom: "0.75rem" }}>
            Something Went Wrong
          </h1>
          <p style={{ color: "#666", marginBottom: "2rem", maxWidth: "24rem" }}>
            An unexpected error occurred. Please try again.
          </p>
          <button
            onClick={reset}
            style={{
              padding: "0.75rem 1.5rem",
              backgroundColor: "#f27319",
              color: "#f4f0df",
              border: "none",
              borderRadius: "8px",
              fontWeight: 600,
              fontSize: "0.875rem",
              cursor: "pointer",
            }}
          >
            Try Again
          </button>
        </main>
      </body>
    </html>
  );
}

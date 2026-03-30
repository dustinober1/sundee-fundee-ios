import type { Metadata, Viewport } from "next";
import { AuthProvider } from "@/components/providers/auth-provider";
import "./globals.css";

export const metadata: Metadata = {
  title: "Sundee Fundee — Strength Training",
  description:
    "AI-powered strength training that adapts to your cycle, injuries, and energy. Every workout is built for exactly where you are today.",
  manifest: "/manifest.json",
  metadataBase: new URL("https://sundeefundee.com"),
  openGraph: {
    type: "website",
    siteName: "Sundee Fundee",
    title: "Sundee Fundee — Strength Training",
    description:
      "AI-powered strength training that adapts to your cycle, injuries, and energy. Every workout is built for exactly where you are today.",
    url: "https://sundeefundee.com",
  },
  twitter: {
    card: "summary",
    title: "Sundee Fundee — Strength Training",
    description:
      "AI-powered strength training that adapts to your cycle, injuries, and energy.",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Sundee Fundee",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d1a40",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body><AuthProvider>{children}</AuthProvider></body>
    </html>
  );
}

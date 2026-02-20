import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Providers } from "@/contexts/providers";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { SerwistProvider } from "./serwist-client";
import { SerwistReloadHandler } from "@/components/SerwistReloadHandler";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Sundee-Fundee",
  description: "Track your workouts and fitness goals",
  manifest: '/manifest.json',
  icons: {
    apple: [
      { url: '/icons/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  appleWebApp: {
    capable: true,
    title: 'SundeeFundee',
    statusBarStyle: 'black-translucent',
  },
  other: {
    'apple-mobile-web-app-capable': 'yes',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <SerwistProvider swUrl="/serwist/sw.js" reloadOnOnline={false}>
          <Providers>
            {children}
            <BottomNavigation />
            <SerwistReloadHandler />
          </Providers>
        </SerwistProvider>
      </body>
    </html>
  );
}

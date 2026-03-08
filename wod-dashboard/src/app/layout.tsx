import type { Metadata } from "next";
import Script from "next/script";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import NavHeader from "@/components/NavHeader";
import CloudKitAuth from "@/components/CloudKitAuth";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Sundee Fundee - WOD Dashboard",
  description: "Admin dashboard for managing Workouts of the Day",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-cream text-navy min-h-screen`}
      >
        <Script
          src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js"
          strategy="afterInteractive"
        />
        <NavHeader />
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <CloudKitAuth>
            {children}
          </CloudKitAuth>
        </main>
      </body>
    </html>
  );
}

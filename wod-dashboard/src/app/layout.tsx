import "./globals.css";

export const metadata = { title: "Sundee Fundee Dashboard" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="flex h-screen">
        <nav className="w-60 bg-navy text-cream p-4 flex flex-col gap-2">
          <h1 className="text-xl font-bold mb-6">Sundee Fundee</h1>
          <a href="/wods" className="hover:text-orange">WODs</a>
          <a href="/programs" className="hover:text-orange">Programs</a>
          <a href="/catalog" className="hover:text-orange">Exercise Catalog</a>
          <a href="/settings" className="hover:text-orange">Settings</a>
        </nav>
        <main className="flex-1 overflow-auto p-6">{children}</main>
      </body>
    </html>
  );
}

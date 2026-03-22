import "./globals.css";
import { Sidebar } from "@/components/sidebar";
import { ToastProvider } from "@/components/toast";

export const metadata = { title: "Sundee Fundee Dashboard" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="flex h-screen">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <ToastProvider>
            <main className="flex-1 overflow-auto p-6">{children}</main>
          </ToastProvider>
        </div>
      </body>
    </html>
  );
}

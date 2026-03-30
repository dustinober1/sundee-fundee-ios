import { AdminSidebar } from "./admin-sidebar";

interface AdminShellProps {
  children: React.ReactNode;
}

export function AdminShell({ children }: AdminShellProps) {
  return (
    <div className="flex min-h-screen bg-cream">
      <AdminSidebar />
      <div className="flex-1 flex flex-col min-h-screen overflow-hidden">
        {children}
      </div>
    </div>
  );
}

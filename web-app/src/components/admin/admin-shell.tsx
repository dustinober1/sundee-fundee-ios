import { AdminSidebar } from "./admin-sidebar";
import { SearchCommand } from "./search-command";

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
      <SearchCommand />
    </div>
  );
}

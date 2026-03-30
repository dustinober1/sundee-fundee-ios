import { redirect } from "next/navigation";
import { getAuthUser } from "@/lib/firestore";
import { isAdmin } from "@/lib/admin-auth";
import { AdminShell } from "@/components/admin/admin-shell";

export const metadata = {
  title: "Admin — Sundee Fundee",
};

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getAuthUser();
  if (!user) {
    redirect("/sign-in");
  }

  const admin = await isAdmin(user.uid);
  if (!admin) {
    redirect("/dashboard");
  }

  return <AdminShell>{children}</AdminShell>;
}

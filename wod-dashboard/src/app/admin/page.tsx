import AdminList from '@/components/AdminList';

export default function AdminPage() {
  // Initial admins will be loaded client-side via AdminList
  // Pass empty array; the component fetches from CloudKit
  return <AdminList initialAdmins={[]} />;
}

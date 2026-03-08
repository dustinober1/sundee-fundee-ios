'use client';

import { useState } from 'react';
import { AdminUser, addAdmin, removeAdmin } from '@/lib/auth';

interface AdminListProps {
  initialAdmins: AdminUser[];
}

export default function AdminList({ initialAdmins }: AdminListProps) {
  const [admins, setAdmins] = useState<AdminUser[]>(initialAdmins);
  const [newAppleID, setNewAppleID] = useState('');
  const [newRole, setNewRole] = useState<'owner' | 'coach'>('coach');
  const [adding, setAdding] = useState(false);
  const [removingID, setRemovingID] = useState<string | null>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const handleAdd = async () => {
    if (!newAppleID.trim()) return;
    setAdding(true);
    setMessage(null);
    try {
      await addAdmin(newAppleID.trim(), newRole);
      setAdmins((prev) => [
        ...prev,
        { appleUserID: newAppleID.trim(), role: newRole },
      ]);
      setNewAppleID('');
      setMessage({ type: 'success', text: 'Admin added successfully' });
    } catch (err) {
      setMessage({
        type: 'error',
        text: err instanceof Error ? err.message : 'Failed to add admin',
      });
    } finally {
      setAdding(false);
    }
  };

  const handleRemove = async (appleUserID: string) => {
    if (!confirm(`Remove admin ${appleUserID}?`)) return;
    setRemovingID(appleUserID);
    setMessage(null);
    try {
      await removeAdmin(appleUserID);
      setAdmins((prev) => prev.filter((a) => a.appleUserID !== appleUserID));
      setMessage({ type: 'success', text: 'Admin removed' });
    } catch (err) {
      setMessage({
        type: 'error',
        text: err instanceof Error ? err.message : 'Failed to remove admin',
      });
    } finally {
      setRemovingID(null);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold text-navy mb-6">Admin Management</h1>

      {/* Message */}
      {message && (
        <div
          className={`mb-4 px-4 py-3 rounded-lg text-sm font-medium ${
            message.type === 'success'
              ? 'bg-green-50 text-green-700 border border-green-200'
              : 'bg-red-50 text-red-700 border border-red-200'
          }`}
        >
          {message.text}
        </div>
      )}

      {/* Add Admin Form */}
      <div className="art-deco-card p-5 mb-6">
        <h2 className="text-lg font-bold text-navy mb-4">Add Admin</h2>
        <div className="flex items-end gap-3">
          <div className="flex-1">
            <label className="block text-sm font-medium text-navy mb-1">
              Apple User ID
            </label>
            <input
              type="text"
              value={newAppleID}
              onChange={(e) => setNewAppleID(e.target.value)}
              placeholder="e.g. 001234.abcdef..."
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
          <div className="w-32">
            <label className="block text-sm font-medium text-navy mb-1">Role</label>
            <select
              value={newRole}
              onChange={(e) => setNewRole(e.target.value as 'owner' | 'coach')}
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              <option value="coach">Coach</option>
              <option value="owner">Owner</option>
            </select>
          </div>
          <button
            onClick={handleAdd}
            disabled={!newAppleID.trim() || adding}
            className="px-5 py-2 bg-orange text-cream font-medium rounded-md hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm whitespace-nowrap"
          >
            {adding ? 'Adding...' : 'Add Admin'}
          </button>
        </div>
      </div>

      {/* Admin List */}
      <div className="art-deco-card overflow-hidden">
        <div className="px-5 py-4 border-b border-navy/10">
          <h2 className="text-lg font-bold text-navy">Current Admins</h2>
        </div>
        {admins.length === 0 ? (
          <p className="px-5 py-8 text-center text-navy/40 text-sm">
            No admins configured yet.
          </p>
        ) : (
          <ul className="divide-y divide-navy/10">
            {admins.map((admin) => (
              <li
                key={admin.appleUserID}
                className="flex items-center justify-between px-5 py-4"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="flex-shrink-0 w-10 h-10 bg-navy/10 rounded-full flex items-center justify-center">
                    <svg className="w-5 h-5 text-navy/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-navy truncate">
                      {admin.appleUserID}
                    </p>
                    <span
                      className={`inline-block mt-0.5 px-2 py-0.5 rounded text-[10px] font-bold tracking-wider uppercase ${
                        admin.role === 'owner'
                          ? 'bg-gold/20 text-gold'
                          : 'bg-navy/10 text-navy/60'
                      }`}
                    >
                      {admin.role}
                    </span>
                  </div>
                </div>
                <button
                  onClick={() => handleRemove(admin.appleUserID)}
                  disabled={removingID === admin.appleUserID}
                  className="flex-shrink-0 px-3 py-1.5 text-sm text-red-600 border border-red-200 rounded-md hover:bg-red-50 disabled:opacity-40 transition-colors"
                >
                  {removingID === admin.appleUserID ? 'Removing...' : 'Remove'}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

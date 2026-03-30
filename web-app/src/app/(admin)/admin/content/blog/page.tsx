"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { RichTextEditor } from "@/components/admin/rich-text-editor";
import { Button } from "@/components/ui/button";
import type { BlogPost } from "@/lib/domain/admin-types";
import { slugify } from "@/lib/domain/admin-types";

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

function newBlogPost(): BlogPost {
  return {
    slug: "",
    title: "",
    description: "",
    author: "",
    date: new Date().toISOString().slice(0, 10),
    tags: [],
    image: undefined,
    content: "",
    status: "draft",
    updatedAt: new Date().toISOString(),
  };
}

function StatusBadge({ status }: { status: "draft" | "published" }) {
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-mono tracking-wide ${
        status === "published"
          ? "bg-green-100 text-green-700"
          : "bg-gray-100 text-gray-500"
      }`}
    >
      {status}
    </span>
  );
}

export default function BlogEditorPage() {
  const [posts, setPosts] = useState<BlogPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<BlogPost | null>(null);
  const [draft, setDraft] = useState<BlogPost | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [isNew, setIsNew] = useState(false);
  const [slugEdited, setSlugEdited] = useState(false);

  useEffect(() => {
    fetch("/api/admin/blog")
      .then((r) => r.json())
      .then((data) => setPosts(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  function handleRowClick(post: BlogPost) {
    setSelected(post);
    setDraft({ ...post, tags: [...post.tags] });
    setIsNew(false);
    setSlugEdited(false);
  }

  function handleNew() {
    setSelected(null);
    setDraft(newBlogPost());
    setIsNew(true);
    setSlugEdited(false);
  }

  function handleClose() {
    setSelected(null);
    setDraft(null);
    setIsNew(false);
    setSlugEdited(false);
  }

  function updateDraft(field: Partial<BlogPost>) {
    setDraft((prev) => (prev ? { ...prev, ...field } : prev));
  }

  function handleTitleChange(title: string) {
    if (!slugEdited) {
      updateDraft({ title, slug: slugify(title) });
    } else {
      updateDraft({ title });
    }
  }

  function handleSlugChange(slug: string) {
    setSlugEdited(true);
    updateDraft({ slug });
  }

  async function handleSave() {
    if (!draft) return;
    setSaving(true);
    try {
      const slug = draft.slug || slugify(draft.title);
      const payload: BlogPost = {
        ...draft,
        slug,
        updatedAt: new Date().toISOString(),
        publishedAt:
          draft.status === "published" && !draft.publishedAt
            ? new Date().toISOString()
            : draft.publishedAt,
      };
      const url = isNew ? "/api/admin/blog" : `/api/admin/blog/${selected?.slug ?? slug}`;
      const method = isNew ? "POST" : "PATCH";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("Save failed");
      const savedItem: BlogPost = isNew ? { ...payload } : { ...payload };
      setPosts((prev) =>
        isNew
          ? [savedItem, ...prev]
          : prev.map((p) => (p.slug === slug ? savedItem : p))
      );
      setSelected(savedItem);
      setDraft({ ...savedItem, tags: [...savedItem.tags] });
      setIsNew(false);
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!selected) return;
    try {
      await fetch(`/api/admin/blog/${selected.slug}`, { method: "DELETE" });
      setPosts((prev) => prev.filter((p) => p.slug !== selected.slug));
      handleClose();
    } catch (e) {
      console.error(e);
    } finally {
      setDeleteOpen(false);
    }
  }

  const columns: Column<BlogPost>[] = [
    { key: "title", header: "Title", sortable: true },
    { key: "author", header: "Author" },
    {
      key: "status",
      header: "Status",
      render: (row) => <StatusBadge status={row.status} />,
    },
    { key: "date", header: "Date", sortable: true },
  ];

  const panelTitle = isNew ? "New Blog Post" : selected ? selected.title || "Edit Post" : "";

  return (
    <>
      <AdminHeader
        title="Blog"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New Post
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col ${draft ? "w-2/5" : "w-full"} overflow-hidden`}>
          {loading ? (
            <p className="p-6 text-text-secondary">Loading...</p>
          ) : posts.length === 0 && !draft ? (
            <EmptyState
              title="No blog posts yet"
              description="Create your first blog post."
              actionLabel="New Post"
              onAction={handleNew}
            />
          ) : (
            <DataTable
              columns={columns}
              data={posts}
              rowKey={(p) => p.slug}
              onRowClick={handleRowClick}
              selectedKey={selected?.slug ?? null}
              searchFn={(row, q) => row.title.toLowerCase().includes(q)}
              searchPlaceholder="Search by title..."
            />
          )}
        </div>

        {draft && (
          <div className="w-3/5 overflow-hidden">
            <DetailPanel
              title={panelTitle}
              onClose={handleClose}
              actions={
                <div className="flex gap-2">
                  {!isNew && selected && (
                    <Button variant="destructive" onClick={() => setDeleteOpen(true)}>
                      Delete
                    </Button>
                  )}
                  <Button variant="primary" onClick={handleSave} disabled={saving}>
                    {saving ? "Saving..." : "Save"}
                  </Button>
                </div>
              }
            >
              <div className="space-y-4">
                {/* Status toggle */}
                <div>
                  <p className="font-mono text-[11px] tracking-wider uppercase text-gold mb-2">
                    Status
                  </p>
                  <div className="flex gap-1 p-1 bg-navy/5 rounded-sm w-fit">
                    {(["draft", "published"] as const).map((s) => (
                      <button
                        key={s}
                        onClick={() => updateDraft({ status: s })}
                        className={`px-4 py-1.5 text-xs rounded-sm font-mono transition-colors ${
                          draft.status === s
                            ? "bg-orange text-white"
                            : "text-text-secondary hover:text-navy"
                        }`}
                      >
                        {s.charAt(0).toUpperCase() + s.slice(1)}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-xs text-text-secondary mb-1">Title</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.title}
                    onChange={(e) => handleTitleChange(e.target.value)}
                    placeholder="Post title"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Slug</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.slug}
                    onChange={(e) => handleSlugChange(e.target.value)}
                    placeholder="url-friendly-slug"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Description</label>
                  <textarea
                    className={INPUT_CLASS}
                    rows={2}
                    value={draft.description}
                    onChange={(e) => updateDraft({ description: e.target.value })}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="block text-xs text-text-secondary mb-1">Author</label>
                    <input
                      className={INPUT_CLASS}
                      value={draft.author}
                      onChange={(e) => updateDraft({ author: e.target.value })}
                      placeholder="Author name"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-text-secondary mb-1">Date</label>
                    <input
                      type="date"
                      className={INPUT_CLASS}
                      value={draft.date}
                      onChange={(e) => updateDraft({ date: e.target.value })}
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Tags{" "}
                    <span className="text-text-secondary/60">(comma-separated)</span>
                  </label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.tags.join(", ")}
                    onChange={(e) =>
                      updateDraft({
                        tags: e.target.value
                          .split(",")
                          .map((t) => t.trim())
                          .filter(Boolean),
                      })
                    }
                    placeholder="training, cycle, strength"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Image URL{" "}
                    <span className="text-text-secondary/60">(optional)</span>
                  </label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.image ?? ""}
                    onChange={(e) => updateDraft({ image: e.target.value || undefined })}
                    placeholder="/images/post-cover.jpg"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-2">Body</label>
                  <RichTextEditor
                    content={draft.content}
                    onChange={(html) => updateDraft({ content: html })}
                    placeholder="Write your blog post..."
                  />
                </div>
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete Post"
        message={`Are you sure you want to delete "${selected?.title}"? This cannot be undone.`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}

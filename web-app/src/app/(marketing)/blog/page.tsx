import { Card } from "@/components/ui/card";
import { getAllPosts } from "@/lib/blog";
import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Blog — Sundee Fundee",
  description: "Training tips, updates, and insights from the Sundee Fundee team.",
  openGraph: {
    title: "Blog — Sundee Fundee",
    description: "Training tips, updates, and insights from the Sundee Fundee team.",
  },
};

export default function BlogPage() {
  const posts = getAllPosts();

  return (
    <main className="max-w-2xl mx-auto">
      <h1 className="text-4xl mb-spacing-lg">Blog</h1>
      <div className="flex flex-col gap-spacing-md">
        {posts.map((post) => (
          <Link key={post.slug} href={`/blog/${post.slug}`}>
            <Card className="hover:shadow-md transition-shadow">
              <p className="text-text-secondary text-[12px] mb-spacing-xs">
                {new Date(post.date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
              </p>
              <h2 className="text-xl mb-spacing-xs">{post.title}</h2>
              <p className="text-text-secondary text-[14px]">{post.description}</p>
              {post.tags.length > 0 && (
                <div className="flex gap-spacing-xs mt-spacing-sm">
                  {post.tags.map((tag) => (
                    <span key={tag} className="text-[11px] bg-navy/5 text-navy px-2 py-0.5 rounded-sm">{tag}</span>
                  ))}
                </div>
              )}
            </Card>
          </Link>
        ))}
        {posts.length === 0 && (
          <p className="text-text-secondary text-center">No posts yet. Check back soon!</p>
        )}
      </div>
    </main>
  );
}

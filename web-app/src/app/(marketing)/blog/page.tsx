import { Card } from "@/components/ui/card";
import { PageHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { getAllPosts } from "@/lib/blog";
import Link from "next/link";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Blog — Sundee Fundee",
  description: "Training tips, updates, and insights from the Sundee Fundee team.",
  openGraph: {
    title: "Blog — Sundee Fundee",
    description: "Training tips, updates, and insights from the Sundee Fundee team.",
  },
};

export default async function BlogPage() {
  const posts = await getAllPosts();

  return (
    <main className="max-w-2xl mx-auto">
      <Link href="/" className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors">
        &larr; Home
      </Link>

      <div className="mt-6">
        <PageHeader label="Insights" title="Blog" subtitle="Training tips, updates, and insights from the Sundee Fundee team." />
      </div>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto my-8" />

      <div className="flex flex-col gap-4">
        {posts.map((post) => (
          <Link key={post.slug} href={`/blog/${post.slug}`}>
            <Card className="hover:shadow-md hover:border-gold/20 border border-transparent transition-all">
              <p className="text-gold font-mono text-[10px] tracking-[0.2em] uppercase mb-2">
                {new Date(post.date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
              </p>
              <h2 className="text-xl mb-1">{post.title}</h2>
              <p className="text-text-secondary text-[14px]">{post.description}</p>
              {post.tags.length > 0 && (
                <div className="flex gap-2 mt-3">
                  {post.tags.map((tag) => (
                    <span key={tag} className="text-[10px] bg-gold/10 text-gold border border-gold/20 px-2.5 py-0.5 rounded-full font-mono tracking-wider uppercase">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </Card>
          </Link>
        ))}
        {posts.length === 0 && (
          <Card>
            <div className="text-center py-8">
              <p className="text-text-secondary">No posts yet. Check back soon!</p>
            </div>
          </Card>
        )}
      </div>
    </main>
  );
}

import { getAllPosts, getPostBySlug } from "@/lib/blog";
import { ArtDecoRule, SectionLabel } from "@/components/ui/art-deco";
import { MDXRemote } from "next-mdx-remote/rsc";
import { notFound } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";

export async function generateStaticParams() {
  return getAllPosts().map((p) => ({ slug: p.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) return {};
  return {
    title: `${post.title} — Sundee Fundee`,
    description: post.description,
    openGraph: {
      title: post.title,
      description: post.description,
      type: "article",
      publishedTime: post.date,
      authors: [post.author],
      ...(post.image && { images: [{ url: post.image }] }),
    },
  };
}

export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) notFound();

  return (
    <main className="max-w-2xl mx-auto">
      <Link href="/blog" className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors">
        &larr; Back to Blog
      </Link>
      <article className="mt-6">
        <header className="mb-8">
          <SectionLabel className="mb-2">
            {new Date(post.date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
            {" · "}{post.author}
          </SectionLabel>
          <h1 className="!text-4xl !font-bold tracking-tight">{post.title}</h1>
          <p className="text-text-secondary mt-3 text-lg leading-relaxed">{post.description}</p>
          <ArtDecoRule className="text-gold/30 mt-6" />
        </header>
        <div className="prose">
          <MDXRemote source={post.content} />
        </div>
      </article>
    </main>
  );
}

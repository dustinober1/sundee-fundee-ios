import { getAllPosts, getPostBySlug } from "@/lib/blog";
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
      <Link href="/blog" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Back to Blog
      </Link>
      <article>
        <header className="mb-spacing-xl">
          <p className="text-text-secondary text-[13px] mb-spacing-xs">
            {new Date(post.date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
            {" · "}{post.author}
          </p>
          <h1 className="text-4xl">{post.title}</h1>
          <p className="text-text-secondary mt-spacing-sm text-lg">{post.description}</p>
        </header>
        <div className="prose">
          <MDXRemote source={post.content} />
        </div>
      </article>
    </main>
  );
}

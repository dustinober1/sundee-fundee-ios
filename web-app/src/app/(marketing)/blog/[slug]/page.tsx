import { getAllPosts, getPostBySlug } from "@/lib/blog";
import { MDXRemote } from "next-mdx-remote/rsc";
import { notFound } from "next/navigation";
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
    <main className="max-w-2xl mx-auto px-spacing-md py-spacing-xl">
      <article>
        <header className="mb-spacing-lg">
          <p className="text-text-secondary text-[13px] mb-spacing-xs">
            {new Date(post.date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
            {" · "}{post.author}
          </p>
          <h1 className="text-4xl">{post.title}</h1>
          <p className="text-text-secondary mt-spacing-sm">{post.description}</p>
        </header>
        <div className="prose prose-navy max-w-none [&_h1]:font-heading [&_h2]:font-heading [&_h3]:font-heading [&_a]:text-orange">
          <MDXRemote source={post.content} />
        </div>
      </article>
    </main>
  );
}

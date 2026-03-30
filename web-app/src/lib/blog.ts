import { cache } from "react";
import { db } from "@/lib/firebase-admin";

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  date: string;
  author: string;
  tags: string[];
  image?: string;
  content: string;
  status: "draft" | "published";
}

export async function getAllPosts(): Promise<BlogPost[]> {
  try {
    const snapshot = await db
      .collection("blogPosts")
      .where("status", "==", "published")
      .orderBy("date", "desc")
      .get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        slug: (data.slug as string | undefined) ?? doc.id,
        title: (data.title as string | undefined) ?? doc.id,
        description: (data.description as string | undefined) ?? "",
        date: (data.date as string | undefined) ?? "",
        author: (data.author as string | undefined) ?? "",
        tags: (data.tags as string[] | undefined) ?? [],
        image: data.image as string | undefined,
        content: (data.content as string | undefined) ?? "",
        status: "published" as const,
      };
    });
  } catch {
    return [];
  }
}

export const getPostBySlug = cache(async (slug: string): Promise<BlogPost | null> => {
  if (!slug) return null;

  try {
    const doc = await db.collection("blogPosts").doc(slug).get();
    if (!doc.exists) return null;

    const data = doc.data()!;
    if (data.status !== "published") return null;

    return {
      slug: (data.slug as string | undefined) ?? doc.id,
      title: (data.title as string | undefined) ?? doc.id,
      description: (data.description as string | undefined) ?? "",
      date: (data.date as string | undefined) ?? "",
      author: (data.author as string | undefined) ?? "",
      tags: (data.tags as string[] | undefined) ?? [],
      image: data.image as string | undefined,
      content: (data.content as string | undefined) ?? "",
      status: "published" as const,
    };
  } catch {
    return null;
  }
});
